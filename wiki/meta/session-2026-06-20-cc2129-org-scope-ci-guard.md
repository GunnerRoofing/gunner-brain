---
type: session
title: session-2026-06-20-cc2129-org-scope-ci-guard
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - backend
  - security
  - soc2
  - tenant-isolation
  - ci
status: stable
related:
  - '[[meta/session-2026-06-20-cc2128-isolation-test-suite]]'
  - '[[gunnerteam/attack-surface-reduction-cc2123-2126]]'
  - '[[gunnerteam/soc2-technical-summary]]'
---

# Session cc-prompt-2129 — CI guard: org-scoping on gt_* queries (CC6.1)

Isolation rests entirely on app-layer `org_id` filtering (no RLS/superuser backstop yet — cc-2127/
2128). The real regression risk is one NEW query that forgets the filter. This is a heuristic static
guard (same pattern as `check-log-hygiene.js`) that fails CI when a `gt_*` query looks unscoped — a
tripwire, NOT a proof (the cc-2128 isolation tests are the proof). **CI-only, NO deploy** (Lambda
stays v342). Commit `6ea4b60`.

## `scripts/check-org-scope.js`
Dependency-free, multi-line-aware string/regex scan of `src/routes/` + `src/lib/`. Flags a db.js
`query()` HELPER call whose inline SQL references a tenant `gt_*` table with NO `org_id` and NO
`// org-scope-ok`. OK conditions: `queryWithTenant(` (never matched — passes org context), an `org_id`
reference in the SQL, or the opt-out comment within the call's line span.

**Matches the helper only** — destructured `query(` + `require('…db').query(` — and deliberately
EXCLUDES `client.query(`/`pool.query(`, which are the hand-rolled `pool.connect()` → `BEGIN` →
`SET LOCAL app.current_org_id` transaction blocks (a separate, reviewed pattern; the prompt scoped to
the `query()`/`queryWithTenant()` helpers).

**Allowlist** of genuinely-global tables (catalog/config/idempotency, explicit + commented):
`gt_rewards_catalog`, `gt_phase_templates`, `gt_template_sections`, `gt_template_items`,
`gt_achievements`, `gt_point_rules`, `gt_point_multipliers`, `gt_webhook_deliveries` (no org_id
column).

## Wiring + verification
- `package.json`: `check:orgscope`. `ci.yml` backend job runs it after the log-hygiene step
  (scripts/ stays tracked via the cc-2104 `!scripts/` gitignore exception).
- Negative-tested: a temp `query('SELECT * FROM gt_time_entries …')` → checker exit 1; removed →
  exit 0. Full backend gate (check / check:logs / check:orgscope / test) green.

## Phase-3 reconcile — 13 helper hits, ALL legitimate (zero real findings)
Each annotated `// org-scope-ok <reason>`:
- **`lib/scheduler.js` (8)** — cron sweeps run across ALL tenants (no req context), scoped by the
  swept row's `user_id`/`id`; includes the 90-day `gt_location_history` retention prune.
- **`routes/fleet/index.js` (2)** — manager-permission checks (does the target user report to
  `req.user.id`) — relationship-scoped, not a tenant data read.
- **`routes/time.js` (2)** — caller's own `gt_user_profile.location_consent` by authenticated
  `user_id` (one is preceded by an explicit `user_organizations` org-membership validation).
- **`routes/points.js` (1)** — service-key `last_used_at` touch by the `id` resolved + authenticated
  via the `key_hash` lookup above (which selects `org_id`).

The ~30 `auth.js`/`users.js` account-deletion cascades are `client.query` inside `BEGIN`+`SET LOCAL`
transactions (scoped by a validated `user_id`) — intentionally outside this heuristic's scope
(excluded by the matcher, not annotated).

## Honest scope
Heuristic — it proves a filter is PRESENT, not that it's correct. Pair with cc-2128 (isolation tests)
for actual evidence. Its job is to stop the silent regression: a new `gt_*` `query()` that forgets
`org_id` fails CI until the author adds the filter / uses `queryWithTenant` / annotates a reviewed
exception.
