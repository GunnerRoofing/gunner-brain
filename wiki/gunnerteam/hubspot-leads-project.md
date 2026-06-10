---
title: HubSpot Lead Object Buildout
type: gunner
tags:
  - hubspot
  - leads
  - crm
  - sales
  - project
created: '2026-04-13'
updated: '2026-04-23'
status: in-progress
sources:
  - Hubspot_ Lead Object Buildout.xlsx
  - HubSpot Leads Project 4.13.26.md
  - HubSpot Leads Project 4.15.26.md
  - HubSpot Leads Project 4.16.26.md
  - HubSpot Lead Phases.md
related:
  - '"[[gunner/hubspot-sales-pipeline]]"'
  - '"[[gunner/app-inventory]]"'
  - '"[[vendors/google-workspace]]"'
  - '"[[gunner/lead-assignment-automation]]"'
  - '"[[vendors/dialpad-api-reference]]"'
  - '"[[vendors/monday-api-reference]]"'
  - '"[[gunner/hubspot-salesperson-sop]]"'
---

# HubSpot Lead Object Buildout

**Status:** In progress — sandbox buildout phase. Next step: demo with sales team.

**Owner:** Tyler Suffern (HubSpot buildout) + India (sandbox)

**Context:** HubSpot's native Lead object is being implemented to create a structured qualification layer between Contacts and Deals. Previously, reps went straight from contact to deal with no intermediate tracking. This adds accountability, proper routing, and speed-to-lead visibility.

---

## Object Hierarchy

```
Contact → Lead → Deal
```

A Lead is created when a Contact enters the sales process. A Deal is only created when the lead is qualified (real person, wants our product, has a price). Reps can create a deal from **any lead stage**.

---

## Project Go-Live Phases

*(Source: HubSpot Lead Phases.md, 2026-04-16)*

| Phase | Name | Status |
|-------|------|--------|
| 1 | Limited go-live | In progress — sandbox build |
| 2 | Round-robin assignment (AWS) | Scripts written — see [[gunner/lead-assignment-automation]] |
| 3 | Dialpad → Monday integration | Scripts written — see [[gunner/lead-assignment-automation]] |
| 4 | HubSpot cleanup | Deferred |

### Phase 1 — Limited Go-Live
- All contacts become leads, auto-assigned to sales team (no 5-min reassignment yet)
- New lead and deal pipeline stages live
- Daily report: lead assignment by rep + pipeline breakdown ("what you had, what you have")
- Workspace dashboards
- Create rep views
- Workflow: auto-task on leads/deals with no activity scheduled (pipeline hygiene)
- Sync marketing efforts to sales tasks

### Phase 2 — Round-Robin Assignment
- AWS Lambda + DynamoDB: hosts assignment scripts and Dialpad availability state
- Becomes WFM (Workforce Management) source of truth for rep availability
- Dialpad is source of truth — monitors when salespeople are on a call
- **Web leads excluded** from round-robin — they follow a separate auto-assign flow (workflow 7e)

### Phase 3 — Dialpad → Monday Integration
- All post-sale customer communication flows to the job's Monday project record
- **Covers:** Project Managers, **Sarah** (project coordinator), **Bryce** (accounts receivable), **Mike Ushka** (service manager)
- Implementation: `_system/lead-assignment/` — these staff need Dialpad user IDs added to `PMS_JSON` in `.env`

### Phase 4 — HubSpot Cleanup
- Delete unused reports, workflows, contact/deal/lead properties
- Automate sales commissions and update dashboards

---

## Conflicts Resolved (meeting notes win)

- Lead stage name: "In Communication / Qualifying Lead" (not "In Communication")
- Reassignment: 24-hour no-task rule (Excel) for the Lead object; 15-minute initial response (CRM rebuild) applies to lifecycle/lead status layer
- Deal creation: allowed from any lead stage, not gated to a specific stage

---

## Lead Stages

| Stage | Description |
|-------|-------------|
| Need to Make Contact | Default entry point — call-in and website leads |
| In Communication / Qualifying Lead | Active conversation; ~50% chance of deal |
| Not Ready | Real person, not buying now |
| Spam / Vendor / BS | Not a real lead — disqualified |
| Deal Created | Lead converted — deal exists |

