---
type: concept
owner: leo
created: 2026-05-19
updated: 2026-06-19
tags: [gunner-ops, lifecycle, concept, ops]
status: active
---

# Ops Job Lifecycle

The pipeline every job in gunner-ops moves through. `stage` is the single most important field on a job — it gates which forms are shown, which roles are notified, and what actions are available.

Deep app reference: [[leo/apps/gunner-ops]]. Overview: [[leo/overview]].

## Stage Order (current "pizza-ticker" model)

User-facing pizza-ticker labels map to internal stage keys:

```
New Project → Permitting/Procurement → Scheduling → Active → Complete
(overview    → job_prep              → schedule    → in_progress → closeout)
```

Canonical stage list lives in `frontend/stages.js`. `closeout` / Complete is the **terminal** stage — jobs do not advance past it. Admins can click back to any past stage to view its snapshot (read-only retreat navigation).

There is an Excel/Monday-style **board view** (`/board`) grouped by stage, plus a project drill-in + Timeline panel on JobDetail.

## Stage Forms and Advance Conditions

| Stage | Form | Required to Advance |
|-------|------|---------------------|
| `overview` | OverviewForm | `customer_contacted` + `contract_start_date` |
| `job_prep` | JobPrepForm | Materials tracked, permit handled, special orders |
| `schedule` | ScheduleForm | `scheduled_date` + `crew` + `material_delivery_date` |
| `in_progress` | InspectionForm | `inspection_passed`; Start Job records `started_at` |
| `closeout` | CloseoutForm | Terminal — 7-item checklist + `sub_payout_rate` |

> **Gap:** the CloseoutForm checklist is currently frontend-only state — not persisted to the DB.

## Who Can Advance Each Stage

| Stage | Roles That Can Advance |
|-------|------------------------|
| `overview` | admin, billing |
| `job_prep` | admin, permitting, dispatch |
| `schedule` | admin, dispatch |
| `in_progress` | admin, service_manager |
| `closeout` | terminal — no advance |

Role system detail: [[leo/apps/gunner-ops]].

## Two Advance Paths

**Automatic (`advance_if_ready`):** Called after every PATCH to jobs, invoices, permits, or materials. Silently advances if conditions are met. Loops until no more advances are possible in a single call. No stage snapshot written.

**Explicit (`POST /api/jobs/{id}/advance`):** User-initiated. Validates required fields for the current stage. Writes a `stage_data` snapshot before advancing. Fires `notify_next` after the advance.

## Stage Snapshots (`stage_data`)

On every explicit advance, a snapshot is written to `job.stage_data[current_stage]` — a JSON audit trail of job state at each stage gate. Contains job + invoice fields at the time of advance. Not written on auto-advances.

```json
{
  "overview": { "stage": "overview", "amount": 12000.0, "customer_contacted": true, ... },
  "schedule": { "stage": "schedule", "scheduled_date": "2026-06-01", "crew_id": "...", ... }
}
```

`stage_data` is currently JSON; converting to JSONB + GIN index is on the backlog.

## Notification Routing

On explicit advance, `notify_next` (in `notify.py`) writes `ops_notifications` records for users in the target stage's role. In-app only (`GET /api/notifications/me`) — no email/SMS.

| Stage Entered | Roles Notified |
|---------------|----------------|
| `schedule` | dispatch |
| `job_prep` | permitting, dispatch |
| `in_progress` | service_manager |
| `closeout` | admin |

## Commit Pattern (Critical — DEC-006)

`advance_if_ready` and `advance` (in `lifecycle.py`) mutate `job.stage` **in memory only**. Callers must commit. Never commit inside either advance function.

```python
# CORRECT
advance_if_ready(job, db)
db.commit()
db.refresh(job)

# BUG — currently in permits.py: commit fires BEFORE the advance,
# so the stage advance lands in a separate implicit commit, not atomically.
db.commit()
advance_if_ready(job, db)
```

Fix for `permits.py`: swap the order so `db.commit()` runs after `advance_if_ready()`.

## RLS Interaction (reusable gotcha)

Because routes commit mid-request and `SET LOCAL app.current_org_id` resets on commit, RLS would hide all rows after a lifecycle commit. The fix re-applies the org via an `after_begin` session listener + `db.expunge(user)`. See the gotcha detail in [[leo/apps/gunner-ops]] and [[leo/apps/masterdb-integration]].

## Required Fields per Stage

`STAGE_REQUIRED` in `jobs.py` enforces field presence at explicit-advance time. Stages without entries rely on `advance_if_ready` conditions checked lazily.

## Legacy note (pre-cutover 7-stage model)

Before the masterdb cutover, the lifecycle was a 7-stage pipeline (`invoice → project → scheduling → procurement_permitting → job_prep → in_progress → complete`) with `project` as an auto-advance intermediate. That model has been collapsed into the current 5-stage pizza-ticker flow above. Mentioned only for context when reading older code/snapshots.
