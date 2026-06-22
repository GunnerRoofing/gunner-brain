---
type: reference
owner: colin
app: GunnerCam
created: 2026-06-21
updated: 2026-06-21
tags: [wl-companycam, photos, s3, uploads]
status: active
---

# Photos & Uploads

The photo / file pipeline for GunnerCam. The app server never proxies file bytes — browsers upload direct to S3 via presigned PUT and read via presigned GET (the S3-keys-not-bytes convention; see [[colin/decisions]], [[colin/aws-infra]]).

## Core upload flow (browser → S3 → register)

Two-step, always:

1. **Presign** — `POST /api/uploads/presign` with `{ kind:'photo'|'file'|'avatar', projectId, contentType, filename? }` → returns `{ uploadUrl, s3Key }`. Browser PUTs bytes directly to S3.
2. **Register** — `POST /api/photos` (photo/video/audio) or `POST /api/files` (documents) inserts the row. On confirm, the content row **and** a paired `updates` activity-feed row are inserted in a **single DB transaction**.

| Concern | Detail |
|---|---|
| Bytes through Lambda | Never — presigned PUT/GET only |
| Doc generation | `POST /api/projects/:id/documents` requires `assertCanManageProject` (manage, not just read) — see [[colin/external-api-integration]] |
| Thumbnails / variants | Deliberately deferred — only originals stored in V1 (see [[colin/mvp-roadmap]]) |
| Deprecated detail view | `Uploader` routes photos/video/audio → `/api/photos`, docs → `/api/files`; `DocumentsTab` has a second lane for PDF template/signature docs via `DocumentPickerModal` + `AddDocumentModal` |

## Video: poster + compression Lambda

Video uploads PUT to S3, POST to `/api/files`, which asynchronously invokes the **VideoPoster Lambda** (`InvocationType=Event`).

- `functions/video-poster/index.mjs` downloads the S3 object, runs a bundled static `ffmpeg` binary (copied via SST `copyFiles`), and writes sibling outputs at derived keys. **No DB writes** — the web app derives URLs by convention.
- **Poster:** `derivePosterKey()` in `src/lib/s3.ts` → `poster.jpg` sibling.
- **Compression (2026-05-27, T-13):** same Lambda also emits a compressed MP4 sibling in one invocation — ffmpeg H.264 `crf 28 veryfast`, 1280px cap, AAC 128k, `+faststart`, `yuv420p`, written to `{prefix}/compressed.mp4`. Original untouched; if the transcode isn't smaller than the source it is skipped. Poster and compression are independent best-effort steps.
- **Playback fallback (lazy-404, no DB column):** `deriveCompressedKey()` mirrors `derivePosterKey()`; compressed keys are bulk-presigned alongside poster keys in `queries.ts`; a `useVideoSource()` hook in `project-detail.tsx` serves the compressed URL and falls back to the original on `onError`. All three video render sites (modal player + both thumbnails) use this hook.

### Video size/duration limits (`src/lib/video-limits.ts`)

| Limit | Constant | Enforcement |
|---|---|---|
| Size | `MAX_VIDEO_BYTES` = 500 MB | **Server-side, authoritative** — `BAD_REQUEST` before any DB write or Lambda invoke |
| Duration | `MAX_VIDEO_SECONDS` = 600 (10 min) | **Client-side only (UX guardrail)** — `videoEl.duration` from a temp object URL before the presigned PUT; server can't know duration without a probe |

> Correction: a 2026-05-29 note described the size cap as client-side only — superseded by the 2026-05-27 T-13 detail confirming the **server** gate is authoritative.

- Bundled ffmpeg is `@ffmpeg-installer/ffmpeg` (libx264 + AAC); must be fetched via `scripts/fetch-ffmpeg-binary.sh` before `sst deploy` (the `bin/ffmpeg` is gitignored — see [[colin/aws-infra]] for VideoPoster Lambda sizing: 2048 MB, 300s, 2 GB `/tmp`). T-13 needs no schema change / `db:generate`.

## Avatars (T-14, 2026-05-27)

Before T-14, `Avatar` rendered initials only — `avatarUrl` was stored and selected in the DB but never rendered or threaded through the shell. T-14 taught `Avatar` to render an `<img>` when a URL is present and wired a presigned URL through `layout.tsx`, `topbar.tsx`, and `queries.ts`.

- Avatar S3 keys are tenant-scoped under `avatars/{corp}/{user}/` and presigned on read.
- `buildAvatarKey()` and `isOwnAvatarKey()` added to `src/lib/s3.ts` (mirroring `buildCompanyLogoKey()`), plus a `kind:'avatar'` branch in `POST /api/uploads/presign`. The avatar branch **rejects keys outside the caller's own prefix**.

## Phase-item (360) photos vs. gallery photos

Two completely separate tables with **no automatic join** (see [[colin/data-model]]):

| Table | Written by | Surfaced via |
|---|---|---|
| `phase_item_photos` | `photoKeys` on the item PATCH | phases read path only — `item.photos[]` |
| `photos` (gallery) | `POST /photos` confirm | `listExternalProjectPhotos` |

- To surface a 360/phase-item photo in the **All Photos** gallery, clients must **also** confirm it via `POST /projects/:id/photos` using the **same `s3Key`** — one S3 object referenced from two surfaces. The confirm endpoint does **not** dedupe on `s3Key`, so posting the same key twice creates a genuine gallery duplicate — **idempotency is the caller's responsibility** (see Open questions).
- `photos.tag` is independent of `phase_item_photos.tag` and must be supplied explicitly on `POST /photos` (not copied automatically).
- The `photoTags` map value on the phase-item PATCH is a **free-form trimmed string** (not a formal `tagId`); empty/whitespace stores null. For sibling-routed 360 captures the tag is derived from the step id (e.g. `'front'`) and surfaces automatically as `item.photos[].tag` — do **not** send `photoTags` for those.

