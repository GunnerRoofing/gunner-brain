---
type: session
title: "Session 2026-06-19: cc-1500–1505 Terraform Infra Hardening + iOS Receipt Fixes + Wiki Lint"
created: 2026-06-19
updated: 2026-06-19
tags:
  - session
  - terraform
  - lambda
  - aurora
  - ios
  - eventbridge
  - rewards
  - wiki-lint
  - location
status: stable
related:
  - "[[tyler/hot.md]]"
  - "[[gunnerteam/aws-environment]]"
  - "[[gunnerteam/masterdb-developer-handoff]]"
  - "[[meta/session-2026-06-18-cc864-871-lockfix-ping-consent]]"
  - "[[meta/session-2026-06-18-cc1111-1126-receipt-scanner-phase2]]"
---

# Session 2026-06-19: cc-1500–1505 Terraform Infra Hardening + iOS Receipt Fixes

Lambda: v291 → v294 (3 publishes). iOS: BUILD SUCCEEDED, no new build this session.
All 6 cc-prompts run and verified. Pending list reduced from 10 items to 3.

---

## Housekeeping

### /clear skill deleted
The `/clear` skill was identified as redundant: it runs `/save` + reminds the user to type `/new`, which is a host-side command the skill cannot invoke. Effectively `/clear` = `/save` with an extra step the user still has to do manually. Skill deleted from `~/.omp/agent/skills/`. Workflow is now simply `/save` + `/new`.

### Skill inventory
13 skills installed: `autoresearch`, `canvas`, `defuddle`, `discovery-mode`, `hindsight`, `obsidian-bases`, `obsidian-markdown`, `obsidian-second-brain`, `save`, `wiki`, `wiki-ingest`, `wiki-lint`, `wiki-query`. Three are always-on (`hindsight`, `discovery-mode`, `obsidian-second-brain`).

---

## cc-1505 — Lambda env drift reconciled into Terraform (v292)

**Problem:** `lambda-api.tf` manages the entire `environment.variables` map with no `ignore_changes` on `environment`. Any var set in the Lambda console is drift — the next `terraform apply` silently rewrites the entire env map and wipes it.

**Delta found (11 drift keys):**

| Key | Type | Source |
|---|---|---|
| `ALERT_EMAIL_LIST` | String | `email.js:104` |
| `DB_CONNECT_TIMEOUT_MS` | String | `db.js:24` via `intEnv` |
| `FIELD_PORTAL_API_URL` | String | `fieldportal.js`, `time.js` |
| `FIELD_PORTAL_API_KEY` | SecureString | same |
| `FIELD_PORTAL_WEBHOOK_SECRET` | SecureString | same |
| `FIELD_PORTAL_PHOTO_COMMENT_WEBHOOK_SECRET` | SecureString | same |
| `FIELD_PORTAL_PROJECT_COMMENT_WEBHOOK_SECRET` | SecureString | same |
| `GUNNERCAM_POINTS_ORG_ID` | String | `points.js` |
| `GUNNERCAM_POINTS_WEBHOOK_TOKEN` | SecureString | `points-webhook.js` (net-new) |
| `LOCATION_PING_FORWARD` | String | `time.js` |
| `REWARDS_ENABLED` | String | `points.js` |

**Additional findings:**
- `COMPANYCAM_API_KEY`: in tf + SSM, but missing from live Lambda — restored by apply
- `NOTION_TOKEN`: zero code references anywhere, no Notion routes — removed from tf
- 3 SSM params already existed; 8 created new (6 interactive SecureStrings via `read -rs VAL`)

**Changes:** `data "aws_ssm_parameter"` block + env line for each key added to `lambda-api.tf`. Rule documented in `CLAUDE.md` under "Learned from mistakes".

**Complication:** `aws_security_group.audit_archiver` replacement was stuck during apply (old VPC ENIs draining). Used `-target=aws_lambda_function.api` to apply only the Lambda env update. Also imported `aws_security_group.lambda_api` (created by a partial apply, not written to state). v292 published and aliased.

