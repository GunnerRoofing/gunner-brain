---
type: reference
owner: leo
created: 2026-06-10
updated: 2026-06-19
tags: [gunner-ops, masterdb, crm, rls, stripe, alembic, reference]
status: active
---

# gunner-ops — Deep Reference

Gunner Roofing's internal job-management CRM, replacing Monday.com. Tracks roofing/siding/windows jobs from intake through completion — permitting, materials, scheduling, inspections, payments. This is the ground-truth page for picking up the app.

Concise overview: [[leo/overview]]. Lifecycle detail: [[leo/concepts/ops-lifecycle]]. masterdb host: [[leo/apps/masterdb-integration]] / [[gunnerteam/masterdb-architecture]].

---

## Production State (deployed 2026-06-10 → 2026-06-19)

**In production, but deployed ≠ in use yet.** No real users/data — data is throwaway/demo, DB is not precious until go-live. Go-live target ~2026-06-26 (3-week MVP sprint, 2 devs).

The masterdb integration is **DONE** (cutover 2026-06-10). gunner-ops now lives **inside masterdb** as a multi-tenant, RLS-isolated app.

| Aspect | Production reality |
|--------|--------------------|
| Backend Lambda | `gunner-ops-dev-api` (arm64, Python 3.13) |
| Database | **PROD masterdb Aurora** — ops connects as non-superuser `ops_app` role (RLS-subject) |
| Schema home | `ops_*` tables live inside masterdb; separate `ops_alembic_version` table |
| Migrations | Alembic at **0008** (2026-06-11) |
| Frontend | https://d2cy304t1txdpd.cloudfront.net |
| Stack | AWS SAM (`template.yaml`), us-east-2 — **not SST** |

### Live Resources

| Resource | Value |
|----------|-------|
| Frontend | https://d2cy304t1txdpd.cloudfront.net |
| API Lambda | `gunner-ops-dev-api` (arm64, Python 3.13) |
| CloudFront ID | EG6TNJ5ETLV64 |
| S3 bucket | `gunner-ops-dev-frontend-980921733684` |
| Stack | `gunner-ops-dev` (SAM), us-east-2 |
| DB | PROD masterdb Aurora — `ops_app` (non-superuser, RLS-subject) |
| Git repo | https://github.com/GunnerRoofing/gunner-ops.git |
| Working branch | `dev` (merged to dev, then prod deploy) |

> ⚠ CRITICAL: credential present — not copied. The `ops_app` DB password + JWT secret are still inline in config; they need rotating into Secrets Manager before go-live (see Backlog). Do not commit secrets to git.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Python 3.13 (arm64 Lambda) |
| API framework | FastAPI + Mangum (Lambda adapter) |
| ORM | SQLAlchemy 2.x + **Alembic** (at 0008; `ops_alembic_version` table) |
| Database (prod) | PROD masterdb Aurora — `ops_app` role, RLS-isolated |
| Database (local) | SQLite (`ops_crm.db`) |
| Validation | Pydantic v2 |
| Auth | **B-lite** — delegates login to masterdb `/v1/auth/login`; validates HS256 `{sub, org_id}`; no local users; RLS via `SET LOCAL app.current_org_id` |
| IaC | AWS SAM (`template.yaml` + `samconfig.toml`) — not SST |
| Frontend | React + Vite (flat `frontend/`, no `src/`) |
| Frontend hosting | S3 + CloudFront |
| Payments | Stripe (sandbox live) — Checkout Session links + out-of-band invoices; webhook signature verification implemented |

> **IaC note (DEC-001):** gunner-ops predates masterdb's SST decision. SAM is working and deployed; no migration planned unless IaC complexity grows.

---

## Auth Cutover — "B-lite"

Local `users`/login is **retired**. ops delegates login to masterdb and trusts its token:

- Frontend login → masterdb `/v1/auth/login` (`{email, password, org_slug}` via `VITE_AUTH_URL` / `VITE_ORG_SLUG`, default org slug `gunner`) → then ops `/api/auth/me`.
- ops validates the HS256 token `{sub, org_id}`, **no local users**.
- RLS enforced via copied org session: `SET LOCAL app.current_org_id`.
- Roles flow through masterdb.
- Verified E2E with `glen@gunner.com` / `demo` / `gunner` (demo creds, not secrets).

---

## Critical RLS Gotcha (reusable)

`SET LOCAL app.current_org_id` **resets on commit**, and routes commit mid-request → RLS then hid **all** rows (empty lists / 404s).

**Fix:** re-apply `SET LOCAL app.current_org_id` via an `after_begin` session listener + `db.expunge(user)`. Applies to **any** RLS app that commits mid-request — share with anyone integrating into masterdb. See [[leo/apps/masterdb-integration]].

