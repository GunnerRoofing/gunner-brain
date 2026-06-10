---
title: SOC 2
type: concept
tags: [soc2, compliance, audit, trust-services-criteria, aicpa]
created: 2026-05-15
updated: 2026-05-15
status: developing
sources: []
related:
  - "[[gunner/system-security-plan]]"
  - "[[gunner/aws-environment]]"
  - "[[ciso-track/roadmap]]"
---

# SOC 2

Service Organization Control 2. An auditing framework developed by the AICPA for service organizations, evaluating how customer data is managed. Based on Trust Services Criteria (TSC).

## Trust Services Criteria

| Category | Abbreviation | Focus |
|----------|-------------|-------|
| Security | CC | Protection against unauthorized access (Common Criteria) |
| Availability | A | System availability per SLA commitments |
| Processing Integrity | PI | Complete, accurate, timely processing |
| Confidentiality | C | Information designated as confidential |
| Privacy | P | Personal information per AICPA privacy principles |

Security (Common Criteria) is the only mandatory category. Most SaaS companies pursue Security + Availability.

## Type I vs. Type II

| Type | What it proves | Typical timeline |
|------|---------------|-----------------|
| Type I | Controls are suitably designed — point-in-time snapshot | Weeks to months |
| Type II | Controls are operating effectively — sustained over a period | 6–12 month observation window |

Type II is what enterprise customers and enterprise sales require. Type I is a stepping stone.

## At Gunner

SOC 2 readiness is an active initiative tied to the federal market expansion strategy ([[gunner/federal-market]]) and enterprise client requirements.

### Phase 1 — Completed 2026-05-14 / 2026-05-15

| Finding | Remediation | Status |
|---------|-------------|--------|
| EC2 `user_data` contained `db_password` + `jwt_secret` readable via IMDSv1 | EC2/ALB destroyed; all traffic on Lambda | ✅ Resolved |
| `GET /forms/get-users` returned all employee emails unauthenticated | `maybeAuth` middleware added | ✅ Resolved |
| `audit_archiver` Lambda log group had infinite retention | 365-day retention set; TF resource in PR2 | ✅ Resolved |
| Secrets in `.env` on EC2 | Rotated to SSM Parameter Store; `.env` deleted | ✅ Resolved |
| RDS publicly exposed | Security group scoped to VPC-only | ✅ Resolved |

Full report: `/Users/tyler.suffern/Documents/Claude/Projects/Gunner Team App/compliance-audit-2026-05-15.md`

### Phase 2 — Open

| Priority | Finding | File:Line | Status |
|---------|---------|-----------|--------|
| P0 | CompanyCam webhook DB writes unscoped to tenant — can clear wrong user's device token | companycam.js:35,52,77 | Open |
| P2 | Fleet document view — no ownership check on sequential docId; no audit log | fleet/index.js:984 | Open |
| P2 | POST `/forms/` and `/forms/submit-ap` fully anonymous | forms.js:33,65 | Open (backlog #33) |
| P3 | `rejectUnauthorized: false` on RDS SSL connection | lib/db.js:9 | Open |
| P4 | Webhook dedup runs before HMAC verification | companycam.js:369 | Open |

### Audit Logging

`audit_archiver` Lambda captures security events to CloudWatch (`/aws/lambda/gunnerteam-dev-audit-archiver`) with 365-day retention. Events: auth (login, token issued/refresh), access control failures, admin actions (user/form CRUD, bulk ops), webhook events with HMAC verification results, and errors.

## Key Concepts

- **Common Criteria (CC)** — The mandatory security controls. Covers logical/physical access, change management, risk assessment, monitoring.
- **Complementary User Entity Controls (CUECs)** — Controls the customer (your client) must implement for the audit to hold. Defined in the audit report.
- **Bridge letter** — Extends a Type II report past its end date while the next audit period is underway. Common in enterprise sales.
- **Readiness assessment** — Pre-audit gap analysis. A CPA firm runs this before the formal audit to identify control deficiencies.
