---
type: reference
owner: colin
app: GunnerCam
created: 2026-05-07
updated: 2026-06-21
tags: [wl-companycam, schema, postgres, migrations, roles]
status: active
---

# Data Model

Source of truth: `~/repos/WL-CompanyCam/src/db/schema.ts`. Migrations in `~/repos/WL-CompanyCam/drizzle/`.

## Conventions (universal)

- PKs: `UUID DEFAULT gen_random_uuid()`
- Timestamps: `TIMESTAMPTZ NOT NULL DEFAULT now()`
- Soft-delete: `deleted_at TIMESTAMPTZ` (nullable) across tables (photos, sections, `crew_reviews`, offices, …). Hard delete forbidden. Read/list queries filter `isNull(deleted_at)`.
- Every domain table carries `corporation_id NOT NULL` with an index (multi-tenant). The DAL returns `corporationId` after asserting access; writes pass it through.
- Polymorphic creator/actor: `creator_id` + `creator_type` governed by `actorTypeEnum`, usually with a denormalized name. Schema-wide convention — reused for completers, assignees, reviewers. Never a nullable `user_id`.
- S3 stores keys, not bytes — presigned-PUT → `s3Key` browser-upload pattern (`src/lib/s3.ts`); accepted at the original design stakeholder meeting without debate. See [[colin/photos-uploads]].
- snake_case · plural tables · FKs always declared.

## Enums

| Enum | Values |
|---|---|
| `project_status` | lead · sold · scheduled · progress · completed · hold · lost |
| `label_color` | red, yellow, green, purple, blue, cyan, gray, orange |
| `user_role` | super_admin · manager · pm · standard · restricted (see role evolution below) |
| `project_user_role` | pm · sales · estimator · other |
| `actor_type` | user · crew_member · integration · system |
| `update_kind` | photo · file · comment · status_change · assignment |
| `notification_kind` | assignment · comment · status_change · message · marketing_ping · review_requested · payment_event |
| `task_type` | general · material_delivery · material_count · yard_sign_call · inspection · permit |
| `task_status` | open · done |
| `task_input_type` | checkbox · photo_single · photo_multi · text |
| `task_priority` | (see `taskPriorityEnum` in `schema.ts`) |
| `phase_type` | pre_install · project_start · in_progress · close_out · change_order |
| `phase_status` | locked · active · complete |
| `phase_item_type` | photo_single · photo_multi · photo_flagged · text · checkbox · measurement · signature |
| `job_type` | roof · siding · window |
| `change_order_status` | (signed / void lifecycle; see `schema.ts`) |

## Tables

### Tenancy

- **`corporations`** — `id`, `name`, `slug` (unique), `timezone` (default `America/New_York`, HQ default), `logo_url`, nullable `template_api_key` (per-corp outbound GunnerTeam service key, migration `0025_cheerful_red_wolf.sql`; null → skip partner fetch, fall back to `PHASE_TEMPLATES`), `masterdb_org_id` (placeholder, no live Ops Portal sync in V1 — see [[colin/masterdb-sync]]), soft-delete. Records created manually by `super_admin` via `/api/admin/companies`.
- **`offices`** — belongs under `corporations` (FK). Name, address fields, phone, Google Place ID, Google review URL, `timezone`, soft-delete. Google listing/review routing is per-office; office drives which Google review URL a "Send Review Request" uses.

### Identity

- **`users`** — `corporation_id`, `cognito_sub` (unique, primary join from JWT), `username`, `email`, `first_name`, `last_name`, `role`, nullable `office_id` (corp-level admins span all offices), nullable `ui_view` enum (`classic`/`modern`, migration 0037), `avatar_url`. Indexes: case-insensitive unique on `(corp_id, username)` and `(corp_id, email)`; `(corp_id, role)` partial on not-deleted.
- **`crews`** — cross-tenant. `id`, `name`, contact info, `external_ids` JSONB.
- **`corporation_crews`** — M2M, PK `(corp_id, crew_id)`, `active`.
- **`crew_members`** — separate login surface, separate Cognito User Pool (`type:'crew_member'`). `crew_id`, `cognito_sub` (unique), `username` (unique), email + name, `avatar_url`. NOT in `users`, and **never** a `users.role` value.
- **`crew_members`** join via `crew_members` (M:M membership) — see also `corporation_crews`.
- **`manager_assignments`** — true M:M `(manager_user_id, pm_user_id, assigned_at)`, indexed on both columns (a PM can report to multiple managers). Added in migration 0011. `assertCanManageProject` consults it to scope a manager's visibility to their own assignments plus projects where any of their PMs has a `project_users` row.

