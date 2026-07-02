---
type: session
title: Post-Cutover Stabilization — GunnerTeam API v51-v58
created: '2026-05-21'
updated: '2026-05-21'
tags:
  - session
  - gunnerteam
  - aws
  - database
  - ios
  - fleet
  - schema
status: complete
related:
  - '[[gunner/gunnerteam-api-aws-migration]]'
  - '[[gunner/aws-environment]]'
  - '[[gunnerteam/system-security-plan]]'
  - '[[concepts/soc2]]'
---
# Post-Cutover Stabilization — GunnerTeam API v51-v58

**Session date:** 2026-05-21 (afternoon/evening)
**Repo:** `GunnerRoofing/gunner-ios`, branch `main`
**API:** `gunnerteam-dev-api` Lambda, live alias → v58 by end of session

---

## What Was Fixed

### Schema — Missing Columns (Reactive Migrations)

All fixes deployed via `POST /auth/run-migrations` endpoint (admin-only, idempotent).

| Table | Missing | Fix |
|---|---|---|
| `gt_vehicle_inspections` | `review_notes TEXT` | Added |
| `gt_vehicle_inspections` | `photo_urls TEXT` | Added (was donor column, not migrated) |
| `gt_vehicle_inspections` | `review_status TEXT` | Added; existing `status` enum values copied over |
| `gt_vehicle_schedules` | `id` had no DEFAULT | `ALTER COLUMN id SET DEFAULT gen_random_uuid()` |
| `gt_vehicle_schedules` | No unique constraint on `user_id` | `CREATE UNIQUE INDEX ... ON gt_vehicle_schedules(user_id)` — required for ON CONFLICT upsert |
| `gt_vehicle_schedules` | `first_overdue_at`, `manager_notified`, `last_user_notified_at` | Added |
| `gt_vehicle_schedules` | `created_at` had no DEFAULT | `SET DEFAULT NOW()` |
| `gt_vehicle_documents` | `active`, `expires_at` | Added (active previously fixed, expires_at new) |
| `gt_vehicle_documents` | `id` had no DEFAULT, `uploaded_at` missing | Migration + INSERT made explicit |
| `gt_vehicle_other_documents` | `active` | Added |
| `gt_vehicle_other_documents` | `id`/`uploaded_at` same issue | Migration + INSERT made explicit |
| `gt_vehicle_maintenance` | `id` had no DEFAULT, `created_at` missing | Migration + INSERT made explicit |
| `gt_vehicle_license_plates` | `user_id`, `vehicle_type`, `license_plate` | Added (table was vehicle-centric; API is user+type-centric) |

Total: **17 idempotent migrations** in the array, all confirmed `ok: true`.

### Root Cause Pattern

The Phase 4/4b Alembic migrations created `gt_*` tables without:
- `DEFAULT gen_random_uuid()` on `id` columns
- `DEFAULT NOW()` on `created_at`/`uploaded_at` columns
- Some columns present in the donor DB never made it into the masterdb schema

**Permanent fix**: all new INSERT statements now provide `id` and timestamps explicitly rather than relying on column defaults. This makes the code independent of migration state.

### Express API Bug Fixes

**`s3.js` — execFile crash in Lambda**
`uploadToS3` was using `execFile('aws', ...)` which shells out to the AWS CLI binary. The CLI doesn't exist in the Lambda runtime. Replaced with AWS SDK v3 `PutObjectCommand`.

**`fleet/index.js` — explicit id+timestamps in INSERTs**
```javascript
// Before (broke when column defaults weren't set):
INSERT INTO gt_vehicle_documents (org_id, vehicle_id, ...) VALUES ($1,$2,...)

// After (self-sufficient):
INSERT INTO gt_vehicle_documents (id, org_id, vehicle_id, ..., uploaded_at)
VALUES (gen_random_uuid(),$1,$2,...,NOW())
```
Applied to: `gt_vehicle_documents`, `gt_vehicle_maintenance`, `gt_vehicle_other_documents` (×2).

**`any_damage` → `damage_reported` column rename**
The donor DB had `any_damage TEXT`; masterdb has `damage_reported BOOLEAN`. All 4 SQL references updated.

**`review_status` vs `status`**
Donor had `review_status TEXT`; masterdb migration created `status inspectionstatus ENUM`. Inspection queries updated to use `review_status` (new column added to masterdb via migration, data copied from `status`).

