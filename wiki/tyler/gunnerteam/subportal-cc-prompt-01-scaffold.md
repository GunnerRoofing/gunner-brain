---
type: source
title: Subcontractor Portal — cc-prompt-01 Scaffold Spec
created: '2026-05-22'
updated: '2026-05-22'
tags:
  - subportal
  - python
  - scaffold
  - sst
  - masterdb
  - architecture
  - security
status: active
related:
  - '[[tyler/masterdb/masterdb-architecture]]'
  - '[[gunnerteam/secure-coding-guide]]'
  - '[[concepts/soc2]]'
---
# Subcontractor Portal — cc-prompt-01 Scaffold Spec

**Working directory:** `~/Documents/Gunner/subportal`  
**Run in:** Claude Code session in that directory  
**Builds:** Full Python backend skeleton — models, auth middleware, search endpoint, Leo webhook, SST v3 infra

---

## Stack

| Layer | Technology |
|---|---|
| Frontend | React 18 + Vite + TypeScript (Phase 2) |
| Backend | Python 3.12 + AWS Lambda |
| API Framework | aws-lambda-powertools `APIGatewayRestResolver` |
| ORM | SQLAlchemy 2.0 (sync, RDS Proxy connection pooling) |
| Migrations | Alembic |
| Validation | Pydantic v2 |
| Auth | AWS Cognito — JWT verified via API Gateway authorizer |
| IaC | SST v3 (Ion) |
| Database | Aurora PostgreSQL + PostGIS |
| Storage | S3 (private bucket) |
| Email | AWS SES |
| Secrets | AWS SSM Parameter Store (SecureString) — never env vars |
| Logging | aws-lambda-powertools Logger + Tracer + Metrics |

---

## Project Structure

```
gunner-subportal/
├── backend/
│   ├── src/subportal/
│   │   ├── api/          # Lambda route handlers
│   │   ├── models/       # SQLAlchemy ORM models
│   │   ├── schemas/      # Pydantic request/response schemas
│   │   ├── services/     # Business logic
│   │   ├── middleware/   # Auth, tenant context, error handling
│   │   └── db/           # Session factory, base model
│   ├── tests/unit/ + integration/
│   ├── alembic/versions/
│   ├── requirements.txt + requirements-dev.txt
│   └── pyproject.toml + alembic.ini
├── frontend/             (Phase 2)
├── infra/                (Phase 4)
├── sst.config.ts
└── package.json
```

---

## Key Pinned Versions

```
aws-lambda-powertools[all]==2.43.1
SQLAlchemy==2.0.36
alembic==1.14.0
pydantic[email]==2.9.2
psycopg2-binary==2.9.10
GeoAlchemy2==0.15.2
boto3==1.35.76
```

Dev: `pytest==8.3.3`, `ruff==0.8.0`, `black==24.10.0`, `moto[ssm,s3,ses]==5.0.20`

---

## Core Architecture Decisions

### Multi-tenancy
- `org_id` on every tenant-scoped table (`TenantMixin`)
- `org_id` ALWAYS from Cognito JWT claims — never from request body
- RLS is backup only; app-layer `org_id` filter is primary enforcement

### Subcontractor data model
- `subcontractors` table is **NOT tenant-scoped** — shared national pool owned by Gunner
- Tenant-scoped tables: `jobs`, `reviews`, `audit_log` (have `org_id`)
- Contact info (email/phone/address) excluded from search results — only via `/contact` endpoint (audit-logged)

### Security invariants
- Search hard cap: `SEARCH_RESULT_CAP = 8` — never return more, never expose total count
- Every search audit-logged to `audit_log` table (SOC 2 CC7.2)
- Leo webhook: per-tenant HMAC-SHA256 verification, idempotent upsert on `(org_id, leo_job_id)`
- Secrets from SSM with `@lru_cache` at cold start — never hardcoded or in Lambda env vars

---

## Models

### `subcontractors` (non-tenant)
`id, company_name, contact_name, address_1, city, state, postal, email, phone, location (Geography POINT), is_active, is_verified, is_claimed`

Indexes: partial unique on `email`, partial unique on `(company_name, postal)`, GIST on `location`, composite on `(state, is_active, is_verified)`

### `subcontractor_profiles`
`id, subcontractor_id, bio, logo_s3_key, website, years_in_business, crew_size, max_jobs_per_week, pricing_notes, pricing_is_public, boost_tier (free|pro|featured), boost_expires_at`

