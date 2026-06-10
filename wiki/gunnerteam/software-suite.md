---
title: Gunner Software Suite
type: gunner
tags:
  - software-suite
  - white-label
  - saas
  - roadmap
  - quote-portal
  - ops-portal
  - companycam
  - fleet
created: 2026-05-13T00:00:00.000Z
updated: 2026-05-13T00:00:00.000Z
sources:
  - white label agenda.xlsx
related:
  - '[[gunner/gunner-forms-app]]'
  - '[[vendors/companycam]]'
  - '[[gunner/gunnerteam-api-aws-migration]]'
  - '[[summaries/white-label-agenda]]'
status: developing
---

# Gunner Software Suite

Gunner is building a white-label SaaS roofing operations platform. The suite consists of 8 interconnected platforms. Gunner uses them internally and licenses them to roofing company partners. The 60-day horizon defines "Urgent" features; everything else is "Future."

---

## Platform Overview

| Platform | Alias | Owner | Role |
|----------|-------|-------|------|
| Quote Portal | QP | Ruchir | Quoting, pricing, proposal generation, partner onboarding |
| Ops Portal | LeoPortal | Leo | Job scheduling, PM/crew assignment, project timeline |
| GunnerCam | ColinCam | Colin | Field photos, e-signatures, daily logs, customer-facing job updates |
| Sub Portal | — | — | Subcontractor visibility, profile, insurance, reviews |
| Marketing Portal | — | — | UTM generator, emailer, user feature management |
| Customer App | — | — | Pizza tracker, invoice payments, push notifications, project updates |
| Global User Table | — | — | Shared user identity across all platforms |
| Fleet Management | — | Tyler | Vehicle inspections, maintenance, scheduling (currently in Gunner Team iOS) |

---

## Systems of Truth

- **QP** — supplier pricing, materials, labor rates
- **Ops Portal** — job scheduling, material ordering, PM and crew assignment, job completion
- **GunnerCam** — job updates, photos, e-signatures (COC & CO)

---

## Platform Details

### Quote Portal (QP)

**Urgent:**
- Handoff to Ops Portal (contract, pictures, materials)
- Pipeline view
- Edit contact person / details
- Create / onboard a company (white label)
- Global user creation
- Mobile friendly
- AI chatbot
- Create a new project
- Google address validator
- Ability to add different products
- Repair button

**Future:**
- Mobile app + ability to take pictures
- Forecasting
- Supplier pricing integration
- CRM functions (tasks, reminders, "my day" view)

---

### Ops Portal (LeoPortal)

**Urgent:**
- Needs to exist (greenfield build)
- Excel/Monday-like view with groups
- Role permissions: Company Admin, Permitting, Procurement, Dispatch, Service Manager
- Pizza ticker stages: New Project → Permitting/Procurement → Scheduling → Active → Complete
- Drill into project — all details + timeline view
- File upload
- Edit contact person / details
- Crew selection and PM selection
- Deep link back to QP
- Get company from QP
- Subcontractors tab: find a sub, active subs, deactivated subs
- Fleet management
- User feature management
- Calendar view
- Job Type = Service Request
- Stripe integration

**Future:**
- Role notification preferences
- Phone call recording
- Sub portal in Ops Portal
- GunnerCam in Ops Portal
- Gantt availability
- Resource allocation
- Forecasting

---

### GunnerCam (ColinCam)

**Urgent:**
- Job created at "Scheduling" stage (triggered from Ops Portal)
- Pulls in sales photos, contract, permit, etc.
- Role permissions: Company Admin, Manager (assign users to manager), User (PM)
- Deep link back to Ops Portal / QP
- Stripe invoices (open and paid) — ability to send invoices
- Daily logs
- E-signatures for COC & CO
- COC signed = Ops Portal Complete
- CO triggers Stripe invoice to be paid
- Get company from Ops Portal
- User feature management
- Dictation
- Videos (+ video compression and time limit)
- Comment on a picture
- Send to customer
- Send to marketing
- Sub reviews 1–5 stars
- Make an app

**Future:**
- Phone call recording
- Offline mode
- Android
- Pictures/videos show uploaded by crew

---

### Sub Portal

**Urgent:**
- Assigned via Ops Portal → gives sub visibility
- Sign up / create or edit profile
- Add sub: upload insurance/license, about us, expertise, total crew members, states/footprint
- Reviews
- Limit contact details, comms through the app to a point

**Future:**
- How the sub will be paid
- Automate sub payments
- Make an app
- English / Spanish

---

### Marketing Portal

**Urgent:**
- UTM generator
- Emailer
- User feature management

---

### Customer App

**Urgent:**
- Pizza tracker
- Pay invoices
- Push notifications (marketing, invoices, project updates)
- Some shared images

---

### Fleet Management

**Urgent:**
- Build it out (currently exists in Gunner Team iOS as vehicle inspections + maintenance)
- Add to Ops Portal (future integration point)

---

## White-Label Architecture

Partners get a fully branded experience under their own domain:

| Surface | URL Pattern | Purpose |
|---------|------------|---------|
| Embed script | `gunnertech.com/form-script.js?color1=...&partner=123&redirectUrl=...` | Quote form rendered on partner's website |
| Customer quote site | `quotes.partnerURL.com` | Branded asphalt GBB or other product quote flow |
| Quote request form | `quotes.partnerURL.com/request-quote` | Inbound lead form |
| QP access | `qp.partnerURL.com` | Partner's QP instance |

**Cross-platform nav:** Google-apps-style icon strip on right side of every platform for jumping between QP, Ops Portal, GunnerCam, etc.

---

## Partner Onboarding Flow

1. Partner fills out Google onboarding form (company info, existing proposal copy)
2. Onboarding call
3. Create company in QP (sets up branding, user access, billing tier, domain)
4. Legal agreement signed offline via DocuSign
5. Gunner manages user on/offboarding until SSO is ready

**Billing:** Tiered by number of jobs. Company Admin role manages their own users/settings/billing after onboarding.

---

## Open Items

- All-in cost per partner (AWS, Hover/GAFQM, DocuSign, etc.) — TBD
- HubSpot integration — TBD
- Customer support tooling (short term: Monday board)
- SSO for partners — prerequisite for self-serve user management
- `Gunner_Technology_Roadmap_2026.xlsx` — additional detail referenced but not yet ingested
- `Revenue & Pipeline Dashboard` — referenced but not yet ingested
