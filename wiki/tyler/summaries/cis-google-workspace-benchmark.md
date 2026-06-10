---
title: CIS Google Workspace Foundations Benchmark v1.3.0 — Summary
type: summary
tags:
  - cis
  - google-workspace
  - benchmark
  - hardening
  - sso
  - mfa
  - dmarc
  - study
created: 2026-04-13T00:00:00.000Z
updated: 2026-04-13T00:00:00.000Z
sources:
  - CIS_Google_Workspace_Foundations_Benchmark_v1.3.0.pdf
related:
  - '[[vendors/google-workspace]]'
  - '[[concepts/mfa]]'
  - '[[concepts/email-security]]'
  - '[[concepts/sso]]'
  - '[[concepts/cis-ig1]]'
status: stable
---

# CIS Google Workspace Foundations Benchmark v1.3.0 — Summary

**Source:** CIS_Google_Workspace_Foundations_Benchmark_v1.3.0.pdf  
**Version:** v1.3.0 — June 30, 2025  
**Issuer:** Center for Internet Security (CIS)

## Scope

Comprehensive hardening recommendations for Google Workspace. Covers:

| Section | Key Recommendations |
|---------|-------------------|
| **Gmail** | SPF, DKIM, DMARC; attachment blocking; phishing/malware scanning; MTA-STS; BIMI |
| **Google Drive** | External sharing controls; DLP rules; link-sharing defaults |
| **Calendar** | External sharing scope; appointment slot visibility |
| **Google Chat** | External chat (off by default recommendation); history settings |
| **Security — 2SV/MFA** | MFA enrollment enforcement; hardware key for admins; grace period config |
| **Security — DLP** | Drive DLP rules for sensitive data patterns (SSN, credit card, etc.) |
| **Security — Session Control** | Session duration; context-aware access |
| **Reporting** | Admin audit log alerts; login monitoring; Drive activity reports |
| **Rules** | Alert rules for suspicious activity |

## L1 vs L2 Profile Definitions

- **L1 (Level 1):** Essential recommendations applicable to all orgs. Low operational impact. Recommended as minimum baseline.
- **L2 (Level 2):** More restrictive. May have operational impact. Recommended for high-security environments.

Gunner should target **L1** as the baseline; review L2 controls case-by-case.

## High-Priority L1 Recommendations for Gunner

### Gmail / Email Security
- DMARC policy = `p=reject` with `rua` reporting ✓ (already done, 2026-02-03)
- SPF record configured ✓
- DKIM signing enabled ✓
- MTA-STS enforce mode ✓
- Email attachment scanning: verify enabled in Admin Console
- Block specific harmful file types in attachments

### 2SV / MFA
- Enforce 2SV enrollment for all users ✓ (OU-based)
- Admin accounts: require hardware key or Titan key (review — currently Authenticator)
- Set 2SV grace period to 0 days for new users

### Drive Sharing
- Default for external sharing: verify set to "Anyone in organization" or more restrictive
- Disable link sharing to "Anyone with the link" as organization default

### Session Control
- Admin Console session duration: verify — should be short (1-4 hours for Admin OU)
- User session duration: currently Google-default; consider tightening

### Alerts / Monitoring
- Ensure admin audit log alerts are active for: admin password changes, 2SV changes, account suspended events
- Google Workspace alerts center: verify all critical alert categories are enabled

## Gap Analysis for Gunner

| Area | Current Status | Benchmark Recommendation | Gap? |
|------|---------------|-------------------------|------|
| DMARC | p=reject ✓ | p=reject | No |
| SPF/DKIM | Configured ✓ | Required | No |
| MFA enforcement | OU-based ✓ | Enforce for all | Verify coverage |
| Admin hardware key | Not confirmed | Required (L1) | Possible gap |
| External Drive sharing | Not documented | Restrict defaults | Verify |
| DLP rules | None documented | L2 recommended | Low priority |
| Alert rules | Not documented | L1 recommended | Review |

## Relationship to Existing Wiki Pages

- Current email security status: [[concepts/email-security]]
- MFA settings by OU: [[concepts/mfa]]
- SSO configuration: [[concepts/sso]]
- Google Workspace vendor page: [[vendors/google-workspace]]
