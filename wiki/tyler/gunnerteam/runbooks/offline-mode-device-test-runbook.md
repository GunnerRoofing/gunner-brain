---
type: runbook
title: GunnerTeam — Offline Mode Device Test
created: '2026-06-20'
updated: '2026-06-20'
tags: [gunner, gunnerteam, runbook, ios, qa, offline]
status: stable
source: Gunner Team App/runbooks/offline-mode-device-test-runbook.md
related: ["[[gunnerteam/gunnerteam-project-structure]]", "[[index]]"]
---

# Offline Mode — Device Test Runbook

Manual end-to-end verification of the deferred-upload outbox (Phases 1–6). Run on a **real device**
(the Simulator doesn't faithfully model airplane mode, app suspension, or background `URLSession`).
Build: cc-2001 … cc-2014 on `main`.

## Setup
- Real iPhone, signed-in user with an assigned job and a vehicle to inspect.
- Backend `live` alias current (idempotency middleware v323+).
- Have ready: the job in the app, the fleet inspection flow, and one in-app form (e.g. IT Request).
- Grant the notification permission when first prompted (capture once offline to trigger it).

## A. Photos — offline capture survives and uploads
1. Airplane mode ON (Wi-Fi off too).
2. Open the job → capture **3 photos** + **1 video** → submit.
   - ✅ Toast: "Saved — will upload when connected". Screen dismisses.
   - ✅ Photos are already in the iOS **Photos** app (cc-1901 safety net).
3. Top banner reads **"Offline — N waiting to upload"** with the right count.
4. Force-quit the app (swipe up). Reopen, still in airplane mode.
   - ✅ Items still queued (survived restart). Banner count unchanged.
5. Tap the banner → **Pending Uploads** lists the photos + video with "Waiting for signal".
6. Airplane mode OFF. **Background the app** (go to Home screen) within a second or two.
   - ✅ Within ~30–60s: a **"N uploads completed"** notification arrives without reopening the app.
7. Reopen → Pending Uploads shows "All caught up"; verify all photos + the video appear on the job
   server-side, video retains its section tag if shot from middle-phase.

## B. Vehicle inspection — multi-photo, single submit
1. Airplane mode ON. Complete a full inspection (fill meta + several photos) → submit.
   - ✅ Optimistic success; item in Pending as "Vehicle inspection".
2. Force-quit + reopen (still offline) → item persists.
3. Airplane mode OFF, background the app.
   - ✅ All field photos upload, the inspection finalizes once, notification fires.
4. Server: exactly **one** inspection record, photos attached. (No duplicate.)

## C. Form submission — create + attachments
1. Airplane mode ON. Submit an IT Request (with 1–2 attachments) and a Material Shortage.
   - ✅ "Submitted — will send when connected"; both in Pending as "Form submission".
2. Reconnect (background the app).
   - ✅ Each creates once and attaches its files; notification fires.
3. Server / Monday: **one** item per form, attachments present.

## D. Idempotency — no duplicates on a lost ack
1. Online. Start an inspection submit (or form create), then kill the network the instant it fires
   (toggle airplane mode mid-request) so the response is lost.
2. Restore network → the outbox retries the same item.
   - ✅ Server has exactly **one** record (the retry returned the original response via the
     `Idempotency-Key`).
   - ✅ Item ends `.done`, not dead-lettered.

## E. Failure handling
1. Submit a deliberately invalid form (missing required field the server rejects with 4xx).
   - ✅ Item dead-letters to **Failed** with the reason shown; a **"needs attention"** notification
     fires; no infinite retry.
2. In Pending Uploads: **Retry** re-runs it; **Discard** (after confirm) removes it and frees its blob.

## F. Background presign window (cc-2013, opportunistic)
1. Queue items offline, reconnect, but keep the app **closed** (don't reopen).
   - ✅ Best-effort: uploads may complete via the BGProcessingTask window (iOS-discretionary — not
     guaranteed timing). To force in dev: Xcode debugger
     `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"<id>"]`.
   - Note: if the app gets no background window, uploads still complete the next time it's foregrounded.

## G. Location round-trip (clears the block-1200 pending test)
1. Airplane mode ON, drive/move with the app checked in for a few minutes (buffers pings).
2. Reconnect.
   - ✅ Location history shows points **spread across the offline interval** (real capture timestamps),
     not all clustered at the reconnect moment.

## Pass criteria
All ✅ above; in particular: nothing lost across a force-quit, exactly-once server records under
lost-ack retries, and at least one notification delivered with the app backgrounded. Log any failure
with the step letter + number for a targeted cc-prompt.
