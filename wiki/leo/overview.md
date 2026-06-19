---
type: overview
owner: leo
created: 2026-06-10
updated: 2026-06-19
tags: [gunner-ops, overview, masterdb, crm]
status: active
---

# gunner-ops — Overview

## App

gunner-ops is Gunner Roofing's internal job-management CRM — a replacement for Monday.com. It tracks roofing, siding, and windows jobs from intake through completion: permitting, materials, scheduling, inspections, and payments. It is the system of record for operations.

## Stages

Pizza-ticker lifecycle:

```
New Project → Permitting/Procurement → Scheduling → Active → Complete
(overview → job_prep → schedule → in_progress → closeout)
```

Full stage conditions and notification routing: [[leo/concepts/ops-lifecycle]]

## Stack

- **Backend:** Python 3.13 (arm64 Lambda), FastAPI + Mangum, SQLAlchemy 2.x + Alembic (at 0008).
- **Database:** runs **inside PROD masterdb Aurora** — ops connects as the non-superuser `ops_app` role (RLS-subject). ops_* tables + `ops_alembic_version` live in masterdb.
- **Auth:** "B-lite" — login delegated to masterdb `/v1/auth/login`; ops validates HS256 `{sub, org_id}`; no local users.
- **Frontend:** React + Vite (flat `frontend/`, no `src/`), hosted on S3 + CloudFront.
- **IaC:** AWS SAM (`template.yaml`), us-east-2 — **not SST**.
- **Payments:** Stripe (sandbox live) — Checkout Session links + out-of-band invoices, signature-verified webhook.

## Key Integrations

- **masterdb** — ops lives inside the shared Aurora data layer as a multi-tenant, RLS-isolated app (cutover done 2026-06-10). Cross-app data via API, not cross-schema queries. See [[leo/apps/masterdb-integration]] and [[gunnerteam/masterdb-architecture]].
- **Stripe** (sandbox `acct_1RgUCICYJB2VMLe8`) — credit-card payment links + cash/check out-of-band invoices; sig-verified webhook. See [[shared/vendors/stripe]].
- **Supplier APIs** — ABC Supply (sandbox creds live, product search working) + SRS/QXO (creds pending, mock fallback). Side-by-side quote comparison, order from job_prep.
- **Google Places** — US-restricted address autocomplete (frontend).
- **HubSpot** — legacy `hubspot_id` on jobs; being replaced by an internal Sales app.

## Status

**In production** (deployed 2026-06-10), running inside masterdb. **Deployed ≠ in use** — no real users/data yet, data is throwaway/demo, DB not precious until go-live. Go-live target ~2026-06-26 (3-week MVP sprint, 2 devs).

Deep app reference (prod state, schema, features, gotchas, backlog): [[leo/apps/gunner-ops]]

## Links

- [[leo/apps/gunner-ops]] — deep gunner-ops reference page
- [[leo/concepts/ops-lifecycle]] — job lifecycle stages + conditions
- [[leo/apps/masterdb-integration]] — masterdb integration detail
- [[leo/index]] — section index (sessions, decisions, concepts, runbooks)
- [[leo/hot]] — hot cache (current focus, active issues)
