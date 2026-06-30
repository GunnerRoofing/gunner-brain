---
type: session
title: 'Session 2026-06-29: comms-admin full stack + iOS fixes + masterdb migrations'
created: '2026-06-30'
updated: '2026-06-30'
tags:
  - session
  - gunnerteam
  - masterdb
  - comms-admin
  - ios
  - cc8.1
  - soc2
status: stable
related:
  - '[[gunnerteam/overview]]'
  - '[[tyler/masterdb/masterdb-architecture]]'
  - '[[gunnerteam/soc2-technical-summary]]'
  - '[[shared/gunner-platform-overview]]'
---

# Session 2026-06-29: comms-admin full stack + iOS fixes + masterdb migrations

Multi-repo engineering session covering: new `gunner-comms-admin` repo (cc-01 through cc-07 + cc-2206 provisioning), `gunnerteam-api` iOS/API fixes (cc-2820/2205/3000/3001/3002), and `gunner-masterdb` migration pipeline (cc-2821, migration-graph CI guard PR #14).

---

## gunner-comms-admin (new repo, built from scratch)

Admin-only, read-only viewer over `masterdb` `dp_*` tables (Dialpad SMS/calls). Full stack: Python Lambda backend + React/Vite frontend.

### Architecture

| Layer | Choice |
|---|---|
| Backend | Python 3.12 + Lambda Powertools + SQLAlchemy 2.0 + psycopg v3 |
| IaC | SST Ion (us-east-2), `sst.config.ts` |
| API | API Gateway HTTP API → Lambda |
| Auth | Cognito pool `us-east-2_hFVBSrcnn`, client `comms-admin-web` (id: `5k3jnst8is3mtqbljtf0vq2aue`) |
| Database | masterdb RDS Proxy, prod cluster `sczazkvf`, read-only DB role |
| Config | SSM SecureString under `/gunner/comms-admin/dev/` |
| Frontend | React 18 + Vite 5 + Amplify v6 + Tailwind 3 |

### Backend modules built

**cc-01 — Scaffold:**
- `config.py`: SSM batch fetch (`GetParametersByPath`), module-scope cache, never logs `_PASSWORD/_SECRET/_KEY/_TOKEN`
- `db.py`: read-only SQLAlchemy engine, `sslmode=verify-full`, RDS CA bundle bundled, pool_size=2, `read_session()` context manager
- `app.py`: Powertools `APIGatewayHttpResolver`, `GET /health`
- Cognito client `comms-admin-web` created; existing clients untouched
- SSM params set: `COGNITO_USER_POOL_ID`, `COGNITO_CLIENT_ID`, `PLATFORM_ORG_ID`, `RECORDINGS_BUCKET`

**cc-02 — Auth (updated version with MFA):**
- `auth.py`: JWKS-cached RS256 verifier, `get_principal()` extracts `email + custom:tenantId + amr` from Cognito JWT
- `require_admin()`: org-id check → MFA check (`REQUIRE_MFA=true` default, checks `amr ∩ {mfa, SOFTWARE_TOTP, HW_TOTP, otp}`) → DB-verified `gt-admin` role query (users→user_organizations→user_app_roles→app_roles→apps, slug=`gunner-team`) → 60s TTL cache. All IDs cast `::text`
- `audit.py`: INSERT into `audit_log` with correct column names (`details` not `metadata`; `created_at` supplied explicitly). Every row carries `email`, `source_ip`, `user_agent`, `request_id` in `details`. On failure: CloudWatch `GunnerCommsAdmin/AuditWriteFailure` metric emitted (cc-prompt-07 alarms on it)

**cc-03 — REST reads:**
- `cursor.py`: `PageCursor(occurred_at, type, id)` + `SinceCursor(occurred_at, id)` — opaque base64 JSON
- `feed.py`: UNION ALL of `dp_sms_messages` + `dp_calls` normalized to `FeedRow`. All filters applied INSIDE each arm. Default 7-day window. Keyset predicate handles `sms`/`call` type-boundary ties correctly (cursor type=`sms` → call arm includes all calls at `c_ts`; cursor type=`call` → sms arm excludes same-ts rows already shown). `recording_urls` / transcript text never projected. `agent_name` via single LEFT JOIN (no N+1)
- `GET /activity`: page mode (DESC) + since mode (ASC live tail, 200-row cap, no audit)
- `GET /thread?externalNumber=`: per-contact, audit on page mode
- `GET /agents`: `SELECT dialpad_name/email/phone/gt_user_id ORDER BY name`

**cc-04 — Gated media:**
- `s3.py`: `presign_get(bucket, key, expires=120)` — lru_cached S3 client, virtual-hosted, SigV4; never logs URL
- `GET /calls/{id}/transcript`: `transcript ?? transcription ?? not_ready`; audit `dialpad.transcript.viewed` with `externalNumber`; never logs transcript text
- `GET /calls/{id}/recording`: presigns each key; key-prefix guard rejects any key not starting with `{PLATFORM_ORG_ID}/`; raw `recording_urls` never returned; audit `dialpad.recording.accessed` with `keyCount`
- IAM: `s3:GetObject` on `arn:aws:s3:::gunnerteam-dev-dialpad-recordings/*` in `sst.config.ts`

**cc-05 — Frontend:**
- `GET /theme`: queries `gt_org_theme` for palette + org name; fallback to `organizations.name` + neutral dark defaults; no brand literals in code
- React app: Amplify v6 with tokens in `sessionStorage` (never `localStorage`) via `cognitoUserPoolsTokenProvider.setKeyValueStorage(sessionStorage)`
- Auth flow: `<Authenticator hideSignUp>` → load `/theme` → inject CSS vars → router
- `api/client.ts`: auto-attaches `Bearer idToken`; dispatches `auth:expired` on 401; `ForbiddenError` on 403; never logs tokens/URLs/bodies
- `FeedPage`: filter bar (type/direction/agent/number/date), keyset pagination, live tail
- `ThreadPage`: SMS bubbles + call cards; transcript in inline panel (per-click fetch); `<audio>` fed presigned URL (fresh fetch each click)
- SST `StaticSite` with HSTS (max-age=63072000 + preload) + CSP (frame-ancestors none, object-src none, connect-src scoped to Cognito+API GW+S3)

**cc-07 — Monitoring (SOC 2 CC7.2):**
- `monitoring.py`: centralized `authed_gate(event)` — JWT verify → admin gate → rate limit → structured access log. Emits `AuthFailure401` / `Forbidden403` to `GunnerCommsAdmin` namespace. 401 logged as `auth.denied.401`; 403 as `auth.denied.403.mfa_required` or `auth.denied.403.forbidden`
- CloudWatch alarms in `sst.config.ts`: `AuditWriteFailure >= 1` (5 min, page on first hit), `Forbidden403 >= 10` (5 min), `AuthFailure401 >= 20` (5 min), Lambda `Errors` 2-of-3 (1 min windows, no flap)
- Phase 4 confirmed: CloudTrail `gunner-events` (multi-region, all management events) captures `InitiateAuth` for pool `us-east-2_hFVBSrcnn` — no new build needed

**cc-2206 — Sub key provisioning (pending Tyler running):**
- `FIELD_PORTAL_SUBCONTRACTOR_API_KEY` goes in SSM at `/gunnerteam/dev/FIELD_PORTAL_SUBCONTRACTOR_API_KEY` (SecureString). No terraform change needed — `loadSecrets()` scans the full `SECRETS_PATH` prefix automatically
- `subApiKey()` in `lib/fieldPortalClient.js` reads it via `getSecretSync('FIELD_PORTAL_SUBCONTRACTOR_API_KEY')`
- Test fixture: crew `7f132300-d1ca-4512-a49b-c274acd137fe` ("TEST SubPortal Crew"), test user `subtest-crew@example.com`
- Verification chain: invite → complete-invite → `gt_subcontractor_crew` row → sub bearer → `/jobs` returns "Juliet Glatzer" → `/jobs/{id}/photos` 200 (real) / 404 (fake) → `/org/users` 403 → admin `/jobs` still 200

### Key test counts
- `tests/test_feed.py`: 28 tests (cursor roundtrip, org filter always present, keyset predicate shape, since direction)
- `tests/test_calls.py`: 20 tests (UUID validation, 404, not_ready, presign params, key-prefix guard)
- Total: 48 passing

### SST Secrets needed before first deploy
```
npx sst secret set SubnetId1 <private-subnet-id> --stage dev
npx sst secret set SubnetId2 <private-subnet-id> --stage dev
npx sst secret set LambdaSecurityGroupId <sg-id> --stage dev
```
DB SSM params + VPC config come from Colin. Post-deploy: subscribe admin email to `CommsAdminAlerts` SNS topic.

---

## gunnerteam-api changes (cc-2205, cc-2820, cc-3000/3001/3002)

**cc-2205** — `project.crew.assigned` webhook handler:
- `handleProjectCrewAssigned()` in `fieldportal.js`: HMAC-SHA256 over `req.rawBody`, dedup via `isDuplicate`, maps `crewId` → sub users via `gt_subcontractor_crew` (server-resolved), fan-out push via `Promise.allSettled`, audit `webhook.project_crew_assigned`. Wired into `/webhook` switch. v404 live.

**cc-2820** — Enrich worker bumps `dp_calls.updated_at`:
- Both `dialpadEnrich()` UPDATEs (transcript + recording_s3_keys) now include `updated_at = now()` so Leo's CRM transform polling by `updated_at` cursor catches late enrichment. v405 live.

**cc-3000** — UploadOutbox index-after-await race fix (iOS):
- Root cause: concurrent `@MainActor` completion tasks held a pre-await `Int` index across `await` points; `removeAll` shifted array, stale index → wrong row `.done` (hang) or out-of-range crash
- Fix: `private func index(of id: UUID) -> Int?` re-resolves by UUID after every `await`. Applied to `run()`, `handlePhotoCompletion`, `handleVideoCompletion`, `handleInspectionFieldCompletion`, `handleFormAttachmentCompletion`
- Test: `OutboxFinalizeOnceTests.testIndexSurvivesConcurrentRemoveAll` — enqueues 3 items, discards idA, asserts idB/idC still locatable

**cc-3001** — Black thumbnails on Submit fix (iOS):
- Root cause: `submit()` zeroes `capturedMedia` for memory efficiency; grid still rendered → blank UIImage shows as black
- Fix: hide thumbnail `ScrollView` during `isUploading || uploadResult != nil`; show centered upload icon instead; add Done button when `uploadResult != nil`; partial failure auto-dismisses after 2s with "N uploaded, M saved for retry"
- Removed dead `failedIndices` retry path (always reset to `[]`, button never rendered)

**cc-3002** — Always-available discard/escape (iOS):
- Root cause: `capturedMedia` non-empty flips top-left ✕→✓ (review), no escape route
- Fix: top-left always renders ✕; empty/uploading → immediate dismiss, non-empty+not-uploading → `showDiscardConfirm = true`; count badge becomes tappable (`mode = .reviewing`); review header gets trash button (gated on `!isUploading`); one shared `confirmationDialog` on `cameraRoot`

---

## gunner-masterdb changes (cc-2821, migration-graph CI guard)

**cc-2821** — `crm_activities.external_number`:
- Alembic revision `u1_crm_activities_extnum` (24 chars — fits `VARCHAR(32)` limit; `u1_crm_activities_external_number` at 33 chars was too long)
- Column: `text`, nullable, E.164. Index: `crm_activities_org_extnum_idx ON crm_activities (org_id, external_number)`
- Applied to prod cluster `sczazkvf` via throwaway Lambda (prod VPC, `vpc-0530f022`). Throwaway deleted.
- Chains off `t1_crm_sales_schema`; `u1_crm_activities_extnum` is now prod head

**Migration-graph CI guard (PR #14):**
- Adds `migration-graph` job to `.github/workflows/ci.yml`
- Runs `alembic heads` (no DB, ~2s) — builds revision map, fails PR if missing/renamed file or multi-head
- Catches the exact `KeyError: 'p20_dialpad_agents'` class that broke `main` earlier
- Branch `ci/alembic-graph-guard` → PR #14 open against `main`
- **Post-merge action needed (repo admin):** add `migration-graph` to `main` branch-protection required status checks

---

## Alembic VARCHAR(32) limit

`alembic_version.version_num` is `VARCHAR(32)`. Revision IDs must be ≤ 32 characters. `u1_crm_activities_external_number` (33 chars) hit this limit; shortened to `u1_crm_activities_extnum` (24 chars).

---

## Key infrastructure facts confirmed this session

- **Prod masterdb cluster:** `sczazkvf` (`gunner-masterdb-production-masterdbcluster-sczazkvf.cluster-c52gm8goign8.us-east-2.rds.amazonaws.com`), VPC `vpc-0530f022b0273f215`, subnets `subnet-004acfd6dbb59a231` / `subnet-0481e68e34ade2858`, SG `sg-06313256b581ef39a`
- **Dev masterdb cluster:** `kdsmbssw`, VPC `vpc-0eb66556f100c7b3c`
- **Deployed API Lambda bundle** was 11 migrations behind `main` (missing p17→t1); throwaway correctly bundled all 35 files from repo
- **CloudTrail `gunner-events`**: multi-region, all management events, `InitiateAuth` for Cognito confirmed present
