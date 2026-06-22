---
type: reference
owner: colin
app: GunnerCam
created: 2026-05-21
updated: 2026-06-21
tags: [wl-companycam, external-api, integration, gunnerteam, webhooks, pnl]
status: active
---

# External API Integration

A distinct, cross-cutting workstream (founding design → ongoing as of 2026-06-21): WL-CompanyCam exposes a server-to-server API under **`/api/external/v1/*`** so a **sister application** can render Gunner project information and push photos, files, comments, check-ins, change orders, and receipt costs. WL-CompanyCam is the **provider**.

The primary client is **Tyler Suffern**'s GunnerTeam iOS app (see [[colin/people-and-context|People & Context]]). The iOS app **never calls the external API directly** — it goes through a GunnerTeam **Lambda proxy** that is the actual `/api/external/v1` client. `modified_since`, `If-None-Match`, and gzip handling live in that proxy; image caching and foreground behavior live in the iOS app. It was scoped from the founding session as TICKET-15 (Phase 2, alongside the Quote Portal inbound endpoint TICKET-14) — a first-class planned integration, not speculative.

## Base + auth

- Base path: **`/api/external/v1`**.
- Dev base URL for Tyler: **`https://project.dev.gunnerroofing.com/api/external/v1`** (was `companycam.dev.gunnerroofing.com` before the May 12 rename).
- Auth: `Authorization: Bearer ccam_<prefix>_<secret>`, verified against a **SHA-256 hash** in the `integration_api_keys` table via `requireIntegration(req.headers)` + `assertExternalProject` — distinct from the internal cookie/DAL flow ([[colin/decisions|Decisions]]). A key resolves to an **integration principal**, not a user.
- **Correction (was: "JWT bearer tokens"):** keys are **not JWTs**. They are `ccam_<prefix>_<secret>` strings stored only as SHA-256 hashes; no plaintext bearer exists in `.env.local` or any AWS parameter.

### Key management

- **Corporation-scoped** (whole corp, not per-project). Tyler's key grants corp-wide access to all Gunner projects (~64-project org by 2026-06-14; 12 projects seen 2026-05-27).
- Minted via `npx tsx scripts/create-integration-key.mts <corp-slug> "<label>"` (needs `DATABASE_URL` → dev DB, so the SSM bastion tunnel must be up). No admin/self-service UI; creation is by script, revocation by direct DB update (both documented in `EXTERNAL_API.md`).
- **Route-level scoping (migration `0046_simple_fantastic_four`, 2026-06-19):** nullable `allowed_scopes` jsonb on `integration_api_keys`. `null` = legacy corp-wide access; a scoped key gets `403` on any route not requiring one of its scopes; wrong/missing key is still `401`. **This supersedes the 2026-06-18 decision that deferred per-route scoping entirely.** Provision with `--scope external:pnl_receipt_line_items`.
- Live one-off verification: create a short-lived key, make the request, then revoke it in the DB (verify `active_temp_keys=0`).

| Key (dev) | Prefix | Notes |
|---|---|---|
| "Tyler dev" | `54f707faafae` | Corp-wide GunnerTeam dev key |
| P&L dev key | `96388a1dae32` | Scoped `external:pnl_receipt_line_items`; stored in macOS Keychain (Service "WL-CompanyCam dev GunnerTeam P&L receipts API key"), shared to tyler@gunnerroofing.com via Keeper |

**Key hygiene:** integration keys were occasionally pasted into chats, and at one point Tyler exposed a set of secrets by accident. Standing fix: **mint a fresh key and rotate**, not reuse. Keys out of git (the push classifier blocks them).

## Inbound sync (projects / jobs)

