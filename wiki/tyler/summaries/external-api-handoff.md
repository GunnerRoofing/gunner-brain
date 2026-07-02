---
title: External API — Project Hub Integration Handoff
type: summary
tags:
  - vendor
  - companycam
  - api
  - integration
  - colin
  - gunnerteam-ios
created: '2026-05-15'
updated: '2026-05-15'
sources:
  - EXTERNAL_API_HANDOFF.local.md
related:
  - '[[vendors/companycam]]'
  - '[[gunnerteam/gunner-forms-app]]'
  - '[[tyler/gunnerteam/gunnerteam-api-aws-migration]]'
status: stable
---

# External API — Project Hub Integration Handoff

Verified handoff from Colin, live-checked against dev on 2026-05-15. Covers Tyler's integration of the GunnerTeam iOS app and API against the Project Hub external API.

> [!warning] API key is NOT in this wiki — it lives in SSM as `COMPANYCAM_API_KEY`. Source file `EXTERNAL_API_HANDOFF.local.md` is git-ignored (`.local.md` pattern). Do not paste the key anywhere tracked.

---

## Environment

| | |
|---|---|
| Base URL | `https://project.dev.gunnerroofing.com/api/external/v1` |
| Stage | `dev` |
| Corp | Gunner Roofing (`corp_id = 8bf873f0-f9a5-4442-9355-1e39c09f4bab`) |
| Health | `GET https://project.dev.gunnerroofing.com/api/health` → `{"ok":true,"service":"wl-companycam",...}` |

The API key is corp-scoped — every request is implicitly filtered to Gunner Roofing.

---

## Authentication

```
Authorization: Bearer <COMPANYCAM_API_KEY>
```

Key format: `ccam_<12-char prefix>_<secret>` (61 chars total).

| Status | Meaning |
|--------|---------|
| `400 {"error":"Bad request"}` | Key didn't match `ccam_<prefix>_<secret>` shape |
| `401 {"error":"Unauthenticated"}` | Well-formed but missing / unknown / revoked |

**Note:** If you see `{"errors":["Unauthorized"]}` (plural, array body) you are hitting `api.companycam.com` (public SaaS), not this service.

---

## The Seven Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/projects?email=<email>` | Projects by customer/homeowner email |
| `GET` | `/projects?userEmail=<email>` | Projects a Gunner user can see (role-aware) |
| `GET` | `/projects/{projectId}` | Full render-ready project detail |
| `POST` | `/uploads/presign` | Presigned S3 PUT URL |
| `POST` | `/projects/{projectId}/photos` | Confirm a photo upload |
| `POST` | `/projects/{projectId}/files` | Confirm a file/video/audio upload |
| `GET` | `/photos/{photoId}/comments` | Full comment thread (flat array) |
| `POST` | `/photos/{photoId}/comments` | Add top-level comment or reply |

### GET /projects

Takes **exactly one** of `email` or `userEmail` — both or neither returns `400`.

- `?email=` — customer email match (homeowner portal path)
- `?userEmail=` — role-aware: admin/manager → all corp projects; standard/restricted → only their projects. Unknown email → `{"projects":[]}` (not 404).

### GET /projects/{id}

Returns: `project`, `assignees`, `crews`, `activity` (day-grouped feed), `photos`, `files`, `photoCount`, `fileCount`, `commentCount`.

Activity item kinds: `photo | file | comment | system`. Photo/file URLs are presigned and expire — re-fetch, don't cache.

### POST /uploads/presign

Step 1 of 3-step upload.

```json
{ "kind": "photo", "projectId": "<uuid>", "contentType": "image/jpeg", "filename": "optional-for-files" }
```

Returns `{ "uploadUrl": "...", "s3Key": "..." }`. Then PUT bytes to `uploadUrl` with matching `Content-Type` — **no Authorization header on the S3 PUT**.

### POST /projects/{id}/photos

Step 3 for photos. Required: `s3Key`, `contentType` (jpeg/png/webp only), `byteSize` (> 0). Optional: `caption`, `capturedAt`, `userEmail`.

`s3Key` must start with `photos/<corpId>/<projectId>/` — pass it through verbatim from presign.

### POST /projects/{id}/files

Step 3 for documents/video/audio. Required: `s3Key`, `name` (non-empty), `contentType`, `byteSize` (> 0). Optional: `userEmail`.

`s3Key` must start with `files/<corpId>/<projectId>/`.

### GET /photos/{photoId}/comments

Returns flat array sorted `createdAt` asc. Build tree client-side using `parentCommentId`. Empty thread → `{"comments":[]}` (not 404).

