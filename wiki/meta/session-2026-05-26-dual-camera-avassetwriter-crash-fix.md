---
type: session
title: 'cc-prompt-30: Dual-Camera AVAssetWriter Crash Fix'
created: '2026-05-26'
updated: '2026-05-26'
tags:
  - ios
  - avcapture
  - crash-fix
  - dual-camera
  - companycam
status: stable
related:
  - '[[gunnerteam/gunner-forms-app]]'
  - '[[tyler/gunnerteam/gunnerteam-project-structure]]'
  - '[[meta/session-2026-05-22-cc-prompt-25-colin-v2-api]]'
---

# cc-prompt-30: Dual-Camera AVAssetWriter Crash Fix

## Crash Summary

**Exception:** `NSInternalInconsistencyException`
```
-[AVAssetWriterInput appendSampleBuffer:] Cannot append sample buffer:
Must start a session (using -[AVAssetWriter startSessionAtSourceTime:]) first
```

**File:** `GunnerTeam/GunnerForms/GunnerTeam/Forms/CompanyCamViews.swift`
**Class:** `CCDualCameraModel`
**Trigger:** First captured frame after tapping record in dual-camera mode.

---

## Root Cause

`AVAssetWriter` requires two calls in sequence before any `append`:
1. `startWriting()` — transitions status from `.unknown` → `.writing`
2. `startSession(atSourceTime:)` — opens the media timeline; MUST come after `startWriting()`

The original code called `startWriting()` inside `startRecording()` (on the call-site), then attempted to guard the `startSession` call inside `captureOutput` with:

```swift
if writer.status == .unknown { writer.startSession(atSourceTime: pts) }
```

Because `startWriting()` already ran, `status` was `.writing` by the time any buffer arrived — the `.unknown` guard was **never true**. `startSession` was therefore never called. The first `append` (frequently from the audio output, which fires before the first back-video frame) crashed immediately.

---

## Fix Applied — Three Phases

### Phase 1 — startWriting + startSession Paired in captureOutput (crash fix)

Both calls moved into the `status == .unknown` block at the top of `captureOutput`, before any output-routing logic. This guarantees they fire on the first buffer — regardless of whether that buffer is audio, front video, or back video.

```swift
func captureOutput(_ output: AVCaptureOutput,
                   didOutput sampleBuffer: CMSampleBuffer,
                   from connection: AVCaptureConnection) {
    guard isRecording, let writer = assetWriter else { return }
    let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

    // Open the session on the very first buffer, regardless of which output fires first.
    // Audio frequently arrives before the first back-video frame.
    // startWriting() and startSession() must be paired here — splitting them
    // across call sites lets the capture queue deliver a buffer between them.
    if writer.status == .unknown {
        writer.startWriting()
        writer.startSession(atSourceTime: pts)
    }
    guard writer.status == .writing else { return }

    if output === audioDataOutput {
        guard let aIn = audioWriterInput, aIn.isReadyForMoreMediaData else { return }
        aIn.append(sampleBuffer); return
    }
    if output === frontDataOutput {
        latestFrontBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); return
    }
    guard output === backDataOutput,
          let backPixel = CMSampleBufferGetImageBuffer(sampleBuffer),
          let adaptor = pixelAdaptor, let vIn = videoWriterInput else { return }

    guard vIn.isReadyForMoreMediaData else { return }
    // ... PiP composition and append
}
```

`startWriting()` removed from `startRecording()`.

**Key rule:** `atSourceTime` must always be `sampleBuffer.presentationTimeStamp` — never `.zero` or hardcoded. Using `.zero` causes A/V sync drift and crashes on some devices.

### Phase 2 — isMultiCamSupported Guard in startRecording

`AVCaptureMultiCamSession.isMultiCamSupported` was already checked in three places:
- Static property `CCDualCameraModel.isSupported`
- `init()` guard preventing `setupSession()` on unsupported devices
- View mode-picker hiding the "DUAL" tab on unsupported devices

Added to `startRecording()` as belt-and-suspenders:

```swift
guard !isRecording, Self.isSupported else { return }
```

Prevents any writer allocation from occurring on A11 and older devices where `isMultiCamSupported` is false.

### Phase 3 — Teardown Serialized on compositeQueue

`stopRecording()` previously set `isRecording = false` on the main thread while dispatching `markAsFinished` / `finishWriting` to `compositeQueue`. Cross-thread write of `isRecording` with no happens-before relationship is a data race against `captureOutput` reads on `compositeQueue`.

New pattern: entire teardown dispatched to `compositeQueue`. `assetWriter` is nilled **first** — since `captureOutput` runs on the same serial queue, any callbacks already queued will hit `guard let writer = assetWriter` and bail before they can touch the finished inputs.

```swift
func stopRecording() {
    compositeQueue.async { [weak self] in
        guard let self, let writer = self.assetWriter else { return }
        let url        = self.outputURL
        let completion = self.recordCompletion
        let vIn        = self.videoWriterInput
        let aIn        = self.audioWriterInput
        // Nil first — any captureOutput already queued on compositeQueue
        // bails at `guard let writer = assetWriter` after this runs.
        self.assetWriter       = nil; self.videoWriterInput = nil; self.audioWriterInput = nil
        self.pixelAdaptor      = nil; self.recordCompletion = nil; self.outputURL = nil
        self.latestFrontBuffer = nil
        DispatchQueue.main.async {
            self.isRecording = false
            self.recordingTimer?.invalidate()
            self.recordingDuration = 0
        }
        guard writer.status == .writing else { writer.cancelWriting(); return }
        vIn?.markAsFinished()
        aIn?.markAsFinished()
        writer.finishWriting {
            DispatchQueue.main.async { completion?(writer.status == .completed ? url : nil) }
        }
    }
}
```

The `writer.status == .writing` guard also safely handles the edge case where `stopRecording()` is called before any buffer has arrived (writer still `.unknown`): it cancels cleanly instead of calling `markAsFinished` on an unstarted writer.

---

## Architecture Notes

- `CCDualCameraModel` uses `compositeQueue` (serial) as both the capture delegate queue and the writer teardown queue. This is intentional — serialization is the safety property.
- `AVCaptureMultiCamSession` is safe to instantiate on unsupported devices; the init guard at line 1296 prevents `setupSession()` from configuring any inputs, so no buffers ever arrive. The new Phase 2 guard prevents the writer from being allocated in that state.
- The PiP composition (front camera at 28% width, bottom-right corner) uses `CIContext` with `.useSoftwareRenderer: false` — GPU-accelerated, runs on `compositeQueue` per-frame.

---

## Acceptance

- [x] `startSession(atSourceTime: sampleBuffer.presentationTimeStamp)` called in `status == .unknown` block before any `append`
- [x] `startWriting()` removed from `startRecording()` — cannot race with the delegate
- [x] `isMultiCamSupported` guard in `startRecording()`
- [x] `stopRecording()` fully serialized on `compositeQueue`; `assetWriter = nil` before `markAsFinished`
