---
title: T1486 — Data Encrypted for Impact (Ransomware)
type: threat
tags: [mitre, t1486, ransomware, impact, threat, backup]
created: 2026-04-13
updated: 2026-04-13
status: developing
sources: []
related: ["[[gunnerteam/system-security-plan]]", "[[vendors/hexnode]]", "[[concepts/incident-response]]", "[[runbooks/incident-response]]", "[[threats/t1566-phishing]]", "[[threats/t1078-valid-accounts]]"]
---

# T1486 — Data Encrypted for Impact

**Tactic:** Impact  
**Technique ID:** T1486  

## Description

Adversaries encrypt data on target systems to deny access and extort payment. Ransomware typically follows initial access via phishing (T1566) or valid accounts (T1078), then moves laterally before triggering encryption. Can affect local files, network shares, and cloud-connected storage.

## Gunner Exposure

| Factor | Detail |
|--------|--------|
| Primary data surface | Google Drive (cloud); local Mac storage |
| Network | Flat network — no segmentation (POAM gap); one compromised device increases lateral movement risk |
| **Backup status** | **No formal backup scope or testing — open POAM item** |
| RPO/RTO | Not formally defined — POAM item |
| Partial recovery | Google Drive version history — covers cloud data only |

## Controls in Place

| Control | Coverage |
|---------|---------|
| FileVault (Hexnode) | Full-disk encryption on Macs — escrowed recovery keys; protects against physical theft, not ransomware |
| Google Drive version history | Partial recovery for cloud files altered by ransomware |
| Hexnode remote wipe | Containment — isolate and wipe compromised device |
| [[concepts/mfa]] | Raises cost of initial access; reduces entry points |
| App Install control (Hexnode) | Mac App Store + identified developers only — reduces malware delivery surface |
| Chrome HTTPS-only + Safe Browsing | Blocks known malware delivery URLs |

## Detection Notes

- No SIEM or EDR currently deployed
- Hexnode compliance dashboard monitors device health, not file activity
- Google Workspace has anomalous activity alerts — mass file modification in Drive may trigger

## Gaps

- **No tested backup and recovery plan** — this is the primary gap. Google Drive version history is not a substitute for a formal backup strategy with tested restore procedures.
- **Flat network** — CIS 12.5 (network segmentation) is a POAM item. Lateral movement from one compromised endpoint is uncontained.
- **No antivirus/EDR** — Bitdefender estimated ~$1.1k/yr, noted as a CMMC gap. CIS IG1 does not strictly require it, but absence is meaningful for ransomware.
- No formal ransomware IR playbook beyond the general procedures in [[runbooks/incident-response]].

## Gunner-Specific Note

Ransomware is the highest-consequence threat for a company of Gunner's size. A successful attack against the flat network with no tested backup plan could be operationally catastrophic. Backup scope, off-site storage, and tested recovery are the most critical open [[concepts/poam|POAM]] items in [[gunnerteam/system-security-plan]].

## Response

Follow [[runbooks/incident-response]] — Procedure 3 (Suspected Ransomware / Malware): isolate device, disable Google account, assess scope, contain, communicate. **Do not pay ransom without leadership approval.**

## Related

- [[gunnerteam/system-security-plan]] — POAM items: backup, network segmentation, BCP
- [[runbooks/incident-response]] — Procedure 3: ransomware response
- [[concepts/incident-response]] — IR authority and defined procedures
- [[threats/t1566-phishing]] — common initial access vector
- [[threats/t1078-valid-accounts]] — credential-based initial access
