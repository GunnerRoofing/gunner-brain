---
title: CMMC Level 1 — Cybersecurity Maturity Model Certification
type: concept
tags: [cmmc, compliance, federal, dod, nist, certification]
created: 2026-04-13
updated: 2026-04-14
status: stable
sources: [CMMC Presentation.txt, AG_Level1_V2.0_FinalDraft_20211210_508.pdf]
related: ["[[concepts/cis-ig1]]", "[[gunnerteam/system-security-plan]]", "[[gunner/federal-market]]", "[[ciso-track/roadmap]]"]
---

# CMMC Level 1 — Cybersecurity Maturity Model Certification

## What It Is

CMMC (Cybersecurity Maturity Model Certification) is a DoD framework that gates access to federal contracts. **Level 1** covers 17 basic cyber hygiene practices derived from FAR 52.204-21 and NIST SP 800-171. Non-certified companies cannot bid on DoD contracts.

CMMC Level 1 is a **self-assessment** — Gunner verifies its own compliance and submits a score to the SPRS (Supplier Performance Risk System) database. CEO or President must sign the submission.

Reference: NIST SP 800-171Ar3 (authoritative standard)  
Assessment Guide: AG_Level1_V2.0_FinalDraft_20211210_508.pdf (official DoD self-assessment methodology — now in vault)

## Gunner's Current Status

As of the CMMC feasibility presentation: **~70% ready.** Being "Cloud Native" ([[vendors/google-workspace|Google Workspace]], [[vendors/hexnode|Hexnode]] MDM, SaaS stack) puts Gunner ahead of ~90% of competitors who run on-premise infrastructure.

### Already Completed

| Requirement | Status | How |
|-------------|--------|-----|
| Automate OS/app updates | Done | Hexnode MDM enforces update policy |
| Email identity (DKIM/SPF) | Done | Configured on gunnerroofing.com |
| Device wiping/sanitization | Done | Hexnode remote wipe capability |
| System Security Plan (SSP) | Done (v1.1) | [[gunnerteam/system-security-plan]] |
| Acceptable Use Policy (AUP) | Done (v1.1) | [[runbooks/acceptable-use-policy]] |

### Remaining Gaps

| Gap | Recommendation | Est. Cost |
|-----|---------------|-----------|
| Antivirus / endpoint protection | [[vendors/bitdefender|Bitdefender GravityZone]] | ~$1,100/yr |
| Visitor logs | Formalize front desk sign-in process | $0 |

## 4-Phase Certification Process

### Phase 1 — PIEE Registration
- Register in the **Procurement Integrated Enterprise Environment (PIEE)**
- Obtain a **CAGE code** from SAM.gov first

### Phase 2 — Self Assessment
- Self-verify all 17 CMMC Level 1 requirements
- **Zero-Gap Rule:** All gaps must be remediated before submission — cannot submit with known deficiencies

### Phase 3 — Documentation & Submission
- Complete the **System Security Plan (SSP)** — ~20 pages describing how each requirement is met (Gunner's SSP is already written — major head start)
- Log into **SPRS** and enter score: 17/17
- CEO or President signs the submission

### Phase 4 — Annual Maintenance
- Re-submit assessment every year
- Ensure new employees receive and sign the AUP

## 17 Practices — Domain Breakdown

The official Assessment Guide (v2.0) operationalizes each practice with explicit pass/fail criteria:

| Domain | Abbrev | Practices | Key Gunner Gap |
|--------|-------|-----------|---------------|
| Access Control | AC | 4 | Mostly met via [[vendors/google-workspace|Google Workspace]] OUs + [[concepts/sso|SSO]] |
| Identification & Authentication | IA | 2 | Met via [[concepts/mfa|MFA]] enforcement |
| Media Protection | MP | 1 | Met via Hexnode remote wipe |
| Physical Protection | PE | 4 | Visitor log process gap |
| System & Communications Protection | SC | 2 | Network segmentation gap (flat network) |
| System & Information Integrity | SI | 4 | **Endpoint AV gap** — SI.L1-3.14.2 requires malicious code protection |

> The Assessment Guide's **Zero-Gap Rule**: all 17 must be MET before SPRS submission. The SI antivirus gap is the primary technical blocker.

See: [[summaries/cmmc-level1-assessment-guide]] for detailed domain breakdown.

## MITRE / NIST Alignment

CMMC Level 1 maps to basic safeguarding requirements. Gunner's existing CIS IG1 baseline ([[concepts/cis-ig1]]) satisfies or overlaps with most CMMC L1 controls — CIS IG1 is a superset for the technical controls.

## Gunner-Specific Exposure Notes

- The SSP is already written — this is the most labor-intensive part of certification and is done
- The AUP requirement (new employees must sign) is already in place
- Primary remaining technical gap: **endpoint antivirus** ([[vendors/bitdefender|Bitdefender GravityZone]] ~$1.1k/yr)
- Primary remaining process gap: **visitor logs / front desk sign-in**
- See [[gunner/federal-market]] for the business case and other non-CMMC compliance requirements
