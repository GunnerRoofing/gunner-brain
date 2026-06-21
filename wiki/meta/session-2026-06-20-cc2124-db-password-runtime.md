---
type: session
title: session-2026-06-20-cc2124-db-password-runtime
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - backend
  - security
  - soc2
  - secrets
  - ssm
  - database
  - deploy
status: stable
related:
  - '[[meta/session-2026-06-20-cc2123-runtime-secrets]]'
  - '[[gunnerteam/soc2-technical-summary]]'
  - '[[gunnerteam/aws-environment]]'
---

# Session cc-prompt-2124 — `DB_PASSWORD` out of the Lambda env via lazy pool init (CC6.1) — v339

The last secret in the Lambda env, and the careful one. After this + cc-2123, the Lambda env is
**secret-free** (0 secrets). Commit `f766dbc`, deployed **v339** (rollback target v337).

## Why it was hard
`lib/db.js` built the pg `Pool` at **module-load** from `process.env.DB_PASSWORD` — before any async
secret fetch could run. Plus proxy-secret-drift history: SSM `DB_PASSWORD` must equal the RDS Proxy's
Secrets Manager secret, and mismatches have caused outages. So this was done alone, after cc-2123 was
verified, with a publish-and-test-before-alias deploy.

## db.js change (lazy, memoized pool)
- Replaced the module-load `new Pool({... password: process.env.DB_PASSWORD ...})` with a memoized
  async `getPool()`: on first call `await getSecret('DB_PASSWORD')` (cc-2123 loader, cached per
  container), build the `Pool` once via `buildPoolConfig(password)`, cache it; reset `_poolPromise`
  on failure so the next call retries.
- `connect()` routes through `await getPool()`.
- **The exported `pool` is kept as a backward-compatible lazy facade**
  `{ connect: () => getPool().then(p => p.connect()), query: (...a) => getPool().then(p => p.query(...a)) }`
  — so all ~10 direct callers (`pool.connect()` ×9 across audit/lambda-migration/auth/fieldportal/
  points-webhook/points/users/fleet/hubspot; `pool.query()` ×1 in fleet/index.js:1467) are
  UNCHANGED. The prompt scoped edits to `db.js` + `lambda-api.tf` only; the facade honors that.
- Unchanged: `ssl {ca: rdsBundle+rootCertificates, rejectUnauthorized:true}` (cc-2102), all timeouts,
  RDS-Proxy detection, `max`, exports surface. Only the password source + init timing move.
- Grep confirmed no top-level pool usage (all `pool.connect`/`pool.query` are inside functions) →
  lazy init can't miss a module-load call. `node --check` OK.

## No drift
`getSecret('DB_PASSWORD')` reads the SAME `/gunnerteam/dev/DB_PASSWORD` SSM SecureString param that
Terraform used to bake into the env (verified present: SecureString, 32 chars). Delivery moves
env→runtime; the value is untouched; the SSM-vs-proxy-secret invariant is unchanged.

## TF (`lambda-api.tf`)
Removed the `DB_PASSWORD = data.aws_ssm_parameter.db_password.value` env line + the now-unreferenced
`data "aws_ssm_parameter" "db_password"` source. Kept `DB_HOST/PORT/NAME/USER` (config). Targeted
plan = `0 add / 1 change / 0 destroy` — only `DB_PASSWORD → null`, 26 other env vars untouched.
`var.db_password` is an unreferenced pre-existing dead var (env used the data source, not the var) →
left alone (out of file scope), flagged for opportunistic cleanup.

## Careful deploy (publish + test BEFORE alias)
1. `terraform apply -target=api` → env removed from `$LATEST` (alias still v337, live safe).
2. S3 deploy db.js → `update-function-code` → wait.
3. `publish-version` → **v339** (alias still v337).
4. **Canary on v339 via `aws lambda invoke --qualifier 339`** (migration probe): `ok:true` — the lazy
   pool built from the runtime-fetched password, TLS-connected, ran the SQL, on the NEW version while
   live traffic stayed on v337. v339 env confirmed 0 DB_PASSWORD.
5. Only then flipped alias `live → v339` (RC env-var routing-config; rollback target v337).

## Live verification
- `/health` 200; serving v339 (log-stream `[339]`).
- migration probe via `--qualifier live` → `ok:true` (live version really connects to Aurora over TLS
  with the runtime password).
- **live env = 0 DB_PASSWORD + 0 secrets total** (the env is now secret-free).
- Log scan (6 min + 3 min): no `db.connect`/`password authentication`/`ECONNREFUSED`/`ETIMEDOUT`/TLS/
  `secrets] missing` errors. Only benign `NodeVersionSupportWarning` (AWS SDK v3 node20→22) on cold
  starts. No rollback.

## Reusable / follow-ups
- The Lambda env now holds ZERO secrets. New secret → SSM SecureString under `/gunnerteam/dev/`, read
  via `getSecret`/`getSecretSync`; never add to `lambda-api.tf` env.
- ⚠️ SSM `DB_PASSWORD` ↔ RDS Proxy Secrets Manager secret must stay equal (drift = outage). **Future
  option:** read the password directly from the proxy's Secrets Manager secret so drift is
  structurally impossible.
- Dead unreferenced `variable "db_password"` + its tfvars line remain (harmless) — clean up later.
