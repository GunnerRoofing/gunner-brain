---
title: GunnerTeam API — Cloudflare → AWS Migration
type: gunner
tags:
  - gunner
  - aws
  - express
  - postgresql
  - rds
  - ec2
  - terraform
  - architecture
  - saas
  - multi-tenancy
created: '2026-05-06'
updated: '2026-05-07'
sources: []
related:
  - '[[gunner/gunner-forms-app]]'
  - '[[gunner/aws-environment]]'
status: in-progress
---

# GunnerTeam API — Cloudflare → AWS Migration

## Decision

Migrate the GunnerTeam backend from Cloudflare Workers + D1 (SQLite) to Express.js + RDS PostgreSQL on AWS. This is a prerequisite for white-labeling, SaaS multi-tenancy, and government compliance targets.

**Why Cloudflare Workers were the wrong foundation at scale:**
- D1 (SQLite) has no row-level security, no real multi-tenancy primitives
- Workers are stateless and can't maintain a real DB connection pool
- No native support for compliance frameworks (SOC 2, FedRAMP)
- Locked into Anil Nair's Cloudflare account — not operationally owned by Gunner/Tyler

## Architecture

### Current (Cloudflare)
```
iOS App → Cloudflare Worker (worker.js) → D1 SQLite (anil-nair account)
                                        → S3 (photo storage)
```

### Target (AWS — EC2 phase, live as of 2026-05-07)
```
iOS App → Express.js on EC2 (t3.small, 3.134.224.29:3000) → RDS PostgreSQL (gunnerteam-dev)
                                                            → S3 (gunner-fleet-dev)
```

### Scaling path
```
EC2 t3.small (internal testing — CURRENT)
  → EKS (Kubernetes) with Helm charts per tenant
    → Multi-region + GovCloud (government contracts)
```

**EC2 → EKS migration effort:** Low. Express code containerizes in ~20 lines of Dockerfile. Terraform is ~80% reusable. Auth migration (JWT → Cognito) is the only hard part — existing passwords can't transfer, requires re-invite flow.

## Infrastructure (Terraform-managed)

All infrastructure is in `/Users/tyler.suffern/Documents/Gunner/GunnerTeam/terraform/`. State stored in S3 (`gunnerteam-terraform-state`, `gunnerteam/terraform.tfstate`).

| Resource | Value |
|----------|-------|
| EC2 instance | `i-002be9ba8cdfbf0da` (t3.small, AL2023, us-east-2b) |
| Elastic IP | `3.134.224.29` (stable across stop/start) |
| API security group | `sg-07790fe3c3e2341b9` (gunnerteam-dev-api) |
| RDS security group | `sg-0dc18b0d8cd6972fe` (gunnerteam-dev-rds) |
| IAM role | `gunnerteam-dev-ec2` (S3 + SSM policies) |
| SSH key | `gunnerteam-ec2` (`~/.ssh/gunnerteam-ec2`) |

**Security group rules (EC2):** Ports 80, 443, 3000, 22 inbound from 0.0.0.0/0. Port 22 added for EC2 Instance Connect / SSH access. Remove or restrict in prod.

**Security group rules (RDS):** Port 5432 from EC2 SG only. Optional `dev_ip` variable for direct psql access from workstation.

**Known SSM issue:** SSM agent shows offline on this instance despite correct IAM policy. Root cause unknown. Workaround: SSH via key pair (`~/.ssh/gunnerteam-ec2`). Investigate before prod — SSM is preferred over open port 22.

## EC2 Deployment

App runs as the `app` OS user, managed by PM2.

```bash
# SSH access
ssh -i ~/.ssh/gunnerteam-ec2 ec2-user@3.134.224.29

# App location
/home/app/gunnerteam-api/

# PM2 commands (run as root or with sudo -u app)
sudo -u app pm2 status
sudo -u app pm2 logs gunnerteam-api
sudo -u app pm2 restart gunnerteam-api
```