- `POST /api/external/v1/projects` — inbound job-sync: upserts by `mondayId`, sets status `scheduled`, resolves `pmEmail` to an existing PM corp user, idempotent. **Never auto-creates users** — unknown `pmEmail` is not provisioned. Reuses the key embedded in Make inbound sync scenario `3640307` (see [[colin/monday-integration|Monday Integration]]).
- Accepted fields: `mondayId` (req), `name` (req), optional `jobId`, `hubspotId`, `quotePortalId`, `invoicingMondayId`, `address`, `phone`, `email`, `status`, `region`, `pmEmail`, `installStartDate`, `installEndDate`, `latitude`/`longitude` (or `lat`/`lng` aliases).
- No new migration at first ship — `creator_type='integration'`, the `external_ids` GIN index, `sync_source`, `last_synced_at` were already in migrations 0000/0001/0016.
- **`external_ids` JSONB** on `projects` (schema.ts:396) reserves `job_id`, `monday_id`, `hubspot_id`, `stripe_id`. **Correction over time:** column was **entirely dead** 2026-05-31 / 2026-06-03 (never read/written); **from ~2026-06-04 inbound sync writes `job_id`/`invoicing_monday_id`**, but `job_id` is still not surfaced in UI or used as a search key (open gap). The Job ID (e.g. `GUN-00359`) originates from the Monday Project Takeoff board field `pulse_id_mkxcr73a` via Make. `stripe_id` gates the Payments tab; older synced projects lacking `invoicing_monday_id` return an empty Payments list and must be re-synced.
- Migration `0038` added nullable `latitude`/`longitude` to `projects`; `/projects` serializes both number-or-null so GunnerTeam avoids client-side geocoding fan-out (which hit Apple's app-wide rate limit on cold loads).
- **Quote Portal inbound** endpoint is idempotent on `external_ids->>'quote_portal_id'` and auto-applies project labels from QP product types (GAF asphalt, Bravo, cedar, siding, windows, doors, gutter guards). Deferred pending a sample QP payload.
- **Leo portal** is expected to provide install start/end dates; `PATCH /api/projects/[id]/route.ts` already validates `YYYY-MM-DD` and rejects `end < start`. Leo fetch sync/webhook is a future ticket.

### CompanyCam importer

Built + deployed **dormant** to dev 2026-06-09. Gates on `status=active && !archived`, then a count heuristic (`MIN_PHOTO_COUNT=15`, `MIN_DOC_COUNT=5` in `src/lib/companycam-import.ts`) to filter junk. Writes `externalIds.companycam_id` via merge-patch (no new columns). Split design: pure engine `companycam-import.ts` (no `server-only`, used by `scripts/sync-from-companycam.mts`) vs `companycam.ts` (`server-only` line 1, SSM cred wrapper, mirrors `monday.ts`). On-demand script (DRY-RUN default, `--live` to commit); cron/two-way/backfill deferred (`tickets/TODO-companycam-sync.md`).

**CompanyCam v2 API quirks:** status is only `active`/`deleted` (+ separate `archived` bool) — pipeline stages live in **Project Labels** (`GET /projects/{id}/labels`), not a status field. No count fields on project objects (probe `/photos` per_page≤100 with `X-Has-Next` header, `/documents` offset-paginated). List pagination has no headers — last page = array length < `per_page`. `GET /projects` supports `query` + `modified_since` but no status filter.

## Outbound read API (projects / tasks / photos / phases)

- Static-key-auth, corp-scoped, read-only. `modified_since=<ISO-8601 UTC>` enables incremental polling; shared `parseModifiedSince` helper throws `BAD_REQUEST` on bad input, filter applies at the outer SELECT on `updated_at`. Covered lists: projects, tasks, photo-comments.
- `GET /api/external/v1/projects` accepts opt-in `include=tasks,phases` (unknown tokens → `400`) nesting full task/phase arrays per project (locked in `DECISIONS.md`, mirrored in `EXTERNAL_API.md`, `EXTERNAL_API_AI.md`, `TYLER_API_HANDOFF.md`).
- `GET /api/external/v1/projects/{id}/photos` — cursor-paginated: default and hard cap **100/page**, newest first, opaque base64url cursor encoding last photo's `capturedAt`+`id`. Response `{ photos, photoCount (true total), nextCursor }`. The detail endpoint caps its inline `photos` array, uses key `nextPhotoCursor` (different name), keeps a true `photoCount`.
- **Tyler sign-off 2026-06-15:** six undocumented fields stripped from `GET /projects/{id}` — `assignableUsers`, `assignableCrewMembers`, `projectMemberUsers`, `tasks`, `taskCount`, `phases`. Detail route now returns an explicit allow-list contract: `{project, assignees, crews, activity, photos, files, counts}`.
- `GET /api/external/v1/tasks/high-alert?userEmail=` (bulk) — every high-alert task across a user's visible projects in one call, eliminating per-project fan-out. Each task embeds a project header (`id, name, customer, address, status`). Supports `modified_since`. Backed by partial index `idx_tasks_corp_high_alert_updated` (migration `0034_windy_mockingbird`). Chosen over counts-in-`/projects` because project timestamps aren't bumped on task-only changes.
- **ETag / `If-None-Match` → `304`** (empty body) on the four heavy GETs (`/projects`, `/projects/{id}`, `/projects/{id}/photos`, `/projects/{id}/phases`), one shared helper in `src/lib/external-api.ts`. Initially deferred (useless without URL stability), re-enabled once presigned S3 URLs were stabilized to an hour window and `warm:1` kept a single Lambda hot. Tyler's proxy must send `If-None-Match` itself (URLSession won't); his proxy computes its own ETag and uses gzip upstream rather than forwarding GunnerCam's.
- Project detail surfaces geofence data (no dedicated GET checkins endpoint): `onSiteNow[]` (open check-ins) and `activity[]` (full check-in/out history as system items tagged `site_checkin`/`site_checkout`), populated by `getExternalProjectDetail` in `src/lib/external-projects.ts`.
- **Over-scoping bug report ("test account sees all projects", 2026-06-21) is NOT a code defect** in `listExternalProjectsForUser`: unknown email → `[]`, non-company-wide roles use an EXISTS semi-join on `project_users`, company-wide roles (manager/company_admin/super_admin) see all by design. Fix = correct the account's role (new users default `standard`, schema.ts:359; `masterdb-sync.ts` doesn't write the users table). See [[colin/masterdb-sync|MasterDB Sync]].

