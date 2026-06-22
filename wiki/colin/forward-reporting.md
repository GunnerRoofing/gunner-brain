---
type: reference
owner: colin
app: GunnerCam
created: 2026-06-21
updated: 2026-06-21
tags: [wl-companycam, reporting, metrics, forecast]
status: active
---

# Forward-Looking Manager Reporting

The manager-and-up reporting surface: a forward-looking metrics bar above the projects list / home screen plus an Analytics modal forecast dashboard. Shows jobs expected to close, expected collections ($), and installs starting next/following week, with a **This Week / This Month / This Quarter** toggle and prior-period comparison. Two computation engines are written as pure functions so they can later be lifted into Leo's ops portal (see [[colin/people-and-context]]).

## Data model: contract value & financial fields

| Field | Source | Role |
|---|---|---|
| `projects.contract_value_cents` | Monday (job dollar value, cents) | The forward-reporting money field. Added in drizzle migration **0032** (clean `ADD COLUMN`, no destructive DROPs). |
| `projects.contract_amount` / `balance` | masterdb mirror | Display-only, empty for Monday-driven jobs. Kept side-by-side intentionally — see [[colin/data-model]], [[colin/masterdb-sync]]. |
| `invoices_cache` | DB mirror (fills as Monday invoicing webhooks fire) | Collections/AR; invoice `dueDate` drives the metrics window. |
| `change_orders` | DB mirror | CO data; not yet rolled into P&L. |

- Install/schedule dates flow from Monday and the mirror tables.
- For a "Job Total" card, the lower-risk path is to display the already-synced `contract_value_cents` first, adding another source only if the product definition of Job Total diverges from it.

## Architecture: how metrics are computed and rendered

Single server-function data path — the manager analytics path **extends `getHomeMetrics` rather than adding new API routes**, passing plain serializable numbers/date-strings as client props.

| Layer | File |
|---|---|
| Metric computation | `getHomeMetrics` in `src/lib/queries.ts` |
| Forecast dashboard data | `getForecastDashboard` in `src/lib/queries.ts` |
| Manager fact-gathering | `getManagerDashboard` in `src/lib/queries.ts` (resolves "today" server-side) |
| View-model types/helpers | `src/lib/view-models.ts` (`HomeMetrics`, `metricsWindows`, `priorPeriodWindow`) |
| Server-component boundary | `src/app/(app)/projects/manager-home-metrics.tsx` |
| Reporting bar (client) | `src/components/metrics-bar.tsx` |
| Analytics modal (client Dialog) | `src/components/forecast-dashboard.tsx` |
| Tests | `view-models.test.ts`, `queries.test.ts` |

- **Standard patch pattern:** add view-model helpers/types in `view-models.ts` → extend the return of `getHomeMetrics` in `queries.ts` → render in `metrics-bar.tsx`.
- **Metric definitions (as of 2026-06-15):** revenue = contract value by `installEndDate`; collections = outstanding unpaid invoices by `dueDate`; closeouts = in-play jobs whose `installEndDate` lands in the target window.

### The two pure engines (ops-portal-ready)

Deliberately written with **no `server-only`/DB/AWS/Next imports** so they lift cleanly into Leo's ops portal; only the fact-gathering layer (`getManagerDashboard`) and React components stay app-specific.

| Engine | File | Responsibility |
|---|---|---|
| Reporting | `src/lib/project-reporting.ts` | Jobs-closing, money-expected, install counts for Week/MTD/QTD with prior-period + YoY pacing. (Earlier name `computeReportingMetrics`.) |
| Health | `src/lib/project-health.ts` | Red/yellow/green project tiering. |

- `project-health.ts` verified live against 48 dev projects: 5 red, 29 yellow, 14 green. Red = overdue install or no comms for X days; yellow = unsigned CO / unpaid start payment / pending signature / open high-alert task. Sample reasons: "Emergency task open", "No update in 5 days", "Unsigned change order".

## The reporting bar (forward-looking)

