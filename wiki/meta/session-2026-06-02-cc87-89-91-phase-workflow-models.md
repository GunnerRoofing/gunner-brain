---
type: session
title: "cc-prompts 87, 89-91: Phase Workflow Data Layer + Completed Tasks View"
created: 2026-06-02
updated: 2026-06-02
tags:
  - gunnerteam
  - ios
  - phase-workflow
  - guided-tasks
  - omp
status: stable
related:
  - "[[meta/session-2026-06-02-cc82-86-guided-tasks-complete]]"
  - "[[meta/lint-report-2026-06-02]]"
---

# cc-prompts 87, 89–91: Phase Workflow Data Layer + Completed Tasks View

---

## cc-prompt-87: Pending-Only View + Completed Tasks Sheet

**File:** `GuidedTasksView.swift` | Commit: `5848f42`

### New computed vars
```swift
private var pendingTasks:   [GunnerTask] { tasks.filter { $0.status == .pending } }
private var completedTasks: [GunnerTask] { tasks.filter { $0.status == .complete } }
```

### Changes
- Both `ForEach` calls (list + grid branches) now iterate `pendingTasks` — completed items removed from the work list
- Progress header: `"\(pendingTasks.count) remaining"` (denominator still `tasks.count` for %)
- Empty state forks on `pendingTasks.isEmpty`: “All tasks complete!” with green `checkmark.circle.fill` when done; original “No tasks yet” when truly empty
- Completed capsule button in overlay HStack (conditional on `!completedTasks.isEmpty`), between `+` and grid toggle
- `.sheet(isPresented: $showCompleted)` → `CompletedTasksSheet`

### CompletedTasksSheet
- Lists all completed tasks with `checkmark.circle.fill`, `completedByEmail`, formatted date
- “Uncheck” button visible only for `task.isUncheckable` tasks (dispatches `uncompleteTask`)
- Photo tasks show no Uncheck button
- “Done” cancel button in toolbar

---

## cc-prompt-89: PhaseWorkflowModels.swift (New File)

**File:** `PhaseWorkflowModels.swift` (new, 343 lines) | Commit: `41ac7e1`

Pure data layer — no UI. All Codable structs and async network functions for the phase workflow.

### Enums
- `GunnerPhaseType` (.preInstall / .projectStart / .inProgress / .closeOut / .changeOrder / .upsell / .unknown) with `displayName` and `systemImage`
- `GunnerPhaseStatus` (.locked / .active / .complete)
- `GunnerPhaseItemType` (.photoSingle / .photoMulti / .photoFlagged / .text / .checkbox / .measurement / .signature / .unknown) with `systemImage`
- `GunnerPhaseItemStatus` (.pending / .complete)
- `GunnerChangeOrderStatus` (.draft / .signed / .void)

### Models
- `GunnerPhaseItemPhoto`: id, url, thumbUrl
- `GunnerPhaseItem`: full item with photos[], notes, flagged, value, steps reusing `GunnerTaskStep`
- `GunnerPhaseSection`: id, phaseId, title, order, items
- `GunnerPhase`: with computed `requiredItems`, `completedRequiredCount`, `canComplete`
- `GunnerChangeOrder`: uses `GunnerPhaseSection` for its sections
- Request/response bodies: `GunnerPhaseItemPatchBody`, `GunnerPhasePatchBody`, `GunnerPhaseCompleteError`, `GunnerPhasePatchResponse`
- `PhaseCompleteBlockedError: Error` with `incompleteItemIds: [String]`

### Network functions
- `uploadPhaseItemPhoto` — presign → S3 PUT → confirm; **returns `s3Key: String`** (unlike `uploadTaskPhoto` which returns `Void`)
- `fetchPhases(jobId:token:)` → `[GunnerPhase]` sorted by order
- `patchPhaseItem(jobId:phaseId:itemId:body:token:)` → `GunnerPhaseItem`
- `completePhase(jobId:phaseId:token:userEmail:)` → `GunnerPhasePatchResponse`; throws `PhaseCompleteBlockedError` on 422
- `fetchChangeOrders`, `createChangeOrder`, `patchChangeOrderStatus`, `patchChangeOrderItem`

### Dependencies (confirmed in scope)
- `GunnerTaskStep` — reused from `GuidedTasksView.swift`
- `PresignResponse` — from `CompanyCamViews.swift` (has `uploadUrl` + `s3Key`)
- `API.base` — from `APIConfig.swift`

---

## cc-prompt-90: JobGuidedView + GuidedJobRow Routing

