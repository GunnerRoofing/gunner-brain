---
type: session
title: "cc-prompts 82–86: Guided Tasks Feature Complete + OMP 15.8.0"
created: 2026-06-02
updated: 2026-06-02
tags:
  - gunnerteam
  - ios
  - guided-tasks
  - omp
status: stable
related:
  - "[[meta/session-2026-06-02-cc76-80-notion-workspace-soc2-fixes]]"
  - "[[meta/session-2026-05-27-cc38-45-cc69-75-fleet-perf-webhooks]]"
---

# cc-prompts 82–86: Guided Tasks Feature Complete + OMP 15.8.0

---

## cc-prompt-82: High-Alert Tasks

**File:** `GuidedTasksView.swift`

### GunnerTask model
```swift
let highAlert: Bool?   // nil-safe — nil treated as false until Colin deploys the field
// CodingKeys updated to include highAlert
```

### Sort: high-alert pending tasks bubble to top
```swift
return response.tasks.sorted { a, b in
    let aHigh = a.highAlert == true && a.status == .pending
    let bHigh = b.highAlert == true && b.status == .pending
    if aHigh != bHigh { return aHigh }
    return (a.order ?? 0) < (b.order ?? 0)
}
```

### GunnerTaskRow
- Circle fill → `Color.red.opacity(0.25)` when `highAlert && !complete`
- `exclamationmark.triangle.fill` badge in title HStack before the Required badge

### GuidedTasksView
- `hasBlockingHighAlert` computed var: `tasks.contains { $0.highAlert == true && $0.status == .pending }`
- Red full-width banner between progress header and task list when any high-alert task is pending

---

## cc-prompt-83: Guided Jobs List + Mode Toggle in JobsView

**File:** `CompanyCamViews.swift`

### JobsView changes
- `@AppStorage("jobsViewMode") private var guidedMode: Bool = true` — persists per device, default guided
- Segmented `Picker` in trailing toolbar: `list.bullet.clipboard` (guided) vs `square.grid.2x2` (manual)
- Guided branch → `GuidedJobsListView`; manual branch → existing rows, destination now `JobDetailView` (skips `JobModeSelectionView`)

### GuidedJobsListView
- Wraps `GuidedJobRow` in `LazyVStack`
- Task lazy-fetch on first expand, cached in `[String: [GunnerTask]]`
- No redundant fetches on collapse/re-expand

### GuidedJobRow
- `@StateObject private var heroLoader = HeroImageLoader()` — per-row thumbnail
- Header: thumbnail + job name + address + `done/total tasks` badge (green when all done)
- Right side: `chevron.right.circle` → `GuidedTasksView`; expand/collapse chevron → inline checklist
- Inline checklist: read-only `circle`/`checkmark.circle.fill` + `exclamationmark.triangle.fill` for `highAlert` pending

---

## cc-prompt-84: List/Grid Toggle in GuidedTasksView

**File:** `GuidedTasksView.swift`

### State
```swift
@AppStorage("guidedTasksGridMode") private var showGrid: Bool = false  // default list
```

### Overlay
Replaced `.overlay(alignment: .topLeading)` (single back button) with `.overlay(alignment: .top)` HStack:
- Back button (left, `.padding(.leading, 20)`)
- `Spacer()`
- Grid/list toggle button (right, `.padding(.trailing, 20)`) — `square.grid.3x3` ↔ `list.bullet`
- `.padding(.top, 8)` — matches original back button padding

### Task list branch
- `showGrid` → 3-column `LazyVGrid` with `GunnerTaskGridCell`
- else → existing `LazyVStack` with `GunnerTaskRow`

### GunnerTaskGridCell
- Icon circle (red tint for high-alert), `exclamationmark.triangle.fill` badge offset `(x: 4, y: -4)` to top-right corner
- Title (2-line caption), Required pill
- Same `handleTaskTap` path, `.disabled(task.status == .complete && !task.isUncheckable)`, 0.55 opacity when done

---

## cc-prompt-86: Task Detail Sheet, Unchecking, Pinned Progress Bar

**File:** `GuidedTasksView.swift`

