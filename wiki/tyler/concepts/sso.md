---
title: Single Sign-On (SSO)
type: concept
tags: [sso, identity, iam, google-workspace, access-control, offboarding]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [Gunner IT Governance.xlsx, Acceptable Use Policy.docx, System Security Plan.docx]
related: ["[[vendors/google-workspace]]", "[[gunnerteam/app-inventory]]", "[[concepts/mfa]]", "[[runbooks/offboarding]]", "[[threats/t1078-valid-accounts]]"]
---

# Single Sign-On (SSO)

## What It Is

Single Sign-On lets users authenticate to multiple applications using one set of credentials. At Gunner Roofing, **Google Workspace is the Identity Provider (IdP)** — every app that supports SSO authenticates through Google.

## Why It Matters at Gunner

SSO is the force multiplier for both access control and offboarding:

- **Provisioning:** One Google account activation propagates access to all SSO apps.
- **Offboarding kill-switch:** Disabling the Google account immediately blocks all Google SSO-connected apps simultaneously.
- **MFA propagation:** MFA enforced at Google applies to all SSO logins.

## Apps with Google SSO (2026-01-16 audit)

Dialpad\*, Hover, Monday.com, HubSpot, Hexnode, Cloudflare, CompanyCam\*

\*Dialpad: SSO for login confirmed, but seat deprovisioning still requires manual admin action — verify.  
\*CompanyCam: SSO listed in audit but also appeared under email/password — verify current state.

## Apps Without SSO — Manual Offboarding Required

These apps are **not** blocked when the Google account is disabled:

| App | Offboarding Action |
|-----|-------------------|
| ADP | Manual deprovision |
| BuilderTrend | Manual deprovision |
| Contactzilla | Manual deprovision |
| KnowBe4 | Manual deprovision |
| Contract Portal | Manual deprovision |
| GAF | Individual accounts — manual |
| Wells Fargo | Manual |
| Chase Mobile | Manual |
| ABC Supply | Manual |

> **Security implication:** Former employees retain access to non-SSO apps until manually removed. The [[runbooks/offboarding]] Kill-Switch checklist covers each in sequence.

## SCIM

SCIM automates user provisioning/deprovisioning beyond just SSO. At Gunner, Google Workspace supports SCIM natively. HubSpot SCIM requires a paid tier (not in use). Most apps require manual seat management even with SSO enabled.

## Gunner SSO Strategy (In Progress)

The goal is to minimize non-SSO app exposure. Current non-SSO apps are documented in [[gunnerteam/app-inventory]] and treated as elevated offboarding risk. See [[threats/t1078-valid-accounts]] for the threat this creates.

## Related

- [[vendors/google-workspace]] — OU structure, SSO/SCIM status table, IdP configuration
- [[gunnerteam/app-inventory]] — full SSO vs email/password classification
- [[concepts/mfa]] — MFA enforced at IdP level propagates through SSO
- [[runbooks/offboarding]] — Kill-Switch process; non-SSO manual steps
- [[threats/t1078-valid-accounts]] — valid accounts threat; non-SSO apps are the exposure
