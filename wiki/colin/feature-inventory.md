---
type: reference
owner: colin
app: GunnerCam
created: 2026-05-21
updated: 2026-06-21
tags: [wl-companycam, features, architecture]
status: active
---

# Feature Inventory

Catalog of what exists in WL-CompanyCam / GunnerCam by area, with current state. Time-sensitive claims are dated; default reference is **as of 2026-06-21**. This is a CATALOG — each entry stays brief and links out to the deep-dive note. For the order things were built in, see the [[colin/build-timeline|Build Timeline]]; for the high-level stack, see [[colin/index|the domain index]]. Sources: 61 distinct Claude + Codex work sessions, 2026-05-25 → 2026-06-19.

## Stack at a glance

| Layer | Choice |
|---|---|
| Framework | Next.js **16.2.4**, App Router, Turbopack, route group `(app)` |
| Language | TypeScript + React (client components where needed) |
| ORM / DB | **Drizzle** + Postgres (`postgres-js`) on **AWS RDS Postgres 16** (us-east-2) |
| Auth | **AWS Cognito** (username/password, HTTP-only session cookies); session in `src/lib/session.ts`, edge logic in `src/middleware.ts` (renamed from `src/proxy.ts` for Next.js 16) |
| Storage | **AWS S3** via presigned URLs (private bucket) — keys, never bytes |
| Email | AWS SES (`src/lib/email.ts`) |
| Deploy | **SST** (`sst.config.ts`); `dev` stage live |
| DNS | **Cloudflare** → `project.dev.gunnerroofing.com` |
| Signing | **DocuSign** (`demo.docusign.net` sandbox) behind a provider abstraction |
| PDFs | **pdf-lib** for server-side document generation |
| Tests | **Vitest** (~1,344 tests / 120 files), co-located `*.test.ts`; **no Playwright/E2E** |

Data access is layered: `src/lib/dal.ts` (single auth gate), `src/lib/queries.ts` (Drizzle reads), `src/lib/view-models.ts` (DB rows → UI shapes). Auth flows through `requirePrincipal()`/`requireUser`/`requireManager` then `assertCanReadProject`/`assertCanManageProject`; errors are sentinel `Error` objects converted by `errorToResponse`. See [[colin/decisions|Decisions]].

## Core project hub & project detail