---

## Directory Layout

```
gunner-ops/
├── backend/
│   ├── main.py            # FastAPI app, router registration, DB init on startup
│   ├── db.py              # engine, SessionLocal, Base, get_db (SQLite local / Postgres prod)
│   ├── models.py          # ALL SQLAlchemy models in one file (DEC-002)
│   ├── schemas.py         # ALL Pydantic schemas in one file
│   ├── auth.py            # POST /api/auth/login
│   ├── auth_utils.py      # JWT helpers, get_current_user, require_role factory
│   ├── jobs.py            # /api/jobs routes
│   ├── invoices.py        # /api/jobs/{id}/invoice
│   ├── permits.py         # /api/jobs/{id}/permit  ← known bug (DEC-006)
│   ├── materials.py       # /api/jobs/{id}/materials
│   ├── lifecycle.py       # stage advance logic (does NOT commit — callers own commit)
│   ├── notify.py          # stage-to-role notification routing
│   ├── notifications.py   # /api/notifications/me
│   ├── stripe_webhook.py  # /api/webhooks/stripe
│   ├── stripe_accounts.py # per-state Stripe key routing (falls back to global)
│   └── seed.py            # demo users
├── frontend/              # React + Vite, flat (no src/)
│   ├── App.jsx            # React Router setup
│   ├── api.js             # apiFetch, apiGet, apiPost, apiPatch, apiDelete
│   ├── stages.js          # canonical pizza-ticker stage list
│   ├── jobUtils.js        # getSLAStatus
│   └── *.jsx              # pages and components
├── template.yaml          # SAM: VPC, RDS, Lambda, S3, CloudFront
└── samconfig.toml
```

---

## Schema (ops_* tables in masterdb)

All ops tables carry `org_id`, **String-UUID PKs**, **Numeric** money (Float retired), and an RLS `org_isolation` policy. Managed by Alembic (at 0008, separate `ops_alembic_version`). The local `users` table is **retired** (auth delegated to masterdb).

| Table | Purpose | Migration |
|-------|---------|-----------|
| `ops_jobs` | Core entity: a roofing/siding/windows job (`crew_id`, `pm_id` refs) | — |
| `ops_invoices` | 1:1 extension of job — financial + workflow status (Numeric money) | — |
| `ops_permits` | 1:1 extension of job — permit tracking | — |
| `ops_materials` | 1:many — materials ordered/delivered for a job | — |
| `ops_notifications` | In-app notifications routed by role on stage advance | — |
| `ops_supplier_quotes` / `ops_supplier_orders` | Supplier search/quote/order (RLS, `idempotency_key`) | 0004 / 0005 |
| `ops_job_contacts` | Multi-contact per job | 0006 |
| (Stripe payment-link + out-of-band invoice fields) | Checkout Session links / cash-check invoices | 0007 / 0008 |

**ops_jobs key fields:** String-UUID PK, `org_id`, `name`, `address`, `trade` (roofing/siding/windows), `stage`, `scheduled_date`, `crew_id` (reference, not a string anymore), `pm_id`, `inspection_passed`, `stage_data` (JSON snapshots — JSON→JSONB+GIN is backlog), `hubspot_id` (legacy), `started_at`.

**ops_invoices:** Numeric money columns (Float retired in the cutover).

---

## Job Lifecycle

Pizza-ticker stages (canonical list in `frontend/stages.js`):

```
New Project → Permitting/Procurement → Scheduling → Active → Complete
(overview → job_prep → schedule → in_progress → closeout)
```

`closeout` / Complete is terminal. Excel/Monday-style **board view** (`/board`) groups by stage; project drill-in + Timeline panel on JobDetail. Full conditions, advance-roles, notification routing, and the commit pattern: [[leo/concepts/ops-lifecycle]].

---

## API Routes

All routes under `/api/`. Auth via `Authorization: Bearer <jwt>`.

| Method | Path | Role Required | Description |
|--------|------|---------------|-------------|
| POST | `/api/auth/login` | none | Email + password → JWT |
| GET | `/api/jobs` | any | List all jobs |
| POST | `/api/jobs` | any | Create job + auto-create invoice |
| GET | `/api/jobs/{id}` | any | Get job with invoice/permit/materials |
| PATCH | `/api/jobs/{id}` | any | Update job fields, triggers advance_if_ready |
| POST | `/api/jobs/{id}/advance` | any | Explicit advance + stage snapshot |
| PATCH | `/api/jobs/{id}/invoice` | billing | Update invoice fields |
| PATCH | `/api/jobs/{id}/permit` | permitting/procurement | Update permit |
| POST | `/api/jobs/{id}/materials` | permitting/procurement | Add material |
| PATCH | `/api/jobs/{id}/materials/{mat_id}` | permitting/procurement | Update material |
| DELETE | `/api/jobs/{id}/materials/{mat_id}` | permitting/procurement | Remove material |
| GET | `/api/notifications/me` | any | Current user's notifications |
| POST | `/api/webhooks/stripe` | none | Stripe webhook (signature-verified) |

