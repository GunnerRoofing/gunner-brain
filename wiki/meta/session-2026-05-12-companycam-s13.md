---
type: session
title: "CompanyCam Feature — Session 13 (4-Tab UI, Upload Flow, QuickLook)"
created: 2026-05-12
updated: 2026-05-12
tags: [session, companycam, ios, gunnerteam, swift]
status: developing
related:
  - "[[vendors/companycam]]"
  - "[[gunnerteam/gunner-forms-app]]"
---

# CompanyCam Feature — Session 13

Continuation of CompanyCam iOS feature build. Session 12 established the base camera + photo upload flow. This session adds the 4-tab job detail view, activity feed, comments, files (QuickLook), and several camera/upload fixes.

---

## JobDetailView — 4 Tabs

`JobDetailView` has four fixed tabs matching the CompanyCam web UI: **ACTIVITY, PHOTOS, COMMENTS, FILES**. Tab bar is a fixed `HStack` with equal-width columns and an amber underline indicator — not a `ScrollView` (was accidentally scrollable before fix).

Each tab shows a count badge from the API response (`photoCount`, `commentCount`, `fileCount`, activity item count). Tabs open to **ACTIVITY** by default.

All four tabs have pull-to-refresh (`refreshable { await loadDetail() }`).

---

## API Response — GET /companycam/jobs/:jobId

Returns:
```json
{
  "project": {...},
  "photos": [...],
  "activity": [...],
  "files": [...],
  "photoCount": N,
  "fileCount": N,
  "commentCount": N
}
```

Activity is an array of day-grouped objects: `{ day, date, items: [CCActivityItem] }`.

`CCActivityItem` has multiple fallback fields because the CC API uses different field names per event type:
- `body ?? text ?? message` → `displayText` (comments / system events)
- `fileName ?? name` → `displayFileName` (file events)
- `kind`: `"photo"`, `"comment"`, `"file"`, or system (anything else)

---

## Activity Feed

Per-day sections with a dark blue header bar (`#2D3F5E`) showing day name and date.

| `kind` | Renders as |
|--------|-----------|
| `photo` | Tappable row showing count ("8 photos uploaded") + chevron — taps switch to Photos tab |
| `comment` | Avatar + name + time + `displayText` |
| `file` | Avatar + name + time + filename with doc icon |
| system (default) | Italic `displayText` in secondary color |

Photo thumbnails from activity items are NOT shown — presigned S3 URLs in activity items go stale. Count-only row is the correct pattern.

---

## Upload Flow — Presign / Confirm (3-Step S3)

Upload changed from base64-over-HTTP to direct S3 upload to avoid the 20MB Express body limit for videos.

1. **Presign:** `POST /companycam/jobs/:jobId/presign` → `{ uploadUrl, s3Key }`
2. **S3 PUT:** iOS puts bytes/file directly to presigned URL — **no Authorization header** (would break S3 signature validation)
3. **Confirm:** `POST /companycam/jobs/:jobId/confirm` → `{ s3Key, contentType, byteSize }`

Photos use `URLSession.upload(for:from:data)`, videos use `URLSession.upload(for:fromFile:)`.

---

## Camera Features

- **Camera flip:** `flipCamera()` on `CCCameraModel` — removes current video input, adds new one for opposite `AVCaptureDevice.Position`. Disabled during recording.
- **Video recording:** `AVCaptureMovieFileOutput` with `CCVideoDelegate`. Timer on `recordingDuration` at 0.1s interval. UI shows red recording badge + elapsed time in top bar.
- **Library picker:** `PHPickerWrapper` (`PHPickerViewController`) — images + videos, no selection limit, no permissions prompt. Does NOT auto-navigate to review screen after pick (was a bug).
- **Video preview:** Tapping a video thumbnail in review opens `fullScreenCover` with `AVPlayer` / `VideoPlayer`.
- **Thumbnail generation:** `generateVideoThumbnail()` uses `AVURLAsset` + `AVAssetImageGenerator` async API (`gen.image(at:)`) — iOS 18 non-deprecated. Cached in `@State thumbnailCache: [String: UIImage]`.

---

## Photo Grid Fix

Grid cells were rendering at varying heights. Fix: `.frame(height: 110)` (exact, not `minHeight`).

---

## Pinch-to-Zoom — ZoomableImageView

`MagnificationGesture` fought `TabView` swipe — replaced with `UIScrollView`-based `ZoomableImageView` (`UIViewRepresentable`). Provides native pinch/pan and double-tap-to-zoom. Coordinator implements `UIScrollViewDelegate.viewForZooming` and re-centers image in `scrollViewDidZoom`.

---

## QuickLook Fixes

**Filename:** `downloadAndPreview()` previously saved temp file as `UUID().uuidString + ext` → QuickLook title showed UUID. Fix: use `file.name` (sanitized with `/` → `_`) as the temp filename. Old copy removed before move to avoid stale data.

**Markup tools disabled:** `QLFilePreview` Coordinator now conforms to `QLPreviewControllerDelegate` and returns `.disabled` for `editingModeFor previewItem`. Share sheet and zoom still available.

---

## Activity Feed — Photo Thumbnails + Deep Links

**Photo thumbnails:** Activity photo rows now show up to 4 thumbnail images (56×56, rounded corners) using `livePhotos(for:)` — cross-references activity item photo IDs against `detail.photos` (freshly loaded) to avoid stale presigned S3 URLs. An overflow chip ("+ N") appears if there are more than 4. Count row still shows below thumbnails.

**Deep linking from activity rows:**
- Photo row → switches to Photos tab + scrolls to the matching date group (`"photogroup_<dateLabel>"` anchor on each `VStack`)
- Comment row → switches to Comments tab + scrolls to that exact comment (`"comment_<id>"` anchor)
- File row → matches by filename to `detail.files`, switches to Files tab + scrolls to that file (`"file_<id>"` anchor on each Button)

**Scroll timing pattern:** State set before tab switch → target tab enters hierarchy → `onAppear` fires with 150ms `asyncAfter` delay (layout time) → scroll. `onChange` handles same-tab tap case. Both handlers clear the state after scrolling. All three tabs (Photos, Comments, Files) wrapped in `ScrollViewReader`.

---

## Auto-Refresh After Upload

`JobDetailView` calls `loadDetail()` in `.onChange(of: showCamera) { _, isShowing in if !isShowing { Task { await loadDetail() } } }` — fires when camera session dismisses, refreshing photos tab without user navigating away.

---

## SourceKit False Positives

`AuthManager`, `Color(hex:)`, `UIImpactFeedbackGenerator` show as SourceKit errors in `CompanyCamViews.swift` because they're defined in other project files. These compile correctly — SourceKit doesn't index cross-file symbols the same way the compiler does. Safe to ignore.