**Lead visibility:** Reps only see their own leads.

---

## Deal Stages (with Weighted Averages)

| Stage | Probability |
|-------|-------------|
| Pitch Scheduled | 30% |
| Pitch Complete | 50% |
| Contract Sent | 70% |
| Contract Signed | 90% |
| Ready to Build | 100% |
| Closed Lost | 0% |

---

## Lead Source Flows

### Call-In (Human or Voicemail/Message)
1. Lead created at **Need to Make Contact** — rep fleshes out record with basic info + playbook
2. Rep moves to **In Communication / Qualifying Lead** → clicks **QP Button** → creates deal → fires Quote Portal

### Website (Form Fill / QP Link)
1. Lead created at **Need to Make Contact** via **Web Submission**
2. QP link already exists on the lead — moving to **In Communication / Qualifying Lead** → creates deal → **auto-copies QP data into deal**

> Key difference: website leads have QP data ready; call-in leads require rep to manually trigger QP.

---

## Lead Properties

| Property | Type | Notes |
|----------|------|-------|
| Project Type | Dropdown | Mirror from Deals |
| QP Link | URL | Show if exists |
| Number | Phone | |
| Email | Email | |
| Lead Source | Dropdown | Rename "Inbound Call Lead" → "Lead Source" on Contact and Deal objects |
| Activities | — | Auto-populated via Dialpad integration |

QP Button ("Send to QP") is a workflow trigger button — set up in Phase 6 workflows.

Address Validator and Playbooks — not needed for sandbox demo, deferred.

---

## Step-by-Step Sandbox Build

### Phase 1: Fresh Sandbox

1. In production HubSpot: Settings → Account Management → Sandboxes
2. If the old Rev Gravy sandbox is listed, delete it (out of sync, unused)
3. Create a new sandbox — name it "Gunner Dev"
4. Switch into the sandbox before any step below

---

### Phase 2: CRM Lifecycle Stages

This is the CRM rebuild base layer.

1. Settings → Properties → Contact Properties → search for "Lifecycle Stage"
2. Edit the property → Edit Options → set stages in this order:
   - Inbound
   - Lead
   - Not Qualified
   - Opportunity
   - Customer
   - Win Back
3. Delete or archive any default HubSpot stages that don't match (Subscriber, Marketing Qualified Lead, Sales Qualified Lead, Evangelist, Other)

**Lead Statuses** (sit inside the "Lead" lifecycle stage):
1. Settings → Properties → Contact Properties → search for "Lead Status"
2. Edit options → set:
   - New
   - Attempted to Contact
   - Connected
   - In Progress
   - Unqualified
3. Remove HubSpot defaults that don't apply

---

### Phase 3: Deal Pipeline + Stages

1. Settings → Objects → Deals → Pipelines
2. Edit (or create) your sales pipeline → rename if needed
3. Set stages in order with close probabilities (see Deal Stages table above)
4. Mark "Ready to Build" and "Closed Lost" as closed stages (one won, one lost)

---

### Phase 4: Lead Object + Stages

1. Settings → Objects → Leads — confirm the Lead object is enabled (newer HubSpot feature; may need to enable under beta/features)
2. Settings → Objects → Leads → Lead Stages → edit pipeline → set stages (see Lead Stages table above)
3. Confirm reps can create a deal from any lead stage (available via Lead record actions menu — test it)

---

### Phase 5: Lead Object Properties

1. Settings → Objects → Leads → Properties → create/confirm all properties in the Lead Properties table above exist
2. QP Button ("Send to QP"): workflow trigger button — set up in Phase 7
3. Address Validator and Playbooks — deferred

**Rename "Inbound Call Lead" → "Lead Source":**
- Settings → Properties → Contact Properties → find "Inbound Call Lead" → rename to "Lead Source"
- Repeat for Deal Properties

---

### Phase 6: Lead Visibility

1. Settings → Objects → Leads → check default record access setting
2. Set to Private by default or Owner only — reps see only leads assigned to them
3. Admins (Tyler, Glen) retain full visibility