---

## Role System

| Role | Access |
|------|--------|
| `admin` | Bypasses all guards |
| `billing` | Invoice endpoints; can advance `overview` stage |
| `permitting` | Permits + materials (forward-looking canonical role) |
| `procurement` | Same as permitting — **legacy**, kept to avoid Postgres enum migration (DEC-005) |
| `dispatch` | Jobs — can advance `job_prep` and `schedule`; route guards TBD |
| `service_manager` | Jobs — can advance `in_progress`; route guards TBD |
| `pm` | Project manager — limited scope (seeded demo users) |

> Roles now map through masterdb (B-lite). `dispatch` + `service_manager` Jobs/Materials route guards are design-TBD — confirm with Leonard before implementing.

---

## SLA Logic

Computed in `frontend/jobUtils.js` (`getSLAStatus`). Applies to jobs in `schedule` or `in_progress` that have a `scheduled_date`.

| Condition | Status |
|-----------|--------|
| Before scheduled date, not started | On Time |
| Day of, not started | At Risk |
| Past date, not started | Late |
| Started on or before scheduled date | On Time |
| Started after scheduled date | Late |

SLA counts appear in MetricBuckets on Home and My Work.

---

## Features Shipped (10-PR session → prod 2026-06-10/11)

| Feature | Notes |
|---------|-------|
| Board view | Excel/Monday-style `/board`, grouped by stage with pizza-ticker labels; canonical `frontend/stages.js` |
| Project drill-in + timeline | JobDetail Timeline panel |
| Critical RLS fix | `after_begin` listener re-applies `SET LOCAL app.current_org_id` + `db.expunge(user)` |
| Crew selection | Crew core model + `/api/crews` dropdown |
| Edit contact | Contact core model, `/api/contacts` GET/POST/PATCH, ContactPanel |
| Multi-contact per job | `ops_job_contacts` (migration 0006) |
| Stripe sandbox | acct `acct_1RgUCICYJB2VMLe8`; webhook `/api/webhooks/stripe` (`checkout.session.completed`, `invoice.paid`). Credit-card Checkout Session links on Overview (0007); out-of-band cash/check via Create Invoice + Mark Received (0008). Per-state Stripe keys (`stripe_accounts.py`, falls back to global). **Webhook signature verification was the key security fix — it had been forgeable + cross-tenant.** |
| Supplier integration | ABC Supply (sandbox creds live, product search working; prod token endpoint `https://partners.abcsupply.com/oauth2/.../v1/token`) + SRS/QXO (Swagger `api.qxo.com`, creds pending). Side-by-side quote comparison (auto-selects lowest total), order from job_prep. `ops_supplier_quotes` + `ops_supplier_orders` with RLS (0004). Falls back to mock until creds arrive. |
| DB indexes | Partial index on active `ops_jobs`, `idempotency_key` on supplier orders (0005) |
| UI polish | Colorblind-safe status indicators (Wong palette diamond/square/triangle); always-on dark theme; "WF Status" → "Financing Status" rename |

---

## Known Bugs

### `permits.py` — double-commit atomicity violation (DEC-006)

`permits.py` calls `db.commit()` **before** `advance_if_ready()`. If a permit update triggers a stage advance, the advance fires in a second implicit commit, not atomically with the permit save.

```python
# Current (wrong):
db.commit()
advance_if_ready(job, db)

# Correct:
advance_if_ready(job, db)
db.commit()
```

### CloseoutForm checklist not persisted

The CloseoutForm 7-item checklist is currently frontend-only state — not persisted to the DB. Known gap.

---

## Ops / Deploy Notes

- **Stack is AWS SAM** (`template.yaml`), us-east-2, Python 3.13 arm64. Not SST.
- **No deploy script yet** — backend deploys are manual.

**Backend (Lambda) — manual:**
```bash
pip3 install --platform manylinux2014_aarch64 --python-version 3.13 \
  --only-binary=:all: -t ./build -r requirements.txt
# zip build/ + backend/, upload to S3, then:
aws lambda update-function-code --function-name gunner-ops-dev-api --s3-bucket ... --s3-key ...
```

