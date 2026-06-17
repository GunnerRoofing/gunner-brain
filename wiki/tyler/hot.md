---
type: hot-cache
updated: '2026-06-16'
---

# Tyler Hot Cache — 2026-06-16

## Current State
- **Lambda:** v249 (`gunnerteam-dev-api`, alias `live`, prod Aurora via RDS Proxy)
- **iOS build:** BUILD SUCCEEDED — all cc-789–815 committed to `main`
- **Last session:** cc-789–815 (2026-06-16) — always-on location, Monday forms, 360 gallery
- **omp:** 16.0.5 (updated from 15.11.8 — restart required)

## Process Rule
**Git is the source of truth — solo-maintainer rules:**
- **Solo iOS/backend work** (Tyler only): commit directly to `main`. No branch, no PR.
- **Shared Lambda runtime** (Colin + automated sessions): reconcile before deploying; deploy only from committed `main`; never hand-patch live artifact.
- **Cross-team / shared infra**: PR + owning-team sign-off required.

Full rules: [[CONTRIBUTING]] · [[CHANGE_MANAGEMENT_POLICY]]

## awsmfa (FIXED 2026-06-16)
`~/.zshrc` `awsmfa`: prompts code → `unset AWS_*` → `sts get-session-token` → writes to BOTH shell env AND `mfa` profile in `~/.aws/credentials`. One way to enter the code; works in any shell/process via `--profile mfa`.

## What's Live (v249)

### Backend — location (new this session)
- `gt_location_history` table — append-only breadcrumbs; written by `PATCH /time/location` on every heartbeat (proxy-safe `query()`)
- `GET /time/fleet-locations` — latest position per user (24h, admin/manager)
- `GET /time/location-history?userId&from&to` — breadcrumb trail (≤31d, 10k cap, audited)
- 90-day retention prune (needs recurring EventBridge schedule — TODO)

### Backend — Monday forms (new)
- `POST /submit-dumpster` — board 18406336489, Form Selection = Dumpster Swap
- `POST /submit-material` — same board, branches on materialOption; file columns `filef0m5yqub`/`filed5z4szso`
- `POST /jobs/:id/photos/confirm` — register phase-item photo in gallery + tag passthrough

### Backend — prior (still live)
- `GET /fieldportal/jobs/:id/activity` (lightweight), `/points/history` camelCase, proxy-safe points reads, leaderboard always-on, `src/points/` module, `src/lib/perf.js`, auth userCache

### iOS (cc-789–815)
- Geofence auto-check-in across up to 20 nearest jobs; `evaluateArrival` on app foreground; no confirm banner
- Always-on location heartbeat (background via movement throttle); `PMPickerSheet` locates any PM via `/time/fleet-locations`
- Dumpster Swap + Material Shortage forms (Requests card in JobGuidedView)
- 360 tags persist + confirm to gallery; grouped-by-tag review; tag pill in All Photos
- Form pickers: `confirmationDialog` (stable); persistent field labels; keyboard scroll-to-center

## Schema Gotchas (masterdb — learned cc-789)
- `users.id` is **varchar** → JOINs need `u.id::uuid`
- `gt_user_profile.user_id`/`.org_id` are **varchar** → `::uuid` casts
- `gt_user_profile` has **no `role`** (use `req.user.role`) and **no `display_name`** (build from first/last)
- `pg` string param vs uuid column → `$1::uuid`

## Open Items
- `gt_location_history` 90-day prune — add recurring EventBridge schedule
- `GUNNERCAM_POINTS_WEBHOOK_TOKEN` — replace placeholder in Lambda console
- `REWARDS_ENABLED=false` — set true when policy approved
- Terraform (`stash@{0}`) — IaC reconcile pending
- Employee notice (`employee-notice-points-location.md`) — backed by location store now; still not distributed (HR/legal/IT)
- Dumpster notes column `long_text2prjdbrs` — verify field id

## Key Facts
- Gunner org ID: `69aad261-347c-44db-8e9e-6c25a8509aa3`
- MFA ARN: `arn:aws:iam::980921733684:mfa/tylerMFA`; base profile `default`; mfa profile `mfa`
- Deploy bucket: `gunnerteam-lambda-deploy-useast2`, key `gunnerteam-deploy.zip`
- Migration secret: `gunner-migrate-2026`; invoke with `--qualifier <version>` to hit a fresh container (warm pool drains slowly across deploys)
- Monday Site Manager Forms board: `18406336489`; status labels must match EXACTLY
- `captured[0]` in camera callbacks is `[Int: Data]` dict subscript — safe, do not replace with `.first`

## Migrations Run (prod Aurora)
20260612_points_ledger, 20260612_achievements, 20260612_leaderboard_optin, 20260612_redemptions, 20260612_point_multipliers, 20260612_points_exclusions, 20260613_delta_cursor, 20260613_deduction_rules, 20260613_review_cursor, 20260616_location_history, 20260616_location_history_retention
