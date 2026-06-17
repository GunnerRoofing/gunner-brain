---
type: session
title: 'cc-815–842: location compliance, iOS file split, service keys, backend fixes'
created: '2026-06-17'
updated: '2026-06-17'
tags:
  - session
  - ios
  - backend
  - location
  - compliance
  - refactor
  - service-keys
status: complete
---

# Session: cc-815–842 — location compliance, iOS file refactor, service keys, backend fixes

**Date:** 2026-06-17  
**Lambda at end:** v259 (`live`)  
**iOS build:** BUILD SUCCEEDED — all cc-815–842 committed to `main`

---

## Backend deploys

| Version | Change |
|---|---|
| v250 | `forwardLocationPing` fixed to use `FIELD_PORTAL_API_URL/KEY` (confirmed contract) |
| v251 | `POST /submit-material` item names: `"<customer> - Material Shortage"` |
| v252–v257 | Location consent/compliance: per-user consent flag, `gt_user_location_status`, compliance roster, dual-auth |
| v258 | `POST /templates/service-keys` fixed (dropped phantom `updated_at` column) |
| v259 | `GET /templates/service-keys` list + `DELETE /templates/service-keys/:id` revoke |

### Location consent + compliance (cc-830, cc-831, cc-832, cc-833)

**Per-user location consent (cc-831):**
- Migration `20260617_location_consent`: `ALTER TABLE gt_user_profile ADD COLUMN IF NOT EXISTS location_consent boolean NOT NULL DEFAULT false`
- `GET /users` exposes `location_consent` per user
- `PATCH /time/location` + `POST /time/travel-ping`: `hasLocationConsent()` helper gates both — returns `200 ok` with no write if `false`; audits `time.location.no_consent`
- Default `false` for all users until CT/NJ notice signed
- Dev opt-in: `UPDATE gt_user_profile SET location_consent = true WHERE user_id = '3e3f0491-b16f-42cd-9437-028a4a3ad771'`

**Location permission status (cc-833):**
- Migration `20260617_user_location_status`: `gt_user_location_status` table `(user_id PK, org_id, auth_status, accuracy, updated_at)`
- `PATCH /time/location-permission`: upserts OS permission status — NOT consent-gated (must capture "denied" from non-enrolled users)
- `GET /time/location-compliance`: dual-auth (Cognito admin/manager + service key); LEFT JOINs `user_organizations` so gone-dark users still appear; returns `auth_status`/`auth_updated_at`/`last_location_at`/`location_consent`/`checked_in` per user
- `GET /time/fleet-locations`: now carries `auth_status` via LEFT JOIN

**iOS (cc-830, cc-832):**
- `AuthManager.locationConsentGranted` (default `false`; populated from `location_consent` in `ValidateResponse`; reset on logout)
- `CheckInManager`: gates `reportTravelPing`, `reportLocation`, `startLocationReporting`, and both continuous-stream start sites behind `locationConsentGranted`
- `CheckInManager.reportPermissionStatus()`: PATCH `/time/location-permission` on every auth-status change + every app foreground; un-gated, fires even when denied
- `LocationComplianceView`: admin/manager list with permission pill (Always=green/WhenInUse=amber/Denied=red), consent pill, last-seen relative time; mounted in `PMPickerSheet` via checklist toolbar button

### Service keys (cc-834)
- **Root cause**: `POST /templates/service-keys` always 500'd since it was written — INSERT wrote `updated_at` but `gt_service_keys` has no such column
- Fix: drop `updated_at` from INSERT
- Added `GET /templates/service-keys` (list metadata, no raw key) and `DELETE /templates/service-keys/:id` (revoke + audit)
- Colin's key minted: `5762117f3cc91a2f0e3ccc9beadeea4dca9f0534fd3bb777c156c09ce4e0c4c1` — stored in 1Password. Rotation: `GET` to find ID → `DELETE` to revoke → `POST` to mint new.

