---
type: hot-cache
updated: '2026-06-19'
---

# Tyler Hot Cache — 2026-06-19

## Current State
- **Lambda:** v307 live (`gunnerteam-dev-api`, alias `live`, prod Aurora via RDS Proxy)
- **iOS build:** BUILD SUCCEEDED — cc-1801 committed to `main`
- **Last session:** 2026-06-19 — cc-1801: fleet doc views fixed. Removed captured auth.currentToken threading; all 7 network calls (upload, view, thumbnail across VehicleDocumentViews + OtherDocumentsViews) now fetch fresh token via await auth.token(). BUILD SUCCEEDED.
- **OMP:** 16.0.7

## Process Rule
**Git is the source of truth — solo-maintainer rules:**
- **Solo iOS/backend work** (Tyler only): commit directly to `main`. No branch, no PR.
- **Shared Lambda** (Colin + automated sessions): reconcile before deploying; never hand-patch.
- **Cross-team / shared infra**: PR + owning-team sign-off required.

## awsmfa
`awsmfa` in `~/.zshrc`: prompts code → `unset AWS_*` → `sts get-session-token` → writes to BOTH shell env AND `mfa` profile. One command, works everywhere.

## Deploy Recipe (CRITICAL — both fixes required)
```bash
rm -f /tmp/gunnerteam-deploy.zip && \
zip -r /tmp/gunnerteam-deploy.zip . -x "*.git*" "node_modules/.cache/*" > /dev/null && \
aws s3 cp /tmp/gunnerteam-deploy.zip s3://gunnerteam-lambda-deploy-useast2/gunnerteam-deploy.zip \
  --region us-east-2 --profile mfa && \
aws lambda update-function-code --function-name gunnerteam-dev-api \
  --s3-bucket gunnerteam-lambda-deploy-useast2 --s3-key gunnerteam-deploy.zip \
  --region us-east-2 --profile mfa --query 'FunctionName' --output text && \
aws lambda wait function-updated --function-name gunnerteam-dev-api --region us-east-2 --profile mfa && \
VERSION=$(aws lambda publish-version --function-name gunnerteam-dev-api \
  --region us-east-2 --profile mfa --query 'Version' --output text) && \
printf '{"AdditionalVersionWeights":{}}' > /tmp/reset-routing.json && \
aws lambda update-alias --function-name gunnerteam-dev-api --name live \
  --function-version "$VERSION" \
  --routing-config file:///tmp/reset-routing.json \
  --region us-east-2 --profile mfa --query 'FunctionVersion' --output text && \
echo "v$VERSION"
```
- `rm -f` first — `zip -r` merges into existing archive (stale zip bug)
- `file:///tmp/reset-routing.json` — inline shorthand `AdditionalVersionWeights={}` is a CLI no-op; prior canary weights silently persist. Fixed in `null_resource.clear_alias_routing` (cc-1500).

## Shipped Tonight (cc-1500–1505, v292–v294)

### cc-1505 — Lambda env drift → Terraform (v292)
- 11 console-only drift keys wired into SSM + `lambda-api.tf` data sources + env block
- `COMPANYCAM_API_KEY` restored (was missing from live Lambda despite being in tf/SSM)
- `NOTION_TOKEN` removed (zero code refs — dead)
- `GUNNERCAM_POINTS_WEBHOOK_TOKEN` set net-new from CompanyCam webhook config
- Rule documented in `CLAUDE.md` under "Learned from mistakes"
- `terraform plan` now clean on env — no more silent console-drift wipes

### cc-1501 — REWARDS_ENABLED=true for dev (v293)
- SSM param updated `false→true`; tf already had the data source from cc-1505
- Pre-flight clear: no Tremendous creds in SSM → no real gift cards possible
- `POST /points/redeem` no longer returns `403 Rewards are not enabled yet`

### cc-1500 — 90-day gt_location_history prune, daily (v294)
- `scheduler.js`: added `pruneLocationHistory()` + dispatch on `'prune-location-history'`
- `eventbridge.tf`: `cron(0 8 * * ? *)` rule/target/permission via existing `for_each`
- `lambda.js`: stale comment on `20260616_location_history_retention` migration updated
- **Bonus:** fixed `null_resource.clear_alias_routing` — provisioner was using CLI shorthand (`AdditionalVersionWeights={}` = no-op); now uses `file:///tmp/reset-routing.json`. Resolves recurring canary-drift gotcha.
- Verified: `{"ok":true,"task":"prune-location-history"}` on v294

