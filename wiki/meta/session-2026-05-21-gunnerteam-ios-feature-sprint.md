---
type: session
title: 'GunnerTeam iOS Feature Sprint — Guided Tasks, Voice Comment, Nav Fixes'
created: '2026-05-21'
updated: '2026-05-21'
tags:
  - session
  - ios
  - swift
  - gunnerteam
  - companycam
  - navigation
status: complete
related:
  - '[[meta/session-2026-05-21-post-cutover-stabilization]]'
  - '[[gunner/gunner-forms-app]]'
  - '[[gunner/aws-environment]]'
---
# GunnerTeam iOS Feature Sprint — Guided Tasks, Voice Comment, Nav Fixes

**Session date:** 2026-05-21 (afternoon/evening, continued from cutover session)
**Repo:** `GunnerRoofing/gunner-ios`, branch `main`

---

## Features Built

### cc-prompt-14 — Guided Tasks (feat/guided-tasks)

Adds an intermediate mode selection screen between the jobs list and `JobDetailView`.

**Backend** (`gunnerteam-api/src/routes/companycam.js`):
- `GET /companycam/jobs/:jobId/tasks` — proxies to Colin's external API, degrades gracefully to `{tasks:[]}` if endpoint not live
- `PATCH /companycam/jobs/:jobId/tasks/:taskId` — proxies task completion, writes `audit_log` entry (SOC 2 CC6.1), validates status enum
- Both routes behind `requireAuth`

**iOS** (new `GuidedTasksView.swift`):
- `GunnerTask` model with `unknown` type fallback for forward-compatibility
- `fetchTasks()` / `patchTask()` using async/await URLSession
- `JobModeSelectionView` — intercepts job tap with two cards: Guided Tasks / Manual
- `GuidedTasksView` — progress bar, task list, empty state, optimistic updates with revert on failed PATCH, toast errors
- `GunnerTaskRow` (photo/form/checkbox type icons, required badge)
- `FormTaskSheet` (text input for form-type tasks)
- Photo tasks: PhotosPicker wired, upload→PATCH chain is a follow-up

**Navigation change** (`CompanyCamViews.swift`):
- `.navigationDestination(item: $selectedJob)` → `JobModeSelectionView` instead of `JobDetailView`

---

### cc-prompt-15 — JobModeSelectionView Visual Polish (feat/guided-tasks-polish)

- **Hero background**: `AsyncImage` with `job.headerImageUrl`, `.blur(radius: 4)`, 52% black overlay. `LinearGradient` fallback.
- **Job info header**: job name (bold white), customer (`person.fill` icon), address (`mappin.and.ellipse`) — each guarded, omitted if nil
- **`ModeSelectionCard`**: `.ultraThinMaterial` frosted glass, white text, cornerRadius 16
- Nav bar: `.toolbarBackground(.hidden)` + `.toolbarColorScheme(.dark)` + `.ignoresSafeArea(.top)`

CCJob field mapping: `headerImageUrl`, `name` (non-optional), `customer: String?`, `address: String?` (flat string)

---

### cc-prompt-16 — Voice Comment: error logging fix (fix/voice-comment-transcription)

Voice comment uses `AVAudioRecorder` → multipart POST to backend Whisper proxy (not `SFSpeechRecognizer`). Previous implementation swallowed all error detail into one generic message.

Fixes applied:
- Audio session `try?` → proper `do/catch` with logging (`.measurement` mode, `.duckOthers`)
- Transcribe guard split into 3 separate checks: HTTP status, JSON parse, `text` key presence
- `[VoiceComment]` log prefix on every failure path for console filtering

---

### cc-prompt-17 — Voice Comment: replace Whisper with SFSpeechRecognizer (fix/voice-comment-ondevice)

Replaces `AVAudioRecorder` + backend Whisper entirely with on-device `SFSpeechRecognizer`.

- `import Speech` added; `NSSpeechRecognitionUsageDescription` added to Info.plist
- `SFSpeechAudioBufferRecognitionRequest` with `shouldReportPartialResults = true` — text updates live while speaking
- `AVAudioEngine` tap feeds buffers directly to recognizer (no file I/O, no backend call)
- `startRecording()` gates on both Speech + Mic authorization before starting
- Live text preview shown in `recordingView` during recording
- Error path only surfaces if `transcribedText` is empty (partial text survives errors)
- `stopRecording()`: engine stop → `endAudio()` → `.review` if text present, `.transcribing` if not
- `postComment()` and all UI unchanged

---

### cc-prompt-18 — Merge all branches + fix navigation regression

All 4 feature branches merged into `main` (excluding `forms-quick-fix-2026-05`):

| Branch | Conflict | Resolution |
|---|---|---|
| `feat/guided-tasks` | None | Clean |
| `feat/guided-tasks-polish` | `GuidedTasksView.swift` add/add | `--theirs` (polished version is superset) |
| `fix/voice-comment-transcription` | None | Clean |
| `fix/voice-comment-ondevice` | `CompanyCamViews.swift` voice comment section | `--theirs` (SFSpeechRecognizer supersedes AVAudioRecorder) |

**Navigation regression**: `--theirs` on `fix/voice-comment-ondevice` reverted `.navigationDestination` back to `JobDetailView` (that branch predated `feat/guided-tasks`). Fixed in patch commit. **Lesson**: never use `--theirs`/`--ours` on files with navigation logic; rebase before merge instead.

---

### cc-prompt-19 — Nav bar flash fix attempt (fix/nav-bar-flash) — SUPERSEDED

`UINavigationBar.appearance()` in `init()` did not prevent the flash. Root cause: SwiftUI morphs source and destination nav bars during the push animation before any modifier or `init()` code runs.

---

### cc-prompt-20 — Nav bar flash: real fix (fix/nav-bar-no-flash)

**The correct fix: remove the system nav bar entirely.**

- `.toolbar(.hidden, for: .navigationBar)` — no bar to morph = no flash
- `.navigationBarBackButtonHidden(true)` — removes synthesised back button
- Custom back button as `.overlay(alignment: .topLeading)`: `chevron.left` in 36×36 `ultraThinMaterial` circle
- `@Environment(\.dismiss)` added to `JobModeSelectionView`
- All `UINavigationBar.appearance()` calls removed
- Back button top padding: `8pt` (overlay is below safe area, so 8pt puts it at system back button position)
- Swipe-to-pop continues to work (NavigationStack backing controller remains)
- `.toolbar(.hidden)` is scoped to `JobModeSelectionView` only — `JobDetailView` and `GuidedTasksView` unaffected

---

## Key Rules Added to CLAUDE.md

**Schema rules** (from post-cutover session):
1. JSONB for JSON columns, never TEXT
2. UUID PK with `DEFAULT gen_random_uuid()` always
3. `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()` always
4. No parallel columns for the same concept
5. Match Express API model, not migration schema
6. ON CONFLICT upserts require a unique index

**Branch/merge rules**:
- `CompanyCamViews.swift` is a collision hotspot — rebase before merge on any branch touching it
- Never `--theirs`/`--ours` on files containing navigation logic
- Rebase before merge pattern: `git rebase main` on feature branch, then `git merge --no-ff`

---

## Final Branch State

- All feature branches merged to `main` ✅
- `forms-quick-fix-2026-05` untouched ✅
- Active PR: `fix/nav-bar-no-flash` (nav bar flash fix)
- `feat/guided-tasks-polish` still listed as unmerged locally — included via cherry-pick in `fix/nav-bar-no-flash` merge chain
