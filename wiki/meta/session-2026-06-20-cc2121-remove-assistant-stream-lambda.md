---
type: session
title: session-2026-06-20-cc2121-remove-assistant-stream-lambda
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - infra
  - terraform
  - security
  - soc2
  - secrets
  - deploy
  - cleanup
status: stable
related:
  - '[[meta/session-2026-06-20-cc2120-remove-jwt-secret]]'
  - '[[meta/session-2026-06-20-cc2118-retire-hs256]]'
  - '[[gunnerteam/soc2-technical-summary]]'
---

# Session cc-prompt-2121 — Remove abandoned assistant-stream Function URL Lambda (CC6.1/6.6) — v335

Delete a public, unauthenticated, secrets-bearing endpoint; resolve the cc-2118 source-of-truth
gap; complete the JWT_SECRET teardown. Commit `befed66`, deployed **v335**.

## Phase 0 — abandonment gate (passed)
`get-metric-statistics` Invocations / 30d for `gunnerteam-dev-assistant-stream` = `[]` (zero).
Corroborating: iOS uses `/assistant/chat` (API-GW route), handler `src/assistant-stream.js`
deleted cc-2118, broken `verifyToken` import, `ASSISTANT_STREAM_URL` unused by code.

## What was removed
- Deleted `terraform/lambda-assistant.tf` — `aws_lambda_function.assistant`,
  `aws_lambda_function_url.assistant`, `aws_cloudwatch_log_group.assistant_lambda`, and the
  `assistant_stream_url` output. The Function URL was **RESPONSE_STREAM, authorization_type=NONE,
  CORS `*`**, env carrying **JWT_SECRET + DB creds + ANTHROPIC_API_KEY** — a public
  unauthenticated secrets-bearing endpoint.
- `lambda-api.tf`: removed the `ASSISTANT_STREAM_URL` env line (:200) and the now-orphaned
  `aws_ssm_parameter.jwt_secret` data source (:12). Confirmed beforehand these were the only
  references outside the deleted file.

## Plan / apply / deploy
Full plan = `1 add / 1 change / 4 destroy` — the 3 assistant resources + the pre-existing benign
`null_resource.clear_alias_routing` replace; `aws_lambda_function.api` in-place dropping
`ASSISTANT_STREAM_URL`; output removed. Verified the **api** block drops ONLY
`ASSISTANT_STREAM_URL` (the `- JWT_SECRET` line was under the assistant **destroy** block). No
masterdb/cognito/rds **changes** (refresh only). Targeted apply → **3 destroyed + api in-place**.
Published **v335**, alias live (no code change → publish + alias only).

## Verify
- Old Function URL (`https://xzmqry2…lambda-url.us-east-2.on.aws/`) → **403** (dead).
- `/health` → 200; **`/assistant/chat` → 401** (the API-GW assistant route on the main Lambda is
  alive + auth-gated, NOT 404 — the real assistant path is unaffected).
- Live alias env free of `ASSISTANT_STREAM_URL` + `JWT_SECRET`.
- Deleted the dead **`/gunnerteam/dev/JWT_SECRET` SSM param** (`ParameterNotFound` confirms).

## Net: JWT_SECRET teardown complete
cc-2118 (code) → cc-2120 (api env + jsonwebtoken dep) → cc-2121 (assistant Lambda env + data
source + SSM param). No code reads it, no Lambda env carries it, no SSM param holds it.

## Notes / leftovers
- The targeted apply left the orphaned `assistant_stream_url` output + the pre-existing
  `null_resource.clear_alias_routing` drift in state — both clear on the next full reconcile
  (same treatment as cc-2115/2119).
- **Out of scope (flagged):** `var.jwt_secret` → `terraform.tfvars` → `user_data.sh` (EC2
  user-data) chain — a *separate* secret value (not the SSM param removed here), likely also dead
  post-Lambda-migration. Assess + clean in its own prompt.

## Reusable
A `terraform apply -target` that destroys resources does NOT process output removals or
non-targeted drift — they linger in state until a full apply. Acceptable when the resource
teardown is the goal; note it.
