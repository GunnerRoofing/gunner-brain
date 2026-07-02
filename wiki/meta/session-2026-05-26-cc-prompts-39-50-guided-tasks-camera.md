---
type: session
title: "cc-prompts 39–50: Guided Tasks Camera System Rebuild"
created: 2026-05-26
updated: 2026-05-26
tags:
  - ios
  - guided-tasks
  - camera
  - uiimagepickercontroller
  - companycam
  - checkbox
status: stable
related:
  - "[[tyler/gunnerteam/gunnerteam-project-structure]]"
  - "[[meta/session-2026-05-26-dual-camera-avassetwriter-crash-fix]]"
---

# cc-prompts 39–50: Guided Tasks Camera System Rebuild

Long session rebuilding the entire camera flow for photo_single and photo_multi guided tasks, fixing the shutter position problem definitively via UIImagePickerController + custom overlay, adding haptics, and shipping the checkbox task type.

---

## Final Architecture (end state)

### Camera path (photo_single + photo_multi)

Both task types flow through a single shared state set in `GuidedTasksView`:

```swift
@State private var cameraTask:        GunnerTask? = nil
@State private var cameraSteps:       [GunnerTaskStep] = []
@State private var showCameraSession: Bool = false
@State private var sessionToken:      String = ""
```

`.fullScreenCover(isPresented: $showCameraSession)` presents `GuidedTaskCameraSession`.

**photo_single**: synthesizes one `GunnerTaskStep(id: task.id, label: task.title, order: 0, required: true)` and passes `subtitle: task.description`.

**photo_multi**: uses `task.steps?.sorted { $0.order < $1.order }`.

### GuidedTaskCameraSession

Thin SwiftUI view — manages step state, upload, advance logic. Delegates all camera UI to `GuidedCameraPickerView`.

```swift
struct GuidedTaskCameraSession: View {
    let steps:      [GunnerTaskStep]
    let subtitle:   String?           // shown below label for single-step (photo_single)
    let jobId:      String
    let token:      String
    let onComplete: () -> Void
    let onError:    (String) -> Void
}
```

`body` is just `GuidedCameraPickerView(...)`.ignoresSafeArea()`.

Completion logic: `advance()` checks `currentIndex >= steps.count || requiredDone` then calls `onComplete(); dismiss()` after 0.25s delay.

### GuidedCameraPickerView (UIViewControllerRepresentable)

```swift
picker.sourceType = .camera
picker.allowsEditing = false
picker.showsCameraControls = false   // no default UIKit controls, no video button
picker.delegate = context.coordinator
picker.cameraOverlayView = hostingController.view
```

`cameraOverlayView` is a `UIHostingController<GuidedCameraOverlay>`.

Frame set via UIWindowScene (no deprecated `UIScreen.main`):
```swift
hc.view.frame = (UIApplication.shared.connectedScenes
    .first { $0.activationState == .foregroundActive } as? UIWindowScene)?
    .screen.bounds ?? .zero
