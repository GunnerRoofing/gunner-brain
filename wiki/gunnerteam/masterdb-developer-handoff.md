---
type: source
title: "masterdb Developer Handoff"
created: 2026-05-27
updated: 2026-06-22
tags:
  - masterdb
  - handoff
  - api
  - python
  - fastapi
  - aurora
  - deployment
status: stable
related:
  - "[[gunner/masterdb-architecture]]"
  - "[[gunner/gunnerteam-api-aws-migration]]"
  - "[[gunner/aws-environment]]"
sources:
  - "handoff masterdb.md (raw source — not in vault)"
---

# masterdb Developer Handoff

Operational reference for the masterdb API. Read [[gunner/masterdb-architecture]] for strategic context first.

---

## Operating & Change-Control Rules

> **As of 2026-06-22:** masterdb is now **Tyler-owned** (from Leo) and the GitHub repo is
> **private**. `main` (Leo's real history) is the source of truth. The canonical, committed copy
> of these rules lives in the repo's **`CONTRIBUTING.md`**; Claude Code also reads them from a
> local (gitignored) `CLAUDE.md`. Keep all three in sync when the rules change.

These apply to everyone who touches the repo — they keep it auditable and SOC 2-defensible:

1. **Git is the source of truth.** Every task ends with a commit + `git push origin main`. Work
   from `origin/main`, never a stale local clone or side branch. Never deploy uncommitted code;
   never let the deployed Lambda drift *ahead* of `main` (hand-rolled zip deploys make this easy).
2. **Alembic only, never direct-to-DB.** All schema/DDL — **and role/grant provisioning** — go in
   Alembic migrations, applied via the throwaway migration-Lambda (delete it after).
3. **FORCE RLS is the crown jewel.** Every table is `FORCE ROW LEVEL SECURITY` on
   `app.current_org_id`; no role bypasses it. `users` has no `org_id` (EXISTS into
   `user_organizations`) → generate ids app-side, don't rely on `RETURNING` under `NOBYPASSRLS`.
4. **Least-privilege roles, one per app.** Apps connect as a `NOSUPERUSER NOBYPASSRLS` role
   (e.g. `gunnerteam_app`), never master. Proxy callers use a role-default GUC; direct callers use
   per-request `SET LOCAL`.
5. **No secrets in the repo.** Passwords/keys set out-of-band, stored in Secrets Manager.
6. **Coordinate before changing shared infra** — QP / LEO / COLIN / GunnerTeam share this cluster.

See [[gunnerteam/b1-soc2-cc6-least-privilege-db-roles]] for the phased hardening plan.
See [[gunnerteam/b1-soc2-cc6-least-privilege-db-roles]] for the `gunnerteam_app` role evidence and grant matrix.

---

## Live Resources

| Resource | Value |
|---|---|
| API endpoint | `https://of4rvaa43c.execute-api.us-east-2.amazonaws.com` |
| Lambda | `gunner-masterd-dev-MasterApi2RouteBbovcaHandlerFunction-wssoombt` |
| Runtime | Python 3.12, us-east-2 |
| DB | Aurora Serverless v2 Postgres (0–4 ACU) |
| IAM role | `arn:aws:iam::980921733684:role/gunner-masterdb-dev-MasterApi2RouteBbovcaHandlerRole-cascvtcw` |
| VPC | `vpc-0eb66556f100c7b3c` |
| Subnets | `subnet-019439fa03909a5d1` (us-east-2a), `subnet-01bc93fe6f0755921` (us-east-2b) |
| Security group | `sg-0d9435eab950f73d1` |
| Git repo | `GunnerRoofing/gunner-masterdb` (**private**) — `main` is source of truth (head `j10_service_client_prefix_auth`) |

> Secrets live outside the repo (Secrets Manager). DB credentials are not in git.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Python 3.12 |
| API framework | FastAPI + Mangum (Lambda adapter) |
| Database | Aurora Serverless v2 Postgres |
| ORM | SQLAlchemy 2.0 |
| Migrations | Alembic |
| Validation | Pydantic v2 |
| Auth | Internal JWT (HS256, python-jose) + bcrypt |
| IaC | SST v3 — **`run()` is currently empty; see deploy note** |
| API Gateway | API Gateway V2 (HTTP API) |

---

## Directory Layout

```
gunner-masterdb/
├── api/
│   ├── main.py               # FastAPI app, CORS, router registration
│   ├── auth_utils.py         # JWT encode/decode, get_auth_context, require_admin
│   ├── schemas.py            # Pydantic response models (Out schemas)
│   └── routers/
│       ├── auth.py           # POST /v1/auth/login
│       ├── orgs.py           # GET /v1/orgs, /v1/orgs/{id}
│       ├── users.py          # GET /v1/users, /v1/users/{id}
│       ├── contacts.py       # GET /v1/contacts, /v1/contacts/{id}
│       ├── projects.py       # GET /v1/projects, /v1/projects/{id}
│       ├── integrations.py   # GET /v1/integrations/* (service client auth)
│       └── audit_logs.py     # GET /v1/audit_logs
├── db/
│   ├── session.py            # SQLAlchemy engine + get_db() dependency
│   ├── seed.py               # Dev seed data
│   └── models/
│       ├── base.py           # Base, TimestampMixin, new_uuid()
│       ├── organizations.py  # Organization, organization_services
│       ├── users.py          # User, UserOrganization (UserType enum)
│       ├── contacts.py       # Contact
│       ├── projects.py       # Project (ProjectStatus enum)
│       ├── crews.py          # Crew, CrewMember
│       ├── financials.py     # ProjectFinancial
│       ├── apps.py           # App, AppRole, UserAppRole
│       ├── audit.py          # AuditLog (AuditAction enum)
│       ├── services.py       # Service
│       └── service_clients.py  # ServiceClient (machine-to-machine auth)
└── sst.config.ts
```

---

## Schema — 13 Tables

| Table | Purpose |
|---|---|
| `organizations` | Tenants — one row per Gunner franchise or subcontractor |
| `users` | Global user registry (cross-org) |
| `user_organizations` | Membership join (user ↔ org, with type) |
| `contacts` | Customers/homeowners, scoped to an org |
| `projects` | Roofing jobs, scoped to org → contact → crew |
| `project_financials` | 1:1 financial extension of projects |
| `crews` | Field work crews, scoped to an org |
| `crew_members` | Membership join (user ↔ crew) |
| `services` | Service catalog (Roofing, Siding, Windows, Doors, Specialty) |
| `organization_services` | Which services an org offers (M2M) |
| `apps` | App registry (QP, LEO, COLIN, Marketing, Crew Portal) |
| `app_roles` | Per-app roles (e.g. QP-Sales, LEO-Procurement) |
| `user_app_roles` | User's role in an app, scoped to org (user+org+role 3PK) |
| `audit_logs` | Immutable event log (create/update/delete/login/logout) |
| `service_clients` | Machine-to-machine API keys (bcrypt-hashed) |

### Conventions
- All PKs are UUID strings (`new_uuid()`)
- All timestamps in UTC (`TimestampMixin` adds `created_at` / `updated_at`)
- Every org-scoped table has an indexed `org_id` FK
- `audit_logs` has no `updated_at` — immutable by design
- `hashed_password` is nullable on `users` — reserved for future SSO users

---

## API Routes

All routes under `/v1`. Human users auth via `Authorization: Bearer <jwt>`. Service clients via `X-Api-Key`.

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/v1/auth/login` | None | Email + password + org_slug → JWT |
| GET | `/v1/orgs` | JWT | Current org |
| GET | `/v1/orgs/{org_id}` | JWT | Specific org |
| GET | `/v1/users` | JWT | Users in auth org |
| GET | `/v1/users/{user_id}` | JWT | Specific user |
| GET | `/v1/contacts` | JWT | Contacts in auth org |
| GET | `/v1/contacts/{contact_id}` | JWT | Specific contact |
| GET | `/v1/projects` | JWT | Projects (crew eager-loaded) |
| GET | `/v1/projects/{project_id}` | JWT | Specific project |
| GET | `/v1/audit_logs` | JWT | Audit log for auth org |
| GET | `/v1/integrations/users` | X-Api-Key | Users — service client access |
| GET | `/v1/integrations/projects` | X-Api-Key | Projects — service client access |
| GET | `/v1/integrations/contacts` | X-Api-Key | Contacts — service client access |

---

## Multi-Tenancy Rules

- `org_id` always comes from the JWT — never from client input
- `users` is **global** — one user can belong to multiple orgs via `user_organizations`
- RBAC is triple-keyed: `user_id + org_id + app_role_id`
- `user_organizations.type` is authoritative for membership type — `users.type` is not (ADR 2026-05-20)
- RLS is enabled at Postgres level as defense-in-depth

---

## Service Clients (Machine-to-Machine)

`service_clients` table stores bcrypt-hashed API keys. Keys cannot be recovered after creation — only rotated.

Current clients:
- **Colin / ColinCam** — read access to `/v1/integrations/*` (users, projects, contacts), Gunner org only

To provision or rotate: ask Leonard.

---

## Migration State

Current head: `p16_gt_app_rls` (applied dev + prod 2026-06-24; k11→p16 full chain deployed)

| Revision | Description |
|---|---|
| `a954c89ee8d2` | initial_schema |
| `39225bb12faa` | phase1 users/gt_columns |
| `b2295e3954b0` | phase2 core new tables |
| `91d972fbfea4` | phase3 app registration |
| `e45b3e594750` | phase4 gt app-scoped tables |
| `98a92a0079b9` | phase5 RLS users and core tables |
| `e1112016c9e7` | phase4b gt supplemental tables |
| `9929737c153a` | add salt to users |
| `a1b2c3d4e5f6` | add active to gt_vehicle_documents |
| `b2c3d4e5f6a7` | add expires_at to gt_vehicle_documents |
| `c3d4e5f6a7b8` | add missing gt columns (schema drift fix) |
| `d4e5f6a7b8c9` | add active to gt_vehicle_other_documents |
| `e5_add_service_clients` | service_clients table |
| `f6_service_clients_rls` | service_clients RLS |
| `g7_fix_c3d4_schema_drift` | fix c3d4 dual-schema, TEXT→JSONB, parallel columns |
| `h8_register_gunner_ops_app` | gunner-ops app + 5 roles |
| `i9_register_masterdb_admin` | master-db-admin slug (tightens admin allowlist) |
| `j10_service_client_prefix_auth` | api_key_prefix + service_auth_lookup RLS policy |
| `k11_provision_gunnerteam_app` | **B1** — `gunnerteam_app` role, grants, `gt_*` ownership, users INSERT policy |
| `k12_crew_members_delete_grant` | **B1 fix** — `crew_members` DELETE grant (cc-2142 audit) |
| `k13_least_priv_trim` | **B1** — revoke 4 over-granted tables (contacts, services, org_services, service_clients) |
| `n14_ops_app_track` | Track ops_app provisioning in Alembic; drop ELSE ALTER ROLE (Aurora blocks NOSUPERUSER change on existing role) |
| `o15_merge` | Merge revision (k13 + n14 were parallel heads off k12) |
| `p16_gt_app_rls` | **B1** — role-scoped RLS policies for `gunnerteam_app` — org context without GUC/SET/pinning |

> Always run `alembic upgrade head` in the migration Lambda — never directly against the DB.

### Running Migrations

Bundle all dependencies from the main Lambda zip (Linux binaries — do NOT pip install on macOS):

Required: `psycopg2`, `psycopg2_binary.libs`, `sqlalchemy`, `alembic`, `mako`, `markupsafe`, `greenlet`, `typing_extensions.py`, `six.py`

Use the same role, VPC, subnets, and SG as the main Lambda. **Delete the migration Lambda immediately after it succeeds.**

---

## Deploy (Current Process)

SST `run()` is empty — no CloudFormation/SST stack. Deploy directly to Lambda:

```bash
# 1. Download current zip
URL=$(aws lambda get-function \
  --function-name gunner-masterd-dev-MasterApi2RouteBbovcaHandlerFunction-wssoombt \
  --query 'Code.Location' --output text)
curl -o current.zip "$URL"

# 2. Unzip, swap changed files, rezip
unzip current.zip -d lambda_pkg
cp path/to/changed_files lambda_pkg/gunner_masterdb/
cd lambda_pkg && zip -r ../new.zip . && cd ..

# 3. Upload
aws lambda update-function-code \
  --function-name gunner-masterd-dev-MasterApi2RouteBbovcaHandlerFunction-wssoombt \
  --zip-file fileb://new.zip
```

> **Critical:** Copy ALL changed model files in a single deploy. Missing one causes import errors on cold start.

---

## Known Tech Debt

| Item | Priority | Notes |
|---|---|---|
| SST `run()` is empty | High | No IaC for the Lambda — if recreated from scratch, no config covers it. Restore before infra changes. |
| `GtVehicleDocument` model drift | Medium | DB has `active` and `expires_at` (added in migrations) but models are missing these fields |
| Money columns use Float | Medium | `project_financials` should use `Numeric(12,2)` |
| Cognito migration deferred | Low | Current auth is HS256 JWT. Cognito only when SSO is a business need. |
| Audit logging on writes | Low | AuditLog table exists but not wired into all endpoints |

---

## Key ADRs (2026-05-20)

- **Shared RDS, per-app proxy, API boundaries** — all apps share one RDS; cross-app data goes through APIs, not direct table access
- **Auth: HS256 JWT now, Cognito when SSO needed** — `hashed_password` nullable for future SSO users
- **Integration order: iOS first** — GunnerTeam iOS establishes the auth handshake pattern; gunner-ops or COLIN follows same playbook
- **`user_organizations.type` is authoritative** — `users.type` is not (legacy field)
