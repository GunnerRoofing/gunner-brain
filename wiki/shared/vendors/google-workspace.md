---
title: Google Workspace
type: vendor
tags: [google-workspace, identity, iam, sso, mfa, vendor, google]
created: 2026-04-13
updated: 2026-04-14
status: stable
sources: [Gunner IT Governance.xlsx, System Security Plan.docx, Acceptable Use Policy.docx]
related: ["[[gunnerteam/environment]]", "[[gunnerteam/app-inventory]]", "[[concepts/cis-ig1]]", "[[vendors/hexnode]]", "[[vendors/keeper]]", "[[summaries/cis-google-workspace-benchmark]]", "[[summaries/cis-chrome-enterprise-benchmark]]"]
---

# Google Workspace

## What It Does

Google Workspace is Gunner Roofing's primary identity provider (IdP) and productivity suite. All SaaS apps that support SSO authenticate through Google. Disabling a Google account is the primary offboarding kill-switch — it immediately blocks access to all SSO-connected apps.

## Organizational Unit (OU) Structure

Five OUs govern all accounts with distinct security policies:

### Standard Users
- **Population:** 35 employees
- **Policy:** Full CIS IG1 baseline
- **MFA:** Required (14-day session duration)
- **Login Challenge:** Medium sensitivity
- **External Sharing:** Restricted to approved domains
- **Services:** Full Google Workspace suite
- **OAuth:** Approved apps only

### Administrators
- **Population:** 5 — Tyler Suffern, [[entities/Eric Recchia|Eric Recchia]], [[entities/Eddie Prchal|Eddie Prchal]], [[entities/Andrew Prchal|Andrew Prchal]], Office Manager
- **Policy:** Elevated — most sensitive OU
- **MFA:** Challenged every session (24-hour session duration)
- **Login Challenge:** High — any unusual signal triggers challenge
- **Login Alerts:** Every single login
- **Developer Tools:** Enabled (for troubleshooting)
- **OAuth:** Restricted to specific APIs
- **Password:** 12-char min, complexity required, 90-day rotation; Keeper-managed

### Service Accounts
- **Population:** solar@, admin@, ads@, shared mailboxes, API accounts
- **Policy:** Non-human accounts
- **MFA:** Disabled (no human to approve) — interactive login triggers immediate IT alert
- **Session Timeout:** 1 hour (shortest)
- **Services:** Email and API access only; specific APIs documented in SSP
- **OAuth:** None
- **Note:** Any interactive login is anomalous — alert IT immediately

### Contractors
- **Population:** ~10 contractor accounts
- **Policy:** Scoped access
- **MFA:** Required (7-day session duration)
- **External Sharing:** Disabled
- **Services:** Email and Drive only
- **Monitored closely for offboarding**

### Staging
- **Population:** New accounts pending IT setup
- **Policy:** No access whatsoever
- **Services:** None — no apps, no Chrome policy inheritance
- **Purpose:** All new accounts land here; IT moves them to correct OU on setup completion

## Chrome Enterprise Core Policies

Applied via Google Admin Console → Devices → Chrome → Settings (CIS IG1 baseline):

| Policy | Standard Users | Admins | Notes |
|--------|---------------|--------|-------|
| Incognito Mode | Disabled | Disabled | CIS L1 |
| Delete Browser History | Blocked | Blocked | CIS L1 — preserves incident investigation evidence |
| Basic Auth over HTTP | Disabled | Disabled | CIS L1 |
| DNS over HTTPS | Secure (forced) | Secure | CIS L1 |
| Browser Sign-in | Forced | Forced | Must sign in with @gunnerroofing.com account |
| Restrict Sign-in Pattern | @gunnerroofing.com | @gunnerroofing.com | Blocks personal Google accounts |
| Safe Browsing | Enhanced (level 2) | Enhanced | CIS L1 — real-time phishing protection |
| HTTPS Only Mode | Force enabled | Force enabled | CIS L1 |
| Developer Tools | Disabled | Enabled | Admins need for troubleshooting |
| Extension Allowlist | Adobe Acrobat, Google Docs Offline | + IT admin tools | Blocklist wildcard (*) — all else blocked |
| User Feedback | Blocked | Blocked | CIS L1 — prevents data to Google |
| Encrypted Client Hello | True | True | CIS L1 — add if missing |
| GenAI / AI Features | Disabled (value 2) | Disabled | Already configured |

**Deprecated:** ProxyMode policy — remove from config entirely.

## Google Workspace Policies by OU

| Policy | Standard | Admins | Service | Contractors | Staging |
|--------|----------|--------|---------|-------------|---------|
| MFA | Required | Every session | Disabled | Required | No access |
| Session Duration | 14 days | 24 hours | 1 hour | 7 days | — |
| Login Challenge | Medium | High | Maximum | — | — |
| Less Secure Apps | — | — | — | — | — |
| External Sharing | Approved domains | Disabled | Disabled | Disabled | — |
| Services | Full suite | Full + admin API | Email + specific APIs | Email + Drive | None |
| OAuth | Approved apps | Specific APIs | None | None | None |
| Login Alerts | Unusual activity | Every login | Every login (anomalous) | — | — |
| Password | 12 char, 90-day | Keeper-managed | 12 char, 90-day | — | — |
| Account Recovery | IT-managed only | IT-managed only | IT-managed only | — | — |

