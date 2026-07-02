---
title: Gunner Team iOS App
type: gunner
tags:
  - gunner
  - ios
  - swift
  - app
  - monday
  - cloudflare
  - forms
  - api
  - auth
  - push-notifications
  - qr
  - referrals
  - fleet
  - vehicle-inspection
  - scheduler
  - overdue-notifications
  - companycam
created: 2026-04-16T00:00:00.000Z
updated: '2026-05-12'
sources: []
related:
  - '[[tyler/gunner-assistant/gunner-assistant]]'
  - '[[vendors/monday]]'
  - '[[questions/app-store-guideline-4-8-webview-login]]'
  - '[[questions/hexnode-custom-app-deployment]]'
status: stable
---

# Gunner Team iOS App

Native iOS app (Swift/SwiftUI) providing Gunner employees with form access, announcements, and company tools. **Renamed from GunnerForms → Gunner Team (2026-04-30).** Approved 2026-04-22 as a Custom App, distributed via Apple Business Manager → Hexnode. Maintained by Tyler Suffern.

**Bundle ID:** `com.gunner.team`  
**URL Scheme:** `gunnerteam://`  
**Display Name:** `Gunner Team` (CFBundleDisplayName in Info.plist)

## Architecture

Hybrid app — native SwiftUI views throughout. Auth system **migrating from Cloudflare D1 (SQLite) + Worker JWT → Express.js + RDS PostgreSQL on AWS.** See [[tyler/gunnerteam/gunnerteam-api-aws-migration]] for full migration decision and infrastructure details. Announcements with APNs push notifications. Forms screen retains Monday.com WebView + native APFormView.

| File | Purpose |
|------|---------|
| `GunnerTeamApp.swift` | App entry point; AppDelegate for push notification registration |
| `Home/ContentView.swift` | Home screen — two hero cards (Forms, Referrals) + header |
| `Home/FormsListView.swift` (in ContentView.swift) | Form card list — Site Manager, Change Order, IT Request, AP Form |
| `Home/ReferralsView.swift` | QR code with UTM URL; CoreImage generation; ShareLink export |
| `Auth/LoginView.swift` | JWT login with StablePasswordField (UIViewRepresentable, focusTrigger) |
| `Auth/AuthManager.swift` | JWT/Keychain, login, invite, reset, device token registration |
| `Auth/SettingsView.swift` | Settings + UserListInline (tappable rows) + UserDetailView |
| `Auth/AcceptInviteView.swift` | New user account setup — first name, last name, username, password |
| `Announcements/AnnouncementsView.swift` | In-app announcements list + compose sheet (admin/manager) |
| `Forms/APFormView.swift` | Native Accounts Payable form via Cloudflare Worker |
| `Forms/ITRequestView.swift` | Native IT Request form |
| `Forms/ChangeOrderView.swift` | Native Change Order form |
| `Forms/FormWebView.swift` | WKWebView wrapper for Monday embeds |
| `Forms/VehicleInspectionHubView.swift` | Fleet hub — Manage Vehicles list, Team Schedules, vehicle detail/edit, assign sheet |
| `Forms/VehicleInspectionView.swift` | Step-based vehicle inspection form (15 steps) |

## Home Screen Navigation

`ContentView` has two hero `HomeCard` items via `NavigationLink(destination:)`:

| Card | Icon | Destination |
|------|------|-------------|
| Forms | list.clipboard.fill (red) | `FormsListView` — all four form cards |
| Referrals | qrcode (blue) | `ReferralsView` — personal QR code |

Header retains logo, "TEAM" wordmark, announcements bell (unread dot), settings gear. `FormsListView` and `ReferralsView` push within the same `NavigationStack` — swipe-back works on both.

## Auth System

JWT-based auth on Cloudflare Worker + D1 SQLite. All API calls use `Authorization: Bearer <token>`.

| Route | Method | Purpose |
|-------|--------|---------|
| `POST /auth/login` | POST | Email + password → JWT (7d expiry) |
| `POST /auth/invite` | POST | Admin creates invite token (email, role, dept, manager) |
| `POST /auth/register` | POST | User registers via invite token |
| `POST /auth/request-reset` | POST | Sends password reset email |
| `POST /auth/reset-password` | POST | Validates reset token → sets new password |
| `POST /auth/change-password` | POST | Authenticated password change |
| `POST /auth/register-device` | POST | Stores APNs device token for push |

**Roles:** `admin`, `manager`, `user`.

