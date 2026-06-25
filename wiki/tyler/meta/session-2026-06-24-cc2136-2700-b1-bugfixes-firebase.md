---
type: session
title: >-
  Session 2026-06-24: B1 prod provisioning, photo OOM fixes, dumpster email,
  Firebase Crashlytics
created: '2026-06-24'
updated: '2026-06-24'
tags:
  - session
  - masterdb
  - b1
  - ios
  - firebase
  - crashlytics
  - dumpster
  - photo-upload
  - bugfix
related:
  - '[[tyler/masterdb/b1-soc2-cc6-least-privilege-db-roles]]'
  - '[[tyler/masterdb/masterdb-developer-handoff]]'
  - '[[tyler/hot]]'
status: stable
---

# Session 2026-06-24: B1 Prod Provisioning, Photo OOM Fixes, Dumpster Email, Firebase

Long session (~30 cc-prompts). Three major work streams + several bug chains.

---

## 1. masterdb B1 — gunnerteam_app provisioned on PROD (cc-2136 → cc-2153)

### GunnerTeam side (cc-2136)
- `complete-invite` route: app-generated UUID replaces `gen_random_uuid()`, `RETURNING` dropped, INSERT wrapped in atomic transaction. Live as v349. Required because `gunnerteam_app` (NOBYPASSRLS) gets 0 rows from RETURNING before `user_organizations` membership exists.

### masterdb side — migrations k11 → p16 applied to PROD cluster

**Critical topology finding (cc-2147):** The masterdb migrate Lambda connected to the **dev** cluster (`kdsmbssw`), not the production cluster (`sczazkvf`) that GunnerTeam actually runs on. All earlier migration work (k11–o15) landed on dev. Re-applied to prod via one-off Lambda in cc-2150.

**Aurora GUC blocker (cc-2148/2151):** `ALTER ROLE gunnerteam_app SET app.current_org_id = ...` fails on Aurora PG 17 — rds_superuser cannot set role-level defaults for unregistered custom GUCs (`app.*` namespace), regardless of quoting. `GRANT SET ON PARAMETER` also blocked. The `custom_variable_classes` param-group fix was misidentified as the solution — Aurora removed it in PG 9.2. **Resolution:** role-scoped RLS policies (p16) hardcode the gunner org_id directly into `gunnerteam_app`'s policy predicate. No GUC, no `SET LOCAL`, no proxy pinning.

