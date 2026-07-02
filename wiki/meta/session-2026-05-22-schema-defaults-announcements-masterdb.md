---
type: session
title: Schema DEFAULT Audit + Announcements Fix + masterdb Platform Ingestion
created: '2026-05-22'
updated: '2026-05-22'
tags:
  - session
  - database
  - migrations
  - masterdb
  - announcements
  - security
  - python
status: complete
related:
  - '[[tyler/masterdb/masterdb-architecture]]'
  - '[[gunnerteam/secure-coding-guide]]'
  - '[[meta/session-2026-05-21-post-cutover-stabilization]]'
  - '[[tyler/gunnerteam/gunnerteam-api-aws-migration]]'
  - '[[concepts/soc2]]'
---
# Session 2026-05-22 — Schema DEFAULT Audit + Announcements Fix + masterdb Platform Ingestion

**Session date:** 2026-05-22
**Repo:** `GunnerRoofing/gunner-ios`, branch `fix/nav-bar-no-flash`

---

## What Was Fixed

### cc-prompt-21 — Announcements 500 Diagnosis

Root cause: `gt_announcements.id` had no `DEFAULT gen_random_uuid()`. Same pattern as `gt_vehicle_documents`, `gt_vehicle_maintenance`, etc.

**Error captured via CloudWatch:**
```
error: null value in column "id" of relation "gt_announcements"
  violates not-null constraint
detail: Failing row contains (null, 69aad261-..., 3e3f0491-..., ...)
```

**GET /announcements:** worked (empty, no RLS block).  
**POST /announcements:** 500 before push code was ever reached (APNs not implicated).

**Fix:** Added three migrations + explicit INSERT values for `id`, `created_at`, `updated_at`.

---

### cc-prompt-22 — Migration Runner Cleanup

Removed two stale entries from the `run-migrations` array:
- `ALTER TABLE gt_vehicle_documents ALTER COLUMN created_at SET DEFAULT NOW()` — column is `uploaded_at`
- `ALTER TABLE gt_vehicle_other_documents ALTER COLUMN created_at SET DEFAULT NOW()` — same

Both always failed. Confirmed via INSERTs that `uploaded_at` is the correct column name on both tables.

Runner went from 18 failures → **0 failures** after removal.

---

### cc-prompt-23 — Comprehensive gt_ DEFAULT Audit

**Temporary audit route** `GET /auth/schema-audit` added to run:
```sql
SELECT table_name, column_name, data_type, column_default, is_nullable
FROM information_schema.columns
WHERE table_schema='public' AND table_name LIKE 'gt\_%'
  AND column_name IN ('id','created_at','updated_at','uploaded_at')
  AND column_default IS NULL AND is_nullable='NO'
```

**18 missing DEFAULTs found** across 8 tables:

| Table | Missing columns |
|---|---|
| `gt_vehicles` | id, created_at, updated_at |
| `gt_vehicle_inspections` | id, created_at, updated_at |
| `gt_vehicle_license_plates` | id, created_at, updated_at |
| `gt_vehicle_maintenance` | updated_at (id+created_at done previously) |
| `gt_vehicle_documents` | uploaded_at |
| `gt_vehicle_other_documents` | uploaded_at |
| `gt_user_profile` | id, created_at, updated_at |
| `gt_inspection_photos` | id, created_at |

**6 INSERT statements hardened** (added explicit `gen_random_uuid()` and `NOW()`):

| File | Table | Change |
|---|---|---|
| `auth.js:624` | `gt_user_profile` | Added id + created_at + updated_at to upsert |
| `users.js:90` | `gt_user_profile` | Same |
| `fleet/index.js:65` | `gt_vehicle_schedules` | Added id + created_at |
| `fleet/index.js:205` | `gt_vehicle_license_plates` | Added id + created_at + updated_at |
| `fleet/index.js:307` | `gt_vehicle_license_plates` | Same (inspection submit path) |
| `fleet/index.js:620` | `gt_vehicles` | Added id + created_at + updated_at |

Audit route removed before final deploy. **35/35 migrations — 0 failures.**

**Spot check:** `POST /fleet/vehicles` returned `201 {"ok":true,"vehicleId":"f1eebff2..."}` ✓

---

### Persistent Deployment Issue Documented

The `live` alias keeps acquiring routing weights (`{58: 1.0}`, `{60: 1.0}`, etc.) that route all traffic to old provisioned concurrency instances. The pattern is:

1. Terraform applies → publishes new version → sets PC on alias
2. PC creation fails ("Alias with weights can not be used") leaving old PC running
3. Old PC serves all requests with stale code

**Workaround per deployment:**
```bash
# 1. Publish new version
NEW_VER=$(aws lambda publish-version --function-name gunnerteam-dev-api ...)

# 2. Clear routing weights
aws lambda update-alias --function-version $NEW_VER \
  --routing-config 'AdditionalVersionWeights={}' ...

# 3. Delete old PC (kills stale warm instances)
aws lambda delete-provisioned-concurrency-config --qualifier live ...

# 4. Wait ~15-20s for Aurora to resume if cold, then run migrations
```

This is the same issue that's been present since the masterdb VPC migration. Root cause is Terraform's PC management conflicting with manual alias updates.

---

## Knowledge Ingested

### [[tyler/masterdb/masterdb-architecture]]

Python Lambda + Aurora Serverless v2 + Cognito + SST v3 platform. Single Aurora cluster, Postgres schemas separate domains: `master`, `sales`, `ops`, `field`, `quotes`. RLS + `org_id` on every query. EventBridge for cross-app workflows. JIT user provisioning via Lambda trigger on first Google SSO login. The GunnerTeam Express API (`gt_` tables) is the first tenant of this platform.

### [[gunnerteam/secure-coding-guide]]

OWASP Top 10 applied to the Python/Lambda/Cognito/Aurora stack. 16-item pre-PR checklist. Key rules:
- `org_id` always from `claims["custom:org_id"]`, never from request body
- Pydantic validates every Lambda event body before business logic
- `secrets.token_urlsafe(32)` not `random` for generated tokens
- `@lru_cache` SSM secret fetch at cold start
- Audit row on every privileged action
- Search endpoints hard-cap at 8 results, never expose total count
- Stripe webhooks: verify HMAC before processing, idempotency on event ID

---

## Final State

- All `gt_*` table `id` and timestamp columns now have `DEFAULT gen_random_uuid()` / `DEFAULT NOW()`
- All INSERTs in the codebase pass `id` and timestamps explicitly
- `run-migrations` runner: 35 entries, 0 failures
- `announcements` POST/GET: working
- Two knowledge pages added to wiki: masterdb architecture + secure coding guide