## External tasks API (guided / field tasks)

- `GET` + `PATCH /api/external/v1/projects/:id/tasks[/​:taskId]` (migration `0017`, DECISIONS.md:499/513). GET returns `{ tasks: [] }` (never 404). Status mapped at the boundary in `src/lib/external-tasks.ts`: internal `open/done` ↔ external `pending/complete`; `notes` column ↔ `description` in the response.
- **Completion attribution:** acting user's email is sent as `userEmail` **in the JSON body, not a header** (a key = integration, not user). Resolves via `findExternalUserByEmail` → `completedByEmail`. Omitted → null; non-matching active corp user → `404`. Schema added `tasks.completed_at` + polymorphic completer (`completed_by_id` + `completed_by_type`).
- **v1 (superseded):** `type` always `'checkbox'`, `required` always `false`, order from `createdAt` sort, discarded `notes` — honest constant-fill because GunnerCam's `taskTypeEnum` is roofing-workflow types, not iOS input modalities. iOS ignores unknown types so adding them later is non-breaking.
- **v2 typed tasks** (migration `0019`, branch `feat/external-typed-tasks-v2`, commit `cfc6601`, deployed dev 2026-05-27): new enum `task_input_type` (`checkbox | photo_single | photo_multi | text`) plus `required` (bool), `position` (int), `response_text` (text). New `task_steps` table holds `photo_multi` position definitions (label, position, required, soft-delete). Serializer emits real `inputType/required/steps[]/order` and `responseText`.
- `task_steps` are **definitions-only** — no server-side per-step completion state; iOS tracks tile completion locally and PATCHes the parent complete when required steps met. Photos upload via the normal presign → S3 PUT → `POST /photos` flow with no server-side step linkage. Serializer uses a two-query pattern (tasks, then steps only if a `photo_multi` task exists).
- `response_text` is a dedicated column (migration 0019) — text-task PATCH `notes` must NOT reuse `tasks.notes` (the admin-authored description); reverting to pending clears `response_text`.
- Field Tasks (System 2, `GuidedTasksView`) is a separate screen/endpoint from Phases. `highAlert=true` tasks float to the top (red badge + warning banner) and **block job completion**. Internal manager preset dispatch: `GET/POST /api/projects/[id]/tasks/batch`, manage-gated, `{assigneeId, assigneeType, items:[{presetItemId}]}`, selection-only atomic insert with `canAssignTo` tier gating.

## Phase workflow API

