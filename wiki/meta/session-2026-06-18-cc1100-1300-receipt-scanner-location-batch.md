---
type: session
title: session-2026-06-18-cc1100-1300-receipt-scanner-location-batch
created: '2026-06-18'
updated: '2026-06-18'
tags:
  - gunnerteam
  - backend
  - ios
  - lambda
  - receipt
  - location
status: stable
related:
  - '[[meta/session-2026-06-18-cc864-871-lockfix-ping-consent]]'
  - '[[gunnerteam/aws-environment]]'
---

# Session: cc-1100–1300 — Receipt Scanner Feature + Location Batch + Address Geocoding

**Date:** 2026-06-18 (second half, continuing from cc-864–871)
**Lambda:** v279→v283 live (`gunnerteam-dev-api`, alias `live`)
**iOS:** cc-1100–1110, cc-1200–1202 backend, cc-1300 committed to `main`
**OMP:** updated 16.0.5 → 16.0.7

---

## Receipt Scanner Feature (cc-1100–1110)

End-to-end receipt scanning, P&L ingest, and review UX. Built across 11 cc-prompts in one session.

### cc-1100 — PDF routing to Files tab
`POST /jobs/:jobId/presign` and `POST /jobs/:jobId/confirm` in `fieldportal.js` only routed `video/*` to upstream `/files`. Everything else went to `/photos`. Added `isFile = contentType.startsWith('video/') || !contentType.startsWith('image/')` predicate so `application/pdf` lands in the job Files tab. Deployed **v279**.

### cc-1101 — ReceiptScannerView (VisionKit)
New `Photos/Camera/ReceiptScannerView.swift`: `UIViewControllerRepresentable` wrapping `VNDocumentCameraViewController`. Returns `ScannedReceipt { pdfData, pages }`. `pages[0]` reserved for cc-1104 Textract extraction. Added `.scan` to `CaptureMode`, mode picker, shutter visual (`doc.viewfinder.fill` icon), and `fullScreenCover`. Uploaded PDF → Files on complete.

### cc-1102 — Receipt extraction endpoint (Textract)
`POST /fieldportal/jobs/:jobId/receipt/extract`: accepts `{ imageBase64 }` (JPEG page-1, not PDF — Textract `AnalyzeExpense` is JPEG/PNG only; avoids cross-account S3 access). Returns `{ vendor, vendorName, currency, total, purchasedAt, lineItems[] }`. IAM: `textract:AnalyzeExpense` granted to `gunnerteam-dev-lambda-api` inline policy. Deployed **v280**. `detectVendor`: `home_depot | abc | other`. `parseAmount`: handles negative prices (refund lines), CR suffix, parens.

### cc-1103 — Receipt commit + Colin P&L push
Migration `20260618_receipts` (run on prod): `gt_receipts` + `gt_receipt_line_items` + 2 indexes. `POST /jobs/:jobId/receipt/commit`: validates line items, bulk-inserts both tables (explicit UUIDs + timestamps + `org_id`), audits, then best-effort pushes to `COLIN_PNL_API_URL` (env-gated OFF by default). `pushReceiptToColin`: `AbortSignal.timeout(10000)`, `receiptId` as idempotency key, amount always positive, `direction: cost | credit`. Deployed **v281**.

### cc-1104 — ReceiptVerifyView (side-push)
New `Photos/Camera/ReceiptVerifyView.swift`. Models: `ReceiptDirection`, `ReceiptVendor`, `ReceiptLineDraft`, `ReceiptExtractResponse`, `ReceiptFileRef`. API: `extractReceipt(jobId:jpegBase64:token:)` free func; `commitReceipt(jobId:body:)` calls `AuthManager.shared.token()`. View matches DumpsterSwap/MaterialShortage idiom: dark gradient + frosted Form card + success overlay; `.enableSwipeBack()`; `themeManager.theme.secondary` accent (not `Color.appSecondary`). `NavigationStack` wraps `cameraRoot`; `ReceiptVerifyView` pushed as a destination (horizontal slide, no sheet). `JobPhotoSession` body decomposed into `cameraRoot`/`cameraPreviewLayer`/`topBar`/etc. to avoid type-checker `expression too complex` error.

### cc-1105 — SCAN mode live preview fix
Root cause: `onChange(of: captureMode)` called `camera.stop()` when `.scan` was selected, but `VNDocumentCameraViewController` didn't present until the shutter tapped. Frozen preview between mode-select and shutter. Fix: removed `else if newMode == .scan { camera.stop() }` branch — `.scan` now follows same path as photo/video (camera stays live). Added `onAppear { camera.stop() }` / `onDisappear { camera.start() }` on the scanner `fullScreenCover` instead, so the session is only relinquished while VisionKit is actually on screen.

