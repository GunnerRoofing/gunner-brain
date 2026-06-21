---
type: session
title: session-2026-06-20-cc2120-remove-jwt-secret
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - backend
  - terraform
  - security
  - soc2
  - secrets
  - deploy
  - regression
status: stable
related:
  - '[[meta/session-2026-06-20-cc2118-retire-hs256]]'
  - '[[gunnerteam/aws-environment]]'
---

# Session cc-prompt-2120 — Remove dead JWT_SECRET + jsonwebtoken (CC6.1) — v334

Shrink the secret surface now that cc-2118 made the main API Cognito-RS256-only. Commit
`3431edf`, deployed **v334**. **Also uncovered a cc-2118 regression** (see below).

## Done (the safe, in-scope core)
- Phase 0: `grep src` = 0 for JWT_SECRET / jsonwebtoken / jwt.sign / signToken → dead in code.
- Phase 1: `npm uninstall jsonwebtoken`; `npm run check` (exit 0) + `npm test` (4 pass; DB
  integration tests skip cleanly without DB_HOST).
- Phase 2: removed `JWT_SECRET = data.aws_ssm_parameter.jwt_secret.value` from `lambda-api.tf`
  env. `terraform plan -target=aws_lambda_function.api` = **0 add / 1 change / 0 destroy**,
  diff = ONLY `- "JWT_SECRET" -> null` (no code change — ignore_changes; assistant untouched).
  Applied.
- Deploy: S3 block (ships the dep removal) + publish + alias → **v334**. Verified: the LIVE
  alias `GetFunctionConfiguration` no longer exposes JWT_SECRET (the incident-class CC6.1 win),
  `/health` 200, v334 serving, rest of env intact (DB_HOST present). Existing auth unaffected
  (`verifyCognitoToken` unchanged; nothing read JWT_SECRET).

## Deviation from the prompt (Phase 2/3 was infeasible as written)
The prompt said "delete the `data "aws_ssm_parameter" "jwt_secret"` source" + "delete the SSM
param." Both are **shared**: `data.aws_ssm_parameter.jwt_secret` (lambda-api.tf:12) is ALSO
referenced by **`lambda-assistant.tf:34`**. Deleting the data source breaks TF; deleting the SSM
param breaks the data source. So I **kept both**. There is also a separate
`var.jwt_secret` → `terraform.tfvars` → `user_data.sh` (EC2 user-data) chain — untouched.

## ⚠️ cc-2118 regression uncovered
cc-2118 deleted `gunnerteam-api/src/assistant-stream.js` as "dead" — but it is the **handler of
the `gunnerteam-dev-assistant-stream` Function URL Lambda** (`lambda-assistant.tf`, handler
`src/assistant-stream.handler`, shares the api code zip). That Lambda is **abandoned**:
- no invocations since ~May 15 (>1 month),
- its `verifyToken` import was already broken (jwt.js exports `verifyCognitoToken`, never
  `verifyToken`) → 401 on every call,
- iOS uses `API.base + "/assistant/chat"` (API Gateway route), **not** the Function URL.

The live Lambda still runs old code (LastModified 2026-06-19, pre-cc-2118 — handler present;
`ignore_changes = [source_code_hash,...]` prevents TF from pushing the now-handler-less archive),
so it is **not live-broken**. But the repo source-of-truth lost the handler, and any future
code-applying deploy of that Lambda would break it. It also still carries `JWT_SECRET` env.

## Recommended follow-up cc-prompt
**Remove the abandoned `assistant-stream` Lambda entirely** (`lambda-assistant.tf` — the
`aws_lambda_function.assistant`, its Function URL, log group, output; leave the handler
deleted). That unblocks the **full** JWT_SECRET teardown: drop the env ref on the assistant, the
shared `data.aws_ssm_parameter.jwt_secret` source, the SSM param itself, and the
`var.jwt_secret`/tfvars/`user_data.sh` EC2 chain. Until then, JWT_SECRET persists only for that
one abandoned Lambda. (Not done here — removing a Lambda + Function URL is a separate decision.)

## Reusable facts
- `aws_ssm_parameter.jwt_secret` is shared by lambda-api + lambda-assistant — can't delete it
  piecemeal.
- The `assistant-stream` Function URL Lambda is abandoned; the active assistant path is the API
  Gateway `/assistant/chat` route (`routes/assistant.js`).
