---
title: "Session 2026-05-15 — Photo Comments v1 + v1.1, Lambda PC, Branch Cleanup"
type: session
tags: [session, gunner, ios, companycam, lambda, aws, terraform]
created: 2026-05-15
updated: 2026-05-15
status: stable
sources: []
related:
  - "[[gunnerteam/gunner-forms-app]]"
  - "[[vendors/companycam]]"
  - "[[summaries/external-api-handoff]]"
  - "[[tyler/gunnerteam/gunnerteam-api-aws-migration]]"
---

# Session 2026-05-15 — Photo Comments v1 + v1.1, Lambda PC, Branch Cleanup

Continuation of the 2026-05-15 main dev session. Previous segment covered CO upload fix and Terraform branch-mismatch lesson (see [[meta/session-2026-05-15-co-upload-fix]]).

---

## Lambda Provisioned Concurrency

**Problem:** iOS app launch fires several API calls concurrently (login + announcements + profile). On a fresh Lambda cold start this caused 27.9s latency on `/assistant` — within Lambda's 30s timeout but iOS may give up first.

**Root cause:** Multiple Lambda containers spin up simultaneously on app launch. The keep-warm EventBridge ping (`rate(5 minutes)`) keeps one container warm, but concurrent requests still cold-start additional containers.

**Solution implemented:** Lambda alias + provisioned concurrency on the main API Lambda.

| Config | Value |
|--------|-------|
| `publish = true` | Required — PC cannot target `$LATEST`, needs a versioned ARN |
| `aws_lambda_alias.api_live` | Alias pointing to `aws_lambda_function.api.version` |
| `provisioned_concurrent_executions` | 2 |
| Cost | ~$22/mo (2 always-warm containers) |

**API Gateway wired through alias:** `integration_uri = aws_lambda_alias.api_live.invoke_arn`. Lambda permission requires `qualifier = "live"` to match. Invocations NOT through the alias (EventBridge keep-warm, scheduler) hit `$LATEST` and do NOT use PC containers — this is fine because PC containers are pre-warmed automatically by AWS and don't need the keep-warm ping.

**Every future `terraform apply` flow:** code change → new version published → alias auto-points to new version → PC drains old containers and warms new ones (~30s). No manual alias management needed.

**Assistant Lambda (streaming):** A separate Lambda (`gunnerteam-dev-assistant-stream`) with Function URL in `RESPONSE_STREAM` mode — NOT covered by keep-warm yet. Keep-warm + `event.keepWarm` short-circuit deferred to after SCP exception lands. Buffered `/assistant` runs on the main API Lambda and is covered by PC.

---

## Photo Comments v1

### Feature Overview

Photo-level commenting on jobs in the Gunner Team iOS app. Tapping a photo in `JobDetailView` opens `CCPhotoViewer`; a bubble.right button in the top-right opens `PhotoCommentsSheet`.

**Scope:** Flat comments only. `parentCommentId` retained on model for v1.1 reply support without re-doing the struct.

### Backend (companycam.js)

Two new proxy routes:

| Route | Handler |
|-------|---------|
| `GET /companycam/photos/:photoId/comments` | Proxies to Colin's API; returns upstream status codes (not blanket 500) |
| `POST /companycam/photos/:photoId/comments` | Proxies with `userEmail: req.user.email` injected from JWT |

**Pattern difference from existing routes:** These use raw `fetch` (not `ccFetch`) so non-ok upstream status codes proxy through. The `ccFetch` helper throws on non-ok, losing the original status.

### iOS Data Model

```swift
struct CCPhotoComment: Identifiable, Decodable {
    let id, body, authorName, authorType, createdAt: String
    let photoId, parentCommentId, authorEmail: String?
    var isReply: Bool { parentCommentId != nil }
}
struct CCPhotoCommentsResponse: Decodable { let comments: [CCPhotoComment] }
```

### iOS UI

- `PhotoCommentsSheet` — loads on appear via `GET`, filters to `parentCommentId == nil` for display, sends via `POST`
- On POST success: decodes response as `CCPhotoComment` directly; falls back to reload if shape doesn't match
- `CommentRow` — author (bold) + relative time (`RelativeDateTimeFormatter`, abbreviated) + body; secondary background card
- `CCPhotoViewer` — added `@EnvironmentObject var auth: AuthManager`; bubble.right button uses `allPhotos[safe: currentIndex]?.id` so swiping then tapping opens the correct photo's thread