Comment shape: `id`, `photoId` (top-level only), `parentCommentId` (replies only), `body`, `authorName`, `authorEmail`, `authorType` (`user | crew_member | integration | system`), `createdAt`.

Schema invariant: a comment has `photoId` OR `parentCommentId`, never both.

### POST /photos/{photoId}/comments

```json
{ "body": "...", "userEmail": "...", "parentCommentId": "<uuid>" }
```

- Omit `parentCommentId` → top-level comment
- Include `parentCommentId` → reply; can reply to replies with no nesting cap
- `parentCommentId` must belong to the same corp or you get `404`

Fires activity-feed write and in-app bell notifications (same as internal UI). Notification failures are swallowed.

---

## userEmail Attribution

| Case | Result |
|------|--------|
| Provided + known active user | Attributed to that user (`authorType: "user"`) |
| Provided but unknown/deleted | `404 Not found` on writes; `{"projects":[]}` on reads |
| Omitted | Attributed to the integration (`authorType: "integration"`) |

**Always pass the logged-in Gunner user's email** on every write so activity feed and notifications show a real person.

---

## Critical Gotchas

1. **3-step upload**: presign → PUT bytes to S3 → register. Cannot skip steps.
2. **No Authorization on S3 PUT** — breaks the S3 signature check.
3. **Pass s3Key verbatim** — register validates the path prefix.
4. **photo register requires both `contentType` AND `byteSize`** — missing either silently 400s.
5. **`GET /projects` is XOR** on `email`/`userEmail` — both or neither = 400.
6. **Presigned URLs expire** (~1h) — re-fetch the project rather than caching URLs in a DB.
7. **No file comments** — `GET/POST /files/{id}/comments` does not exist; photo comments only.
8. **400 ≠ 401** — 400 means bad key shape; 401 means unknown/revoked key.

---

## Error Contract

| Status | Body | Meaning |
|--------|------|---------|
| `400` | `{"error":"Bad request"}` | Bad body or malformed key |
| `401` | `{"error":"Unauthenticated"}` | Missing/unknown/revoked key |
| `403` | `{"error":"Forbidden"}` | Authenticated but forbidden |
| `404` | `{"error":"Not found"}` | Resource or `userEmail` not visible |
| `500` | `{"error":"Internal error"}` | Internal error — capture `x-amzn-requestid`, ping Colin |

---

## Dev Seed Fixtures (stable as of 2026-05-15)

| Thing | Value |
|-------|-------|
| Admin user | `tyler.suffern@gunnerroofing.com` |
| Another admin | `colin.wong@gunnerroofing.com` |
| Customer email | `jwheeler@gmail.com` |
| Project: Ridgewood Gutters | `c9d8636e-22f0-4602-af5a-59f5b1af2b71` |
| Project: Greenwich Mansard | `3ee32521-75bd-4845-a96c-ab83c47fa79d` |
| Project: Maplewood Skylight | `a92648bb-79e4-4710-95f6-5df30639ca79` |
| Photo on Ridgewood | `54caa260-5578-4475-9de8-478130b801d5` |
| File on Ridgewood | `a12f4480-ce9d-487e-a411-da681818e1c4` |

If any return 404, dev DB was re-seeded — re-run projects list to get fresh IDs.

---

## Gap List (not externalized yet)

| Capability | Available |
|------------|-----------|
| Comment on file/PDF | ❌ (no `/files/{id}/comments`) |
| Top-level project comment (no target) | ❌ |
| @-mention notifications | ⚠️ Partial — body stores `@name` but mention notify doesn't fire on external posts |
| Delete photo/file/comment | ❌ |
| Tasks, change orders, labels, status change | ❌ |
| List users/crews | ❌ |
| Create projects | ❌ |

Most gaps are small symmetric additions — ping Colin if any blocker.

---

## Test Coverage

58 tests passing (verified 2026-05-15):
```
npm test -- --run src/app/api/external/v1/
# Test Files  6 passed (6)
#      Tests  58 passed (58)
```

Drop-in TypeScript client is in `EXTERNAL_API_HANDOFF.local.md` §12 — includes `listProjectsForUser`, `getProject`, `listPhotoComments`, `postPhotoComment`, `uploadPhotoAsUser`, `uploadFileAsUser`.

---

## Key Hygiene

Dev key only. A separate key must be minted against prod when the integration goes live. Mint via `tsx scripts/create-integration-key.mts gunner "<name>"` in the wl-companycam repo. Revoke by setting `revoked_at` on the `integration_api_keys` row.
