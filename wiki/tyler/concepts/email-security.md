---
title: Email Security (DMARC / SPF / DKIM / MTA-STS / BIMI)
type: concept
tags: [email-security, dmarc, spf, dkim, mta-sts, bimi, phishing]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [Gunner IT Governance.xlsx, System Security Plan.docx, IT_Tasks_1775773048.xlsx]
related: ["[[vendors/google-workspace]]", "[[threats/t1566-phishing]]", "[[vendors/knowbe4]]", "[[concepts/mfa]]"]
---

# Email Security

## Stack Deployed on gunnerroofing.com

| Component | Status | Purpose |
|-----------|--------|---------|
| SPF | Active | Authorizes which mail servers can send as gunnerroofing.com |
| DKIM | Active | Cryptographic signature proving email authenticity |
| DMARC | **p=reject** (since 2026-02-03) | Instructs receivers to reject emails failing SPF/DKIM alignment |
| MTA-STS | Enforce mode | Forces TLS on inbound SMTP — prevents downgrade attacks |
| BIMI | Active | Displays Gunner Roofing logo in supporting mail clients (requires DMARC enforcement) |

## DMARC Migration History

| Phase | Policy | Notes |
|-------|--------|-------|
| Initial | `p=none` | Monitor only — no enforcement |
| Intermediate | `p=quarantine` | Suspicious mail sent to spam |
| 2026-02-03 | `p=reject` | Full enforcement — spoofed mail rejected at receiver |

SPF and DKIM were fully verified before `p=reject` was activated.

**Reporting:** Cloudflare + vali.email for DMARC aggregate report monitoring.

## Threat Coverage

This stack directly addresses [[threats/t1566-phishing]] via domain spoofing:

- A threat actor **cannot** send email appearing to come from @gunnerroofing.com to external recipients — DMARC p=reject causes receivers to reject it
- Does **not** prevent phishing emails sent from other domains targeting Gunner employees
- Inbound phishing from external domains is addressed by Chrome Safe Browsing (Enhanced) + [[vendors/knowbe4]] training

## SendGrid

Transactional email for Gunner is managed via SendGrid. Access obtained through Becky's account.

> **Security flag (open):** SendGrid backup code found in OneNote (page 107). Should be moved to Keeper and removed from OneNote.

## Completed Work

DMARC, SPF, DKIM implementation was completed in December 2025 (first task: Dec 3, 2025). DMARC migration to p=reject completed 2026-02-03. Listed as practical experience in [[ciso-track/roadmap]].

## Related

- [[vendors/google-workspace]] — DMARC migration history, MTA-STS enforce, BIMI, delegated admin details
- [[threats/t1566-phishing]] — phishing threat; email security is the primary technical domain control
- [[vendors/knowbe4]] — phishing simulation and user awareness training
