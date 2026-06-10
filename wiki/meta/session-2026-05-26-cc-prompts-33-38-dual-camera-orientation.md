---
title: "cc-prompts-33–38: Dual Camera Orientation + Glassmorphism Polish"
type: session
tags: [dual-camera, AVFoundation, iOS, glassmorphism, GunnerTeam]
created: 2026-05-26
updated: 2026-05-26
sources: []
related:
  - "[[gunner/gunnerteam-project-structure]]"
  - "[[session-2026-05-26-dual-camera-avassetwriter-crash-fix]]"
status: complete
---

# cc-prompts 33–38: Dual Camera Orientation + Glassmorphism Polish

**Date:** 2026-05-26  
**Branch context:** `main`, `fix/front-camera-orientation`, `feat/task-row-glassmorphism`  
**File primary:** `GunnerForms/GunnerTeam/Forms/CompanyCamViews.swift`, `GuidedTasksView.swift`

---

## What Was Built

Six sequential cc-prompts refining the `CCDualCameraModel` dual camera compositor and polishing `GuidedTasksView` UI.

---

## cc-prompt-33 — Black video (CIContext can't render to YUV pool)

**Root cause:** Pixel buffer pool format was derived from the live camera output (`420YpCbCr8BiPlanarFullRange`). `CIContext.render(_:to:bounds:colorSpace:)` silently produces black frames when the destination buffer is YUV.

**Fix:** Pool must always use `kCVPixelFormatType_32BGRA`. CIImage reads YUV input fine; only the output buffer needs BGRA.

**Outcome:** Pre-flight showed `32BGRA` was already hardcoded — the bad `configureWriterIfNeeded` pattern from cc-prompt-32 was never merged. No code change needed.

---

## cc-prompt-34 — Landscape output (portrait orientation on connections)

**Root cause:** `AVCaptureVideoDataOutput` delivers landscape buffers by default.

**Fix (two parts):**
1. Set `videoOrientation = .portrait` (later updated to `videoRotationAngle = 90`) on both back and front `AVCaptureConnection` objects.
2. Introduced `configureWriterIfNeeded(from: CVPixelBuffer)` — defers writer video input setup from `startRecording()` to first back-video frame. Uses `min(rawW, rawH)` / `max(rawW, rawH)` as belt-and-suspenders portrait guarantee.

**Architecture change:** `startRecording()` now only creates `AVAssetWriter` + audio input. Video input and pixel buffer pool are added in `configureWriterIfNeeded`, which must run before `startWriting()`. Audio frames before the first video frame are dropped (acceptable — fraction of a second).

**Key invariant:** `AVAssetWriter` requires all inputs added before `startWriting()`. `configureWriterIfNeeded` fires on the first backDataOutput frame, which is the trigger for `startWriting/startSession`.

---

## cc-prompt-35 — Back camera content sideways

**Root cause:** `videoOrientation = .portrait` changes reported buffer dimensions in `AVCaptureMultiCamSession` but does **not** rotate the actual pixel data for the back camera. This is a known asymmetry in multi-cam mode.

**Fix:** Apply `.oriented(.right)` to `backCI` before scaling in the compositor. This is a lossless metadata-only CIImage operation that also updates `extent` to portrait dimensions, so the existing scale transform maps correctly.

---

## cc-prompt-36 — Front camera CIImage rotation (.oriented(.left))

**File:** `GunnerForms/GunnerTeam/Forms/CompanyCamViews.swift` — `compositeAndAppend` in `CCDualCameraModel`

**Root cause:** Same as cc-prompt-35 (back camera) — `videoOrientation = .portrait` on the connection changes reported dimensions but not pixel data. Front-facing sensor delivers landscape bytes with the opposite handedness to the back camera.

**Fix (one line):** Chain `.oriented(.left)` on `frontCI` immediately after construction from `CVPixelBuffer`:

```swift
let frontCI = CIImage(cvPixelBuffer: fp)
    .oriented(.left)   // 90° CCW — front sensor is opposite handedness to back
```

