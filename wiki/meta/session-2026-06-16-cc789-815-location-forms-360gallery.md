---
type: session
title: 'cc-789–815: always-on location, Monday forms, 360 gallery'
created: '2026-06-16'
updated: '2026-06-16'
tags:
  - session
  - ios
  - backend
  - location
  - geofence
  - monday-forms
  - 360-camera
  - gallery
status: complete
---

# Session: cc-789–815 — always-on location, Monday forms, 360 gallery

**Date:** 2026-06-16  
**Lambda at end:** v249 (`live`)  
**iOS:** BUILD SUCCEEDED, all cc-789–815 committed to `main`  
**omp:** updated 15.11.8 → 16.0.5 (restart required)

---

## Backend deploys

| Version | Change |
|---|---|
| v238 | `gt_location_history` table + `PATCH /time/location` breadcrumb write + `GET /time/fleet-locations` (admin/manager, 24h) |
| v239–v244 | Iterative schema-cast fixes on the time routes (see "Schema gotchas" below) |
| v245 | `GET /time/location-history` (breadcrumb trail, Colin contract) + `20260616_location_history_retention` (90-day prune) |
| v246 | `POST /submit-dumpster` (Site Manager Forms board) |
| v247 | `POST /submit-material` (4 branches) + material file-upload columns |
| v248/v249 | `POST /jobs/:id/photos/confirm` (gallery register + tag passthrough) |

### Always-on location (cc-789, 790, 791)
- **`gt_location_history`** — append-only breadcrumb table `(id, org_id, user_id, lat, lng, accuracy_m, recorded_at)`, descending index. The single source for both latest-position and trail.
- **`PATCH /time/location`** writes a breadcrumb on every heartbeat regardless of check-in (proxy-safe `query()`, no `SET LOCAL`).
- **`GET /time/fleet-locations`** — latest position per user within 24h; admin/manager only; `checked_in` flag; `display_name` from `users.first_name`/`last_name`.
- **`GET /time/location-history?userId&from&to`** — ordered breadcrumb trail, admin/manager only, org-verified `userId`, ≤31-day window, 10k cap, audited (`fleet.location_history.viewed`).
- **Retention:** 90-day prune migration; needs a recurring EventBridge schedule for ongoing enforcement (deploy-time prune only for now).
- iOS (cc-790): always-on heartbeat when `authorizedAlways` (not only checked in); movement-driven 5-min throttle (`lastReportedAt`) so breadcrumbs land in the **background** where the foreground `Timer` is suspended; `PMPickerSheet` switched to `/time/fleet-locations` + `PMLocation`; locate works for any PM with a recent fix.
- Colin spec: `team-docs/colin-fleet-location-history-2026-06-16.md`.

### Schema gotchas (discovered the hard way on the time routes)
- `users.id` is **varchar**, not uuid → all JOINs need `u.id::uuid = …`.
- `gt_user_profile.user_id` and `.org_id` are **varchar** → `gup.user_id::uuid`, `gup.org_id::uuid`.
- `gt_user_profile` has **no `role` column** — role comes from `req.user.role` (resolved by `requireAuth` via `user_app_roles` JOIN). Do NOT query `gt_user_profile.role`.
- `gt_user_profile` has **no `display_name` column** — build it from `TRIM(first_name || ' ' || last_name)`.
- `pg` sends JS strings as varchar → comparing a string param to a uuid column needs `$1::uuid`.
- These fixes also repaired pre-existing breakage in `/time/active`, `/time/events`, `/time/summary`.

### Geofence auto-check-in (cc-789 iOS, cc-794)
- `registerGeofence` prefers `job.latitude`/`job.longitude` (payload coords) over `MKLocalSearch` geocoding; `monitorRegion` helper; `autoArrive` checks in directly (no confirm banner).
- `registerGeofences(for:)` monitors up to **20 nearest** located jobs (iOS hard cap); re-ranked on each list refresh.
- `evaluateArrival()` — one-shot nearest-job-within-200m check via `requestLocation`, fired on list load and every app foreground (`scenePhase .active`).
- `didExitRegion` guards `region.identifier == checkedInJobId` so exiting a non-checked-in region never triggers a spurious checkout.

