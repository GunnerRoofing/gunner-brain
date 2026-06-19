---
type: session
title: session-2026-06-18-cc864-871-lockfix-ping-consent
created: '2026-06-18'
updated: '2026-06-18'
tags:
  - gunnerteam
  - backend
  - ios
  - lambda
  - location
  - debugging
status: stable
related:
  - '[[wiki/gunnerteam/masterdb-developer-handoff]]'
  - '[[wiki/gunnerteam/POSTMORTEM-2026-06-15]]'
---

# Session: cc-864–871 — Lock Contention Fix, Location Ping Consent, Docs Refresh

**Date:** 2026-06-18  
**Lambda:** v275 → v277 live (`gunnerteam-dev-api`, alias `live`); v278 pending MFA refresh  
**iOS:** BUILD SUCCEEDED — cc-864–871 committed to `main`

---

## cc-864 — Audit_log 12-min Lock / App-wide Timeout Root Cause + Fix

**Symptom:** `Query read timeout` across ALL routes (auth 503, /validate 500) while ACU stays flat at 50%. Cascading 28–52s timeouts. Looked like a capacity problem — it was not.

**Root cause chain:**
1. `assistant-kb.js` called `ensureLoaded()` at module top-level (line 119 of old code)
2. This started a 13s S3 PDF-loading async chain on every Lambda cold start
3. The unsettled Promise caused `Runtime.NodeJsExit` — Node exits with an open async operation in flight
4. The Lambda container that NodeJsExited had a `queryWithTenant` connection mid-transaction (BEGIN + SET LOCAL, never COMMITted) — the RDS Proxy kept the connection alive with the stale transaction
5. Exclusive lock on `audit_log` held for **12+ minutes** via the stranded Proxy connection
6. Every route calling `audit()` (which INSERTs into `audit_log`) blocked → cascading timeouts → 500s/503s app-wide

**Confirmed via CloudWatch:** `audit_log INSERT ms=724304` — a query blocked **12 minutes** on a lock.

**Fix:** Removed the top-level `ensureLoaded()` call from `assistant-kb.js`. It was already called on-demand by the `/assistant` route handler — eager loading was wrong. Deployed **v275**.

**Lesson filed in CLAUDE.md:** "Never run async/DB work at module load — strands a transaction + locks a table on cold start." Also: diagnose "everything times out at low CPU" as **lock contention**, not capacity. Check PI wait events (`Lock:*`) before touching ACU/instance size.

**Remaining recommendation (needs reboot window):** Set `idle_in_transaction_session_timeout = 30000` on the RDS cluster param group — caps any future stranded transaction at 30s.

**Also found:** Stale routing config bug — `AdditionalVersionWeights: {276: 1.0}` was routing 100% of traffic to v276 even after alias updated to v277. The shorthand `AdditionalVersionWeights={}` is silently a no-op; must use `'{"AdditionalVersionWeights":{}}'` explicit JSON. Fixed in CLAUDE.md deploy recipe.

---

## cc-865/866/867/868/870 — Silent Push → Location Report Debugging Chain

**Goal:** `POST /time/request-location` returns 200, APNs accepts the push, but device never POSTs `PATCH /time/location` back.

### cc-866 — Server-side APNs diagnostic
Added diagnostic logging to `apns.js` (`sendSilentPush` returns `'sent'`/`'stale'`/`'error'`) and `time.js` (logs `devicesPinged` + per-token result). **Result: `devicesPinged: 1`, APNs result: `ACCEPTED`** — push leaves server cleanly. Not a sandbox/production mismatch. Removed diag logs after confirming.

### cc-865/868 — On-device breadcrumbs
Added 4 `NotificationStore.shared.add(...)` toasts to trace the push→fix→report chain:
1. **Push rx** — `didReceiveRemoteNotification` (proves push arrives, shows payload keys + type)
2. **Loc req** — `handleLocationRequest` entry (shows consent + authorizationStatus.rawValue before gate)
3. **Loc req report** — `didUpdateLocations` on `pendingLocationReport` path (proves fix arrived)
4. **Loc report sent/failed** — `reportLocation` HTTP status

**Result from breadcrumbs:** "Loc req consent=**false**" — the consent gate was blocking. Push arrived, handler ran, but `AuthManager.locationConsentGranted` was permanently false on device.

### cc-867 — Root cause: `/validate` never returned `location_consent`

**Root cause:** `location_consent` was stored per-user in `gt_user_profile` and accessible via `GET /users` (admin roster), but **`POST /auth/validate` never returned it**. `AuthManager.locationConsentGranted` was permanently `false` on the device regardless of DB state — gating off ALL location reporting.

**Fix:** Added `COALESCE(p.location_consent, false) AS location_consent` to the `/validate` SELECT (table `p` = `gt_user_profile` was already joined) and `location_consent: u.location_consent` to the response JSON. Key matches iOS `ValidateResponse` CodingKey `"location_consent"` exactly. No iOS change needed. Deployed **v277**.

**Verified:** `/validate` response now contains `"location_consent":true` for consented users.

**Also fixed:** Stale routing config (`AdditionalVersionWeights: {276: 1.0}`) was routing 100% to v276 even after alias updated to v277. Cleared with explicit JSON; confirmed `Version: 277` in Lambda log tail.

**Also reverted:** cc-865/868 diagnostic breadcrumbs removed after cause was pinned (cc-870).

**Lesson:** A per-user field the client needs must be added to the endpoint the client actually reads for the current user (`/validate`), not only the admin roster (`/users`).

---

## cc-869 — PMLocationView Ping UI Improvements

The ping chain worked end-to-end but the screen didn't reflect it for stationary pings.