### Pinned progress bar
Progress header moved OUT of `ScrollView`. Structure is now:
```
VStack(spacing: 0) {
    Color.clear.frame(height: 64)   // spacer under overlay buttons (56 + 8)
    VStack(spacing: 8) { … }        // progress header — PINNED
    .background(.ultraThinMaterial)
    ScrollView { … }                // task list — scrollable
}
```

### GunnerTask.isUncheckable extension
```swift
var isUncheckable: Bool {
    switch type {
    case .checkbox, .text, .form: return true
    default: return false  // photo tasks stay locked — uploads aren't reversed
    }
}
```

### uncompleteTask
- Optimistic PATCH to `"pending"`, reverts on failure with error haptic + toast

### handleTaskTap routing
| Condition | Action |
|-----------|--------|
| `complete && isUncheckable` | `detailTask = task` (opens TaskDetailSheet in uncheck mode) |
| checkbox + no steps + pending | `detailTask = task` (opens TaskDetailSheet for confirm) |
| checkbox + steps | `checkboxTask` (CheckboxTaskSheet, unchanged) |
| text/form + pending | `selectedFormTask` (FormTaskSheet, unchanged) |
| photo | camera session (unchanged) |

### .disabled predicate updated
```swift
.disabled(task.status == .complete && !task.isUncheckable)
// Photo tasks stay locked; checkbox/text/form tappable when complete
```

### TaskDetailSheet
- Cancel + "Uncheck" (red) or "Mark Complete" (bold) in toolbar
- Sections: description (if present), completed by + date (when complete), highAlert + required badges
- `dateLabel` parses `completedAt` ISO8601 → formatted `DateFormatter` string

### CheckboxTaskSheet
- Description section added above step list

---

## cc-prompt-85: In-App Task Creation (iOS + Backend)

**Backend:** `gunnerteam-api/src/routes/companycam.js`

```js
// POST /companycam/jobs/:jobId/tasks
// Validates title (required, non-empty string) and type (VALID_TYPES whitelist)
// Proxies to Colin's POST /api/external/v1/projects/:jobId/tasks
// Audit log INSERT on success (SOC 2 CC6.1)
```

**iOS:** `GuidedTasksView.swift`

- `GunnerTaskCreateBody` Codable struct
- `createTask()` function: POST to `/companycam/jobs/:jobId/tasks`, expects 201, decodes `GunnerTask`
- `@State private var showCreateTask = false`
- `+` button added to overlay HStack (between Spacer and grid toggle)
- `.sheet(isPresented: $showCreateTask)` — post-create: append + re-sort (highAlert pending first)
- `CreateTaskSheet`: title field, description (optional, multi-line), type picker (checkbox/text/photoSingle), Required toggle, High Alert toggle with footer copy
  - `photo_multi` excluded — requires `steps[]` Colin creates from web UI
  - Add button disabled until title is non-empty

**Deployed:** v108 (also includes cc-79, cc-80, cc-81 changes from prior session).

---

## OMP 15.5.6 → 15.8.0

Updated via `omp update`. Clean upgrade.

**pi-powerline-footer re-appeared** — OMP update pulled `pi-powerline-footer@0.5.6` back in (was permanently uninstalled in cc-68). Caused OMP to hang on startup. Fixed by:
1. Removing from `~/.omp/plugins/omp-plugins.lock.json` (`plugins` array)
2. Removing from `~/.omp/plugins/package.json` (`dependencies`)
3. `rm -rf ~/.omp/plugins/node_modules/pi-powerline-footer`

**Note for future updates:** After any `omp update`, check that `pi-powerline-footer` hasn't re-appeared in `package.json`. If it has, remove it from all three locations.

---

## Git State

| Commit | Description |
|--------|-------------|
| `5470ab8` | cc-82: high-alert tasks |
| `793b149` | cc-83: guided jobs list + mode toggle |
| `0dac1f8` | cc-84: list/grid toggle |
| `704cf09` | cc-86: task detail sheet, unchecking, pinned progress bar |
| `b25589d` | cc-85: in-app task creation |

All pushed to `main`. Lambda v108 live.
