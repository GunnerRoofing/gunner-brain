---
type: session
title: "cc-prompts 38–45, 69–75: Fleet Performance + CompanyCam Webhooks"
created: 2026-05-27
updated: 2026-05-27
tags:
  - gunnerteam
  - fleet
  - ios
  - performance
  - companycam
  - apns
  - webhooks
status: stable
related:
  - "[[tyler/gunnerteam/gunnerteam-performance-standards]]"
  - "[[meta/session-2026-05-27-cc57-63-invite-registration-fix]]"
  - "[[meta/session-2026-05-27-omp-plugins-cc51-53]]"
---

# cc-prompts 38–45, 69–75: Fleet Performance + CompanyCam Webhooks

---

## CompanyCam Webhook Push Fixes (cc-38–40)

### cc-38: user_devices.push_token (not users.device_token)

All three CompanyCam webhook handlers were querying `users.device_token` — a legacy column that is NULL for all Cognito users. APNs tokens live in `user_devices.push_token`.

**Fixed pattern (all three handlers):**
```js
// ❌ Old — always returns NULL for Cognito users
const { rows } = await query('SELECT id, device_token FROM users WHERE email = $1', [email]);

// ✅ New — LEFT JOIN user_devices
const { rows } = await query(
  `SELECT u.id, ud.push_token AS device_token
   FROM users u
   LEFT JOIN user_devices ud ON ud.user_id = u.id AND ud.platform = 'apns'
   WHERE u.email = $1
   ORDER BY ud.updated_at DESC NULLS LAST
   LIMIT 1`,
  [email]
);
```

Multi-user handlers use `DISTINCT ON (u.id)`:
```js
SELECT DISTINCT ON (u.id) u.id, u.email, ud.push_token AS device_token
FROM users u
LEFT JOIN user_devices ud ON ud.user_id = u.id AND ud.platform = 'apns'
WHERE u.email = ANY($1::text[])
ORDER BY u.id, ud.updated_at DESC NULLS LAST
```

Stale-token cleanup: `DELETE FROM user_devices WHERE push_token = $1` (not UPDATE users).

### cc-39: Remove assignedRole !== 'pm' filter

`handleProjectAssigned` was silently dropping all assignments where `assignedRole !== 'pm'`. Colin's system defaults `assignedRole` to `'other'` when not set — meaning virtually all real assignments never pushed.

Fix: remove the `assignedRole` early-return entirely. The webhook already targets a specific `assignedUserEmail`; role is not the right filter. The self-assignment guard (`assignedUserEmail === actorEmail`) is kept.

### cc-40: photo.comment.added field mismatch

Colin's payload uses `recipients` (not `recipientEmails`) and `comment.body` (not top-level `commentBody`). Handler was always receiving `undefined` → `targets = []` → short-circuits without pushing.

```js
// ❌ Old
const { photoId, projectId, projectName, commentBody, authorEmail, recipientEmails } = req.body;
const targets = Array.isArray(recipientEmails) ? ... : [];
const body = commentBody ? ...

// ✅ New
const { photoId, projectId, projectName, comment, authorEmail, recipients } = req.body;
const targets = Array.isArray(recipients) ? recipients.filter(e => e !== authorEmail) : [];
const body = comment?.body ? `"${comment.body.slice(0, 60)}"` : 'Someone commented on a photo';
```

---

## iOS Fleet Fixes (cc-41–45)

### cc-41: myVehicleId cached in AuthManager (UserDefaults)

`myVehicleId` was local `@State` in `VehicleInspectionHubView` — nil on first render. Card popped in after ~1s API round-trip.

```swift
@Published var myVehicleId: String = UserDefaults.standard.string(forKey: "gunner.myVehicleId") ?? "" {
    didSet { UserDefaults.standard.set(myVehicleId, forKey: "gunner.myVehicleId") }
}
// Clear on logout:
myVehicleId = ""
```

Hub now reads `auth.myVehicleId` — renders from cache on first paint.

### cc-43: Prefetch myVehicleId at login

Calls `prefetchVehicle()` at the end of both `validate()` and `validateLegacy()` for non-manager users. By the time user taps Fleet, `auth.myVehicleId` is already set.

```swift
private func prefetchVehicle() async {
    guard let tok = await token(),
          let url = URL(string: workerBase + "/fleet/my-vehicle") else { return }
    // ...fetches and sets auth.myVehicleId
}
// Called at end of validate() / validateLegacy():
if decoded.role == "user" { await prefetchVehicle() }
```

### cc-42: Registration expiry syncs on upload

`POST /fleet/vehicles/:id/documents`: after INSERT, if `docType === 'registration'` and `expiresAt` is present, `UPDATE gt_vehicles SET registration_expires = $1`.

