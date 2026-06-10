---
type: session
title: "iOS Refactor: File Splits cc-126–147 + Photo/UI Fixes"
created: 2026-06-03
updated: 2026-06-03
tags:
  - ios
  - swift
  - refactor
  - gunnerteam
  - cc-prompts
status: evergreen
related:
  - "[[gunner/gunnerteam-project-structure]]"
  - "[[gunner/masterdb-developer-handoff]]"
---

# iOS Refactor: File Splits cc-126–147 + Photo/UI Fixes

Session covering cc-prompts 126–147. Primary theme: breaking four monolithic Swift files into focused units, then resolving the structural errors that resulted, followed by a series of UI and photo-handling bug fixes.

---

## File Splits (cc-126 – cc-133)

### cc-126 — CompanyCamViews.swift → 7 files (`b61916b`)
Split 3,747-line monolith into:
- `CCModels.swift` — data models
- `JobListView.swift` — jobs list views
- `JobDetailView.swift` — job detail + QuickLook
- `JobPhotoSessionView.swift` — camera session + photo library
- `CCPhotoViewerView.swift` — full-screen photo viewer
- `CCCommentsView.swift` — photo/job comments
- `FullScreenVideoView.swift` — full-screen video player

### cc-127 — VehicleInspectionHubView.swift → 6 files (`1bb97a8`)
Split 3,687-line file. Key complication: `// MARK: - Private Response Types` section had response structs used by multiple destination files — `private` removed from moved types.

### cc-128 — PhaseWorkflowViews.swift → 5 files (`e009752`)
- `JobGuidedView.swift`, `PhaseDetailView.swift`, `PhaseChangeOrderView.swift`, `PhaseItemSheets.swift`, `PhotoMarkupEditor.swift`

### cc-129 — GuidedTasksView.swift → 4 files (`177a535`)
- `GunnerTaskModels.swift` (models + all free network functions), `JobModeSelectionView.swift` (+HeroImageLoader), `GuidedTasksView.swift` (trimmed), `TaskSheetsView.swift`

### cc-130 — VehicleInspectionView.swift → 2 files (`ac18172`)
- Kept: Types + Main View
- New: `CameraSessionComponents.swift` — InspectionCameraSession, SingleImageLibraryPicker, camera model

### cc-131 — iOS File Structure Rules added to CLAUDE.md (`6d9eaf9`)
600-line signal (not hard cap), one-primary-view-per-file rule, models/network in `*Models.swift`, 5+ MARK = split trigger, naming conventions, `private` scope rules on splits.

### cc-132 — Softened 600-line cap (`caa9d1f`)
Reframed as "split on mixed concerns, not line count." Real triggers: 2+ unrelated primary views, models in view file, 5+ MARK sections covering different features.

### cc-133 — Folder reorganization (`c4d1627`)
Created `Jobs/`, `Photos/`, `Fleet/` folders under `GunnerTeam/`. `Forms/` now contains only the 4 Monday.com submission views. `APIConfig.swift` moved to `App/`. 27 files renamed — zero insertions/deletions (Xcode File System Synchronized Groups picks this up automatically).

---

## Post-Split Structural Fixes (cc-134 – cc-137)

### cc-134 — Fleet file content errors (`9d5d952`)
cc-127 Python split had off-by-one ranges causing:
- `VehicleMaintenanceViews.swift`: duplicate partial `struct MaintenanceItem` opening (no body), duplicate MARK, incomplete `MyScheduleInfo` stub at EOF
- `TeamSchedulesView.swift`: stray `// MARK: - Add Vehicle Sheet`, incomplete `MaintenanceListResponse` stub at EOF
- `VehicleListViews.swift`: stray Team Schedules MARK, duplicate Assign Vehicle Sheet MARK, stray Inspection Reports/Response Types MARKs, incomplete `HubSchedulesResponse` stub at EOF
- `VehicleInspectionReviewView.swift`: duplicate `inspectionStatusInfo` signature (empty first copy)

Fix: Python `patch()` helper with deletion ranges applied atomically across all 4 files.

### cc-135 — CLAUDE.md lesson: file split boundary (`a58da61`)
Added to `## Learned from mistakes`: specify types by name, not line ranges. MARK headers are the boundary. Verify first/last line of each moved block before committing.

### cc-136 — Missing imports + ZoomablePhoto conflict (`fa21553`)
- `Jobs/JobModeSelectionView.swift`: `import Combine` (HeroImageLoader uses @Published)
- `Photos/JobPhotoSessionView.swift`: `import Combine` (CCCameraModel/CCDualCameraModel)
- `Fleet/InspectionReportsView.swift`: `ZoomablePhoto` → `InspectionZoomablePhoto` (conflict with `CCPhotoViewerView.swift`)

### cc-137 — Visibility fix for shared Fleet helpers (`511388d`)
`inspectionStatusInfo` and `PhotoURLWrapper` were `private` in `VehicleInspectionReviewView.swift` but used by `InspectionReportsView.swift`. Removed `private` → internal.

---

## UI Fixes (cc-138 – cc-141)

### cc-138 — Single mode toggle button + opaque manual background (`dd652a0`)
- Replaced two-button guided/manual HStack with single toggle (icon shows destination mode)
- UIImpactFeedbackGenerator(.light) on tap
- Manual hero scrim: `0.65 → 0.88`

### cc-139 — Hide duplicate header + light surface in embedded manual view (`a6af712`)
- `JobDetailView` header (name/address) wrapped in `if !embedded` — no duplicate in manual mode
- ZStack background: `else { Rectangle().fill(.regularMaterial) }` for embedded mode (added in cc-141)
- Tab bar background: transparent when embedded
- Take Photos button: adjusted padding when embedded
- Manual hero scrim: `0.88 → 0.45` (white panel handles readability)

