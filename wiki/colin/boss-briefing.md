---
type: reference
owner: colin
app: GunnerCam
created: 2026-05-07
updated: 2026-05-07
tags: [wl-companycam, briefing, aws, saas]
status: active
---

# Gunner Project Hub — Boss Briefing

Tags: #wl-companycam #briefing #aws #saas
Date: 2026-05-07

---

## 1. What it is, in one paragraph

A web replacement for **CompanyCam**. PMs and crews open it on a phone or laptop, find a roofing project (each project = a customer's address), and use it as the system of record for that job: photos, files, comments, status changes, who's assigned. Today it serves Gunner only. The product is intentionally built so we can resell the same software, white-labeled, to other roofing companies (50+ tenants is the design target). Every architectural choice traces back to that endgame.

## 2. It's already running

- **Live URL:** `https://d2gd0tqb1r9ceg.cloudfront.net` (dev stage on AWS)
- **What's running:** three AWS Lambda functions (web server, image optimizer, page revalidation), CloudFront in front, RDS Postgres behind, S3 for files, Cognito for logins. Last deploy: 2026-05-06.
- **Git posture:** one commit on `main`. MVP just reaching shore — no production users yet, no PR history.

---

## 3. Tech stack

| Concern | Choice | Why |
|---|---|---|
| Web framework | Next.js 16 (App Router) | UI + APIs in same codebase |
| Auth | AWS Cognito | Managed identity, free up to 50k MAU |
| Database | RDS Postgres 16 (`wl-companycam-dev`, us-east-2) | Standard relational DB |
| File storage | S3 bucket `wl-companycam-dev-cw` | Photos and files (private bucket) |
| Hosting | AWS Lambda + CloudFront via SST | Pay-per-request, no idle cost |
| ORM / migrations | Drizzle | Schema in code, versioned SQL |
| AWS account | `980921733684`, region us-east-2, profile `devops` | One account, all infra |

---

## 4. How the three core AWS services fit together

**There is no direct connection between RDS, S3, and Cognito. The Next.js app is the bridge between all three.**

### What each one is

- **RDS (Postgres database):** Stores all *structured* data — users, projects, comments, photos *metadata*, files *metadata*, activity feed. Like a giant Excel sheet with relationships.
- **S3 (file bucket):** Stores actual *file bytes* — JPEGs, PDFs. Not a database. You hand it a file + a "key" (filename like `photos/abc/123.jpg`), it stores the bytes. No queries, no joins.
- **Cognito (identity service):** Stores usernames + hashed passwords. Issues JWT tokens after login. Doesn't know anything about the business.

### The pattern

> Specialized AWS service stores the heavy/specialized thing. RDS stores a string that points to it, plus all the structured business data around it.

- S3 stores the photo bytes; RDS stores the `s3_key` plus uploader/project/caption.
- Cognito stores the credentials; RDS stores `cognito_sub` plus the user's role/corp/name.

### Photo upload flow

```
1. Browser → app:     "I want to upload to project X"
2. App → S3:          "Give me a presigned URL"
3. App → browser:     URL
4. Browser → S3:      [direct upload — bytes never touch our server]
5. Browser → app:     "Done. Key is photos/abc/123.jpg"
6. App → RDS:         INSERT INTO photos (s3_key, project_id, ...)
```

**Compute bill stays flat regardless of photo volume** — bytes don't go through Lambda.

### Login flow

```
1. Browser → app:     username + password
2. App → Cognito:     "Are these valid?"
3. Cognito → app:     JWT token containing sub = abc-123
4. App → browser:     Sets HTTP-only cookie

Later requests:
5. App verifies JWT signature locally (no Cognito call)
6. App → RDS:         SELECT * FROM users WHERE cognito_sub = 'abc-123'
7. App now knows role, corporation, etc.
```

---

## 5. Data model highlights

Source: `src/db/schema.ts`. UUID PKs, soft-delete only (`deleted_at`), `corporation_id` on every domain table.

### Core tables

- **`corporations`** — the tenant. Gunner is row 1.
- **`users`** — Gunner employees. Mirrored to Cognito by `cognito_sub`. Roles: admin / manager / standard / restricted.
- **`crews`** + **`crew_members`** — subcontractors. Crews are cross-tenant.
- **`projects`** — the spine. Customer info, status, primary PM, labels.
- **`project_users`** / **`project_crews`** — who's assigned.
- **`photos`** / **`files`** / **`comments`** — content (S3 keys, never bytes).
- **`updates`** — the activity feed engine. One row per event.

### Clever bits

- **`bucket_day` is a stored generated column** on `updates`: auto-computed as the calendar day in Eastern Time. Indexed. Makes the day-grouped activity feed instant even with thousands of events.
- **`external_ids` JSONB**: integration IDs (Quote Portal, Monday, HubSpot, Stripe) live in one JSON column with a GIN index. Adding new integrations doesn't require migrations.
- **Polymorphic creator** (`creator_id` + `creator_type`): records can be authored by user / crew_member / integration / system. One pattern handles all four.

### Permissions

| Role | Sees |
|---|---|
| Admin / Manager | All projects in their corp |
| Standard user | Only projects assigned via `project_users` |
| Crew member | Only projects whose crew (`project_crews`) they belong to |

Centralized in `src/lib/dal.ts` (`assertCanReadProject`, `assertCanManageProject`).

---

## 6. Cost breakdown

### Today (1 corp, ~5 testers)

| Service | Estimated monthly |
|---|---|
| RDS Postgres (`db.t4g.micro`, 20 GB) | ~$15–18 |
| Lambda | ~$0–1 |
| CloudFront | ~$0 |
| S3 | ~$0–1 |
| Cognito | $0 |
| CloudWatch | ~$0–1 |
| **Total** | **~$15–22/mo** |

### At ~50 active users (full Gunner rollout)

| Service | Estimated monthly |
|---|---|
| RDS (bumped to `db.t4g.small`, possibly Multi-AZ) | ~$30–60 |
| Lambda | ~$5–15 |
| S3 storage | ~$5–15 |
| S3 + CloudFront egress | ~$5–15 |
| **Total** | **~$50–115/mo** |

### At 10 paying corps × 30 users = 300 users

| Service | Estimated monthly |
|---|---|
| RDS + RDS Proxy | ~$95–215 |
| Lambda + S3 + CloudFront | ~$60–160 |
| **Total** | **~$180–450/mo** (~$0.60–$1.50 per user) |

### At 100 corps × 50 users = 5,000 users

**~$1,000–2,500/mo** (~$0.20–$0.50 per user)

CompanyCam charges ~$45/user/month. Even at $20/user/month pricing, gross margin is **95%+**.

---

## 7. SaaS-readiness scorecard

| Capability | Built? | Notes |
|---|---|---|
| Multi-tenant data model | ✅ | `corporation_id` everywhere |
| Pay-per-use hosting | ✅ | Lambda + CloudFront |
| Per-tenant S3 isolation | ⚠️ Partial | Key prefixes only; one shared bucket |
| Soft-delete / audit | ⚠️ Partial | `deleted_at` yes; audit table no |
| Custom domain per tenant | ❌ | |
| Per-tenant branding | ❌ | Schema field exists; UI doesn't read it |
| Tenant billing (Stripe Billing) | ❌ | |
| Stripe Connect | ❌ | |
| PandaDoc signing | ❌ | |
| Quote Portal sync | ❌ | |
| SOC 2 readiness | ❌ | Foundations partial |

---

## 8. Long-term risks (what could stop it from running)

Ordered by likelihood × impact.

### 1. Shared dev/prod environment — WILL cause an incident

`.env.local` and the deployed Lambda point at the same RDS + S3. A misdirected migration or seed will eventually hit prod. **Fix:** split into two SST stages. ~2–3 days work.

### 2. Bleeding-edge framework stack

Next.js 16 + OpenNext + SST is a fragile combination. OpenNext already lags Next 16 features (see comment in `src/middleware.ts`). A future Next.js patch could break deploys. **Fix:** pin exact versions, add CI build check. ~1 day.

### 3. Database connection exhaustion

Connection pool is `max: 1` per Lambda. RDS `db.t4g.micro` accepts ~90 connections. Around **80 concurrent users = app down**. **Fix:** RDS Proxy (~$15/mo). ~half day.

### 4. RDS storage fill-up

20 GB instance + soft-deletes never removing data + activity feed growing forever = fills up in 6–18 months. RDS auto-scaling may not be enabled. **Fix:** enable storage auto-scaling. 30 minutes.

### 5. Region-level AWS outage

All in us-east-2. No multi-region. Annual exposure = a few hours of downtime when AWS has incidents. **Fix:** expensive multi-region setup, defer until SLAs demand it.

### Other things that will degrade product

- **Orphan S3 files** — uploads that never get confirmed accumulate forever. No cleanup job, no unique constraint on `s3_key`.
- **Sessions die every hour** — refresh token rotation not built. Users get bounced to login mid-day.
- **Unbounded photo size** — presigned URL has no max-size policy.
- **No background workers** — blocks variants pipeline, email invites, Quote Portal sync.
- **Photo originals served full-size** — slow on cell networks at job sites.

### Technical debt that compounds

- No tests, no CI
- No error monitoring (Sentry/Datadog)
- No audit log table (SOC 2 future)
- `creator_name` denormalization drifts when users rename
- `primary_pm_id` on projects can drift from join table
- Cross-tenant isolation in app code only (no Postgres RLS)

---

## 9. Open architectural decisions

Listed in `DECISIONS.md`. Mostly business calls the boss can help unblock.

1. Postgres host: Aurora Serverless v2 vs RDS Postgres
2. Next.js hosting: Amplify vs OpenNext (current) vs ECS
3. Infra-as-code: Terraform vs CDK
4. S3 layout: single bucket prefix vs bucket-per-corp
5. PandaDoc: shared corp account vs per white-label
6. Stripe Connect: Standard vs Express
7. Cognito: one pool with claims vs pool-per-corp
8. Crew member auth: separate Cognito app vs shared

---

## 10. Bottom line

**Asset, not liability.** Architecture is sound: multi-tenant from row 1, proper separation of bytes from data, centralized permissions, type-safe end-to-end.

**Not yet production-grade.** Missing CI, tests, monitoring, separate environments, rollback story.

**Roughly 3–4 weeks of focused ops work** to graduate from "MVP that runs because nobody's pushing it" to "production system that can run unattended."

**Roughly 1–2 months of feature work** to get from "internal Gunner tool" to "sellable to customer #2" — branding, custom domains, billing, email invites, password resets, at least one differentiating integration.

---

## Quick reference

- Repo: `~/repos/WL-CompanyCam`
- Schema: `src/db/schema.ts`
- Auth helpers: `src/lib/dal.ts`, `src/lib/cognito.ts`, `src/lib/session.ts`
- S3 helpers: `src/lib/s3.ts`
- Decisions doc: `DECISIONS.md`
- User guide: `USER_GUIDE.md`
- MVP roadmap: `tickets/MVP_ROADMAP.md`
- Live URL: `https://d2gd0tqb1r9ceg.cloudfront.net`
- AWS profile: `devops` (account 980921733684, us-east-2)
- Cognito User Pool: `us-east-2_sEOcsFA76`
- RDS: `wl-companycam-dev.c52gm8goign8.us-east-2.rds.amazonaws.com:5432`
- S3 bucket: `wl-companycam-dev-cw`
