---
title: masterdb Cutover Complete + Post-Cutover Stabilization
type: session
tags:
  - session
  - database
  - migration
  - masterdb
  - aws
  - ios
status: complete
created: '2026-05-21'
updated: '2026-05-21'
---
# Session 2026-05-21 — masterdb Cutover + Post-Cutover Stabilization

**Session date:** 2026-05-21
**Status:** Complete

---

## What was accomplished

### Infrastructure
- Lambda `gunnerteam-dev-api` migrated to masterdb VPC (`vpc-0eb66556f100c7b3c`)
- Terraform fully reconciled — state serial 112, SGs recreated in masterdb VPC
- VPC peering (gunnerteam ↔ masterdb) created for import, then torn down after cutover
- Donor iOS RDS (`gunnerteam-dev`) decommissioned, final snapshot taken
- Aurora Serverless v2 auto-pause disabled (min 0.5 ACU)
- Version 40 live as of 16:47 UTC

### Database migrations applied (masterdb)
All via one-shot Lambda pattern against Aurora PostgreSQL:
- Phase 5 RLS on users (revision `98a92a0079b9`)
- `users.salt` column added (revision `9929737c153a`)
- `gt_vehicle_documents.active` (revision `a1b2c3d4e5f6`)
- `gt_vehicle_documents.expires_at` (revision `b2c3d4e5f6a7`)
- `gt_vehicle_inspections.photo_urls` + `review_status`, `gt_vehicle_license_plates.user_id/vehicle_type/license_plate` (revision `c3d4e5f6a7b8`)
- `gt_vehicle_other_documents.active` (revision `d4e5f6a7b8c9`)
- RLS split policies on `reset_tokens` + `invite_tokens` (SELECT USING TRUE, write ops keep org isolation)

### Express API fixes deployed
- `any_damage` → `damage_reported` column rename
- `s3.js` uploadToS3 replaced `execFile('aws')` with SDK `PutObjectCommand`
- auth.js JWT now includes `email`, `firstName`, `lastName`
- companycam.js: job comment POST passes `userName` + `email`; new `/jobs/:jobId/transcribe` route (OpenAI Whisper)
- `doc_expiry_status` subquery stubs restored after `expires_at` confirmed live
- All hardcoded API URLs replaced with `API.base` (#if DEBUG / else) across 14 Swift files

### Data cleanup
- `gt_vehicles` deduplicated: 140 rows → 28 (5× import duplication cleared)

### iOS Swift fixes
- `workerBase` → `API.base` enum (api-dev in DEBUG, api in release)
- `APIConfig.swift` created as single source of truth
- `ResetPasswordView`: `/auth/complete-reset` → `/auth/reset-password`
- `SettingsView`, `VehicleInspectionHubView`, `VehicleDocumentViews`, `VehicleInspectionView`: all `Int` IDs → `String` (masterdb UUIDs)
- `AuthManager.forgotPassword`: `/auth/forgot` → `/auth/forgot-password`

---

## Known post-cutover items
- `users.salt` populated for 3 test users — all accounts nulled (will be recreated via invite flow)
- Secrets handling rules documented at `wiki/gunner/secrets-handling-rules.md`
- IAM least-privilege runbook saved at `wiki/runbooks/aws-iam-least-privilege.md` — execute at end of first dev wave
- Node.js upgrade to >=22 needed before Jan 2027
- Old SGs in gunnerteam VPC (`sg-0ae88019e9b799cf9`, `sg-095e6758d90a7ca2f`) are orphaned — delete manually once ENIs release

## Next steps
- Users log out and back in once to get new JWT claims (email, firstName, lastName)
- Test vehicle inspection submit (UUID fix)
- Test Whisper transcription route
- Ask Eddie to enable IAM Identity Center at org management account level
