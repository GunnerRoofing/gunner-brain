---
title: White Label Agenda
type: summary
tags:
  - software-suite
  - white-label
  - saas
  - roadmap
  - companycam
  - ops-portal
  - quote-portal
created: 2026-05-13T00:00:00.000Z
updated: 2026-05-13T00:00:00.000Z
sources:
  - white label agenda.xlsx
related:
  - '[[gunnerteam/software-suite]]'
  - '[[vendors/companycam]]'
  - '[[gunnerteam/gunner-forms-app]]'
status: evergreen
---

# White Label Agenda

Source: `raw-sources/white label agenda.xlsx` — two sheets: partner Q&A (Ruchir) and software feature matrix.

Full synthesis at [[gunnerteam/software-suite]].

## Sheet 1 — Partner Onboarding Q&A

| Question | Answer |
|----------|--------|
| Onboarding a partner | Google form → company info collected → onboarding call |
| Create company screen | Done in QP — add/delete/disable partners, user management, settings, billing |
| Legal agreement | Offline via DocuSign |
| Billing model | Tiered by number of jobs |
| Admin role | New "Company Admin" role manages company's users, settings, billing |
| Job title editable | Yes — e.g. "Remodeling Specialist" updates on website UI plugin |
| Quote send modes | Manual, send right away, delayed send |
| Notifications (non-HubSpot) | Via email, configurable per user settings |
| Quote Portal on mobile | Needs optimization — app is future state |
| Sub app review | Done in GunnerCam |
| Reporting | Sales reporting + Ops reporting dashboards |
| Service requests | Form → Ops Portal as service request; Service Manager sees Ops Board as service requests only |
| Proposal/template | Collect existing proposal via onboarding form; assist in creating; use QP project type templates |
| All-in cost | TBD (AWS, Hover/GAFQM, DocuSign envelopes, etc.) |
| Customer support | Short term = Monday board |
| HubSpot integration | TBD |

## Sheet 2 — Software Feature Matrix (60-day = Urgent)

See [[gunnerteam/software-suite]] for full structured breakdown.

**Systems of Truth:**
- QP = supplier pricing, materials, labor rates
- Ops Portal = job scheduling, material ordering, PM/crew assignment, job completion
- GunnerCam = job updates, photos, e-signatures

**White-label web architecture:**
- Embed script: `gunnertech.com/form-script.js?color1=...&color2=...&partner=123&redirectUrl=...`
- Customer-facing quote site: `quotes.partnerURL.com` (asphalt GBB or other products)
- Quote request form: `quotes.partnerURL.com/request-quote`
- QP functions: `qp.partnerURL.com`

**Cross-platform navigation:** Google-apps-style icon strip on right side of all platforms for jumping between QP, Ops Portal, GunnerCam, etc.

**Project notes:**
- Gunner to manage all company users (on/off board) until SSO is ready
- References: `Gunner_Technology_Roadmap_2026.xlsx`, `Revenue & Pipeline Dashboard`