---

### Phase 7: Workflows

Build in this order — properties and stages must exist first.

**7a — Copy Lead Details to Deal (on deal creation)**
1. Automation → Workflows → Create → Deal-based
2. Trigger: Deal is created AND associated Lead exists
3. Actions: Copy property values from associated Lead → Deal (Project Type, Lead Source, QP Link, contact info)

**7b — Round Robin Assignment**
1. Automation → Workflows → Create → Lead-based
2. Trigger: Lead is created **AND Lead Source ≠ Web Submission** (web leads are excluded — they auto-assign via 7e)
3. Action: Send Webhook → `_system/lead-assignment/` Lambda (handles Dialpad availability check, 5-min timer, location routing)
4. See [[gunner/lead-assignment-automation]] for full implementation — this is not a native HubSpot rotation

**7c — 24-Hour No-Task Reassignment**
1. Automation → Workflows → Create → Lead-based
2. Trigger: Lead is created OR lead stage changes to "Need to Make Contact"
3. Add delay: 24 hours
4. Condition: No open tasks associated with the lead AND lead is still active (not Spam / Not Ready / Deal Created)
5. Action: Rotate record to next owner in round robin sequence
6. Build reporting on reassigned leads (Phase 9)

**7d — QP Button**
1. Automation → Workflows → Create → Lead-based — name it "Send to QP"
2. Trigger: Manual enrollment (this becomes the button)
3. Actions: Create associated Deal → copy lead details to deal → fire Quote Portal link
4. Settings → Objects → Leads → Record Customization → add the workflow as an action button labeled "Send to QP"

**7e — Website Lead Web Submission**
1. Automation → Workflows → Create → Lead-based
2. Trigger: Lead created with source = Web Submission (form fill / QP link)
3. Action: Set lead stage to "Need to Make Contact" → populate QP Link field from form data
4. When rep moves to "In Communication / Qualifying Lead": auto-create deal and copy QP data → confirm this logic works in sandbox before going further

---

### Phase 8: Sales Workspace

1. Settings → Sales → Sales Workspace → enable it in sandbox
2. Remove "Companies" from the workspace view
3. Link the Sales MTD dashboard to the workspace
4. Test that each rep's workspace only shows their assigned leads

---

### Phase 9: Stale Deal Workflows + Reports

Build last — depends on deal stages being set.

**Report 1 — Stale Deal Report:**
1. Reports → Create Report → Deals
2. Filter: Last Activity Date > 120 days ago AND Deal Stage is NOT Closed Lost AND NOT Ready to Build
3. Group by: Owner
4. Columns: Deal Name, Stage, Last Activity Date, Close Date, Amount
5. Save → set up Google Sheets export (HubSpot → Google Sheets integration or manual)
6. Create a second version filtered to "within 120 days" (approaching stale)

**Report 2 — Closed Lost by Rep + 7-Day Activity:**
1. Reports → Create Report → Deals
2. Filter: Deal Stage = Closed Lost, Close Date = Last 7 days
3. Group by: Owner, Close Date
4. Add second dataset: Activities in last 7 days by owner
5. Save — Glen and third-party verifier use this for accountability

**Workflow — 14-Day Daily Call Task:**
1. Automation → Workflows → Create → Deal-based
2. Trigger: Deal has no activity for 120 days AND Deal Stage is NOT Closed Lost AND NOT Ready to Build
3. Action: Create task for deal owner → "Call/Text/Email [Contact Name]" → due today
4. Add delay: 1 business day → re-enroll if still no activity
5. Run for 14 days maximum (add counter property or use enrollment limit)
6. Business days only: use HubSpot's business hours filter on the delay step

---

## Sandbox Test Checklist Before Demo

- [ ] Create a test lead via form fill → confirm web submission flow (auto-assign, QP link present, stage = Need to Make Contact)
- [ ] Create a test lead via manual entry → confirm call-in flow (QP button fires correctly, creates deal)
- [ ] Move lead through all stages → confirm "Deal Created" stage and deal association work
- [ ] Verify rep cannot see other reps' leads
- [ ] Trigger 24-hour reassignment (set delay to 5 min for testing, reset to 24hr after)
- [ ] Confirm deal stages show correct probabilities
- [ ] Confirm deal creation works from Need to Make Contact, In Communication, and Not Ready stages
- [ ] Run stale deal report → verify excluded stages work correctly