**Changes to `PMJobViews.swift`:**
- **Poll window:** 30s → **90s**, interval 5s → **8s** (silent-push wake + requestLocation fix + PATCH easily exceeds 30s)
- **Map:** `Map(initialPosition:)` → `Map(position: $cameraPosition)` with `@State var cameraPosition: MapCameraPosition` initialized from `location` in `init`. `withAnimation` recenters on every successful poll — stationary pings now visually confirm even when pin doesn't move
- **`pingFailed` flag:** `@State private var pingFailed = false`. Set `true` on 90s timeout, `false` on success or new ping start
- **Success state:** on `recorded_at` advancing past baseline → `location = fresh`, recenter camera, `statusMsg = "Updated just now"` for 4s then clear
- **Timeout fallback:** `pingFailed = true`, `statusMsg = nil` → footer shows `"Last seen X ago — couldn't get a live update"` from existing `stalenessLabel` — last-known pin stays visible, manager always has data

---

## cc-871 — Refresh `docs/gunnerteam-app-summary.md`

Replaced stale EC2/JWT/bcrypt/Monday-webview description with code-verified summary of current stack.

**Key corrections made vs the draft template:**
- Forms breakdown: IT Request / Change Order / AP are native SwiftUI; Dumpster Swap + Material Shortage are native SM Ops forms in **Jobs tab** (not Forms tab), posting to `/submit-dumpster|material` → Monday board `18406336489`; Site Manager Forms URL + Lowe's COC go to `SFSafariViewController`
- Push types: `fleet`/`inspection` share a case + `announcement` + `location_request`
- Added SM Ops board `18406336489` to stack table
- Assistant: non-streaming `POST /assistant/chat`, 4h idle auto-clear (confirmed `sessionTimeout = 4 * 3600`)
- PendingActionQueue: in-memory only, not restart-durable (confirmed in source comment)
- `.gitignore` required whitelist entry (`!docs/gunnerteam-app-summary.md`) — `docs/` is ignored by default

---

## Current State After Session

### Lambda versions
| Version | What's in it |
|---|---|
| v275 | cc-864: assistant-kb.js top-level ensureLoaded() removed |
| v276 | cc-865/866 diag logs (superseded) |
| v277 | cc-867: /validate returns location_consent; cc-870 diag cleanup |
| **v278** | cc-870 backend cleanup (apns.js + time.js diag logs removed) — **pending MFA refresh to deploy** |

**v277 is live.** v278 deploy blocked on expired MFA token — run `awsmfa` then:
```bash
rm -f /tmp/gunnerteam-deploy.zip && \
cd ~/Dev/GunnerTeam/gunnerteam-api && \
zip -r /tmp/gunnerteam-deploy.zip . -x "*.git*" "node_modules/.cache/*" > /dev/null && \
aws s3 cp /tmp/gunnerteam-deploy.zip s3://gunnerteam-lambda-deploy-useast2/gunnerteam-deploy.zip --region us-east-2 --profile mfa && \
aws lambda update-function-code --function-name gunnerteam-dev-api \
  --s3-bucket gunnerteam-lambda-deploy-useast2 --s3-key gunnerteam-deploy.zip \
  --region us-east-2 --profile mfa --query 'FunctionName' --output text && \
aws lambda wait function-updated --function-name gunnerteam-dev-api --region us-east-2 --profile mfa && \
VERSION=$(aws lambda publish-version --function-name gunnerteam-dev-api \
  --region us-east-2 --profile mfa --query 'Version' --output text) && \
aws lambda update-alias --function-name gunnerteam-dev-api --name live \
  --function-version "$VERSION" --routing-config '{"AdditionalVersionWeights":{}}' \
  --region us-east-2 --profile mfa --query 'FunctionVersion' --output text && \
echo "v$VERSION"
```

### iOS commits this session
| Commit | Content |
|---|---|
| `2cb425b` | cc-865 breadcrumbs (reverted) |
| `5e90beb` | cc-867 backend (auth.js) |
| `22961cd` | cc-865 breadcrumb revert |
| `e37a7e6` | CLAUDE.md deploy recipe fix |
| `d401b2f` | cc-868 re-add breadcrumbs (reverted) |
| `05c8b5f` | cc-869 PMLocationView ping UI |
| `17d2328` | cc-870 iOS diag cleanup |
| `3442287` | cc-870 backend diag cleanup |
| `05e2fbe` | .gitignore whitelist |
| `9a9be0a` | cc-871 app summary doc |

### Open Items (carried forward)
- **v278 deploy**: run `awsmfa` then deploy block above
- **`idle_in_transaction_session_timeout = 30000`**: flag to Tyler for next maintenance window (instances show `pending-reboot`)
- **`LOCATION_PING_FORWARD` flag**: off until CT/NJ consent #37 signed
- **`REWARDS_ENABLED=false`**: set true when policy approved
- **`gt_location_history` 90-day prune**: recurring EventBridge schedule (currently deploy-time only)
- **`GUNNERCAM_POINTS_WEBHOOK_TOKEN`**: set real value in Lambda console
- **Employee notice** (`employee-notice-points-location.md`): HR/legal/IT sign-off before distribution
- **Terraform stash reconcile**: `stash@{0}`, separate from iOS/backend work
- **Colin**: wire service key to `GET /time/location-compliance`

### Schema / Deploy Gotchas (new this session)
- **`AdditionalVersionWeights={}` shorthand is a no-op** — always use `'{"AdditionalVersionWeights":{}}'` explicit JSON to clear canary weights
- **`rm -f /tmp/gunnerteam-deploy.zip` required** — `zip -r` merges into existing archive; both now in CLAUDE.md deploy recipe
- **`/validate` must return all per-user flags the client gates on** — `location_consent` was missing, caused 6 sessions of phantom debugging
- **Lock contention masquerades as capacity** — "everything times out at 50% ACU" → check `Lock:*` PI wait events first
