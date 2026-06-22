---
type: reference
owner: colin
app: GunnerCam
created: 2026-06-21
updated: 2026-06-21
tags: [wl-companycam, my-day, frontend, dashboard]
status: active
---

# My Day

My Day is the GunnerCam home screen for all non-crew users as of 2026-06-21. It is the flagship full-screen dashboard: health-sorted job cards, a stage filter, a focus/fan-out workflow panel, finance/SOW panels, and per-PM manager tooling. This note is the deep-dive; for the one-paragraph catalog entry see [[colin/feature-inventory]] and for the end-user walkthrough see [[colin/user-guide]].

## History & current status

My Day has lived three lives. Treat anything older than 2026-06-11 as superseded.

| Date | Event |
|---|---|
| ~2026-05-25 | My Day exists as a **PM-only** job-first view (active-install cards, today's tasks, daily-log to-do). Managers never had it. |
| 2026-05-27 | **Removed** — commits `e984f36` ("Remove My Day; restrict daily logs to PMs") + `1630b71`, branch `feat/remove-my-day-pm-only-daily-log`. `src/app/(app)/my-day/page.tsx` deleted, sidebar entry removed, managers landed on `/projects`. |
| 2026-06-11 | **Reintroduced** as the new manager-facing home. |
| 2026-06-12 | Real-data rebuild (`feat/redesign-v2`, later parked to `redesign-trash`) replaced mock data with real jobs: red/yellow/green health cards sorted red-first, phase-banner filtering, rain-extended chips, PM names, day-of-install indicators, unread Messages strip, completed jobs collapsed into a bottom group. |
| 2026-06-15 → 2026-06-21 | Heavy evolution: focus-mode layout, finance panels, SOW exhibit, PM attribution, task-split, "Linden Crisp" styling. |

- As of 2026-06-21, `/` (a server component at `src/app/(app)/page.tsx`) does a Next.js `redirect()` to `/my-day`, the primary authenticated entry point. Projects is demoted to admin/reference only.
- **Stale path:** DAL "wrong surface" fallback redirects and the sidebar's "Projects (Deprecated)" entry still point at `/projects`, so Projects remains the implicit home for role-mismatch error paths — pending cleanup.

## Architecture & components

- **Two competing implementations coexist; only `MyDayContent` is live.**
  - **Active:** `MyDayContent` (`src/components/my-day-content.tsx`), mounted at `/my-day/page.tsx`, fed by `listProjectsForPrincipal`.
  - **Legacy orphaned:** `MyDayJobs` (`my-day-jobs.tsx`) + `getMyDayJobs`/`getMyDayTasks` queries + `ViewMyDayJob`/`ViewProjectAssignee` view-models — not wired to any route. Do not build on it without confirmation. `MyDayJobs` still renders `p.labels`; `MyDayContent` does not (satisfying "manual labels not on My Day").

| File | Role |
|---|---|
| `src/components/my-day-content.tsx` | Cards, attention groups, focus workflow, P&L, finance/SOW panels, self-contained detail popup |
| `src/components/my-day-stage-filter.tsx` | Filter keys/labels + arc-hop animation + `STAGE_FILTER_COLORS` |
| `src/components/shell/floating-chrome.tsx` | Search/bell/account chrome + admin classic toggle |
| `src/lib/view-models.ts` | `attentionState()` (~L1034), `installBadgeState()`, `ViewProject` |
| `src/lib/queries.ts` | `listProjectsForPrincipal` list query |
| `src/lib/external-phases.ts` | `loadBulkProjectPhasesForUi`, `loadProjectPhasesForUi` |

- **Shell:** Managers/PMs get no sidebar or hamburger — My Day is full-screen and all personal controls live in `floating-chrome.tsx` (bare Gunner logo top-left; standalone notification circle with unread badge; user pill with name + role label + gear → Account settings / Sign out; opening one panel auto-closes the other). Super admin and crew keep the classic shell (`topbar.tsx`); both shells can toggle to/from My Day.
- `/my-day` feeds `MyDayContent` from `listProjectsForPrincipal` (ALL visible projects), **not** a dedicated `getMyDayJobs` query — any "active installs only" view needs a conscious query switch.
- Card focus mode opens a `WorkflowPanel` directly, bypassing the tab-based project detail UI; the workflow renderer is My Day's own, separate from project-detail's `PhaseWorkflowTab`.
- My Day has its own self-contained project detail popup inside `my-day-content.tsx`, entirely separate from `project-detail.tsx`; its media/task components are defined inline. Changes to one do not affect the other.
- **CSS location matters:** most `.mdc-*` focus-view CSS (profit, finance, spark, payment panels) lives in a `LIST_CSS` string constant **inside the component file**, NOT globals.css; the focus-view named grid (`project`/`sow`/`workflow` areas) is in globals.css. See [[colin/gotchas]].

### `ViewProject` shape

Carries: `id`, `name`, `customer`, `address`, `phone`, `email`, `jobId`, `status`, `labels`, `assignees` (`ViewUser[]` — **project role lost at list level**), `crew`, `photos`, `files`, `unread`, `updated`, `thumb`, `recentThumbs`, `starred`, install dates, `latestLog`, `attention`, `currentPhase`, `contractValueCents`, plus `workflowPhases` and `invoiceFinance` (hydrated at list time). List query is in `src/lib/queries.ts`.

### Attention logic

Red/yellow/green is centralized in `attentionState()` in `view-models.ts` (~L1034); the signal is derived from hardcoded aggregates (overdue tasks, draft COs, unpaid invoices, stale activity), **not** a first-class signal model.

## Card grid, layout & focus mode

- **Card UI contract (authoritative as of 2026-06-15):** stage filters, red/yellow/green concern groups, photo-led rows, address/customer, PM faces, P&L spark, attention badges, workflow focus panel, plus a bottom categorization key explaining the groupings.
- Cards have **split click targets:** card body enters focus mode (clicking the focused card again exits); chevron opens an inline per-card stage dropdown floating in-column without shifting the grid.
- **Card grid columns — CONFLICT:** a 2026-06-14 decision locked **3 columns regardless of viewport** (narrow scrolls horizontally); a responsive-breakpoint version (1400px→2col, 1000px/700px→1col) also appears in the tree. Treat 3-col-default as intent, with breakpoints as the as-built fallback. See [[colin/decisions]].
- **Focus/fan-out mode is full-screen (100dvh):** nav chrome + footer hidden via a body-level data flag, app body starts at y=0. Document scroll is locked; inner scroll regions handle the workflow ledger and detail pane. The inner focus root must own scrolling (`height:100dvh; overflow-y:auto`) because html/body overflow is hidden.
- **Latest focus-mode layout (2026-06-21):** four adjacent columns — project/workflow, SOW/permits, profit, manager tasks — at ~360/360/250/230px @1280px, replacing an earlier `space-between` that left a large gap; a compact-density layer is scoped to focus mode only.
- Earlier settled widths (2026-06-14): focused card 430px matching the workflow slab; floating profit mini-panel 138px.
- Workflow slab capped at **490px** in default no-detail state (iterated 720→560→520→490px); detail pane widens layout only when a content-bearing item is selected (`my-day-content.tsx` ~L1273). Pinned project card must **NOT** use `position:sticky` in viewport-locked focus mode (causes workflow to slide under it). See [[colin/gotchas]].
- 2026-06-15: floating-shell padding halved 28px→14px (`globals.css .app-body`) plus tightened card internals to reduce ellipsis truncation.

## Workflow / phases panel

Workflow data comes from **Tyler's iOS app**, which owns the 43-step field workflow; GunnerCam is **read-only** on phases/phase_items. See [[colin/external-api-integration]].

- Template has three top-level phases — **Project Start → In Progress → Close Out** (Pre-Install + its Window Inventory section removed 2026-06-09 from `phase-templates.ts`) — with job-type branch sections; "43 steps" is an approximation across branches.
- `GET /api/projects/[id]/phases` serves phase/task data for the fan-out panel. Loading is lazy-fetch (on card expand, not at grid render). A promise-based cache warms each card on pointerenter/focus; a background sweep warms all visible cards 1.2s after page settle, 3 at a time.
- **Perf pass (2026-06-12, deployed to dev without a commit):** steady-state `/phases` is **ONE batched DB round trip** after auth — phases, sections, items, photo counts join through `project_phases` on `(corporationId, projectId)` in a single `Promise.all`; completer display names left-joined (deleted `fetchUserNames`); `assertCanReadProject` stays sequential before the read. Previously ~6–8 serialized round trips.
- **First-ever open of a legacy project** triggers `materializeProjectPhases` (via `ensurePhasesCurrent`) inside the request — originally serial INSERTs per phase/section/item (multi-second over the SSM tunnel); now batched to one INSERT per table with ids re-matched by natural key. Second open always skips materialization and is fast.
- `loadBulkProjectPhasesForUi` (`external-phases.ts`, 2026-06-16) hydrates already-current workflow rows for ALL visible projects at page load in one set-based query, surfaced as `workflowPhases` on `ViewProject`. It is **deliberately read-only** (no materialization/fixup); legacy/missing workflows still fall back to the per-project `/phases` route, which can be slow on stale state.
- `loadProjectPhasesForUi` backs the project-detail "pizza ticker" + Workflow tab (`PhaseTicker`, `PhaseWorkflowTab`): four-chunk banner (active=blue, complete=green, locked=grey) with X/Y counts; read-only phase→section→item tree with REQUIRED pills and "Completed by … · date"; per-item photos/notes/measurements via lazy fetch + lightbox.
- `completedById` is now surfaced on the workflow item view-model (previously trimmed before UI) to enable **per-PM attribution**.
- **2026-06-16 refinements:** bubble-down inline detail pane opens under the selected task row (not page bottom); 360-capture sibling rows hidden with photo counts rolled up to the visible parent 360 item.
- **Gotchas:** `.mdc-wf > * { position:relative; z-index:1 }` shadows the shared lightbox CSS, making the lightbox render inline instead of fullscreen; lightbox opens must key off **stable photo IDs, not signed URLs**. See [[colin/gotchas]].
- The project-detail Workflow tab was redesigned (vertical timeline rail, spring expansion, staggered entrance, 680px column cap, ~27px rows). Its two-pane responsive collapse is keyed to **viewport width (1250px), not actual column width** — premature squeeze when the side drawer is open.

## Project detail popup / utility drawer

- `GET /api/projects/[id]/details` (`route.ts` + `route.test.ts`) is the internal cookie-auth JSON detail route added to lazy-load full project detail for the popup. It calls `requirePrincipal()` then `assertCanReadProject()` before `getProjectDetailForPrincipal()`. *(Earlier nuggets noting "no such route exists" are superseded.)*
- `getProjectDetailForPrincipal()` does **NOT** do its own access check — every caller must call `assertCanReadProject()` first (crew principals especially). It is updates-backed and caps activity/comments at the latest **200 updates rows**, so busy projects show incomplete history.
- A scoped fast-path was added to the detail query to skip phase/on-site workflow state (which the popup never rendered) while keeping task + assignment data — dropping tasks entirely broke the Tasks tab.
- Popup resized to ~75vw/75vh (capped 1360×780 @1920×1080), centered with scrim overlay + pop-in animation; a 20s client-side detail prefetch/cache starts on launcher hover/focus/open.
- **Tab evolution:** started with 5 tabs (Activity / Tasks / Media / Comments / Documents); the **Tasks tab was removed from the popup** (2026-06-16) — tasks live in regular project detail + the separate `ManagerProjectTasksPanel` on the My Day page (kept). *Supersedes a 2026-06-15 nugget that ADDED a Tasks tab to the utility drawer; the 2026-06-16 removal is the later state.*
- Documents tab redesigned to a two-pane workspace (card grid + preview panel; PDFs embed via presigned URL in iframe, non-previewable files get an app-style face). Tab-rail CSS is a fixed grid — must update column count when adding/removing tabs (4→5 broke Documents wrapping). See [[colin/gotchas]].
- `POST /api/projects/[id]/comments` accepts `{ body, photoId?, fileId?, parentCommentId? }` with exactly one optional target (validated same-project/corp, not soft-deleted) and returns only `{ id }` — callers must re-fetch (`router.refresh` pattern) since there's no optimistic merge and no edit/delete route.
- **Shared components:** `MyDayTargetComments` (Activity/Media/Documents) and `MyDayFileCard` (Activity feed + Media) can't be deleted when scoping affordances out of one tab. Removing the Media comment affordance introduced `MyDayMediaFileCard`; the `mdc-popup-media-grid` class is shared with the Activity strip and needs a scoped override (minmax 132px→200px, 10px gap → ~6 larger cards/row).

## Finance / P&L / invoices

- **The P&L sparkline is a confirmed PLACEHOLDER:** deterministic fake math seeded by project id (`my-day-content.tsx` ~L405); no real cost, margin, or P&L history data exists in the repo. The project DTO carries only `contractValueCents` — no persisted cost or gross-margin field. **Must be made real or visibly marked unavailable before launch** (hard blocker; see Open questions).
- **Invoice loading is cache-first (2026-06-16):** `ViewProject.invoiceFinance` is hydrated from `projects.invoicesCache` at list-query time (reusing the existing attention-status parse) — total due, total paid, latest 3 displayable rows render immediately. `/api/projects/[id]/invoices` is kept as a background refresh; `invoicesCache === null` falls back to live Monday API (see [[colin/monday-integration]]). Malformed cache rows count toward totals/attention but are excluded from the visible list unless they carry a real Monday sub-item id.
- `FloatingProfitPanel` (focus-mode P&L tracker) split its single `loadingFinance` flag into separate `invoiceLoading`/`changeOrderLoading` so each reveals independently (change orders are DB-backed/fast; invoices arrive from snapshot first). It separates profit/margin from payment status into two cards. The invoice-paid meter renders at 0% even with no Monday total (previously coerced to a misleading "0% Paid"). Expanded panel: 430px wide, 96px sparkline, shows contract value, est. profit, est. cost, buffer/shortfall vs a 50% target. *Was once accidentally hidden by a CSS rule (not removed from the tree).*
- The focus-mode Profit card was unified into a finance panel: profit chart + invoice-paid meter + Monday-backed invoice list + change-order ledger. CO creation stays in the existing PDF/sign modal (not duplicated). Receipt cost rows from the P&L ingest endpoint surface as a "Receipt Costs" ledger section (2026-06-18), aggregated per project (costs negative, credits positive), defaulting empty.
- The front-page card P&L tracker (`PnlSpark` — sparkline, percent bar, contract value) renders in a right-side `.mdc-fin` column; it's hidden inside the focused card where the larger floating panel appears. **Gotchas:** panel container used `align-items:flex-end` causing misaligned zoomed layouts; `PnlSpark` SVG needs `preserveAspectRatio="none"` or the line won't widen with its container.

## Manager tasks, PM attribution & timeline planning

- **PM identity** in My Day relies on per-project role assignees (`roleOnProject === 'pm'`), **NOT** global user roles; highest-priority role used when a user has several. Switched from generic user assignees to `ViewProjectAssignee` carrying per-project role. **CAVEAT:** at the list-query level `assignees` is still typed `ViewUser[]` so project role is lost — cards can only sort PM-first heuristically. A true PM accountability column needs a role-aware contract.
- **Dual-PM attribution strip** renders only when a project has exactly two `pm`-role assignees (hidden for 1 or 3+): two-column layout (stacks ≤390px) above the phase ledger, with each PM's avatar/name, completed count, contribution meter, phase chips, and recently-completed items.
- **Manager-only per-project task panel** (`ManagerProjectTasksPanel`) in the focused view: shows install dates, PM extension requests, overdue PM task alerts; a pure read model derived from PM daily logs + open tasks (no separate "manager task" schema entity). Saves date changes via `PATCH /api/projects/[id]` then `router.refresh()`. Timeline edits route to the existing install-timeline editor (calendar button), not an inline editor. A top-right two-card rail places P&L left, Manager tasks (slimmer) right.
- **PM task-split (uncommitted WIP in working tree, 2026-06-17):** `WorkflowPmSplit` opens in-place in the focus view (replacing a navigate-away link); `PmSplitModal` extracted to a shared module reused by focus view + project Tasks tab. Toggle-board UI: per-task owner chips, quick actions (Split evenly / All to PM / Reset to both), schedule date field, live tally. The "Split tasks" badge is always visible on 2-PM jobs but **red only while tasks are co-owned, calm once fully split**. Appears only for projects with exactly 2 PMs that have dispatched checklist tasks.
- `PATCH /api/projects/[id]/tasks/[taskId]` extended to accept `dueDate` and `scheduledAt` for split-popup scheduling. Date inputs needed **both** `onChange` and `onInput` handlers (automation/native pickers don't reliably fire React `onChange`). See [[colin/gotchas]].
- **"Plan timelines"** manager-rail action opens a per-PM tabbed checklist planner: each PM tab has its own start/end span (default = install window) and selected template tasks. Batch dispatch API extended with per-assignment `startDate`/`endDate` (old global schedule payload kept for back-compat).
- Demo seed: a 2-PM dispatched checklist seeded into dev RDS on the **Figueroa Metal** project (Sarah Gengo + Colin Wong, same 4 tasks).

## Scope of Work / SOC / role-gated tools

- **LOCKED role split** (multiple 2026-06-15 confirmations; origin = mid-June 2026 Joe demo whiteboard): PM sees **SOC + Photos + Permit**; Manager/super_admin (company_admin treated as manager) **additionally** see **Job Total + CO**. Fields are role-exclusive, not shared (PMs shouldn't see money; managers shouldn't see PM permit detail). Reuse existing flags `isGlobalPm`/`isManager`/`isSuperAdmin`/`isPmOrPrivileged`; missing data → disabled/placeholder, **not** omitted. See [[colin/decisions]].
- **SOC = Scope of Contract** (confirmed ~2026-06-12). NOT yet a first-class doc type — documents are generic templates in `src/lib/document-templates/index.ts`; SOC/Permit/Job Total are not yet semantic UI labels or doc types.
- `ScopeOfWorkExhibit` (`src/components/scope-of-work-exhibit.tsx`, CSS in globals.css) already renders SOW detail as a modal popup via `createPortal` to `<body>` (the inline-accordion dropdown only ever existed in the design-preview harness). Has a `variant='body'` mode (hides header/summary chrome, opens ledger sections by default) for the focus panel. Progressive disclosure: totals/section prices/short summaries always visible; full line-item text behind a hover/focus/click floating popover. Rendered as a sibling top-aligned div beside `WorkflowPanel` (two-panel flex, absolutely positioned right so it can't inflate grid rows).

## Daily logs & INSTALL badge (early foundation, 2026-05-27)

- Migration `0014` (`drizzle/0014_glorious_giant_girl.sql`, branch `feat/pm-daily-logs`, commit `191b66d`) created the `daily_logs` table: `daily_log_health` enum (`on_time`/`at_risk`/`late`), 14 columns, partial unique index on `(project_id, log_date)`, CHECK constraints (percent 0–100; notes required unless `on_time`), cascade FK, soft-delete via `deleted_at`. See [[colin/data-model]].
- **Smart INSTALL badge** derives state from the latest daily log via `installBadgeState()` in `view-models.ts` (replacing date math): `upcoming → start → on-time/at-risk/late → complete → ?`; `?` only on past-end installs with ≥1 log but never 100%; legacy no-log jobs stay `complete`. Chain: `installBadgeState` → `InstallCell` (`projects-list.tsx`) → `[data-status]` CSS.
- `percent_complete` was removed from the PM daily-log form/API/view-models/queries but the `daily_logs.percent_complete` column and manager-side badge logic were **KEPT** (no migration); the "100%→complete" path is dormant until a manager-side writer exists (recorded in [[colin/decisions]]).
- "Fill out today's log" row opens `daily-log-modal.tsx` (refactored to parent-controlled) in-place; on submit the card flips to "logged". The derived to-do is computed (not stored) from the absence of today's `daily_logs` row in the corporation timezone (`todayIsoDateInTimeZone`).

## Design direction & styling

- **"Linden Crisp"** is the chosen My Day look (2026-06-17, from a 6-variant harness `design-previews/focus-view-typography-variants.html`): Hanken Grotesk, 16px rounded cards, soft shadows, warm-brown money color, **full-strength urgency reds** (NOT softened). Scoped to `.mdc-vtroot` so the rest of the app stays on Barlow. Touched `src/app/layout.tsx` (`--font-hanken`), `globals.css` (labeled block), `scope-of-work-exhibit.tsx` (`sow-popup--my-day`). App global font was earlier changed Inter→Barlow.
- **Stage rail "Gunner Flag" palette** (2026-06-17): navy = Project Start, brand red = In Progress (replacing yellow — Colin rejected the traffic-light feel), white/cool green = Close Out. `STAGE_FILTER_COLORS` in `my-day-stage-filter.tsx`; Action Needed accents switched yellow→Gunner blue; amber tokens elsewhere (margin warnings, favorite stars) left alone.
- Stage filter is a controlled component (value/counts/onChange) with **arc-hop squash-and-stretch orb animation** across All/Starred/Project Start/In Progress/Close Out.
- Completed projects in the projects list got a gray (`#94A3B8`) left-accent bar instead of the on-track green: `data-group` on each row (`projects-list.tsx`) + `.cc-row[data-group="done"]{box-shadow:inset 4px 0 0 #94A3B8}` placed AFTER the green rule (`globals.css`).
- **CSS gotchas** (see [[colin/gotchas]]): in globals.css a later `padding` shorthand overrides earlier longhand `padding-left/right` (`.app-body`) — order matters. Mobile workflow header hides the decorative progress meter to avoid horizontal scroll. Focus mode can leak a bottom green strip (footer underlay) if focused content doesn't own the full-viewport background.

## Open questions / TODOs (as of 2026-06-21)

- **P&L is a hard blocker:** no real cost, margin, or P&L history data exists — must wire a real data contract or mark unavailable before launch. Data sources for SOC, Permit, Job Total, CO, and P&L are still undefined and are the main Project Detail implementation blocker.
- **ON TIME column display rule not locked:** binary "On time" vs "4d behind", rain-day adjustment math, and staleness threshold are undefined (existing code has multi-state `on_time`/`at_risk`/`late`/`missing`).
- **Project Detail redesign not done:** still defaults to the `activity` tab (`project-detail.tsx` ~L208) with the 7-tab model (Activity/Media/Comments/Tasks/Workflow/Documents/Payments) instead of the locked workflow-first full-screen layout with utilities demoted to a dropdown. Direct `/projects/[id]` nav defaults to `activity`, not `workflow` — possible regression vs workflow-first intent.
- **Role-gating largely unimplemented:** PM-vs-manager job-detail branching receives role flags but doesn't use them; only install-date editing and the metrics/forecast bar are manager-gated. Highest-value missing manager view: per-PM red/yellow rollup ("Marcus has 4 red jobs").
- Agreed manager projects-table columns (PROJECT / PHASE / PM / ON TIME / P&L) NOT yet landed in `projects-list.tsx`; issue badges stay under PROJECT.
- **Office scoping** exists in the schema but ALL queries ignore it — every manager has corp-wide cross-office visibility (likely unintended). See [[colin/data-model]].
- **Rain Day / manual schedule extension** explicitly DEFERRED / out of scope (no UI or API; PMs can't push install dates).
- **On-site check-in glow** ("On site" pill + per-avatar ring when a PM is checked in) designed but NOT built: `listProjectsForPrincipal` doesn't fetch `project_site_checkins`, and My Day is a one-shot server render with no polling/revalidation, so glow state would freeze at page load without a polling layer. See [[colin/location-pings]].
- My Day doesn't surface sent-but-unsigned signature requests (only open tasks); `signatureRequests` is never joined.
- The two My Day implementations (`MyDayContent` vs `MyDayJobs`/`getMyDayJobs`) still need reconciliation; legacy path should not be built on without confirmation.
- Change orders have two parallel surfaces (external/iOS workflow API path + legacy document modal) that need reconciliation before redesign.
- Analytics planned to add current-week / following-2-weeks / closeouts-this-week buckets; "closeout" definition (`installEndDate` vs `close_out` phase vs COC signature) not locked. See [[colin/forward-reporting]].
- `npm run lint` currently fails on pre-existing undefined symbols in `project-detail.tsx`: `ToolBox`, `UtilityButton`, `PermitPanel`, `JobTotalPanel`.
- **No DOM/e2e tests** for My Day cards, floating chrome, or project-detail tab/focus behavior — manual browser QA only (data layer is well-covered). Browser QA repeatedly blocked locally: dev-auth shim (`DEV_AUTH_USERNAME=cwong`) DB lookup fails; Next.js won't start a second dev server (lock); Turbopack serves stale CSS after globals.css edits (needs `.next` clear / restart); in-app preview gives the hidden tab a 0×0 viewport (unreliable clicks/screenshots, requires Playwright fallback). See [[colin/gotchas]].

## Deploy state (as of 2026-06-21)

- SOW feature was **local-only** at session end (never deployed to dev).
- The 2026-06-12 phases perf work was deployed to dev as an **uncommitted working tree** (SST deploys the whole tree — see [[colin/ops-deploy]]).
- Multi-PM task-split is **uncommitted WIP** (not on a branch).
- `/admin/users` PM/manager setup is **unreachable** from the floating-chrome nav for managers/PMs.