**Files:** `PhaseWorkflowViews.swift` (new, 280 lines), `CompanyCamViews.swift` | Commit: `bf1b171`

### PhaseWorkflowViews.swift

**JobGuidedView** — landing screen when user taps a job in guided mode:
- Hero background (blurred+dimmed, same pattern as GuidedTasksView)
- `Color.clear.frame(height: 64)` spacer under overlay
- Scrollable `ForEach(phases)` → `PhaseCard` with `NavigationLink` to `PhaseDetailView`
- `FieldTasksCard` navigates to `GuidedTasksView`
- Change Order FAB (`Color.appWarning` capsule) visible only when `activePhase != nil`
- Back button + job title in overlay

**PhaseCard** — three states:
- Locked: 0.6 opacity, lock icon, no progress
- Active: progress ring (trimmed circle, `completedRequiredCount/requiredItems.count`), `appWarning` color
- Complete: green `checkmark.circle.fill`

**FieldTasksCard** — `note.text` icon, "Field Tasks" label, chevron

**Stubs** (filled later):
- `PhaseDetailView` → filled cc-91
- `ChangeOrderView` → filled cc-93

### GuidedJobRow change
`NavigationLink` destination: `GuidedTasksView(job:heroLoader:)` → `JobGuidedView(job:)`
(`heroLoader` dropped — `JobGuidedView` owns its own `@StateObject`)

---

## cc-prompt-91: PhaseDetailView + PhaseItemGridCell

**File:** `PhaseWorkflowViews.swift` | Commit: `8188c97`

Replaced `PhaseDetailView` stub with full implementation.

### PhaseDetailView
- Pinned progress header: phase name + `completedRequired/requiredItems.count required` + `ProgressView`
- `loadSections()`: fetches all phases, finds this phase by id, sorts sections by order
- 3-col `LazyVGrid` per section with `PhaseItemGridCell`
- `highlightedItemIds: Set<String>` — populated from `PhaseCompleteBlockedError.incompleteItemIds` on 422
- Complete Phase button: green when `canComplete`, locked icon when not; spinner during `attemptCompletePhase()`
- `attemptCompletePhase()`: calls `completePhase()`, dismisses on success, catches `PhaseCompleteBlockedError` to highlight items
- `markItemComplete(itemId:)` helper for cc-92 item handlers
- Uses `auth.email` (plain `@Published var String`) for `userEmail` — no async needed
- `.sheet(item: $activeItem)` stub comment for cc-92

### PhaseItemGridCell
- Icon circle (red for `.photoFlagged`), label, `fixedSize` 2-line cap
- Orange dot badge (required + not complete) at `topTrailing` offset
- Red `RoundedRectangle` stroke overlay when `highlighted` (from 422 response)
- `.disabled(item.status == .complete)`

---

## Wiki Lint + Auto-Fixes (2026-06-02)

180 pages scanned. 7 issues auto-fixed:
1. `wiki/lint-report.md` — added all 6 required frontmatter fields
2. `session-2026-05-19-omp-finalization.md` — added `title:`
3. `session-2026-05-19-omp-professional-setup.md` — added `title:`
4. `[[How does the LLM Wiki pattern work]]` in log.md — corrected to `[[concepts/LLM Wiki Pattern|...]]`
5. `[[handoff masterdb]]` in masterdb-developer-handoff.md — replaced with plain text code ref
6. `[[claude-obsidian-ecosystem]]` in session note — delinked
7. Orphan `session-2026-05-21-masterdb-cutover-complete` — linked from `masterdb-architecture.md`

151 empty sections across 79 files remain (scaffolded stubs, not errors).

---

## OMP Config: opus-4-8

`~/.omp/agent/config.yml` updated:
- `default`, `slow`, `plan`, `task` → `anthropic/claude-opus-4-8:high`
- `smol`, `commit` stay on `claude-sonnet-4-6:off` (lightweight ops)

---

## Git State

| Commit | cc-prompt | Description |
|--------|-----------|-------------|
| `5848f42` | cc-87 | Pending-only view + CompletedTasksSheet |
| `41ac7e1` | cc-89 | PhaseWorkflowModels.swift (data layer) |
| `bf1b171` | cc-90 | JobGuidedView + PhaseCard + GuidedJobRow routing |
| `8188c97` | cc-91 | PhaseDetailView + PhaseItemGridCell |

All pushed to `main`. Next: cc-88 (backend proxy routes, pending), cc-92 (phase item interaction sheets), cc-93 (ChangeOrderView).