### `subcontractor_trades`
`(subcontractor_id, trade)` — unique constraint

### `subcontractor_coverage`
`(subcontractor_id, zip_code, radius_miles)` — unique constraint

### `subcontractor_documents`
`id, subcontractor_id, doc_type, s3_key, expiry_date, is_verified, verified_by_user_id` — S3 keys only, presign on demand

### `subcontractor_ranking`
`id, subcontractor_id (unique), avg_rating, review_count, vendor_review_count, homeowner_review_count, response_rate, ranking_score (indexed)`

### `jobs` (tenant-scoped: TenantMixin)
`id, org_id, leo_job_id, address, city, state, postal, location, trade, status, assigned_subcontractor_id, assigned_at, assigned_by_user_id`

Unique: `(org_id, leo_job_id)`

### `reviews` (tenant-scoped: TenantMixin)
`id, org_id, subcontractor_id, reviewer_user_id, reviewer_type (vendor|homeowner), job_id, rating (1-5 CHECK), comment, is_verified, is_flagged`

### `homeowner_review_tokens`
`id, job_id, subcontractor_id, token (unique signed JWT), used_at, expires_at`

### `audit_log`
`id, org_id, user_id, action, subcontractor_id, job_id, ip_address, user_agent, metadata (JSONB)`

Actions: `search, profile_view, contact_reveal, doc_view, assignment, export, review_submit`

---

## Auth Middleware Pattern

```python
# API Gateway Cognito authorizer validates JWT — Lambda trusts claims
def get_user_context(event) -> UserContext:
    claims = event.request_context.authorizer["claims"]
    return UserContext(
        user_id=claims["sub"],
        org_id=claims["custom:org_id"],   # set at JIT provisioning
        email=claims["email"],
        roles=claims.get("custom:roles", "").split(","),
    )
```

---

## Search Endpoint Pattern

```python
@app.get("/subcontractors/search")
def search_subcontractors():
    user = get_user_context(app.current_event)  # auth first
    params = SubSearchRequest(...)               # pydantic validation
    results = _search(db, params)               # PostGIS + ranking score
    db.add(AuditLog(action="search", ...))      # always audit
    return {"results": results[:8]}             # hard cap, no total
```

---

## Leo Webhook Pattern

```python
@app.post("/jobs/sync")
def sync_job():
    org_id = json.loads(raw_body)["org_id"]
    secret = _get_leo_secret(org_id)            # per-tenant SSM secret
    if not verify_hmac(raw_body, signature, secret):
        raise UnauthorizedError(...)
    # Idempotent upsert on (org_id, leo_job_id)
```

---

## SST v3 Config

- Lambda: Python 3.12, 30s timeout, 512MB
- API Gateway routes: `GET /subcontractors/search`, `POST /jobs/sync`, `GET /subcontractors/{id}/contact`
- CORS allow-list: `https://app.gunnerroofing.com` (white-label origins added per-tenant later)
- Cognito authorizer wired in Phase 2

---

## Acceptance Criteria

- `python -c "from src.subportal.main import handler"` runs clean
- `ruff check src/` → 0 errors
- `black --check src/` → 0 errors
- Alembic migration file exists in `alembic/versions/`
- `npx sst --version` works from root
- No hardcoded secrets anywhere
- Every route calls `get_user_context()` or `verify_hmac()` before processing
- `SEARCH_RESULT_CAP = 8` enforced in search handler
- Audit log written in search handler

---

## What This Prompt Does NOT Build (Next Prompts)

- React/Vite frontend
- Admin dashboard
- Subcontractor claim flow
- PostGIS geocoding (stubbed with postal prefix fallback for now)

---

## Commit Message

```
feat: scaffold subportal backend + SST v3 infra

- Python 3.12 + Lambda Powertools + SQLAlchemy 2.0 + Alembic + Pydantic v2
- ORM models: subcontractors, jobs, reviews, audit_log
- Auth middleware: Cognito JWT → UserContext (org_id from claims only)
- Search endpoint: PostGIS radius + ranking score, hard cap 8 results
- Leo webhook receiver: per-tenant HMAC-SHA256 verification, idempotent
- SST v3 config: API Gateway + Lambda + CORS allow-list
- Alembic initial migration (schema only, not applied)

SOC 2: CC6.1 CC6.2 CC6.7 CC7.2
```