hc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
```

`updateUIViewController` rebuilds overlay root when `isUploading`, `stepLabel`, or `stepProgress` changes.

### GuidedCameraOverlay (SwiftUI View)

Full-screen overlay with `.ignoresSafeArea()`. Two visual regions:

**Top** — frosted pill: `stepProgress` (e.g. "2 / 3") + `stepLabel` + `stepSubtitle`. Dark background, 60pt from top.

**Bottom** — at 48pt from screen bottom:
- X button (left) — calls `onCancel()`
- Shutter circle (center) — calls `onCapture()` + `.heavy` haptic; shows `ProgressView` while `isUploading`
- Balance spacer (right)

---

## Why UIImagePickerController (not AVFoundation)

`GuidedTaskCameraSession` was originally a pure AVFoundation view (cc-41), copying `InspectionCameraSession` exactly. The shutter button was persistently in the wrong position despite multiple layout fixes:

- cc-43: `.frame(maxWidth: .infinity, maxHeight: .infinity)` on VStack
- cc-45: `.ignoresSafeArea()` on VStack inside ZStack

Root cause: `GuidedTaskCameraSession` is presented inside `if let task = cameraTask { ... }` in the `fullScreenCover`. SwiftUI wraps this `if let` in `ConditionalContent`, breaking safe-area propagation from the call-site `.ignoresSafeArea()`. The `Spacer()` inside the VStack couldn't expand to the physical screen bottom regardless of modifiers applied.

**Fix (cc-46)**: `UIImagePickerController.cameraOverlayView` is positioned against UIWindowScene screen bounds — absolute UIKit coordinates, completely outside SwiftUI layout. Shutter position is guaranteed.

---

## Photo_single Subtitle (cc-47)

`GuidedTaskCameraSession` gained `let subtitle: String? = nil`. In `GuidedCameraPickerView.makeOverlay(for:)`, `stepSubtitle: steps.count == 1 ? subtitle : nil` — only shows for single-step tasks. Multi-step photo tasks don't have per-step descriptions in the current schema.

---

## Haptic Feedback Map

| Trigger | Call |
|---|---|
| Task row tap | `.medium` impact |
| Camera shutter | `.heavy` impact |
| Step advance after upload | `.light` impact |
| PATCH success | `.success` notification |
| Upload or PATCH failure | `.error` notification |
| Back button | `.light` impact |
| FormTaskSheet submit | `.medium` impact |
| CheckboxTaskSheet row toggle | `.medium` impact |
| CheckboxTaskSheet Done | `.medium` impact |
| CheckboxTaskSheet Cancel | `.light` impact |

---

## CheckboxTaskSheet (cc-50)

`GunnerTaskStep` is reused for checkbox steps — no new model needed. `handleTaskTap .checkbox` opens `CheckboxTaskSheet` when `task.steps` is non-empty; falls back to immediate `completeTask` for step-less checkboxes.

```swift
struct CheckboxTaskSheet: View {
    let task: GunnerTask
    let onComplete: () async -> Void  // non-throwing; errors handled by completeTask
```

`allRequiredChecked` = `steps.filter(\.required).allSatisfy { checked.contains($0.id) }`.

Done button disabled until `allRequiredChecked`. On tap: calls `await onComplete()` → `.success` notification → `dismiss()`. Errors surface as toasts from `completeTask` internally; sheet always dismisses.

Optional steps show "Optional" caption. `GunnerTaskRow` icon for `.checkbox` changed to `"checklist"`.

---

## Backend Fix: audit_log org_id (cc-45)

**Bug:** `PATCH /companycam/jobs/:jobId/tasks/:taskId` crashed with `null value in column "org_id" violates not-null constraint`.

**Root cause:** `resolveUser()` in `auth.js` returns `{ id, username, email, firstName, lastName, role, orgSlug }` — no `orgId`. The middleware sets `req.orgId` (not `req.user.orgId`). The audit_log INSERT used `req.user.orgId` which was always `undefined`.

**Fix:** `req.user.orgId` → `req.orgId` in `companycam.js` line 513.

---

## Branch Merge Summary (cc-49)

Merged into main via `--no-ff`:
- `fix/camera-shutter-position` — VStack frame fix
- `feat/haptics` — haptic feedback
- `fix/shutter-and-save` — patchTask diagnostics + audit_log fix
- `fix/camera-custom-controls` — UIImagePickerController overlay
- `fix/photo-single-guided-overlay` — subtitle param

Skipped: `forms-quick-fix-2026-05` (production branch, never touch).

---

## Key File

`GunnerForms/GunnerTeam/Forms/GuidedTasksView.swift` — all guided tasks logic. All structs (`GuidedTaskCameraSession`, `GuidedCameraPickerView`, `GuidedCameraOverlay`, `CheckboxTaskSheet`, `FormTaskSheet`, `GunnerTaskRow`) live in one file. `CameraModel`/`CameraPreview` (AVFoundation) stay in `VehicleInspectionView.swift`; guided tasks uses `UIImagePickerController` only.
