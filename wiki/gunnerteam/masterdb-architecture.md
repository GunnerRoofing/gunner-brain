---
type: decision
title: masterdb Architecture
created: '2026-05-22'
updated: '2026-05-22'
decision_date: '2026-05-22'
status: active
tags:
  - masterdb
  - architecture
  - database
  - aws
  - python
  - cognito
  - aurora
  - multi-tenancy
related:
  - '[[gunner/gunnerteam-api-aws-migration]]'
  - '[[gunner/masterdb-developer-handoff]]'
  - '[[gunner/gunnerteam-api-aws-migration]]'
---
# masterdb Architecture

The masterdb is the foundation platform replacing HubSpot, Monday, and CompanyCam with a unified in-house stack. All Gunner software modules share a single Aurora cluster.

---

## Stack

| Layer | Technology |
|---|---|
| Frontend | React + Vite |
| Backend | Python + AWS Lambda + API Gateway |
| Database | Aurora Serverless v2 PostgreSQL |
| ORM | SQLAlchemy + Alembic |
| Validation | Pydantic |
| Auth | AWS Cognito (local + Google SSO) |
| Payments | Stripe (integrated via webhooks) |
| Events | EventBridge |
| Storage | S3 |
| IaC | SST v3 |
| Lambda utilities | aws-lambda-powertools (Python) |

---

## High-Level Structure

```
Master DB (foundation)
├── Sales        (replaces HubSpot)
├── Ops          (replaces Monday)
├── Field        (replaces CompanyCam)
├── Phone Field  (internal tool)
├── Quote App    (existing, integrated)
└── Stripe       (external, integrated via webhooks)
```

---

## Multi-Tenancy Model

- **Single Aurora cluster, single database**
- **Postgres schemas** separate domains: `master`, `sales`, `ops`, `field`, `quotes`
- Every table includes `org_id`
- **RLS policies** enforce isolation at the DB layer — same pattern as `gunner-masterdb` (GunnerTeam API)
- Cognito provides identity; app derives org from authenticated session

This is the same multi-tenancy approach used in the GunnerTeam Express API migration (cc-prompt-10) but at larger scope — multiple product schemas within the same cluster rather than a single `gt_` prefix.

---

## Inter-App Communication

- **Direct reads** from `master` schema (shared data)
- **Cross-app workflows** via EventBridge events
- **API calls** only when fresh data is required

---

## Auth Flow

1. **AWS Cognito User Pool** for identity
2. **Email/password** for local accounts
3. **Google federation** for SSO (team uses Google Workspace)
4. **JIT user provisioning** via Lambda trigger on first SSO login
5. Per-org SSO config stored in `master.organizations.sso_config`

---

## Key Architectural Decisions

**Why single cluster / multiple schemas instead of multiple databases?**
- Cross-schema JOINs are possible (e.g., `sales` reading from `master.contacts`)
- Single connection pool, single backup, single point of compliance
- Schema-level isolation is sufficient with RLS; separate DBs add ops overhead without security benefit at current scale

**Why Python + Lambda instead of Node.js?**
- SQLAlchemy + Alembic are the mature Python ORM/migration stack
- aws-lambda-powertools provides structured logging, tracing, idempotency
- GunnerTeam Express API (Node) stays separate — masterdb is a new build

**Why SST v3?**
- SST handles Lambda + API Gateway + Cognito + EventBridge as a unified IaC stack
- Better DX than raw CDK/Terraform for Lambda-heavy backends

---

## Relationship to GunnerTeam Express API

The GunnerTeam iOS app currently talks to `gunnerteam-dev-api` (Node.js/Express, `gunner-masterdb` Aurora cluster, `gt_` prefix tables). That API is the **first tenant** of the multi-tenant masterdb platform.

The masterdb platform is the **next evolution** — same Aurora cluster, same org/RLS model, adding Python Lambda microservices per domain (Sales, Ops, Field) alongside the existing Express API.

---

## Schema Naming Convention

| Schema | Domain | Replaces |
|---|---|---|
| `master` | Core identity, orgs, users | Shared foundation |
| `sales` | Leads, deals, contacts, pipeline | HubSpot |
| `ops` | Projects, tasks, workflows | Monday |
| `field` | Jobs, photos, inspections | CompanyCam |
| `quotes` | Quote Portal (existing) | Existing app |

The `gt_` prefix tables in the current `gunner_masterdb` database map to the `field` domain conceptually.
## Related Sessions

- [[meta/session-2026-05-21-masterdb-cutover-complete]] — masterdb cutover completion notes
