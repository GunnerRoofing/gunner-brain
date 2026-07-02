---
title: CIS Controls v8.1.2 — Implementation Group 1 (IG1)
type: concept
tags: [cis, cis-ig1, framework, security-baseline, controls, compliance]
created: 2026-04-13
updated: 2026-04-14
status: stable
sources: [Gunner IT Governance.xlsx, IT Standards v2 Final.pptx, System Security Plan.docx, IT Decision & Change Log.docx, CIS_Controls_Guide_v8.1.2_0325_v2.pdf, CIS_Controls_Version_8.1.2___March_2025.xlsx]
related: ["[[vendors/hexnode]]", "[[vendors/google-workspace]]", "[[gunnerteam/system-security-plan]]", "[[ciso-track/roadmap]]", "[[concepts/nist-csf]]"]
---

# CIS Controls v8.1.2 — Implementation Group 1 (IG1)

## What It Is

The **CIS Critical Security Controls** (CIS Controls) is a prioritized set of safeguards developed by the Center for Internet Security to defend against the most common cyber attacks. Version 8.1.2 (March 2025) contains 18 controls — the same structure as v8.1, with the addition of **NIST CSF 2.0 GOVERN function mapping** across all safeguards.

**Implementation Group 1 (IG1)** is the foundational tier — "essential cyber hygiene" — designed for small organizations with limited IT resources. It covers the subset of controls that stop approximately **85% of common cyberattacks**.

## Gunner Adoption

CIS IG1 was officially adopted as Gunner Roofing's security framework on **2026-03-18** (Decision ID: SEC-001), authorized by [[entities/Eddie Prchal|Eddie Prchal]], [[entities/Andrew Prchal|Andrew Prchal]], and [[entities/Eric Recchia|Eric Recchia]].

> **Decision rationale:** Option 2 — CIS IG1 "Gunner Security Baseline" approved. Option 3 — ISO 27001 deferred pending business growth.

This framework is the reference for all Hexnode MDM policies, Google Workspace OU design, Chrome Enterprise policies, and the System Security Plan.

## IG1 Controls Relevant to Gunner

| CIS Control | Name | Gunner Implementation |
|-------------|------|----------------------|
| 1.1 | Hardware Asset Inventory | Hexnode MDM dashboard — all enrolled devices |
| 2 | Software Asset Management | App allowlisting via Chrome + Hexnode policy |
| 4.1 | Compliance Auditing | Hexnode compliance dashboard |
| 5.3 | Disable Dormant Accounts | Google Workspace Staging OU; 45-day review |
| 5.4 | Restrict Admin Privileges | Admin OU — 5 accounts, per-session MFA |
| 5.5 | Service Account Inventory | Service Accounts OU in Google Workspace |
| 5.6 | Centralize Account Management | Google Workspace as single IdP |
| 6.2 | Software Allowlist | Chrome extension allowlist per OU |
| 6.3 | MFA for External Apps | Google Workspace MFA enforcement |
| 6.4 | MFA for Remote Access | Admin OU per-session MFA |
| 6.7 | Centralize Access Control | Google SSO across all SaaS apps |
| 7 | OS & Patch Management | Hexnode update deferral + auto-install |
| 8.1 | Audit Log Review | Google Admin Console + Hexnode logs |
| 11.1–11.4 | Data Recovery | FileVault + Hexnode escrowed keys; backup scope in SSP |
| 12.5 | Network Segmentation | Planned (current: flat network) |
| 14.1 | Security Awareness Program | KnowBe4 phishing simulations |

## Framework Context (Security Playbook)

Gunner uses a multi-framework approach — each framework plays a different role:

| Framework | Role | Status at Gunner |
|-----------|------|-----------------|
| **CIS IG1** | The Checklist — "Essential Hygiene" baseline | **Active — primary framework** |
| NIST CSF 2.0 | The Strategy — maturity model (Identify, Protect, Detect, Respond, Recover) | Planned study |
| Zero Trust | The Philosophy — "Never trust, always verify" architecture | Aspirational |
| CMMC L1 | The License — DoD required for federal contracts | Evaluated; relevant if Gunner pursues government contracts |
| ISO 27001 | The Badge — international ISMS certification | Deferred pending growth |

## Strategic Options Evaluated (2026)

When selecting the framework, three options were presented to leadership:

| Feature | Option 1: Status Quo | Option 2: CIS IG1 ✓ | Option 3: ISO 27001 |
|---------|---------------------|---------------------|---------------------|
| Philosophy | Manual & Reactive | Automated & Proactive | Restrictive & Hardened |
| Device Enrollment | 90% (manual) | 100% (CIS 1.1) | 100% + MAC whitelist |
| Network | Flat (open) | Segmented (CIS 12.5) | Port-locked only |
| Data Flow | Unrestricted | Managed @gunner (CIS 6.1) | Siloed (no AirDrop/iCloud) |
| Compliance | Zero | Formal documentation | ISO 27001 certified |

## Gunner-Specific Exposure Notes

- Current: network segmentation (CIS 12.5) is planned but not yet implemented — flat network is an open risk
- Security awareness program (CIS 14.1) partially satisfied by KnowBe4 but formal program ownership not yet documented
- Backup testing (CIS 11) is planned, not yet executed — see [[gunnerteam/system-security-plan]] POAM

## NIST CSF 2.0 Alignment

CIS Controls v8.1.2 maps all 18 controls to all six NIST CSF 2.0 functions, including the new GOVERN function. This allows Gunner's CIS IG1 baseline to be expressed in CSF 2.0 language for reporting to leadership.

See: [[concepts/nist-csf]] for the full NIST CSF 2.0 concept page.  
See: [[summaries/cis-controls-v8-1-2]] for the v8.1.2 update source summary.

## Related Benchmark Pages

- [[summaries/cis-google-workspace-benchmark]] — CIS Google Workspace v1.3.0 (June 2025)
- [[summaries/cis-chrome-enterprise-benchmark]] — CIS Chrome Enterprise Core v1.0.0 (June 2025)
- [[summaries/cis-ios-26-benchmark]] — CIS Apple iOS 26 v1.0.0 (October 2025)
- [[summaries/cis-macos-26-benchmark]] — CIS Apple macOS 26 Tahoe v1.0.0 (October 2025)
- [[summaries/cis-ms-office-benchmark]] — CIS Microsoft Office Enterprise v1.2.0 (study reference)

## Related Threat Pages

- [[threats/t1566-phishing]] — CIS 9 (Email and Web Browser Protections)
- [[threats/t1078-valid-accounts]] — CIS 5, 6 (Account Management, Access Control)
- [[threats/t1110-brute-force]] — CIS 5, 6 (Account Management, MFA)
- [[threats/t1486-data-encrypted-for-impact]] — CIS 11 (Data Recovery), CIS 12 (Network Segmentation)
- [[threats/t1199-trusted-relationship]] — CIS 15 (Service Provider Management)
