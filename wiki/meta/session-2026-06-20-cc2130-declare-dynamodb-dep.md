---
type: session
title: session-2026-06-20-cc2130-declare-dynamodb-dep
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - backend
  - security
  - soc2
  - dependencies
  - supply-chain
  - deploy
status: stable
related:
  - '[[meta/session-2026-06-20-cc2128-isolation-test-suite]]'
  - '[[meta/session-2026-06-20-cc2123-runtime-secrets]]'
  - '[[gunnerteam/soc2-technical-summary]]'
---

# Session cc-prompt-2130 — Declare the implicit @aws-sdk/client-dynamodb dependency (CC7.1/CC8.1) — v343

`idempotency.js` + `rateLimitStore.js` `require('@aws-sdk/client-dynamodb')`, but it was NOT in
`package.json` — it resolved only because the Lambda nodejs20 runtime bundles a v3 SDK. Blind spot:
absent from the lockfile + SBOM (cc-2101), a runtime SDK change could break it, and a local `require`
of those modules failed (surfaced in cc-2128). Same fix class as cc-2123 (client-ssm). Commit
`b55e4ee`, deployed **v343** (rollback v342).

## Audit
`grep -rho '@aws-sdk/[a-z-]*' src/ | sort -u` vs the declared deps: **client-dynamodb was the ONLY
undeclared `@aws-sdk/*`**. The other six (cognito-identity-provider, s3, ses, ssm, textract,
s3-request-presigner) are all declared. So a single add, no further gaps.

## Change
`npm install @aws-sdk/client-dynamodb@3.1073.0` → `package.json` `^3.1073.0` (matches the newest
declared client, `client-ssm` from cc-2123, for a consistent bundle); lockfile pins `3.1073.0` (+5
transitive deps now locked). It is now **bundled in the deploy zip** (deterministic, SBOM-visible)
rather than relying on the runtime SDK. No `src/` changes.

## Verify
- Local: `rateLimitStore` + `idempotency` + `lambda.js` require-load OK (the cc-2128 failure is gone);
  `npm run check` + `npm test` (5 pass) + `npm audit --audit-level=high` all green.
- Deployed v343. Live: `/health` 200; migration probe `ok:true` (cold start requires the chain through
  `rateLimitStore` → `client-dynamodb`, so this proves the bundled dep loads in the Lambda).
- **DynamoDB rate-limit path end-to-end:** hammered `POST /points/webhook`. The `webhookLimiter` runs
  before the signature check, so bad-sig requests count toward the 120/min limit. Result: 120 requests
  → 401, request **121 → first 429** (`DynamoRateLimitStore.increment` via `UpdateItemCommand`),
  15×429 after, 0 errors. Log scan: no `Cannot find module` / DynamoDB errors.
- Idempotency uses the SAME bundled `DynamoDBClient` (loads at init via `forms.js`; verified by
  construction + the rate-limit proof) — couldn't exercise its GetItem/PutItem path without an authed
  replay.

## Result
The supply-chain blind spot is closed: the next CI SBOM run lists `@aws-sdk/client-dynamodb`, the
lockfile pins it, and the Lambda no longer depends on the runtime happening to provide it.
