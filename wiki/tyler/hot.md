---
type: hot-cache
updated: '2026-06-19'
---

# Tyler Hot Cache — 2026-06-19
## Current State
- **Lambda:** v291 live (`gunnerteam-dev-api`, alias `live`, prod Aurora via RDS Proxy)
- **iOS build:** BUILD SUCCEEDED — cc-1111–1126, cc-1400 committed to `main`
- **Last session:** 2026-06-19 — receipt validation confirmed good; LOCATION_PING_FORWARD ON + live; Colin service key wired to `/time/location-compliance`
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
aws lambda update-alias --function-name gunnerteam-dev-api --name live \
  --function-version "$VERSION" \
  --routing-config '{"AdditionalVersionWeights":{}}' \
  --region us-east-2 --profile mfa --query 'FunctionVersion' --output text && \
echo "v$VERSION"
```
- `rm -f` first — `zip -r` merges into existing archive (stale zip bug)
- `'{"AdditionalVersionWeights":{}}'` explicit JSON — shorthand `AdditionalVersionWeights={}` is a no-op; prior canary weights route 100% to old version

## What's Live (v291)

### Backend — receipt scanner (updated this session)
- `POST /jobs/:jobId/receipt/extract`: dual-image best-of selection (cc-1122/1126)
  - Accepts `imageBase64` (primary, original color) + optional `imageBase64Alt` (B&W)
  - `parseExpenseDoc(out)` — pure fn; `reconScore(r)` — `|total − Σ lines|`
  - `garbageFraction(r)` — fraction of lines with description `<4` chars or no 3+ letter run
  - Selection: prefer original; switch to B&W only when `reconScore(bw)+1.0 < reconScore(orig)` AND `garbageFraction(bw) ≤ garbageFraction(orig)+0.05`
  - `cleanDescription()`: segment-split, 5 passes (tax markers, qty@unit, UPC, prices, item codes), pick longest segment ≥ 2 chars
  - Tax (`category:'tax'`), Freight (`category:'freight'`), Sales Tax fallback = TOTAL−SUBTOTAL
  - ABC trailing-minus `110.00-` → `num()` detects → `credit`
  - `audit` records `candidates` count
- `POST /jobs/:jobId/receipt/commit`: unchanged (cc-1103)

### Backend — location batch (cc-1202)
- `POST /time/location-batch`: consent-gated; bulk INSERT with client `recorded_at`; 2000 ping ceiling

### iOS — receipt scanner (updated this session)
- `ReceiptScannerView`: `makeScan` → `(bw, ocr)` tuple; `ocrImage` = perspective-corrected color original (for Textract); B&W for PDF/Files only
- `JobPhotoSessionView`: sends both images; `asJpeg(_:)` steps quality 0.85→0.7→0.55→0.4 at 6.5 MB ceiling
- `ReceiptVerifyView`:
  - `ReceiptLineCategory`: `item | tax | freight`; `ReceiptLineDraft` decode-tolerant (`decodeIfPresent`, defaults `.item`)
  - `lineRow` dispatches to `itemRow` (full layout) or compact fee row (label + Amount + picker)
  - Two-pass `ForEach` with "Taxes & Fees" divider; both passes have `.onDelete` with index mapping
  - Summary: "Items total" + "Receipt total" + mismatch warning (`Color.appWarning`)
  - `net` removed; `lineSum` = unsigned Σ
  - Description field: `axis: .vertical`, `lineLimit(1...3)`, `minimumScaleFactor(0.85)`
- SCAN mode HUD: moved to top (`.padding(.top, 60)`); `Capsule()` pill shape
- `JobGuidedView+Content`: Requests row icons = white glyph on `themeManager.theme.secondary` chip (cc-1400)

### iOS — location (cc-1200–1201)
- `applyTrackingMode()` in `CheckInManager`: off-job → `kCLLocationAccuracyKilometer`, 500m filter, 900s interval; checked-in → 100m, 500m→100m filter, 300s
- `LocationPingQueue`: disk-backed FIFO, cap 5000, batch max 2000; flush on reconnect + foreground
- `reportLocation(lat:lng:)` deleted — replaced by queue enqueue with `loc.timestamp`

### iOS — PMLocationView (cc-1300)
- `reverseGeocode(_:)` via CLGeocoder; address shown in footer above status pill
- `.task(id: location.recordedAt)` re-geocodes after each successful ping

### Backend — earlier features still live
- `POST /auth/validate` returns `location_consent`
- `POST /time/request-location`: APNs silent push ping
- `GET /time/location-compliance`: dual-auth
- Assistant-kb.js lock fix (cc-864)

## Pending
- **`idle_in_transaction_session_timeout = 30000`** on RDS cluster param (pending-reboot)
- **`COLIN_PNL_API_URL`**: unset until Colin implements `/jobs/:jobId/pnl/line-items`
- **`REWARDS_ENABLED=false`**: set true when policy approved
- **`gt_location_history` 90-day prune**: recurring EventBridge schedule
- **`GUNNERCAM_POINTS_WEBHOOK_TOKEN`**: set real value in Lambda console
- **Employee notice** (`employee-notice-points-location.md`): HR/legal/IT sign-off
- **Terraform stash reconcile**: `stash@{0}`

## Key Facts
- Gunner org ID: `69aad261-347c-44db-8e9e-6c25a8509aa3`
- MFA ARN: `arn:aws:iam::980921733684:mfa/tylerMFA`; base profile `default`; mfa profile `mfa`
- Deploy bucket: `gunnerteam-lambda-deploy-useast2`, key `gunnerteam-deploy.zip`
- Migration secret: `gunner-migrate-2026`; invoke with `--qualifier <version>` for fresh container
- `gt()` shell function in `~/.zshrc`: run `gt-setup` once; `gt` exports `$TOKEN` + `$API`

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