### cc-1106 — Single-shot scanner (replacing VisionKit)
Root cause: `VNDocumentCameraViewController` is a multi-page scanner — Apple chrome, non-customizable, can't be limited to one page. Replaced with `ReceiptImageProcessor` (enum, no UIKit view controller): `VNDetectDocumentSegmentationRequest` → `CIPerspectiveCorrection` → `CIColorControls` (saturation=0, contrast=1.35, brightness=0.05) → `CIUnsharpMask`. Runs on `DispatchQueue.global(.userInitiated)`. High-contrast grayscale (not Otsu threshold) preserves faint thermal receipt text (Home Depot, grocery). Shutter now calls `captureForScan()` → `camera.capturePhoto` → `ReceiptImageProcessor.process` → `uploadScannedReceipt`. Removed `import VisionKit`, `showScanner` state, and the `fullScreenCover(isPresented: $showScanner)` block entirely.

### cc-1107 — Guard collision bug
Bug: `captureForScan` set `isPreparingReceipt = true` before calling `uploadScannedReceipt`, whose first line was `guard !isScanUploading, !isPreparingReceipt else { return }`. Guard was already false → immediate return → silent stall. Fix: `uploadScannedReceipt` is the single owner of both flags. `captureForScan` sets `isPreparingReceipt = true` (HUD during CPU processing) but removes the `defer` that cleared it. `uploadScannedReceipt` guard reduced to `guard !isScanUploading`. Also added `errorHUD` in shooting mode since `uploadResult = "Receipt upload failed"` was only rendered inside `reviewView`.

### cc-1108 — Unit-price parsing + vendor hardening
**Backend.** Previous parser returned `quantity: 1, amount = extended total` — quantities were always wrong. Switched to unit-price model: `amount = per-unit price, quantity = N`. Priority ladder: (1) `EXPENSE_ROW` regex `qty@unit` (Home Depot format `3@10.01  30.03`), (2) Textract QUANTITY+UNIT_PRICE, (3) QUANTITY+PRICE/qty arithmetic, (4) fallback qty=1. Sign from PRICE (extended total — refund rows have PRICE<0 even when unit positive). `detectVendor` now takes a haystack: `vendorName + all summary field values + first 8 line descriptions`. Added `MORE SAVING` + `PRO XTRA` as Home Depot signals. Deployed **v283**.

### cc-1109 — Verify screen unit-price model
**iOS.** Net computation: `Σ(±amount)` → `Σ(±qty × amount)`. Row layout: "Amount" label → "Unit $"; added read-only "Total" column (`qty × unit`, formatted as currency). `.onChange(of: line.amount)`: if `newVal < 0`, auto-flip to `direction = .credit` and `amount = abs(newVal)` — refund rows from Textract auto-select Credit without manual picker tap.

### cc-1110 — SCAN mode framing guide
Static `scanFrameGuide: some View` (GeometryReader, `allowsHitTesting(false)`): dashed `RoundedRectangle` in `themeManager.theme.secondary` at 82% viewport width × 1.35 aspect (portrait receipt). "Position receipt in frame" capsule label 22pt above guide top. Shown when `captureMode == .scan && !isPreparingReceipt && !isScanUploading` — hides automatically on shutter tap. No per-frame Vision, no video data output tap.

---

## Location Battery Optimization (cc-1200–1202)

### cc-1200 — Coarse off-job accuracy (iOS)
Root cause: continuous GPS at `kCLLocationAccuracyHundredMeters` + `distanceFilter = 100` ran 24/7 off-shift. `applyTrackingMode()` in `CheckInManager` sets accuracy + distanceFilter + `reportIntervalSec` by `checkedInJobId`:
- **Off-job**: `kCLLocationAccuracyKilometer`, distanceFilter=500, reportInterval=900s (15 min) — avoids waking GPS chip
- **Checked in**: `kCLLocationAccuracyHundredMeters`, distanceFilter=100, reportInterval=300s (5 min)

Called at: `startLocationReporting()`, `restorePersistedState()`, `checkOut()` (post-stop), `locationManagerDidChangeAuthorization`. `didUpdateLocations` throttle uses `reportIntervalSec` instead of hardcoded 300.

### cc-1201 — Offline location buffer (iOS)
New `App/LocationPingQueue.swift` (`@MainActor final class`): disk-backed FIFO at `Application Support/gt_location_queue.json`. Cap 5000 pings, batch max 2000.
- `enqueue()`: append + cap + atomic persist + spawn flush
- `flush()`: guards (not flushing, has pending, `isConnected`, has token); drains in ≤2000-ping chunks to `POST /time/location-batch`; keeps unsent on HTTP error (retry on next reconnect/enqueue)
- `reportLocation(lat:lng:)` deleted from `CheckInManager` — replaced by `LocationPingQueue.shared.enqueue(LocationPing(lat, lng, timestamp: loc.timestamp, accuracy:))` using the **real fix capture time** (not wall-clock at send time)
- Foreground flush: `NotificationCenter.addObserver(.appDidBecomeActive)`
- Reconnect flush: `NetworkMonitor.pathUpdateHandler` captures `wasOffline`, flips to connected → `flush()`