**Rule:** New/changed env var = SSM param (SecureString for secrets) + `data "aws_ssm_parameter"` + env line in `lambda-api.tf`, then `AWS_PROFILE=mfa terraform plan` (must show NO env removals) → apply → publish-version → alias live. NEVER set env vars in the Lambda console.

---

## cc-1127 — iOS receipt verify fixes

**Phantom empty row:** `ForEach($lines) { if line.category == .item { row } }` yields an empty view for each fee line, but List still renders a blank cell. Fix: replaced with index-based `ForEach(itemIdx, id: \.self)` / `ForEach(feeIdx, id: \.self)` where `itemIdx = lines.indices.filter { lines[$0].category == .item }`. No `if` inside `ForEach` = no blank cells. Delete offset mapping uses `offsets.map { itemIdx[$0] }` to hit the correct global index.

**Editable receipt total:** Added `@State private var totalInput: Double?`, seeded once via `.onAppear { if totalInput == nil { totalInput = total.map(abs) } }`. `receiptTotal` computed property now reads `totalInput.map(abs)` instead of `total.map(abs)`. Summary section renders a `TextField("0.00", value: $totalInput, format: .number)` instead of a static `Text`. Editing re-evaluates `totalsMatch` live. Line items sent to P&L are unchanged.

---

## cc-1501 — REWARDS_ENABLED=true for dev (v293)

**Pre-flight:** `rewardsEnabled()` gates `POST /points/redeem`. Provider is per-SKU from `gt_rewards_catalog.provider`. Checked for Tremendous credentials: no `TREMENDOUS_API_KEY` in SSM → any `tremendous`-backed catalog item would fail with 401 and auto-refund points. Zero real gift card risk. `internal` provider makes no external calls.

SSM param updated `false → true` (`/gunnerteam/dev/REWARDS_ENABLED`). Data source already wired from cc-1505. Single `-target=aws_lambda_function.api` apply. v293 published. `POST /points/redeem` no longer returns `403 Rewards are not enabled yet`.

**Note for later:** When wiring Tremendous for real, set `TREMENDOUS_SANDBOX=true` + `TREMENDOUS_API_KEY` (test key) via SSM + tf before adding catalog items with `provider='tremendous'`.

---

## cc-1500 — 90-day gt_location_history prune, daily (v294)

**Problem:** The `20260616_location_history_retention` migration ran once on deploy but there was no recurring enforcement. SOC 2 data-minimization requires ongoing deletion.

**Changes:**
- `scheduler.js`: added `pruneLocationHistory()` (plain `query()`, global delete, not tenant-scoped) + dispatch branch `'prune-location-history'` before the `else` in `runScheduledTasks`
- `eventbridge.tf`: added `prune-location-history` to `scheduled_tasks` map with `cron(0 8 * * ? *)` (08:00 UTC daily, ~03:00–04:00 ET off-peak). Rule/target/permission generated by existing `for_each`
- `lambda.js`: updated stale comment on `20260616_location_history_retention` migration to point at managed EventBridge path

**Verify:** `aws lambda invoke` with `{"source":"aws.events","detail":{"task":"prune-location-history"}}` → `{"ok":true,"task":"prune-location-history"}` ✅

**Bonus fix — `null_resource.clear_alias_routing`:** The provisioner was using `--routing-config AdditionalVersionWeights={}` (CLI shorthand). This is silently a no-op — prior canary weights persist. Found when v293 alias showed `FunctionVersion: 294` but `RoutingConfig: {"AdditionalVersionWeights":{"293":1.0}}`, routing 100% of traffic to v293. Fixed to `printf '{"AdditionalVersionWeights":{}}' > /tmp/reset-routing.json` + `--routing-config file:///tmp/reset-routing.json`. Deploy recipe in hot.md updated to match.

---

## cc-1504 — Terraform stash@{0} dropped

`stash@{0}` = `WIP on reconcile/v233` (71 files: 8 terraform, 8 API, 55 iOS). Full diff read via `/tmp/stash0.patch`.

