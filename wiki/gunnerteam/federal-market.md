---
title: Federal Market Expansion Strategy
type: gunner
tags: [federal, cmmc, dod, contracts, strategy, gunner]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [CMMC Presentation.txt]
related: ["[[concepts/cmmc]]", "[[gunnerteam/system-security-plan]]", "[[runbooks/acceptable-use-policy]]"]
---

# Federal Market Expansion Strategy

## The Opportunity

Federal roofing contracts (DoD, VA, Army Corps of Engineers) offer:
- Guaranteed payment
- High contract values
- Limited competition — CMMC certification acts as a barrier that most roofing companies can't clear

**Gunner's advantage:** Already "Cloud Native" and approximately 70% CMMC-ready, ahead of ~90% of competitors.

## Local Target Opportunities (Stamford Region)

| Facility | Location | Notes |
|----------|----------|-------|
| Sikorsky Aircraft | Stratford, CT | Massive defense facility; continuous maintenance needs |
| West Point Military Academy | West Point, NY | Hundreds of campus buildings (housing, academic, storage) |
| Naval Submarine Base | Groton, CT | High-security infrastructure projects |

## The 6 Compliance Pillars

All six must be satisfied to pursue federal contracts:

| Pillar | Requirement | Status |
|--------|-------------|--------|
| 1. Cyber | CMMC Level 1 — register score in SPRS database | ~70% ready — see [[concepts/cmmc]] |
| 2. Finance | Surety Bonding — Performance & Payment Bonds (Miller Act); capacity >$1M | Needs verification with surety broker |
| 3. Sourcing | Buy American Act — >55% domestic material cost; BAA Compliance Letters from suppliers | Process to be established |
| 4. Access | Background Checks — zero tolerance for warrants/felonies; pre-screen crews weeks before job | Process to be established |
| 5. Safety | EM 385-1-1 — stricter than OSHA; daily safety logs; superintendent may need OSHA 30 or EM 385 training | Not started |
| 6. Labor | Davis-Bacon Act — must pay "Prevailing Wage"; file weekly payroll reports; audit subcontractor payroll | Not started |

## Operating Model: General Contractor (Prime)

Gunner acts as **Prime Contractor** — not doing the physical roofing labor on federal jobs.

| Role | Who | Responsibility |
|------|-----|---------------|
| Prime Contractor | Gunner | Bidding, project management, procurement, safety compliance, permitting |
| Subcontractors | Third-party crews | Physical roofing labor |

**FAR 52.219-14 (Self-Performance Rule):**
- Gunner must keep **25% of contract revenue** (excluding materials) — cannot pass through cash
- Project management labor, overhead, and profit count toward the 25%
- If subcontracting to another **small business**, the 25% rule is waived

## Key Legal Frameworks

| Law | What It Requires |
|-----|-----------------|
| **Miller Act** | Performance & Payment Bonds on all federal jobs — guarantees project completion and payment to subs/suppliers even if Gunner goes bankrupt. Bonding capacity based on company financials. |
| **Buy American Act (BAA)** | >55% of total contract cost must be domestic materials. Procurement must obtain BAA Compliance Letters from manufacturers/suppliers. |
| **Davis-Bacon Act** | Prevailing Wage must be paid. Weekly certified payroll reports filed with the government. Gunner must audit subcontractor payroll weekly to confirm compliance. |
| **FAR 52.219-14** | Self-performance requirement — 25% of contract revenue must stay with the prime. |
| **OFCCP / EEO** | Contracts >$10k: Equal Opportunity laws apply (post openings to state agencies). Contracts >$50k: Affirmative Action — must maintain applicant tracking log (gender/race/veteran status) for every applicant, even those not hired. Failure to produce logs = breach of contract. |

## Workforce Access (Military Bases)

- Every worker (employee and subcontractor) needs a federal pass to enter a military base
- Requires background check — zero tolerance for outstanding warrants or felonies
- **Must pre-screen all crews weeks before a job starts** — cannot wait until job day

## Safety Requirements

Military safety standards exceed OSHA requirements:

- Example: OSHA may not require a railing on a house; military base may require full perimeter guardrail or 100% tie-off on flat roofs
- Superintendent or safety lead likely needs **OSHA 30** or **EM 385-1-1** training
- Daily safety logs required on all military sites

## IT / CMMC Action Items

| Item | Owner | Priority |
|------|-------|---------|
| [[vendors/bitdefender|Bitdefender GravityZone]] (antivirus) | Tyler | High — closes last major CMMC tech gap (~$1.1k/yr) |
| Visitor log process (front desk) | Tyler + Operations | Medium |
| PIEE / SAM.gov registration | [[entities/Eric Recchia|Eric Recchia]] | High — needed before any bid |
| SPRS self-assessment submission | Tyler + [[entities/Eric Recchia|Eric]] | High — after gap remediation |

## References

- [NIST SP 800-171Ar3](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-171Ar3.pdf)
- [FAR 52.219-14](https://www.acquisition.gov/far/52.219-14)
- [Miller Act (GSA)](https://www.gsa.gov/system/files/miller_brochure.pdf)
- [Davis-Bacon FAQ](https://www.dol.gov/agencies/whd/government-contracts/construction/faq/conformance)
