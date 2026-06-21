---
type: synthesis
title: "Attack-Surface Reduction — cc-2123→2126 (June 2026)"
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - soc2
  - security
  - secrets
  - tenant-isolation
  - gunnerteam
  - backend
status: stable
related:
  - "[[meta/session-2026-06-20-cc2123-runtime-secrets]]"
  - "[[meta/session-2026-06-20-cc2124-db-password-runtime]]"
  - "[[meta/session-2026-06-20-cc2125-forms-auth-lockdown]]"
  - "[[meta/session-2026-06-20-cc2126-time-jobid-preflight]]"
  - "[[gunnerteam/secrets-handling-rules]]"
  - "[[gunnerteam/soc2-technical-summary]]"
---

# Attack-Surface Reduction — cc-2123 → cc-2126 (June 2026)

A four-prompt CC6.1/CC7.2 hardening block on `gunnerteam-dev-api` (us-east-2, alias `live`). Net
result: **the Lambda env holds zero secrets**, and the **last unauthenticated / un-scoped write
surfaces are closed**. Lambda version walked **v335 → v341**. Each change shipped via the standard S3
deploy → publish → alias flow with a live canary; all changes are local commits on `main` (infra
precedent, not pushed).

| Prompt | Change | Lambda | Commit | Control |
|---|---|---|---|---|
| cc-2123 | ~17 app secrets out of env → runtime SSM fetch | v337 | `6919e5b` | CC6.1 |
| cc-2124 | `DB_PASSWORD` out of env via lazy pool init | v339 | `f766dbc` | CC6.1 |
| cc-2125 | `requireAuth` + rate-limit on forms IT-request & AP | v340 | `9763fc7` | CC6.1 / CC7.2 |
| cc-2126 | org-ownership preflight on client `jobId` (time.js) | v341 | `e607ae2` | CC6.1 |

---

## The two themes

### 1. Secret-surface elimination (cc-2123 + cc-2124)
Secrets were baked into the Lambda environment, where `lambda:GetFunctionConfiguration` exposed them —
the incident class. Now **every** secret is an SSM SecureString under `/gunnerteam/dev/`, fetched once
per container and cached:
- `lib/secrets.js`: `loadSecrets()` (one memoized `GetParametersByPath`), `getSecretSync()`
  (drop-in for `process.env`, valid after the load `lambda.js` does at the top of every invocation),
  `getSecret()` (async, fail-loud).
- `lib/db.js`: the pg `Pool` is built lazily by `getPool()` → `getSecret('DB_PASSWORD')` on first use
  (the hard one — it used to build at module load), with the exported `pool` kept as a
  backward-compatible `{connect,query}` facade so ~10 callers were untouched.
- Canonical procedure now lives in [[gunnerteam/secrets-handling-rules]]: new secret → SSM SecureString
  + `getSecretSync`; never add it to `lambda-api.tf` env.

### 2. Closing un-authed / un-scoped writes (cc-2125 + cc-2126)
- **cc-2125** — `POST /` (IT request) and `POST /submit-ap` had no `requireAuth`, no limiter, and AP
  had no audit. Added `requireAuth` + a distributed `formsLimiter` + full `forms.submitted` audit.
  Required a coordinated iOS fix (the create payloads sent `requiresAuth: false`); also surfaced a
  latent bug — `/submit-co` was already backend-gated while the app sent no token, so online Change
  Orders were 401ing. All five forms now match their backends.
- **cc-2126** — `POST /time/checkin` stored a client `jobId` in org-scoped tables AND forwarded it to
  Field Portal with no org check. Added the proven `fieldportal.js` org-verify preflight
  (`ccFetch GET /projects/:jobId` → 404 on miss, fail-closed) before any write/proxy, and extracted a
  single shared FP client (`lib/fieldPortalClient.js`).

---

## Reusable patterns established

- **Runtime secrets:** `getSecretSync` is safe anywhere because `lambda.js` awaits `loadSecrets()` at
  the top of every invocation; module-load secret/DB reads must become lazy (see `getPool`).
- **Org-ownership preflight:** any client-supplied resource ID (jobId/taskId/itemId) gets
  `ccFetch(GET /projects/:id).catch(()=>null); if(!x) 404` before a write or upstream proxy — fail
  closed, never leak existence (enforces the CLAUDE.md rule).
- **Single Field-Portal client:** `lib/fieldPortalClient.js` is the one `ccFetch`; both `fieldportal.js`
  and `time.js` import it.
- **iOS forms auth contract:** create payloads must set `FormSubmitPayload(requiresAuth: true)` — the
  outbox executor attaches the Cognito Bearer only then.

## Deploy / verification conventions reused
- Canary BEFORE alias for risky changes: publish a version, exercise it via
  `aws lambda invoke --qualifier <v>` (the migration probe is the DB/secrets canary — `ok:true` proves
  `loadSecrets`+IAM+`getSecret`+DB), then flip the alias; rollback = re-alias the prior version.
- Propagation lag (cc-2119) recurs: warm old-version containers serve new behavior for ~45–75s after an
  alias flip — confirm the per-request `[version]` and re-test; use side-effect-free probes (empty
  bodies) so a stale version can't mutate data.

## Honest limitations (carried across the block)
- Authed end-to-end paths (forms create, checkin 200/404) weren't exercised live — no Cognito RS256
  token to forge; verified by construction + parity with proven siblings.
- **cc-2126 tradeoff (prompt-accepted fail-closed):** check-in now requires Field Portal reachable
  (FP down → 404, not the old succeed-with-fire-and-forget). Bounded ~5s.
- iOS builds not re-run for the cc-2125 bool-flip edits (compile-safe).

## Out of scope / flagged forward
- The real tenant-isolation backstop — a `NOSUPERUSER`/`NOBYPASSRLS` app DB role + the RLS-vs-app
  scoping decision — lives partly in the `gunner-masterdb` SST stack (Colin); pre-second-tenant gate.
- DB topology: dev Lambda → `gunnerteam-dev-masterdb-proxy` → the PRODUCTION Aurora cluster (shared,
  SST/Pulumi-owned). True dev/prod split is a go-live task.
- Dead unreferenced `variable "db_password"` + tfvars line remain (harmless, pre-existing).