## SSO / SCIM App Status

| App | SSO Supported | SSO Type | SCIM | Current Method | Offboarding Action |
|-----|--------------|----------|------|----------------|-------------------|
| Google Workspace | Yes (native) | Google Identity | Yes | Direct — primary IdP | Disable account → blocks all SSO apps |
| HubSpot | Yes | SAML / Google SSO | Paid tier only | Manual invite then Google SSO | Manual deprovision in HubSpot admin |
| Monday.com | Yes | Google SSO | — | Google SSO | Manual deprovision in Monday admin |
| CompanyCam | Yes | Google SSO | — | Google SSO | — |
| ADP | No | — | — | Manual | Manual deprovision |

## CIS Controls Satisfied by OU Structure

| CIS Control | Control Name | How It's Satisfied |
|-------------|-------------|-------------------|
| CIS 5.3 | Disable Dormant Accounts (45 days) | Staging OU isolates unconfigured accounts; Contractor OU makes dormancy audits targeted |
| CIS 5.4 | Restrict Admin Privileges | Admin OU applies per-session MFA + login alerts exclusively to 5 privileged accounts |
| CIS 5.5 | Inventory of Service Accounts | Service Accounts OU is the authoritative inventory — count of accounts = service account count |
| CIS 5.6 | Centralize Account Management | All accounts managed through Google Workspace; single control point for provisioning |
| CIS 6.2 | Allowlist Authorized Software | Extension allowlist per OU in Chrome policy |
| CIS 6.3 | MFA for Externally-Facing Apps | MFA enforced at OU level for all human OUs |
| CIS 6.4 | MFA for Remote Access | Admin OU enforces MFA on every session |
| CIS 6.7 | Centralize Access Control | All access through Google Workspace OUs + SSO; disabling one account blocks all |
| CIS 14.1 | Security Awareness Program | OU structure maps to KnowBe4 user groups for role-appropriate phishing simulations |

## Key Configurations and Quirks

- New accounts always land in **Staging** first — no access until IT explicitly moves them
- Admin accounts have **no self-service account recovery** — IT-managed only
- Service account interactive logins should be treated as security incidents
- Chrome extension blocklist (`*`) must have the allowlist configured **before** the blocklist is applied, or it will lock out all extensions including approved ones

## Email Security (DMARC / SPF / DKIM / MTA-STS / BIMI)

Full email hardening stack implemented on gunnerroofing.com.

### DMARC Migration History

| Date | Change |
|------|--------|
| Initial | `p=none` (monitor only) |
| Intermediate | `p=quarantine` |
| 2026-02-03 | `p=reject` — full enforcement |

- **Reporting:** Cloudflare + vali.email used for DMARC aggregate report monitoring
- SPF and DKIM were verified before enforcement was activated

### MTA-STS

MTA-STS is configured in **enforce mode** on gunnerroofing.com. Forces TLS on inbound SMTP connections — prevents downgrade attacks.

### BIMI

BIMI (Brand Indicators for Message Identification) logo implemented. Displays the Gunner Roofing logo next to emails in supporting mail clients (Gmail, etc.). Requires DMARC `p=reject` or `p=quarantine` to activate.

### Delegated Admin Account

Tyler Suffern has `admin@gunnerroofing.com` delegated to his personal `tyler.suffern@gunnerroofing.com` account. The admin account appears in the Gmail account switcher with a "Delegated" badge. This allows admin actions without maintaining a separate login session.

## CIS Benchmark Alignment

New CIS benchmarks for Google products (June 2025) are now in the vault:

| Benchmark | Key Gaps for Gunner |
|-----------|-------------------|
| [[summaries/cis-google-workspace-benchmark]] | Admin hardware key (L1 recommendation — verify); external Drive sharing defaults; alert rules configuration |
| [[summaries/cis-chrome-enterprise-benchmark]] | Safe Browsing: upgrade to Enhanced protection; HTTPS-Only mode; verify RestrictSigninToPattern is set |

**Priority actions from benchmarks:**
1. Verify Admin OU accounts use hardware security key (or assess risk of Authenticator-only)
2. Audit external Drive sharing defaults in Admin Console
3. Enable HTTPS-Only mode in Chrome Enterprise policy
4. Upgrade Chrome Safe Browsing to Enhanced protection

## Related Pages

- [[gunnerteam/environment]] — full environment overview
- [[gunnerteam/app-inventory]] — complete application inventory
- [[concepts/cis-ig1]] — CIS IG1 framework details
- [[vendors/keeper]] — password management