**Migration chain applied to PROD:**
| Revision | What |
|---|---|
| k11 | CREATE ROLE gunnerteam_app (NOSUPERUSER NOBYPASSRLS), grants, gt_* ownership (37 tables), users INSERT policy |
| k12 | crew_members DELETE grant (found by cc-2142 grant audit) |
| k13 | Revoke 4 over-grants (contacts, services, org_services, service_clients) |
| n14 | Track ops_app provisioning in Alembic; ELSE ALTER ROLE removed (Aurora can't change NOSUPERUSER on existing role) |
| o15 | Merge revision (k13 + n14 were parallel heads off k12) |
| p16 | Role-scoped RLS policies for gunnerteam_app — org context without GUC/SET |

**p16 mechanism:** 19 permissive `gunnerteam_app_org` policies across 18 tables (direct `org_id = '<gunner-uuid>'` for org_id tables; EXISTS into user_organizations for `users`). OR-combined with existing `org_isolation` policy — no other role affected. Validated on dev: `SET ROLE gunnerteam_app` with no GUC → all FORCE-RLS tables return real rows.

**Other B1 outcomes:**
- `gunnerteam_app` password set on prod (cc-2152), `~/gunnerteam_app-prod-password.txt` for Tyler → Keeper + proxy secret
- `ops_app` password reset on prod (cc-2153), `~/ops_app-prod-password.txt` for Tyler → Keeper-share to Leo
- gunner-ops confirmed **direct connect** (cc-2144), no RDS Proxy → SET LOCAL is fine, no pinning concern

**Alembic head on prod:** `p16_gt_app_rls`  
**Verification (cc-2150):** SET_CONFIG role=gunnerteam_app with no session setup → gt_vehicles=29, users=11, user_orgs=14 — all correct.

---

## 2. Photo Upload Bug Chain (cc-2400 → cc-2407)

### Cert pinning (cc-2400)
Amazon RSA 2048 M04 intermediate hash `G9LNNAql897egYsabashkzUCTEJkWBzgoEtk8X/678c=` — **unchanged**, no cert drift.

### OOM fixes (cc-2400/2401/2402/2403/2404)
- **PHPickerWrapper data race** (cc-2400): `media.append()` called from concurrent backgrounds → EXC_BAD_ACCESS. Fixed: `serialQ.sync { media.append(...) }`.
- **submit() photo loop OOM** (cc-2401): all UIImages retained during encode. Fixed: `capturedMedia[idx] = .photo(UIImage())` before encode + `autoreleasepool` around each JPEG encode. O(N) → O(1) peak memory.
- **Camera keeps running during review** (cc-2402): frame buffers (~12MB each) held during 48MB JPEG encode → OOM. Fixed: `.onChange(of: mode) { .reviewing → camera.stop() }`.
- **renderComposite @3x scale** (cc-2403): `UIGraphicsImageRenderer(size: size)` with no format → device @3x → 12096×9072 buffer (439MB) for a 4032×3024 image. Fixed: `fmt.scale = src.scale`.
- **Resize helpers @3x** (cc-2404): same bug in 4 call sites across GunnerTaskModels, PhaseWorkflowModels, VehicleInspectionView+Data. Fixed with `ast_edit` across all 4.

### photos/confirm timeout bug (cc-2405/2406)
Root cause: `upstreamFetch(url, opts, intEnv(...), 'fieldportal photo confirm')` — args 3+4 swapped. `timeoutMs = 'fieldportal photo confirm'` → NaN → 1ms timer → AbortError → 500. Every MiddlePhaseCameraSession upload failed. Fixed: replaced with `ccFetch`. Org-verify preflight added in cc-2405 then removed in cc-2406 (it itself caused 404s).

### Missing payload fields (cc-2407)
GunnerCam POST /projects/:id/photos requires `contentType` + `byteSize` minimum. iOS wasn't sending them; backend wasn't forwarding them. Fixed: iOS adds both, backend constructs full payload matching batch upload contract.

### 5xx alarm root cause diagnosis (cc-2500)
- Windows A/C/E: cold-start 90s timeout during rapid deploy-version churn (multiple publishes flushed warm pool)
- Windows B/C: the 1ms upstreamFetch timeout bug (bulk 5xx) — fixed cc-2405/2406
- Window D: GunnerCam 400 Bad Request from missing payload fields — fixed cc-2407
- Audit `Query read timeout` = secondary (pool starvation from stacked timed-out connections)

---

## 3. Dumpster Email Feature (cc-2600 → cc-2604)

`POST /submit-dumpster` now:
1. Creates Monday item on Site Manager Forms board (existing)
2. Looks up vendor from PM procurement board (Monday board 18346389609) by customer name → Dumpster subitem → `board_relation_mky2y29c` (BoardRelationValue inline fragment required — plain `value`/`text` always null) → vendor email from vendors board
3. Sends SES email to vendor (TO), procurement@gunnerroofing.com (CC), Reply-To = procurement
4. `DUMPSTER_VENDOR_EMAIL_OVERRIDE` SSM param routes vendor TO address for testing
5. Date formatted as `June 24, 2026 — Afternoon (PM)` via `fmtSwapDate`
6. iOS sends `projectAddress` field; smUserId/resolveSmUserId removed (dead code)
7. Optimistic success — no polling (cc-2604)

Lambda: v359 live.

---

## 4. Firebase Crashlytics (cc-2700)

Added to iOS:
- `FirebaseApp.configure()` first in `AppDelegate.application(_:didFinishLaunchingWithOptions:)`
- `CrashlyticsSetup.swift`: `setUser(username:)` / `clearUser()` — username only, no PII
- Wired in `AuthManager.validate()` on login and `clearState()` on logout
- No Firebase Analytics — Crashlytics only
- `-ObjC` linker flag, DWARF with dSYM, run script phase with 5 input files

Commit: `5977edb`

---

## 5. Receipt PDF Deferred (cc-2700 — different block)

`POST /fieldportal/jobs/:jobId/receipt/commit` now registers PDF with Colin AFTER commit (not at scan time). `ReceiptFileRef` gains `byteSize: Int`. PDF only appears in Files tab after user taps Submit.

---

## Also This Session

- **CLAUDE.md minimized**: 793 → 339 lines. Added Reuse Rule, Three Questions (Architect/Operator/10-year-old), Engineering Workflow (unit test gate, retry cap, writer/tester split, worktree isolation).
- **gunner-masterdb CLAUDE.md**: gitignored by Leo's design — stays local only.
- **gunner-masterdb source of truth**: reconciled live Lambda to `origin/main`. Head confirmed `p16_gt_app_rls` on prod.
- **CONTRIBUTING.md**: added to gunner-masterdb with change-control rules.

---

## Lambda Version History (this session)
- v349: cc-2136 (complete-invite app UUID)
- v350: cc-2149 _sql diagnostic action
- v352–359: dumpster email iterations + photo bug fixes
- **v359: current live**
