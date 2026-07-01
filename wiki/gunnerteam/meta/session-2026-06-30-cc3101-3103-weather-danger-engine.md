---
type: session
title: session-2026-06-30-cc3101-3103-weather-danger-engine
created: '2026-06-30'
updated: '2026-06-30'
tags:
  - gunnerteam
  - backend
  - weather
  - lambda
  - deploy
  - apns
  - rls
  - eventbridge
status: stable
related:
  - '[[gunnerteam/meta/session-2026-06-29-cc3100-3102-nws-weather-provider]]'
  - '[[gunnerteam/aws-environment]]'
  - '[[gunnerteam/overview]]'
  - '[[shared/rds-proxy-tls-and-sst-python-packaging]]'
---

# Session cc-3101 / cc-3103 — dangerous-weather alert engine + read endpoints (v416→v417)

Two work items on `gunnerteam-api`, building on the cc-3100/3102 NWS provider foundation and the
cc-3104 provider danger-data contract: the danger-only alert **engine** (cc-3101, v416, commit
`d3eb7d2`) and the **read side** (cc-3103, v417, commit `b9d95a1`). Danger-only rescope (2026-06-30):
weather surfaces **only** as a danger alert — to ops (poll endpoint / Colin's app) and crew (APNs) —
never a forecast card, and never fires on normal weather.

## cc-3101 — dangerous-weather alert engine (v416)

**`lib/weather/evaluate.js` (new, pure, unit-tested).** `evaluate(conditions, config)` returns only
genuinely dangerous conditions. Fires on NWS **Warnings** (`kind` normalized in cc-3104's
`contract.js`) and quantitative thresholds; normal weather → `[]` (the entire point of the rescope).
- Warning-driven: `tornado`→`tornado/critical`, `severe_storm`→`severe_storm/critical`,
  `flood`→`heavy_rain/high`, `winter`→`heavy_snow/high`, `high_wind`→`high_wind/high`. `sourceAlertId`
  = the alert id. `other` (Watches/Advisories) is never danger-tier.
- Threshold-driven (`sourceAlertId=null`): `accum.rainIn>=1.0`, `accum.snowIn>=3.0`,
  `current.windGustMph>=35` (`RAIN_DANGER_IN`/`SNOW_DANGER_IN`/`WIND_GUST_DANGER_MPH` code constants —
  per-org tuning would need `gt_org_weather_config` columns that don't exist; no masterdb migration).
- One row per condition; a warning-driven row wins over a threshold duplicate. `config.enabled===false`
  → `[]`. **Spec deviation:** the prompt referenced `accum.windGustMph`, but the cc-3104 contract puts
  the window-max gust in `current.windGustMph` — the engine reads the real field.
- `evaluate.test.js` = 20/20 (Tester agent), incl. the mandated normal-weather `→ []` case.

**`lib/weather/index.js` `getJobWeather` now forwards `accum`** (cc-3104 added it to the contract but
index.js was out of that prompt's scope; without it, threshold triggers never fire).

**`lib/apns.js` `sendPush` gained a back-compat `opts` = `{sound, interruptionLevel}`.** `critical`
conditions (tornado/severe_storm) send `{critical:1, name:'default', volume:1.0}` +
`interruptionLevel:'time-sensitive'` (distinct/louder where entitled, never missing-file silence — the
iOS app bundles no custom sounds). node-apn 8.1.0 supports both natively.

**`lib/scheduler.js` `weather-sweep` task** (wired into `runScheduledTasks`), daylight-ET gated
(`etHour>=6 && etHour<20`). Two legs, both attributing alerts to a `job_id`:
- **Crew leg** — plain `query()` over open `gt_time_entries` (checked-in) → job, latest
  `gt_travel_pings` coord (fallback `check_in_lat/lng`), crew APNs token. `org-scope-ok` cron sweep.
- **Job-site leg** — active job coords from `gt_job_bundle_cache.payload->'jobs'` (the only local
  mirror of Field Portal jobs; `ops_jobs`/`projects` have no lat/lng + no app-role grants). Dev coords
  are all null, so this leg is inert in dev; the crew leg is the populated path.
- Per fired condition: **upsert** `gt_weather_alerts` via `queryWithTenant(orgId)` (FORCE-RLS);
  **push** checked-in crew; **close-out** open rows whose condition no longer fires (`ended_at=NOW()`);
  `audit({action:'weather.danger.alert', orgId, metadata:{jobId,condition,severity}})`.

**`terraform/eventbridge.tf`:** `weather-sweep = rate(15 minutes)` (rule/target/permission via the
existing `for_each = local.scheduled_tasks`).

### Load-bearing schema facts (queried live off prod via the `_sql` Lambda)
- `gt_weather_alerts` FORCE-RLS. Dedup index `uq_gt_weather_alerts_dedup(org_id, job_id, condition,
  source_alert_id)` — `source_alert_id` **nullable, no `NULLS NOT DISTINCT`**, so `ON CONFLICT` can't
  dedup threshold-driven (null-source) rows. Two upsert paths: warning-driven via `ON CONFLICT DO
  NOTHING`; threshold-driven via a manual open-row guard (`SELECT … WHERE source_alert_id IS NULL AND
  ended_at IS NULL`).
- Grants to `gunnerteam_app` = SELECT/INSERT/UPDATE, **no DELETE** → alerts close via `ended_at`, never
  deleted. Runtime role is `gunnerteam_app` (cc-2137 landed).
- `gt_time_entries` / `gt_travel_pings`: **not** FORCE-RLS, owned by `gunnerteam_app` → plain `query()`.
- `user_devices`: FORCE-RLS (owner postgres) but a `gunnerteam_app_org` policy hardcoded to Gunner's
  org (`69aad261…`) is OR'd with `org_isolation`, so plain `query()` still sees Gunner's devices — how
  `checkOverdueInspections` already works.
- **Cast bug (cc-2205 class):** `user_devices.user_id` is `varchar`, `gt_time_entries.user_id` is
  `uuid` → the crew-leg subquery join needs `d.user_id = te.user_id::text` (varchar=uuid otherwise
  errors, breaking the whole sweep). Found via the live-leg dry run.

### Provider flip to NWS (via the cc-3101 terraform apply)
The targeted `eventbridge.tf` apply also realized committed drift in `lambda-api.tf`:
`WEATHER_PROVIDER` `openweather`→`nws` + NWS env vars (cc-3102's deferred wiring). Required: openweather
emits no `accum`/Warning `kind`, so the engine is inert under it — and openweather was already 401ing in
dev. Env applies to `$LATEST`; the alias only picks it up on the next `publish-version`, so sequence
was: terraform apply (env→nws) → full S3 deploy (snapshot nws into a version, alias `live`) → live nws
smoke (`evaluated=2` crew jobs, no danger, no false fire).

### Verification (secret-gated fixture seam, cc-2207 pattern)
NWS never returns danger on demand, so a temporary `MIGRATION_SECRET`-gated `_fixtures` path in
`weatherSweep` seeded the cache + synthetic org/job/crew, then was reverted and redeployed clean.
Proved: forced tornado → insert + crew push transmitted to APNs (`BadDeviceToken` only because the
token is fabricated — a real token delivers) with the critical opts; 2nd invoke → `inserted=0` (ON
CONFLICT dedup); normal weather → close-out `ended_at`; threshold rain → insert then open-row dedup;
fresh normal job → fully inert. Verification rows closed via `ended_at` (no DELETE grant).

## cc-3103 — active danger-alert read endpoints (v417)

**Phase 0 — `routes/templates.js` `POST /service-keys` (make scoped keys mintable):** prefix the
minted value `gtsk_` (so `authOrServiceKey` dispatches on it and the middleware's `header.slice(7)`
hash matches) and store optional `req.body.allowed_tasks` (validated array-of-strings → existing
`gt_service_keys.allowed_tasks` `text[]`; null = unrestricted). Admin-only + single-time `{key}` return
unchanged.

**Phase 1 — `GET /weather/alerts/active` (`authOrServiceKey`):** org-wide active alerts
(`ended_at IS NULL`) via `queryWithTenant`. In-handler scope check (mirrors `assistant.js`):
`req.serviceKeyTasks != null && !includes('weather_alerts_read')` → 403 `task_not_allowed` (null =
unrestricted). Per-caller rate limit (`serviceKeyId || user.id || orgId`, 60/min, Dynamo store when
`RATE_LIMIT_TABLE` set) + `audit('weather.alerts.polled', orgId, {count})`. Payload =
`{id, jobId, condition, severity, startedAt}` only — no names/PII/brand (Colin maps jobId→project his
side).

**Phase 2 — `GET /weather/job/:jobId` (`requireAuth`) repurposed to a badge:** forecast/provider path
deleted; org-verify the job via `ccFetch('/projects/:id')` (fail-closed → 404, no existence leak), then
return that job's active alert (`{activeAlert:{condition,severity,startedAt}}`) or `{activeAlert:null}`
via `queryWithTenant`. `lib/weather/*` left in place (the engine uses it).

**Verify (live via API Gateway):** scoped key → 200 + seeded alert; out-of-scope key → 403; no auth →
401; after `ended_at` set, the alert drops from the active list. Per-job: open → populated, none →
`null`, bogus → 404, no auth → 401. A temp Cognito user + two service keys + seeded alerts were created
and fully cleaned up (Cognito delete; service keys deleted; alerts closed via `ended_at`).

## Key facts / gotchas
- **Danger-only model:** `evaluate.js` fires only on NWS Warnings + quantitative thresholds; normal
  weather returns `[]`. Ops signal = the persisted open `gt_weather_alerts` row (read by
  `/weather/alerts/active`); crew signal = APNs push. Job badge = an open alert for that job.
- **`gt_weather_alerts` closes via `ended_at`, never DELETE** (no grant) — clears the badge + resets
  dedup. Threshold-driven (null `source_alert_id`) rows can't use `ON CONFLICT` (nullable, distinct
  NULLs) → manual open-row guard.
- **The engine requires the NWS provider** (`accum` + Warning `kind`s); openweather can't feed it.
- **`_sql` reads on FORCE-RLS tables need org context**: node-pg returns an *array* for multi-statement
  queries (so `result.rows` is undefined) — the working pattern is a single statement `WITH ctx AS
  MATERIALIZED (SELECT set_config('app.current_org_id','<org>',false)) SELECT … FROM ctx, <table> …`.
  (`UPDATE … FROM ctx` does **not** work — RLS `USING` is evaluated during the target scan before the
  ctx cross-join runs `set_config`; use `SET app.current_org_id=…; UPDATE …` there.)
- **APNs critical alerts** use `{critical:1,name:'default',volume:1.0}` + `time-sensitive` — never a
  named `.caf` (the iOS app bundles none → would play silent).

## Deploy / git
Full S3 deploy block each item (`gunnerteam-lambda-deploy-useast2` → `update-function-code` → `wait` →
`publish-version` → `update-alias live`, `file:///tmp/rc.json` empty routing). Commits: `d3eb7d2`
(cc-3101, v416), `b9d95a1` (cc-3103, v417) — touched files only. Pre-existing `null_resource.
clear_alias_routing` version-trigger churn in the terraform plan is unrelated.
