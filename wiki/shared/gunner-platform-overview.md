---
type: synthesis
title: Gunner Platform Overview
created: '2026-06-29'
updated: '2026-06-29'
tags:
  - ecosystem
  - overview
  - infrastructure
  - onboarding
  - shared
status: stable
related:
  - '[[gunnerteam/overview]]'
  - '[[colin/overview]]'
  - '[[leo/overview]]'
  - '[[doug/overview]]'
  - '[[tyler/masterdb/masterdb-architecture]]'
  - '[[gunnerteam/aws-environment]]'
  - '[[gunnerteam/soc2-technical-summary]]'
  - '[[shared/entities/Eric Recchia]]'
---

# Gunner Platform Overview

High-level map of every application and the shared infrastructure beneath them. Written to orient anyone setting up or integrating with Gunner's engineering stack.

---

## What We're Building

Gunner is replacing a patchwork of third-party SaaS tools (project management, CRM, quoting, photos, notes, reviews) with a unified, in-house platform. Every piece runs on AWS (account `980921733684`, `us-east-2`) and shares a single Aurora PostgreSQL cluster (**masterdb**) as the data foundation.

---

## The Shared Foundation

**masterdb — Aurora PostgreSQL 17 (Serverless v2)**

The single database cluster every app writes to. Multi-tenant; each row carries `org_id`. Row-Level Security enforces tenant isolation at the DB layer. Auth flows through AWS Cognito. IaC is split: the DB cluster is managed by a `gunner-masterdb` SST/Pulumi stack; the app layer above it (Lambda, API Gateway, S3, Cognito) is Terraform.

See [[tyler/masterdb/masterdb-architecture]] for the full schema / RLS model.

---

## Applications

### 1. GunnerTeam iOS (Tyler)

Native Swift/SwiftUI app for field crews. Covers jobs, guided phase workflows, task checklists, photo capture, fleet/vehicle inspections, change orders, and forms.

- **Backend:** Node.js/Express Lambda (`gunnerteam-dev-api`, alias `live`) + API Gateway + Cloudflare
- **Database:** masterdb Aurora (connects as `gunnerteam_app`)
- **Deploy:** S3-staged zip → publish version → alias promotion
- **Repo:** `GunnerRoofing/gunner-ios` (monorepo: `GunnerForms/` iOS + `gunnerteam-api/` Lambda)

See [[gunnerteam/overview]], [[gunnerteam/aws-environment]].

### 2. GunnerCam (Colin)

Web field-operations platform for PMs and crews (phone or laptop). System of record for a job: photos, files, comments, status, task assignments, activity feed. Built to white-label to 50+ paying tenants without a rewrite.

- **Stack:** Next.js 16 App Router, React 19, Tailwind v4, Drizzle ORM
- **Hosting:** Lambda + CloudFront via SST v4
- **Database:** Own dedicated RDS Postgres 16 (separate from masterdb)
- **Key integrations:** GunnerTeam iOS (server-to-server API), Monday.com sync, Stripe invoicing, Dialpad
- **Repo:** `GunnerRoofing/gunner-cam` (or equivalent)

See [[colin/overview]].

### 3. gunner-ops / "Leo" (Leo)

Internal job-management CRM replacing Monday.com. Tracks roofing/siding/windows jobs from intake through closeout via a 5-stage pizza-ticker lifecycle (`overview → job_prep → schedule → in_progress → closeout`).

- **Stack:** Python 3.13 arm64 Lambda, FastAPI + Mangum, SQLAlchemy 2.x + Alembic, React + Vite frontend
- **Hosting:** AWS SAM, S3 + CloudFront
- **Database:** Lives inside masterdb Aurora (own `ops_*` tables, connects as `ops_app` role with RLS isolation)
- **Key integrations:** Stripe (payments), ABC Supply + SRS (material quotes), Google Places (address autocomplete)
- **Repo:** `GunnerRoofing/gunner-ops`

See [[leo/overview]].

### 4. Quote Portal / QP (Impressico, India team)

Existing sales-to-contract portal. Handles the full lead → measure → quote → proposal → contract → payment lifecycle.

- **Stack:** Node.js 22 Lambdas (~128 functions), Next.js 16 frontends
- **Database:** Own Aurora cluster (`dev-gunner-aurorapgdb-db-cluster`) — separate from masterdb
- **Key integrations:** DocuSign, Stripe, GAF/Hover, HubSpot
- **Note:** Owned externally; Tyler's team integrates with it but doesn't own the codebase

### 5. Doug's Marketing Tools (Doug)

Four standalone apps:

| App | Status | What it does |
|---|---|---|
| **Lead Finder** | Live | Sources and surfaces new sales leads |
| **Review Engine** | Early | Collects and manages customer reviews |
| **Content Creator** | Live | Cron-scheduled poster to WordPress, Facebook, X (Google AI for generation) |
| **WP Local Page Template** | In progress | Templated WordPress landing pages for local markets |

See [[doug/overview]].

