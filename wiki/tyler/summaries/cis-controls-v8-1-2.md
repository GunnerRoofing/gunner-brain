---
title: CIS Controls v8.1.2 Guide — Summary
type: summary
tags: [cis, cis-controls, framework, security-baseline, nist-csf, study]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [CIS_Controls_Guide_v8.1.2_0325_v2.pdf, CIS_Controls_Version_8.1.2___March_2025.xlsx]
related: ["[[concepts/cis-ig1]]", "[[concepts/nist-csf]]", "[[ciso-track/roadmap]]"]
---

# CIS Controls v8.1.2 Guide — Summary

**Sources:**  
- `CIS_Controls_Guide_v8.1.2_0325_v2.pdf` — Narrative guide  
- `CIS_Controls_Version_8.1.2___March_2025.xlsx` — Reference spreadsheet with all safeguards, IG mappings, and NIST CSF 2.0 function tags  
**Published:** March 2025  
**Issuer:** Center for Internet Security (CIS)

## What Changed: v8.1 → v8.1.2

The primary change in v8.1.2 is the addition of **NIST CSF 2.0 GOVERN function mapping** across all 18 controls. Previously, CIS Controls mapped to IDENTIFY, PROTECT, DETECT, RESPOND, and RECOVER. The new GOVERN function — introduced in CSF 2.0 — required updating the mapping appendices.

All 18 controls and the 3 IG tiers are **unchanged** from v8.1.

## Structure

- **18 Controls** organized by priority
- **3 Implementation Groups (IGs):**
  - IG1 — Essential Cyber Hygiene (SMBs, limited resources) — ~57 safeguards
  - IG2 — Advanced Cyber Hygiene (mature IT, dedicated security) — IG1 + additional
  - IG3 — Expert Cyber Hygiene (large/complex orgs) — all safeguards
- **Reference spreadsheet (XLSX):** Full tabular listing of all safeguards with Security Function, IG1/2/3 flags, and descriptions

## The 18 Controls (Summary)

| # | Control | IG1 Relevant? |
|---|---------|--------------|
| 1 | Inventory and Control of Enterprise Assets | Yes |
| 2 | Inventory and Control of Software Assets | Yes |
| 3 | Data Protection | Yes |
| 4 | Secure Configuration of Enterprise Assets and Software | Yes |
| 5 | Account Management | Yes |
| 6 | Access Control Management | Yes |
| 7 | Continuous Vulnerability Management | Yes |
| 8 | Audit Log Management | Yes |
| 9 | Email and Web Browser Protections | Yes |
| 10 | Malware Defenses | Yes |
| 11 | Data Recovery | Yes |
| 12 | Network Infrastructure Management | Partial (12.5) |
| 13 | Network Monitoring and Defense | No (IG2+) |
| 14 | Security Awareness and Skills Training | Yes |
| 15 | Service Provider Management | Partial |
| 16 | Application Software Security | No (IG2+) |
| 17 | Incident Response Management | Yes |
| 18 | Penetration Testing | No (IG3 only) |

## NIST CSF 2.0 Function Mapping (Key Update)

The XLSX spreadsheet tags each safeguard with one of the six CSF 2.0 functions (GOVERN, IDENTIFY, PROTECT, DETECT, RESPOND, RECOVER). This allows Gunner's CIS IG1 baseline to be directly cross-walked against NIST CSF 2.0 requirements — useful for:
- CMMC gap analysis
- CISSP study (domain mapping)
- Board/leadership reporting using CSF 2.0 language

## Gunner Applicability

Gunner adopted CIS IG1 as its security baseline (Decision SEC-001, 2026-03-18). This update:
- Confirms the IG structure is unchanged — existing Hexnode/Google Workspace controls remain valid
- Adds a CSF 2.0 GOVERN mapping that is relevant to Tyler's CISO-track work
- The XLSX is a useful reference for gap analysis against Gunner's current controls

See: [[concepts/cis-ig1]] for Gunner's implementation status.