### Projects (the spine)

- **`projects`** — `corporation_id`, `name`, `customer_name`, `address`, `phone`, `email`, `status` enum, `primary_pm_id` → users, `thumb_url`, `starred`, polymorphic `creator_id` + `creator_type`, `external_ids` JSONB, `job_type` enum (nullable), nullable `install_start_date` / `install_end_date` (migration `0012_clammy_onslaught.sql`; install duration always derived `end − start + 1`, never stored), `contract_value_cents` (Job Total, migration 0032), `rain_days INTEGER NOT NULL DEFAULT 0` (migration 0037), nullable `office_id`, mirror fields `contract_amount` / `balance` / `payment_status`, `archived_at`, `deleted_at`. Indexes: `(corp, status)` partial · `(corp, updated_at)` · GIN on `external_ids`.
- **`project_labels`** — colored tag chips. Position-ordered.
- **`project_users`** — assignments. PK `(project_id, user_id, role_on_project)` so a user can hold multiple roles. Indexes on user (drives "my projects") and project.
- **`project_crews`** — crew assignments. PK `(project_id, crew_id)`.
- **`project_site_checkins`** — `userId` (nullable FK to users; null when incoming email didn't resolve), `externalUserId`, `userEmail`, `userDisplayName`, `checkedOutAt`. Open session = `checkedOutAt IS NULL`. `listOnSiteForProject` is per-single-project; no batched variant yet. See [[colin/location-pings]].

#### `external_ids` JSONB

Keyed per integration — no per-integration columns are added:

| Key | Source / meaning |
|---|---|
| `monday_id` | Monday board item, [[colin/monday-integration]] |
| `job_id` | `GUN-#####` job ID, written by Monday inbound sync |
| `hubspot_id` | HubSpot |
| `companycam_id` | CompanyCam merge-patch upsert match key |

- The CompanyCam upsert matches on `externalIds->>'companycam_id'`, sets `sync_source='companycam'` + `last_synced_at`, and preserves all pre-existing keys.
- The `GUN-#####` job ID is surfaced in the project list row, detail header (`Customer — GUN-01623`), and search via `jobIdOf()` in `queries.ts`; `ViewProject`/`ProjectDetail` carry `jobId` (committed 2fa6573). Only projects that went through Monday inbound sync have one — seed/test projects (e.g. `CLAUDE-TEST-001`) show no Job ID.
- **Monday inbound contract** maps only identity, customer/contact, status, PM email, install dates, region, and contract value. SOC, permit, labels, and P&L cost fields are **NOT** inbound. Job Total = `projects.contractValueCents`, synced via `monday.ts` / `monday-job-sync.ts`. See [[colin/forward-reporting]].

### Tasks (two-layer: flat Field Tasks)

Task schema lives in `schema.ts` ~581–814. Two orthogonal axes — **do not conflate**:

- `task_type` — roofing-category taxonomy (predates GunnerTeam integration).
- `task_input_type` — iOS render modality (introduced migration 0019); exactly 4 canonical values `checkbox`, `photo_single`, `photo_multi`, `text`.

Tables: `tasks`, `task_templates`, `task_template_items`, `task_steps` (corp-scoped templates).

- **`tasks`** — polymorphic `assignee_id` + `assignee_type` (made polymorphic in migration 0011: added `assignee_type actor_type`, dropped FK to `users`, CHECK = both NULL together OR `assignee_id IS NOT NULL AND assignee_type IN ('user','crew_member')`; existing rows backfilled to `user`). Completion triplet `completed_at` / `completed_by_id` / `completed_by_type` with a coherence CHECK (migration `0017_broken_moira_mactaggert.sql`, T-4 external-tasks work — **reverses** the earlier T-4 lock of "no `completed_at` column"). Also `task_type` (default `general`, backfilled, migration 0015) and `quantity`.
- **`task_steps`** — named photo positions (Front, Back, …) for `photo_multi` tasks. `photo_multi` without steps → 400.
- Legacy input-type aliases `photo → photo_single` and `form → text` are normalized only at the inbound API boundary by `parseInputType()` in `src/lib/task-input.ts`; the DB enum and external read path see only the 4 canonical values. Unknown type → 400.
- `POST /api/projects/[id]/tasks` uses `db.transaction()` to atomically insert the task row + any `task_steps`, preventing orphaned tasks.
- **Templates** (Stream C, decision T-12) reversed T-4: migration 0015 added `task_templates` + `task_template_items`, shipped admin CRUD at `/admin/task-templates` + project "Apply template" (committed `adcc39a`). Migration 0021 extended `task_template_items` with `notes`, `trade_tag`, `phase`, `input_type`, `required` to power the preset library (one seeded "PM Field Checklist"); generic template feature ignores them (default null/false) → zero regression.

### Phase workflow (guided documentation)

Jobs have a two-layer model: the **phase-based guided workflow** (new) and the flat personal **Field Task** list (existing `POST /tasks`); both coexist on the iOS job view. Phases: Pre-Install → Project Start → In Progress → Close Out, plus Change Order (triggerable anytime).

Migration `0023_brave_boom_boom.sql` added 5 tables + 5 enums (`phase_type`, `phase_status`, `phase_item_type`, `job_type`, `change_order_status`) plus a `projects.job_type` column:

- **`project_phases`**, **`phase_sections`**, **`phase_items`**, **`phase_item_photos`**, **`change_orders`**.
- **`phase_sections`** is polymorphic: belongs to either a `phase_id` OR a `change_order_id`, CHECK enforces exactly one non-null — keeping `phase_items` / `phase_item_photos` uniform across both parents.
- Sections are the primary unit of trade branching (names like `Prep — Roof`, `Install — Window`); items + photos hang beneath, so soft-deleting a section cleans its whole subtree (one Todd Thomas cleanup soft-deleted 5 sections / 18 open items / 0 photos in one transaction).
- **`phase_items`** stores only the completion triplet (`completed_at`, `completed_by_id`, `completed_by_type`) — no stored name; `loadProjectPhasesForUi` resolves user-completer names via `fetchUserNames` (added alongside `fetchUserEmails` in `external-phases.ts`), falling back gracefully for integration completers (e.g. Tyler's app via API key).
- A project with `trade = null` AND `job_type = null` is a generic job and materializes ALL trade branches (roof + siding + window); setting a specific value restricts future expansion. New projects get this generic 'all' default because Monday provides no `job_type` at creation — accepted until job-type classification ships.

### Payload tables

- **`photos`** — `corporation_id`, `project_id`, polymorphic `creator_id` + `creator_type`, denormalized `creator_name`, optional `crew_id` for the crew badge, `s3_key`, `content_type`, `byte_size`, `caption`, `captured_at`, soft-delete. Index: `(project, captured_at)` partial on not-deleted.
- **`files`** — analogous, but `name` instead of caption, no `captured_at`. Index: `(project, created_at)` partial.
- **`comments`** — `project_id`, polymorphic `author_id` + `author_type`, denormalized `author_name`, `body`. Index: `(project, created_at)` partial.

### Activity feed engine

- **`updates`** — one row per project event, drives the Activity **and** Comments tabs (LEFT JOIN comments/photos/files). Writing only to child tables leaves content invisible — fix pattern is an idempotent `INSERT…SELECT…LEFT JOIN IS NULL` to create matching `updates` rows (a one-shot backfill created 360 photo + 48 file + 134 comment update rows). Polymorphic creator. Polymorphic payload pointers (exactly one of `photo_id` / `file_id` / `comment_id` matches `kind`); `photo_id` FK is `onDelete: cascade` so deleting a `photos` row removes its activity rows. Denormalized `preview_text` and `preview_image` so feed render skips payload joins. Two timestamps: `occurred_at` (field time — for photos copies `captured_at`) and `created_at` (when recorded).
  - **`bucket_day`** is a **stored generated column**: `((occurred_at AT TIME ZONE 'America/New_York')::date)`. Indexed via `(project_id, bucket_day, occurred_at)` (alias `idx_updates_project_bucket`) — the most important index in the schema. Powers the day-grouped activity feed (the differentiator from CompanyCam's endless scroll); stays under 100ms with 10k rows.
  - Other indexes: `(project, kind, occurred_at)` for tab filtering · `(corp, created_at)` for `modified_since` outbound sync.

### Reviews & logs

- **`crew_reviews`** (migration `0018_cute_zaran.sql`, applied via `db:migrate-safe`) — follows the `daily_logs` pattern: polymorphic creator + denormalized `creator_name`, `rating integer CHECK (rating BETWEEN 1 AND 5)`, nullable `body`, `project_id NOT NULL` cascade FK, soft-delete, indexes on `crew_id` + `corporation_id`, and a partial unique index `(crew_id, project_id, creator_id) WHERE deleted_at IS NULL` (one review per user per crew per job).
- **`daily_logs`** — collect health, notes, ETA. The modal does **NOT** collect `percentComplete` even though the column exists → progress visuals stay thin unless seeded/set elsewhere.
- **`change_orders`** — structured workflow object (external API, phase-item evidence, amount, signed/void lifecycle, Stripe draft invoice). Surfaced via Documents/Workflow flows, not a first-class manager card. Files: `change-order-modal.tsx`, `/api/projects/[id]/change-orders/route.ts`. See [[colin/stripe-make]].

### Notifications

- **`notifications`** — bell feed + future email/push fan-out. `recipient_id` polymorphic (no FK; app-enforced). `update_id` nullable (for kinds with no associated update — marketing_ping, payment_event). Tracks `read_at`. Indexes: `(recipient_type, recipient_id, created_at)` partial on unread for the bell badge query · full inbox index without the partial.

## Roles & permissions

Two orthogonal permission layers:

1. Global `users.role` enum.
2. Per-project `project_users.role_on_project` enum (`pm | sales | estimator | other`). A `standard` user with `role_on_project='pm'` gains project-manage access **without** a global role change.

### Global role enum evolution

| Date | Migration | Change |
|---|---|---|
| 2026-05-25 (T-9) | `0011_tranquil_shard.sql` | Added `pm` via `ALTER TYPE user_role ADD VALUE 'pm' BEFORE 'standard'` → six tiers `super_admin → admin → manager → pm → standard → crew_member` |
| 2026-05-27 | `0013_little_excalibur.sql` | **Retired `admin`**: backfill admin→manager, DROP/CREATE the type. Enum now `super_admin, manager, pm, standard, restricted`; `manager` is the top company-level role |

- `ALTER TYPE … ADD VALUE` must be applied with `db:migrate-safe`, **not** `db:migrate` (fails inside Drizzle's default transaction wrapper).
- Migration 0011 also shipped a backfill `scripts/promote-existing-pms.mts` promoting `standard` users with any `project_users.role_on_project='pm'` row to global `role='pm'`.

### Assignment & access gating

- **Task assignment** is tier-gated: assign to anyone strictly below your tier; PMs assign laterally to other PMs; crew/standard self-assign only. Server-side `canAssignTo()` in `src/lib/dal.ts` (~505–547; manager TIER 3 → PM TIER 2 allowed); client-side `canAssignBetween` in `src/lib/role-hierarchy.ts`.
- **Admin · Users page** surfaces for managers (scoped to their PMs) with Manager column, PM role pill, Deactivate, and `PUT /api/admin/users/[id]/managers` (replaces the full M:M set). Managers create/deactivate only their own PMs; role changes are admin-only; admins can deactivate anyone except `super_admin` and themselves.

### Read-scoping behavior

- **`listExternalProjectsForUser`** branches on role: company-wide WL roles (`manager`/`company_admin`/`super_admin`) return all corp projects; project-scoped roles (`pm`/`standard`/`restricted`) use a correlated EXISTS against `project_users`; an unrecognized email returns an empty list immediately — mirrors in-app DAL behavior intentionally. See [[colin/external-api-integration]].
- **`listProjectsForPrincipal`** (`src/lib/queries.ts`) previously silently dropped all but the first PM and first Sales assignee. Fixed to build `assigneesByProject` from every `project_users` row, dedupe per user (PK is `(project, user, role)`), sort by role priority (pm → sales → estimator → other) then name.
- **`ViewProject`** now carries `assignees: ViewUser[]` (all deduped/sorted `project_users` rows) instead of separate `pm`/`sales` scalars; `crew` stays separate (it's a crew entity). Files: `view-models.ts`, `queries.ts`, `projects-list.tsx`, `queries.test.ts`.
- **"Last Updated"** projects-list signal changed from `projects.updated_at` (overwritten by every sync, incl. no-ops) to the MAX of real activity — feed events, task changes, phase status changes, phase-item completions (incl. Tyler's checklist) — falling back to `created_at`. Implemented as one grouped MAX union query in `listProjectsForPrincipal`; list sort uses the same signal.

## Timezones

Three sources coexist and can differ in multi-region setups:

| Source | Scope |
|---|---|
| `corporations.timezone` | HQ default |
| `offices.timezone` | per-site |
| viewer browser `Intl` zone | client |

- The hardcoded `America/New_York` `bucket_day` (above) disagrees with site-local time for non-NY offices.
- **Planned strategy** — site time (project's office zone) as primary with the IANA abbreviation always rendered next to timestamps. Phase 1 (no migration): swap `corpTz` for `siteTz` from `project.officeId → offices.timezone`, fallback `corporations.timezone`. Phase 2 (follow-up): drop the generated `bucket_day` and recompute at write time from the project's site zone.

## SOC / permit (no dedicated field)

- No dedicated SOC field or permit-status table. "Permit" lives only as `taskType='permit'` on tasks/templates (see [[colin/permits]]). SOC-like progress is approximated via phase workflow (`external-phases.ts`, `phase-templates.ts`) and daily-log health/ETA. A dedicated permit badge/status/due/completed state would need a new source or contract.

## Migration cheat-sheet (selected)

| Migration | Adds |
|---|---|
| `0011_tranquil_shard` | `pm` role · `manager_assignments` M:M · polymorphic `tasks.assignee` · promote-existing-pms backfill |
| `0012_clammy_onslaught` | `projects.install_start_date` / `install_end_date` |
| `0013_little_excalibur` | retire `admin` role |
| `0015` | `task_templates` + `task_template_items` · `tasks.task_type` + `quantity` |
| `0017_broken_moira_mactaggert` | task completion triplet + coherence CHECK |
| `0018_cute_zaran` | `crew_reviews` |
| `0019` | `task_input_type` enum |
| `0021` | `task_template_items` preset columns (`notes`, `trade_tag`, `phase`, `input_type`, `required`) |
| `0023_brave_boom_boom` | phase workflow (5 tables, 5 enums, `projects.job_type`) |
| `0025_cheerful_red_wolf` | `corporations.template_api_key` |
| `0032` | `projects.contract_value_cents` |
| `0037_wealthy_korath` | `projects.rain_days` · `users.ui_view` (applied to dev RDS 2026-06-12) |
| pending-but-applied-on-dev (as of 2026-06-21) | P&L receipt tables · `integration_api_keys.allowed_scopes`; `drizzle-kit generate` reports no further drift |

See [[colin/ops-deploy]] for migration application mechanics (`db:migrate` vs `db:migrate-safe`).

## Key invariants worth knowing

- `bucket_day` regenerates from `occurred_at` automatically — DB is the source of truth. App code must not write it.
- `creator_name` / `author_name` denormalization drifts when users rename. (Known tech debt in [[colin/risks]].)
- `primary_pm_id` on `projects` can drift from the join in `project_users`. (Same.)
- No DB-level RLS — cross-tenant isolation enforced in app code (`src/lib/dal.ts`). Compounding tech debt.
- Install duration is always derived, never stored. Job Total is `contract_value_cents` (Monday-synced).

## Open questions / TODOs

- `company_admin` may silently see fewer projects than expected: `dal.ts` treats it as manager-equivalent for company-wide access, but `queries.ts` (~line 392) may not extend the same breadth — the manager cockpit can lie by omission. **Flagged P0.**
- Frontend role checks (`shell.tsx` `isSuperAdmin`/`isManager`, `sidebar.tsx`, `topbar.tsx`, `admin-users.tsx`) hard-depend on DB enum values with no legacy fallback — a leftover `role='admin'` row silently loses manager nav and shows an unstyled raw "admin" string.
- Manager-assignment UI is single-select only: `admin-users.tsx` line 424 binds `value={u.managers[0]?.id}` and sends one id, discarding all but the first manager despite the M:M backend supporting many.
- `job_type`/`trade` are null at creation (Monday doesn't classify), so new projects materialize all roof+siding+window In Progress sections until job-type classification ships.
- Daily-log modal doesn't collect `percentComplete` though the DB column exists.
- GUN-##### job IDs only exist on Monday-synced projects — testing the UI requires running the sync or patching `external_ids` via the DB tunnel.
- Deferred refactors: `outbound_integrations` table (until a 2nd partner — `template_api_key` on `corporations` covers the single-partner case today); a batched on-site-checkins variant; Phase 2 timezone migration off the hardcoded-NY `bucket_day`.

## Helper code locations

- `src/lib/dal.ts` — `assertCanReadProject`, `assertCanManageProject`, `canAssignTo`, single-resolver permissions
- `src/lib/queries.ts` — typed query helpers (`listProjectsForPrincipal`, `jobIdOf`)
- `src/lib/role-hierarchy.ts` — client-side `canAssignBetween`
- `src/lib/task-input.ts` — `parseInputType()` legacy alias normalization
- `src/lib/external-phases.ts` — `loadProjectPhasesForUi`, `fetchUserNames` / `fetchUserEmails`
- `src/lib/phase-templates.ts` — `PHASE_TEMPLATES` fallback
- `src/lib/view-models.ts` — DB row → UI shape transforms
- `src/lib/cognito.ts`, `src/lib/session.ts` — JWT verification + cookie session
- `src/lib/s3.ts` — presigned PUT/GET helpers
- `src/lib/notifications.ts` — write-fanout helpers
- `src/db/seed.ts` — local + dev seed

_Last full merge from ~26 work sessions, 2026-05-21 → 2026-06-21._
