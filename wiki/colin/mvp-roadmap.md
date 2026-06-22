---
type: reference
owner: colin
app: GunnerCam
created: 2026-05-07
updated: 2026-06-21
tags: [wl-companycam, roadmap, mvp, poc]
status: active
---

# MVP Roadmap

Source: `~/repos/WL-CompanyCam/tickets/MVP_ROADMAP.md`. Strategy and gaps below are reconciled against `DECISIONS.md` and `QA-CHECKLIST.md` (the two authoritative audit sources, as of the 2026-06-04 code audit).

## Strategic direction — the late-May 2026 pivot

The 2026-05-29 standup locked the through-line (reaffirmed 2026-05-31 → 2026-06-10; key voice: Eric Recchia):

- Ship GunnerCam + the Quote/Leo portal **live as a Gunner-internal proof-of-concept first**, iron out kinks with the Gunner team, then offer the software as a **SaaS second**.
- All white-labeling scope is **explicitly deferred** to a future phase.
- **Tyler's iOS app is the field app.** The "make an app" line item is struck — field PMs operate from mobile. The GunnerCam **web** manager view serves almost exclusively Joe (and possibly Sarah), one ops user (confirmed by Eric Recchia). India owns Quote Portal items. See [[colin/external-api-integration]] and [[colin/people-and-context]].
- Direction (Eddie Prchal, 2026-06-10): strike the standalone GunnerCam manager web view and **fold it into the ops portal** as another screen (e.g. a daily job view drilled into from a project) — a fully separate web system is hard to justify for one ops user.
- Standup attendees on record (2026-06-01): Eric Recchia, Doug Kilzer, Colin Wong, Leonard Fuentes.

## Completeness assessment (as of 2026-06-15)

- App judged **~70% structurally complete but only ~40% product-shaped**: the DB and APIs are far more mature than the UX.
- Schema already includes phases, phase items, change orders, daily logs, site check-ins, invoice cache, and contract value — see [[colin/data-model]].
- Main gap is **making [[colin/my-day]] + Workflow the single obvious path** through the product, not adding features.

## "MVP done" (original definition) means a real user can:

1. Log in with username + password.
2. See their projects (admins: all in corp · standard: only assigned).
3. Open a project → details, address, customer, status, assigned people, photos, comments.
4. Upload photos (desktop or phone).
5. Post comments.
6. See an activity feed mixing photos and comments, reverse-chrono.
7. Admins manage users — invite, assign to projects, change role.

## Shipped features (as of 2026-06-04 code audit)

Confirmed present in the codebase. Catalog detail lives in [[colin/feature-inventory]]; deep notes linked inline.

- Payments tab — see [[colin/stripe-make]]
- Inbound Monday → PM job-sync with PM reassignment — see [[colin/monday-integration]]
- Typed tasks
- DocuSign signing (Change Order + Completion Certificate / COC templates)
- Daily logs; video/photo/dictation + comments; grid photos — see [[colin/photos-uploads]]
- Roles; offices; in-app notifications
- `job_id` ingestion: inbound sync stores `job_id` (e.g. `GUN-01623`) in `externalIds.job_id` but it is **not yet surfaced in the UI**.

## Not built / known gaps (as of 2026-06-04)

| Gap | State | Detail |
|---|---|---|
| **Task templates** | Deleted | Removed in commit `7059760`; absent from current code. Tables `task_templates` / `task_template_items` still exist but there is **no apply endpoint and no admin UI**. Files existed at `adcc39a` (restorable via git). |
| **CompanyCam historical import** | Draft / untracked | `scripts/sync-from-companycam.mts` + `tickets/TODO-companycam-sync.md` exist; on-demand only, no cron/Lambda. Needs token wiring, dry-run, labels/status + cron/backfill decisions, SST wiring. Scope (active + scheduled from Project Takeoff) decided at standup but not enforced in import logic. Requires a CompanyCam API token. See [[colin/masterdb-sync]]. |
| **COC-signed → Monday outbound** | Not built | Webhook handler does in-app/email only; no Monday dispatch. See [[colin/monday-integration]]. |
| **Project archiving / deletion** | Not built | `src/app/api/projects/[id]/route.ts` PATCH has no archive or soft-delete logic; `QA-CHECKLIST.md` marks it missing. Blocks PM cleanup. |
| **PWA mechanics** | Absent | `DECISIONS.md` commits to PWA-only for V1, but `src/app/layout.tsx` has only basic metadata — no manifest, service worker, offline mode, or device push. Camera upload exists in project detail. |

> **Stale-claim correction:** `DECISIONS.md` entry **T-12** describes task templates as built; they were deleted in `7059760`. The QA checklist correctly reflects the deletion.

**Remaining open items for Colin (2026-06-04):** (1) show/search job ID in UI, (2) task-template apply UI, (3) COC→Monday outbound, (4) CompanyCam import.

## Workflow / guided-tour scope

- Guided-tour workflow templates: **remove the Pre-install section** (covered by daily tasks/notes); retain three sections — **Project Start, In Progress, Close Out**.
- Canonical item list should match Eddie's Google Doc ("Guided Tour projects per day" sheet), not a loose Excel/text file.
- The **change-order guided tour is already done**; no further work needed.

## Deferred backlog (by phase)

The "don't add features the ticket didn't ask for" rule (DECISIONS) traces to the V2 backlog being defined upfront in the original design session.