**Redeploy after code push:**
```bash
cd /home/app/gunnerteam-api
git pull  # once repo has the code
sudo -u app npm install --production
sudo -u app pm2 restart gunnerteam-api
```

Currently code was deployed via `scp` from Mac (GitHub repo didn't have `gunnerteam-api/` yet at first boot). Push to GitHub and update user_data.sh git clone path for future instances.

## Multi-Tenancy Design

Every table has `tenant_id INTEGER NOT NULL DEFAULT 1`. Default tenant = 1 (Gunner Roofing).

**Row-Level Security (PostgreSQL RLS):**
- Express sets `SET LOCAL app.current_tenant_id = '<id>'` on every DB connection before any query
- RLS policy on every table: `USING (tenant_id = current_setting('app.current_tenant_id', TRUE)::INTEGER)`
- Even a buggy query cannot leak cross-tenant data — enforced at the database level
- Superuser (migrations) bypasses RLS automatically

**Adding a new tenant** = one INSERT into `tenants` table. No schema changes, no new database.

**Tenant resolution at login:** iOS app sends `subdomain` field with login request. Backend resolves tenant from `tenants.subdomain` before any user lookup.

## Express.js Project Structure

**Location:** `/Users/tyler.suffern/Documents/Gunner/GunnerTeam/gunnerteam-api/`

```
src/
  app.js                   # Express entry point, route mounting, health check
  lib/
    db.js                  # pg pool; queryWithTenant() sets RLS context per request
    crypto.js              # PBKDF2 (SHA-512, 100k iterations) — matches worker format
    jwt.js                 # sign/verify JWT (jsonwebtoken package, 7d expiry)
    s3.js                  # AWS SDK v3 upload + proxy download (GetObjectCommand)
    apns.js                # @parse/node-apn v7 push notifications
    email.js               # Resend API + email templates
  middleware/
    auth.js                # requireAuth (JWT verify), requireRole(...roles)
  routes/
    auth.js                # login, validate, register, invite, forgot/reset, device-token
    users.js               # GET/PATCH/DELETE users
    announcements.js       # GET/POST/DELETE announcements
    fleet/index.js         # ALL vehicle routes (inspections, schedules, fleet, reports, photo proxy)
```

**Key implementation decisions:**

| Decision | Rationale |
|----------|-----------| 
| PBKDF2 SHA-512 100k iterations | Must match Cloudflare Worker hash format — migrated passwords work without forced reset |
| `queryWithTenant()` wrapper | Acquires client, sets RLS context, runs query, releases — tenant isolation on every call |
| Individual DB env vars (not DATABASE_URL) | Password contains `#` which dotenv parses as a comment if unquoted in a connection string |
| S3 photo proxy (`GET /vehicle/photo?key=...`) | Private S3 objects; iOS `TokenImage` view sends Bearer token; proxy fetches S3 with AWS SDK |
| `multer` v2 + memoryStorage | File uploads held in memory, uploaded to S3 directly — no disk I/O on server |
| `@parse/node-apn` v7 | v6 depended on vulnerable `node-forge`; v7 resolves this |

**dotenv `#` comment bug:** If a DB password contains `#`, dotenv truncates the value at the `#` unless the value is quoted. Always quote passwords in `.env`: `DB_PASSWORD="pass#word"`.

## Secrets Management (SSM Parameter Store)

As of 2026-05-14, **no `.env` file exists on EC2.** All 22 config values are stored in AWS SSM Parameter Store at `/gunnerteam/dev/<KEY>`.

- 7 SecureString (KMS-encrypted): `DB_PASSWORD`, `JWT_SECRET`, `RESEND_API_KEY`, `MONDAY_API_TOKEN`, `COMPANYCAM_API_KEY`, `COMPANYCAM_WEBHOOK_SECRET`, `ANTHROPIC_API_KEY`
- 15 String: DB connection config, APNs IDs, S3 buckets, ports, API URLs, etc.

**Bootstrap:** `start.sh` in the repo root fetches all params at startup and exports them as env vars before `exec node src/app.js`. PM2 runs `start.sh`, not `app.js` directly.

**EC2 IAM role** (`gunnerteam-dev-ec2`) has `ssm:GetParameter/GetParameters/GetParametersByPath` scoped to `arn:aws:ssm:us-east-2:*:parameter/gunnerteam/dev/*`.

To update a secret: `aws ssm put-parameter --name "/gunnerteam/dev/KEY" --value "newval" --type SecureString --overwrite`, then `pm2 restart gunnerteam-api`.

## RDS Instance

| Property | Value |
|----------|-------|
| Identifier | `gunnerteam-dev` |
| Engine | PostgreSQL 18.3 |
| Class | db.t4g.micro |
| Region | us-east-2 (Ohio) |
| Endpoint | `gunnerteam-dev.c52gm8goign8.us-east-2.rds.amazonaws.com` |
| Database | `gunnerteam` |
| Master user | `gunnerapp` |
| Public access | No — `publicly_accessible = false` applied 2026-05-14 |
| Backup retention | 7 days |

**Schema applied:** `schema-postgres.sql` — all tables, indexes, RLS policies, triggers confirmed clean.

**Seeded data:** Tenant 1 (`gunner`, Gunner Roofing) + admin user `tyler.suffern` seeded via `seed.js`.

## Compliance Roadmap

| Target | Timeline | Prerequisites |
|--------|----------|---------------|
| SOC 2 Type II | ~1-2 years | Audit log (done), access controls, monitoring, pen test |
| ISO 27001 | ~2 years | SOC 2 foundation + documentation |
| CMMC Level 2 | ~2-3 years | Separate GovCloud stack, NIST 800-171 controls |
| FedRAMP | 4-5 years | CMMC + formal 3PAO assessment |

**GovCloud strategy:** Same Docker image, different deployment — `us-gov-east-1` region, no shared infra with commercial tenants, air-gapped from commercial AWS account.

## White-Label / SaaS Strategy

- App name and branding will change (not finalized)
- Bundle ID change = new APNs certificates + new App Store listing
- DB schema, Express code, and all business logic have zero brand names
- Subdomain-based tenant routing: `acmeroofing.gunnerteamapp.com` → resolves tenant → scoped data
- Future: Stripe per-tenant billing, per-tenant SSO (Cognito SAML/OIDC)

## Current Status (2026-05-14)

- [x] PostgreSQL schema designed and applied to RDS
- [x] Express.js project scaffolded with all routes ported from worker.js
- [x] Terraform infrastructure deployed (EC2, EIP, SGs, IAM, RDS)
- [x] EC2 instance running Express API via PM2 (`app` user, `/home/app/gunnerteam-api/`)
- [x] DB connection verified — login returns JWT token
- [x] **RDS `publicly_accessible = false`** — applied 2026-05-14
- [x] **Audit logging live** — `audit_logs` table + 33 events across all routes — 2026-05-14
- [x] **Secrets in SSM Parameter Store** — `.env` deleted from EC2 — 2026-05-14
- [ ] Push `gunnerteam-api/` to GitHub (deployed via scp currently)
- [ ] Migrate D1 data → RDS
- [ ] Set up HTTPS (ACM cert + ALB or nginx) before external users
- [ ] Switch `APNS_PRODUCTION=true` before ABM/Hexnode deploy
- [ ] Re-invite all GunnerTeam users to new DB
- [ ] SOC 2: access reviews process, backup restore test, Node v22 upgrade

## Route Prefix

Express routes are mounted **without an `/api/` prefix**:

```
POST /auth/login        ← correct
POST /api/auth/login    ← 404 Not Found
```

All iOS `URL(string:)` calls and curl tests must use the bare path. `{"error":"Not found"}` from a known route = wrong prefix.

## Related

- [[gunner/gunner-forms-app]] — iOS app; base URL will point to this Express server
- [[gunner/aws-environment]] — existing AWS infrastructure context
