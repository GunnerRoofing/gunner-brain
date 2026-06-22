---
type: session
title: session-2026-06-21-cc2201-keepwarm-db-connection
created: '2026-06-21'
updated: '2026-06-21'
tags:
  - gunnerteam
  - backend
  - reliability
  - rds-proxy
  - lambda
  - deploy
status: stable
related:
  - '[[gunnerteam/aws-environment]]'
  - '[[meta/session-2026-06-20-cc2124-db-password-runtime]]'
---

# Session cc-prompt-2201 — kill sparse cold-path apigw-5xx (DB pool idles out between keep-warm pings) — v346

Sparse single 5xx spikes (`gunnerteam-dev-apigw-5xx` / `lambda-errors`), self-resolving ~4 min,
clustering overnight. Commit `665fdc9`, deployed **v346** (rollback v344).

## Phase 0 gate (confirmed before any code change)
3-day Logs Insights on `/aws/lambda/gunnerteam-dev-api`: 5xx dominated by
`[timing] db.connect failed ms≈5005 error=Connection terminated due to connection timeout` →
`POST /validate 503 ms≈5007`, `auth.resolveUser` / `forgot-password` 500s, and cold scheduled-task
(`Overdue inspection` / `Maintenance check`) failures. The `ms` cluster at **~5000 = the env
`DB_CONNECT_TIMEOUT_MS=5000`** (env overrides the 3000 code default). Matches "Connection terminated
due to connection timeout / TimeoutError" — not a route/logic error → proceed. (The high-ms
`location-ping forward failed timeoutMs=10000` lines are swallowed Field-Portal-upstream best-effort
timeouts, unrelated to the apigw-5xx.)

## Root cause
`keep_warm` (eventbridge.tf, `rate(5min)`, `{keepWarm:true}`) kept the container alive, but the
`keepWarm` branch returned **before any DB use**, while `db.js idleTimeoutMillis` was 30s. So the
pooled RDS-Proxy connection died ~30s after each real request and the ping never refreshed it →
every post-idle request re-borrowed against the connect budget and occasionally blew it → 500/503.

## Fix
- `db.js`: `idleTimeoutMillis` → `intEnv('DB_IDLE_TIMEOUT_MS', 360000)` (outlives the 5-min ping so the
  warmed connection persists); `connectionTimeoutMillis` default → `8000` for genuinely-cold borrows
  (RDS-Proxy borrow + TLS can exceed the old budget). `query_timeout` / `statement_timeout` stay 3000
  — slow QUERIES still fail fast.
- `lambda.js`: the `keepWarm` branch now pre-warms `await loadSecrets()` + `pool.query('SELECT 1')`
  inside a best-effort try/catch (a warm-up failure must not fail the ping), refreshing a live pooled
  connection the next real request reuses. (SELECT 1 is autocommit → returns to the pool; an idle
  keep-alive, NOT a SET-LOCAL proxy pin, so no starvation concern.)

## Env-override handling
Phase 0 flagged `DB_CONNECT_TIMEOUT_MS` was set in SSM to 5000 (env wins over the `intEnv` default).
So: `aws ssm put-parameter /gunnerteam/dev/DB_CONNECT_TIMEOUT_MS 8000` (String, v2) +
`terraform apply -target=aws_lambda_function.api` (the data source re-reads SSM → env now 8000), in
addition to the code default. `DB_IDLE_TIMEOUT_MS` has no env override → the 360000 code default
applies.

## Deploy + verify
SSM bump → targeted tf apply (env) → S3 code deploy → publish **v346** → alias live. Verified: live env
`DB_CONNECT_TIMEOUT_MS=8000`; keepWarm invoke → `{statusCode:200, body:'warm'}` with **0**
`[keepWarm] pre-warm failed` (the SELECT 1 succeeded); `/health` 200; migration probe ok:true; **0**
connect-timeout / `db.connect failed` in logs post-deploy.

## ⏳ Pending (ongoing, per Phase 3)
Watch `gunnerteam-dev-apigw-5xx` + `gunnerteam-dev-lambda-errors` for 24h (target zero new datapoints)
and re-run the Phase 0 Logs Insights query tomorrow to confirm no new `status=5` lines.
