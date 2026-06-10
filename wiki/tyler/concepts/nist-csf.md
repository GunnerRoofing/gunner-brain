---
title: NIST Cybersecurity Framework 2.0
type: concept
tags: [nist, csf, framework, risk-management, govern, study, cissp]
created: 2026-04-14
updated: 2026-04-14
status: stable
sources: [NIST.CSWP.29.pdf]
related: ["[[concepts/cis-ig1]]", "[[concepts/cmmc]]", "[[gunner/system-security-plan]]", "[[ciso-track/roadmap]]", "[[summaries/nist-csf-2]]"]
---

# NIST Cybersecurity Framework 2.0

## What It Is

The NIST Cybersecurity Framework (CSF) is a voluntary risk management framework published by the National Institute of Standards and Technology. Version 2.0 was released **February 26, 2024** — the first major update since v1.1 (2018).

Key changes from 1.1 → 2.0:
- **New GOVERN function** — explicitly addresses leadership, policy, risk management strategy, and supply chain risk
- Expanded scope — no longer framed as "critical infrastructure only"; designed for all organizations
- Stronger supply chain / third-party risk (TPRM) emphasis
- Community Profiles and quick-start guides (including an SMB profile)

## The Six Functions

```
GOVERN → IDENTIFY → PROTECT → DETECT → RESPOND → RECOVER
```

| Function | Abbreviation | Core Question |
|----------|-------------|--------------|
| **GOVERN** | GV | How do we manage cybersecurity risk at the leadership level? |
| **IDENTIFY** | ID | What assets and risks do we have? |
| **PROTECT** | PR | What safeguards are in place? |
| **DETECT** | DE | How do we find problems when they happen? |
| **RESPOND** | RS | What do we do when an incident occurs? |
| **RECOVER** | RC | How do we restore operations after an incident? |

### GOVERN (New in CSF 2.0)

The most significant addition. Addresses the "why" behind cybersecurity decisions. Subcategory groups:

| Code | Group | What It Covers |
|------|-------|---------------|
| GV.OC | Organizational Context | Risk tolerance, mission, legal/regulatory requirements, stakeholder expectations |
| GV.RM | Risk Management Strategy | Formal risk priorities, risk appetite, risk process ownership |
| GV.RR | Roles & Responsibilities | CISO-level accountability documented; cybersecurity roles defined |
| GV.PO | Policy | Policies developed, communicated, enforced, and reviewed |
| GV.OV | Oversight | Leadership reviews cybersecurity outcomes periodically |
| GV.SC | Supply Chain Risk | Third-party risk management (TPRM) formally included |

## Core, Profiles, and Tiers

**The Core** is the full taxonomy of Functions → Categories → Subcategories. It defines *what* cybersecurity activities an organization should perform.

**Profiles** are customized slices of the Core aligned to an organization's mission, risk tolerance, and resources:
- **Current Profile** — what you do now
- **Target Profile** — what you want to do
- Gap between them = the roadmap

**Tiers (1–4)** describe how sophisticated an organization's risk management approach is:

| Tier | Name | Description |
|------|------|-------------|
| 1 | Partial | Reactive, informal, no organization-wide approach |
| 2 | Risk Informed | Policies exist but not consistently applied |
| 3 | Repeatable | Formal, consistent, reviewed periodically |
| 4 | Adaptive | Continuously adapts; shares information externally |

> Tiers are *not* maturity scores to maximize — they describe appropriate risk management approaches relative to organizational needs.

## Relationship to CIS Controls

CIS Controls v8.1.2 (March 2025) added explicit NIST CSF 2.0 GOVERN function mapping, completing alignment across all six functions. This means:

- Gunner's CIS IG1 baseline can be directly mapped to NIST CSF 2.0 language
- GOVERN-category gaps (policy, risk management strategy, supply chain risk) are surfaced by the new mapping
- Useful for CISSP domain study and for board-level risk communication

See: [[concepts/cis-ig1]] — Gunner's active security framework  
See: [[summaries/cis-controls-v8-1-2]] — v8.1.2 update details

## Gunner's Current Tier Estimate

| Function | Tier Estimate | Notes |
|----------|--------------|-------|
| GOVERN | 1 → 2 | SSP and AUP exist; risk management strategy informal; no formal risk register |
| IDENTIFY | 2 | Asset inventory via Hexnode; app inventory documented; no formal risk assessment cadence |
| PROTECT | 2 → 3 | MFA, MDM, SSO, email security all implemented; gap: no AV/EDR |
| DETECT | 1 → 2 | Google Admin audit logs exist; no SIEM; no formal monitoring cadence |
| RESPOND | 2 | IR runbook exists; not tested; no formal IR plan (POAM item) |
| RECOVER | 1 → 2 | Google Drive version history; no formal backup scope or testing (POAM item) |

## Gunner GOVERN Gaps

The GOVERN function is the most significant gap for Gunner:
- No formal **risk register** (POAM item)
- No formal **BCP** (POAM item)
- **Vendor renewal tracking** not documented — supply chain risk gap (GV.SC)
- **Risk appetite** not formally stated — implied by CIS IG1 selection; not written

## Study Notes (CISSP / CISO Track)

- NIST CSF 2.0 is directly relevant to CISSP Domain 1 (Security & Risk Management)
- GOVERN aligns to the CISO role's primary responsibility: connecting business risk to security decisions
- The Profiles concept maps to gap analysis and security roadmapping — core CISO skills
- CSF 2.0 is the primary framework language for communicating with boards and executives

See: [[ciso-track/roadmap]] — CISSP study plan  
See: [[summaries/nist-csf-2]] — detailed source summary
