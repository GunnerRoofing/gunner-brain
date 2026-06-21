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

### Phase 2 — SOC 2 product-environment controls (2026-06-18–19)

Controls APP-01…APP-09 implemented and verified. Full register: [[gunnerteam/ssp-addendum-1-product-environment]]. Session summary: [[gunnerteam/soc2-accomplishments-2026-06]].

| Control | What | Status |
|---|---|---|
| APP-01 Location retention | Daily EventBridge prune of `gt_location_history` > 90 days | ✅ |
| APP-02 Monitoring & alerting | CloudWatch → SNS → email + Google Chat; ok_actions wired | ✅ |
| APP-03 CI / SDLC | GitHub Actions: syntax, tests, `npm audit`; no deploy creds in CI | ✅ |
| APP-04 Auth IaC | Cognito under Terraform (`prevent_destroy`; clean plan) | ✅ |
| APP-05 Brute-force at scale | DynamoDB shared rate-limit store (cross-instance) | ✅ |
| APP-06/08 Audit archival | Fixed archiver + WORM S3 Object Lock (6 mo hot / 7 yr cold) | ✅ |
| APP-07 Audit coverage | Single `audit()` writer; standard in `CLAUDE.md` | ✅ |
| APP-09 Credential drift | SSM DB creds reconciled to RDS Proxy secret | ✅ |

**Two production incidents resolved:** API Gateway 0/0 throttle + VPC ejection (cc-1614/1615); RDS Proxy exhaustion from `resolveUser` pinning + fire-and-forget freeze (cc-1628/1629/1631).

**Key operating conventions:** de-pin rule (`query()` not `queryWithTenant` for hot reads), Lambda freeze rule (`await` all async before handler resolves), safe 5-step env-change flow (cc-1621).

### Phase 2 — Open findings (pre-cc-1601)

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
