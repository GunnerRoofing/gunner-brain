---
title: T1199 — Trusted Relationship
type: threat
tags: [mitre, t1199, trusted-relationship, initial-access, threat, vendor, contractor]
created: 2026-04-13
updated: 2026-04-13
status: developing
sources: []
related: ["[[vendors/google-workspace]]", "[[gunnerteam/app-inventory]]", "[[runbooks/offboarding]]", "[[concepts/sso]]"]
---

# T1199 — Trusted Relationship

**Tactic:** Initial Access  
**Technique ID:** T1199  

## Description

Adversaries abuse trust relationships with third-party organizations — vendors, contractors, or managed service providers — that have privileged or elevated access to target systems. Compromising a trusted third party provides an entry path without requiring direct exploitation of the target.

## Gunner Exposure

| Factor | Detail |
|--------|--------|
| Contractors | ~10 contractor accounts in Contractors OU (email + Drive only) |
| Make.com | Automation platform — integration tokens for HubSpot and Monday.com |
| SendGrid | Transactional email — compromise could enable phishing at scale via gunnerroofing.com infrastructure |
| DevOps team | External team manages Gunner's AWS environment (5 accounts: Gunner, Gunner-Prod, Gunner-Dev, Gunner-QA, Gunner-Staging) |
| Shared credentials (historical) | QuickMeasure previously had shared login — rotated to individual accounts |

## Controls in Place

| Control | Coverage |
|---------|---------|
| Contractors OU | Scoped to email + Drive only; no admin access; 7-day MFA sessions; monitored for offboarding |
| [[concepts/sso]] | Disabling contractor Google account = immediate SSO access revocation |
| [[runbooks/offboarding]] | Kill-Switch process applies to contractors |
| [[vendors/keeper]] | Shared credentials managed in Keeper; rotated on personnel changes |
| Service account alerts | Interactive logins to service accounts trigger immediate IT alert |

## Detection Notes

- Google Workspace audit logs track contractor account activity
- Contractors OU is monitored closely for offboarding timing
- Service account interactive login = immediate incident signal
- No vendor risk review cadence currently defined

## Gaps

- **AWS DevOps team:** External team has elevated access to production infrastructure. No documented vendor risk assessment or access review cadence. **CRITICAL:** AWS DevOps credentials (username/password + Aurora prod DB connection string) found in OneNote — treat as potentially exposed.
- **Make.com:** Holds integration tokens to HubSpot and Monday.com. If Make.com account is compromised, data flows could be manipulated or exfiltrated.
- **SendGrid:** Access obtained through Becky's account. If compromised, attacker could send transactional email via gunnerroofing.com infrastructure. DMARC p=reject mitigates domain spoofing to external domains, but SendGrid-originated mail would be legitimate.
- No formal vendor risk management program — identified as a CISO-track skill gap.

## Gunner-Specific Note

The Contractors OU in Google Workspace is well-designed for T1199 — minimal access, SSO-gated, and easy to revoke. The residual exposure is in third-party integrations (Make.com, DevOps AWS) where access is not Google-SSO-controlled and no access review cadence exists.

## Related

- [[vendors/google-workspace]] — Contractors OU configuration, service account alert policy
- [[gunnerteam/app-inventory]] — vendor integration details
- [[runbooks/offboarding]] — Kill-Switch applies to contractors
- [[concepts/sso]] — contractor access revocation via Google account disable