**Migrations (prod):** `ops_app` lacks DDL privileges. Run Alembic via `migrate.handler` with `MIGRATE_DATABASE_URL` set to the **admin** URL, then restore the env afterward.

**Frontend (S3 + CloudFront):**
```bash
cd frontend
npm run build
aws s3 sync dist/ s3://gunner-ops-dev-frontend-980921733684 --delete
aws cloudfront create-invalidation --distribution-id EG6TNJ5ETLV64 --paths "/*"
```

**Environment:** frontend reads `VITE_GOOGLE_PLACES_KEY` from `.env.local` (gitignored), restricted to CloudFront + localhost in GCP.

> ⚠ CRITICAL: credential present — not copied. The Google Places key lives in `.env.local`; ask Leonard for a copy rather than generating a new one (existing key has the correct domain restrictions). Value not transcribed here.

---

## Backlog / Pending Work

| Item | Priority | Notes |
|------|----------|-------|
| Rotate `ops_app` DB password + JWT secret to Secrets Manager | **High** — before go-live | Currently inline |
| SRS/QXO supplier credential wiring | Medium | ABC Supply sandbox already live; SRS falls back to mock |
| Deploy script | Medium | Deploys currently manual |
| `stage_data` JSON → JSONB, then GIN index | Medium | Currently JSON |
| Cursor pagination | Medium | Lists unpaginated |
| Collapse cash/check Stripe flow to single "Record Payment" | Low — parked | Currently Create Invoice + Mark Received |
| `permits.py` double-commit | Low | Still present — see Known Bugs |
| `dispatch` + `service_manager` job guards | Low | Design TBD — discuss with Leonard |
| `procurement` role removal | Low | Postgres enum value removal requires a full migration |
| Offline strategy (IndexedDB / Service Worker) | Low | Not started |
| QP company-pull + deep-link | Deferred | — |

---

## masterdb Integration — DONE (cutover 2026-06-10)

gunner-ops no longer has its own isolated RDS instance — it lives **inside masterdb** (the shared Aurora data layer for all Gunner apps) as a multi-tenant, RLS-isolated app. Cross-app data goes through API calls, **not** cross-schema queries.

| Concern | Before | As-built |
|---------|--------|----------|
| Multi-tenancy | None — single org | `org_id` on every ops table; RLS `org_isolation` on all |
| Primary keys | Integer | String-UUID (masterdb convention) |
| Money | Float | `Numeric` |
| Users | Local `users` table | **Retired** — auth delegated to masterdb (B-lite) |
| Crews | String field on `jobs` | `crew_id` reference (Crew core model, `/api/crews`) |
| RBAC / auth | Flat role enum, local JWT | masterdb `/v1/auth/login`; ops validates HS256 `{sub, org_id}`; RLS via `SET LOCAL app.current_org_id` |
| Migrations | `create_all` only | Alembic at 0008 (`ops_alembic_version`) |
| Schema home | Isolated RDS Postgres | ops_* tables inside PROD masterdb Aurora |

**Do not:** add cross-schema direct queries (use API for cross-app data); run DDL as `ops_app` (no DDL privilege — use `migrate.handler` + `MIGRATE_DATABASE_URL` admin, then restore); remove the `procurement` role without a migration ready.

Detail: [[leo/apps/masterdb-integration]]. Host DB architecture: [[gunnerteam/masterdb-architecture]].

---

## Architectural Decisions

- **DEC-001:** SAM over SST — predates masterdb decision, working and deployed (still SAM).
- **DEC-002:** Single `models.py` + `schemas.py` — app small enough; revisit at ~300 lines.
- **DEC-003:** ~~`create_all` not Alembic~~ — **RESOLVED:** Alembic adopted (at 0008, separate `ops_alembic_version`).
- **DEC-004:** ~~Integer PKs~~ — **RESOLVED:** migrated to String-UUID PKs in the masterdb cutover.
- **DEC-005:** `procurement` role kept — Postgres enum value removal is a full migration.
- **DEC-006:** `advance_if_ready` does not commit — callers own the commit cycle (still violated in `permits.py`).
- **DEC-007:** ~~Stripe placeholder~~ — **RESOLVED:** Stripe sandbox live; webhook signature verification implemented (key security fix).
- **DEC-008:** Auth delegated to masterdb (B-lite) — no local users; ops validates HS256 `{sub, org_id}` and enforces RLS via `SET LOCAL app.current_org_id`.

---

## Questions to Confirm with Leonard

- `dispatch` + `service_manager` role guards on Jobs/Materials routes — design TBD.
- Go-live readiness (~2026-06-26): secrets rotation, SRS creds, real-data migration off demo data.
- Whether `started_at` on jobs needs DB tracking (currently only set via InspectionForm).
