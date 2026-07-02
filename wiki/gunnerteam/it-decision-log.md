---
title: "IT Decision & Change Log"
type: gunner
tags: [gunner, governance, decisions, changelog, audit]
created: 2026-04-21
updated: 2026-04-21
sources: [IT Decision & Change Log.docx]
related:
  - "[[gunnerteam/system-security-plan]]"
  - "[[gunner/environment]]"
  - "[[vendors/hexnode]]"
  - "[[concepts/cis-ig1]]"
status: stable
---

# IT Decision & Change Log

**Document ID:** IT-GOV-LOG-001 v1.1  
**Classification:** INTERNAL  
**Owner:** IT Department (Tyler Suffern)  
**Established:** 2026-03-18  
**Review cycle:** Quarterly / on change  
**Location:** IT folder in Google Drive

Gunner's official governance record of IT decisions, security program changes, policy updates, configuration changes, vendor selections, incidents, and exceptions. Dual purpose: day-to-day decision record + audit-ready evidence library for insurance, enterprise clients, and auditors.

## Log Structure

Five logs — add entries to the appropriate section, never delete old entries:

| Log | Purpose |
|-----|---------|
| 1 — Security Program Decisions | Security posture decisions, framework approvals, authorized by leadership |
| 2 — Policy & Document Changes | AUP, SSP, this log, any formal IT policy version changes |
| 3 — Configuration & System Changes | Hexnode/MDM, Chrome Enterprise, network, any significant system change |
| 4 — Vendor & Software Decisions | Add/remove/change SaaS tools and vendors |
| 5 — Incidents & Policy Exceptions | Security incidents + formally accepted policy exceptions |

## Key Decisions on Record

### Security Program (Log 1)

| ID | Decision | Authorized By |
|----|----------|---------------|
| SEC-001 | CIS IG1 "Gunner Security Baseline" approved as official security framework. ISO 27001 (Option 3) deferred pending growth. | [[entities/Eddie Prchal|Eddie Prchal]], [[entities/Andrew Prchal|Andrew Prchal]], [[entities/Eric Recchia|Eric Recchia]] |
| SEC-002 | AUP and SSP v1.0 drafted and presented to leadership. Pending formal sign-off. | [[entities/Eric Recchia|Eric Recchia]] |

### Configuration Changes (Log 3)

| ID | System | Change |
|----|--------|--------|
| CHG-2026-001 | Hexnode | Disabled "Prevent pairing with non-Configurator hosts" to allow Xcode pairing for GunnerForms dev. L2 control only — no L1 gap. Mac iCloud toggle pending. |
| CHG-2026-002 | Hexnode | Enabled "Install Apps", "Trust Enterprise Apps", "Users can modify enterprise app trust" for custom app testing. |
| CHG-2026-003 | Hexnode | Enabled "Manage Copy/Paste between managed/unmanaged apps" — copy/paste was broken for iMessage links. Medium risk. |

### Vendor Decisions (Log 4)

| Vendor | Status | Notes |
|--------|--------|-------|
| Hexnode UEM | Continue | Under evaluation for Jamf migration (Microsoft stack consolidation) |
| Google Workspace | Continue | Under evaluation for Microsoft 365 migration — financial case prepared |
| Google Drive Backup | Open | Evaluating Afi.ai, Backupify, Veeam — no selection yet |
| Keeper Security | Continue | Mandatory for all staff |

### Exceptions (Log 5)

| ID | Exception | Status |
|----|-----------|--------|
| EXC-001 | Chrome sign-in not fully disabled (L2 control). Accepted — Google Workspace SSO requires browser sign-in. Mitigated by `RestrictSigninToPattern`. | Accepted |

## For Auditors

Log 1, SEC-001 (dated March 2026, signed by owners) is the primary evidence that Gunner's security program has formal leadership authorization. Combined with the AUP and SSP, this constitutes the core IT governance record.

## Maintenance Rules

- Add entries to the bottom of the relevant table
- Never delete existing rows
- All entries require: date, ID, description, authorized by
- Quarterly review: update open statuses, escalate >90 day items to [[entities/Eric Recchia|Eric]]
- Version-bump the document when making significant updates
