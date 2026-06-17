---
type: hot-cache
updated: '2026-06-17'
---

# Tyler Hot Cache — 2026-06-17

## Current State
- **Lambda:** v259 (`gunnerteam-dev-api`, alias `live`, prod Aurora via RDS Proxy)
- **iOS build:** BUILD SUCCEEDED — cc-815–842 committed to `main`
- **Last session:** cc-815–842 (2026-06-17) — location compliance, iOS file split, service keys
- **omp:** 16.0.5; `/clear` skill updated to end with `/new` instruction

## Process Rule
**Git is the source of truth — solo-maintainer rules:**
- **Solo iOS/backend work** (Tyler only): commit directly to `main`. No branch, no PR.
- **Shared Lambda** (Colin + automated sessions): reconcile before deploying; never hand-patch.
- **Cross-team / shared infra**: PR + owning-team sign-off required.

## awsmfa
`awsmfa` in `~/.zshrc`: prompts code → `unset AWS_*` → `sts get-session-token` → writes to BOTH shell env AND `mfa` profile. One command, works everywhere.

## What's Live (v259)

### Backend — location consent/compliance (new this session)
- `gt_user_profile.location_consent` (boolean, default false, migration 20260617_location_consent)
- `PATCH /time/location` + `POST /time/travel-ping`: consent-gated (no write if false)
- `gt_user_location_status` table (migration 20260617_user_location_status)
- `PATCH /time/location-permission`: upserts OS permission status (un-gated)
- `GET /time/location-compliance`: dual-auth (Cognito admin/manager + service key); all org users
- `GET /time/fleet-locations`: +`auth_status` column
- **Dev opt-in**: `UPDATE gt_user_profile SET location_consent = true WHERE user_id = '3e3f0491-b16f-42cd-9437-028a4a3ad771'`

### Backend — service keys (fixed)
- `POST /templates/service-keys` was always 500 (phantom `updated_at` column) — fixed
- `GET /templates/service-keys` (list) + `DELETE /templates/service-keys/:id` (revoke) — new
- **Colin's key**: `5762117f3cc91a2f0e3ccc9beadeea4dca9f0534fd3bb777c156c09ce4e0c4c1` → 1Password

### Backend — other fixes
- `routes/fleet/index.js`: `require('../points/awardPoints')` → `../../` (3 sites, was causing 500 on every inspection submit — **cc-835 was critical**)
- Monday item names: `"<customer> - Dumpster Swap"` / `"<customer> - Material Shortage"`
- `forwardLocationPing`: uses `FIELD_PORTAL_API_URL/KEY`; flag still off

### iOS
- `locationConsentGranted` in `AuthManager`; consent gates heartbeat stream in `CheckInManager`
- `reportPermissionStatus()` fires on every auth-status change + foreground
- `LocationComplianceView` in PMPickerSheet (checklist button, admin/manager)
- Massive file refactor complete: all CLAUDE.md iOS file rules satisfied

## Migrations Run (prod Aurora — complete list)
20260612_points_ledger, 20260612_achievements, 20260612_leaderboard_optin, 20260612_redemptions, 20260612_point_multipliers, 20260612_points_exclusions, 20260613_delta_cursor, 20260613_deduction_rules, 20260613_review_cursor, 20260616_location_history, 20260616_location_history_retention, 20260617_location_consent, 20260617_opt_in_dev_accounts, 20260617_user_location_status

## Service Key Rotation
```bash
gt && curl -s "${API}/templates/service-keys" -H "Authorization: Bearer ${TOKEN}" | jq .
curl -s -X DELETE "${API}/templates/service-keys/<id>" -H "Authorization: Bearer ${TOKEN}"
curl -s -X POST "${API}/templates/service-keys" -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" -d '{"description":"..."}'
```

## Open Items
- `gt_location_history` 90-day prune → recurring EventBridge schedule
- `GUNNERCAM_POINTS_WEBHOOK_TOKEN` + `REWARDS_ENABLED=false`
- Terraform stash reconcile
- Employee notice — HR/legal/IT sign-off
- `LOCATION_PING_FORWARD` flag — off until consent #37 signed
- Colin to wire service key to `GET /time/location-compliance`

## Key Facts
- Gunner org ID: `69aad261-347c-44db-8e9e-6c25a8509aa3`
- MFA ARN: `arn:aws:iam::980921733684:mfa/tylerMFA`
- Deploy bucket: `gunnerteam-lambda-deploy-useast2`, key `gunnerteam-deploy.zip`
- Migration secret: `gunner-migrate-2026`; use `--qualifier <version>` to hit fresh container

## Schema Gotchas (masterdb)
- `users.id` is **varchar** → all JOINs need `u.id::uuid`
- `gt_user_profile.user_id`/`.org_id` are **varchar** → `::uuid` casts needed
- `gt_user_profile` has **no `role`** (use `req.user.role`) and **no `display_name`**
- `pg` string param vs uuid column → `$1::uuid`
- `captured[0]` in camera callbacks is `[Int: Data]` dict — safe, do not replace with `.first`
