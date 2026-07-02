---
title: Incident Response Runbook
type: runbook
tags: [incident-response, runbook, security, ir]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [System Security Plan.docx]
related: ["[[concepts/incident-response]]", "[[gunnerteam/system-security-plan]]", "[[vendors/hexnode]]", "[[vendors/google-workspace]]", "[[vendors/keeper]]", "[[runbooks/it-comms-style-guide]]"]
---

# Incident Response Runbook

**Purpose:** Actionable response steps for the three most likely security incidents at Gunner Roofing.  
**Scope:** All Gunner offices and managed devices.  
**Primary Responder:** Tyler Suffern (IT Manager)  
**Backup Responder:** [[entities/Eric Recchia|Eric Recchia]] (VP of Strategy)  
**Last Verified:** 2026-04-13  

> A full written IR plan is a POAM item in [[gunnerteam/system-security-plan]]. This runbook covers the defined scenarios. Expand as incidents occur and patterns emerge.

---

## Procedure 1 — Lost or Stolen Device

**Trigger:** Employee reports device missing or stolen.

| Step | Action | Tool |
|------|--------|------|
| 1 | Employee reports to IT immediately via Google Chat or phone | — |
| 2 | Locate device via Hexnode Find | Hexnode |
| 3 | If device cannot be recovered or is confirmed stolen → initiate remote wipe | Hexnode |
| 4 | Confirm FileVault was active — escrowed key in Hexnode vault | Hexnode |
| 5 | If device had access to sensitive data: rotate credentials for affected apps in Keeper | Keeper |
| 6 | Document: device serial, date reported, actions taken, outcome | IT Decision & Change Log |
| 7 | Procure replacement via Apple Business Manager | ABM / [[concepts/apple-business-manager]] |

**Escalation:** If device contained customer PII or financial data, notify [[entities/Eric Recchia|Eric Recchia]] and assess notification requirements.

**MITRE relevance:** [[threats/t1078-valid-accounts]] — lost device without encryption = cached credential risk.

---

## Procedure 2 — Account Compromise

**Trigger:** Suspicious login alert, user reports unauthorized access, phishing click confirmed, credentials found in breach data.

| Step | Action | Tool |
|------|--------|------|
| 1 | Immediately disable Google Workspace account | Google Admin Console |
| 2 | Rotate all passwords in Keeper for affected user | Keeper |
| 3 | Review Google Admin audit logs — what was accessed, when, from where | Google Admin Console |
| 4 | Check for unauthorized OAuth grants or connected apps | Google Admin → Security → Connected Apps |
| 5 | If Admin account compromised: review all admin actions in the suspect window | Google Admin audit log |
| 6 | Notify [[entities/Eric Recchia|Eric Recchia]] if Admin OU account; notify [[entities/Eddie Prchal|Eddie]]/[[entities/Andrew Prchal|Andrew]] if broader impact | Direct |
| 7 | Communicate to company if operations affected (RED tier) | [[runbooks/it-comms-style-guide]] |
| 8 | Document: user account, timeline, activity observed, actions taken | IT Decision & Change Log |
| 9 | Re-enable account only after full credential rotation confirmed | Google Admin Console |

**MITRE relevance:** [[threats/t1078-valid-accounts]], often preceded by [[threats/t1566-phishing]].

---

## Procedure 3 — Suspected Ransomware / Malware

**Trigger:** Unusual file activity, encrypted files, ransom note, Hexnode compliance alert, user reports.

| Step | Action | Tool |
|------|--------|------|
| 1 | Isolate device — physically disconnect from network; remotely lock via Hexnode | Hexnode |
| 2 | **Do NOT pay ransom** without approval from [[entities/Eddie Prchal|Eddie]]/[[entities/Andrew Prchal|Andrew Prchal]] | — |
| 3 | Identify scope: which device(s), which data, which user account was active | Google Admin / Hexnode |
| 4 | Disable affected user's Google Workspace account to contain further spread | Google Admin Console |
| 5 | Assess Google Drive for mass file changes — check version history for recovery | Google Drive |
| 6 | Initiate remote wipe of confirmed-compromised device | Hexnode |
| 7 | Notify leadership immediately: [[entities/Eric Recchia|Eric Recchia]] → [[entities/Eddie Prchal|Eddie]]/[[entities/Andrew Prchal|Andrew Prchal]] | Direct |
| 8 | Communicate to company if operations impacted (RED tier) | [[runbooks/it-comms-style-guide]] |
| 9 | Document everything: timeline, scope, device, user, all response actions | IT Decision & Change Log |

> **Backup gap:** Formal backup scope and testing are POAM items. Google Drive version history is the current recovery mechanism for cloud data. Local-only files may not be recoverable.

**MITRE relevance:** [[threats/t1486-data-encrypted-for-impact]].

---

## Crisis Communication

Use the **RED tier (Tier 1 — Service Alert)** template from [[runbooks/it-comms-style-guide]] for any company-wide incident notification.

## Post-Incident

1. Update IT Decision & Change Log with complete timeline
2. Identify root cause and any control gaps that were exploited
3. Update relevant threat pages and this runbook with real-world context
4. Append session entry to `wiki/log.md`