Day-one MVP shipped Cognito login, a role-filtered project list (admin/manager → all corp projects, standard → assigned-only, crew → their crew's projects), a day-grouped activity feed, S3 uploads, comments + status-change logging, and admin UIs for users/crews.

Project Detail (`src/components/project-detail.tsx`, route `src/app/(app)/projects/[id]/page.tsx`) loads via `getProjectDetailForPrincipal()` in `src/lib/queries.ts`. Tabs: Activity, Media, Comments, Tasks, Workflow, Documents, Payments (Payments count hardcoded to 0). It defaults **workflow-first** — `activeSurface` starts `null`, utility panels open only on explicit click, direct nav shows the Workflow section.

**The `/projects` route + `ProjectDetail` are officially deprecated** (labeled "Projects (Deprecated)" in `src/components/shell/sidebar.tsx`, as of 2026-06-15), but their data shape and view-model helpers remain authoritative and are reused by newer surfaces: `getProjectDetailForPrincipal()`, view-model types (`ViewActivityDay/Item/ThreadComment/Photo/File` in `src/lib/view-models.ts`), the mention-aware `comment-composer.tsx`, and the presign-to-S3 Uploader. No separate day-detail route — day detail is bucketed inside the Activity feed.

Internal comments: `POST /api/projects/[id]/comments` accepts one mutually-exclusive target (`photoId | fileId | parentCommentId`), validates same-project/corp, fans out notifications/mentions, dispatches project/photo webhooks. No internal edit/delete route in V1. The project **side drawer** is a CSS slide-out (`.project-side-drawer`, 320px→0 over 280ms, collapses to `display:none` ≤1100px); its conversation panel is a chat thread (last 50 comments oldest→newest, day separators, pinned `CommentComposer`); clicking a row jumps to Activity and flash-highlights the comment (1.6s CSS flash). Real-time delivery of others' messages is out of scope (arrives on next `router.refresh()`).

Install-timeline date math is **local time** to avoid TZ date-shift (`installTimeline` → `{start,end,durationDays,status,progress}`, status `none|upcoming|in_progress|done`); project-detail *timestamps* render in the corp's IANA timezone (corp `timezone` column threaded as `corpTz`). Sidebar collapse is CSS via `data-collapsed` on `.shell`; collapsed uses `public/gunner-logo-mark.webp`, expanded `public/gunner-logo.svg` (white background dissolved via `background-blend-mode: multiply`).

## Projects list & health (RAG triage)

The list is organized into four collapsible triage groups: **Needs Attention (red), Action Needed (yellow), On Track (green), Complete (collapsed by default)** in `projects-list.tsx` — caret headers, colored left-edge indicators, row counts; searching auto-expands all groups.

Card attention status (added 2026-06-10), reason pills, sorted red→yellow→green:
- **Red** — overdue high-alert task, OR an underway install with no real field activity (photos/files/comments) 2+ days.
- **Yellow** — unsigned change order, invoice past due, or overdue normal task.
- Jobs on "hold" do not alarm. Staleness uses only real field activity, so Monday re-syncs can't mask a stalled job.

*(Superseded 2026-06-08 design note: the RAG dashboard was originally specced to fully replace the manager list with status-reason row text; as shipped 2026-06-10 it became the four-group list.)* `AssigneeStack` caps avatars at 5 with a `+N` overflow chip; `ViewProject` dropped separate `pm`/`sales` fields for a single deduped `assignees: ViewUser[]` (sorted pm→sales→estimator→other then name).

## Tasks: typed tasks, dispatch checklist, multi-PM

Typed tasks (checkbox / text / single-photo / photo-grid `photo_multi`) are live and served to Tyler's iOS app. `task-modal.tsx` has a Type selector, a Required toggle (blocks iOS job completion), and a `photo_multi`-only positions/steps editor (each step labeled + Required); `photo_multi` is web-only (excluded from the in-app create form). Internal routes: `POST /api/projects/[id]/tasks`, `PATCH /api/projects/[id]/tasks/[taskId]` (no GET-list/DELETE on the per-project path; reads via server queries), `POST /api/internal/task-reminders` (cron). **Tasks are NOT in the external `/api/external/v1/` surface.** Uncheck is live (`PATCH {"status":"pending"}`). **highAlert** is fully implemented (banner, red badges, sorts to top, blocks job-completion indicator — commit `40fcbc6f`, deployed 2026-06-02). New-task assignee defaults to the project PM.

**Task-template / bundle history** (a long churn between deleted/restored/auto-applied): built, then deleted in `7059760` / PR #14 (2026-05-27, replaced by a `taskSteps` model + `src/lib/task-input.ts`) with `task_templates` + `task_template_items` (migration 0015) kept as orphaned schema; app layer restored from `adcc39a` (2026-06-03) as Admin > Task Templates + Apply Template; the standalone Apply Template button removed again (2026-06-05). As of 2026-06-05 flat templates **auto-apply on project creation** via `applyAllCorpTemplatesToProject` (fires best-effort after Monday-sync `created:true` and after manual New Project). Restoring task bundles remains a recurring ticket (Doug's "bundle → opening task set").

**PM batch dispatch checklist** (commit `9f0d873`, human-in-the-loop): manager sees a per-trade pre-checked checklist, unchecks unwanted items, picks a PM, hits Assign — only checked items become tasks. UI `src/components/dispatch-checklist.tsx` (manager/PM only); endpoint `POST /api/projects/[id]/tasks/batch` (selection-aware). Preset library `src/lib/pm-checklist-presets.ts` (~63 live items for Gunner corp), idempotent seeder `scripts/seed-pm-checklist-presets.mts` (`npm run db:seed-presets`). Migration 0021 added `notes, trade_tag, phase, input_type, required` to `task_template_items`. Items tagged by trade (roofing→{asphalt,specialty}, siding, doors, skylights, windows, all) and phase (Pre-Start/Day 1/In Progress/Closeout); no-trade projects show only the 14 All-trade items. Dispatch validates preset IDs against the project's `job_type`; pre-classification (`job_type=null`) projects need data cleanup, not a code fix (the "Todd Thomas" gap). *(Superseded 2026-06-02 snapshot: a review found this feature + 0021 columns missing — they have since landed.)*

**Multi-PM task splitting** (2026-06-11): jobs with 2+ PMs show a per-PM filter bar in the Tasks tab; every task row has an inline manager-gated assignee dropdown. `PATCH /tasks/[taskId]` accepts assignee changes (reassign is manage-gated, status-toggle read-gated; assignee must already be in `project_users`). Assignee pickers (Add Task, dispatch, side-drawer) are scoped to project members; the corp-wide list is still used for comment @-mentions. **Auto-claim:** the first PM added inherits all open unassigned tasks in the same DB txn; a second PM never auto-claims.

**Multi-PM dispatch duplication + review cue** (2026-06-15): `POST /tasks/batch` accepts legacy `{assigneeId, assigneeType, items}` and new `assignments: [{...}]` multi-target body (optional `dueDate`/`scheduledAt`); DispatchChecklist becomes a PM-by-task ownership matrix for 2+ PM projects, defaulting to duplicating all selected tasks to every PM. A red `!` review cue appears in the Tasks split bar and [[colin/my-day|My Day]] PM cards when duplicate open copies exist → routes to `/projects/{id}?tab=tasks&reviewSplit=1`. Detection is the pure client-safe helper `src/lib/task-split-review.ts` (keyed on title/notes/priority/type/required/high-alert + scheduling, no extra endpoint). Unassigning uses the PATCH reassign path with `assigneeId: null`. Fix: a PM who is project-role `pm` but globally `company_admin` was wrongly excluded from dispatch targets.

`task_comments` table (migration `0040_superb_outlaw_kid.sql`) added per-task running conversations — FKs to corporations/projects/tasks, soft-delete + polymorphic creator. Manager tasks fan out as one copy per selected assignee (single-owner model); PM timeline spans reuse `scheduledAt`/`dueDate` (noon-UTC start for date stability).

## Phase workflow (Tyler iOS-owned) & guided tour

Two parallel checklist systems: flat **task templates** (`task_templates`→`task_template_items`, web Tasks panel, no phase grouping) vs the **phase workflow** (`project_phases`→`phase_sections`→`phase_items`, 5 phase types: pre_install, project_start, in_progress, close_out, upsell) which Tyler's GunnerTeam iOS app reads/writes. The internal web API is **read-only** for phases; the external/Tyler API owns mutation (see [[colin/external-api-integration|External API Integration]]). Phase-workflow items are shared per project (no per-PM forks); only the Tasks layer supports per-PM ownership.

Phase rows materialize lazily on first `GET /api/external/v1/projects/{id}/phases` (idempotent, `src/lib/external-phases.ts`), and also eagerly on project creation (Monday-sync `created:true` + manual New Project); old projects backfill on first open. Live templates live in `src/lib/phase-templates.ts` (Project Start, In Progress, Close Out, Change Order, and the now-removed Pre-Install). "Document Existing Site Conditions" is a single `photo_360` item with a tag column for six targets (Dumpster, Material, Existing damage [highAlert], Windows+screens, Siding, Patios/decks/walkways). In Progress branches per trade (roof/siding/window), falling back to all sections when job type is null.

**Pre-Install phase removed from the guided tour 2026-06-08** (permanent deletion, no toggle) — Window Inventory and chimney/skylights/fascia inspection lived there and are currently absent.

**Workflow tab** is a two-pane layout: phase timeline (`.wf-*`) left + sticky Scope-of-Work card (`.sow-*`) right (`src/app/globals.css`); active phase auto-opens on fresh load. Phase items expand inline (2026-06-11) to show photos, notes, measurement value, and a flagged pill; completed photo tasks show a count chip; clicking lazy-fetches presigned S3 URLs into a thumbnail grid → fullscreen lightbox (arrow/ESC nav, captioned). Endpoint `GET /api/projects/[id]/phase-items/[itemId]/photos` (DAL `assertCanReadProject`, ordered by `capturedAt`); `external-phases.ts` adds `photoCount/notes/value/flagged` to `ViewPhaseItem` via one grouped COUNT query. `src/components/scope-of-work-exhibit.tsx` renders read-only SOW rows for PMs.

## Documents, signing & change orders

Document-templates system (`src/lib/document-templates/`) generates branded, project-aware PDFs (Project Completion Certificate, Chimney Waiver, Skylight Waiver, Material Return List) as programmatic `pdf-lib` renders — **not fillable forms** (explicit decision). Registry + shared render helpers (branded header/footer, labeled fields, two-column signature blocks with per-side DocuSign anchors). Generation route `POST /api/projects/[id]/documents` dispatches by `templateId`, stores PDF to S3, records the file row (gated `assertCanManageProject`); an optional `signer` field triggers `/api/signing/send` inline. White-labeling pulls corp branding per-request via `src/lib/document-branding.ts` (`corporations.logoUrl`, `offices.address*/phone`; logo as PNG/JPG, no SVG, falls back to text). Client catalog types are split from server-only `DocumentTemplate`.

DocuSign anchor placement is via `stampDocuSignAnchor()` inside each template's `generate()` (reference `project-completion.ts:117`, anchor `PROJECT_COMPLETION_SIGN_HERE_ANCHOR` / `PC_HOMEOWNER_SIGN_HERE_V1`); the provider resolves the tab by searching embedded near-white text (`src/lib/signing/providers/docusign.ts:127`). `POST /api/signing/send/[fileId]` works for any PDF in the files table. The four signature templates were recalibrated via the permanent harness `scripts/calibrate-document-templates.mts` (modes `geom`/`lines`/`grid`/`fill`, US-Letter 612×792pt) — Chimney Waiver signature block and Change Order dollar column had rendered off-page (y>792) and are now on-page; Material Return added a `maxRows: 12` cap with a live "N / 12 rows" counter. Chimney Waiver page 2 accepts up to 4 photos into four 232×232pt 2×2 boxes (client center-square crop + HEIC→JPEG; route validates magic bytes, 4 MB/file cap).

**Change-order e-sign** runs through document-template + SigningButton under DocumentsTab (path `DocumentsTab > DocsTable > DocsGrid > DocsRow/DocsCard > SigningButton`), threading `defaultSignerName/defaultSignerEmail` from `project.customer`/`project.email`. `ChangeOrderModal.tsx` is an **unwired dead-end** (mounted nowhere) — future CO work should target SigningButton/SendModal. DocuSign env points at `demo.docusign.net` (sandbox); production needs an ops go-live promotion.

**Known unresolved CO signing bug (2026-05-29):** `change-order.ts` never calls `stampDocuSignAnchor()` for `CHANGE_ORDER_OWNER_SIGN_HERE_ANCHOR`, so `POST /api/signing/send/:id` returns 500 (`ANCHOR_TAB_STRING_NOT_FOUND`). Also a contract mismatch: the template declares `signing:"manager"` but the UI routes the homeowner through DocuSign. Neither fix applied as of 2026-05-29.

**COC-signed → Monday status flip** shipped (2026-06-03): on a Certificate-of-Completion DocuSign signing (`'Project Completion - YYYY-MM-DD.pdf'`), the webhook flips the job's Monday Stage column and posts an update (best-effort, never throws) via `flipJobStatusToComplete()`. Dormant until three SST env vars are set: Monday board id `18346327856`, status column id `color_mkyg7189` ("Stage"), and the completion label (Complete vs Project Close Out — pending Eric's confirmation). See [[colin/monday-integration|Monday Integration]].