### Monday forms (cc-795, 796, 804, 805)
- Board `18406336489` (Site Manager Forms), branched by the "Form Selection" status column.
- **Dumpster Swap** — `POST /submit-dumpster`, Form Selection fixed to "Dumpster Swap".
- **Material Shortage** — `POST /submit-material`, branches on `materialOption`: Shortage / Wrong-Incorrect / Incorrect Measurement / Return; per-branch required-field validation; material file columns `filef0m5yqub` (Return Sheet), `filed5z4szso` (Picture).
- **Monday status labels must match EXACTLY** or Monday silently drops them.
- iOS: both forms styled like `PDFChangeOrderView` (hero bg, frosted Form card, dark nav); reachable from the new **"Requests" card** in `JobGuidedView` (Change Order / Dumpster Swap / Material Shortage rows).

### 360 photo tagging + gallery (cc-812, 813, 814, 815)
- `phase_item_photos.tag` is separate from the `photos` gallery table — must `POST /projects/:id/photos` (`/photos/confirm` proxy) to land 360 shots in All Photos.
- Proxy forwards `photoTags` on phase-item PATCH (cc-812); `tag` passes through photo GET via the `...p` spread.
- iOS: `handle360Captures` sends `photoTags` for the **own bucket only** (value = human tag label, not id; siblings derive their tag automatically); confirms each photo to the gallery once per `s3Key` (best-effort); completed 360 item shows photos **grouped by tag** (`photo360GroupedView`); All Photos shows a teal tag pill mirroring the navy customer badge.

---

## UI polish (cc-796–811)
- Form picker saga: tried `.pickerStyle(.menu)` → `Menu{Picker}` → `Menu{Button}` → inline-expand → **`confirmationDialog`** (final, no bounce/blank). Yes/No stayed `.segmented` (instant). Lesson: SwiftUI `Form` animates row insertion, so inline-expand dropdowns bounce; system `Menu` blanks the label on selection. `confirmationDialog` is the stable native pattern.
- Persistent labels above placeholder-only text fields; placeholders blanked to avoid doubled text.
- `TextField(axis:.vertical)` for keyboard avoidance (TextEditor doesn't get Form scroll-to-focus); `ScrollViewReader` scrolls focused field to `.center`.
- Project/user search was 401ing — missing `Authorization` header on `/search-projects` and `/get-users` (both `requireAuth`); fixed in Change Order + Dumpster + Material forms.

## Tooling
- **`awsmfa` rewritten** in `~/.zshrc`: prompts for code → `unset AWS_*` env (so it uses the long-term IAM key, not stale session creds) → `sts get-session-token` → writes to BOTH shell env AND the `mfa` profile in `~/.aws/credentials`. The old breakage was "Cannot call GetSessionToken with session credentials" (env had expired session creds shadowing the IAM key).
- **omp** updated to 16.0.5 (major bump from 15; watch for behavior changes after restart).

---

## Open Items
- `gt_location_history` 90-day prune needs a recurring EventBridge schedule (deploy-time only now).
- Material form notes column `long_text2prjdbrs` (Dumpster) still flagged for field-id verification.
- `GUNNERCAM_POINTS_WEBHOOK_TOKEN`, `REWARDS_ENABLED=false` — unchanged from prior session.
- Terraform stash (`stash@{0}`) — still needs IaC reconcile.
- Employee notice (`employee-notice-points-location.md`) — now technically backed by the location store; still not distributed (HR/legal/IT sign-off).

## Related
- [[CONTRIBUTING]] · [[CHANGE_MANAGEMENT_POLICY]]
- [[employee-notice-points-location]]
- [[session-2026-06-15-cc766-788-appstore-hardening-polish]]
