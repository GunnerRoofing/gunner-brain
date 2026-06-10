---
title: HubSpot Workflow Designs — Lead Assignment & Activity Hygiene
type: gunner
tags:
  - hubspot
  - workflows
  - leads
  - crm
  - automation
created: '2026-04-20'
updated: '2026-04-23'
status: developing
sources: []
related:
  - "[[gunner/hubspot-leads-project]]"
  - "[[gunner/lead-assignment-automation]]"
  - "[[gunner/hubspot-sales-pipeline]]"
  - "[[vendors/hubspot]]"
  - "[[gunner/hubspot-salesperson-sop]]"
---

# HubSpot Workflow Designs — Lead Assignment & Activity Hygiene

Detailed workflow designs built during the Phase 1 HubSpot Leads buildout. These are distinct from the Lambda/DynamoDB round-robin assignment (Phase 2) documented in [[gunner/lead-assignment-automation]].

---

## Workflow A — Rotate Lead If No Owner

**Object:** Leads  
**Purpose:** Auto-assign unassigned leads after a 5-minute window for reps to self-claim.

### Design

```
Enrollment trigger:
  - Lead stage is any of: Need to Make Contact (Lead pipeline)
  - AND Lead Owner is unknown
  - Re-enrollment: OFF

1. Delay — 5 minutes
   (reps can self-assign during this window)

2. Branch: Lead Owner is still unknown?
   YES → 3. Rotate record to owner (within 1 team)
   NO  → End (rep self-assigned)
```

### Key Notes

- **Enrollment filter** does the initial unknown check; the branch re-checks after the delay in case a rep grabbed it.
- The rotation step sets Lead Owner via HubSpot's built-in owner field.
- No "overwrite if already has owner" — redundant given the filters.
- Step 3 (Edit Record to sync Contact Owner) was removed; Owner Sync workflow handles that.
- **Do not** add a step to copy Lead Owner to Contact Owner here — see Workflow B.

---

## Workflow B — Owner Sync (Lead Owner → Contact Owner)

**Object:** Leads  
**Purpose:** Mirror Lead Owner to Contact Owner on the associated Primary contact whenever Lead Owner changes.

### Design

```
Enrollment trigger:
  - Property: Lead Owner changed
  - New value: Lead Owner is known
  - Re-enrollment: ON (every time it changes)

1. Edit record
   - Record type: Contact (Associated object)
   - Association label: Primary
   - Property: Contact owner
   - Change type: Replace
   - Value: Lead Owner (token from enrolled lead)
```

### Known Limitation

Property changes made **by another HubSpot workflow** (e.g., the rotation in Workflow A) may not reliably fire a "property changed" trigger in a second workflow. This was observed in testing — Workflow A rotated the lead but Workflow B did not trigger.

**Fallback:** If Owner Sync proves unreliable, move the Edit Record step back into Workflow A (use the "owner ID of the assigned owner" output token from the rotate step, not the Lead Owner property).

### Bidirectional Sync Risk

A Contact Owner → Lead Owner sync in the opposite direction would create an infinite loop (A changes B triggers C changes A...). This bidirectional problem is deferred to the Lambda layer, which can set both fields in a single API call with no trigger chain.

---

## Workflow C — No Activity Alert (Leads)

**Object:** Leads  
**Purpose:** Create a call task when a lead has had no activity for over 24 hours, as a hygiene reminder for reps.

### Design

```
Enrollment trigger:
  - Last activity date is more than 1 day ago (EDT)
  - AND Lead stage is any of:
      Need to Make Contact (Lead pipeline)
      Qualifying Lead (Lead pipeline)
      In Communication (Lead pipeline)
  - Re-enrollment: ON

1. Create task
   - Title: "No Activity — Please Engage ([Lead Name])"
   - Type: Call
   - Due: Today
   - Assign to: Lead Owner
```

### Design Decisions

- **Last activity date** (not Next activity date) is used as the trigger — it staggers task creation naturally across reps rather than creating a pile of tasks simultaneously.
- **Next activity date** (populated by open tasks) was considered but has an edge case: overdue tasks may clear it, causing false triggers.
- There is no HubSpot filter for "number of open tasks" or "has open task" on the Lead object. The overdue task edge case is accepted — reps are trained to complete or reschedule overdue tasks same day.

---

## Workflow D — No Activity Alert (Deals)

**Object:** Deals  
**Purpose:** Same hygiene logic as Workflow C, applied to active deals.

### Design

```
Enrollment trigger:
  - Last activity date is more than 1 day ago (EDT)
  - AND Deal stage is any of:
      Pitch Scheduled
      Pitch Complete
      Expecting to Close  ← (formerly "Contract Sent" — renamed 2026-04-20)
  - Re-enrollment: ON

1. Create task
   - Title: "No Activity — Please Engage ([Deal Name])"
   - Type: Call
   - Due: Today
   - Assign to: Deal Owner
```

---

## HubSpot Workflow Quirks (Discovered in Testing)

| Quirk | Detail |
|-------|--------|
| Rotation token | After a rotate step, use **"owner ID of the assigned owner" from step N** — not a Lead Owner property. The property may be empty at time of action. |
| Workflow-to-workflow triggers | Property changes made by a workflow action may not fire "property changed" triggers in a separate workflow. Verify in testing. |
| Next activity date | Populated by any open task. Overdue tasks may clear this field — treat as an accepted gap. |
| No task count filter | HubSpot Lead object workflows have no "number of open tasks" or "has open task" filter available. |

---

## Pipeline Stage Reference

**Lead Pipeline (as of 2026-04-20)**

- Need to Make Contact
- Qualifying Lead
- In Communication
- Closed Won / Closed Lost

**Deal Pipeline (as of 2026-04-20)**

- Pitch Scheduled
- Pitch Complete
- Expecting to Close *(formerly Contract Sent)*
- Closed Won / Closed Lost

---

## Related

- [[gunner/hubspot-salesperson-sop]] — Sales Workspace SOP; these workflows surface as automated tasks seen by reps
- [[gunner/hubspot-leads-project]] — Lead object buildout context
- [[vendors/hubspot]] — HubSpot vendor page