## Notifications, roles, admin & integrations

**Notifications** landed 2026-05-25 (commit `95f71f0`): `notifications` table (recipient user/crew, project, kind, `read_at`), helper `src/lib/notifications.ts`, `GET /api/notifications`, topbar bell. Seven kinds: assignment, comment, status_change, message, marketing_ping, review_requested, payment_event (wired into assignments + comments). Bell popup (`notifications-bell.tsx`) is text-only, clamped to 2 lines. Webhooks (`src/lib/webhooks.ts`) are single-attempt best-effort (no retry queue); task reminders (`src/lib/task-reminders.ts`) stamp `sent_at` regardless of delivery success. No dead-letter/replay dashboard.

**Roles:** hierarchy `super_admin > manager > pm > standard > restricted`; "Company Admin" was retired (T-9/T-10) but `company_admin` later re-appears as a live role in `userRoleEnum` + DAL (confirmed 2026-06-02/06-03), so terminology drifts across specs. Manager assignments use a `manager_assignments` M:M table. `ProjectDetailPage` derives a matrix (global-PM files logs, per-project PM manages project actions, manager/super_admin edit timeline; `company_admin` deliberately NOT project-privileged). Known discrepancy: the page computes `isManager` as role exactly `'manager'`, whereas DAL `isManagerPrincipal` also includes `company_admin`.

