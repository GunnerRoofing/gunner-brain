---
type: session
title: session-2026-06-20-cc2123-runtime-secrets
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - backend
  - security
  - soc2
  - secrets
  - ssm
  - deploy
status: stable
related:
  - '[[gunnerteam/soc2-technical-summary]]'
  - '[[meta/session-2026-06-20-cc2120-remove-jwt-secret]]'
  - '[[gunnerteam/aws-environment]]'
---

# Session cc-prompt-2123 — Secrets out of the Lambda env → runtime SSM fetch (CC6.1) — v337

~17 secrets were baked into the Lambda env (exposed via `GetFunctionConfiguration` — the incident
class). Now fetched at runtime from SSM, cached per container. Commit `6919e5b`, deployed **v337**
(rollback target v335). The big change of the block — phased + canaried.

## Design (lowest-risk)
`lambda.js` is the single entry for ALL invocations (HTTP / scheduled / SNS / migration). It
`await loadSecrets()` once at the top of every invocation (memoized → one SSM call per container),
so the cache is always populated before any handler. That makes a **synchronous
`getSecretSync('NAME')`** safe in every downstream path (Express handlers, scheduled tasks, SNS,
shared libs like email/apns) — so most reads became a mechanical `process.env.X → getSecretSync('X')`
with **no async/signature churn**. Only the module-load `new Anthropic(...)` needed a lazy getter.

`lib/secrets.js`: `loadSecrets()` (memoized `GetParametersByPath(SECRETS_PATH, WithDecryption)`,
paginated), `getSecret()` (async, fail-loud), `getSecretSync()` (drop-in for `process.env`; throws
only if called before load). Added `@aws-sdk/client-ssm`.

## Discovery findings
- 13 secrets read by code; **4 CompanyCam secrets had ZERO reads** (dead, superseded by
  `FIELD_PORTAL_*`) — removed from env, no conversion.
- `routes/assistant-stream.js` orphaned (its only consumer was the cc-2121-removed Lambda) → deleted.
- IAM already allows `ssm:GetParametersByPath` (cc-2107).
- **`MIGRATION_SECRET` was NOT in SSM** — its env came from `var.migration_secret`/tfvars. Created
  the `/gunnerteam/dev/MIGRATION_SECRET` SecureString param (value preserved) so the migration/DB
  probe keeps working; removed the now-dead var + tfvars line.

## Converted reads
apns (APNS_KEY_CONTENT), email (RESEND, GOOGLE_CHAT), assistant (ANTHROPIC — lazy), fieldportal
(FIELD_PORTAL_API_KEY + 3 webhook secrets + OPENAI + COLIN_PNL), forms (MONDAY ×2), time
(FIELD_PORTAL_API_KEY ×4), points-webhook (GUNNERCAM_POINTS_WEBHOOK_TOKEN), lambda.js
(MIGRATION_SECRET). Grep → 0 remaining `process.env.<secret>`; `node --check` all green. Webhook
`express.raw()` + verify-before-dedup ordering untouched.

## TF
Removed 17 secret env keys + 16 data sources from `lambda-api.tf`; added `SECRETS_PATH` config;
removed the dead `migration_secret` var + tfvars line. Targeted plan = `0 add / 1 change / 0 destroy`
(env: −17 secrets, +SECRETS_PATH; no code/vpc change).

## Deploy + canary
terraform apply (env → $LATEST) → S3 deploy (ships secrets.js + getSecretSync + client-ssm) →
publish **v337** → alias (live switches atomically; v335 retained for rollback). Verified:
- **migration probe → `ok:true`** — the make-or-break canary (loadSecrets + IAM + getSecretSync +
  DB). One `GetParametersByPath` populates the whole cache, so this proves every secret is loadable.
- `/health` 200; **points-webhook bad-sig → 401** (a real getSecretSync webhook read works, not 500);
- **live alias env = 0/17 secrets + `SECRETS_PATH` present** (the CC6.1 incident-class win).
- Authed paths (assistant/monday/email/colin/google-chat) verified by construction (shared proven
  cache + clean module load) — not triggerable without a user token.

## Reusable
- **Add a new secret:** `aws ssm put-parameter --type SecureString` under `/gunnerteam/dev/`, read
  via `getSecretSync('NAME')`. Do NOT add it to `lambda-api.tf` env. Config/IDs/flags still go in env.
- `getSecretSync` is safe anywhere because `lambda.js` awaits `loadSecrets()` at the top of every
  invocation.

## Out of scope / future
- `DB_PASSWORD` — module-load pool init + proxy-secret-drift history → its own prompt (cc-2124).
- Secrets Manager with managed rotation is the alternative if rotation becomes a requirement.
