---
type: session
title: session-2026-07-02-cc3107-weather-smoke-test
created: '2026-07-02'
updated: '2026-07-02'
tags:
  - gunnerteam
  - backend
  - weather
  - smoke-test
  - rls
  - cognito
  - nws
  - lambda
status: stable
related:
  - '[[gunnerteam/meta/session-2026-06-30-cc3101-3103-weather-danger-engine]]'
  - '[[gunnerteam/meta/session-2026-06-29-cc3100-3102-nws-weather-provider]]'
  - '[[gunnerteam/aws-environment]]'
  - '[[gunnerteam/overview]]'
  - '[[shared/rds-proxy-tls-and-sst-python-packaging]]'
---
# Session: 2026-07-02 — cc-3107 weather danger-alert smoke test

Built and shipped `gunnerteam-api/scripts/smoke-weather.mjs` — a repeatable, prod-safe,
self-cleaning smoke test that exercises the danger-only weather pipeline
([[gunnerteam/meta/session-2026-06-30-cc3101-3103-weather-danger-engine|cc-3101 engine, cc-3103 read routes]])
end to end against the LIVE dev Lambda (which fronts PROD masterdb). Committed `bf2373f`
on `main`. Final live run: **10 passed, 0 failed, 0 skipped**.

## What the script does

Three checks, all using the secret-gated `_sql` preflight seam + the EventBridge
`weather-sweep` task dispatch that `lambda.js` already exposes — no new backend surface,
nothing reachable via API Gateway.

- **Check A — display/read path.** Seeds a tornado/critical alert directly, asserts
  `GET /weather/alerts/active` returns it with the exact 5-key shape
  `{id,jobId,condition,severity,startedAt}` (service-key auth), that the per-job badge
  `GET /weather/job/:jobId` is populated then null, and that closing (`ended_at`) removes it.
- **Check B — engine + REAL NWS.** Finds a currently-active danger-kind NWS Warning,
  seeds a crew check-in at that coordinate, invokes the real `weatherSweep`, asserts the
  classified alert fired (kind→condition/severity), appears in the read, dedups on a second
  sweep, and closes when the crew moves to a calm coord.
- **Check C — no-false-fire.** Crew at a verified-calm arid coordinate (Phoenix/Vegas/Tucson/ABQ),
  sweep, assert zero alert rows.

Then a state-clean teardown: closes Check A's row **by captured id only** (never job_id, so a
real Field Portal job's genuine alerts are never touched), deletes sentinel check-ins + the
ephemeral service key, and asserts zero residue.

## Provenance note

