---
title: CompanyCam
type: vendor
tags: [vendor, companycam, photos, field-ops, ios, gunner]
created: 2026-05-12
updated: 2026-05-15
status: stable
sources: []
related:
  - "[[gunner/gunner-forms-app]]"
  - "[[gunner/environment]]"
  - "[[gunner/app-inventory]]"
---

# CompanyCam

## What It Does

CompanyCam is a field photo documentation platform used primarily by roofing, construction, and contracting companies. It organizes job-site photos by project, supports GPS tagging, and provides daily logs for field crews.

## How It's Used at Gunner

Field crews use CompanyCam to document project conditions, progress photos, and job-site activity. Photos are organized by project (job) and tied to CompanyCam user accounts.

| Detail | Value |
|--------|-------|
| Internal instance | `companycam.dev.gunnerroofing.com` |
| Authentication | Google SSO |
| API | Internal proxy via `gunnerteam-api` Express server |

## Gunner Team App Integration

CompanyCam is integrated into the Gunner Team iOS app. Field users can browse job photo galleries, view activity feeds, comments, and files, and upload photos/videos from the app. The integration uses an internal proxy rather than direct CC API calls.

**Architecture:** iOS app → `gunnerteam-api` (Express/EC2) → `companycam.dev.gunnerroofing.com/api/external/v1`

Key routes:
| Route | Description |
|-------|-------------|
| `GET /companycam/jobs` | List projects filtered by logged-in user's email |
| `GET /companycam/jobs/:jobId` | Project detail — photos[], activity[], files[], counts |
| `POST /companycam/jobs/:jobId/presign` | Get presigned S3 URL for direct upload |
| `POST /companycam/jobs/:jobId/confirm` | Confirm upload after iOS writes directly to S3 |
| `GET /companycam/photos/:photoId/comments` | Fetch flat comment list; proxies upstream status codes |
| `POST /companycam/photos/:photoId/comments` | Post comment; injects `userEmail` from JWT |
| `PATCH /companycam/photos/:photoId/comments/:commentId` | Edit own comment; injects `userEmail` |
| `DELETE /companycam/photos/:photoId/comments/:commentId` | Delete own comment; handles 204 No Content |

**Upload flow (3-step S3):** iOS presigns → PUTs bytes directly to S3 (no Auth header — would break S3 signature) → confirms with CC API. This bypasses the 20MB Express body limit for video files.

### iOS Views (`CompanyCamViews.swift`)

- `JobsView` — lists jobs assigned to the logged-in user by email
- `JobDetailView` — 4-tab view (ACTIVITY, PHOTOS, COMMENTS, FILES); photo grid cells with 3pt Gunner red border when `commentCount > 0`
- `JobPhotoSession` — camera (photo + video), library picker (PHPicker), review screen, presign/confirm upload
- `CCPhotoViewer` — paged full-screen viewer; bubble.right button (top-right) opens `PhotoCommentsSheet` for the current photo
- `PhotoCommentsSheet` — loads comments on appear; flat view (v1); long-press own comments for Edit/Delete context menu; `EditCommentSheet` for inline edit
- `QLFilePreview` — QuickLook wrapper; markup/annotation tools disabled; filename uses actual `file.name` (not UUID)

### Activity Feed Notes

Activity items use multiple fallback fields (`body ?? text ?? message` for text, `fileName ?? name` for filenames). Photo activity rows show count only ("N photos uploaded") — presigned S3 URLs in activity items go stale and cannot be used as thumbnails. Tapping a photo activity row switches to the Photos tab.

## Inbound Webhooks

`POST /companycam/webhook` handles multiple event types via `X-CCam-Event` header. `verifyHmac(rawBody, sig, secret)` is called per-handler with the appropriate secret — each event type has its own secret in SSM.

**Shared requirements (all events):**
- `express.raw()` — signature is computed over raw bytes
- Dedup on `X-CCam-Delivery` UUID before dispatching
- Respond under 3s

### project.assigned

Fires when a user is added to a project. Dispatches APNs to assigned PM.

- Secret: `COMPANYCAM_WEBHOOK_SECRET` (SSM)
- Filter: `assignedRole === "pm"` only; skip self-assignments
- Full spec: [[summaries/project-assigned-webhook-receiver-spec]]

### photo.comment.added

Fires when a comment is added to a photo (v1.1, 2026-05-15).

- Secret: `COMPANYCAM_PHOTO_COMMENT_WEBHOOK_SECRET` (SSM)
- Returns 200 immediately; APNs push is fire-and-forget
- Notifies users in `recipientEmails[]` (excluding `authorEmail`)
- **APNs push blocked** until APNS file-path bug #11 is resolved — receiver logs and returns 200 correctly

> [!warning] Both webhook secrets live in SSM, never in source. Rotate by coordinating a swap window with the WL-CompanyCam team.

## Project Hub — External API (Colin's App)

A separate, purpose-built external API layer over the same underlying platform. Lives at a different domain from the internal instance.

| | |
|---|---|
| Base URL | `https://project.dev.gunnerroofing.com/api/external/v1` |
| Auth | `Authorization: Bearer <COMPANYCAM_API_KEY>` (key in SSM — never in wiki) |
| Service name | `wl-companycam` |
| Test coverage | 58 passing (verified 2026-05-15) |

**Nine endpoints (updated 2026-05-15):** `GET /projects`, `GET /projects/{id}`, `POST /uploads/presign`, `POST /projects/{id}/photos`, `POST /projects/{id}/files`, `GET /photos/{photoId}/comments`, `POST /photos/{photoId}/comments`, `PATCH /photos/{photoId}/comments/{commentId}`, `DELETE /photos/{photoId}/comments/{commentId}`. Colin's `GET /projects/{id}` now returns `commentCount: Int` per photo object.

**Upload is 3 steps:** presign → PUT bytes to S3 (no Authorization header) → register. Presigned URLs expire ~1h — don't cache in DB.

**userEmail attribution:** pass the logged-in user's email on every write so activity feed attributes to a real person. Unknown email → 404 on writes.

**Notable gap:** no `/files/{id}/comments` — comment threads exist only on photos.

Full endpoint reference, gotchas, dev fixtures, and TypeScript client: [[summaries/external-api-handoff]]

> [!warning] API key is NOT in this wiki. Lives in SSM as `COMPANYCAM_API_KEY`. Source file is git-ignored (`*.local.md`).

## Known Issues / Resolved

> [!info] CC API Upload — Superseded (2026-05-15)
> Earlier attempts to upload via the internal CC API (`companycam.dev.gunnerroofing.com`) returned 400/500 — server-side bug in Next.js/OpenNext/Lambda app, not fixable from GunnerTeam side. The Project Hub external API (`project.dev.gunnerroofing.com`) is a separate surface with a working 3-step S3 upload flow. New integration work should use the external API.

## SSO / App Inventory

| SSO Supported | SSO Type | Current Method |
|--------------|----------|---------------|
| Yes | Google SSO | Google SSO |

See [[gunner/app-inventory]] for full SSO and offboarding notes.

## Related

- [[gunner/gunner-forms-app]] — iOS app integration, photo viewer, upload implementation
- [[gunner/environment]] — SaaS stack; CompanyCam in Core Operations table
- [[gunner/app-inventory]] — SSO inventory