- A manager-and-up bar sits above the projects list / on the home screen with forward-looking metrics: jobs expected to close, expected collections ($), and installs starting next/following week.
- **Superseded direction:** the bar originally used to-date windows (quarter-start → today). As of **2026-06-15** `metricsWindows` in `view-models.ts` was rewritten to forward-looking windows (today → end of week/month/quarter) compared against an equal-length trailing span; labels relabeled **This Week / This Month / This Quarter**; the bar now shows job count plus dollar pipeline.
- "Expected collections" only counts projects whose Monday invoicing webhook has fired (cache fills as Monday rows are edited), so it undercounts until all rows are touched.
- **Live dev snapshots:** 2026-06-10 deploy showed 13 jobs closing within 7 days, 15 starting within 14 days, 13 of 52 projects with invoice data cached; the pure `project-reporting.ts` engine returned Jobs = 11, installs-next-week = 4, pacing ▲267% vs last week, Money = $0 (`invoices_cache` not yet populated).

## Analytics modal & forecast dashboard

`forecast-dashboard.tsx` is a Dialog opened from the reporting header, driven by `getForecastDashboard`, with four views: pipeline by stage, revenue forecast by month, collections forecast, and install schedule.

- **Live dev data (2026-06-15):** pipeline $1,366,215 (Scheduled 30 jobs · $1.02M; In Progress 11 · $344K); Jun revenue $708K, Jul $658K; install schedule 11→7→3→3→1→1 over six weeks; collections forecast $0 (data gap, see Open questions).
- **Pipeline-by-stage reads the live Monday Take Off board** via `getTakeoffPipelineByStage()` in `src/lib/monday.ts`, replacing the local-rows-only approach. Paginates via `items_page`/`next_items_page`, buckets count + dollar by Stage label, dormant-safe (returns `null` on token/error → falls back to local rows). Committed `d365dad`, deployed to dev 2026-06-15; live board had 1,277 items across 3 pages. See [[colin/monday-integration]].
- **Decision:** the funnel displays **raw Monday Stage labels** (Prep, New - Needs Review, Escalation, Scheduling, etc.) instead of collapsing into the fixed 5-bucket enum (lead/sold/scheduled/progress/hold), which lost granularity. Committed `7fa34f5` (amended for a missing type import), deployed dev 2026-06-15. `lead`/`sold` stay zero because they live on the HubSpot/sales pipeline board, not the Take Off board.

## "Joe metrics" / weekly operational view

Joe's whiteboard view = current-week revenue/collections, following-two-weeks revenue/collections, and closeouts this week; derived from the existing corp-scoped project scan (no new data source). Revenue uses `contractValueCents` + install end dates; collections use unpaid invoice balances by due date.

- **Decision:** this view **coexists with** (does not replace) the existing This Week/Month/Quarter + forecast analytics. Most urgent metrics surface on [[colin/my-day]]; deeper forecast lives behind a separate Analytics/Forecast section to avoid crowding My Day.
- **Implementation churn (2026-06-15):** a compact "Joe week" strip was added to `metrics-bar.tsx` (computed in `getHomeMetrics`) in one session, then **fully reverted in the same session** at the user's request in another. Concurrent subagents found the Joe-week type/helper/tests already partly present from parallel edits — agents must read current file state before patching (see [[colin/gotchas]]).
- **Latest landed form (2026-06-12, branch `feat/redesign-v2`):** the Analytics page gained Joe's metrics — Collected vs Revenue for current week and following 2 weeks, plus Job Close-outs this week (with a job list, each linking to its project) — via a new `getWeeklyOutlook` query in `queries.ts`; existing analytics cards left untouched.

## Window semantics & bugs (gotchas)

