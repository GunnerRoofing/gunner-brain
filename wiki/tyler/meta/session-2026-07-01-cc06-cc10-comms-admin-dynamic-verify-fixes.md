---
type: session
title: session-2026-07-01-cc06-cc10-comms-admin-dynamic-verify-fixes
created: '2026-07-01'
updated: '2026-07-01'
tags:
  - comms-admin
  - cognito
  - mfa
  - audit
  - cloudwatch
  - iam
  - sst
  - lambda
  - soc2
  - verification
status: stable
related:
  - '[[tyler/meta/session-2026-06-30-cc08-09-comms-admin-tls-packaging]]'
  - '[[tyler/meta/session-2026-06-29-cc2820-3002-comms-admin-full-stack]]'
  - '[[shared/rds-proxy-tls-and-sst-python-packaging]]'
  - '[[tyler/concepts/mfa]]'
---

# Session cc-06 / cc-10 — comms-admin dynamic verification: 3 deploy-blocking bugs found, fixed, committed

cc-06 is the end-to-end dynamic verification pass over the live `gunner-comms-admin` **dev** deploy
(admin-only read-only viewer over masterdb `dp_*` Dialpad SMS/call data; SST/Pulumi + Python 3.12
Lambda behind API Gateway HTTP API; Cognito pool `us-east-2_hFVBSrcnn` client `comms-admin-web`).
Verification found **three critical, deploy-blocking bugs**, all fixed in-scope and re-verified live.
cc-10 committed the fixes (commit `05ccea4`) to kill the drift — until then they existed only on the
Lambda via `update-function-code`/`put-role-policy`. All AWS ops use `AWS_PROFILE=mfa` (the `tyler-cli`
user is MFA-gated by an explicit `GunnerRequireMFA` deny; plain calls are denied).

API: `https://ghd55lgjwg.execute-api.us-east-2.amazonaws.com`. Account `980921733684`, us-east-2.
Function `gunner-comms-admin-dev-CommsAdminHandlerFunction-ozkootkm`; role
`…CommsAdminHandlerRole-bddcubrt`; log group `…CommsAdminHandlerFunction-tffumtsf` (SST sets a custom
log group, so its name ≠ the function name).

## The 3 bugs (all would fire the moment a real admin used the tool)

### Bug 1 — MFA gate locked out EVERY admin (cc-02 scope)
`require_admin` gated MFA on `_MFA_FACTORS.intersection(principal["amr"])`, but **this Cognito pool's
`USER_SRP_AUTH` + `SOFTWARE_TOKEN_MFA` flow — the exact flow the Amplify frontend uses — emits NO `amr`
claim** in either the id or access token, even after a fully-completed MFA challenge. Proven by minting
a genuinely MFA-authenticated token (it passed a live `SOFTWARE_TOKEN_MFA` challenge — an earlier
attempt even failed at that step with `ExpiredCodeException`) and dumping the entire claim set: no
`amr`. With `REQUIRE_MFA=true` (the default, confirmed live), a fully-enrolled admin got
`403 mfa_required`. **Total admin lockout**, and it blocked the entire downstream admin surface.

**Fix (`auth.py`):** verify MFA **server-side** via `cognito-idp admin_get_user`
(`UserMFASettingList` non-empty). On an OPTIONAL-MFA pool an enrolled user is *always* challenged at
sign-in, so "has an enrolled MFA factor" is an exact proxy for "this token was obtained with MFA".
Cached 60s; fails **closed**. Does NOT touch pool-level MFA config (the pool is shared with the mobile
app). Requires `cognito-idp:AdminGetUser` (added to IAM). `amr` dropped from the `Principal` TypedDict
and `get_principal`.

### Bug 2 — access-denial metrics never emitted (cc-07 scope)
The handler role had only `s3:GetObject` / `ssm:GetParameters` / `kms:Decrypt` — **no
`cloudwatch:PutMetricData`**. `monitoring._put_metric` and `audit._emit_failure_metric` caught the
resulting AccessDenied and logged `metric_emit_failed`, so **`AuthFailure401`, `Forbidden403`, and
`AuditWriteFailure` never emitted** — silently blinding all three cc-07 alarms. Confirmed in logs
(`metric_emit_failed` for both the 401 and 403 test traffic) and by 0 datapoints in CloudWatch.

**Fix (`sst.config.ts` IAM):** add `cloudwatch:PutMetricData`, scoped by condition
`cloudwatch:namespace = GunnerCommsAdmin` (PutMetricData has no resource-level scoping). After the fix,
`AuthFailure401`/`Forbidden403` land in the `GunnerCommsAdmin` namespace and `metric_emit_failed`
disappears from logs.

