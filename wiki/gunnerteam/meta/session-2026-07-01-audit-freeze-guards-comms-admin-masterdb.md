---
type: session
title: "Session 2026-07-01 — audit-write-timeout re-diagnosis, invite/receipt guards, comms-admin reconcile+merge, masterdb migrate pipeline"
created: 2026-07-01
updated: 2026-07-01
owner: gunnerteam
status: stable
tags:
  - session
  - gunnerteam-api
  - comms-admin
  - masterdb
  - soc2
  - audit
  - lambda-freeze
  - sst
related:
  - "[[gunnerteam/meta/session-2026-06-30-cc2211-3201-whitelabel-audit-flush]]"
  - "[[gunnerteam/meta/session-2026-06-30-cc3101-3103-weather-danger-engine]]"
  - "[[tyler/meta/session-2026-07-01-cc06-cc10-comms-admin-dynamic-verify-fixes]]"
  - "[[tyler/meta/session-2026-06-30-cc08-09-comms-admin-tls-packaging]]"
  - "[[shared/rds-proxy-tls-and-sst-python-packaging]]"
  - "[[gunnerteam/aws-environment]]"
---

# Session 2026-07-01 — audit freeze re-diagnosis · invite/receipt guards · comms-admin reconcile+merge · masterdb migrate pipeline

Ten task prompts across four repos: `gunnerteam-api`, `gunner-ios`, `gunner-comms-admin`, `gunner-masterdb`. The single most valuable output is the **audit-write-timeout root-cause correction** (below) — it overturns a capacity hypothesis with hard metric evidence.

---

## Headline: audit-write-timeout is container-freeze, NOT cluster capacity (cc-3200 + RDS metrics)

**cc-3200** enriched the `[Audit] write failed` log line in `gunnerteam-api/src/lib/audit.js` — diagnostic only, no behavior change to the write path / 8s `AUDIT_WRITE_TIMEOUT_MS` / non-blocking swallow. Added a `t0 = Date.now()` and rewrote the catch line to:

```js
const path = req?.originalUrl || req?.path || '-';
console.error(`[Audit] write failed action=${action} path=${path} ms=${Date.now() - t0}: ${err.message}`);
```

Deployed **v419**. Log-hygiene gate passed (no forbidden field matches). The first *real* post-deploy failure line settled the diagnosis:

```
[Audit] write failed action=dialpad.sms.received path=- ms=125745: Query read timeout
```

**`ms=125745` (125.7 s) against an 8 s query_timeout = 16×.** A query cannot exceed its own timeout; the only mechanism is the container being **frozen** between dispatch and when the `setTimeout`-based `query_timeout` finally fires on thaw. `dialpad.sms.received` is a **fire-and-forget webhook** (`dialpad.js:288`, `.catch(()=>{})`, no `req` → `path=-`).

### The metric evidence (read-only, prod cluster `gunner-masterdb-production-masterdbcluster-sczazkvf`, behind `gunnerteam-dev-masterdb-proxy`)

Window 20:00–22:30 UTC covering 317 failures/24h:

| Signal | Value | Reads as |
|---|---|---|
| ACUUtilization | flat **25.0%** (= 2.0/8.0 ACU floor) | never scaled — 4× idle headroom |
| CPUUtilization | 5–9% | idle |
| DatabaseConnections | 14 max / 8 avg | pool fine |
| Proxy BorrowLatency | ~40 µs typ, 55 ms peak | no starvation |
| WriteLatency | ~0.3 ms max | landed writes instant |
| Deadlocks | 0 | no lock cycles |

