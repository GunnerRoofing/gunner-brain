---
type: diagnostic
title: queryWithTenant Diagnostic — gunnerteam_app via Proxy
created: '2026-06-24'
updated: '2026-06-24'
tags:
  - diagnostic
  - gunnerteam_app
  - rls
  - cutover
  - b1
related:
  - '[[gunnerteam/b1-soc2-cc6-least-privilege-db-roles]]'
  - '[[gunnerteam/masterdb-developer-handoff]]'
status: complete
---

# queryWithTenant Diagnostic — gunnerteam_app via Proxy

**Date:** 2026-06-24  
**Context:** cc-2156 — pre-cutover verification of the `SET LOCAL` tenant path as `gunnerteam_app` through `gunnerteam-dev-masterdb-proxy`. Reproduced exactly how v366 connects: Node `pg` client, proxy endpoint, SCRAM-SHA-256 auth.  
**Lambda:** one-off in prod VPC (`vpc-0530f022b0273f215`), deleted after run.

---

## Raw Results

| Step | Query | Result |
|---|---|---|
| s0 | `SELECT current_user, current_database()` | `gunnerteam_app / gunner_masterdb` |
| s1 | `SELECT id FROM organizations WHERE slug='gunner'` | `7d6db1bb-fc40-4063-9b08-a39e4ba95fb5` |
| s2 | `SELECT id FROM users LIMIT 1` | `d90fbd29-5bae-4b30-91ae-1e6e35b3cabb` |
| s3 | `BEGIN; SET LOCAL app.current_org_id = '<ORG>'; SELECT current_setting(…); ROLLBACK` | echoes `7d6db1bb…` ✅ |
| s4 | `SELECT count(*) FROM users` (plain) | 4 |
| s5 | same under SET LOCAL | 4 (identical ✅) |

### Per-table under SET LOCAL (s6)

| Table | Count | Notes |
|---|---|---|
| users | 4 | ✅ |
| user_organizations | 4 | ✅ |
| user_app_roles | 12 | ✅ |
| app_roles | 31 | ✅ |
| apps | 8 | ✅ |
| gt_user_profile | **0** | empty in prod — data gap, not RLS |
| gt_vehicle_schedules | **0** | empty in prod |
| gt_vehicles | **0** | empty in prod |

### s7 — exact `/auth/validate` query

| Condition | SET LOCAL org_id | Result |
|---|---|---|
| Prod org (correct) | `7d6db1bb-fc40-4063-9b08-a39e4ba95fb5` | **1 row** ✅ |
| Dev org (stale JWT) | `69aad261-347c-44db-8e9e-6c25a8509aa3` | **1 row** ✅ |

---

## Verdict

**SET LOCAL is NOT the root cause of any 401s.**

1. `SET LOCAL app.current_org_id` works for `gunnerteam_app` through the proxy — the value echoes back correctly (s3).
2. Plain vs SET LOCAL user count is identical (s4=s5=4) — SET LOCAL does not interfere with reads.
3. The exact `/auth/validate` query returns 1 row under both the correct prod org ID **and** the old dev org ID (`69aad261`). The p16 `gunnerteam_app_org` policies provide a safety net that survives any org ID in SET LOCAL — the permissive OR means the user is visible regardless.
4. `gt_user_profile`, `gt_vehicle_schedules`, `gt_vehicles` return 0 rows — these tables are **empty in prod**, not blocked. The validate query uses LEFT JOINs so NULLs propagate cleanly; no row is dropped.

**If 401 "User not found" occurred during the cc-2155 cutover, the cause is NOT:**
- RLS policy interaction with SET LOCAL
- Wrong org ID in SET LOCAL
- Missing grants on these tables

**The cause must be elsewhere — candidates:**
- A DB connection/authentication failure at the proxy layer (pool never connected → query never ran → `result.rows.length === 0` → 401)
- A different route or middleware failing before validate runs
- The test session used a stale/invalid JWT that had an expired or mismatched `sub` (user_id not in the prod DB)

**Immediate action:** before the next cutover attempt, exercise `/auth/validate` directly with a fresh Cognito token from Tyler's device against `gunnerteam-dev-api` (aliased to v366 temporarily) to confirm the exact failure path. If the pool never connects, the error log will show the pg connect error.

---

## Org ID Note

`GUNNERCAM_POINTS_ORG_ID` SSM = `69aad261-347c-44db-8e9e-6c25a8509aa3` — this is a GunnerTeam webhook-filter param, **not** the masterdb `organizations.id`. The prod masterdb has `slug='gunner'` → `7d6db1bb-fc40-4063-9b08-a39e4ba95fb5`. JWTs carry the masterdb ID (set at login via slug lookup). No mismatch on the auth path.
