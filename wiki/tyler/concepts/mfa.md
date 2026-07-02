---
title: Multi-Factor Authentication (MFA)
type: concept
tags: [mfa, authentication, identity, google-workspace, access-control]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [Gunner IT Governance.xlsx, System Security Plan.docx]
related: ["[[vendors/google-workspace]]", "[[concepts/sso]]", "[[vendors/keeper]]", "[[threats/t1110-brute-force]]", "[[threats/t1078-valid-accounts]]"]
---

# Multi-Factor Authentication (MFA)

## What It Is

MFA requires users to provide two or more verification factors to authenticate. At Gunner, MFA is enforced through **Google Workspace** and propagates to all Google SSO-connected apps.

## MFA Configuration by OU

| OU | MFA Required | Challenge Frequency | Session Duration |
|----|-------------|--------------------|-----------------| 
| Standard Users | Yes | Unusual activity | 14 days |
| Administrators | Yes | **Every session** | 24 hours |
| Service Accounts | Disabled | N/A — interactive login = incident | 1 hour |
| Contractors | Yes | — | 7 days |
| Staging | No access | N/A | — |

## Admin OU — Elevated Requirements

Admin accounts are challenged on every login regardless of location or device. The 24-hour session means daily re-authentication. This satisfies CIS Controls 6.3 and 6.4.

Password policy for Admin OU: 12-character minimum, complexity required, 90-day rotation, Keeper-managed.

## Recovery

- Work phones added as Google account recovery numbers (completed)
- Account recovery is IT-managed only for all OUs — no self-service
- If Admin account recovery is needed: Tyler Suffern handles it directly

## Coverage Gaps

MFA only protects apps authenticated through Google SSO. Non-SSO apps ([[gunnerteam/app-inventory]]) are not covered by Gunner's MFA enforcement — credential-based attacks against ADP, Wells Fargo, etc. are harder to detect and block.

## CIS Controls

| Control | Coverage |
|---------|---------|
| CIS 6.3 | MFA for externally-facing apps — enforced per OU |
| CIS 6.4 | MFA for remote access — Admin OU every session |

## Security Impact

MFA is the primary mitigation for [[threats/t1110-brute-force]] and significantly raises the cost of [[threats/t1078-valid-accounts]] exploitation. A stolen Google password alone is insufficient for account access on any human OU.

## Related

- [[vendors/google-workspace]] — full OU policy table and session duration settings
- [[concepts/sso]] — MFA enforcement propagates through SSO to connected apps
- [[threats/t1110-brute-force]] — primary threat MFA mitigates
- [[threats/t1078-valid-accounts]] — valid account abuse; MFA is a key control