iOS: `VehicleDetailView` title changed from `primaryText` (black) to `Color.appDestructive` (red). Edit text button replaced with pencil icon (`square.and.pencil`) for balanced centering.

### cc-44: Full reload after doc upload, skip fetchUsers for non-managers

- `VehicleDocSection.onReload`: `loadDocuments()` → `load()` so `registrationExpires` on the vehicle row refreshes after upload
- `load()`: `isManager ? fetchUsers(token:) : []` — eliminates guaranteed 403 round-trip for non-managers

### cc-45: Upload sheet .id fix

`sheet(isPresented:)` captures closure at creation — `uploadDocType` never updated in the reused view. Fix: `.id(uploadDocType)` on `VehicleDocUploadSheet` forces SwiftUI to destroy/recreate on type change.

---

## Fleet Performance Fixes (cc-69–75)

### query() vs queryWithTenant — the root cause

`queryWithTenant` wraps every call in `BEGIN / SET LOCAL / COMMIT`. For read-only routes with an explicit `org_id` filter, this adds transaction overhead. Switching to `query()` with `WHERE org_id = $1` eliminated 25-30s hangs.

**Routes converted (8+ calls total):**
- `GET /fleet/my-vehicle`
- `GET /fleet/vehicles/:id` (3 calls)
- `GET /fleet/vehicles/:id/documents` (3 calls)
- `GET /fleet/vehicles/:id/maintenance` (Promise.all, 2 calls)
- `GET /vehicle/pending-inspections`
- `GET /announcements`

### Pool max

```js
max: 5  // Never 1 — serializes all Promise.all parallel queries
```

### N+1 fix (cc-69: reports/team)

Replaced per-user inspection query with LATERAL JOIN — 15 serial round-trips → 1 query.

### Lambda migration runner (cc-71)

`event._migration` handler in `lambda.js` runs named SQL migrations from within the VPC. Secret-gated via `MIGRATION_SECRET` env var. Never reachable via API Gateway.

```bash
aws lambda invoke --function-name gunnerteam-dev-api:live \
  --payload '{"_migration":"20260527_fleet_indexes","_secret":"gunner-migrate-2026"}' ...
```

### Indexes added

Migration `20260527_fleet_indexes`:
- `idx_gt_vehicle_inspections_review_status` (partial WHERE NULL)
- `idx_gt_user_profile_manager_id`
- `idx_gt_vehicle_inspections_user_id`
- `idx_gt_vehicle_inspections_submitted_at`

Migration `20260527_schedules_indexes`:
- `idx_gt_announcements_org_id`
- `idx_gt_vehicle_schedules_user_id`
- `idx_gt_vehicle_schedules_active` (partial WHERE active = TRUE)

### onAppear guards (cc-73–74)

All API-fetching `onAppear` calls guarded with `hasFetched` to prevent 4x duplicate requests per tab tap.

Pattern:
```swift
@State private var hasFetched = false
.onAppear {
    guard !hasFetched else { return }
    hasFetched = true
    Task { await loadData() }
}
.refreshable {
    hasFetched = true  // always allow pull-to-refresh
    await loadData()
}
```

Views guarded: VehicleInspectionHubView, VehicleListView, VehicleDetailView, TeamSchedulesView, PendingInspectionsView, AnnouncementsView, InspectionReportsListView, PersonInspectionHistoryView, JobsView, JobDetailView, VehicleInspectionView. (11 views total)

### Request logger (cc-72)

```js
app.use((req, _res, next) => {
  console.log(`[REQ] ${req.method} ${req.path}`);
  next();
});
```

Fires on every HTTP request — identifies routes in Lambda timeouts that previously showed START/END with no output.

---

## Deploy State

All changes committed and pushed to origin/main. Zip at `/tmp/gt-deploy.zip` each time, deploy blocked by MFA expiry. Use:

```bash
AWS_PROFILE=mfa aws lambda update-function-code \
  --function-name gunnerteam-dev-api \
  --zip-file fileb:///tmp/gt-deploy.zip \
  --region us-east-2 && \
AWS_PROFILE=mfa aws lambda wait function-updated \
  --function-name gunnerteam-dev-api --region us-east-2 && \
VERSION=$(AWS_PROFILE=mfa aws lambda publish-version \
  --function-name gunnerteam-dev-api --region us-east-2 \
  --query 'Version' --output text) && \
AWS_PROFILE=mfa aws lambda update-alias \
  --function-name gunnerteam-dev-api --name live \
  --function-version "$VERSION" --region us-east-2 && \
echo "Live → v$VERSION"
```