### 6. Window Measurement Quoting Tool (Eddie Prchal)

Standalone tool for measuring windows and generating quotes. Early stage — AWS infrastructure TBD.

### 7. Gunner Notes (Eric Recchia)

Internal team meeting notes and knowledge-management tool. Eric (VP of Strategy) is leading. Early stage — infrastructure TBD.

---

## Shared Infrastructure

| Layer | What's There |
|---|---|
| **Cloud** | AWS, single account `980921733684`, `us-east-2` |
| **Database** | Aurora PostgreSQL 17 Serverless v2 — one cluster (masterdb), shared by GunnerTeam + gunner-ops |
| **Auth** | AWS Cognito User Pool `us-east-2_hFVBSrcnn`; IAM Identity Center SSO + MFA enforced for engineers |
| **Compute** | Lambda (Node.js for GunnerTeam; Python for gunner-ops); API Gateway HTTP APIs |
| **CDN / Edge** | CloudFront (GunnerCam, gunner-ops frontend); Cloudflare (GunnerTeam API edge + DNS) |
| **Storage** | S3 — separate buckets per app (photos, audit logs, deploy artifacts, Dialpad recordings) |
| **Secrets** | SSM SecureString (runtime fetch — zero secrets baked into Lambda env); Secrets Manager for DB creds |
| **IaC** | Terraform (GunnerTeam app layer) + SST v4 (GunnerCam) + SAM (gunner-ops) + SST/Pulumi (masterdb cluster) |
| **CI/CD** | GitHub Actions — syntax check, SAST (Semgrep + Bandit for masterdb), dep audit, SBOM, unit tests |
| **Monitoring** | CloudWatch alarms → SNS → email + Google Chat; EventBridge scheduled tasks; audit log S3 WORM (7yr Object Lock) |
| **MDM** | Apple Business Manager + Hexnode (iOS device management for field crews) |
| **Repos** | All under `GunnerRoofing/` GitHub org |

---

## How the Apps Connect

```
Crews (iOS)
  └─► GunnerTeam API (Lambda/Node)
        ├─► masterdb Aurora (jobs, users, audit)
        ├─► GunnerCam API (photos, project data)
        └─► Dialpad (call logs, transcripts, recordings → S3)

PMs / Managers (browser)
  └─► GunnerCam (Next.js / CloudFront)
        ├─► GunnerCam RDS (own Postgres)
        ├─► Monday.com (sync)
        └─► Stripe (invoicing)

Ops team (browser)
  └─► gunner-ops (FastAPI / CloudFront)
        ├─► masterdb Aurora (ops tables, RLS-isolated)
        ├─► Stripe (payments)
        └─► ABC Supply / SRS (material quotes)

Sales (browser)
  └─► Quote Portal (Node Lambdas / own Aurora)
        ├─► DocuSign, Stripe, GAF/Hover
        └─► HubSpot (being phased out)

Marketing (automated)
  └─► Doug's tools → WordPress, Facebook, X
```

---

## Key People

| Person | Role | Owns |
|---|---|---|
| [[shared/entities/Tyler Suffern\|Tyler Suffern]] | IT / iOS / Backend | GunnerTeam iOS + API, masterdb platform, AWS infra |
| Colin Manning | Full-Stack | GunnerCam (field-ops web platform) |
| Leo (Leonard) | Full-Stack | gunner-ops CRM |
| Doug | Marketing Tech | Lead Finder, Review Engine, Content Creator, WP Templates |
| Eddie Prchal | Full-Stack | Window measurement quoting tool |
| [[shared/entities/Eric Recchia\|Eric Recchia]] | VP of Strategy / System Owner | Gunner Notes; formal IT governance owner (SSP) |

---

## What's Not Done Yet (Open Infrastructure Items)

- **No true prod/dev split** — everything runs in one AWS dev account. Separating a real production account is the biggest open infra item before real customer onboarding.
- **Gunner Notes and window quoting tool** — no AWS infrastructure provisioned yet.
- **Cloudflare WAF** — planned, waiting on Cloudflare Pro tier.
- **Tested disaster recovery drill** — not yet run against live infrastructure.
- **gunner-ops go-live** — first real users expected late June/July 2026; currently in dev with demo data.
- **QP: NY Stripe routing bug + committed secrets** — known issues, owned by the India team.

---

## Security Posture (summary)

SOC 2 Common Criteria coverage is strong for the GunnerTeam app layer. Key controls live:

- Cognito auth + `requireAuth` on every route
- Tenant isolation via `org_id` + RLS
- Zero secrets in Lambda env (all SSM runtime fetch)
- TLS everywhere, S3 TLS-only policy, Aurora `force_ssl`
- CI: SAST (Semgrep), dep audit, SBOM per run
- Audit log → WORM S3 (7yr Object Lock)
- CloudWatch alarms → Google Chat

See [[gunnerteam/soc2-technical-summary]] and [[gunnerteam/security-compliance-roadmap]] for the full control posture and roadmap.