### Activity Tab (no change)

The existing `case "comment"` activity row renders author header + text. `CCActivityItem` has no `target` field — photo thumbnail in comment activities deferred to v1.1 pending confirmed API shape from Colin.

---

## Photo Comments v1.1

### 1. Webhook — photo.comment.added

**Refactor:** `verifyHmac(rawBody, signature, secret)` — secret is now a param instead of hardcoded to `COMPANYCAM_WEBHOOK_SECRET`. Enables per-event secret selection.

**New webhook handler structure:**

```
POST /companycam/webhook
  → read X-CCam-Event header
  → dedup by X-CCam-Delivery
  → switch(eventType):
      'project.assigned'     → handleProjectAssigned (existing logic, COMPANYCAM_WEBHOOK_SECRET)
      'photo.comment.added'  → handlePhotoCommentAdded (new, COMPANYCAM_PHOTO_COMMENT_WEBHOOK_SECRET)
      default                → 200 ignored
```

**`handlePhotoCommentAdded` pattern:** HMAC verify → return 200 immediately → fire-and-forget APNs to `recipientEmails` (excluding `authorEmail`). APNs push won't fire until APNS file-path bug #11 is resolved, but the receiver logs and returns 200 correctly today.

**New SSM parameter:** `/gunnerteam/dev/COMPANYCAM_PHOTO_COMMENT_WEBHOOK_SECRET` (already exists). Added to `terraform/lambda-api.tf` SSM lookup and Lambda env vars.

### 2. Photo Border Indicator

**`CCPhoto.commentCount: Int?`** added (optional — older API responses without it decode fine).

**Grid cell overlay:** `Rectangle().strokeBorder(Color(hex: "#DD141E"), lineWidth: 3)` when `commentCount > 0`. Gunner red brand color; 3pt width; no corner radius (grid cells are flush).

### 3. Edit and Delete

**Backend routes added:**

| Route | Notes |
|-------|-------|
| `PATCH /companycam/photos/:photoId/comments/:commentId` | Injects `userEmail: req.user.email`; proxies upstream status |
| `DELETE /companycam/photos/:photoId/comments/:commentId` | Handles 204 No Content separately (no `.json()` call on empty body) |

**iOS:**
- `CommentRow` gets context menu with Edit + Delete — only shown when `comment.authorEmail?.lowercased() == auth.email.lowercased()`
- Long-press → Edit: opens `EditCommentSheet` (pre-filled; Save disabled if body unchanged or empty); on save calls `patchComment()` which updates list in-place if response decodes as `CCPhotoComment`, else reloads
- Long-press → Delete: `.alert` confirmation; on 2xx calls `comments.removeAll { $0.id == comment.id }`

---

## CompanyCam 401 Diagnosis

**CloudWatch error:** `CompanyCam 401: {"error":"Unauthenticated"}` on jobs routes.

**SSM check:** `/gunnerteam/dev/COMPANYCAM_API_KEY` — value starts `ccam_`, correct format.

**Usage in code:** `Authorization: Bearer ${ccKey()}` — pattern is correct.

**Conclusion:** Key is present and correctly formed. 401 indicates the key was **revoked or rotated on Colin's side**. Resolution: compare current SSM value against Colin's latest handoff doc and do `aws ssm put-parameter --overwrite` with the current key.

---

## Branch Cleanup

- `debug/login-trace` deleted (local + remote) — login timeout investigation paused; branch served its diagnostic purpose
- Login timeout root cause still unknown — hypothesis was `queryWithTenant` (SET LOCAL inside RDS proxy transaction holding idle connection). Needs a fresh `debug/login-trace` or direct CloudWatch investigation next session.

---

## Open Items After This Session

| Item | Status |
|------|--------|
| CompanyCam 401 | Key likely revoked — get current key from Colin, do SSM put-parameter |
| APNS bug #11 (file-path) | Blocks all push delivery including photo.comment.added |
| Assistant Lambda keep-warm | Deferred — SCP exception pending; code note left in eventbridge.tf |
| Login timeout | Paused — debug/login-trace deleted; reopen if login issues recur |
| Cloudflare API token | IPv6 IP restriction blocking `terraform apply` from this network; use `-target` to apply only Lambda resources |
