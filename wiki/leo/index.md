---
type: index
owner: leo
created: 2026-06-10
updated: 2026-07-01
tags: [gunner-ops, index]
status: active
---

# Leo — Section Index

Leo owns **gunner-ops** (the named section app) and is the de-facto owner of the
**quote portal (QP)** and the **Dialpad↔HubSpot** integrations, plus the
ops-side of **masterdb**. Cross-team foundations (masterdb internals, Dialpad/HubSpot
vendor pages) are canonical in [[gunnerteam/index]] and [[shared/entities/_index|shared]] —
the pages here are the Leo/ops-angle views that link out to them.

## Overview

- [[leo/overview]] — gunner-ops at a glance (stack, integrations, status)

## Apps

- [[leo/apps/gunner-ops]] — job-lifecycle CRM replacing Monday.com (deep reference: prod state, schema, features, deploy)
- [[leo/apps/masterdb-integration]] — the ops↔masterdb contract (B-lite auth + RLS); links to [[gunnerteam/masterdb-architecture]]
- [[leo/apps/quote-portal]] — QP overview: repo map, environments, AWS access

## Quote Portal (QP)

- [[leo/qp/quote-wizard]] — the guided 4-step quote-wizard rebuild (roof + native Siding/Windows pricing live on stage)
- [[leo/qp/crm-sell]] — CRM "Sell mode" record workspace inside the wizard (first HubSpot-strangler slice; backend contract locked with Tyler)
- [[leo/qp/teardown]] — QP repo/Lambda teardown findings + landmines
- [[leo/qp/pricing-formula]] — EP-Edit workbook → backend calc DB formula updates

## Integrations

- [[leo/integrations/dialpad-hubspot]] — the two live Dialpad↔HubSpot Lambdas (sync + call/SMS logger)

## Concepts

- [[leo/concepts/ops-lifecycle]] — the gunner-ops job lifecycle (pizza-ticker stages + advance conditions)
- [[leo/concepts/material-order-automation]] — VP/CEO demo: QP-priced material takeoff + SOW, measurement upload (PDF/CSV), PO PDF export; headed for ops procurement

## Decisions

_ADRs to migrate / file as they're made._

## Sessions

_Saved working sessions land in `leo/meta/`._
