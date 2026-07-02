---
title: CMMC Level 1 Assessment Guide v2.0 — Summary
type: summary
tags: [cmmc, compliance, federal, dod, self-assessment, sprs]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [AG_Level1_V2.0_FinalDraft_20211210_508.pdf]
related: ["[[concepts/cmmc]]", "[[gunnerteam/federal-market]]", "[[gunnerteam/system-security-plan]]"]
---

# CMMC Level 1 Assessment Guide v2.0 — Summary

**Source:** AG_Level1_V2.0_FinalDraft_20211210_508.pdf  
**Published:** December 10, 2021 (Final Draft)  
**Issuer:** Office of the Under Secretary of Defense for Acquisition & Sustainment

## Purpose

This is the official DoD assessment methodology for CMMC Level 1 self-assessments. It operationalizes how organizations verify the 17 Level 1 practices and submit scores to SPRS. It is the authoritative reference for what "meets" vs. "does not meet" each practice.

## 17 Practices Across 6 Domains

| Domain | Abbreviation | # Practices |
|--------|-------------|-------------|
| Access Control | AC | 4 |
| Identification & Authentication | IA | 2 |
| Media Protection | MP | 1 |
| Physical Protection | PE | 4 |
| System & Communications Protection | SC | 2 |
| System & Information Integrity | SI | 4 |

### Key Practices (Selected)

**AC (Access Control)**
- AC.L1-3.1.1 — Limit system access to authorized users
- AC.L1-3.1.2 — Limit system access to permitted transactions
- AC.L1-3.1.20 — Verify and control external connections
- AC.L1-3.1.22 — Control public-facing CUI (not applicable at Level 1, but awareness context)

**IA (Identification & Authentication)**
- IA.L1-3.5.1 — Identify information system users
- IA.L1-3.5.2 — Authenticate users, processes, and devices

**MP (Media Protection)**
- MP.L1-3.8.3 — Sanitize or destroy information system media before disposal

**PE (Physical Protection)**
- PE.L1-3.10.1 — Limit physical access to authorized individuals
- PE.L1-3.10.2 — Escort visitors and monitor visitor activity
- PE.L1-3.10.3 — Maintain audit logs of physical access
- PE.L1-3.10.4 — Control and manage physical access devices

**SC (System & Communications Protection)**
- SC.L1-3.13.1 — Monitor, control, and protect communications
- SC.L1-3.13.5 — Implement subnetworks for publicly accessible system components

**SI (System & Information Integrity)**
- SI.L1-3.14.1 — Identify, report, and correct information and information system flaws
- SI.L1-3.14.2 — Provide protection from malicious code
- SI.L1-3.14.4 — Update malicious code protection mechanisms
- SI.L1-3.14.5 — Perform periodic scans and real-time scanning

## Assessment Scoring

- Each practice is scored as **MET** or **NOT MET**
- All 17 must be MET before submission (Zero-Gap Rule)
- Score submitted to SPRS database
- CEO or equivalent must affirm the submission
- Annual re-assessment required

## Gunner Applicability

Most Level 1 practices are met via existing controls:
- **AC:** Google Workspace OU structure + SSO
- **IA:** MFA enforcement across Google Workspace
- **MP:** Hexnode remote wipe for media sanitization at end-of-life
- **PE:** Physical access at CT HQ and branch offices (verify visitor log gap)
- **SC:** Network segmentation planned (POAM) — flat network is a gap for SC.L1-3.13.5
- **SI:** **Gap** — antivirus/endpoint protection not deployed; Bitdefender GravityZone (~$1.1k/yr) is the recommended fix

> **Key gap:** SI.L1-3.14.2 (malicious code protection) requires endpoint AV. This is the primary technical blocker for CMMC Level 1 submission.