The initial `.js` I wrote was replaced during an interruption by Tyler's hand-authored
`smoke-weather.mjs` — a materially better implementation (service-key read path instead of
Cognito-user churn, exact-shape assertions, real close-out via crew-to-calm, `--qualifier live`,
`skip` status, env-configurable `GT_BEARER`/`GT_BADGE_JOB_ID`). Adopted it as canonical, then
drove it to green. Only `scripts/smoke-weather.mjs` was committed; an unrelated unstaged
`GunnerForms/…/project.pbxproj` (Tyler's iOS work) was left untouched.

## Bugs found and fixed in the adopted script

### 1. FORCE-RLS blindness through the `_sql` seam (critical — would fail instantly)

`gt_weather_alerts` is FORCE-RLS. The `_sql` seam's pooled connection carries **no**
`app.current_org_id`, so:
- a plain `SELECT` **silently returns zero rows** (`org_id::text = current_setting(...,true)`
  compares against NULL → false), and
- a plain `INSERT` is **denied**: `new row violates row-level security policy` (verified live).

The adopted script did all 10 `gt_weather_alerts` ops with plain `sql()` → Check A's seed
would throw on the first statement. Fix — two helpers, using patterns proven live:

- **`alertsRead(orgId, tail)`** — reads and `INSERT … RETURNING`: a **single-statement**
  MATERIALIZED CTE that sets the GUC inline, tail references `ctx`:
  `WITH ctx AS MATERIALIZED (SELECT set_config('app.current_org_id', ORG, false)) <tail>`.
  Insert form: `INSERT … SELECT … FROM ctx RETURNING id`. Select form:
  `SELECT … FROM ctx, gt_weather_alerts WHERE …`.
- **`alertsWrite(orgId, stmt)`** — row-less UPDATEs (`ended_at` close-outs): cheaper
  `SET app.current_org_id = ORG; <stmt>` prefix.

**Why the split matters:** a multi-statement `SET …; SELECT …` / `SET …; INSERT … RETURNING`
**loses the final statement's rows** — node-pg's simple-query protocol returns an *array* of
results, and the seam's `{rows: result.rows}` is then undefined → `{}`. So anything that must
return rows MUST be the single-statement CTE form; only row-less writes can use the SET prefix.
Leak-safety: the session GUC is scoped to the pooled connection, but every real app query runs
`queryWithTenant()`'s own `BEGIN + SET LOCAL` which overrides it first — nothing leaks past the
script's own statements. Non-RLS tables (`gt_service_keys`, `gt_time_entries`) correctly stay on
plain `sql()`.

### 2. Fragile dedup assertion (race with the production cron)

Check B's dedup count filtered `ended_at IS NULL`. But the unique dedup index is
`(org_id, job_id, condition, source_alert_id)` — it does **not** include `ended_at`. The
production `weatherSweep` cron runs every 15 min and legitimately closes the sentinel alert
between the two manual sweeps (when the warning's exact-point resolution shifts), so an
open-only count flakes to 0 — a close-out, not a duplicate. Fixed to test the true index
invariant: **exactly one row ever exists for the tuple**, open or closed.

### 3. Cognito auth flow (badge sub-check)

`admin-initiate-auth --auth-flow ADMIN_USER_PASSWORD_AUTH` fails with
`InvalidParameterException: Auth flow not enabled for this client`. Pool `us-east-2_hFVBSrcnn`
client `6m41qei5jq3nt46jler56im1cg` has `ALLOW_USER_PASSWORD_AUTH` (not the admin flow). Use
`initiate-auth --client-id <id> --auth-flow USER_PASSWORD_AUTH` (client-id only, no
`--user-pool-id`). The ID token carries `custom:tenantId` + `token_use=id`, and `resolveUser`
resolves it via the seeded `users` + `user_organizations` rows.

## Reusable facts surfaced (verified live)

- **`--qualifier live` works for the `_sql` seam** (task dispatch + preflight both hit the alias).
- **`weatherSweep` daylight-ET gate is 06:00–20:00** (`getETContext`); outside it the task
  returns `{ok:true,task:'weather-sweep',skipped:'off-hours'}`. The script self-gates identically.
- **EventBridge dispatch shape:** `{source:'aws.events', detail:{task:'weather-sweep'}}` — a bare
  `{detail:{task}}` falls through to serverless-express.
- **weatherSweep Leg 1 (crew) has no `ORDER BY`** — a pre-existing real check-in on a job could
  race a fixture's coordinate. The script guards by refusing a real job that already has open
  check-ins.
- **`WARNING_DANGER` map** (evaluate.js, module-private): tornado→tornado/critical,
  severe_storm→severe_storm/critical, flood→heavy_rain/high, winter→heavy_snow/high,
  high_wind→high_wind/high. Mirrored in the script (keep in sync).
- **The "WL TEST" fixture job** (`768357f3-…`) resolves upstream via `ccFetch`, so the badge
  path returns a populated `activeAlert`; a synthetic job id 404s at `ccFetch` by design.
- **Schema types (join-mismatch trap):** `gt_time_entries.org_id/user_id` are UUID;
  `gt_weather_alerts.org_id/job_id/id` are VARCHAR. `gt_time_entries.user_id` has no FK → any
  UUID works as a sentinel crew member (no `users` row needed for the sweep query).

## Outcome

Live run at 09:05 ET (inside daylight window): Check A (exact-shape read + badge populated/null on
the real WL TEST job + close-out), Check B (real Flood Warning → `heavy_rain/high` fired, read,
dedup invariant, close-on-calm), Check C (no false fire on Phoenix), state-clean — **10/10**.
Verified zero residue across `gt_weather_alerts`, `gt_time_entries`, `gt_service_keys`, `users`.

**Limitation stated honestly:** "coordinate with Colin at a test device" is a human-in-the-loop
step that can't be performed autonomously; it's documented in the script's warning banner. The
automated A/B/C checks don't need it — the sentinel B check-in is a device-less random-UUID user,
so it generates zero extra APNs pushes. Safety of invoking prod `weatherSweep`: it already runs
every 15 min on cron; the extra invoke dedups (`ON CONFLICT DO NOTHING` / open-row check → no
double-push).