### Other backend fixes
- **cc-835**: `routes/fleet/index.js` — `require('../points/awardPoints')` → `require('../../points/awardPoints')` (3 sites: inspection submit lines 313/324 + manager review line 519). Was causing 500 on every inspection submit.
- **cc-820**: Monday item names now `"<customer> - Dumpster Swap"` / `"<customer> - Material Shortage"` (was just `customerName`)
- **cc-816**: `forwardLocationPing` wired to `FIELD_PORTAL_API_URL/KEY` (same as check-in push); `user.id` UUID as dedup key; `isFinite` guard on lat/lng; flag still off (consent #37)

---

## iOS: major file refactoring (cc-825–842)

This session completed the CLAUDE.md iOS rules sweep: one primary view per file, no models in view files, no files >1000 lines without decomposition.

| Prompt | What moved |
|---|---|
| cc-825 | `SettingsView.swift` 1690→270 lines; `UserModels.swift`, `UserManagementViews.swift`, `PickerSheets.swift`, `FleetModels.swift`, `VehicleScheduleViews.swift` created |
| cc-826 | 19 Fleet Codable models extracted → `Fleet/InspectionModels.swift` + appended `Fleet/FleetModels.swift` |
| cc-827 | Photos comment models → `Jobs/FPModels.swift`, `Jobs/CCModels.swift`; `Photos/PhotoModels.swift` (PresignResponse) |
| cc-828 | `Announcement`/`AnnouncementsResponse` → `Announcements/AnnouncementModels.swift`; `InviteValidate`/`Login`/`ErrorResponse` → `Auth/UserModels.swift`; `PMLocation` → `Jobs/JobListModels.swift` |
| cc-829 | `PhaseDetailView.swift` siblings → `PhaseItemViews.swift` |
| cc-830 | `VehicleListViews.swift` 1258→385 lines; `VehicleDetailView.swift`, `VehicleSheets.swift` |
| cc-831 | `JobGuidedView.swift` 1167→799; `CameraMarkupModels.swift`, `JobMenus.swift`, `PhaseCardViews.swift`, `LeadsLocationManager.swift` |
| cc-832 | `VehicleDocumentViews.swift` 1076→617; `DocumentPickerHelpers.swift`, `OtherDocumentsViews.swift` |
| cc-833 | `VehicleInspectionView.swift` 1162→317; `VehicleInspectionView+Steps.swift`, `+Data.swift`, `FlowLayout.swift` (extensions) |
| cc-834 | Camera control row: capture button dead-centered (equal thirds, leading/trailing alignment) |
| cc-836 | Phase review screen: 3-col captured-photo thumbnail grid via `capturedPhotosGrid` |
| cc-837 | `JobPhotoSessionView.swift` 1150→597; `CCCameraModel.swift`, `CCDualCameraModel.swift`, `CameraRepresentables.swift` |
| cc-838 | `JobGuidedView.swift` 799→312; `JobGuidedView+Content.swift`, `+Data.swift` (extensions) |
| cc-839 | `PhaseDetailView.swift` 880→333; `PhaseDetailView+Views.swift`, `+Actions.swift` (extensions) |
| cc-840 | `ContentView.swift` 976→207; `TabRoots.swift`, `FormsListView.swift`, `AppBanners.swift` |
| cc-841 | `GuidedTasksView.swift` 984→644; `GunnerTaskRowViews.swift` |
| cc-842 | `JobListView.swift` 956→285; `GuidedJobsListView.swift`, `PMJobViews.swift` |

**Technique for large views:** same-type `extension` blocks in sibling files (cc-833/838/839). Properties must be deprivatized for extensions to access them — access-level change only, zero runtime effect.

---

## `omp update` (16.0.5)
- **Breaking in 16.0.1**: `hooks`/`customTools` → `extensions` array; `--hook`/`--tool` → `--extension`/`-e`; directories `hooks/`,`tools/` → `extensions/`; `commands/` → `prompts/`
- **Breaking in 16.0.0**: `toolCallSyntax` → `dialect`; `ToolCallFormat` → `DialectFormat`
- **New**: Advisor runtime (passive second-model reviewer, `advisor.enabled`); `role` field on task spawns; `/new` clears live context; `--max-time` flag; Vertex AI; clipboard image paste
- **`/clear` skill updated**: now ends with "run `/new`" instruction (the only thing that actually drops live context)
- **`awsmfa` rewritten**: `unset AWS_*` before STS call so it uses long-term IAM key, not stale session creds; writes to both shell env AND `~/.aws/credentials` under `mfa` profile

---

## Key decisions / patterns learned

**Service key rotation:**
```bash
gt && curl -s "${API}/templates/service-keys" -H "Authorization: Bearer ${TOKEN}" | jq .   # get ID
curl -s -X DELETE "${API}/templates/service-keys/<id>" -H "Authorization: Bearer ${TOKEN}"  # revoke
curl -s -X POST "${API}/templates/service-keys" -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" -d '{"description":"..."}'                             # mint new
```
Raw key only appears once in mint response — save immediately to 1Password.

**Warm container delay**: Lambda alias updates don't immediately drain warm containers. `--qualifier <version>` bypasses the warm pool for testing. Expect 2–10 min for old containers to clear.

**iOS extension decomposition pattern:**
1. Remove `private` from all stored state (access-level only, zero runtime effect)
2. Move computed views → `+Views.swift`; move data funcs → `+Data.swift`; both `extension StructName { … }`
3. `@Environment(\.dismiss) var dismiss` must also be deprivatized if used cross-file

---

## Open Items
- `gt_location_history` 90-day prune → add recurring EventBridge schedule
- `GUNNERCAM_POINTS_WEBHOOK_TOKEN` + `REWARDS_ENABLED=false` — still pending
- Terraform stash reconcile
- Employee notice — not distributed; HR/legal/IT sign-off pending
- `LOCATION_PING_FORWARD` flag — off; enable after consent #37 signed
- Colin's service key delivered — he needs to wire it to `GET /time/location-compliance`

## Related
- [[gunnerteam/CONTRIBUTING]] · [[gunnerteam/CHANGE_MANAGEMENT_POLICY]]
- [[gunnerteam/employee-notice-points-location]]
- [[session-2026-06-16-cc789-815-location-forms-360gallery]]
