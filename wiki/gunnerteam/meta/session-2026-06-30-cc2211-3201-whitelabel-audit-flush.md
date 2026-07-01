---
type: session
title: session-2026-06-30-cc2211-3201-whitelabel-audit-flush
created: '2026-06-30'
updated: '2026-06-30'
tags:
  - gunnerteam
  - backend
  - white-label
  - audit
  - soc2
  - lambda
  - deploy
  - masterdb
status: stable
related:
  - '[[gunnerteam/brand-colors]]'
  - '[[gunnerteam/dialpad-hubspot-integration]]'
  - '[[gunnerteam/aws-environment]]'
  - '[[tyler/meta/session-2026-06-29-cc2820-3002-comms-admin-full-stack]]'
  - '[[gunnerteam/meta/session-2026-06-21-cc2201-keepwarm-db-connection]]'
---

# Session cc-2211 / cc-2212 / cc-3201 — white-label copy de-hardcode + audit flush-before-freeze (v418→v421)

Four work items on `gunnerteam-api`: a read-only masterdb topology investigation (comms_admin_ro
placement), two white-label passes removing hardcoded "Gunner Team" from customer-facing copy
(v418, v420), and the CC7.2 audit-write-timeout fix (v421). All committed to `origin/main`
(deploys are the working tree; drift-closed 0/0 each time).

## comms_admin_ro topology investigation (read-only — the STEP-0 provision was correctly refused)

A runbook (`cc-prompt-comms-admin-step0`) asked to provision a read-only `comms_admin_ro` role on
**prod** masterdb by grafting `db/migrate.py` into a "dev-named Lambda that points at prod" and
invoking `provision_comms_admin_ro_role`. The action code (`gunner-masterdb` @ `7a32e04`,
`db/migrate.py:208`) was verified safe: bare `CREATE ROLE comms_admin_ro LOGIN` (no ALTER of
SUPERUSER/BYPASSRLS — Aurora blocks that for rds_superuser, cc-2150), SELECT-verify of
`rolsuper`/`rolbypassrls` with refusal on privilege, org-id asserted `== 69aad261…` (refuses the
`7d6db1bb` decoy), server-side `format(%L)` password, RO grants + audit_log INSERT.

**The provision was NOT run — the G2 target gate failed twice, correctly.** The runbook's premise
("the dev-named Lambda points at prod") was false for the function it named:

- `gunner-masterd-dev-MasterApi2RouteBbovcaHandlerFunction-wssoombt` → `DATABASE_URL` host
  `gunner-masterdb-dev-masterdbcluster-kdsmbssw` = `cluster-C2HJZGYLUKBS4FIVHVR2X6BKAQ` = the **DEV**
  cluster. Not `sczazkvf`. STOP per the gate's own "traces to another cluster → wrong target" rule.

A follow-up **topology verification** (strictly `describe-*`/`list-*`/`get-*`, one rejected
read-only invoke, no mutations) resolved where the data actually lives:

- **Q1 — `gunnerteam-dev-masterdb-proxy` fronts PROD.** Its targets are
  `gunner-masterdb-production-masterdbcluster-sczazkvf` (+ 2 prod instances). The **dev-named proxy
  fronts the prod cluster** — this is the load-bearing gotcha (matches cc-2111/cc-2147).
- **Q2 — a prod-connected masterdb Lambda DOES exist:**
  `gunner--production-MasterApi2RouteBbovcaHandlerFunction-bedubsdv` → `DATABASE_URL` = the prod
  `sczazkvf` cluster directly. It was missed by an earlier `contains(FunctionName,'masterd')`
  lowercase filter (its name is `MasterApi`, capital M). `gunner-ops-dev-api` also → prod. So the
  "prod is CloudShell-only (cc-2913)" assumption is wrong; a Lambda migrate path to prod exists.
- **Q3 — inconclusive read-only:** the dev migrate Lambda's live handler is `api/main.handler`
  (Mangum FastAPI); an `{"action":…}` payload is rejected by Mangum. Reaching
  `list_databases_and_gt_tables` needs a handler swap = mutation, out of scope.
- **Q4 — dp_* data lives on PROD.** The Dialpad `dp_*` writer is **gunnerteam-api**
  (`src/routes/dialpad.js` INSERTs `dp_sms_messages`/`dp_calls`/`dp_agents`/`dp_events`), deployed
  as `gunnerteam-dev-api`, which connects via `DB_HOST=gunnerteam-dev-masterdb-proxy` (db
  `gunner_masterdb`, role `gunnerteam_app`) → per Q1 that proxy fronts prod `sczazkvf`.
- **Q5 — both clusters `StorageEncrypted=True`.**