**Disambiguation notes:**
- If result is upside-down: change `.left` → `.leftMirrored`
- If result is still sideways: change `.left` → `.right`
- `isVideoMirrored = true` on the connection handles selfie-flip for the **preview layer only** — the CIImage pipeline is independent

**Location:** `CompanyCamViews.swift` line ~1487 (inside `if let fp = latestFrontBuffer {` block in `compositeAndAppend`)

---

## cc-prompt-37 — GuidedTasksView: content behind status bar

**File:** `GunnerForms/GunnerTeam/Forms/GuidedTasksView.swift`

**Root cause:** `.ignoresSafeArea(edges: .top)` was applied to the outer `ZStack`, pulling all children (including the progress header and task list) to y=0 behind the status bar. The `heroBackground` computed property already had its own `.ignoresSafeArea()`, making the ZStack-level modifier doubly wrong.

**Fix (two parts):**

1. **Remove `.ignoresSafeArea(edges: .top)` from both ZStacks** (one in `JobModeSelectionView`, one in `GuidedTasksView`). `heroBackground` retains `.ignoresSafeArea()` so the hero photo still bleeds behind the status bar.

2. **Add top clearance for the back button:**
   - `JobModeSelectionView`: top spacer changed from 16 → 56pt
   - `GuidedTasksView` (task list): `.padding(.top, 56)` added to the `VStack(spacing: 0)` inside the ScrollView

**Clearance math:** back button = 8pt gap + 36pt height + 12pt breathing room = 56pt below the safe area bottom edge.

**Acceptance check:**
- `ignoresSafeArea` appears exactly twice — both on `heroBackground` (not on ZStack)
- `.padding(.top, 56)` present in the task list VStack

---

## cc-prompt-38 — Front camera PiP sideways (deeper fix)

**Root cause:** Both sensors share the same landscape physical orientation, but front and back have **opposite** native orientations. `.oriented(.right)` alone on the front camera produces sideways output.

**Fix:** Apply `.oriented(.leftMirrored)` to `frontCI` — 90° CCW + horizontal flip, matching the selfie-mirror expectation.

**Note:** `isVideoMirrored = true` on the `AVCaptureConnection` affects the **preview layer only**, not pixel buffer bytes in multi-cam mode.

**Orientation correction table for future reference:**

| What you see | Correction |
|---|---|
| Upside-down and mirrored | `.rightMirrored` |
| Correct portrait, not mirrored | `.left` |
| Correct portrait, mirrored, 90° sideways | `.upMirrored` |
| Rotated 180° | `.downMirrored` |

---

## Deprecation Fix (post-38)

`videoOrientation = .portrait` (deprecated iOS 17) was replaced with `videoRotationAngle = 90` on both connections. Pixel rotation is now handled entirely in the compositor via `.oriented()`, so connection rotation only affects reported buffer dimensions (which `min/max` guards anyway).

---

## Activity Tab Debug Probe

Added temporary `[ActivityVideo]` print in `loadDetail()` to inspect raw JSON for video activity items from Colin's API. Filters on `kind` containing "video", `mediaType`, or `media_type`. Used to discover whether `thumbnail_url`, `preview_url`, or similar fields exist on video items.

---

## Key Architecture Facts (CCDualCameraModel)

- **Session:** `AVCaptureMultiCamSession` — does NOT rotate pixel data regardless of connection orientation settings
- **Compositor runs on:** `compositeQueue` (serial `DispatchQueue`)
- **Writer start trigger:** First back-video frame (not `startRecording()`)
- **Pool format:** Always `kCVPixelFormatType_32BGRA` — `CIContext.render` cannot write to YUV
- **Back correction:** `.oriented(.right)` on `backCI`
- **Front correction:** `.oriented(.leftMirrored)` on `frontCI`
- **Belt-and-suspenders:** `configureWriterIfNeeded` uses `min/max` swap on raw buffer dims
- **Audio:** May drop a few frames before first video frame — acceptable