| Feature | Status |
|---|---|
| **T-14 account settings** (2026-05-27) | `/settings` (`account-settings.tsx`), `PATCH /api/me` (allowlist `firstName/lastName/avatarUrl`) + `POST /api/me/password` (Cognito ChangePassword); avatar as S3 key; crew users redirected to `/projects` |
| **T-13 video compression** (2026-05-21) | H.264 sibling-key generation on the VideoPoster Lambda (ffmpeg, 2GB/300s), 500 MB / 10-min caps in `video-limits.ts` — see [[colin/photos-uploads|Photos & Uploads]] |
| **T-15 dictation** | Client-only Web Speech API mic button (`dictation-button.tsx`) in comment composer, daily-log notes, task notes; no backend/Transcribe; absent on Firefox |
| **T-16 crew reviews** (migration 0018, PR #12) | `crew_reviews` table, 1–5 stars + note from corp users on subcontractor crews, one-per-user-per-crew-per-job, per-crew average on `admin-crews.tsx`; distinct from the `review_requested` enum |
| **Company-detail admin** (2026-05-27, super_admin only) | `/admin/companies/[id]` (`admin-company-detail.tsx`); `DELETE .../admins/[userId]` soft-deletes the user (Cognito intact; cross-corp→404, self→403) |
| **QA toolbar / preview-as-user** (`ENABLE_QA_TOOLS`, PR #14) | Sparkles icon, gated QA controller (super_admin in prod); `src/lib/qa.ts`, role switcher (no re-login), date override, 22-item localStorage checklist; `docs/qa-toolbar.md` |

**Labels:** `LabelsModal` is a pure UI component taking an `onSave` callback (commit `ba2809e`) — persistence owned by the caller. `LabelsInline` (project detail) passes a PUT-based save; `LabelsField` (new-project) synthesizes local IDs into a hidden input read by the `createProject` server action as JSON `{text,color}[]`. Fixed 8-color palette in `globals.css:272`. A curated ~41-preset taxonomy (GAF Asphalt UHDZ, James Hardie, AZEK/PVC, etc.) was designed but **not yet wired/seeded**; workflow-stage strings + external-tool refs were deliberately excluded.

**GUN-##### Job ID** (from `external_ids.job_id`, written by inbound Monday sync) surfaces in projects list + detail header and is searchable (commit `2fa6573`), rendered only when non-null.

**Per-user `ui_view` preference** (`'classic' | 'modern'`, `users.ui_view`, migration 0037): company admins default classic→`/projects`; managers/PMs default modern→`/my-day`. Toggle in classic `/settings` + the modern gear-pill modal (`PATCH /api/me`). The modern job-detail view centers on the 43-step phase/section/item tree (read-only), demoting other tabs to deep-link buttons; PMs see SOC/Photos/Permit boxes, managers see Job Total/CO; schedule editing removed (Rain Day button only); labels hidden. See [[colin/my-day|My Day]].

**Stripe:** invoice display, resend (email+amount matching), `PaymentsTab` + multi-account `src/lib/stripe.ts` + `/api/projects/[id]/invoices` + `/resend` (on `feat/stripe-payments-multiaccount`, confirmed 2026-06-03). *(Superseded 2026-05-27 state: Stripe was entirely absent in V1 and `contractAmount/balance/paymentStatus` were read-only mirror columns.)* The `payment_event` enum is still never fired by app code. See [[colin/stripe-make|Stripe & Make]].

Health probe `GET /api/health` is a no-auth liveness check (`{ok:true, service:'wl-companycam', timestamp}`); `/api/ready` reserved for DB/Cognito readiness. `src/proxy.ts` → `src/middleware.ts` rename happened in the `95f71f0` batch alongside notifications + the Vitest suite.

## CompanyCam integration (research, mostly dormant)

CompanyCam import feature committed (`ef8b8bf`), **dormant** pending the `CompanyCamApiToken` SST secret and a product decision on interpreting Project Labels as stages. v2 API auth = long-lived Personal Access Token (Bearer); status is only `active`/`deleted` (true stage lives in Project Labels); rate limits 240 GET / 100 write per min with no `Retry-After` (blind backoff); photo JSON inlines original/web/thumbnail URLs with per-photo MD5 (bytes must be re-uploaded to S3 per the keys-not-bytes rule); **no `photo.deleted` webhook** (needs periodic reconciliation); webhooks HMAC-SHA1. Planned sync mirrors `scripts/sync-from-masterdb.mts` (upsert by external ID in `projects.external_ids` JSONB; new `POST /api/webhooks/companycam`). Multi-tenant token storage would need a `provider_credentials(corporation_id, provider, secret_ref)` table. See [[colin/masterdb-sync|MasterDB Sync]].

## Architecture invariants, gaps & testing

- **External API V1** (`/api/external/v1/`: projects, photos, comments, files, uploads) supports POST of photos/files into an existing project but is **GET-only on `/projects/:id`** (no create endpoint), so the Ops-Portal handoff at scheduling status is not automated — manual `/projects/new` is the only create path. `deep_link` data is complete (`external_ids` JSONB stores `quote_portal_id`, `monday_id`) but has no UI rendering. `corporations.features` JSONB per-tenant flags are designed-for but not built. Native mobile is deferred post-V1 (PWA only, locked in [[colin/decisions|Decisions]]).
- **SOC (Scope of Contract)** has no dedicated table — approximated via Documents-tab non-media files (`nonMediaFiles`) + dollar amounts. **Permit** is only `task_type='permit'` (`schema.ts:~153`), not a project-level record (see [[colin/permits|Permits]]). **Job Total** sources from `projects.contract_value_cents` (synced via `monday-job-sync.ts`) falling back to `contract_amount`; neither is currently threaded into the Project Detail view-model props. Change Orders have a structured `changeOrders` table + external phase/CO APIs + PDF/signing path.
- The **SOW card on the Workflow tab renders hardcoded demo data** ("Roofing / Half-Round Gutters, $116,836.32") for every project (2026-06-15) — not wired to real per-project data; when all phases collapse, the two-pane grid shows a large void.
- The **Joe-redesign** direction (workflow-as-body, tabs demoted to a utility cluster, compact header, no manual labels, Rain Day excluded, role-scoped boxes) has a reference artifact `src/components/project-workfront.tsx` on the `redesign-trash` branch. A full implementation pass (120 files, 1343 tests) was built, verified, then **fully reverted** in-session at the user's request (post-revert clean at 119 files / 1338 tests).
- **Testing:** Vitest-only, ~1,344 unit/API tests across 120 files, **no Playwright/Cypress/E2E** (a readiness gap for a field/mobile app). Route coverage ~63 test files vs ~75 route files (~12 untested). Highest-risk untested writes: the daily-logs route (PM-only auth, corp-tz date selection, 409 duplicate handling) and the client `LabelsModal`. No component test for `ProjectDetail`/`PhaseWorkflowTab`. The `dal.ts` gate, `api-error.ts` contract, and per-`corporation_id` multi-tenancy were confirmed intact (2026-05-27 QA pass).
- `design-previews/` is served statically on **port 4599**; standalone HTML harnesses (inlining literal token values + exact `globals.css`, since Tailwind v4 `@import`/`@theme` can't be linked raw) are the established UI-verification pattern. See [[colin/gotchas|Gotchas]].
- **Daily logs** are PM-gated server-side (`daily-logs/route.ts:53`); notes optional when `health=on_time`, required for `at_risk`/`late` (save blocked until provided).
- **Task preset seeding** requires a manual `npm run db:seed-presets` per corporation (no admin UI trigger) — an operator dependency for onboarding any new Gunner corporation.

## Open questions / TODOs

- **Rain Day (P0, repeatedly flagged 2026-06-15):** no domain model or API. `install_date` is manager-PATCH-able, but there's no `rain_day` table, `update_kind` enum, reason field, timeline-extension API, or audit trail. (The modern mockup envisions a Rain Day confirm button incrementing `rain_days` and pushing end date +1.)
- **Health signal model:** [[colin/my-day|My Day]] red/yellow/green is a hardcoded aggregate (overdue tasks, draft COs, unpaid invoices, stale activity), not a plugin-style signal model. Site check-ins ([[colin/location-pings|Location Pings]]) don't feed project-list/My Day health; missing-location, rain-extension, and missed-workflow-step signals are unmodeled.
- **Phase scheduling/escalation:** `phase_items` lack due dates, expected-by dates, owners, escalation severity, and missed-step reasons — required by the whiteboard's 43-step model; external Tyler API owns mutation.
- **Native push on PM assignment (deferred):** no FCM/APNs/VAPID credential in SST secrets, no `push_subscriptions` device-token table. Assignment already fires `WebhookProjectAssignedUrl` + in-app bell.
- **Batch dispatch product decisions (7 open, `TODO-batch-tasks.md`):** required-flags, Day/phase semantics, conditional show/hide, default assignee, recap-log duplication, per-corp authoring, batch re-dispatch dedup (current behavior: re-dispatch creates a fresh batch without dedup).
- **Guided-tour feature gaps (candidate tickets):** upsell flow (priced additional-services grid), duplicate-photo routing to a prior bucket, window-inventory default-to-previous-window inheritance.
- **CompanyCam decisions (2026-05-27, open):** sync scope, direction (mirror vs two-way), multi-tenant token storage, photo bytes-mirroring vs lazy-fetch (cost-significant at 100k+ photos), backfill depth.
- **Deferred / dead enum values:** `marketing_ping`, `payment_event`, `review_requested` exist in schema but are never fired by app code; `offices.google_review_url` is unwired. Phase-aware checklists + status-pipeline changes flagged V2 by Eric (pending Eddie/Andrew input).
- **Payments/AR view:** Eddie Prchal called out expected-collections / AR-by-job as worth keeping in the daily manager view (possibly an AR board / ops portal).

## Current state / gaps (infra)

- Deployed to a single **`dev`** stage (`project.dev.gunnerroofing.com`); **no separate production stage** yet. See [[colin/ops-deploy|Ops & Deploy]].
- No Sentry, no audit log, no Playwright/E2E. AWS access depends on daily SSO login (see [[colin/gotchas|Gotchas]]).
- `gunner-masterdb` migration (sharing core tables with the iOS stack) was ~90% as of 2026-05-21 — see [[colin/masterdb-sync|MasterDB Sync]].
- The path to the white-label SaaS goal (multi-tenant, ~50k users) is scaffolded but not load-tested.
