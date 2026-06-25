---
title: SSP Addendum 1 — Product Environment Controls
type: gunner
tags:
  - ssp
  - soc2
  - governance
  - compliance
  - gunnerteam
created: '2026-06-18'
updated: '2026-06-19'
document_id: IT-SSP-001-A1
version: 0.1 DRAFT
classification: CONFIDENTIAL
status: pending-signoff
related:
  - '[[gunnerteam/system-security-plan]]'
  - '[[gunnerteam/aws-environment]]'
  - '[[tyler/concepts/soc2]]'
  - '[[entities/Eric Recchia]]'
  - '[[entities/Tyler Suffern]]'
---

# SSP Addendum 1 — GunnerTeam Product Environment Controls

**Document ID:** IT-SSP-001-A1  
**Parent:** [[gunnerteam/system-security-plan]] (IT-SSP-001)  
**Version:** 0.1 DRAFT — pending review & sign-off  
**Classification:** CONFIDENTIAL  
**Established:** 2026-06-18  
**Review Cycle:** On change / quarterly

> [!warning] Status: DRAFT
> All controls (APP-01…APP-09) are **Implemented & Verified** as of 2026-06-18–19. The document is not yet signed. Route to Eric + the owners for signature and merge into the branded SSP template.

---

## Purpose

[[gunnerteam/system-security-plan]] (IT-SSP-001) scopes Gunner's security program to the corporate IT environment ("GRIS" — ~36 staff, Macs, Google Workspace, UniFi, Hexnode). This addendum extends the SSP to a **second in-scope boundary: the GunnerTeam product environment** — the application Gunner is preparing to sell white-labeled — and records the control work completed to make that environment SOC 2-ready.

**Framework framing:** CIS IG1 ("Gunner Security Baseline," SEC-001) remains the control baseline. SOC 2 is an attestation on top of that baseline. This addendum maps each control to both CIS IG1 and the relevant SOC 2 Trust Services Criteria (TSC).

**Target TSC:** Security (Common Criteria), Availability, Confidentiality. Privacy is in consideration due to employee location data (APP-01).

---

## Scope

**GunnerTeam product environment** — a distinct boundary from the corporate endpoint fleet:

- **Hosting:** AWS, us-east-2 — Lambda (`gunnerteam-dev-api`) behind API Gateway, Aurora PostgreSQL (via RDS Proxy), S3, Cognito (`us-east-2_hFVBSrcnn`), EventBridge, SSM Parameter Store, CloudWatch
- **IaC:** Terraform (state in encrypted S3); Cognito under IaC (APP-04)
- **Build/deploy:** single-developer CI (GitHub Actions, APP-03); deploy via S3 → Lambda alias
- **Data handled:** customer PII, job-site photos (S3), **employee location history** (highest-sensitivity), authentication data, push tokens

> **Note:** the `dev`-named Lambda currently serves production data ("fake prod until go-live"); true dev/prod split is a tracked go-live task.

---

## Control Register

