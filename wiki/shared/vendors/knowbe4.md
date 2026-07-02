---
title: KnowBe4
type: vendor
tags: [knowbe4, security-awareness, phishing, training, vendor]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [KnowBe4 Proposal.pptx, Gunner IT Governance.xlsx, Tyler Suffern - Performance Review 2026.docx]
related: ["[[gunnerteam/environment]]", "[[concepts/cis-ig1]]", "[[ciso-track/roadmap]]"]
---

# KnowBe4

## What It Does

KnowBe4 is a Human Risk Management platform specializing in phishing simulation and security awareness training. It is the world's largest security awareness and simulated phishing platform (founded 2010).

## How It's Used at Gunner

Gunner uses a **phishing-simulation-only** implementation — not the full video training suite. This is a deliberate lean, high-impact approach.

| Feature | In Use |
|---------|--------|
| Email phishing simulations | Yes |
| Scheduled automated campaigns | Yes |
| Click tracking (who clicked, which depts) | Yes |
| Custom roofing-specific templates | Yes |
| Failed test coaching landing page | Yes |
| Full video training library | No |

## Contract Details

| Item | Value |
|------|-------|
| Users | 51 |
| Term | 3-year subscription |
| Total cost | $2,148.12 |
| Annual cost | $716.04/year |
| Pricing | End-of-year incentive pricing |

## Why KnowBe4 (vs. alternatives)

| Option | Reason Not Selected |
|--------|-------------------|
| GoPhish (open-source) | Free but requires significant IT resources to host and maintain; lacks template library and automation |
| Proofpoint | Enterprise-grade, expensive, requires outside contracting; many unneeded features (email protection suite) |
| **KnowBe4** | **Industry leader; 8,000+ templates; easy deploy; $5k/yr for full platform — chose phishing-only slice** |

## Implementation Details

- **Templates:** 8,000+ phishing email templates from real-world campaigns; customizable for roofing/construction scenarios
- **Scheduling:** Automated, recurring phishing campaigns
- **Tracking:** Click tracking identifies at-risk individuals and departments
- **Coaching:** Users who click a simulated phishing link see an immediate coaching page explaining what they fell for
- **User groups:** Mapped to Google Workspace OU structure for role-appropriate targeting (field crew vs. office staff)

## CIS Control Satisfied

- **CIS 14.1** — Establish and Maintain a Security Awareness Program: KnowBe4 simulations are the primary security awareness mechanism. Training completion reports should be exported quarterly to the SSP evidence folder.

## Phishing Alert Button (PAB)

The PAB is a KnowBe4 add-on installed in Gmail that lets users report suspicious emails with one click. It handles both real threats and KnowBe4 simulations (simulation reports trigger an immediate "Email Reported Successfully" coaching message).

**How to use the PAB:**

1. Open the suspicious email
2. Click the PAB:
   - **Desktop:** orange fish hook icon on the **right side panel** of Gmail
   - **Mobile:** grey fish hook icon at the **bottom of the email** (scroll down)
3. Confirm the report

A company-wide PAB reminder email was sent to all_gunner@gunnerroofing.com on 2025-12-03 from IT Support (it@gunnerroofing.com).

**Real phishing example on record:** Dec 9, 2025 — email from `quicktask8891@gmail.com` with subject "EMERGENCY; PROVIDE YOUR CELL PHONE NUMBER IMMEDIATELY" impersonating "[[entities/Eddie Prchal|Eddie Prchal]]". Flagged as spam. Classic CEO/executive impersonation. Signed/mailed by gmail.com (not gunnerroofing.com) — visible in Gmail header.

## Gunner-Specific Exposure Notes

- Non-technical field staff are a high-risk population — roofing-specific phishing templates (e.g., fake supplier invoices, insurance claim scams) are important
- Formal security awareness program ownership has not yet been documented — this is a gap vs. CIS 14.1 full compliance
- ROI framing from proposal: annual cost ($716) is negligible compared to cost of a single successful wire transfer fraud incident