- **V2 backlog (original design session):** voice notes UI, geofence auto-association, webhooks, full-text search, SOC 2.
- **Earlier V1-exclusion list (2026-05-27 ticket roadmap):** Offices · Crews · Managers · day-bucketed feed (`bucket_day`) · DMs · notifications · PandaDoc/DocuSign · Stripe payments · Quote Portal integration · Tyler's outbound API · marketing/showcase/review buttons · Files (non-photos) · voice notes · photo tags · Settings page · white-label theming · geofence/GPS · photo variants/thumbnails · soft-delete UI · advanced search · list filters. *(Some later shipped — Offices, Managers, Payments, DocuSign.)* The data model keeps `deleted_at`; the UI does not expose soft-delete.
- **Phase-2/3 deferral list (2026-06-08):** Quote Portal inbound webhook · Tyler's outbound REST API ([[colin/external-api-integration]]) · Stripe payments tab ([[colin/stripe-make]]) · PandaDoc/DocuSign for change orders · notification bell · direct messages · office sub-locations (Cromwell/NY/NJ) · manager-over-users hierarchy · settings/branding page · photo thumbnails. *(At that snapshot the `manager` role existed in the enum but had no `manager_assignments` table; managers saw the same data as admins.)*

## MVP UI trims (2026-05-27)

- Project Hub sidebar reduced to a single nav item (Projects only); Messages and Settings links removed from `sidebar.tsx`; topbar notification bell removed.
- Project detail tabs trimmed to three — **Activity, Photos, Files** — with Docs, Payments, Messages removed (~340 lines of FilesTab/DocsTab/PaymentsTab/MessagesTab deleted). Call/Email/Showcase/Review buttons, Star/More kebab, and "+ Label" cut from the header. Photos tab made default.
- System integration users (Stripe, PandaDoc, Quote Portal — `kind: 'system'`) removed from `seed.ts` with ~6 associated activity items. Remaining seed users are real humans: cwong, sgengo, jmassari, rbiberon, klovely, jprakash, zwebb, nalmeida, crew.

## Gotchas (testing / access)

Full list in [[colin/gotchas]].

- **QA toolbar** (role-preview "Preview as" — super_admin / manager / PM / restricted / crew — + date-override) is gated by `ENABLE_QA_TOOLS=true`, **NOT set** on deployed dev (`https://project.dev.gunnerroofing.com`, real Cognito auth). Role- and date-dependent tests run locally. Stripe tests prefer deployed dev (live SSM keys + Make scenarios).
- **Daily logs are PM-only**: a global `pm` role check blocks managers and super_admins even when assigned. No route test file exists for daily logs (one of four routes missing tests). The "complete" INSTALL badge isn't UI-testable because the daily-log modal does not collect `percentComplete` (by design — manager's call). Comment edit/delete exists in external v1 API but not the internal web UI.

## Open questions / TODOs

- **Offline mode strategy unresolved** (2026-06-03): recommended close is an ADR scoping offline to Tyler's native app, with GunnerCam limited to a banner + `modified_since` delta-sync (already shipped on 4 external routes — see [[colin/external-api-integration]]). **TODO: write the offline-mode ADR** — not yet written as of 2026-06-21.
- **Where predefined task sets live** (start-of-job / end-of-job templates) — GunnerCam, Leo portal, or a separate admin tool — unresolved as of 2026-05-29. Doug Kilzer wants a "task manager" that pushes task sets to Tyler's app and records yes/no answers or photos back to the GunnerCam UI; team open to manager-level batch task assignment inside GunnerCam as a short-term workaround.

## Original ticket sequence

| # | Title | Est | Notes |
|---|---|---|---|
| MVP-1 | Schema migration | ½ day | 4 new tables, drop 3 text cols, seed users |
| MVP-2 | Auth | 2–3 days | Username/password, signed cookie/JWT, middleware. No reset/2FA. |
| MVP-3 | Role-scoped projects list | ½ day | admin: all; standard: only assigned |
| MVP-4 | Project detail with tabs | 3–4 days | Activity / Photos / Comments. Flat list (no day buckets in MVP). |
| MVP-5 | Photo upload | 2–3 days | Presigned S3 PUT direct from browser; mobile camera capture |
| MVP-6 | Comments | 1 day | Composer on Comments tab; flows into activity feed |
| MVP-7 | Admin user management | 2 days | `/admin/users`, invite, assign, change role |
| MVP-8 | Visual pass to match Quote Portal | 2–3 days | Navy headers, pill buttons, sidebar nav |

**Total:** ~2.5–3 weeks focused, plan 4 weeks with debugging.

## Schema deltas (original MVP plan)

Repo already had `corporations`, `projects`, `project_labels`. The MVP plan added 4 tables and modified projects.

**Add:** `users`, `project_users`, `photos`, `comments`.
**Modify projects:** drop `pm_name`, `sales_name`, `crew_name` text columns (replaced by `project_users`); optionally add `primary_pm_id FK → users`.

Indexes: `users(corporation_id, role)` · `project_users(user_id)` · `photos(project_id, taken_at DESC)` · `comments(project_id, created_at DESC)`.

> Note: actual `src/db/schema.ts` has gone far beyond this — full crews, manager role, polymorphic creator, full updates feed, notifications, phases, change orders, daily logs, site check-ins, invoice cache, contract value. See [[colin/data-model]].