**Conclusion: `comms_admin_ro` belongs on PROD (`sczazkvf` / `cluster-7WBH4MF4THJ46CNTCPOALVB3UI`),
not dev.** The viewer reads the `dp_*` feed which is written to prod. Recommended provision target
= the prod Lambda `…bedubsdv` (verify its bundled `db/migrate.py` carries the action first) OR
CloudShell self-serve against `sczazkvf`. Not provisioned in this session — reported target only.
Note: connecting as `comms_admin_ro` also needs an RDS Proxy `auths` entry (windowed, Tyler-driven)
before it can reach the DB.

### Cluster map (us-east-2, profile mfa)
| Cluster | DbClusterResourceId | Role |
|---|---|---|
| `gunner-masterdb-production-masterdbcluster-sczazkvf` | `cluster-7WBH4MF4THJ46CNTCPOALVB3UI` | PROD — all gt_/dp_ data; fronted by `gunnerteam-dev-masterdb-proxy` |
| `gunner-masterdb-dev-masterdbcluster-kdsmbssw` | `cluster-C2HJZGYLUKBS4FIVHVR2X6BKAQ` | DEV — masterdb migrate Lambda target |
| `dev-gunner-aurorapgdb-db-cluster` | `cluster-EIUZBUKG2HJI2IAE4MUKHZ72KA` | unrelated |

## cc-2211 — de-hardcode invite email + join push (white-label) — v418

Outbound auth copy hardcoded the product name, violating the white-label rule (org name resolves
per request from `gt_org_theme`/`organizations.name`). Reused the **existing** `resolveOrgName(orgId)`
helper (`src/lib/assistant-tasks.js`) rather than adding a second — extended it to prefer
`gt_org_theme.config->>'brand'`/`'name'`, else `organizations.name`, else `'your company'`, via one
LEFT JOIN (per-container cache kept).

- `POST /auth/invite`: subject `You're invited to ${orgName}`, body `…added to <strong>${orgName}</strong>…`
  (orgName from `req.orgId`).
- `POST /auth/complete-invite` admin push: `${displayName} has joined ${orgName}.` (orgName from
  `inv.org_id`→`orgId`). complete-invite is push-only (no email).
- Left `a.slug='gunner-team'` (internal identifier) untouched.

**Null-theme fallback is structurally guaranteed:** `PATCH /org/theme` only accepts 8 hex-color keys
(`ALLOWED_KEYS`), so `config->>'brand'`/`'name'` are always NULL → COALESCE resolves to
`organizations.name`. For the real Gunner org (`69aad261`, slug `gunnerroofing`) that = "Gunner
Roofing". Tests: `test/assistant-tasks.test.js` 5/5 (Tester agent) — null guard, row name,
empty-rows fallback, cache, error fallback.

## cc-2212 — remaining customer-facing copy (reset email, shared FROM/title, deep-link pages) — v420

- `src/lib/email.js`: split `FROM` into `FROM_ADDRESS` + `DEFAULT_FROM_NAME` (`'Gunner Team'`); added
  `buildFrom(name)` — RFC 5322 From header, **strips CR/LF/`"`/`<>` (header-injection safety)**,
  quotes the name, falls back to default. `sendEmail` gained optional `fromName`; `deepLinkPage`
  gained optional `brandName` (the `<title>`). Internal `sendAlertEmail`/`sendFormEmail` repointed to
  `buildFrom()` — unchanged `"Gunner Team"` default, non-breaking.
- `src/routes/auth.js`: invite passes `fromName: orgName`; forgot-password resolves `orgName` from the
  user's `org_id` and uses it in subject/body/fromName.
- `src/app.js`: `/invite` made async → looks up `invite_tokens.org_id` → `resolveOrgName` → branded
  title + `set up your ${orgName} account` (neutral `your account` fallback). `/reset` query extended
  to return `org_id`, same treatment; expired-link page → neutral `from the app`. (`invite_tokens`/
  `reset_tokens` are non-RLS, readable via the plain `query` pool.)
- Tests: `test/email.test.js` 10/10 (Tester agent) — buildFrom normal/falsy/whitespace/injection.

**Left as-is (out of scope):** `[GunnerTeam Alert]` monitoring subjects (internal), `gunnerteam://`
URL scheme, `GunnerTeam API` log string, removed-endpoint message (auth.js:65), `DEFAULT_FROM_NAME`.

## cc-3201 — audit flush-before-freeze via AsyncLocalStorage — v421 (SOC 2 CC7.2)

Root cause of `[Audit] write failed: Query read timeout`: fire-and-forget `audit()` writes were
**suspended when the async Lambda handler froze the container on promise-resolve** (proven by
`dialpad.sms.received ms=125745`, 16× the 8s timeout; cluster idle — not capacity). This is the
"Lambda freeze — await all async before the handler resolves" rule biting fire-and-forget audit.

