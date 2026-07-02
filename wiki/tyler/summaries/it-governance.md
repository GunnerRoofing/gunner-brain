---
title: Summary — Gunner IT Governance Workbook
type: summary
tags: [summary, governance, google-workspace, cis, chrome, iam]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [Gunner IT Governance.xlsx]
related: ["[[vendors/google-workspace]]", "[[concepts/cis-ig1]]", "[[gunnerteam/app-inventory]]", "[[gunnerteam/environment]]"]
---

# Summary — Gunner IT Governance Workbook

**Source:** `Gunner IT Governance.xlsx`  
**Author:** Tyler Suffern  
**Purpose:** CIS IG1 account management and browser controls reference for Google Workspace

## Key Contents

1. **Google Workspace Organizational Units** — 5-OU structure (Standard Users, Administrators, Service Accounts, Contractors, Staging) with distinct MFA, session, and service policies per OU

2. **Chrome Enterprise Core Policies by OU** — CIS L1 browser hardening: incognito disabled, DNS-over-HTTPS forced, extension blocklist with allowlist, HTTPS-only, AI features disabled

3. **Google Workspace Policies by OU** — MFA enforcement, session duration, login challenge sensitivity, external sharing, OAuth restrictions per OU

4. **CIS IG1 Controls Satisfaction Map** — Maps each CIS control (5.3–6.7, 14.1) to the specific OU or policy that satisfies it, with evidence location

5. **Application Inventory & SSO Status** — All company apps, SSO type, SCIM status, offboarding action per app

## Key Takeaways

- This workbook is the authoritative reference for "what controls what" in Google Workspace
- Service Account OU interactive logins should be treated as security incidents
- Extension allowlist must be configured before blocklist (*) is applied
- ProxyMode Chrome policy is deprecated — must be removed
- EncryptedClientHelloEnabled was missing from config — must be added

## Pages Updated From This Source

- [[vendors/google-workspace]] — full OU and policy details
- [[gunnerteam/app-inventory]] — SSO/offboarding table
- [[concepts/cis-ig1]] — CIS control mapping
- [[gunnerteam/environment]] — OU summary