- Phases use **lazy idempotent materialization**: created in the DB on first `GET /api/external/v1/projects/{id}/phases` (idempotent via a `project_id`+type unique index), not at project creation. No backfill of existing projects in v1. Templates are **hardcoded** in `src/lib/phase-templates.ts` (`PHASE_TEMPLATES`), materialized by `materializeProjectPhases()` / `external-phases.ts` in one transaction. Structure is immutable per-job (no POST/DELETE on sections/items); only content (status/notes/photos) is mutable.
- **Note conflict resolved:** a 2026-06-03 session described "Option A fetch-and-snapshot" from a GunnerTeam template service (`templates-client.ts`, `GET /templates/for-job-type/:jobType`, Bearer per-org service key, base `https://api-dev.team.gunnerroofing.com`, 3s AbortController fallback). **Later 2026-06-09 sessions state this external template-fetch system does not exist and was never built** — templates remain hardcoded (code comment: "Hardcoded for v1 — an admin-editable template UI is deferred"). **Treat the partner-template-service path as superseded / not-built.**
- `phaseTypeEnum`: `pre_install | project_start | in_progress | close_out`; `upsell` is reserved in the enum but absent from `PHASE_TEMPLATES` (zero-migration wiring later). On first GET, `pre_install` is active, the rest locked.
- `phaseItemTypeEnum` (schema.ts) has seven types: `photo_single, photo_multi, photo_flagged, checkbox, text, measurement, signature`. `photo_flagged` sends `flagged=true` on PATCH. Item PATCH: `phases/[phaseId]/items/[itemId]/route.ts`.
- `PATCH .../phases/:phaseId` with `status:'complete'` → `{ phase, unlockedPhase }` atomically (`unlockedPhase` null on final `close_out`); locked→active cascade is atomic. A `422` (sentinel added to `src/lib/api-error.ts`) = required items incomplete, includes `incompleteItemIds`. **`status:'pending'` currently returns `501` — the revert path is open work (see TODOs).**
- Job-type filtering is **server-side** via optional `jobTypes`/`section.jobTypes`; `job_type=null` materializes all sections. iOS renders whatever the API returns (no conditional visibility). `jobTypeEnum` = `roof | siding | window` (closed) — GunnerTeam maps their sub-types (shingle, flat roof, etc.) to these three; `corpId`/org resolved from the Bearer key, never in the URL.
- Six external phase/change-order route handlers landed under `/phases/` and `/change-orders/` (25 vitest tests; suite 1148/1148). Photo appends are append-only with a cross-tenant S3 key guard.

## 360 photos & photo tagging

- `FOUR_SIDES_360_TAGS_WITH_SIBLINGS` flavor routes each side capture onto a **hidden sibling item**, so `collectPhoto360HiddenSiblingIds` stripping siblings made `item.photos[]` come back empty. Fix: roll sibling photos up onto the parent `photo_360` item at read time; siblings stay hidden from `items[]` and the completion gate.
- Shared `assembleItemPhotos` helper in `external-phases.ts` is used by both the bulk GET and the PATCH item response (`reloadItem`) to prevent the two read paths drifting (sibling rollup, tag derivation, persisted-tag precedence).
- Migration `0041` (`drizzle/0041_ambiguous_mongu.sql`) added a nullable `tag` column to **both** `phase_item_photos` and `photos` (gallery) tables — purely additive, no DROPs. Both gained it independently because gallery and phases serve different consumers.
- Photo `tag` ∈ `front/left/right/back`. For 360-sibling items the tag is **derived at read time** from the tag-step id (zero client work). For label-only/direct-attach photos, optional `photoTags: {'<s3Key>':'front'}` on item PATCH persists to `phase_item_photos.tag`; a **persisted tag takes precedence** over the derived one. Label-only 360 tiles correctly return `tag: null`.
- `GET /projects/:id/phases` per-item `photos` verified live on dev as `{id, url (presigned S3, 206 image/jpeg confirmed), s3Key, tag}`; `photo_360` items also carry `steps[]` (`id, label, order, required, itemId, highAlert`) plus `flagged, value, notes, status, completedAt, completedByEmail`.
- Internal `GET /api/projects/[id]/phase-items/[itemId]/photos` (added 2026-06-05, `requirePrincipal` + `assertCanReadProject`, lazy-fetched by the Workflow tab) returns additive nullable `tag` + `tagLabel`; for a `photo_360` parent it includes parent + all sibling photos annotated with capture side ("Front", "Right side", etc.). See [[colin/photos-uploads|Photos & Uploads]].
- Adversarial-review bugs fixed before deploy: `parsePhotoTags` key trimming must mirror `parsePhotoKeys` (untrimmed whitespace silently dropped tags); `reloadItem`'s photo SELECT was missing the `corporation_id` filter (multi-tenancy violation).
- **Tyler's photos all upload as plain project-gallery photos** (presign `kind:photo` → confirm) with **no phase/task id**, so an S3-key→phase-item join would always be null. Tyler declined `/projects/:id/photos` phase annotation — GunnerTeam keeps that linkage on their side.

