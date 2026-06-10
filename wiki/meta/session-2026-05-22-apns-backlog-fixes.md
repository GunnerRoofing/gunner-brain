---
type: session
title: '2026-05-22: APNs push fixes, backlog audit, cc-29 nav revert'
created: '2026-05-22'
updated: '2026-05-22'
tags:
  - ios
  - api
  - apns
  - gunner-ios
  - session
status: active
related:
  - '[[meta/session-2026-05-22-cc-prompt-26-27-announcements-omp]]'
  - '[[gunner/gunnerteam-api-aws-migration]]'
---

# Session 2026-05-22: APNs Push Fixes, Backlog Audit, cc-29 Nav Revert

## cc-28 Backlog Audit (audit only — no fixes)

| Item | Status | Finding |
|---|---|---|
| Manage Users | ⚠️ Needs live test | API route correct (`queryWithTenant`, proper auth, `AppUser.id: String`). No static bug. Needs live `curl` to diagnose runtime failure. |
| Project comment webhook | ✅ Already handled | `project.comment.added` wired at line 549 of `companycam.js`. SSM parameter exists. Nothing to do. |
| Legacy photo URLs | ⚠️ Unknown | RDS Data API (`HttpEndpoint`) disabled on cluster — can't query without RDS console or Lambda wrapper. |

**Lambda deployment lesson (from this session):** `update-function-code` alone is not enough when API Gateway hits a named alias. API Gateway invokes the `live` alias which is pinned to a specific version number (visible as `[63]` in CloudWatch log prefixes). New code uploaded to `$LATEST` is invisible until you publish a version and update the alias. Required sequence:
```bash
aws lambda update-function-code --zip-file ...
aws lambda publish-version --function-name gunnerteam-dev-api
aws lambda update-alias --function-name gunnerteam-dev-api --name live --function-version <new-version>
```

## APNs Push Notification Fix

### Root cause chain
1. `APNS_KEY_CONTENT` SSM param exists and is valid PEM (`-----BEGIN PRIVATE KEY-----`) ✓
2. Device token exists in `user_devices` table ✓
3. Token prefix `475c7a87e7c3` is `Unregistered` — stale/expired ✗
4. `announcements.js` called `sendPush()` but ignored the return value — stale tokens never deleted ✗

`sendPush()` in `apns.js` already returns `'stale'` for `Unregistered`/`BadDeviceToken`/`DeviceTokenNotForTopic`. `companycam.js` handlers already handled this correctly. `announcements.js` did not.

### Fix: announcements.js stale token cleanup (commit `4911c2f`)
```javascript
// Before — return value ignored, stale token accumulates:
await Promise.allSettled(
  tokenRes.rows.map(r => sendPush(r.push_token, title, body))
);

// After — stale tokens deleted from user_devices:
await Promise.allSettled(
  tokenRes.rows.map(async r => {
    const stale = await sendPush(r.push_token, title, body);
    if (stale === 'stale') {
      await queryWithTenant(req.orgId,
        'DELETE FROM user_devices WHERE push_token = $1',
        [r.push_token]
      ).catch(err => console.error('[APNs] stale token cleanup failed:', err.message));
    }
  })
);
```

### Two token stores — inconsistency noted (not fixed this session)
- `user_devices` table — populated by `PATCH /auth/device-token` (the correct registration path used by announcements)
- `users.device_token` column — used by `companycam.js` webhook handlers (legacy)

These are separate stores. Announcements uses `user_devices`. The stale cleanup in `companycam.js` clears `users.device_token`, not `user_devices`. Unifying these is a follow-up item.

## user_devices updated_at Constraint Fix

### Root cause
`PATCH /auth/device-token` was failing with `NOT NULL constraint violation` on `user_devices.updated_at`. The INSERT omitted `updated_at` and the column has no DEFAULT. The cc-prompt-23 DEFAULT audit only covered `gt_` prefixed tables — `user_devices` has no `gt_` prefix and was missed.

### Fix (commit `a4dcad9`)

**INSERT in `auth.js`:**
```javascript
// Before:
`INSERT INTO user_devices (id, user_id, org_id, platform, push_token, created_at)
 VALUES (gen_random_uuid(), $1, $2, 'apns', $3, NOW())`

// After:
`INSERT INTO user_devices (id, user_id, org_id, platform, push_token, created_at, updated_at)
 VALUES (gen_random_uuid(), $1, $2, 'apns', $3, NOW(), NOW())`
```

**Migration added to `/auth/run-migrations`:**
```sql
-- user_devices (not a gt_ table — missed in cc-prompt-23 DEFAULT audit)
ALTER TABLE user_devices ALTER COLUMN updated_at SET DEFAULT NOW();
```

**Rule:** The cc-prompt-23 DEFAULT audit only covered `gt_` tables. Any non-`gt_` table with `NOT NULL` columns and no DEFAULT is the same latent bug. Check `user_devices`, `users`, `user_organizations`, `app_roles`, etc. if new INSERT failures appear.

## cc-prompt-29 — Revert cc-27 Navigation Restructure

cc-prompt-27 hoisted the hero background outside the inner `NavigationStack` to prevent background sliding during push. It broke navigation — tapping "Guided Tasks" opened a white screen with incorrect slide direction.

### Revert (commit `0247c35`)
The cc-27 implementation commit (`e6f2989`) was reverted directly. The merge commit (`1537fde`) was skipped (`-m` flag required for merge reverts — not worth the complexity).

Navigation restored to cc-prompt-26 state:
- `JobModeSelectionView` owns `@StateObject private var heroLoader = HeroImageLoader()`
- `GuidedTasksView` accepts `@ObservedObject var heroLoader: HeroImageLoader`
- Both views render `heroBackground` in their own `ZStack`
- Background flicker on push is the accepted trade-off vs broken navigation

### Why cc-27 failed
`JobModeSelectionView` was given its own inner `NavigationStack` to govern the `→ GuidedTasksView` push. SwiftUI's behavior with nested `NavigationStack`s caused the push to animate incorrectly — the destination rendered as a white screen sliding from the wrong direction. The outer `ContentView.NavigationStack` and inner stack conflicted.

## Commits This Session (main, merged from fix/short-term-backlog)

| Commit | Description |
|---|---|
| `4911c2f` | fix(api): clean up stale APNs tokens from user_devices on Unregistered |
| `a4dcad9` | fix(auth): user_devices INSERT — explicit updated_at + device_name null handling |
| `0247c35` | Revert cc-27: restore working navigation (heroLoader per-view pattern) |
| `481aef5` | Merge fix/short-term-backlog |

## To Complete (requires manual steps)

1. **Run migrations:** `POST /auth/run-migrations` with admin JWT — sets `updated_at DEFAULT NOW()` on `user_devices`
2. **Re-register device token:** Open iOS app — it calls `PATCH /auth/device-token` on launch, replacing the stale `475c7a87e7c3...` token
3. **Smoke test push:** Post a test announcement, confirm notification arrives
4. **Legacy photo URLs:** Run SELECT in RDS Query Editor to count rows with `3.134.224.29` then apply UPDATE if any exist
5. **Manage Users:** Live `curl -H "Authorization: Bearer $JWT" https://api-dev.team.gunnerroofing.com/users` to diagnose runtime failure
