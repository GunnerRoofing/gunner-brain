---
title: HubSpot Sales Pipeline — Stale Deal Management
type: gunner
tags: [hubspot, sales, pipeline, workflows, reporting]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [My Notebook @ Gunner Roofing.pdf]
related: ["[[vendors/hubspot]]", "[[gunner/environment]]"]
---

# HubSpot Sales Pipeline — Stale Deal Management

**Context:** Glen tracks sales activity. A third party verifies via report. This initiative was scoped out on 2026-03-31 to address deals with no activity and reps who need task-level accountability.

**Exclusions:** Closed-lost deals and "Ready to Build" deals are excluded from all workflows and reports below.

---

## 1. STALE DEAL REPORT

**Purpose:** Identify deals with no activity for reassignment to active reps.

- Export to Google Sheets by rep
- Two sub-reports:
  - Deals with **no activity within 120 days** (still in pipeline, going stale)
  - Deals with **no activity more than 120 days** (effectively dead, candidate for reassignment)
- Shows how busy each rep is alongside their stale deal count
- Trigger: Run this first (Step 1) before doing anything else — it drives the reassignment process

**Timeline:** 14 days to work the 120-day list, then 14 days after the 120-day mark to follow up on any remaining

## 2. DAILY CALL WORKFLOW

**Purpose:** Ensure every stale deal gets a call attempt over a 14-day window.

- Assign a task to the deal owner **every day for 14 days** to call any deal that is not closed-lost
- If there is **no task already assigned** to the deal, include it in a daily **call/text/email workflow**
- Workflow should run on **business days only**

## 3. CLOSED-LOST ACTIVITY REPORT

**Purpose:** Monitor rep accountability and activity volume.

- Shows **closed-lost deals by rep per day**
- Shows **activities over the last 7 days** per rep
- Used by Glen / third-party verifier to confirm reps are working leads

---

## 4. CRM LIFECYCLE STAGES

Gunner's HubSpot CRM restructuring (scoped early 2026) standardizes contact lifecycle and lead status tracking.

### Lifecycle Stage Flow

```
Inbound → Lead → Not Qualified → Opportunity → Customer → Win Back
```

| Stage | Description |
|-------|-------------|
| Inbound | Raw contact, not yet reviewed |
| Lead | Reviewed, worth pursuing |
| Not Qualified | Reviewed, not a fit at this time |
| Opportunity | Active deal in pipeline |
| Customer | Closed/won |
| Win Back | Past customer targeted for re-engagement |

### Lead Statuses

Used within the **Lead** lifecycle stage to track rep activity:

- New
- Attempted to Contact
- Connected
- In Progress
- Unqualified

### Assignment Rules

- **Round robin** distribution for inbound leads across active reps
- **15-minute reassignment timer:** if a rep does not action a new lead within 15 minutes, the lead is reassigned to the next rep in rotation
- Closed-lost and "Ready to Build" deals are **excluded** from all automated workflows

### HubSpot SOPs Reference

Scribehow walkthrough for Gunner HubSpot SOPs exists (Scribehow link saved separately by Tyler).

---

## OPEN ITEMS

- [ ] Build stale deal report in HubSpot → export to Google Sheets
- [ ] Create 14-day daily call workflow (business days only, exclude closed-lost and ready-to-build)
- [ ] Build closed-lost by rep + 7-day activity report
- [ ] Confirm with Glen which third-party verifier is reviewing reports