## Change orders, DocuSign & signing

- **Two divergent CO flows by design** (field documentation vs executable PDF):
  1. External/iOS guided-checklist `POST /api/external/v1/projects/[id]/change-orders` — only creates a `change_orders` row with 4 template sections; no PDF, no `files` row, no DocuSign.
  2. Web modal `POST /api/projects/[id]/change-orders` — generates a PDF, uploads to S3, inserts a `files` row + an `updates` row.
- `POST /api/external/v1/projects/:id/change-orders/pdf` (built + deployed dev 2026-06-04) gives iOS a single atomic call: PDF render + S3 upload + `files` row (Documents tab). Shared helpers `createChangeOrderPdfFile()` (`src/lib/change-order-pdf-create.ts`) and `sendForSignature()` (`src/lib/signing/send-for-signature.ts`) are reused by web and external routes.
  - **Contract conflict resolved (treat 2026-06-14 as current):** the doc-clarification states `/change-orders/pdf` **only generates+stores the PDF** (returns `fileId`) and does **NOT** trigger DocuSign — dispatch is a separate `POST /api/signing/send/:fileId` call. This was added to `EXTERNAL_API.md`/`TYLER_API_HANDOFF.md` after Tyler reported envelopes not arriving. (The earlier description had the endpoint fire the DocuSign envelope + Monday CO webhook on owner sign-off.)
