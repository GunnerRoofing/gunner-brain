---
title: Summary — System Security Plan (SSP)
type: summary
tags: [summary, ssp, governance, incident-response, security-plan]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [System Security Plan.docx]
related: ["[[gunnerteam/system-security-plan]]", "[[concepts/cis-ig1]]", "[[vendors/hexnode]]", "[[vendors/google-workspace]]"]
---

# Summary — System Security Plan (SSP)

**Source:** `System Security Plan.docx`  
**Document ID:** IT-SSP-001 v1.1  
**Classification:** CONFIDENTIAL  
**Status:** Operational — awaiting formal leadership sign-off (SEC-002)

## Key Contents

Formal security documentation for Gunner Roofing Information Systems (GR IS). CIS IG1 baseline.

1. **System Identification** — System name, ownership ([[entities/Eric Recchia|Eric Recchia]]), authorizing officials ([[entities/Eddie Prchal|Eddie]] & [[entities/Andrew Prchal|Andrew Prchal]]), mission, operational status
2. **Roles & Responsibilities** — IT Manager primary owner; onboarding ("New Crew") and offboarding ("Kill-Switch") processes; PAM (5 admin accounts)
3. **Configuration Management** — Asset naming, patch management via Hexnode, software allowlisting
4. **Maintenance & Monitoring** — Hexnode compliance dashboard, Google Admin audit logs, security alerting
5. **Incident Response** — Lost/stolen device (Hexnode wipe); account compromise (Google disable + Keeper rotation); crisis comms via IT Comms Style Guide
6. **Data Recovery** — FileVault + escrowed keys; full backup plan and testing in POAM
7. **Security Awareness** — KnowBe4; physical walkthroughs planned
8. **POAM** — Active milestones: network segmentation, backup testing, formal awareness program, risk register, BCP

## Open POAM Items

- Network segmentation (CIS 12.5)
- Formal backup scope and testing
- Physical security walkthrough schedule
- Security awareness program documentation
- Formal risk register
- Full written IR plan
- BCP documentation

## Wiki Page

Full wiki page: [[gunnerteam/system-security-plan]]
