---
type: session
owner: tyler
created: 2026-06-11
updated: 2026-06-11
tags: [gunnerteam, ios, ux, aux, shared-components]
status: complete
related:
  - "[[tyler/hot.md]]"
  - "[[tyler/Memory.md]]"
---

# cc-403–412: Shared AuxComponents + Aux Screen UX Sprint

**Session date:** 2026-06-11 (sixth session)
**Lambda:** v175 unchanged (no backend changes)
**iOS:** BUILD SUCCEEDED throughout (warnings fixed)
**OMP:** updated to 15.11.8

---

## Shared Components (cc-403)

`Theme/AuxComponents.swift` created with:
- `StatusBadge` — icon + label + color capsule; semantic factory methods: `.pass()`, `.fail()`, `.needsWork()`, `.role()`, `.dept()`, `.assignee()`, `.pool()`, `.yours()`, `.overdue()`, `.upcoming()`, `.docsExpired()`, `.docsExpiring()`, `.inspectionStatus()`
- `EmptyStateView` — icon + title + message + optional CTA button
- `StickyEditBar` — Save/Cancel as `.safeAreaInset(edge: .bottom)`; `.light` haptic on Cancel, `.medium` on Save
- `DestructiveConfirmSheet` — `.standard` or `.typeToConfirm` variants; `.warning` haptic on confirm
- Haptic reference comment block at top

## Fleet UX (cc-404–406)

### cc-404 — VehicleListView: search + StatusBadge rows
- `@State private var searchQuery` + `filteredGrouped` computed property
- `.searchable(text: $searchQuery, prompt: ...)` on ScrollView
- `vehicleGroupSection` redesigned: 4pt `appPrimary` left accent bar for "my vehicle", `StatusBadge.yours()`/`assignee()`/`pool()`/`docsExpired()`/`docsExpiring()`/`overdue()`/`upcoming()`
- `maintenanceTint` background removed (status via badge only)
- `EmptyStateView` for empty fleet + empty search
- Row tap fires `.light` haptic via `.simultaneousGesture`

### cc-405 — InspectionReportsListView + PersonInspectionHistoryView
- `InspectionReportsListView`: search, `StatusBadge.inspectionStatus()`, `EmptyStateView` for empty list + empty search
- `PersonInspectionHistoryView`: period filter fires `UISelectionFeedbackGenerator`, inspection rows use `StatusBadge.inspectionStatus()` + `statusColor()` for border, `EmptyStateView` for empty period
- `statusBadge`/`statusPill`/`inspectionStatusInfo` helpers removed

### cc-406 — VehicleDetailView: VehicleDraft + StickyEditBar + DestructiveConfirmSheet
- `VehicleDraft` struct: 12 field snapshot, `validatePlate()`/`validateYear()`, `isValid` computed
- 12 `@State private var edit*` + `isEditing` + 3 delete state vars → `draft: VehicleDraft?` + `showDeleteConfirm`
- `StickyEditBar` as `.safeAreaInset`; toolbar simplified to pencil-only when `draft == nil`
- `editRow`: `@ViewBuilder`, `field: Binding<String>?` optional (nil = read-only, dimmed 0.35), error text
- `DestructiveConfirmSheet` naming the plate
- `save()`: `.success`/`.error` haptics; `draft = nil` on success

## Inspection + Reports (cc-408)

`InspectionHistoryDetailView`:
- Review card uses `StatusBadge.inspectionStatus()` (not hand-rolled capsule)
- `anyDamage` row uses `damageBadge()` helper: "Damage reported" amber / "No damage" green
- Photo tile: `.contentShape(Rectangle())` + `.light` haptic on tap

## Settings (cc-407, cc-409)

### cc-407 — UserDetailView: read-only header + StickyEditBar + role confirm + DestructiveConfirmSheet
- `profileHeaderCard`: initials avatar, name, username, `StatusBadge.role()`/`dept()`
- `profileSection` split: read mode (static rows + "Edit Profile" tap) / edit mode (styled fields)
- `StickyEditBar` as `.safeAreaInset`
- Role chip tap → `confirmationDialog` naming the person before `setRole()`
- `deleteSection` → `DestructiveConfirmSheet` with `typeToConfirm` (username)
- `profileSaved`/`confirmDelete`/`deleteError` removed

### cc-409 — SettingsView: accordion → NavigationLink + sheet
- "Invite User" accordion → sheet (`InviteUserSheet`) with title + Done button
- "Manage Users" accordion → `NavigationLink` → `UserListView` (searchable by name/username/email/dept)
- `navRow` helper added (chevron-right style row)
- `UserListInline` badges → `StatusBadge.role()`/`dept()`/`yours()`; `roleBadgeColor`/`roleBadgeLabel`/`deptBadgeColor` deleted
- Row tap fires `.light` haptic via `.simultaneousGesture`

## Announcements (cc-410)

`ComposeAnnouncementView`:
- Auto-focuses title field on appear (`.onAppear { composeFocus = .title }`)
- Both fields: `appPrimary.opacity(0.08)` fill + 1.5pt border
- Message field: placeholder text overlay
- Post moved from toolbar to `safeAreaInset` bottom bar (56pt)
- `canSubmit` now title-only (body optional)
- Cancel: `.light`; Post: `.medium` + `.success`

## Fleet Add Vehicle (cc-411)

`AddVehicleSheet`:
- `AddField` enum + `@FocusState` chain (Name→Plate→Year→Make→Model→Color→VIN)
- Auto-focuses Name on appear
- All fields: `appPrimary.opacity(0.08)` fill + 1.5pt border; red border + error text on validation failure
- `validatePlate()` / `validateYear()` with inline error display
- Save: validates first; `.error` haptic on failure; `.medium` on valid tap; `.success`/`.error` on server response
- Vehicle type picker change fires `UISelectionFeedbackGenerator`
- Button 56pt tall, disabled until Name non-empty + no validation errors

## Notifications (cc-412)

`NotificationsView`:
- `NotifGroup` struct: collapses duplicates by `(title, body)` key
- `×N` count badge + "Latest Xh ago" timestamp for grouped rows
- Dismiss fires `.light` haptic + dismisses all matching notifications in group
- Empty state → `EmptyStateView` ("You're all caught up.")
- `notifSection`/`notifRow` replaced by `notifGroupSection`/`notifGroupRow`

---

## Key Patterns This Session

**`Color.appPrimaryMuted`** — does NOT exist. Use `Color.appPrimary.opacity(0.08)` everywhere the prompt says `appPrimaryMuted`.

**`@FocusState` in helper functions** — `@FocusState private var focus: FieldEnum?` must be declared as a stored property on the struct. Helper `func inputRow(...)` can reference `$focus` and `focus` as long as it's a method on the same struct (not a free function).

**`enum AddField: Hashable`** inside a View struct must NOT be `private` if used as a parameter type in any `func` — use internal (no access modifier) to avoid "method must be declared private because its parameter uses a private type".

**`DestructiveConfirmSheet` button text** — "Keep" is the cancel label (not "Cancel") to avoid competing with the dismiss gesture.

**`NotifGroup` nested inside NotificationsView** — nested struct avoids top-level naming conflicts.
