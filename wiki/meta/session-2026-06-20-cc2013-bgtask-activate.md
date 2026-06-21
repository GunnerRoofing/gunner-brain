---
type: session
title: session-2026-06-20-cc2013-bgtask-activate
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - ios
  - offline
  - outbox
  - bgtask
status: stable
related:
  - '[[meta/session-2026-06-20-cc2012-video-outbox]]'
---

# Session cc-prompt-2013 — Activate the background presign task (BGProcessingTask)

**Phase 6 of offline mode.** Closes the cc-2010 BGTask loose end: the handler existed but
was never registered (no Info.plist permitted identifier), so the "presign + hand transfers
to the background session while the app is closed" window was inactive.

## What was already done (cc-2010, no change needed)

`BackgroundUploader.swift` already had the full BGTask body: `bgTaskID =
"com.gunnerroofing.outbox.presign"`, `registerBGTask()`, `scheduleBGPresignIfNeeded()`
(BGProcessingTaskRequest, requiresNetworkConnectivity=true, guards on !publicItems.isEmpty),
and `handleBGPresignTask` (expirationHandler → setTaskCompleted(false); run() →
setTaskCompleted(true) → reschedule). `UploadOutbox.enqueue()` already calls
`scheduleBGPresignIfNeeded()`; `run()` already presigns all `.waiting` items.

## What changed (commit `5fdfb03` on `main`, 2 files +11 −2)

- **`Info.plist`**: added `processing` to `UIBackgroundModes` (was only
  location + remote-notification) — **required** or `submit()` throws `notPermitted` and
  simulate-launch never fires. Added `BGTaskSchedulerPermittedIdentifiers` array with the
  exact registered id `com.gunnerroofing.outbox.presign`.
- **`GunnerFormsApp.didFinishLaunchingWithOptions`**: replaced the stale "uncomment this"
  NOTE with the real `BackgroundUploader.registerBGTask()` call (handlers must register
  before launch finishes).
- **`GunnerFormsApp` scenePhase `.onChange`**: added `.background` →
  `BackgroundUploader.scheduleBGPresignIfNeeded()` for the app-closed opportunistic window.

## Key facts / gotchas

- **BGProcessingTask requires the `processing` UIBackgroundMode**, not just the permitted
  identifier — the prompt only named the identifier; the mode is the silent prerequisite.
- Registered id ↔ plist string must match exactly or you get a "no handler registered" crash.
  Verified: code line 90 == plist == `com.gunnerroofing.outbox.presign`.
- Scheduling is iOS-discretionary (battery/usage based) — foreground/active (reconnect sink +
  appDidBecomeActive) stays the guaranteed trigger; BGTask only improves the app-closed case.

## Verification

- `plutil -lint Info.plist` → OK; `xcodebuild -scheme GunnerTeam` → **BUILD SUCCEEDED**.
- Identifier match + all call sites confirmed via grep (register once in didFinishLaunching;
  schedule on enqueue + scenePhase-background + handler-reschedule).
- **Not exercised at runtime**: the debugger simulate-launch
  (`_simulateLaunchForTaskWithIdentifier:`) presign→transfer→finalize→notification flow was
  not run on a device/simulator. Build- and wiring-verified only.