Fix — bind a per-request audit queue via `AsyncLocalStorage` and flush before the handler returns:

- **`src/lib/audit-context.js` (new):** `enqueueAudit(promise)` registers an in-flight write with the
  current request (returns `false` with no context → detached write = pre-3201 behavior).
  `runWithAuditContext(fn)` runs `fn` then, in `finally`, flushes `store.pending` before resolving,
  **bounded by `AUDIT_FLUSH_TIMEOUT_MS` (default 2500)** via `Promise.race([allSettled, timeout])`
  (API Gateway buffers the response, so an unbounded flush would hold the client response open; a
  write still running at the cap is left detached and surfaces via the enriched log). Flush never
  throws.
- **`src/lib/audit.js` (full replace):** split into `writeAudit` (never rejects — logs+swallows) +
  `audit(opts)` (starts the write, `enqueueAudit`s it, returns the promise). Public API `{ audit }`
  and the `audit({...})` call signature unchanged, so all ~120 callers (both `await audit(...)` and
  fire-and-forget `audit(...).catch()`) are unaffected. The enriched failure log
  (`action=…path=…ms=…`) is retained.
- **`src/lambda.js`:** wrapped the **entire dispatch** (`aws.events`/SNS/`_migration`/`_sql`/`_task`/
  final `cachedHandler`) in `runWithAuditContext`, so both HTTP and scheduled paths flush before
  freeze — capturing req-less in-handler calls like `dialpad.js:288` (`dialpad.sms.received`) that a
  "flush only when req present" design would miss. `keepWarm` returns before the wrapper (unchanged).
- Tests: `test/audit-context.test.js` 7/7 (Tester agent) — no-context→false, in-context→true,
  return-value passthrough, flush-waits, bounded-cap (slow write detached), rejection absorbed,
  fn-throw flushes+propagates. All suites together: **22/22**.

**Validation is forward-looking.** Pre-fix baseline (24h `[Audit] write failed`/hr): off-peak 1–14,
business-hours peaks **20–65** (14:00 UTC = 65) — the diurnal `Query read timeout` stream. Post-flip
(v421, off-peak) confirmed control-flow intact: HTTP dispatch through the wrapper → `200`, keepWarm →
`warm`, zero handler errors/timeouts. The failure-rate drop must be confirmed during the next
12:00–21:00 UTC window with:
```
fields @timestamp, @message | filter @message like /\[Audit\] write failed/ | stats count() as fails by bin(1h)
```
Any residual = genuinely slow writes exceeding the 2500ms cap (inspect `ms=`), not frozen ones.
**Follow-up:** once clean, lower `AUDIT_WRITE_TIMEOUT_MS` from the band-aid 8000 back toward the
standard query budget (the flush cap needs no terraform change — it defaults in code).

## Deploy / git discipline

Each cc-prompt: full S3 deploy block (`gunnerteam-lambda-deploy-useast2` → `update-function-code` →
`wait` → `publish-version` → `update-alias live`), serving version confirmed via direct alias invoke
(`ExecutedVersion`), then commit **only the touched files** (leaving unrelated iOS/package/fieldportal
WIP unstaged) and `git push origin main` to close deployed-not-in-git drift (0/0 after each).
Commits: `de4965a` (cc-2211), `1e7ae8a` (cc-2212), `48fe55b` (cc-3201). Versions v418 → v420 → v421.

## Key facts / gotchas
- **`gunnerteam-dev-masterdb-proxy` (dev-named) fronts the PROD `sczazkvf` cluster** — the dp_* /
  gt_ data all lives on prod (cc-2111/cc-2147 confirmed again).
- **Prod masterdb migrate Lambda = `gunner--production-MasterApi2RouteBbovcaHandlerFunction-bedubsdv`**
  (capital `MasterApi`; a `masterd` lowercase filter misses it). The `…wssoombt` "dev" function
  targets the DEV cluster.
- `resolveOrgName(orgId)` (`lib/assistant-tasks.js`) is the shared white-label name resolver:
  `gt_org_theme` brand/name → `organizations.name` → `'your company'`, per-container cached.
- `gt_org_theme.config` is colors-only today (8 hex keys enforced by `PATCH /org/theme`) — brand
  override is future-proofing; today it always falls back to `organizations.name`.
- AsyncLocalStorage flush pattern (`runWithAuditContext` in `lambda.js`) is the general fix for any
  fire-and-forget async that must complete before the Lambda freeze; bounded by an env cap so it
  never holds the buffered API Gateway response open.