### cc-1504 — terraform stash@{0} reconciled
- `reconcile/v233` stash (71 files, v233-era) fully superseded by main (v294)
- All API deltas already in main: `sendAlertEmail`, PII redaction, `etHour<14` guard, announcements priority/is_read, auth LATERAL JOIN + ipKeyGenerator, fleet `checkMaintenanceAlerts` + `awardPoints`
- All terraform deltas superseded by cc-1505/1500 (old VPC, old SGs, old morning/afternoon EventBridge split)
- stash@{0} dropped. Remaining: stash@{0}=upload-monday-null-check, stash@{1}=vehicle-inspections

### cc-1503 — Aurora idle_in_transaction_session_timeout=30s
- Prod cluster already on custom param group — no new group, no reboot needed
- Was: `86400000` ms (24 h = effectively disabled). Now: `30000` ms (30 s)
- Dynamic param applied immediately; `DBClusterParameterGroupStatus: None`
- Server-side 30s + pool-side 5s (`DB_IDLE_TX_TIMEOUT_MS`) now both enforced

### cc-1127 — iOS receipt verify fixes
- Phantom empty row above "Taxes & Fees": replaced filtered `ForEach($lines)` with index-based `ForEach(itemIdx/feeIdx)` — no `if` inside ForEach, no blank cells
- Editable receipt total: `@State private var totalInput: Double?`, seeded once on `.onAppear`, drives `receiptTotal` → `totalsMatch` live via `TextField`

## Pending (2 items — both external blockers)
- **`COLIN_PNL_API_URL`**: unset until Colin implements `/jobs/:jobId/pnl/line-items`
- **Employee notice** (`employee-notice-points-location.md`): HR/legal/IT sign-off
- **GUNNERCAM points webhook**: Tyler's half done (token set, `POST /points/webhook` handler live). Colin needs to install + smoke-test his side; verify no `401 bad signature`.

## What's Still Live (v294 = everything below)

### Backend — receipt scanner
- `POST /jobs/:jobId/receipt/extract`: dual-image best-of selection (cc-1122/1126)
- `POST /jobs/:jobId/receipt/commit`: unchanged (cc-1103)

### Backend — location
- `POST /time/location-batch`: consent-gated; bulk INSERT, 2000 ping ceiling
- `LOCATION_PING_FORWARD=true`: pings forward live to Colin (GunnerCam)
- `GET /time/location-compliance`: dual-auth, Colin service key wired

### Backend — rewards/points
- `REWARDS_ENABLED=true` (dev only)
- `POST /points/redeem`: unblocked; `GUNNERCAM_POINTS_WEBHOOK_TOKEN` set

### Backend — scheduled tasks (EventBridge)
- `overdue-inspections`: `rate(4 hours)`
- `maintenance-check`: `rate(4 hours)`
- `prune-location-history`: `cron(0 8 * * ? *)` daily 08:00 UTC

### iOS
- Receipt scanner: dual-image OCR, verify UI (index-based rows, editable total)
- Location: `applyTrackingMode()`, `LocationPingQueue`, `PMLocationView` geocoder
- `JobGuidedView+Content`: Requests row icons (cc-1400)

## Key Facts
- Gunner org ID: `69aad261-347c-44db-8e9e-6c25a8509aa3`
- MFA ARN: `arn:aws:iam::980921733684:mfa/tylerMFA`; base profile `default`; mfa profile `mfa`
- Deploy bucket: `gunnerteam-lambda-deploy-useast2`, key `gunnerteam-deploy.zip`
- Migration secret: `gunner-migrate-2026`; invoke with `--qualifier <version>` for fresh container
- `gt()` shell function in `~/.zshrc`: run `gt-setup` once; `gt` exports `$TOKEN` + `$API`
- Aurora prod cluster: `gunner-masterdb-production-masterdbcluster-sczazkvf` (custom param group, `idle_in_tx=30s`)

## Schema Gotchas (masterdb)
- `users.id` is **VARCHAR** → `u.id::uuid`
- `gt_user_profile.user_id`/`.org_id` are **VARCHAR** → `::text` casts
- `gt_user_profile` has no `role` (use `req.user.role`) and no `display_name`
- `SET LOCAL` rejects `$1` → use string interpolation (orgId is auth-derived)
- `gt_task_cursors` keyed (org_id, task) — no user_id column
- **Single flag owner**: if two functions gate on the same `isX` flag, the second one's guard fires immediately → silent bail. One function must own the flag end-to-end.
- **`/validate` must return all per-user flags** the client gates on (cc-867 lesson)

## Dev Environment
- **iTerm scrollback**: OMP window move causes replay of full scroll buffer. Fix: `Settings → Profiles → Terminal → Scrollback lines` → ~1000. Also end sessions with `/new`.