### Bug 3 — EVERY audit write threw (cc-02 scope; the app's whole SOC 2 point)
Surfaced by an in-VPC probe running the app's exact INSERT as `comms_admin_ro`. Two schema mismatches:
1. **`audit_log.id` is `NOT NULL` with NO DB default**, but the app's `_INSERT` omitted `id` →
   `IntegrityError: null value in column "id" … violates not-null constraint`.
2. **`audit_log.user_id` FKs to `users.id`**, but the app stamped `principal["sub"]` (the **Cognito
   sub**), which is NOT a masterdb `users.id`. Verified: the 3 gt-admins' Cognito subs do not exist as
   `users.id` (e.g. tyler.suffern `users.id = 3e3f0491…` vs Cognito sub `61ab55c0…`). The admin gate
   joins on **email**, not id — corroborating that sub ≠ users.id. → FK violation.

Both failures were invisible: `audit()` swallows errors, and the failure metric couldn't emit (Bug 2).

**Fix (`audit.py` + `auth.py`):** generate `id = str(uuid.uuid4())`; resolve the real masterdb
`users.id` in the admin gate (`_is_admin_db` now `SELECT u.id::text …`, returns `(is_admin, user_id)`,
cached), stash it as `principal["user_id"]`, and stamp THAT as `audit_log.user_id` (FK-valid), never
the Cognito sub. Probe-verified: the fixed INSERT shape (generated id + real `users.id` + platform org)
passes privilege + FK + RLS `WITH CHECK` + NOT NULL; a wrong-org INSERT is correctly rejected by RLS.

## How it was verified (no forging possible)
The backend verifies a real Cognito RS256 signature + audience = `comms-admin-web`, so tokens cannot be
forged. **Real ID tokens were minted via hand-rolled Cognito SRP (`USER_SRP_AUTH`) in stdlib** (the
client allows only SRP + refresh; no admin-password flow), against throwaway test users
(`cc06-verify@`, `cc06-nomfa@`) created with controlled `custom:tenantId` and TOTP enrollment — all
deleted at the end. TOTP computed in stdlib (no `pyotp`). Secret code / raw tokens written to `0600`
temp files, never printed; shredded after.

DB-layer mechanics were verified with a **one-off in-VPC probe Lambda** (`cc06-probe`, deleted after)
reusing the app's own role + subnets + SG + `comms_admin_ro` creds, importing the app's own
`query_feed`/`db`/`audit` modules — so it exercised the *deployed* code paths against *real* data as the
*same* least-priv role.

## Results by item
- **Auth matrix — PASS.** no token → `401`; `/health` open (`db:ok`); wrong `custom:tenantId` → `403`
  Forbidden; non-enrolled → `403 mfa_required`; enrolled non-admin → `403` Forbidden ("Not an admin",
  proving the DB gt-admin round-trip runs). Metrics now emit.
- **Keyset — PASS.** Probe walked all 1304 feed rows with `limit=1`: page-walk reproduced ground-truth
  order exactly — no dup, no skip, `nextCursor` null only on the last page. `?since=` returned only
  strictly-newer rows and excluded the cursor row; always `nextCursor=null` in since-mode. Real data
  has same-*second* sms/call pairs but they differ at microsecond precision, so the exact-equal-
  timestamp tie-break isn't exercised by natural data (covered by unit tests; a scratch dp_* row can't
  be inserted by the read-only role).
- **Org isolation — PASS (SQL) / HTTP-404-as-admin BLOCKED.** A real `call_id` resolves under the
  platform org but returns None under a foreign org for both transcript and recording → the
  `_NotFound → 404` mechanism (all queries carry `WHERE org_id = :org`). Prod is single-org, so no
  natural cross-org id exists and none can be inserted (read-only).
- **Gated media — PASS.** Presigned URL is real S3 (`X-Amz-Signature`, under `<org>/` prefix), GET →
  200 (plays), and after TTL expiry GET → 403; no raw Dialpad `recording_urls` in the response
  (the app never selects that column). App TTL = `_PRESIGN_TTL = 120s`. `not_ready` path fires when
  `recording_s3_keys` is null (104 such calls in data).
- **Audit rows — write path FIXED & proven / live row-count BLOCKED.** Pre-fix 100% failed; post-fix
  the INSERT succeeds. Routes emit exactly one audit call per open with the correct action
  (`dialpad.thread.viewed` / `.transcript.viewed` / `.recording.accessed`), `externalNumber` in
  `details`, and never transcript text. Asserting "exactly one row live" needs a gt-admin token + a
  role that can `SELECT audit_log` (`comms_admin_ro` is INSERT-only there, by design) — BLOCKED.
