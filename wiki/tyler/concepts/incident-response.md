---
title: Incident Response
type: concept
tags: [incident-response, security, ir, cis, ssp]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [System Security Plan.docx]
related: ["[[gunnerteam/system-security-plan]]", "[[runbooks/incident-response]]", "[[runbooks/it-comms-style-guide]]", "[[vendors/hexnode]]", "[[vendors/google-workspace]]", "[[threats/t1078-valid-accounts]]", "[[threats/t1486-data-encrypted-for-impact]]"]
---

# Incident Response

## Response Authority

| Role | Responsibility |
|------|---------------|
| Tyler Suffern (IT Manager) | Primary — owns IR; day-to-day authority |
| [[entities/Eric Recchia|Eric Recchia]] (VP of Strategy) | Backup — acts in Tyler's absence; notify on admin compromise |
| [[entities/Eddie Prchal|Eddie]] / [[entities/Andrew Prchal|Andrew Prchal]] (Owners) | Notify on major incidents (ransomware, data breach, AWS) |

## Defined Incident Types (SSP v1.1)

Three scenarios are defined in [[gunnerteam/system-security-plan]]:

### Lost or Stolen Device
1. Employee reports to IT immediately
2. IT locates via Hexnode Find
3. Remote wipe initiated via Hexnode
4. Incident documented in IT Decision & Change Log

### Account Compromise
1. Disable Google Workspace account immediately
2. Rotate all Keeper passwords for affected user
3. Review Google Admin audit logs
4. Document incident

### Suspected Ransomware / Malware
See [[runbooks/incident-response]] — Procedure 3.

For actionable step-by-step procedures, see [[runbooks/incident-response]].

## Crisis Communication

Use the **RED tier (Tier 1 — Service Alert)** from [[runbooks/it-comms-style-guide]] for company-wide incident notification.

## POAM Gaps

The following IR-related items are open in the SSP [[concepts/poam|Plan of Action & Milestones]]:

- [ ] Full written IR plan — currently partial
- [ ] Formal risk register
- [ ] BCP (Business Continuity Plan)
- [ ] Backup scope, testing, and off-site storage
- [ ] RPO/RTO formally defined

## Relevant Threat Pages

- [[threats/t1078-valid-accounts]] — account compromise scenario
- [[threats/t1486-data-encrypted-for-impact]] — ransomware scenario
- [[threats/t1566-phishing]] — most common initial access vector leading to incidents

## Related

- [[gunnerteam/system-security-plan]] — SSP v1.1; IR authority and defined procedures
- [[runbooks/incident-response]] — full actionable runbook
- [[runbooks/it-comms-style-guide]] — crisis communication templates (RED tier)