**Manager permissions (2026-05-04):** Granular permission split in `UserDetailView`:
- `canEditProfile` — admin OR manager's direct report (not self)
- `canEditSecurity` — admin OR direct report OR self (managers can change own password)
- `canEditName` — admin only, OR manager's report whose dept ≠ Sales (Sales names are admin-only)
- `canChangeRole` — not self AND (admin OR manager's direct report); managers limited to User/Manager options only
- `canDelete` — admin only, not self

**D1 Database:** `gunner-team-db` (id: `5b0240c5-8b47-46fa-b1a4-82825edce3e2`) bound to worker. Schema: `users`, `invite_tokens`, `reset_tokens`, `announcements`. Unique index on `users.email` added 2026-05-04.

**Email:** Resend API on `updates.gunnerroofing.com` — invite and reset emails.

## Announcements Feature (feature/announcements)

In-app announcement list + APNs push notifications on post.

| Route | Method | Auth | Purpose |
|-------|--------|------|---------|
| `GET /announcements` | GET | Any user | Fetch list (pinned first, then newest) |
| `POST /announcements` | POST | Admin/Manager | Post new announcement + fire push |
| `DELETE /announcements/:id` | DELETE | Admin (any) / Manager (own) | Delete |

**Push flow:** `handlePostAnnouncement` → INSERT row → fetch all `device_token` values → `sendAPNsPush()` per token. Errors logged to `console.log` via `wrangler tail gunner-team-api`.

**APNs:** ES256 JWT via `crypto.subtle.importKey` + `crypto.subtle.sign`. `APNS_ENV` secret controls endpoint:
- `sandbox` → `api.sandbox.push.apple.com` (Xcode dev builds)
- `production` → `api.push.apple.com` (ABM/Hexnode distribution)

**APNs debugging (2026-05-04):** `InvalidProviderToken` (403) error — all secrets were set but key was invalid. Fix: re-paste all 5 APNs secrets via Cloudflare dashboard. Confirmed working after re-paste. If secrets are set via dashboard (not `wrangler secret put`), multiline `.p8` key can silently corrupt — prefer CLI.

**Cloudflare secrets (all set as of 2026-05-04):**
- `APNS_BUNDLE_ID` = `com.gunner.team`
- `APNS_ENV` = `sandbox` (switch to `production` before ABM deploy)
- `APNS_TEAM_ID` — Apple Developer team ID
- `APNS_KEY_ID` — APNs key ID (from Apple Developer portal)
- `APNS_PRIVATE_KEY` — p8 key contents (Sandbox & Production type — works for both envs)

**Xcode:** Push Notifications capability must be enabled in target → Signing & Capabilities.

## D1 Migrations

All completed as of 2026-05-04:
```sql
ALTER TABLE users ADD COLUMN department TEXT;
ALTER TABLE users ADD COLUMN manager_id INTEGER;
ALTER TABLE invite_tokens ADD COLUMN department TEXT;
ALTER TABLE invite_tokens ADD COLUMN manager_id INTEGER;
CREATE TABLE IF NOT EXISTS announcements (...);
ALTER TABLE users ADD COLUMN device_token TEXT;
ALTER TABLE users ADD COLUMN first_name TEXT;
ALTER TABLE users ADD COLUMN last_name TEXT;
ALTER TABLE invite_tokens ADD COLUMN first_name TEXT;
ALTER TABLE invite_tokens ADD COLUMN last_name TEXT;
CREATE UNIQUE INDEX idx_users_email ON users(email);
```

## Referrals Feature

`ReferralsView` generates a QR code client-side using `CoreImage.CIFilterBuiltins` — no backend needed. Each user's QR encodes a URL with UTM parameters:

```
https://www.gunnerroofing.com/?utm_campaign=App_Sales&utm_source=Smith&utm_medium=Referral
```

**UTM design (confirmed working 2026-05-04 — HubSpot capturing all 3):**
- `utm_campaign` = `App_Sales` (dept = Sales) or `App_PM` (all others). Future: `App_Customer` for customer app.
- `utm_source` = user's last name (URL-encoded) — used for HubSpot contact owner assignment via workflow
- `utm_medium` = `Referral` (hardcoded)

**HubSpot routing:** Workflow branches on `utm_campaign` value. `App_Sales` → assign contact owner by last name match (no round robin). `App_PM` → round robin pool, shared kickback. Contact form is hand-coded (not HubSpot native) — submits to both estimator system and HubSpot API simultaneously; already reads and passes UTM params.

**Known limitation:** Last name matching breaks if two salespeople share a last name. Consider switching `utm_source` to username if that becomes an issue.

QR image is generated at 10× scale for sharpness. `ShareLink` exports the QR as an image. Tap to expand QR → sets screen brightness to 1.0 for easy scanning.

## User Management — UserDetailView

`UserListInline` renders a hierarchical tappable list (NavigationLink per row). Returns `[(user: AppUser, isReport: Bool)]` tuples for visual indentation metadata.

**Admin hierarchy order:** self → other admins (alpha) → each manager + their reports (alpha) → ungrouped users. `seen: Set<Int>` deduplicates — a user promoted to manager won't appear twice.

**Manager view:** self first → direct reports alphabetically.

**Visual treatment:** Report rows have a 3px blue (`#1B538F` 25% opacity) left accent bar, slightly smaller font. Department color badge per row (Sales=red, Technology=blue, Operations=cyan, Finance=green, HR=purple, Marketing=amber, Corporate=slate). Role badge (Admin/Manager/User) always shown.

**Manager picker (`UserPickerSheet`):** filtered to managers and admins only.

`UserDetailView` sections (shown based on permissions):
- **Profile** — first/last name (editable if `canEditName`), username + email (read-only), dept picker, manager picker
- **Role** — pill selector; admins see User/Manager/Admin; managers see User/Manager only
- **Security** — password reset (shown to admin, manager's reports, and managers for self)
- **Danger Zone** — delete with inline confirmation; admin-only, not self

Pickers use `StringPickerSheet` / `UserPickerSheet` — `.sheet` based to avoid iOS popover bug inside sheets.

## StablePasswordField Fix

LoginView uses `UIViewRepresentable` with a stable `UITextField` instance to prevent iOS re-evaluating autofill context on every SwiftUI render (caused Passwords QuickType bar flicker). Focus managed via `focusTrigger: Int` binding — coordinator tracks `lastTrigger`, only calls `becomeFirstResponder()` via `DispatchQueue.main.async` when trigger increments. Avoids AttributeGraph cycles.

## Cloudflare Worker

**URL:** `https://gunner-team-api.anil-nair.workers.dev/`  
**Secrets:** `MONDAY_API_TOKEN`, `JWT_SECRET`, `RESEND_API_KEY`, `APNS_BUNDLE_ID`, `APNS_ENV` (sandbox), `APNS_TEAM_ID`, `APNS_KEY_ID`, `APNS_PRIVATE_KEY`  
**Owner:** Anil Nair's Cloudflare account (Tyler has deploy access)

## Repository

- **GitHub:** `gunner-ios` repo (GunnerRoofing org)
- **Location:** `/Users/tyler.suffern/Documents/GunnerForms/`
- **Xcode project:** `GunnerForms/GunnerTeam.xcodeproj`
- **Target:** `GunnerTeam` (renamed in Xcode; `productName = GunnerTeam`, `INFOPLIST_FILE = GunnerTeam/Info.plist`)

## Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | App Store version — always shippable |
| `feature/ap-native` | APNs + auth base; all new features branch from here |
| `feature/announcements` | Announcements + push notifications + home nav (most complete) |
| `feature/navigation` | Home screen nav rewrite (missing announcements — needs merge) |
| `feature/change-order-native` | Native CO form (older) |
| `feature/sign-in-with-monday` | Preserved; removed from main for 4.8 compliance |

**Note:** `feature/navigation` and `feature/announcements` diverged from `feature/ap-native`. Announcements + push only exist on `feature/announcements`. Merge into nav or pick one branch to continue from.

## Current Forms

| Form | Mode | Destination |
|------|------|-------------|
| Site Manager Forms | WebView | wkf.ms/3PGtJR9 (Monday embed) |
| Change Order | Native | Board 18310339669 via Cloudflare Worker |
| IT Request | Native | Board 18408104314 via Cloudflare Worker |
| Accounts Payable | Native | APFormView via Cloudflare Worker |

## App Store Status

- v1.01 rejected 2026-04-09 — Guideline 4.8 (login services)
- Approved 2026-04-22 — Custom App (private); not on public App Store
- Updated version approved 2026-04-28 — native IT Request + Change Order + auth
- Deployment: Apple Business Manager → Hexnode MDM; see [[questions/hexnode-custom-app-deployment]]
- App Review test account: `appreview@gunnerroofing.com`

## Vehicle Inspection & Fleet Management (updated 2026-05-11)

### Hub Structure

`VehicleInspectionHubView` is the Fleet tab entry point for **all roles** (including regular users — routing changed 2026-05-11; users no longer go directly to VehicleInspectionView).

**Non-manager users see:**
- Red **Inspection Overdue** banner (if overdue) — heavy haptic, taps directly into inspection form
- **Start Inspection** / **Submit Inspection** card (color + text changes when overdue)
- **My Vehicle** card (if a vehicle is assigned) → read-only VehicleDetailView with "Edit Notes" button

**Admin/manager users also see:**
- **Manage Vehicles** → `VehicleListView`
- **Team Schedules** → `TeamSchedulesView`
- **Inspection Reports** → `InspectionReportsListView`
- **Pending Inspections** card (when count > 0)

### Overdue Inspection Detection (Client-Side)

`checkSchedule()` in the hub calls `GET /vehicle/my-schedule` and computes overdue state client-side using the same windows as the scheduler (weekly=7d, biweekly=14d, monthly=30d). Sets `isOverdue` state which drives the red banner and card styling. `loadMyVehicle()` separately fetches `/fleet/my-vehicle` to populate the "My Vehicle" card.

`MyScheduleInfo` decodes `last_inspection` as a `Date` using `ISO8601DateFormatter` with fractional-seconds support — handles both `yyyy-MM-dd` and full ISO8601 timestamps.

### Overdue Notification Scheduler (Backend)

`scheduler.js` runs every 4 hours (no day-of-week constraint — purely rolling window). Logic:

1. **First overdue:** Sets `vehicle_schedules.first_overdue_at = NOW()` and sends APNs push to user: "Your vehicle inspection is overdue. Please submit it now." Stale tokens are cleared from `users.device_token`.
2. **Manager notification:** 24 hours after `first_overdue_at`, sends push to user's manager: "[Name] hasn't submitted their vehicle inspection." Sets `manager_notified = TRUE` to prevent repeat.
3. **Reset:** Submitting an inspection calls `UPDATE vehicle_schedules SET first_overdue_at = NULL, manager_notified = FALSE` — clears overdue state for next cycle.

**Testing:** Set `first_overdue_at = NOW() - INTERVAL '25 hours'` directly in DB to trigger both user + manager notifications on next scheduler tick. Or backdate `submitted_at` on the latest inspection row.

### Mandate Inspection (Manager/Admin)

Long-press a scheduled user row in TeamSchedulesView → "Mandate Inspection" context menu item. Calls `POST /vehicle/mandate-inspection` → sets `first_overdue_at = NOW()` + sends push: "Your manager has requested an immediate vehicle inspection." App shows overdue state on user's next launch. "Sent" badge appears on the row briefly after success.

### User Vehicle View

Non-managers navigate to `VehicleDetailView` from the "My Vehicle" card. Behavior differences from manager view:
- Toolbar shows **"Edit Notes"** instead of "Edit"
- `save()` sends only `{ notes }` in the PUT body (not all fields)
- `VehicleDocSection` shows no upload buttons (`isManager: false`)
- All other fields (`editRow` with `managerEditable: false`) remain read-only

### Vehicle Types

| Type | rawValue | Icon | Picker at step 1? |
|------|----------|------|-------------------|
| Company Vehicle | `"Company Vehicle"` | car.fill | No — loads silently from /fleet/my-vehicle |
| Gutter Van | `"Gutter Van"` | bus.fill | Yes — /fleet/gutter-vans |
| Metal Machine | `"Metal Machine"` | gearshape.fill | Yes — /fleet/metal-machines |
| Dump Trailer | `"Dump Trailer"` | truck.box.fill | Yes — /fleet/dump-trailers |

**Gutter van names (D1):** Stamford Gutter Van, Cromwell Gutter Van, Mt. Arlington Gutter Van.

### Inspection Form Flow (VehicleInspectionView)

15 steps: 0=vehicle type, 1=plate/picker, 2–10=photos, 11=mileage, 12=damage, 13=notes, 14=submit.

- **Company Vehicle selected:** calls `GET /fleet/my-vehicle` first. If no vehicle assigned → alert "You don't have a company vehicle assigned." If assigned → sets `licensePlate` from vehicle, skips to step 2.
- **Gutter/Metal/Trailer selected:** loads shared vehicle picker (step 1); tap auto-advances. Next button hidden on step 1 for shared pickers.
- **Back from step 2 (Company Vehicle):** returns to step 0 (skips plate step).

### Fleet API Endpoints

| Route | Method | Auth | Purpose |
|-------|--------|------|---------|
| `/fleet/vehicles` | GET | Admin/Manager | List vehicles (manager: reports' only) |
| `/fleet/vehicles` | POST | Admin/Manager | Create vehicle |
| `/fleet/vehicles/:id` | GET | Admin/Manager | Vehicle + last inspection detail |
| `/fleet/vehicles/:id` | PUT | Any | Update vehicle; non-managers send only `notes` |
| `/fleet/vehicles/:id` | DELETE | Admin | Deactivate vehicle |
| `/fleet/vehicles/:id/assign` | POST | Admin/Manager | Assign to user (manager: reports only) |
| `/fleet/vehicles/:id/assign` | DELETE | Admin | Unassign (admin-only) |
| `/fleet/my-vehicle` | GET | Any | Returns vehicle assigned to current user |
| `/fleet/gutter-vans` | GET | Any | Active Gutter Van list for picker |
| `/fleet/metal-machines` | GET | Any | Active Metal Machine list for picker |
| `/fleet/dump-trailers` | GET | Any | Active Dump Trailer list for picker |
| `/vehicle/my-schedule` | GET | Any | Returns own schedule_type + last_inspection for overdue calc |
| `/vehicle/schedules` | GET | Admin/Manager | All active schedules |
| `/vehicle/schedule` | POST/DELETE | Admin/Manager | Set or remove a user's schedule |
| `/vehicle/mandate-inspection` | POST | Admin/Manager | Force overdue state + push user immediately |
| `/vehicle/pending-inspections` | GET | Admin/Manager | Inspections awaiting review |
| `/vehicle/inspections/:id/review` | POST | Admin/Manager | Approve/reject inspection |

**All shared vehicle endpoints** (`/fleet/gutter-vans`, `/fleet/metal-machines`, `/fleet/dump-trailers`) must SELECT `current_mileage` — omitting it causes `FleetVehicle` decode failure since `currentMileage: Double?` would be missing.

### Fleet D1 Schema

`vehicles` table. `vehicle_type` has a CHECK constraint — recreated twice via migrations:
- **migrations-fleet-v3.sql** — fixed triple-space bug (`'Company   Vehicle'` → `'Company Vehicle'`) in original CHECK
- **migrations-fleet-v4.sql** — added `'Dump Trailer'` to CHECK constraint; ran UPDATE to reclassify Dump Trailer row

Key columns: `id`, `name` (custom label), `vehicle_type`, `license_plate`, `year`, `make`, `model`, `vin`, `color`, `state`, `registration_expires`, `current_mileage`, `assigned_user_id`, `notes`, `active`, `created_at`, `updated_at`.

**Seed data:** `seed-vehicles.sql` — 27 vehicles (pool F-150s, assigned company vehicles, 3 gutter vans, 1 metal machine, 1 dump trailer, 1 dump trailer). D1 tip: use `wrangler d1 execute --file` for large INSERT files — the D1 web console and `--command` both fail for multi-row inserts.

### FleetVehicle Swift Model

Defined in `SettingsView.swift` (shared across both fleet files). Key design decisions:
- `currentMileage: Double?` — **must be optional**; D1 returns NULL for vehicles with no mileage recorded; non-optional caused silent JSON decode failure (entire decode returns nil, SwiftUI shows empty list)
- `assignedName` computed property joins `firstName`/`lastName`/`username` from LEFT JOIN on `assigned_user_id`
- `vehicleIcon` returns SF Symbol string per vehicle type

`FleetVehiclesResponse`, `MyVehicleResponse`, `VehicleDetailResponse`, `LastInspectionInfo` structs all in `SettingsView.swift`.

### VehicleListView

Groups vehicles into 4 sections (Company Vehicle / Gutter Van / Metal Machine / Dump Trailer). `vehicleDisplayTitle()` shows `"2023 Ford F-150"` (year + make + model), falling back to `name`. Each row navigates to `VehicleDetailView(vehicleId:)`.

### VehicleDetailView

Full vehicle detail + edit page. `headerCard` shows year/make/model as title; shows custom `name` as subtitle only when it differs from the derived YMM string.

**Edit mode:**
- `editRow()` has `managerEditable: Bool = false` param; field only becomes a `TextField` when `isEditing && (auth.role == "admin" || managerEditable)`
- Manager-editable fields: `Expires` (registration_expires), `Mileage` (current_mileage), `Notes`
- Admin-only: all other fields + vehicle type picker
- `AssignVehicleSheet`: filters `eligibleUsers` to `managerUsername == auth.username` for managers; Unassign button only shown for admin

### Manager Fleet Permissions (Backend Enforced)

| Action | Admin | Manager |
|--------|-------|---------|
| View vehicle list | All active | Reports' vehicles only (no pool) |
| View vehicle detail | Any | Reports' vehicles only |
| Edit fields | All | Mileage, Notes, Reg. Expires only |
| Assign vehicle | To anyone | To direct reports only |
| Unassign vehicle | Yes | Blocked (403) |
| Add/delete vehicle | Yes | No |

### Settings — Vehicle Display

`SettingsView` loads `/fleet/my-vehicle` on appear and shows a Vehicle row in the account card:
- Format: `"2023 Ford F-150 · C154755"` (year/make/model · plate)
- Falls back to `name` if year/make/model are all nil
- Only shown when `myVehicle != nil` (i.e., user has an assigned vehicle)

### Document Upload UX (2026-05-11)

`VehicleDocSection` rows each have an "Upload" button when no doc exists for that type. Tapping pre-selects the doc type and opens `VehicleDocUploadSheet`. Fixes applied:

- **Removed** the standalone "Upload" button from the DOCUMENTS section header — only per-row upload buttons remain
- **Removed** the doc type segmented picker from `VehicleDocUploadSheet` (type is always pre-selected from the tapped row; picker was redundant)
- **Sheet title** dynamically shows "Upload Insurance" or "Upload Registration"
- **`confirmationDialog` ("Choose Source")** moved from `NavigationStack` level down to the "Choose File" button — anchors correctly as a bottom action sheet inside presented sheets

### VehicleDetailView `formatDateOnly` (2026-05-11)

`formatDateOnly(_ raw: String)` now tries `yyyy-MM-dd` first, then falls back to `ISO8601DateFormatter` with `.withFractionalSeconds` — fixes ugly `2026-05-11T00:00:00.000Z` display for registration expiry dates returned as full timestamps from the API.

### Role Badge Color (2026-05-11)

`SettingsView` role row: `roleColor` is now always `accentBlue` (`#1B538F`) for all roles including "user". Previously users showed gray.

### Known Gotchas

- `currentMileage` must be `Double?` — NULL from D1 silently kills the entire `FleetVehicle` decode if non-optional
- D1 CHECK constraints can't be altered — recreate table with rename-copy-drop pattern (see v3/v4 migrations)
- `MyVehicleResponse` is defined once in `SettingsView.swift` (not private) — do not redeclare in `VehicleInspectionView.swift`
- `MyScheduleResponse` / `MyScheduleInfo` defined privately in `VehicleInspectionHubView.swift` for overdue calc
- Branch: `feature/vehicle-inspections`

## Vehicle Maintenance & Other Documents (added 2026-05-11)

### Maintenance Feature

Per-vehicle mileage-based maintenance schedules. Managers/admins add items; drivers and managers both get notified; a receipt upload completes each cycle and auto-advances the next due mileage.

**Views (in `VehicleInspectionHubView.swift`):**

| View | Role access | Purpose |
|------|------------|---------|
| `VehicleMaintenanceView` | All | List of maintenance items with status badges; + button for manager/admin |
| `MaintenanceItemDetailView` | All | Detail — interval, next due (editable by manager), last completed; upload receipt |
| `MaintenanceAddSheet` | Manager/Admin | Type picker + interval picker + auto-calculated next due; "Other" type has free-text field |
| `MaintenanceReceiptUploadSheet` | All | Upload receipt → POST to complete endpoint → advances cycle |

**Entry point:** `VehicleDetailView` → "Maintenance" nav card between Operational section and Documents section.

**Status logic (`MaintenanceItem.status`):**
- `ok` — next due > current mileage + 500
- `upcoming` — next due within 500 miles
- `overdue` — current mileage ≥ next due

**Interval presets:** 3,000 / 5,000 / 6,000 / 7,500 / 10,000 / 12,000 / 15,000 / 20,000 / 30,000 mi, plus custom.

**Auto-calculated next due:** `currentMileage + intervalMiles` on add; manager can override the field before saving.

**Completing a cycle:** POST multipart to `/fleet/vehicles/:id/maintenance/:mid/complete` with receipt file → inserts row in `vehicle_other_documents` (linked via `maintenance_id`) → advances `next_due_miles += interval_miles`, clears `upcoming_notified_at`, clears `overdue_notified_at`.

**Maintenance scheduler (`checkMaintenanceDue()` in `scheduler.js`):**
- Upcoming alert at ≤500 miles out — fires once (`upcoming_notified_at`)
- Overdue alert — fires every 3 days (`overdue_notified_at`)
- Both driver and manager notified for each alert
- Runs every 4 hours alongside `checkOverdueInspections`

**`hasMaintenanceDue` badge:** `AuthManager.hasMaintenanceDue: Bool` persists in UserDefaults (same `didSet` pattern as `isOverdue`). Set by `checkMaintenance(vehicleId:)` in the hub on launch. Fleet tab badge shows when `pendingInspectionCount > 0 || auth.isOverdue || auth.hasMaintenanceDue`. Cleared on `logout()`.

**Role-based field locking in `editRow`:** `managerEditable: Bool` and `userEditable: Bool` params. Locked fields show `.opacity(0.35)` in edit mode. Mileage and Reg. Expires are manager-editable; Notes is user-editable. Admin can edit all.

### Other Documents Feature

General document bucket per vehicle — miscellaneous uploads beyond insurance/registration. Receipts from maintenance completion land here (linked via `maintenance_id`).

**Views (in `VehicleDocumentViews.swift`):**

| View | Purpose |
|------|---------|
| `OtherDocumentsView` | List with tap-to-view, delete (manager), + upload button |
| `OtherDocUploadSheet` | Name field + file picker (camera / photos / files) |
| `OtherDocViewerSheet` | PDF or image viewer with ShareLink |

**Entry point:** `VehicleDocSection` → "Other" row at the bottom (after Registration).

**Driver upload notification:** When a driver uploads via `OtherDocUploadSheet` or completes a maintenance cycle, the API sends an APNs push to their manager: "[Name] uploaded a maintenance receipt." / "[Name] uploaded a document."

**S3 key structure:** `vehicles/{tenantId}-{tenantSlug}/{vehicleId}/other/{timestamp}_{filename}` — same bucket as inspection photos and insurance/registration docs.

### New API Routes

| Route | Method | Auth | Purpose |
|-------|--------|------|---------|
| `/fleet/vehicles/:id/maintenance` | GET | Any (own vehicle for users) | List items with status + currentMileage |
| `/fleet/vehicles/:id/maintenance` | POST | Manager/Admin | Add item |
| `/fleet/vehicles/:id/maintenance/:mid` | PUT | Manager/Admin | Edit nextDueMiles / interval |
| `/fleet/vehicles/:id/maintenance/:mid` | DELETE | Manager/Admin | Soft-delete (active = FALSE) |
| `/fleet/vehicles/:id/maintenance/:mid/complete` | POST | Any | Upload receipt → advance cycle |
| `/fleet/vehicles/:id/other-docs` | GET | Any (own vehicle for users) | List other documents |
| `/fleet/vehicles/:id/other-docs` | POST | Any | Upload document (multipart) |
| `/fleet/vehicles/:id/other-docs/:docId` | DELETE | Manager/Admin | Delete |
| `/fleet/other-docs/:docId/view` | GET | Any | S3 proxy — stream file |

### DB Tables (RDS PostgreSQL)

**`vehicle_maintenance`:** `id`, `tenant_id`, `vehicle_id`, `maintenance_type` (oil_change / tire_rotation / brake_inspection / air_filter / transmission / coolant / other), `custom_type`, `interval_miles`, `next_due_miles`, `last_completed_miles`, `last_completed_at`, `upcoming_notified_at`, `overdue_notified_at`, `created_by`, `active`.

**`vehicle_other_documents`:** `id`, `tenant_id`, `vehicle_id`, `maintenance_id` (nullable FK — set when uploaded via complete endpoint), `document_name`, `file_key`, `file_name`, `file_mime`, `uploaded_by`, `uploaded_at`.

### Notification System Fixes (2026-05-11)

**Mandate inspection persistence:** Added `mandate_pending BOOLEAN` column to `users` table. `POST /vehicle/mandate-inspection` sets it TRUE. `GET /vehicle/my-schedule` returns `mandatePending`. `checkSchedule()` in the hub converts `mandatePending` into an `isOverdue = true` state and adds a local notification — ensures delivery even if the APNs push arrived before the target user was logged in on their device.

**Daily overdue push cadence:** `last_user_notified_at` column on `vehicle_schedules`. Scheduler checks if it's been >24h since last push before re-sending. Previously sent on every 4-hour tick.

**Cross-account notification isolation:** `NotificationStore.shared.clearAll()` called in `AuthManager.logout()` — clears the UserDefaults-backed array so notifications from a previous account don't bleed into a new login.

**APNs push dedup:** `NotificationStore.add(title:body:force:Bool=false)`. Default: skips if an undismissed notification with the same title already exists. `force: true` used in both `willPresent` and `didReceive` handlers in `GunnerFormsApp.swift` so APNs pushes always land in the bell.

## Maintenance Bug Fixes & Enhancements (2026-05-11, session 11)

### Scroll Bounce Fix
`VehicleMaintenanceView` used `VStack(spacing: 0)` inside `ScrollView`. SwiftUI measures all rows on first render — if any height is indeterminate, the content offset shifts on first scroll. Fixed by switching to `LazyVStack(spacing: 0)` (rows measured on demand) and adding `.contentShape(Rectangle())` to each row button for full-width tap area.

### Maintenance Nav Card — Icon Color
`maintenanceNavSection()` used `Color.orange` for the icon background/tint. Changed to `accent` (`#059669`) to match the rest of the Fleet UI.

### Auto-Interval on Type Select
`MaintenanceAddSheet` now updates `intervalMiles` when the user changes `selectedType`, using a `recommendedIntervals` dictionary:

| Type | Recommended Interval |
|------|---------------------|
| Oil Change | 5,000 mi |
| Tire Rotation | 7,500 mi |
| Brake Inspection | 15,000 mi |
| Air Filter | 15,000 mi |
| Transmission | 30,000 mi |
| Coolant Flush | 30,000 mi |
| Other | (unchanged) |

Only applies when `useCustomInterval` is false. `updateNextDue()` is called after the interval updates.

### Quick Complete from List
`VehicleMaintenanceView` now shows an inline **"Mark Complete"** button on overdue (red) and upcoming (orange) rows. Tapping opens `MaintenanceReceiptUploadSheet` directly without navigating to `MaintenanceItemDetailView`. List reloads on sheet dismiss. Added `@State private var completeItem: MaintenanceItem?` + `.sheet(item: $completeItem)`.

### current_mileage Numeric→String Bug
`current_mileage` is `numeric` in Postgres. node-postgres returns `numeric` as a JavaScript string. Two places had string-concatenation bugs instead of addition:

1. **GET `/fleet/vehicles/:id/maintenance`** — `milesUntilDue` and `currentMileage` in response now wrapped with `parseInt(..., 10)`.
2. **POST `/fleet/vehicles/:id/maintenance/:mid/complete`** — `completedMiles + interval_miles` was `"4900" + 5000 = "49005000"`. Fixed: `parseInt(current_mileage || 0, 10)`. One corrupted record (49,005,000 mi) corrected directly in DB to 9,900 mi.

**Pattern to remember:** Any `numeric` column from Postgres through node-postgres will be a string in JavaScript. Always `parseInt` or `parseFloat` before arithmetic.

### Other Documents Row Tap Area
"Other" row in `VehicleDocSection` used `.buttonStyle(.plain)` but had no `.contentShape(Rectangle())`. Tapping the `Spacer()` whitespace between the icon and chevron did nothing. Fixed by adding `.contentShape(Rectangle())` inside the button label.

### Notifications Feature Wired Up
`NotificationsView` and `NotificationStore` existed as untracked files but were never connected. Fixed:
- Added bell icon button to `ContentView` header (between megaphone and settings gear)
- Unread badge dot on bell when `notifStore.unreadCount > 0`
- `.sheet(isPresented: $showNotifications)` presents `NotificationsView`
- `AppDelegate.userNotificationCenter(_:willPresent:)` — now calls `NotificationStore.shared.add(title:body:)` for foreground pushes
- `AppDelegate.userNotificationCenter(_:didReceive:)` — now also stores the notification before handling deep-link routing

### Vehicle Card Maintenance Tinting (VehicleListView)
`FleetVehicle` now has `maintenanceStatus: String?` (`"overdue"` / `"upcoming"` / `nil`). The `/fleet/vehicles` GET route computes it via subquery:

```sql
(SELECT CASE
   WHEN EXISTS (SELECT 1 FROM vehicle_maintenance vm
     WHERE vm.vehicle_id = v.id AND vm.active = TRUE
     AND vm.next_due_miles - v.current_mileage::numeric <= 0) THEN 'overdue'
   WHEN EXISTS (SELECT 1 FROM vehicle_maintenance vm
     WHERE vm.vehicle_id = v.id AND vm.active = TRUE
     AND vm.next_due_miles - v.current_mileage::numeric <= 500) THEN 'upcoming'
   ELSE NULL
 END) AS maintenance_status
```

`vehicleGroupSection` in `VehicleListView` tints each row via `.background(maintenanceTint(vehicle))`:
- `"overdue"` → `Color(hex: "#DD141E").opacity(0.08)` (red wash)
- `"upcoming"` → `Color.orange.opacity(0.08)` (yellow wash)
- `nil` / `"ok"` → `Color.clear`

`VStack` is clipped with `.clipShape(RoundedRectangle(cornerRadius: 16))` so tints don't bleed outside the card. Shadow on the outer `.background` modifier is unaffected.

## CompanyCam Feature (added 2026-05-12)

Integration with the internal CompanyCam instance (`companycam.dev.gunnerroofing.com/api/external/v1`). Lets field employees view their assigned jobs and take/upload job photos without leaving the app.

**Branch:** `feature/companycam-jobs` — pushed to GitHub 2026-05-12.

### Views (`CompanyCamViews.swift`)

| View | Purpose |
|------|---------|
| `JobsView` | Lists CompanyCam projects assigned to the logged-in user (matched by email) |
| `JobDetailView` | Photo gallery grouped by date, "Take Photos" button, tap-to-view full screen |
| `JobPhotoSession` | Full-screen camera + review screen; captures multiple photos, then uploads batch |
| `CCPhotoViewer` | Full-screen paged photo viewer — `TabView(.page)`, swipe between all job photos, counter, caption |
| `ZoomablePhoto` | `AsyncImage` wrapper used inside `CCPhotoViewer` — loads `src` URL falling back to `thumbUrl` |

### API Proxy (`gunnerteam-api/src/routes/companycam.js`)

All CC calls proxy through the GunnerTeam API (auth + CORS + key management):

| Route | Purpose |
|-------|---------|
| `GET /companycam/jobs` | Fetches CC projects filtered by user email |
| `GET /companycam/jobs/:jobId` | Project detail + photos |
| `POST /companycam/jobs/:jobId/photos` | Upload base64 JPEG array |

`express.json({ limit: '20mb' })` required in `app.js` — default 100KB body limit was too small for photo payloads (2.8MB+).

### Known Issue — CC Upload API Bug

The CompanyCam internal API at `companycam.dev.gunnerroofing.com` returns 400 "Bad request" for all JSON upload formats and 500 for multipart. Root cause: server-side bug in the Next.js/OpenNext/Lambda app. Not fixable from the GunnerTeam API side. iOS shows "Server error (500) — contact IT if this persists." **Requires CC app maintainer to fix.**

All upload formats were tested from EC2 via curl — JSON data URI, JSON URL, multipart with various field names, raw binary. All fail.

### Camera Layout Fix (GeometryReader)

`JobPhotoSession` body wrapped in `GeometryReader { geo in }`. The shutter button was rendering in the center of the screen on first frame because `CameraPreview` (UIViewRepresentable) reports 0 ideal size before `layoutSubviews` fires — ZStack collapses, VStack doesn't fill the screen.

Fix: `VStack { ... }.frame(width: geo.size.width, height: geo.size.height)` — forces exact screen dimensions from the first render frame instead of jumping after the first state change.

**Do not add `.ignoresSafeArea()` to the `fullScreenCover` call site** — this causes the review screen header to be cut off behind the Dynamic Island.

### Nav Bar Scroll Fix

`JobDetailView` used `.toolbarBackground(bgPrimary, for: .navigationBar)` + `.toolbarBackground(.visible, for: .navigationBar)` to prevent the nav bar from going black on scroll.

## Bug Fixes (2026-05-12)

### VehicleDocumentViews — Giant Image Viewer

Both `VehicleDocViewerSheet` and `OtherDocViewerSheet` used `ScrollView([.horizontal, .vertical])` with `Image(uiImage:).scaledToFit().frame(maxWidth: .infinity)`. In a vertical scroll view with no height constraint, SwiftUI renders the image at full native resolution (thousands of pixels tall).

**Fix:** Remove the `ScrollView`; use `.scaledToFit().frame(maxWidth: .infinity, maxHeight: .infinity)` directly. Image fits the screen correctly.

### OtherDocViewerSheet — Share as Unreadable Document

The temp file for sharing was written using `doc.documentName` (e.g. `"Oil Change Receipt"`) — no file extension. iOS couldn't determine the file type and shared it as a generic document.

**Fix:** Use `doc.fileName` (e.g. `photo_1234567890.jpg`) for the temp file path, which carries the actual extension.

## Open Items

- [x] All D1 migrations complete (2026-05-04)
- [x] APNs secrets set and push notifications working (2026-05-04)
- [x] Unique index on users.email (2026-05-04)
- [x] Duplicate email check in handleInvite — returns clean error (2026-05-04)
- [x] UTM referral system designed and confirmed working in HubSpot (2026-05-04)
- [x] User hierarchy + dept badges in UserListInline (2026-05-04)
- [x] Granular manager permissions (canEditProfile/Security/Name/Role) (2026-05-04)
- [x] Forms list scrolls from top (not vertically centered) (2026-05-04)
- [ ] **Re-invite all GunnerTeam users** — new DB is live; Tyler has admin
- [ ] HubSpot workflow — branch on `utm_source` (last name) → assign Contact Owner per salesperson
- [ ] Switch `APNS_ENV` → `production` before ABM/Hexnode deploy
- [ ] Logo redesign — Tyler doing in Photoshop
- [x] Vehicle Inspection form — step-based, 4 vehicle types, photo + mileage + damage (2026-05-05)
- [x] Fleet management hub — Manage Vehicles + Team Schedules pages (2026-05-05)
- [x] Manager fleet permissions — reports-only visibility, limited edit fields (2026-05-05)
- [x] Overdue inspection scheduler — 4h polling, user + manager push notifications (2026-05-11)
- [x] Overdue state visible in app — red banner + card styling, client-side overdue calc (2026-05-11)
- [x] Mandate inspection — manager long-press → force overdue + push (2026-05-11)
- [x] User fleet hub — all users go to Hub; "My Vehicle" card for users with assigned vehicle (2026-05-11)
- [x] User vehicle view — read-only with "Edit Notes" button; save sends only notes field (2026-05-11)
- [x] Document upload UX — removed redundant header Upload button + doc type picker (2026-05-11)
- [x] Registration expiry date — formatDateOnly handles ISO8601 timestamps (2026-05-11)
- [x] Role badge color — user role now accentBlue (not gray) in Settings (2026-05-11)
- [ ] **Switch APNS_PRODUCTION=true** before ABM/Hexnode deploy
- [ ] Test full inspection flow for each vehicle type after deploy
- [ ] Test mandate inspection push end-to-end on device
- [x] Vehicle maintenance feature — VehicleMaintenanceView, add/detail/receipt sheets (2026-05-11)
- [x] Other documents feature — OtherDocumentsView, upload/viewer sheets (2026-05-11)
- [x] Maintenance scheduler — upcoming (500mi) + overdue (3-day repeat) APNs notifications (2026-05-11)
- [x] hasMaintenanceDue badge — Fleet tab + UserDefaults persistence (2026-05-11)
- [x] mandate_pending DB column — guarantees mandate delivery across login cycles (2026-05-11)
- [x] Daily overdue push cadence — last_user_notified_at prevents every-4h spam (2026-05-11)
- [x] Cross-account notification isolation — NotificationStore.clearAll() on logout (2026-05-11)
- [x] Role-based editRow field locking — 0.35 opacity for locked fields in edit mode (2026-05-11)
- [x] Notifications bell wired up — NotificationsView + NotificationStore connected to ContentView header (2026-05-11)
- [x] Maintenance scroll bounce — LazyVStack + contentShape fix (2026-05-11)
- [x] Maintenance icon color — orange → green (2026-05-11)
- [x] Auto-interval on type select — recommendedIntervals map in MaintenanceAddSheet (2026-05-11)
- [x] Quick complete from list — inline "Mark Complete" button on overdue/upcoming rows (2026-05-11)
- [x] current_mileage numeric→string bug — parseInt in GET maintenance + complete endpoint; DB record corrected (2026-05-11)
- [x] Other docs row tap area — contentShape(Rectangle()) on "Other" row (2026-05-11)
- [x] Vehicle card maintenance tinting — yellow/red wash per maintenance_status subquery (2026-05-11)
- [x] CompanyCam jobs feature — JobsView, JobDetailView, JobPhotoSession, CCPhotoViewer built (2026-05-12)
- [ ] **CompanyCam upload API bug** — CC internal API returns 400/500 for all upload formats; requires CC app maintainer to fix
- [x] Camera shutter position — GeometryReader fix; shutter renders at bottom from first frame (2026-05-12)
- [x] Nav bar scroll black — toolbarBackground fix on JobDetailView (2026-05-12)
- [x] VehicleDocViewer giant image — removed unconstrained ScrollView; scaledToFit fills screen correctly (2026-05-12)
- [x] OtherDocViewer share extension — temp file now uses doc.fileName (with extension), not doc.documentName (2026-05-12)

## FormWebView Key Details

- **Shared WKWebView session** — `SharedWebViewConfig` singleton shares cookies; Monday login persists
- **Pull-to-refresh** — custom `UIPanGestureRecognizer`; `CGAffineTransform` slides WKWebView down; logarithmic damping
- **Soft reload vs hard reload** — `softReloadTrigger` calls `webView.reload()`; `retryID` recreates WKWebView
- **Swipe-to-go-back** — `SwipeBackEnabler` re-enables `interactivePopGestureRecognizer`
- **User agent** — spoofed to Chrome/macOS
- **Light mode forced** — `overrideUserInterfaceStyle = .light`

## Cloudflare Worker Implementation Notes

- `board_relation` column requires `{ item_ids: [parseInt(projectId)] }` — integer, not string
- `multiple_person` column requires `{ personsAndTeams: [{ id: parseInt(userId), kind: "person" }] }`
- JavaScript ASI bug: never put `return` on its own line before a function call
- Template literals spanning multiple lines caused Promise resolution errors; use string concatenation

## Related

- [[tyler/gunner-assistant/gunner-assistant]] — planned AI knowledge base tab
- [[vendors/monday]] — Monday.com GraphQL API v2024-01
- [[questions/app-store-guideline-4-8-webview-login]] — Guideline 4.8 rejection and fix
- [[questions/hexnode-custom-app-deployment]] — ABM + Hexnode custom app deployment