---

## Known Problems / Open Issues

*(Captured 2026-04-15)*

| Problem | Notes |
|---------|-------|
| Round robin — location and/or "busy" | **Being addressed in Phase 2** — see [[gunner/lead-assignment-automation]] |
| Address validator clunkiness | Deferred from sandbox; revisit before prod launch |
| Lead type — Pipeline Automation creates lead automatically | Verify this doesn't conflict with manual lead creation flows |
| Workflows need cleanup and sorting | Accumulating fast; organize before prod |
| Lead label | Not yet defined |
| Create views | Rep views not built yet |
| Lead card can't be updated | HubSpot limitation — investigate workaround |
| Lead + deal reassignment | Reassignment logic needs to apply to both objects |
| Impact of lead launch on existing workflows | Audit existing workflows before go-live to prevent conflicts |
| Playbooks up to date | Verify playbooks reflect new lead stages before demo |

---

## Reassignment Timing (Resolved — 2026-04-15)

Two separate windows confirmed:

| Window | Trigger | Mechanism |
|--------|---------|-----------|
| **5 minutes** | No outbound call to customer after assignment | AWS Lambda (`_system/lead-assignment/`) — not a HubSpot workflow |
| **24 hours** | No task scheduled on the lead | HubSpot workflow 7c |

The 5-min window is the speed-to-lead check. The Lambda queries Dialpad call history to verify the rep actually called. If not, the lead is reassigned to the next available rep and the 5-min clock restarts. See [[gunner/lead-assignment-automation]].

---

## Dialpad → Monday Integration (Phase 3)

All post-sale customer communication via Dialpad is logged to the Monday project record for the job.

**Who is covered** (add all to `PMS_JSON` in `_system/lead-assignment/.env`):
- Project Managers
- **Sarah** — project coordinator
- **Bryce** — accounts receivable
- **Mike Ushka** — service manager

How it works: when any of these staff make/receive a Dialpad call or SMS to a known job contact number, the `dialpadEvents` Lambda posts a formatted update to the Monday item. See [[gunner/lead-assignment-automation]] for setup.

---

## Make.com — Lead Activity to Deal Workflow

*(Scoping started 2026-04-15)*

Goal: Move lead activity (calls, texts) to the associated deal so the deal timeline stays current.

Key consideration: Check whether the "Add Timeline Activity" checkbox is exposed when a deal is created — if so, use it to avoid logging duplicates on both the lead and the deal.

This overlaps with the Dialpad → HubSpot direct integration being scoped (replacing the unreliable native Dialpad integration).

---

## Open Questions (2026-04-16)

- **Lead tags** — is it useful to tag leads by source (e.g. Inbound Call, Web Estimator, Referral) for reporting? Decision needed before workflows are finalized.
- **Lead type / Lead label** — HubSpot has both fields; use case not yet defined. Decide whether these map to lead source, job type, or something else.
- **Task creation** — should tasks be created automatically on lead assignment? Or manually by the rep? Confirm with Glen/India.
- **Web estimator leads** — confirmed they create a Lead (not a Deal) at "Need to Make Contact." Verify the web estimator integration sends `lead_source = Web Submission` so workflow 7e triggers correctly.

---

## Deferred (Not Building Yet)

- Dialpad → HubSpot direct integration (replacing native; Make.com webhook approach being scoped)
- Address Validator
- Playbooks
- State-based round robin with Google Calendar away status
- Training materials
- Doug sync of marketing efforts to lead/deal objects
- Website self-serve flow (no rep contact → create deal, assign to Glen, no commission)

---

## Related

- [[gunner/hubspot-salesperson-sop]] — Sales Workspace SOP for salesperson day-to-day use (IT-SOP-HUB-002)
- [[gunner/hubspot-workflow-designs]] — detailed workflow designs for lead assignment and hygiene
- [[vendors/hubspot]] — HubSpot vendor page