- **Live-tail — PASS (mechanism) / full-UI BLOCKED.** `POLL_INTERVAL = 5_000ms`; `poll` early-returns
  on `document.hidden`; a `visibilitychange` handler `clearInterval`s on hide and restarts on show;
  rows prepend (scroll preserved). `?since=` contract proven by probe.
- **Hardening — PASS.** `sslmode=verify-ca` is the only mode in the connect path (no
  verify-full/require/disable); `/health` `db:ok` proves it connects through the proxy. DB role
  rejects UPDATE/DELETE on `dp_*`/`audit_log` (`permission denied`); `audit_log` is append-only (INSERT
  only, SELECT denied). No secrets in logs: 0 matches for `eyJ`/`X-Amz-Signature`/`Signature=`/
  `Authorization`/`password`/`Bearer` across the test window; denial log lines carry only
  action/source_ip/request_id/status.

## BLOCKED items — exact missing prerequisite
The HTTP-level org-isolation 404, the live audit row-count assertion, and the live-tail UI behavior all
need one or both of: (1) a **real gt-admin Cognito login** (gt-admins: `andrew@`, `eddie@`,
`tyler.suffern@`) — a controlled test user can't clear the DB gt-admin gate, and seeding a scratch
gt-admin needs a cluster-master DB write (Colin-gated migrate path; ad-hoc master-cred writes to shared
prod-grade data were deliberately not performed); (2) a **DB role that can `SELECT audit_log`**
(cluster-master or a granted read role). Their underlying mechanisms were all proven via the probe.

## Deploy blocker (separate defect, flagged)
`sst deploy --stage dev` is currently **broken**: it aborts on the cc-05 frontend
`CommsAdminSiteAssetsBucket aws:s3:BucketV2` with `sdk.helper_schema: missing expected [:
provider=aws@6.66.2` — a pulumi aws-provider schema bug on the existing bucket, orthogonal to the
backend. Because of this the cc-06 fixes were applied to the live Lambda via `update-function-code` +
`put-role-policy` (matching committed source; self-healing on the next clean deploy). Fix needs an
aws-provider pin or bucket-state repair before SST can deploy again.

## cc-10 — commit (kill the drift)
Committed the four fix files + `.gitignore` (added `.DS_Store`) + `package-lock.json` (root
`package.json` is tracked; the lockfile isn't matched by the `.gitignore` `*.lock`, so committing it
keeps status clean) as commit **`05ccea4`**:
`cc-06: fix MFA amr lockout (server-side MFA via admin_get_user), audit_log INSERT (supply id + real
users.id FK), + IAM (AdminGetUser, PutMetricData)`. Unit suite 48/48. `git status` clean. A future
clean `sst deploy` (cc-11) now reconciles the live patch with source.

## Key gotchas / reusable facts
- **This Cognito pool emits no `amr` on SRP+TOTP.** Do not gate MFA on `amr` for `us-east-2_hFVBSrcnn`
  — verify enrollment server-side via `admin_get_user` (`UserMFASettingList`). On an OPTIONAL-MFA pool,
  enrolled ⇒ always challenged ⇒ enrollment == MFA-used.
- **`audit_log` schema (masterdb, gunner-ios-owned):** `id` is `NOT NULL` with **no DB default** — the
  writer must supply `uuid4()`. `user_id` **FKs to `users.id`**; the Cognito `sub` is NOT a `users.id`,
  so resolve the real users.id (by email, as the admin gate already does). Recommend a masterdb
  migration adding `DEFAULT gen_random_uuid()` on `audit_log.id` as defense-in-depth.
- **PutMetricData needs an explicit IAM grant** (no resource-level scoping; scope by
  `cloudwatch:namespace` condition). A missing grant fails silently (caught → `metric_emit_failed`),
  blinding alarms.
- **Cognito SRP + TOTP can be minted in stdlib** (no `pycognito`/`pyotp`) when only `USER_SRP_AUTH` is
  allowed and you can't forge tokens. `admin-set-user-password --permanent` + `associate/verify-
  software-token` + `admin-set-user-mfa-preference` on a throwaway user; delete after. TOTP reuse
  within one 30s window → `ExpiredCodeException` (space mints ≥31s).
- **One-off in-VPC probe pattern:** reuse the app's role/subnets/SG + `comms_admin_ro` creds, import
  the app's own modules, exercise the real code paths against real data; roll back writes to avoid
  polluting append-only tables; delete the function immediately after.
- **SST custom log group:** the function's log group name (`…-tffumtsf`) ≠ the function name
  (`…-ozkootkm`); read `LoggingConfig.LogGroup` to find it.
