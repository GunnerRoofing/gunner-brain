---
type: reference
owner: leo
created: 2026-06-19
updated: 2026-06-19
tags: [qp, quote-portal, teardown, aws, security, consolidation]
status: active
---

# QP — Teardown Findings

Repo + deployed-gateway analysis (2026-06-19), now backed by stage AWS read access. Feeds the QP ownership roadmap's Scaffold and Audit phases. **Do not delete anything still pending a CloudWatch=0 confirmation.** Part of [[leo/apps/quote-portal]].

## Load-bearing "dead" code

- **~46% of live prod API-Gateway functions have NO source in `portal-backend`** — they live in **`portalBackendArchive`**. That repo is **load-bearing, NOT safe to delete**.
- The `archive/` subfolder inside `portal-backend` is also load-bearing.

## Shared-resource landmines (do not touch during teardown)

- The QP **API Gateway is SHARED with the HR/corporate portal** (`get-hr-handbook`, `get-employee-spotlight`, etc.).
- **`gunnermediabucket` S3 bucket** — shared across dev+stage+prod.
- **Google OAuth client** — same client id across dev+stage+prod.

## Version drift — verify against the DEPLOYED gateway, not the repo

- `apiGatewayGunner/api/stage.yaml` is **STALE** (shows v1). The **deployed** stage gateway (REST API **`i7yajednwl`**, behind `api-stage.gunnerroofing.com`, acct `127214181149`) actually routes `/pricing/asphalt`→**v2** and `/pricing/siding`→**v3**.
- **Re-verify ALL teardown route→fn claims against the deployed gateway, not the repo yaml.** The v1 lambdas exist but get ~zero traffic.
- v1 calculator source is **recoverable as the deployed artifact** from the dev account (`aws lambda get-function` → `Code.Location` → curl zip) — used to verify the wizard Phase C field contract. See [[leo/qp/quote-wizard]].

## Consolidation candidates

- 9 pricing-calculator Lambdas should consolidate to 1; ~8 HubSpot Lambdas overlap.
- **Code-only verdicts** (no prod AWS needed; pending only CloudWatch=0):
  - `admin-margin-api-v1` owns all `/admin/margin` CRUD → `get-margin-details-api-v1` + `update-margin-api-v1` are **superseded DELETE candidates** (no routes/refs).
  - `get-project-pricing-api-v1` (monolithic "legacy roofing pricing engine") is **superseded** by the per-material `/pricing/*` calcs → DELETE candidate.

## Blocker

- Full teardown + dead-Lambda confirmation needs **CloudWatch 90-day invocation counts**. Stage read access obtained; **prod still pending**.

## SECURITY flag (raise to Leonard)

> ⚠ CRITICAL: credential present — not copied.
>
> Git-committed `pricing-calculator-asphalt-api-v1/service.mjs` (branches `develop1` / `GUNIT-509` / `GUNIT-513`) has **hardcoded DB admin credentials in plaintext** (a dev Aurora host, the `gunner_admin` user, db `prod_oct17` — values omitted here). They are in git history. **Rotate the credential and move it to SSM / Secrets Manager.**

## Links
- [[leo/apps/quote-portal]] — QP overview, repo + env map, deployed gateway
- [[leo/qp/pricing-formula]] — calc-DB work that depends on these route→fn facts
- [[leo/qp/quote-wizard]] — Phase C field contract verified via the recovered artifact