## Shared lightbox

The project photo lightbox (dark viewer + comment rail + previous/next navigation) was extracted from `project-detail.tsx` into a standalone shared component at `src/components/project-photo-lightbox.tsx` (2026-06-15). Both the deprecated project-detail page and the new [[colin/my-day]] popup import it. Previous/next arrows render only when `photos.length > 1`.

## CompanyCam integration (read-only)

The GunnerCam ↔ CompanyCam integration is **strictly read-only**. All calls to `api.companycam.com` (across `companycam-import.ts`, `companycam.ts`, the content/users importers, the sync script, the cron) are HTTP GETs; the token was provisioned read-only per `sst.config.ts` (SST secret → `/wl-companycam/{stage}/companycam-api-token` → `COMPANYCAM_API_TOKEN_PARAM`, see [[colin/aws-infra]]). The only POST in the codebase hits an internal GunnerCam sync route, not CompanyCam.

- **Not deployed anywhere.** The 5-minute CompanyCam sync cron and its internal route exist only on branch `feat/high-alert-tasks` and are NOT on dev (deploy/workflow-ui returns 404). As of 2026-06-21 the only times CompanyCam's API was touched were on-demand import runs around 2026-06-03 — all reads; no automated sync ran on any deployed stage.
- CompanyCam's own `/v2/photos` can return intermittent **504 Gateway Timeout**, succeeding on retry (observed June 2026) — a plausible cause of user-reported flakiness independent of GunnerCam. See [[colin/gotchas]].
- **Recommended backfill (2026-06-01):** a one-off idempotent script under `scripts/` (not a feature) using paginated `GET /v2/projects`, matching CC projects to GunnerCam rows by normalized address or customer email, streaming CC photo URLs to Gunner S3. Create a new project row only if no match (`corp_id` = Gunner, `creator_type = 'integration'`, store `external_ids.companycam_id`). Suggested filter `photo_count > 15` to drop HubSpot junk; Eric Recchia's filter: only `scheduled` and `active` status projects. Chunked, rate-limited, keyed by CC photo id.

### Demo import — as-run (2026-06-04, commit `47532b1`)

- Stores CompanyCam **CDN photo URLs directly** in `photos.s3_key` (no re-hosting): `urlForKey` hotlinks full `https://` URLs as-is. CC URLs (`img.companycam.com/<signature>/...`) are signed-path imgproxy URLs with **no query-string expiry** — durable enough for a demo; documents are also publicly fetchable with no auth.
- **Migration `0027`** adds a `companycam_id` idempotency column to `photos`, `files`, and `comments` so content sync (Phase D, `SYNC_CONTENT=1`) can re-run safely. Mapping: CC `/projects/{id}/photos` → `photos`, `/documents` → `files`, `/comments` → `comments`. Creator/author resolved to the real app user via `users.companycam_user_id`, falling back to the project PM. Applied to dev 2026-06-04.

| As-run totals (both passes) | Count |
|---|---|
| Photos | 3,540 |
| Files | 335 |
| Comments | 1,208 |
| Projects | 31 |

- Gunner's CompanyCam account has essentially **zero photo-level comments** (only 1 account-wide; per-photo backfill = ~3,400 calls retrieved just 1) — all team comments live at the project level. The backfill pass was partially rate-limited by CompanyCam, but idempotent inserts meant no data loss.
- **Project cover images** (`thumb_url`) are a random photo from the **middle 50%** of the chronological set (mid-job photos more likely show the house exterior, not most recent). Cover is set only when `thumb_url IS NULL`, so a manually chosen cover is never clobbered and the choice is stable across cron ticks. The existing 6 covers were backfilled via a direct SQL migration on dev.

## Signing / file delivery

- **Signing-route fix (2026-06-08):** patched both the web signing route `/api/signing/send/[fileId]` and the shared external signing helper simultaneously, so either entry point (including the iOS/external path) handles absolute-URL file rows correctly.
- **Stripe resend (commit `20dcafa`, 2026-06-03):** `POST /api/projects/[id]/invoices/resend` prefers exact invoice-ID lookup (`in_…` prefix) with an email tenant-guard, then falls back to email+amount match (covers multi-account Stripe; SSM-loaded keys per tenant). See [[colin/stripe-make]].

## Gotchas (as of 2026-06-21)

- **360 photo 500 (2026-06-16):** `phase_item_photos.tag` exists in migration `0041_ambiguous_mongu` but was missing from a local dev DB, causing the photo API to return 500 for 360 parent items. **Fix:** run `npm run db:migrate` locally before testing 360 photo rollup. See [[colin/gotchas]].
- CompanyCam `/v2/photos` intermittent 504 — retry-safe (see above).

## Open questions / TODOs (as of 2026-06-21)

- 360/phase-item → gallery confirm endpoint has **no server-side `s3Key` dedupe**; caller-side idempotency is required to avoid duplicate gallery rows — candidate for a server-side guard.
- CompanyCam 5-minute sync cron + internal route remain unmerged on `feat/high-alert-tasks` and undeployed to dev (no automated sync running anywhere). See [[colin/ops-deploy]].
- CompanyCam demo photo storage relies on CC CDN URLs being durable "enough for a demo" — not a production-grade re-hosting strategy. See [[colin/risks]].
