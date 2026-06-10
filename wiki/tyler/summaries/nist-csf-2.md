---
title: NIST Cybersecurity Framework 2.0 — Summary
type: summary
tags: [nist, csf, framework, risk-management, study]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [NIST.CSWP.29.pdf]
related: ["[[concepts/nist-csf]]", "[[concepts/cis-ig1]]", "[[ciso-track/roadmap]]"]
---

# NIST Cybersecurity Framework 2.0 — Summary

**Source:** NIST.CSWP.29.pdf — NIST Cybersecurity Framework 2.0  
**Published:** February 26, 2024  
**Issuer:** National Institute of Standards and Technology (NIST)

## What Changed from CSF 1.1 → 2.0

| Change | Detail |
|--------|--------|
| New GOVERN function | 6th function added; explicitly addresses roles, policy, risk management at leadership level |
| Expanded scope | No longer "critical infrastructure" only — applicable to all organizations |
| Supply chain emphasis | GOVERN includes supply chain risk (TPRM) |
| Profile templates | New quick-start guides and community profiles (SMB, enterprise) |
| Tiers clarified | 4 tiers remain; described more as risk management maturity descriptors |

## The Six Functions

| Function | Abbreviation | What It Does |
|----------|-------------|-------------|
| **GOVERN** | GV | Sets cybersecurity strategy, roles, policy, supply chain risk — the "why" |
| **IDENTIFY** | ID | Asset management, risk assessment, improvement planning |
| **PROTECT** | PR | Safeguards to limit impact — IAM, data security, platform security, awareness |
| **DETECT** | DE | Continuous monitoring, anomaly detection |
| **RESPOND** | RS | Incident management, analysis, communication, mitigation |
| **RECOVER** | RC | Restoration, communication, improvement after incident |

### GOVERN (New in 2.0)

The most significant addition. Covers:
- **GV.OC** — Organizational Context: risk tolerance, mission, regulatory requirements, stakeholder expectations
- **GV.RM** — Risk Management Strategy: formal risk priorities, risk appetite, risk process owners
- **GV.RR** — Roles and Responsibilities: CISO-level accountability documented
- **GV.PO** — Policy: policies developed, communicated, enforced
- **GV.OV** — Oversight: leadership review of cybersecurity outcomes
- **GV.SC** — Supply Chain Risk Management: TPRM formally included

## Core, Profiles, Tiers

**Core:** The Functions/Categories/Subcategories taxonomy — what cybersecurity activities an organization should perform.

**Profiles:** Customized snapshots of the Core aligned to business requirements. A "current profile" vs "target profile" gap = roadmap.

**Tiers (1–4):**
| Tier | Name | Description |
|------|------|-------------|
| 1 | Partial | Reactive; informal; no organization-wide approach |
| 2 | Risk Informed | Policies exist but not consistently applied |
| 3 | Repeatable | Formal, consistent, reviewed periodically |
| 4 | Adaptive | Actively adapts; continuous improvement; shares info externally |

> Gunner is approximately Tier 2 → Tier 3 transition: formal policies (SSP, AUP) exist; consistent application in progress (Hexnode MDM, Google Workspace hardening); adaptive capability not yet present.

## NIST CSF 2.0 + CIS Controls v8.1.2 Alignment

CIS Controls v8.1.2 (March 2025 update) added explicit mapping to the new GOVERN function, completing alignment across all six CSF 2.0 functions. This makes CIS IG1 directly mappable to NIST CSF 2.0 — the two frameworks reinforce each other.

## Gunner Study Notes

- NIST CSF 2.0 is on Tyler's CISSP study path and appears in the ciso-track roadmap
- GOVERN function is directly relevant to Tyler's CISO trajectory — board-level risk communication
- The Profiles concept maps well to SSP gap analysis (current vs target state)
- TPRM (supply chain risk) connects to Gunner's vendor management gap (no formal renewal tracking)

See concept page: [[concepts/nist-csf]]
