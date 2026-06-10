---
title: T1078 — Valid Accounts
type: threat
tags: [mitre, t1078, valid-accounts, credential-access, initial-access, persistence, threat, offboarding]
created: 2026-04-13
updated: 2026-04-13
status: developing
sources: []
related: ["[[vendors/google-workspace]]", "[[vendors/keeper]]", "[[runbooks/offboarding]]", "[[concepts/mfa]]", "[[concepts/sso]]", "[[gunner/app-inventory]]", "[[runbooks/incident-response]]"]
---

# T1078 — Valid Accounts

**Tactic:** Initial Access, Persistence, Privilege Escalation, Defense Evasion  
**Technique ID:** T1078  
**Sub-techniques:** T1078.001 (Default Accounts), T1078.002 (Domain Accounts), T1078.003 (Cloud Accounts), T1078.004 (Local Accounts)

## Description

Adversaries use valid credentials — stolen, purchased, or obtained through phishing — to authenticate as legitimate users. Because activity appears normal, detection is significantly harder than exploit-based access. At Gunner, the primary concern is T1078.003 (Cloud Accounts) — Google Workspace and SaaS app credentials.

## Gunner Exposure

| Factor | Detail |
|--------|--------|
| Primary surface | Google Workspace accounts (cloud) |
| Secondary surface | Non-SSO apps — not blocked by disabling Google account |
| Offboarding gap | Non-SSO apps remain accessible until manually deprovisioned |
| **CRITICAL** | Admin credentials (AWS, Keeper recovery codes, Hexnode, Netgear, GAM, SendGrid, HubSpot 2FA) found in OneNote — should be in Keeper |

## Detection Notes

- **Google Workspace login alerts:** Admin OU — every login; Standard OU — unusual activity signals
- **Service account interactive logins** — treated as security incidents (immediate alert configured)
- **Google Admin audit logs** — review on suspected compromise
- **Keeper Security Audit** — surfaces reused or known-compromised passwords

## Controls in Place

| Control | Coverage |
|---------|---------|
| [[concepts/mfa]] | MFA per OU — captured password alone is insufficient for Google SSO apps |
| [[vendors/keeper]] | Unique random passwords — eliminates reuse across services |
| [[concepts/sso]] | Disabling Google account = simultaneous kill-switch for all SSO apps |
| [[vendors/google-workspace]] | Login alerts, login challenge, per-session Admin MFA |
| [[runbooks/offboarding]] | Kill-Switch process — disable, wipe, deprovision non-SSO apps, rotate Keeper |

## Gaps / Exposure Notes

- **Non-SSO apps** remain accessible after Google account disable — see [[gunner/app-inventory]] for manual steps required
- **CRITICAL (open):** Multiple admin credentials found in OneNote outside Keeper — AWS DevOps credentials, Keeper recovery codes, Hexnode admin password, Netgear switch, Google GAM, SendGrid, HubSpot 2FA codes. These should be treated as potentially exposed until rotated into Keeper and removed from OneNote.
- No PAM solution beyond OU-based separation in Google Workspace + Keeper
- No behavioral analytics or SIEM to detect anomalous legitimate-user activity

## Gunner-Specific Note

The offboarding Kill-Switch process is the primary operational defense. Google account disable is the kill-switch. Non-SSO apps are the residual exposure — each requires a manual step. Former employees who were not fully deprovisioned from non-SSO apps retain valid accounts.

## Response

Follow [[runbooks/incident-response]] — Procedure 2 (Account Compromise): disable Google account, rotate Keeper credentials, review audit logs.

## Related

- [[runbooks/offboarding]] — Kill-Switch process; primary defense
- [[runbooks/incident-response]] — Account Compromise procedure
- [[concepts/mfa]] — key mitigation
- [[concepts/sso]] — kill-switch mechanism
- [[vendors/keeper]] — credential management
- [[gunner/app-inventory]] — non-SSO app exposure map