### cc-1202 — Batch location ingest (backend)
`POST /time/location-batch`: consent-gated; 2000 ping ceiling; drops invalid rows (non-finite coords, bad timestamp) individually; bulk `INSERT … VALUES` with client-supplied `recorded_at` — `GET /time/location-history` shows real fix timestamps spread across offline window, not clustered at flush time. Updates `gt_time_entries.last_seen` with newest ping. `LOCATION_PING_FORWARD` gates `forwardLocationPingsBatch` (batch forward to Colin). `forwardLocationPing` updated to accept client `timestamp` param — live pings fall back to `now()`; fixes Colin's `(corp, userId, timestamp)` dedup on retries. Deployed **v282** (note: had routing config stale-weight bug — `{282: 1.0}` canary cleared with explicit JSON).

---

## cc-1300 — Street Address on Track-Location Map
`PMLocationView` in `Jobs/Browse/PMJobViews.swift`. Added `@State private var address: String?`. `reverseGeocode(_:)`: `CLGeocoder().reverseGeocodeLocation` one-shot; builds `"subThoroughfare thoroughfare, locality, administrativeArea"` string; `nil` on failure (no cache — single pin on manually-opened view). `.task(id: location.recordedAt)` on the `Map` branch: fires on appear AND when `pollForUpdate` returns a fresh location (recordedAt changes) → address refreshes after a ping. `locationFooter`: address capsule prepended above the existing status block; hidden when `nil`.

---

## Current State

### Lambda versions
| Version | Content | Status |
|---|---|---|
| v279 | cc-1100: PDF→Files routing | superseded |
| v280 | cc-1102: Textract extract endpoint | superseded |
| v281 | cc-1103: receipt commit + migration | superseded |
| v282 | cc-1202: batch location ingest | superseded |
| **v283** | cc-1108: unit-price parsing + vendor hardening | **live** |

### iOS commits this block
`572fed0` (cc-1100) → `87a0fb5` (cc-1101) → `b8d0ea8` (cc-1104) → `05fc940` (cc-1200) → `d5a70e0` (cc-1201) → `9a730d8` (cc-1300) → `c9b1847` (cc-1105) → `fecfb55` (cc-1106) → `2b457ac` (cc-1107) → `5109164` (cc-1108) → `9eda6d3` (cc-1109) → `a913e9a` (cc-1110)

### Migrations added to prod
`20260618_receipts` — `gt_receipts` + `gt_receipt_line_items` tables + 2 indexes

### Open Items (carried forward)
- **`idle_in_transaction_session_timeout = 30000`** on RDS cluster param (pending-reboot — next maintenance window)
- **`LOCATION_PING_FORWARD` flag**: off until CT/NJ consent #37 signed
- **Colin P&L endpoint** (`COLIN_PNL_API_URL`): unset until Colin implements `/jobs/:jobId/pnl/line-items`
- **`REWARDS_ENABLED=false`**: set true when policy approved
- **`gt_location_history` 90-day prune**: recurring EventBridge schedule
- **`GUNNERCAM_POINTS_WEBHOOK_TOKEN`**: set real value in Lambda console
- **Employee notice** (`employee-notice-points-location.md`): HR/legal/IT sign-off
- **Terraform stash reconcile**: `stash@{0}`
- **Colin service key**: wire to `GET /time/location-compliance`
- **Receipt validation on real receipts**: verify B&W legibility on real Home Depot (thermal) + ABC samples; if Otsu was used and faint text drops, keep high-contrast grayscale

## Key Decisions
- **VisionKit rejected for receipts**: `VNDocumentCameraViewController` is multi-page, Apple chrome, non-customizable. Single-shot `camera.capturePhoto` + `ReceiptImageProcessor` (Vision + CoreImage) is the correct primitive.
- **Otsu threshold rejected**: `CIColorThresholdOtsu` drops faint thermal receipt text; high-contrast grayscale (CIColorControls contrast=1.35) preserves legibility.
- **Unit-price model**: `amount = per-unit price, quantity = N`; extended total = qty × amount. Matches receipt layout and how Colin's P&L multiplies.
- **Single flag owner**: one function (usually the "upload" function) owns the HUD state. Two functions setting the same flag with a guard on it causes an immediate silent bail.
- **Offline location real timestamps**: `loc.timestamp` (CLLocation capture time) used, not `Date()` at send time. Preserved end-to-end through the batch endpoint's `recorded_at` insert.
- **Stale canary weight**: `AdditionalVersionWeights: {N: 1.0}` from a previous deploy can route 100% traffic to old version even after alias update. Always use `'{"AdditionalVersionWeights":{}}'` explicit JSON.

## OMP / Dev Environment
- **OMP updated**: 16.0.5 → 16.0.7 (`~/.local/bin/omp update`)
- **iTerm scrollback buffer**: when OMP window moves, iTerm redraws by replaying scroll buffer. Fix: `Settings → Profiles → Terminal → Scrollback lines` — set to ~1000 instead of unlimited. Also: end sessions with `/new` to keep buffer short.
