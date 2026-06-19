---
type: overview
owner: leo
created: 2026-06-19
updated: 2026-06-19
tags: [qp, quote-portal, aws, lambda, overview]
status: active
---

# QP — Quote Portal (overview)

The Quote Portal (QP) is Gunner Roofing's end-to-end roofing sales system: internal sales reps build and send proposals; customers review and pay through a separate customer-facing portal. Distinct from [[leo/apps/gunner-ops]] (the post-sale job-lifecycle CRM) — QP is the pre-sale quote/proposal/contract/payment surface.

Active QP work breaks into three tracks, all on **stage** (prod untouched):
- [[leo/qp/quote-wizard]] — the guided 4-step wizard rebuild of the sales-rep quote flow.
- [[leo/qp/teardown]] — repo + deployed-gateway analysis, consolidation candidates, shared-resource landmines, security flag.
- [[leo/qp/pricing-formula]] — applying EP's updated quote workbook to the backend calc DB (SQL migrations, all trades, stage-only).

Vendor stub: [[shared/vendors/quote-portal]].

## Repo map

### Primary (active development)
| Repo | Purpose |
|------|---------|
| `GunnerRoofing/sales-portal-frontend` | Internal sales-rep app (Next.js, JS, SCSS+Bootstrap). Home of the quote wizard. |
| `GunnerRoofing/portal-backend` | 65+ active Lambdas; 100+ functions total counting archive. Node 22 ESM `.mjs`, each Lambda its own SAM stack (Express + `serverless-http`). |
| `GunnerRoofing/gunner-qp-customer-portal` | Customer-facing app (Next.js, **TypeScript** App Router). Stripe payments, state-keyed (NY/CT/OH/NJ/PA). |
| `GunnerRoofing/gunner-2022` | Purpose TBD — confirmed active by offshore team. |
| `GunnerRoofing/estimator-wordpress` | estimator.gunnerroofing.com — headless WP + FaustJS. |

### Support (offshore single-contributor — know they exist, low active-dev need)
| Repo | Purpose |
|------|---------|
| `GunnerRoofing/infrastructure-as-code` | CloudFormation for all shared infra. |
| `GunnerRoofing/apiGatewayGunner` | API Gateway definition (SAM + OpenAPI per env). **Note: env yamls drift from the deployed gateway** — see [[leo/qp/teardown]]. |
| `portalBackendArchive` | **Load-bearing** — ~46% of live prod gateway functions have source only here. Do NOT delete. See [[leo/qp/teardown]]. |

## Backend shape

- Generic, **DB-formula-driven** pricing engine: calcs string-substitute and `Function()`-eval `base_metric` / `condition` rows from the DB. Pricing edits = DB row updates, not code changes. This is why [[leo/qp/pricing-formula]] is SQL migrations rather than code.
- Roof formulas live in `gg.product_materials_prices`; rates in `gg.margin` / `lk_state_tax` / `product_additional_charges`.
- Auth: `api-authorizer-v1` (JWT) and `sso-authorizer-v1` (Google SSO) on API Gateway. Both portals share one Cognito pool per env (passwordless magic-link).

## Environment map

| Env | Domain | AWS account | Access held | Status / notes |
|-----|--------|-------------|-------------|----------------|
| **stage** | qp-stage.gunnerroofing.com | `127214181149` | **ReadOnlyAccess** (profile `gunner-stage`, us-east-2) | **Day-to-day working env, ALL test data (writes OK).** VPC CIDR 10.5.0.0/16. |
| dev | qp-dev.gunnerroofing.com | `980921733684` | full (long held) | Separate dev env; the only creds held for a long time. VPC CIDR 10.2.0.0/16. |
| qa | — | — | — | Spun down (Indra env, not running). |
| prod | qp.gunnerroofing.com | (pending) | none yet | **In production, NOT live** — deployed, no real customer traffic. Stakeholder smoke-test gates go-live. |

> Naming gotcha (confirmed): **stage = the working env with all test data**; **dev** is a separate env (the long-held creds); **prod** is deployed but not yet taking customer traffic.

WordPress/Estimator sites run on separate EC2: prod WP/Estimator AWS account `195275661166`; non-prod share one EC2.

### Deployed stage API Gateway
- REST API **`i7yajednwl`**, behind `api-stage.gunnerroofing.com`, acct `127214181149`.
- Routes the **deployed** versions, not the repo yaml: `/pricing/asphalt`→v2, `/pricing/siding`→v3. The repo `apiGatewayGunner/api/stage.yaml` is stale (shows v1). Always verify route→fn against the deployed gateway. See [[leo/qp/teardown]].
- The QP gateway is **shared with the HR/corporate portal** — landmine, do not touch during teardown.

### Stage Aurora (where pricing work happens)
- Cluster **`stage-gunner-aurorapgdb`** (acct `127214181149`), DB **`prod_oct17`** — a prod snapshot restored into the stage cluster (isolated from dev, ~93 test projects, safe to write).
- Access: SSM port-forward through app EC2 **`i-01a18718706e85336`** → `psql localhost:5433`. QP runs its OWN Aurora cluster, separate from masterdb. See [[leo/qp/pricing-formula]].

> ⚠ CRITICAL: credential present — not copied. A git-committed v1 asphalt calculator (`pricing-calculator-asphalt-api-v1/service.mjs`) has plaintext DB admin creds in git history — rotate + move to SSM/Secrets Manager. Detail in [[leo/qp/teardown]].

## Links
- [[leo/qp/quote-wizard]] — guided 4-step wizard rebuild
- [[leo/qp/teardown]] — teardown findings + security flag
- [[leo/qp/pricing-formula]] — EP-workbook → calc-DB side-quest
- [[leo/apps/gunner-ops]] — the post-sale job CRM (sibling app)
- [[shared/vendors/quote-portal]] — vendor stub
