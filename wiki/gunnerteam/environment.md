---
title: Gunner Roofing — Environment Overview
type: gunner
tags:
  - environment
  - infrastructure
  - network
  - stack
  - gunner
created: 2026-04-13T00:00:00.000Z
updated: 2026-04-13T00:00:00.000Z
status: stable
sources:
  - System Security Plan.docx
  - Gunner IT Governance.xlsx
  - Departmental Comms.xlsx
  - Tyler Suffern - Performance Review 2026.docx
related:
  - '[[vendors/hexnode]]'
  - '[[vendors/google-workspace]]'
  - '[[vendors/keeper]]'
  - '[[vendors/knowbe4]]'
  - '[[gunner/app-inventory]]'
  - '[[gunnerteam/system-security-plan]]'
  - '[[gunner/brand-colors]]'
  - '[[gunner/completed-projects]]'
  - '[[vendors/jamf]]'
---

# Gunner Roofing — Environment Overview

## Organization

| Field | Detail |
|-------|--------|
| Company | Gunner Roofing LLC |
| System Name | Gunner Roofing Information Systems (GR IS) |
| System Owner | [[entities/Eric Recchia|Eric Recchia]], VP of Strategy |
| Authorizing Officials | [[entities/Eddie Prchal|Eddie Prchal]] & [[entities/Andrew Prchal|Andrew Prchal]] (Owners) |
| IT Manager | Tyler Suffern (tyler.suffern@gunnerroofing.com) |
| Headcount | ~36 employees + ~10 contractors |
| Operational Status | Active — transitioning to CIS IG1-compliant managed posture |

## Office Locations

| Location | Role | Notes |
|----------|------|-------|
| Stamford, CT | HQ | Network upgraded to Unifi 2GB with Cat6a cabling + centralized server |
| CT Branch (Cromwell) | Secondary | |
| NJ Office | Secondary | Full Unifi build-out: UXG-Pro, USW-Pro-48-PoE, 3× U6-Pro APs, Mac Mini, UPS/PDU/rack |

**Main phone:** 866-262-6005

**DUNS #:** 121897089 (used for federal/surety work — see [[gunner/federal-market]])

### weatherTAP GPS Coordinates (for weather monitoring)

| Office | Lat | Lon |
|--------|-----|-----|
| Stamford CT (STAM) | 41.048 | -73.527 |
| Cromwell CT (CROM) | 41.605 | -72.656 |
| NJ Office | 40.902 | -74.635 |

## Device Fleet

| Type | Platform | Management |
|------|----------|------------|
| MacBooks | macOS | Hexnode MDM via Apple Business Manager (DEP) |
| iPhones | iOS | Hexnode MDM via Apple Business Manager (DEP) |
| Target enrollment | 100% | CIS IG1 Control 1.1 |

Devices are named using the convention: `GR-[last 6 of serial number]`

## SaaS Stack

### Core Operations
| Tool | Purpose | Notes |
|------|---------|-------|
| Google Workspace | Email, Drive, Chat, Calendar, identity provider | Primary IdP — all SSO flows through Google |
| Dialpad | Customer communication (VoIP) | Subject of VoIP vendor audit in 2025 |
| Monday.com | Operations project management, IT dev board | Automated Chat notifications configured |
| HubSpot | Sales CRM | Google SSO; automated Chat notifications |
| CompanyCam | Project photos & daily logs | Google SSO |
| Quote Portal | Quote customization & management | |
| ADP | Payroll, crew payouts | |
| DocuSign | Document signing | |
| BuilderTrend | Project management (field) | |

### IT & Security
| Tool | Purpose | Notes |
|------|---------|-------|
| [[vendors/hexnode|Hexnode MDM]] | Mobile device management (Mac + iPhone) | Apple Business Manager integration |
| [[vendors/keeper|Keeper]] | Password management | Company-wide, overhauled for offboarding |
| [[vendors/knowbe4|KnowBe4]] | Phishing simulation & security awareness | Phishing-only implementation, 51 users |
| Chrome Enterprise Core | Managed browser | CIS IG1 browser hardening policies |
| Google Admin Console | Identity & access management | 5 OUs; see [[vendors/google-workspace]] |

### Field & Communication
| Tool | Purpose |
|------|---------|
| Google Chat | All-company announcements, team comms, peer-to-peer |
| Gmail | Email; IT request management, marketing |
| Google Drive | File sharing, link sharing |
| Contactzilla | Synced company-wide phone directory (all devices) |
| My2N | Access control (field) |
| Rhombus | Camera/video system |
| Whip Around | DVIR (Driver Vehicle Inspection Reports) |
| ABC Supply | Supplier portal |

### Internal Apps (Gunner-Built)
| Tool | Purpose |
|------|---------|
| Gunner Forms app | iOS app (Apple Business Manager) wrapping Monday.com WorkForms — IT request, service request, PTO, reimbursement, referral forms |

## Network Architecture

- **Stamford HQ:** Unifi 2GB system with Cat6a cabling; centralized server; warehouse AP enrolled; static IPs for printers
- **NJ Office:** Full Unifi build-out complete — UXG-Pro (Gateway Pro), USW-Pro-48-PoE (48-port managed PoE switch), 3× U6-Pro APs, Mac Mini, UPS/PDU/rack; Owl conference room camera deployed
- **DNS:** Cloudflare DNS (home lab reference; production DNS details not documented yet)
- **Email security:** DMARC, SPF, DKIM configured on gunnerroofing.com domain; Sendgrid access established
- **Managed domains (mobile):** hubspot.com, monday.com, adp.com, google.com

## Google Workspace Organizational Units

See [[vendors/google-workspace]] for full OU policy details.

| OU | Population | Purpose |
|----|------------|---------|
| Standard Users | 35 employees | Full CIS IG1 baseline |
| Administrators | 5 (Tyler, Eric, Eddie, Andrew, Office Manager) | Elevated session controls |
| Service Accounts | solar@, admin@, ads@ + shared mailboxes | Non-human accounts |
| Contractors | ~10 | Scoped to email + Drive only |
| Staging | New/unconfigured accounts | No access until IT setup complete |

## Key Personnel

| Name | Role | Access Level |
|------|------|-------------|
| Tyler Suffern | IT Manager / System Admin | Admin OU |
| [[entities/Eric Recchia|Eric Recchia]] | VP of Strategy / System Owner | Admin OU |
| [[entities/Eddie Prchal|Eddie Prchal]] | Owner / Authorizing Official | Admin OU |
| [[entities/Andrew Prchal|Andrew Prchal]] | Owner / Authorizing Official | Admin OU |
| Office Manager | — | Admin OU |

## Cloud Infrastructure

Gunner has an AWS environment managed by a DevOps team (separate from IT). Accounts:

| AWS Account | Purpose |
|-------------|---------|
| Gunner | Root / production |
| Gunner-Prod | Production workloads |
| Gunner-Dev | Development |
| Gunner-QA | Quality assurance |
| Gunner-Staging | Staging / pre-prod |

AWS credentials and Aurora DB connection strings are stored in Keeper (or should be — see security flags).

## Security Posture

- **Framework:** CIS IG1 (approved SEC-001, 2026-03-18) — see [[concepts/cis-ig1]]
- **Security plan:** [[gunnerteam/system-security-plan]]
- **Policies:** [[runbooks/acceptable-use-policy]], IT Communications Style Guide
- **Incident response:** Hexnode remote wipe for lost/stolen devices; Google Workspace disable + Keeper rotation for account compromise
- **Email security:** DMARC p=reject (2026-02-03), MTA-STS enforce, BIMI active — see [[vendors/google-workspace]]
