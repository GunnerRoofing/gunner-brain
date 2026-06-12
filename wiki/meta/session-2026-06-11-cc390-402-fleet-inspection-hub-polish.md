---
type: session
owner: tyler
created: 2026-06-11
updated: 2026-06-11
tags: [gunnerteam, ios, backend, fleet, inspection, ux]
status: complete
related:
  - "[[tyler/hot.md]]"
  - "[[tyler/Memory.md]]"
---

# cc-390–402: Fleet Inspection + Hub Polish, Role Fix, Notification Animation

**Session date:** 2026-06-11 (fifth session)
**Lambda at session end:** v175 live (prod Aurora)
**iOS:** BUILD SUCCEEDED throughout

---

## Fleet Inspection UX (cc-390–397)

### cc-390 — Single-camera auto-launch
- `advance()` auto-launches `InspectionCameraSession` when entering step 2 with pending photos
- Intercept card replaced with minimal "Tap to take photo" dashed button
- `stepIndex` 2–10 confirmed matching between `CameraSessionComponents` and `photos` dict

### cc-391 — Driver feedback surface
- Backend: `GET /vehicle/inspections` returns `review_status`, `review_notes`, `license_plate`
- `InspectionsResponse` promoted from `private` to `internal` (shared between two files)
- `VehicleInspectionHubView`: `loadFeedback()` on appear; amber/red `feedbackCard` above Start Inspection
- `InspectionFeedbackView`: manager notes + Re-submit button; `navigationDestination`

### cc-392 — Pending Inspections card layout
- `load()` sorts damage-first, then oldest-submitted
- Card-per-item layout: red/teal damage/clean pill, amber photo count < 9, `AuthenticatedThumb`

### cc-393 — Damage checklist
- Step 12: Y/N toggle → 8-chip checklist → optional free-text
- `anyDamageString` computed property serialises to "; "-joined string
- `FlowLayout` custom `Layout` for wrapping chips
- `notesStep` (step 13) preserved separately

### cc-394 — Hub redesign
- Manager: `managerSummaryCard` (tappable pending/maintenance stats, or "All clear")
- Driver: `myInspectionCard` three states — overdue hero (red), scheduled hero (teal), no-schedule nav card
- `navCard`: `maintenancePill` Bool → `maintenancePillLabel: String` + `maintenancePillOverdue: Bool`
- My Vehicle/My Vehicles pill now shows specific item label

### cc-395 — Plate/vehicle prefill for fixed-truck drivers
- Non-ops, non-manager drivers with `myVehicleId` set: `prefillVehicle()` fetches plate, sets `vehicleType = .company`, auto-launches camera
- `prefillBanner` chip shows "Company Vehicle · XYZ-1234  Change" during steps ≥2
- "Change" resets to step 0

### cc-396 — Manager Review hero redesign
- `InspectionReviewView`: full-bleed hero photo (68% width via `@State heroHeight` + `GeometryReader`), gradient scrim, glass back button, 3-column photo grid at 96pt
- Sticky `.safeAreaInset` action bar: Pass (full-width teal) + Needs Work/Fail (outlined)
- Two-tap select/submit pattern; notes TextEditor slides in above bar
- `UIScreen.main` deprecated → replaced with `GeometryReader` measurement

### cc-397 — Maintenance countdown bar
- Card-per-item layout (12pt spacing), urgency sort (overdue→upcoming→ok)
- `Capsule` progress bar per item (fraction = interval consumed, color by urgency)
- `progressFraction` and `progressColor` helpers; `urgencyRank` for sort

---

## Data / Infra (cc-398–400)

### cc-398 — Fix Tyler's role to admin
- `user_app_roles` row updated via Lambda migration `20260611_fix_tyler_admin`
- Role is in `user_app_roles` → `app_roles` (not `user_organizations.role`)
- v174

### cc-399 — Hide FAB during vehicle inspection
- `assistantStore` threaded through `FleetTabRoot` → `VehicleInspectionHubView`
- `.onChange(of: showInspection)` hides FAB when inspection wizard opens, restores on dismiss

### cc-400 — Maintenance alert EventBridge + specific pill label
- `loadUrgentMaintenance()` loads top urgent item, sets `urgentMaintLabel`/`urgentMaintStatus`
- `navCard` pill shows "Oil due in 480 mi" (amber) or "Oil OVERDUE" (red)
- `checkMaintenanceAlerts` exported from `fleet/index.js`: queries per-org overdue/upcoming items within 500mi, sends driver push + manager push
- Migration: `alert_sent_at TIMESTAMPTZ` on `gt_vehicle_maintenance`
- EventBridge rule: `cron(45 11 * * ? *)` daily (06:45 ET)
- v175

### cc-401 — Admin/manager inspection card + remove redundant Pending nav card
- `myInspectionCard` now renders for all users (removed `!isManager` guard)
- "Pending Inspections" nav card removed (summary card is the only entry point)
- `loadMyVehicle()` and `loadUrgentMaintenance()` now run for all roles

### cc-402 — Notification dismiss animation fix
- Row removal: `.move(edge: .trailing)` → `.scale(0.96).combined(with: .opacity)` (no bleed)
- Shadow moved inside `.background(shape...)` to clip correctly during collapse
- Dismiss animation: spring → `.easeOut(duration: 0.22)` (no overshoot)

---

## Key Patterns

**`FlowLayout`** (`VehicleInspectionView.swift`) — custom SwiftUI `Layout` for wrapping chip rows. Reusable pattern for tag/chip UI in any view.

**`AuthenticatedThumb`** (`VehicleInspectionReviewView.swift`) — Bearer-token-auth image loading via URLSession in `.onAppear`. Pattern for any proxied photo thumbnail.

**`InspectionsResponse` internal** — must be `internal` (not `private`) when shared between `VehicleInspectionView.swift` and `VehicleInspectionHubView.swift`.

**`GeometryReader` for deprecated `UIScreen.main`** — iOS 26 deprecates `UIScreen.main.bounds`. Use `@State var dim: CGFloat = defaultValue` + `GeometryReader { geo in Color.clear.onAppear { dim = geo.size.width * ratio } }` with `.frame(height: 0)` so it doesn't affect layout.

**Shadow clipping during animation** — Move `.shadow()` inside `.background(Shape().shadow(...))` rather than as a separate modifier after `.clipShape()`. This keeps shadow inside clip bounds during layout transitions.

**`urgencyRankLocal` pattern** — private helper in views for urgency sorting matching the backend's own `urgencyRank`. Consistent: overdue=2, upcoming=1, ok=0.

---

## Lambda Deploy History

| Version | Key Change |
|---------|------------|
| v172 | cc-400 iOS groundwork (prior sessions) |
| v173 | cc-398 fix_tyler_admin (wrong SQL — `user_organizations.role` doesn't exist) |
| v174 | cc-398 corrected (via `user_app_roles`) |
| v175 | cc-400 maintenance alerts + `alert_sent_at` migration |