### iOS Swift Fixes

**Pending inspections card**
Was: custom `var pendingInspectionsCard: some View { ... }` (31 lines) gated on `pendingLoaded` state.
Now: standard `navCard(icon:title:subtitle:badgeCount:action:)` call, shows once data loads. Badge always visible (grey at 0, accent when >0). Removed `pendingLoaded` state entirely.

**URL consolidation — `APIConfig.swift`**
Created `API.base` enum replacing 72 hardcoded `api.team.gunnerroofing.com` strings across 14 Swift files:
```swift
enum API {
    #if DEBUG
    static let base = "https://api-dev.team.gunnerroofing.com"
    #else
    static let base = "https://api.team.gunnerroofing.com"
    #endif
}
```

**Type fixes (Int → String for UUIDs)**
After masterdb migration, all IDs are UUIDs. Fixed across:
- `SettingsView.swift`: `AppUser.id`, `managerId`, `assignedUserId`, `UserPickerSheet`, `Set<Int>`, `deleteConfirmId`
- `VehicleInspectionHubView.swift`: `vehicleId`, `userId`, `deleteConfirmId`, Decodable struct ids, function signatures
- `VehicleDocumentViews.swift`: `deleteConfirmId`, `deleteDoc(id:)`, `VehicleDoc.id`, `maintenanceId`
- `VehicleInspectionView.swift`: inspection item `id`

**Endpoint fixes**
- `AuthManager.forgotPassword`: `/auth/forgot` → `/auth/forgot-password`
- `ResetPasswordView`: `/auth/complete-reset` → `/auth/reset-password`

### Infrastructure

**Terraform VPC reconciliation**
Lambda was manually moved to masterdb VPC (`vpc-0eb66556f100c7b3c`) months ago. Terraform still had the old default VPC (`vpc-01348041c36d04d16`). Reconciled:
- `main.tf`: `data.aws_vpc.default` now targets masterdb VPC by ID
- `nat.tf`: lambda subnets updated to masterdb private subnets; removed Terraform-managed NAT/EIP (masterdb VPC has its own)
- `sg.tf`: removed dead `rds`/`rds_proxy` SG resources; added `aws_security_group_rule.aurora_from_lambda`

**gt_vehicles deduplication**
Import ran 5× during testing → 140 vehicles (5 copies each). Reduced to 28 (one per unique vehicle) via one-shot Lambda. Kept row with `assigned_user_id` set where present.

---

## Schema Rules Added to CLAUDE.md

Six rules added to prevent recurrence:

1. **JSONB for JSON columns** — never `TEXT` + `JSON.parse()`
2. **UUID PK with DEFAULT** — always `DEFAULT gen_random_uuid()` on `id`
3. **`created_at` with DEFAULT** — always `DEFAULT NOW()`, never in INSERT params
4. **No parallel columns** — don't add `status` when `review_status` exists
5. **Match Express API model** — grep routes before designing table; API is source of truth
6. **ON CONFLICT requires unique index** — add in same migration that introduces the upsert

---

## Lambda Version History (This Session)

| Version | Change |
|---|---|
| 51 | Already deployed at session start |
| 52 | Remove 3 debug console.log lines from fleet routes |
| 53 | `created_at DEFAULT NOW()` migration for `gt_vehicle_schedules` |
| 54 | iOS/API changes from Claude Code (email/JWT fields, Whisper route) |
| 55 | Schedule migrations (id DEFAULT, unique index, columns) |
| 56 | Full 15-migration array + document/maintenance column migrations |
| 57 | `created_at DEFAULT NOW()` for `gt_vehicle_documents` and `gt_vehicle_other_documents` |
| 58 | Explicit id+timestamps in all vehicle doc/maintenance INSERTs; pending inspections navCard |

---

## Open Items

- Old SGs in gunnerteam VPC (`sg-0ae88019e9b799cf9`, `sg-095e6758d90a7ca2f`) orphaned — delete once ENIs release
- `api.gunnerteam.app` domain does not resolve — not a valid API endpoint; use `api.team.gunnerroofing.com`
- Node.js upgrade to >=22 needed before Jan 2027 (SDK advisory in every log)
- Audit `[Audit] write failed: null value in column "org_id"` — forgot-password route fires audit before org context is set (non-fatal, known issue)
