---
title: Gunner Application Inventory
type: gunner
tags: [apps, saas, inventory, stack, gunner]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [Departmental Comms.xlsx, Gunner IT Governance.xlsx, Acceptable Use Policy.docx]
related: ["[[gunner/environment]]", "[[vendors/google-workspace]]", "[[vendors/hexnode]]"]
---

# Gunner Application Inventory

All business operations must run through approved applications. Personal apps and unapproved tools are prohibited on company devices (per AUP).

## Approved Application Stack

| App | Category | [[concepts/sso|SSO]] | Use Case |
|-----|----------|-----|---------|
| Google Chat | Communication | Google | All-company announcements; team comms; peer-to-peer; IT request management |
| Gmail | Communication | Google | Email; marketing; IT request management |
| [[vendors/dialpad|Dialpad]] | Communication | — | Customer communication (VoIP) |
| Google Calendar | Productivity | Google | Meeting invitations |
| Google Drive | Productivity | Google | File sharing; link sharing |
| [[vendors/monday|Monday.com]] | Operations | Google SSO | Project management; IT dev board; automated request forms |
| [[vendors/hubspot|HubSpot]] | Sales | Google SSO | CRM; automated Chat notifications from deals/reviews |
| CompanyCam | Field | Google SSO | Project photos & daily logs |
| Quote Portal | Sales | — | Quote customization & management |
| Gunner Forms (iOS) | IT | Monday SSO | IT request, service request, PTO, reimbursement, referral forms |
| ADP | HR/Payroll | — | Crew payouts; payroll |
| DocuSign | Documents | — | Contract signing |
| BuilderTrend | Field | — | Field project management |
| Contactzilla | Directory | Google | Synced company-wide phone book (all devices) |
| [[vendors/keeper|Keeper]] | Security | — | Password management |
| [[vendors/knowbe4|KnowBe4]] | Security | — | Phishing simulation |
| My2N | Field | — | Access control |
| Rhombus | Security | — | Video/camera system |
| Whip Around | Field | — | DVIR evaluated for fleet management — does not meet requirements; not in active use. Fleet management remains an open need. |
| ABC Supply | Field | — | Supplier portal |
| GAF | Field | Individual accounts | Roofing materials portal |
| Wells Fargo | Finance | — | Banking |
| Chase Mobile | Finance | — | Banking |
| Amex GBT Mobile | Travel | — | Travel management |
| Adobe Acrobat | Productivity | — | PDF viewing/signing |
| [[vendors/stripe-api-reference|Stripe]] | Payments | — | Payment processing — sandbox ("Gunner CT") environment confirmed; integration in development |
| [[vendors/make-com|Make.com]] | Automation | — | Workflow automation — Monday → Google Chat notifications, HubSpot → Google Chat |
| GoTo | Meetings/VoIP | — | Evaluated during VoIP audit; tested HubSpot integration — not selected, Dialpad retained |
| [[vendors/sendgrid|Sendgrid]] | Email delivery | — | Transactional email management; access via Becky's account |
| Owl | Conference room | — | Conference room camera; deployed to NJ office |
| QuickMeasure | Field | — | Roofing measurement tool; shared login via andrew@gunnerroofing.com — credentials should be in Keeper |
| CompanyCam | Field | Google SSO | Project photos — confirmed SSO |
| Hover | Domain registrar | Google SSO | Domain management — confirmed SSO |
| Cloudflare | DNS/CDN | Google SSO | DNS, email security (DMARC reporting) — confirmed SSO |
| My2N | Access control | Email/Password | No SSO |
| Contract Portal | Sales | Email/Password | No SSO — manual offboarding required |
| GAF | Field | Email/Password (individual accounts) | No SSO — individual accounts |
| Wells Fargo | Finance | Email/Password | No SSO |
| Whip Around | Field | Email/Password (need enterprise for SSO) | SSO requires enterprise tier; not currently active |

## Offboarding Checklist by App

When an employee departs, accounts must be deprovisioned in this order:

1. **Disable Google Workspace account** → immediately blocks all Google SSO apps
2. **HubSpot** — manual deprovision in HubSpot admin
3. **Monday.com** — manual deprovision in Monday admin
4. **CompanyCam** — manual (Google SSO blocks access on step 1)
5. **ADP** — manual deprovision
6. **Keeper** — revoke seat; rotate any shared credentials employee had access to
7. **Hexnode** — remote wipe device, change owner
8. **Dialpad** — manual deprovision
9. **Any other app without SSO** — manual review

## Apps Without SSO (Higher Offboarding Risk)

These apps require manual deprovisioning — they will NOT be blocked by disabling the Google account:

- ADP
- Dialpad
- BuilderTrend
- Contactzilla
- GAF QuickMeasure (moved to individual accounts — previous shared credential risk)
- Wells Fargo
- Chase Mobile
- ABC Supply

## Departmental App Usage

| App | Primary Departments |
|-----|-------------------|
| Google Chat | All — company-wide |
| Dialpad | Sales, customer-facing |
| Monday.com | Operations, IT |
| HubSpot | Sales, Marketing |
| CompanyCam | Field, Operations |
| Quote Portal | Sales |
| Gmail | All |
| ADP | HR, Payroll, Field Crew |
| Gunner Forms | All (IT requests, PTO, etc.) |

## SSO vs Email/Password Classification

As of 2026-01-16 audit:

**Google SSO enabled:** Dialpad, Hover, Monday.com, HubSpot, Hexnode, Cloudflare

**Email/Password only (no SSO):** My2N, CompanyCam\*, Google (native), Apple ID, Contract Portal, GAF, Gunner API, KnowBe4, Make.com, Microsoft, Wells Fargo, Whip Around (needs enterprise tier for SSO)

\*CompanyCam supports Google SSO but was listed under email/password in the audit — verify current state.

> **Offboarding implication:** Email/Password apps will NOT be automatically blocked when the Google account is disabled. These require manual action. See offboarding checklist below.

## AI Tool Policy

From the AUP — AI access is controlled:

| Tool | Status |
|------|--------|
| Claude (Anthropic) | Approved (IT-provisioned access) |
| ChatGPT | Restricted — personal accounts prohibited on work devices |
| Google Gemini | Managed — pushed via MDM to Total Lockdown iPhones; AI features disabled via Chrome and MDM policy |
| Apple Intelligence | Disabled via Hexnode MDM policy |

> Employees must never input customer data, financial information, or anything confidential into any AI tool.
