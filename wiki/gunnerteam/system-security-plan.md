---
title: System Security Plan (SSP)
type: gunner
tags:
  - ssp
  - security-plan
  - governance
  - compliance
  - incident-response
  - gunner
created: 2026-04-13T00:00:00.000Z
updated: 2026-04-13T00:00:00.000Z
sources:
  - System Security Plan.docx
related:
  - '[[gunner/environment]]'
  - '[[concepts/cis-ig1]]'
  - '[[vendors/hexnode]]'
  - '[[vendors/google-workspace]]'
  - '[[runbooks/acceptable-use-policy]]'
status: stable
---

# System Security Plan (SSP)

**Document ID:** IT-SSP-001  
**Classification:** CONFIDENTIAL  
**Version:** v1.1 (reformatted 2026-03-26)  
**Established:** 2026-03-18  
**Next Review:** 2027-03-18  
**System:** Gunner Roofing Information Systems (GR IS)  
**Baseline:** CIS IG1

## System Identification

| Field | Value |
|-------|-------|
| System Name | Gunner Roofing Information Systems (GR IS) |
| System Owner | [[entities/Eric Recchia|Eric Recchia]], VP of Strategy |
| Auth. Officials | [[entities/Eddie Prchal|Eddie Prchal]] & [[entities/Andrew Prchal|Andrew Prchal]] (Owners) |
| Primary Mission | Secure, high-availability computing and communication for roofing sales, project management, and corporate operations |
| Status | Operational / Active — transitioning to fully managed CIS IG1-compliant posture |

## Data Classification

*(Specific classification levels not extracted — document references data classification scheme)*

## Roles & Responsibilities

### Security Management Hierarchy

| Role | Responsibility |
|------|---------------|
| IT Manager (Tyler Suffern) | Primary SSP owner; day-to-day security operations |
| VP of Strategy ([[entities/Eric Recchia|Eric Recchia]]) | System owner; may add governance entries in IT Manager's absence |
| Owners ([[entities/Eddie Prchal|Eddie]], [[entities/Andrew Prchal|Andrew Prchal]]) | Authorizing officials; final approval on security decisions |

### Onboarding ("New Crew" Process)
1. Account created in Google Workspace Staging OU (no access)
2. Hexnode enrollment via Apple Business Manager
3. Device renamed `GR-[last 6 serial]`
4. Local account created; password set via Keeper
5. Account moved from Staging to correct OU
6. Keeper seat provisioned
7. App access provisioned per role
8. AUP acknowledgment form signed and retained

### Offboarding ("Kill-Switch" Process)
1. Google Workspace account disabled (blocks all [[concepts/sso|SSO]] apps immediately)
2. Hexnode remote wipe initiated
3. Manual deprovision from non-SSO apps (ADP, [[vendors/dialpad|Dialpad]], etc.)
4. [[vendors/keeper|Keeper]] vault revoked; shared credentials rotated
5. Device recovered/wiped

### Privileged Access Management (PAM)

- Admin accounts are separate from daily-use accounts (5 accounts in Admin OU)
- Admin work happens in admin accounts — not personal user accounts
- All admin actions logged; per-session MFA required

## Configuration Management

### Hardware
- Asset tracking via Hexnode MDM dashboard
- Naming convention: `GR-[last 6 of serial]`
- Disposal process: documented (not extracted)

### OS & Patch Management (CIS Control 7)
- Managed via Hexnode: 7-day update deferral; security updates auto-install
- No beta programs

### Software Control (CIS Control 2)
- Hexnode app catalog controls installed apps on all devices
- Chrome extension blocklist (`*`) with allowlist exceptions

### Managed Browser (Chrome Enterprise Core)
- See [[vendors/google-workspace]] for full Chrome policy table

## Maintenance & Monitoring

### Compliance Auditing (CIS Controls 1.1 & 4.1)
- Hexnode compliance dashboard — non-compliant device reports
- Google Admin Console — user, login, and audit reports

### Security Alerting
- Google Workspace: login alerts on Admin OU (every login), unusual activity alerts on Standard OU
- Service account interactive logins trigger immediate alert

### Physical Security
- Physical walkthrough cadence: planned (CIS Control 14.1)
- Office locations: Stamford CT (HQ), CT branch, NJ

### Automated Maintenance
- Chrome update enforcement via Chrome Enterprise
- OS update enforcement via Hexnode

## Incident Response Plan

### Response Authority
- Primary: IT Manager (Tyler Suffern)
- Backup: VP of Strategy ([[entities/Eric Recchia|Eric Recchia]])

### Lost or Stolen Device
1. Employee reports to IT immediately
2. IT locates device via Hexnode Find
3. IT initiates remote wipe via Hexnode
4. IT documents incident in IT Decision & Change Log

### Account Compromise
1. Immediately disable Google Workspace account
2. Rotate all passwords in Keeper for the affected user
3. Review Google Admin audit logs for unauthorized activity
4. Document incident

### Crisis Communication
- Use IT Communications Style Guide (Tier 1 RED — Service Alert) for company notification
- See [[runbooks/it-comms-style-guide]] *(page to be created)*

## Data Recovery (CIS Control 11)

| Item | Detail |
|------|--------|
| RPO/RTO | Not yet formally defined — POAM item |
| Backup scope | Planned — CIS Control 11.2 |
| Retention | Planned |
| Backup protection | FileVault + Hexnode escrowed keys; offsite/cloud backup — planned |
| Backup testing | Not yet executed — POAM item |

## Security Awareness (CIS Control 14.1)

- KnowBe4 phishing simulations deployed — see [[vendors/knowbe4]]
- Physical security walkthroughs: planned — CIS 14.1
- Formal program ownership: not yet documented — gap

## Plan of Action & Milestones ([[concepts/poam|POAM]])

| Item | Status |
|------|--------|
| Network segmentation (CIS 12.5) | Planned — current network is flat |
| Formal backup scope & testing | Planned |
| Physical security walkthrough schedule | Planned |
| Formal security awareness program documentation | Gap |
| Formal risk register | Gap |
| Written IR plan (full) | Partial |
| BCP documentation | Gap |

## Addendum

**IT-SSP-001-A1** (2026-06-18) extends this SSP to the GunnerTeam product environment (second in-scope boundary). See [[gunnerteam/ssp-addendum-1-product-environment]].

Controls APP-01…APP-09 are implemented and verified. Addendum is DRAFT — pending the same sign-off chain as this document (Tyler, Eric, Eddie, Andrew).

## Approval & Sign-Off

- AUP and SSP v1.0 presented to leadership 2026-03-18 (SEC-002) — pending formal signature as of that date
- Sign-off status: **in progress**