**Result: 100% superseded.** All API deltas already in main (`sendAlertEmail`, PII redaction, `etHour<14` guard, announcements priority/is_read, auth LATERAL JOIN + ipKeyGenerator, fleet `checkMaintenanceAlerts` + `awardPoints`). All terraform deltas superseded by cc-1505/1500 (stash reverted to old VPC `vpc-0530f022b0273f215`, old SGs, old morning/afternoon split EventBridge rules). All 55 iOS files diverged. `companycam.js` deletion in stash correctly not applied (file still needed in main).

stash@{0} dropped. Remaining: `stash@{0}` = upload-monday-null-check, `stash@{1}` = vehicle-inspections (both untouched).

---

## cc-1503 — Aurora idle_in_transaction_session_timeout=30s

**Background:** 2026-06-17 lock-contention storm — unsettled `Runtime.NodeJsExit` left an open transaction holding an `audit_log` lock for 12+ minutes. Pool-side `DB_IDLE_TX_TIMEOUT_MS` (5 s default) catches well-behaved connections. This adds the server-side cluster param as a backstop for anything that bypasses the pool.

**Finding:** Both Aurora clusters (`gunner-masterdb-dev-*` and `gunner-masterdb-production-*`) already on custom cluster param groups — no new group needed, no reboot. Both on `aurora-postgresql 17.7`.

Prod param group: `gunner-masterdb-production-masterdbclusterparametergroup-bzfauowx`
Previous value: `86400000` ms (24 h = effectively disabled)
New value: `30000` ms (30 s)

Dynamic param → applied immediately with `ApplyMethod=immediate`. `DBClusterParameterGroupStatus: None` (no pending-reboot). No downtime.

**Defence in depth:** Pool fires at 5 s → cluster kills at 30 s → any stranded transaction dead within half a minute regardless of pool state.

---

## Pending (3 items)

| Item | Blocker |
|---|---|
| `COLIN_PNL_API_URL` | Colin implements `/jobs/:jobId/pnl/line-items` |
| Employee notice (`employee-notice-points-location.md`) | HR/legal/IT sign-off |
| GUNNERCAM points webhook smoke-test | Colin installs his side; verify `POST /points/webhook` no longer `401 bad signature` |

---

## Key Durable Wins

- **Lambda env = 100% Terraform-managed.** Console edits = drift. Rule in `CLAUDE.md`.
- **`AdditionalVersionWeights={}` CLI shorthand is a no-op.** Use `file:///tmp/reset-routing.json`. Fixed in `null_resource.clear_alias_routing` and deploy recipe.
- **Aurora prod cluster already on custom param group.** No ceremony needed for future param changes — just `modify-db-cluster-parameter-group` with `ApplyMethod=immediate`.
- **FIELD_PORTAL_* is a separate integration from COMPANYCAM_*.** Not duplicates.

---

## Wiki Lint — 2026-06-19

Full report: [[meta/lint-report-2026-06-19]]

226 pages scanned. 9 issues found and fixed. 0 remaining.

**Auto-fixed (9):**
- Stale version: `overview.md` + `aws-environment.md` v277 → v294
- Dead links in `git-source-of-truth-policy.md`: `[[gunnerteam/hot.md]]` → `[[tyler/hot]]`; `[[shared/decisions/]]` → `[[shared/decisions/README]]`
- Frontmatter gaps: added missing `created`/`updated` to POSTMORTEM, git-source-of-truth-policy, employee-notice, CONTRIBUTING, CHANGE_MANAGEMENT_POLICY

**Orphan false positives (4 — all clean):**
Scanner flagged `runbooks/incident-response`, `summaries/system-security-plan`, `concepts/_index`, `sources/_index` as orphans. All are linked from `wiki/tyler/index.md` via path-relative wikilinks (`[[runbooks/incident-response]]` etc.). The scanner only matched exact bare-filename links and missed path-qualified ones. Both `_index` files are real, full navigation pages — not scaffold stubs.

**Lint scanner note:** Path-relative wikilinks (e.g. `[[runbooks/x]]` inside `tyler/index.md`) resolve correctly in Obsidian but read as dead to a naive `[[filename]]` text matcher. Scope the orphan check to bare-filename links only, or resolve relative to the containing folder.