| ID | Control | What it does | CIS IG1 | SOC 2 TSC | Status | Evidence |
|---|---|---|---|---|---|---|
| **APP-01** | Location-data retention *(cc-1601)* | Daily EventBridge prune of `gt_location_history` > 90 days; enforces the published privacy commitment | 3.5 | C1.2, P4 | ✅ Verified (v295) | EventBridge `gunnerteam-dev-prune-location-history`; `audit_log` action `location_history.retention.pruned` |
| **APP-02** | Security monitoring & alerting *(cc-1602)* | CloudWatch alarms → SNS → email + Google Chat: Lambda errors/throttles, API 5xx, log-metric filter for auth/lock events | 8.11, 13 | CC7.2, CC7.3 | ✅ Verified | 4 alarms; SNS `gunnerteam-dev-alerts`; `sendAlertEmail()` + `postToGoogleChat()`; ok/insufficient_data actions wired |
| **APP-03** | Secure SDLC — CI *(cc-1603)* | GitHub Actions on push/PR: syntax check, tests, `npm audit`; no deploy creds in CI | 16.1, 7.x | CC8.1, CC7.1 | ✅ Verified | `.github/workflows/ci.yml`; Actions run history |
| **APP-04** | Auth infra under change control *(cc-1604)* | Cognito user pool + clients imported into Terraform; `prevent_destroy`; clean (zero-change) plan | 4.1, 5.x, 6.x | CC6.1, CC8.1 | ✅ Verified | `terraform/cognito.tf` |
| **APP-05** | Brute-force protection at scale *(cc-1605)* | Per-container in-memory rate limiting replaced with shared DynamoDB store — limits hold across Lambda instances | 13 | CC6.1, CC6.7, CC7.2 | ✅ Verified (v299) | DynamoDB `gunnerteam-dev-rate-limits`; `DynamoRateLimitStore` |
| **APP-06** | Audit-log archival correctness *(cc-1606)* | Fixed archiver SQL (`audit_log`/`created_at`); added dry-run/year overrides | 8.x | CC7.2 | ✅ Verified | `terraform/lambda/audit-archiver.js` |
| **APP-07** | Audit logging standard & completeness *(cc-1607)* | Single `audit()` writer; coverage on credential/money/submission routes; standard documented in repo `CLAUDE.md` | 8.2, 8.5 | CC7.2, CC2.1 | ✅ Verified (v296) | `src/lib/audit.js`; repo `CLAUDE.md`. *Residual: raw `audit_log` INSERTs remain in fieldportal/auth/users/companycam — migrate-on-contact per standard.* |
| **APP-08** | Audit-log retention — tamper-resistant archive *(cc-1608)* | Archiver auth via Secrets Manager + RDS Proxy; monthly rolling prune (6 mo hot / 7 yr S3); S3 versioning + Object Lock (WORM, governance mode) | 8.3, 3.x | CC7.2, CC6.1, A1.2, C1 | ✅ Verified | S3 `gunner-audit-logs` (Object Lock); EventBridge monthly; 245 rows dry-run archived |
| **APP-09** | DB credential reconciliation *(cc-1609)* | Reconciled stale SSM `DB_USER`/`DB_PASSWORD` to the RDS Proxy secret; IaC stays drift-safe | 4.x, 5.x | CC8.1, CC6.1 | ✅ Verified | sha256 match; corrected creds baked into v297 |

---

## Retention Policy (APP-08 basis)

SOC 2 prescribes no fixed retention number — it requires a **defined, honored** period with logs that remain intact and retrievable.

| Tier | Duration | Mechanism |
|---|---|---|
| Hot (queryable in Aurora) | 6 months | `AUDIT_RETENTION_MONTHS=6` |
| Cold (S3) | 7 years | Glacier at 1 yr; expire at 7 yr |
| Integrity | Object Lock (WORM, governance mode) | Prevents alteration/deletion within period |

---

## Finding Remediated (for the assessor)

While verifying APP-01, the audit-log **retention control was found to have never operated**: the `audit-archiver` Lambda queried a non-existent table/column (`audit_logs`/`ts` vs the live `audit_log`/`created_at`) AND had no network path to the database (security group not permitted on the RDS Proxy; wrong VPC). Remediated 2026-06-18 by **APP-06** + **APP-08**. The remediation also surfaced **APP-09** (SSM credential drift). Documented transparently per the IT Decision & Change Log discipline.

---

## Approval & Sign-Off

| Name | Role | Signature | Date |
|---|---|---|---|
| [[Tyler Suffern\|Tyler Suffern]] | System Administrator / ISSO | | |
| [[Eric Recchia\|Eric Recchia]] | VP of Strategy / System Owner | | |
| [[Eddie Prchal\|Eddie Prchal]] | Owner — Authorizing Official | | |
| [[Andrew Prchal\|Andrew Prchal]] | Owner — Authorizing Official | | |

*CONFIDENTIAL — Gunner Roofing LLC — IT Department — IT-SSP-001-A1 v0.1 DRAFT*

---

## Related
- [[gunnerteam/system-security-plan]] — parent SSP (corporate IT boundary)
- [[gunnerteam/aws-environment]] — GunnerTeam AWS architecture
- [[gunnerteam/soc2-accomplishments-2026-06]] — implementation session summary
- [[tyler/concepts/soc2]] — SOC 2 framework concept page