- Request body (`/change-orders/pdf`): required `description`, `contractorSignaturePng` (**bare base64, no `data:` prefix** — iOS doesn't produce data URLs), `signerName`, `signerEmail`; optional `userEmail`, `project`, `owner`, `projectAddress`, `originalContractSum`, `previousChangeOrders`, `changeOrderAmount` (currency strings incl. `(150)` for negative), `contractorName`, `emailSubject`, `emailMessage`. Returns `201` with `fileId`, `name`, presigned URL, `signingRequestId`. `signHereAnchor` is **never** accepted from the caller — the server always injects it (`/owner_change_order_sign_here/`).
- When `ENABLE_SIGNING != true` the `/change-orders/pdf` endpoint throws `NOT_FOUND (404)` (matching the web flow precedent), **not `503` as originally specced**. On dev `ENABLE_SIGNING=true` (DocuSign demo API `demo.docusign.net` / `account-d.docusign.com`), so this case doesn't arise.
- Tyler's Lambda proxy for `/companycam/jobs/:jobId/change-orders/pdf` was a `501` stub; once flipped it must translate Monday `jobId`→GunnerCam `projectId` and forward verbatim with the `ccam_...` bearer. No iOS changes needed.
- **GunnerTeam must send `amountCents` on CO create** or signed COs never generate a Stripe invoice (the invoice branch silently skips). Dev once had 2 zero-amount draft COs confirming the field wasn't being sent. See [[colin/stripe-make|Stripe & Make]].
- CO PDF signature-placement bug fixed in `change-order-pdf.ts` (signature image overlapped the "OWNER/CONTRACTOR PAYABLE: GUNNER NY/NJ/LLC" entity line) — increased vertical gap, lowered max signature height.
- **Gotcha:** CompanyCam-imported files store **absolute** CompanyCam S3 URLs (`https://companycam-attachments-prod-us-east-1.s3.amazonaws.com/...`) as their `s3_key`, so DocuSign did `presignGet(file.s3Key)` against the app bucket → 404. Fix: absolute http(s) `s3_key` → fetch directly after permission check; else normal presigned path.
- CO item photos/signatures from the guided-checklist flow appear as loose project photos in the activity feed because they share the `photos/{corp}/{project}/` S3 prefix (`external-phases.ts` ~line 692). Flagged, unfixed (needs CO-scoped prefix or stream-query filter).
- **`change_orders` lifecycle split (P1, unresolved):** external API creates/signs `change_orders` rows; the internal CO route generates a PDF document instead of touching that table → manager CO views, P&L rollups, and analytics hard to reconcile. New internal **read** route `GET /api/projects/[id]/change-orders` (DAL-auth, delegates to `loadChangeOrders`) was added for the [[colin/my-day|My Day]] finance panel; the PDF/sign modal remains the canonical "Add Change Order" write path.

## Geofence check-ins & P&L receipt ingest

### Geofence check-ins

- `POST /api/external/v1/projects/{id}/checkins` and `/checkouts` are **write-only** (POST-only since commit `b29fca6`); no GET list endpoint exists or was ever removed. Payload `{ userId, userEmail, timestamp (req), lat?, lng? }`. Each check-in is one row in `project_site_checkins`; `checkedOutAt` stays NULL until checkout. The "On site" badge is derived from open sessions (`checkedOutAt IS NULL`), not a stored flag. Reads happen via project detail (`onSiteNow[]` + `activity[]`). See [[colin/location-pings|Location Pings]].

### P&L receipt ingest

- `POST /api/external/v1/jobs/{jobId}/pnl/line-items` (built + deployed dev 2026-06-19) lets GunnerTeam push confirmed receipt line items. Bearer `ccam_...` auth, **idempotent/upsert on `receiptId`** (resend replaces lines, never appends), surfaces in [[colin/my-day|My Day]] under **Receipt Costs**.
- Body: `source ('receipt')`, `receiptId`, `vendor` enum (`home_depot | abc | other`), `vendorName`, `currency`, `purchasedAt` (nullable date), `lineItems[]` of `{description, quantity, amount, direction}`. `amount` is **always positive**; `direction` enum (`cost | credit`) carries sign — job P&L effect per line = `direction=='credit' ? +amount : -amount`. Non-2xx marks the push failed for retry; partial failures must not 200.
- `jobId` resolves via `projects.external_ids->>'job_id'` (functional index mirroring the Monday id index), tenant-scoped — unknown/out-of-corp `jobId` → `404`. Uses `requireIntegration(req.headers)`.
- Migration `0045_brief_hex.sql` added `pnl_receipts` (header, upsert key `receiptId` scoped by `corporation_id`) + `pnl_receipt_line_items`, plus the `touch_project` trigger on each. Idempotency = soft-delete prior active lines for a receipt in a transaction, then insert the replacement set (no hard deletes).
- Route requires scope `external:pnl_receipt_line_items` (provisioned via `create-integration-key.mts ... --scope external:pnl_receipt_line_items`). GunnerTeam side env-gated via `COLIN_PNL_API_URL` / `COLIN_PNL_API_KEY`, OFF until the endpoint is live (receipts buffered on their side meanwhile).
- **Bug fixed:** the P&L aggregate summed per-unit `amount_cents` without multiplying by `quantity` — now computes `round(quantity * amount_cents)` per line by direction (query-mock tests can't catch this; guarded at input-normalization).

## Webhooks (outbound events)

| Event | Receiver | Secret |
|---|---|---|
| `project.comment.added` | `https://api-dev.team.gunnerroofing.com/companycam/webhook` | SST secret `WebhookProjectCommentAddedSecret` → Tyler's SSM `COMPANYCAM_PROJECT_COMMENT_WEBHOOK_SECRET` |
| `photo.comment.added` | same `-dev` receiver | (see gotcha below) |
| project-assigned | fires on **all roles**; GunnerTeam filters for PM their side (adding sales/estimator later needs no redeploy) | — |

- HMAC-signed: `X-CCam-Event` header, signature in `X-CCam-Signature`. Single-attempt, 3s-timeout, fire-and-forget. Implementation in `src/lib/webhooks.ts`.
- Project comments external API (`GET/POST/PATCH/DELETE /api/external/v1/projects/:id/comments`) deployed dev 2026-05-26; top-level project comments are discriminated from photo comments by the absence of a `photoId` field. (A `commentCount` per photo was GunnerTeam's Priority-1 blocking ask on May 18 and was delivered.)
- **Gotcha:** `WebhookPhotoCommentAddedUrl` on dev was misconfigured to the **prod-style** URL (`api.team.gunnerroofing.com`, no `-dev`), so events never reached Tyler's dev Lambda — corrected to the `-dev` URL. `WebhookProjectAssignedUrl` on dev is still a bare HTTP IP:port leftover (noted, **not fixed**).
- **Gotcha:** rotating a live webhook HMAC secret creates a silent failure window until both the SST secret and Tyler's SSM value are updated atomically — coordinate both sides and verify with a test event immediately.

## Performance & infrastructure

Full perf pass implemented + deployed to dev 2026-06-10 (branch `deploy/workflow-ui`, commit `34da908`; deploy `AWS_PROFILE=devops npx sst deploy --stage dev` → `https://project.dev.gunnerroofing.com`). See [[colin/gotchas|Gotchas]].

- External-auth `last_used_at` write throttled to once / 5 min (telemetry-only, single highest-leverage fix; commit `0fd180e`).
- `GET /projects` photo scan: two full unbounded `photos` scans → one windowed `ROW_NUMBER() OVER (PARTITION BY project_id ORDER BY created_at DESC)` capped at 4×N rows (returns 4/project + true count).
- `GET /projects/{id}/photos` dropped ~25 → ~5 DB statements via a dedicated path; `GET /projects/{id}/phases` ~9 serial round-trips → ~4-5.
- Detail route stopped returning the full internal web view-model (`getProjectDetailForPrincipal`) which over-exposed `assignableUsers`/`assignableCrewMembers` and wasted 2 round-trips.
- **DB layer:** `postgres-js` with `max:1` connection — every sequential `await` is a full Aurora round-trip, so over-fetch and index gaps (not N+1) were the real bottleneck; code already batches into `Promise.all`. S3 presigning (`presignGet` in `src/lib/s3.ts`) is local SigV4 crypto, not network — parallelizing yields no gain.
- **Indexes:** migration `0028` added functional partial btree indexes on `(corporation_id, lower(trim(email)))` for `projects` and `users` (apply on prod with `CREATE INDEX CONCURRENTLY`). Migration `0033` added functional indexes on email/userEmail lookups and reversed the activity-feed index direction for early LIMIT termination. 0032/0033 were on dev before 0034 applied 2026-06-10.
- **`include=tasks,phases` gotcha:** initial impl caused >15s responses for the ~64-project org because phase sections/items/photos were hydrated via huge `IN (...)` ID lists (the joined item query runs ~12ms; assembling thousands of intermediate IDs was the bottleneck). Fix rewrote `external-phases.ts` to join phase items/photos by `project_id` directly (64-project phase include dropped ~5-6.8s → ~2.2-3.5s through the SSM tunnel).
- **"25s slow project" report was a CLIENT bug, not GunnerCam latency:** GunnerTeam used a JS-level 4.5s timeout that resolved the promise but didn't abort the underlying fetch, leaking sockets that queued later requests — fixed in their v220 with `AbortSignal.timeout(4500)`. GunnerCam's server handler was never over ~1.48s.
- **Test-mock gotcha:** external-API test mocks relying on query-call order break when parallel async loaders are reordered (parallelizing the phase loader shifted which fixture was consumed first — fix reordered fixtures to match the new microtask subscription order: `fetchUserNames` before the counts `Promise.all`).
- Document-template thumbnails: switched from 1-hour immutable browser cache to `no-store`, with `THUMB_VERSION='2026-05-19-assets'` query-param bust in `document-picker-modal.tsx`; removed in-memory cache.

## Docs / handoffs

| Doc | Audience |
|---|---|
| `EXTERNAL_API.md` | human-facing contract |
| `EXTERNAL_API_AI.md` | "AI contract" — enough for another agent to call the API without reading the codebase |
| `TYLER_API_HANDOFF.md` | GunnerTeam integration guide (send-to-Tyler) |
| `TYLER_PERF_HANDOFF.md` | canonical Tyler-facing perf doc (server changes, payoff-ordered client fixes, two contract questions); on `deploy/workflow-ui`; Tyler confirmed all server-side gains immediately observable |
| `TYLER_PERF_VERIFICATION.md` | latency verification guide + slow-report template |
| `INTEGRATION_GUIDE.md`, `HANDOFF-*.md`, `api.md` | earlier integration handoffs for Tyler |

Colin frequently tested live endpoints "as Tyler would" (curl with a bearer key) before handing over, and wrote a handoff doc each time.

## Leaked-field / contract-hygiene gotchas

Internal columns repeatedly leaked into the external payload and had to be explicitly stripped: `contract_value_cents` and `rain_days` (caught 2026-06-12 on `feat/redesign-v2`); `assignableUsers`/`assignableCrewMembers` and the six fields listed under the read API (2026-06-09 → 2026-06-15). **Standing rule:** audit external API response shapes whenever new columns are added to `projects`.

## Open questions / TODOs (as of 2026-06-21)

| ID | Item |
|---|---|
| **A1** | **Phase revert:** `PATCH .../phases/:phaseId` with `status:'pending'` returns `501`. Needs: set phase back to pending, re-lock the successor it unlocked (without destroying successor progress), idempotent (already-pending → 200 no-op), return `{phase, relockedPhase}`. Errors: `403` locked/not-permitted, `409` downstream phase already complete, `404` unknown. Tyler's proxy already built. |
| **A2** | **Files `tag` + `createdAt`:** `POST .../projects/:projectId/files` doesn't persist/return `tag` or `createdAt` → video-section filtering + date grouping broken on GunnerTeam's side. Needs migration adding `tag text` + `captured_at timestamptz` to `files`. GunnerTeam already sends both. (A2 gates A3.) |
| **A3** | **Editable tag PATCH:** no per-item PATCH for photos/files; need `PATCH .../projects/:projectId/photos/:photoId` + files equivalent (follow `tasks/[taskId]` PATCH pattern). Depends on A2's migration. Sequencing: A1 → A2 → A3. |
| — | **Dedicated checkin history endpoint:** no `GET /projects/{id}/checkins` returning all sessions with paired in/out timestamps + lat/lng; data exists in `project_site_checkins` but only open sessions projected via `onSiteNow[]`. Build only if Tyler needs full history. |
| — | **P&L contract items (2026-06-18, partly resolved by 2026-06-19 deploy):** whether `{base}` reuses `FIELD_PORTAL_API_URL` or a separate host; whether the service key is scoped only to ingest (→ resolved: scoped key `external:pnl_receipt_line_items`); explicit upsert-on-`receiptId` confirmation; where receipt lines land in the P&L viewer. |
| — | **Surface `external_ids.job_id`:** flows into `external_ids.job_id` on inbound sync but unused — small high-value gap to display (e.g. "Smith – 12345") and make searchable in project header/search. |
| — | **CompanyCam status mapping:** Gunner's CompanyCam Project Label taxonomy → GunnerCam's `projectStatusEnum` unresolved (needs Gunner ops input + exact label names); importer defaults all to `scheduled`. Cron/two-way/backfill/threshold tuning deferred. |
| — | **CO lifecycle reconciliation (P1):** unify the split where the external API writes `change_orders` rows but the internal CO route generates a PDF document instead — affects manager views, P&L, analytics. |
| — | **CO item photo prefix:** guided-checklist CO photos/signatures pollute the activity feed (shared `photos/{corp}/{project}/` prefix); needs CO-scoped prefix or stream-query filter (`external-phases.ts` ~line 692). |
| — | **Null-jobType org-default template:** no agreed path for an org-default template when `jobType` is null (moot if the partner-template-service path stays unbuilt). |
| — | **`WebhookProjectAssignedUrl` (dev):** still a bare HTTP IP:port test leftover, not corrected. |

---

**Direction of travel:** the `gunner-masterdb` migration aims to give the GunnerTeam stack and WL-CompanyCam a shared master DB for core/common tables, which would reduce how much has to flow over this API long-term. See [[colin/masterdb-sync|MasterDB Sync]].

*Source sessions: 2026-05-25 → 2026-06-21; ~32 distinct work sessions (Claude + Codex), spanning the WL-CompanyCam, gunner-masterdb, and permit-poc repos.*