**The cluster was idle while 317 INSERTs blew an 8 s timeout.** Not capacity. Performance Insights is **disabled** on both prod instances (can't read `Lock:*` waits directly), but the failure distribution is a **continuous diurnal/business-hours curve** (2026-06-29 23:10 → 2026-06-30 22:55 UTC; peaks 8–10 per 5-min at 14:35–14:55 and 17:45 UTC), **not a burst** — including a post-deploy failure at 22:58Z.

### Correction of a prior hypothesis (recorded honestly)
An interim "burst ending 22:00:06Z → shared-cluster capacity (Colin/Track B)" read was an artifact of a `sort desc | limit 20` query showing the *top* of a continuous stream. The metrics **refute capacity** and **vindicate the original freeze diagnosis** (see [[gunnerteam/meta/session-2026-06-30-cc2211-3201-whitelabel-audit-flush]] — cc-3201 flush-before-freeze). **Track B / Colin is closed for this failure population.**

### Design gap this surfaces for cc-3201
The dominant failing action `dialpad.sms.received` is fire-and-forget **inside** an Express handler but passes **no `req`** (`dialpad.js:288` uses `orgId: ORG_ID`). A queue keyed on "`audit()` enqueues when `req` is present" would **miss the top offender**. The fix must bind the queue to the request via **`AsyncLocalStorage`** (capture every `audit()` in-request regardless of whether `req` was passed) — which is exactly the mechanism cc-3201 already landed. Only genuinely out-of-request callers (scheduler, SNS) fall through to a direct awaited write.

---

## gunnerteam-api authorization hardening

### cc-1200 — admin **and** manager may invite subcontractors
`src/routes/auth.js` `POST /auth/invite`: split the single admin-only gate into two — inviting `admin`/`manager` stays admin-only; inviting `subcontractor` now allowed for admin **or** manager; inviting `user` unchanged. Manager inviter stays org-scoped by token exactly like admin. I/O-free test suite `test/invite-auth.test.js` (harness = `finalHandler`+`fakeRes`; the crewId-missing 400 proves the auth gate cleared without DB/email). Deployed **v425**. Commit `e02f307`.

### cc-1201 — deny subcontractors on receipt routes
`/fieldportal` is subcontractor-allowed for jobs/photos, but the receipt endpoints are a **financial write path** (persist `gt_receipts` + push cost lines to Colin P&L). Added `if (req.user.role === 'subcontractor') return res.status(403)...` as the **first statement** of both `POST /jobs/:jobId/receipt/extract` and `.../receipt/commit`. I/O-free `test/receipt-guard.test.js` (sub→403 both, manager→400-not-403). Deployed **v426**. Commit `db89ba9`.

Full unit suite **189/48** — i.e. 185→189 gunnerteam-api tests green after the two new suites; comms-admin 48/48 separately.

**Deploy hygiene:** the working tree carried an unrelated `package.json`/`package-lock.json` drift declaring `@aws-sdk/client-cloudwatch` — already installed and `require`d by `scheduler.js:7`, inert, and `node_modules` ships identically regardless. Left uncommitted for its owner; shipped only `main + my source file` each deploy.

**Honest boundary (both cc-1200/1201):** live role-token checks (manager-200/user-403, sub-403) were NOT exercised — `requireAuth` verifies an unforgeable Cognito RS256 signature then resolves role from the shared prod masterdb; manufacturing tokens = resetting a real user's Cognito password or seeding the change-controlled prod DB. Not done. Gate logic proven by unit suites; deploy + auth wiring proven live (401 no-token / invalid-token).

---

## gunner-ios — cc-3105 severe-weather danger badge
New `Jobs/Weather/WeatherDangerModels.swift` (+`WeatherDangerBadge.swift`): a "⚠️ Severe weather — <condition>" badge shows on the job detail screen **only** while `GET /weather/job/:jobId` returns `activeAlert != null` (cc-3103 contract), renders nothing otherwise/on load error (fail quiet). Tap → safety sheet with condition-specific line. Critical (tornado/severe_storm) = `themeManager.theme.destructive` + heavier weight + outline; high = `warning`. `weather.danger` push (`type:"weather"`) routes to the job via `AuthManager.pendingWeatherJobId` → `ContentView` switches to Jobs tab → `JobsTabRoot` resolves jobId→FPJob (preload bundle, jobs-list fallback) → pushes `JobDetailView`. **BUILD SUCCEEDED** (iPhone 17 sim); 15/15 decode+severity logic checks pass. Committed to `main` (`024bc7f`) — 7 files only; synchronized Xcode file group auto-included the new dir (no `project.pbxproj` edit). Critical APNs interruption-level is server/entitlement-driven — app holds only `aps-environment`, so no dead client code added.

> ⚠️ **SECURITY FLAG:** the `gunner-ios` monorepo `origin` remote URL has a **GitHub PAT embedded in plaintext** in `.git/config` (`https://github_pat_…@github.com/...`), printed by `git remote -v`. Recommend rotating it and switching to osxkeychain credential helper or SSH. Value not copied/reused.

---

## gunner-comms-admin (cc-10 → cc-12) — backup, reconcile, deploy, merge

- **GitHub backup:** created empty private `GunnerRoofing/gunner-comms-admin` (via `gh`, org-admin), pushed both branches (`main` + `cc-08-db-tls-verify-ca`). `.gitignore` hardened (`resource.enc`, `sst.pyi`, `sst-env.d.ts`, `tsconfig.tsbuildinfo`, `.DS_Store`); root `package-lock.json` tracked (root `package.json` exists). *(Note: prompt assumed `gh` unavailable — it was actually installed/authed as `tylersuffern`, org admin; created the repo directly rather than block.)*
- **cc-10:** committed the cc-06 fixes (`05ccea4`) — server-side MFA via `admin_get_user`, `audit_log` INSERT `id`(uuid4)+real `users.id` FK, IAM (`AdminGetUser`, scoped `PutMetricData`). pytest **48/48** (built ephemeral py3.12 `[test]` venv — root `.venv` is SST-only py3.14). *(This commit appeared via a parallel actor in the shared repo mid-`git add`; verified content rather than duplicating.)*
- **cc-11:** the `sst deploy` blocker was **pulumi-aws #4471** — the `Bucket→BucketV2` alias state-read regression ("`missing expected [`"), present in **6.66.2/6.66.3**, fixed in **v6.79.0** (PR #5476, adds `TransformFromState` migrating singular→plural bucket props). Pinned `aws: { version: "6.79.0" }` in `sst.config.ts` (nearest clean forward). `AWS_PROFILE=mfa npx sst deploy --stage dev` **completed clean** — `BucketV2` Updated, buggy `default_6_66_2` provider deleted. `/health` `db:ok` ×3. Reconcile proof: live 401×5 → `AuthFailure401 Sum=5` in `GunnerCommsAdmin` namespace (proves committed emitter code + `PutMetricData` IAM shipped via SST); live role inline policy == committed `sst.config.ts` verbatim (no `put-role-policy` drift). Commit `39ff0c3`.
- **cc-12:** `git merge --no-ff cc-08-db-tls-verify-ca` → main (`4e5d5c6`), pushed `origin/main`; `main..branch` empty (fully merged); branch left in place. Canonical history for SOC 2 CC8.1.

**403 `mfa_required` not exercised live** — needs a real Cognito token for a non-MFA-enrolled admin (prod mutation); proven at every reachable layer (shared PutMetricData path, live AdminGetUser IAM, shipped `require_admin` logic, 48/48 units).

---

## gunner-masterdb (cc-2922, cc-2923) — migrate pipeline, reviewable diffs only

- **cc-2922:** new Alembic revision `v1_provision_masterdb_migrate.py` chained onto the single head `u1_merge_weather_crm` (migration-graph = exactly 1 head). Creates `masterdb_migrate` `LOGIN NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE` — **BYPASSRLS is not grantable on this Aurora cluster** (no superuser to confer it, cc-2150), so cross-tenant/seed migrations use the in-txn `NO FORCE`→re-`FORCE` toggle or stay a master exception. Member of `gunnerteam_app, ops_app, crm_app`; `USAGE,CREATE ON public`; DML on `alembic_version`. Idempotent; role-creating revision itself runs via the MASTER path (documented exception). Added `_set_masterdb_migrate_password` (`format(%L)` server-side quoting) + handler action. PR #22, CI green.
- **cc-2923:** `sst.config.ts` production-gated migrate Lambda (`db/migrate.handler`, in-VPC, connects DIRECT as `masterdb_migrate`) + GitHub OIDC provider + `gha-masterdb-migrate` role trust-scoped to the exact `migrate-prod.yml@refs/heads/main` workflow ref, least-priv `lambda:InvokeFunction`-only. Free-path `migrate-prod.yml` (manual `workflow_dispatch`, operator types `apply`, `concurrency: migrate-prod`, `<PLACEHOLDER>` ARNs inert until deploy). CONTRIBUTING §2/§7 corrected. **Draft PR #23, CI green. NOT deployed** — Colin runs the watched prod-stage `sst deploy` (needs a no-op `sst diff`) and fills placeholders from stack outputs.

---

## Reusable facts (promote if referenced again)
- **pulumi-aws `BucketV2` "missing expected [" → pin ≥ 6.79.0** (fix PR #5476 for #4471). SST 3.19.3 defaults to the buggy 6.66.2. Pin via `providers.aws.version`.
- **Lambda fire-and-forget freeze signature:** `[Audit] write failed ... ms=<big> : Query read timeout` where `ms` ≫ the timeout = container frozen post-response, timer fires on thaw. Idle cluster + huge `ms` = freeze, not capacity. Fix = flush in-flight side effects before the handler promise resolves (`AsyncLocalStorage` queue), or `await` them.
- **`resolveUser` derives role from the DB, not JWT claims** — so live role-gated verification needs both a signed Cognito token AND a seeded prod row; not manufacturable without a prod mutation.

## Version / commit ledger
- gunnerteam-api Lambda: **v419** (cc-3200) → **v425** (cc-1200) → **v426** (cc-1201), alias `live`. Commits `e02f307`, `db89ba9` on `main`.
- gunner-ios: commit `024bc7f` on `main`.
- gunner-comms-admin: `05ccea4` (cc-06/cc-10), `39ff0c3` (cc-11 pin), merge `4e5d5c6` (cc-12) on `main`; provider `aws@6.79.0`; dev stage deploys clean.
- gunner-masterdb: PR #22 (cc-2922, mergeable), draft PR #23 (cc-2923, not deployed).