- **Window-semantics mismatch** (`src/lib/view-models.ts:1132`): "Week" is forward-looking (full Mon–Sun) while MTD/QTD are backward-looking (start-of-period → today), so Week can show more jobs than MTD. Completed jobs fall out of the open-job count (`queries.ts:809`), so MTD/QTD effectively count only overdue/still-open jobs with `installEndDate` before today — reading more like "slipped jobs" than true month-to-date closes. Unresolved (see Open questions).
- **MTD/QTD prior-period bug (fixed):** `priorPeriodWindow()` built the prior window as `startIso + spanDays` without clamping to the prior month's last day; for today = 2025-03-31 the prior window computed Feb 1 → Mar 03, double-counting Mar 1–3 rows and inflating `vsPriorPeriodPct`. Fixed by clamping to prior month/quarter last day; regression tests added (parallel QTD bug also fixed).
- **Hydration bug (fixed):** seeding `computeReportingMetrics()` with the client clock (`todayLocalIsoDate()` / `Date.now()` in render) caused SSR/hydration mismatch. Fix: resolve "today" server-side in corp timezone via `getManagerDashboard` and thread `todayIso` as a required prop.
- **`install_overdue` health signal (fixed):** originally over-fired on any past-end job with no daily log, contradicting the row's INSTALL badge which treats "no log" as untracked not failed. Guarded to fire only when an install log explicitly exists but is past its end date.
- **Caret rotation gotcha:** the reporting block's collapse caret can't be driven by a CSS descendant rule in the live Next.js dev page (silently overridden, likely specificity / hot-recompile) — use an inline `style={transform: collapsed ? 'rotate(-90deg)' : 'none'}` on the icon element.

## Ops, deployment & product framing

- **Backfill script** `scripts/backfill-monday-contract-value.mts` populated `contract_value_cents`: 24 of 37 dev projects got values totaling $1.39M; 13 had no Monday value. Follows the one-off pattern (postgres + `DATABASE_URL`, DRY_RUN default, `SYNC_APPLY=1` to apply); Monday API token piped from SSM into env to avoid logging (`/wl-companycam/<stage>/monday-api-token`, see [[colin/aws-infra]]). Migration 0032 applied to dev via SSM tunnel before backfill.
- **Decision (in `DECISIONS.md`, see [[colin/decisions]]):** Eddie/Eric intend the manager dashboard (reporting block + high-alert rows) to eventually fold into Leo's ops portal as a "daily/live view" tab, not a standalone system — hence the pure-function engines.
- **Product framing:** the daily-jobs-running view should be a **snapshot of a single day** across all services/projects ("here's the day"), not a feed of comments/activity (Eddie's CompanyCam critique: any comment surfaces as noise, hiding the true operational snapshot).
- **AR board (desired):** per-job payments / expected collections scoped per job is a wanted feature for Joe — Eddie wants the GunnerCam Payments-tab data to surface in the ops portal as an AR board rather than living in GunnerCam.

## Open questions / TODOs (as of 2026-06-21)

- **Fourth KPI unchosen.** Manager top-strip wants four KPI cards; six candidates exist; `metrics-bar.tsx` (~line 78) currently shows three (jobs expected to close, expected collections, installs starting next week).
- **"Closeout" lacks a firm definition** — candidates: `installEndDate`, the `close_out` phase status/completion, or COC signature.
- **Analytics windows don't match spec.** Live windows (this week/month/quarter, next 6 weeks/months) don't yet match the spec ("current week + following 2 weeks + closeouts this week"); as of some 2026-06-15 sessions still unimplemented, and a placement decision remains (analytics still hangs off `/projects` rather than [[colin/my-day]], the intended true home). `getWeeklyOutlook` on `feat/redesign-v2` (2026-06-12) is one landed implementation — reconcile branch state.
- **P&L / revenue analytics are placeholders** (`queries.ts` ~line 830, `view-models.ts` ~line 1315): `contractValueCents` stands in for real P&L with no cost basis, no margin calc, no CO rollup; the 50%-margin placeholder graph and CO-into-P&L rollup are absent.
- **MTD/QTD semantics mismatch unresolved** (as of 2026-06-10): they exclude completed jobs so don't accumulate over the period. Two candidate fixes — (1) include completed jobs whose `installEndDate` fell in the window so MTD accumulates (matches manager expectations), or (2) extend windows to end-of-month/quarter making everything a forecast.
- **Collections forecast reads $0 on dev** — a data gap, not a code bug: depends on invoice `dueDate` fields populated in the metrics-window cache, which fills as Monday invoicing webhooks fire (dev has no future-dated invoice data yet). See [[colin/monday-integration]].
- **Guided-tour line items** under each phase (Project Start / In Progress / Close Out) still need reconciliation against Eddie's "Guided Tour projects per day" Google Doc (change-order guided tour already complete and separate).

_Sources: 2026-05-21 → 2026-06-21; ~13 distinct work sessions._