### cc-140/141 — Panel opacity tuning → regularMaterial (`817fe2a`)
`Color.white.opacity(0.93)` → `0.82` → replaced with `Rectangle().fill(.regularMaterial)` for correct dark/light mode adaptation (frosted glass).

---

## Photo Markup Toolbar Fixes (cc-142 – cc-144)

### cc-142 — safeAreaInset approach (`bea2e48`)
Removed `VStack` wrapper from `PhotoMarkupEditor`; moved toolbar to `.safeAreaInset(edge: .bottom)` on ZStack. Stray VStack closing brace required secondary cleanup.

### cc-144 — Native .bottomBar placement (`852c6bb`)
`safeAreaInset` still misaligned (ZStack's ignoresSafeArea content gave inset closure wrong width). Fixed by moving all drawing tools into `.toolbar` with `.bottomBar` placement. Used 9 individual `ToolbarItem` entries (not `ForEach` inside `ToolbarItemGroup` — known rendering issue). Added `colorButton(_:)` private helper.

---

## Photo + Task Fixes (cc-143 – cc-147)

### cc-143 — Photo viewer opens wrong photo after upload (`202f61e`)
- `allPhotos` changed from `let` to `var` in `CCPhotoViewer`
- Init: if tapped photo not in allPhotos (upload still indexing), prepend it → always correct
- `loadDetail()` after camera dismiss delayed 1.5s (`Task.sleep(1_500_000_000)`) to let API index upload

### cc-145 — Disable photo taps during refresh (`8c7fa8f`)
- Added `@State private var isRefreshing = false`
- `loadDetail()` sets `isRefreshing = true` on entry, clears on all exit paths
- Photo grid buttons `.disabled(isRefreshing)`

### cc-146 — Black photo + required/highAlert + createdAt (`6e076b8`)
- `UIImage.normalised()` extension: redraws into fresh context when `imageOrientation != .up`
- `FieldTaskLocalPhotoStore.save` normalises before jpegData
- `PhotoMarkupEditor.renderComposite` normalises source before drawing
- `CreatePhotoTaskSheet` gains Required + High Alert toggles; `onCreate` closure is now `(String, String?, Bool, Bool) -> Void`
- `createPhotoFieldTask` accepts and forwards `required`/`highAlert`
- `GunnerTask` gains `let createdAt: String?`; `GunnerTaskRow` shows relative timestamp

### cc-147 — createdAt in TaskDetailSheet (`5e3bc5d`)
`createdLabel` computed var (mirrors `dateLabel`); "Created" Section shown before "Completed" in the detail List.

---

## Key Patterns Established

**File split workflow (correct approach):**
1. `grep -n "^// MARK:"` to map boundaries
2. Confirm exact start/end lines by reading surrounding context
3. In Python: slice `lines[start:end]` with MARK comment as first line of each file
4. Verify `body[0]` and `body[-1]` before writing
5. Parallel `write_file` calls; then `git rm` original

**Python split off-by-one lesson:** When adjacent sections share a boundary line (e.g. the last line of one MARK range IS the first line of the next struct), overlap occurs. Always verify each file starts with its own MARK comment and ends with the correct struct's closing brace.

**SwiftUI `private` scope:** `private` at file scope = fileprivate. When splitting a file, types used across files must drop `private`.

**`UIImage` orientation:** Camera captures often have `imageOrientation != .up`. Normalise before any JPEG encode or draw operation.

**`.bottomBar` toolbar:** `ForEach` inside `ToolbarItemGroup(.bottomBar)` may not render all items. Use individual `ToolbarItem` entries. `safeAreaInset` receives incorrect width proposals when its parent has `ignoresSafeArea` content.

**regularMaterial:** iOS adaptive material surface for embedded views — handles dark/light mode automatically, no custom color scheme logic needed.

---

## Commits This Session
| Commit | Description |
|--------|-------------|
| `b61916b` | cc-126: CompanyCamViews → 7 files |
| `1bb97a8` | cc-127: VehicleInspectionHubView → 6 files |
| `e009752` | cc-128: PhaseWorkflowViews → 5 files |
| `177a535` | cc-129: GuidedTasksView → 4 files |
| `ac18172` | cc-130: VehicleInspectionView → 2 files |
| `6d9eaf9` | cc-131: iOS file structure rules in CLAUDE.md |
| `caa9d1f` | cc-132: Soften 600-line cap |
| `c4d1627` | cc-133: Folder reorganization (Jobs/Photos/Fleet) |
| `9d5d952` | cc-134: Fleet split structural fixes |
| `a58da61` | cc-135: File split boundary lesson in CLAUDE.md |
| `fa21553` | cc-136: Missing Combine imports + ZoomablePhoto rename |
| `511388d` | cc-137: inspectionStatusInfo/PhotoURLWrapper visibility |
| `dd652a0` | cc-138: Single mode toggle + opaque manual background |
| `a6af712` | cc-139: Hide duplicate header + light surface |
| `bef6673` | cc-140: Panel opacity 0.93→0.82 |
| `817fe2a` | cc-141: regularMaterial for embedded panel |
| `bea2e48` | cc-142: Markup toolbar safeAreaInset |
| `852c6bb` | cc-144: Markup toolbar .bottomBar native placement |
| `202f61e` | cc-143: Photo viewer correct photo + upload delay |
| `8c7fa8f` | cc-145: Disable photo taps during refresh |
| `6e076b8` | cc-146: Photo orientation, required/highAlert, createdAt |
| `5e3bc5d` | cc-147: createdAt in TaskDetailSheet |
