---
type: hot-cache
updated: '2026-06-20'
---

# Tyler Hot Cache — 2026-06-20 (final)

## Current State
- **Lambda:** **v346 live** (`gunnerteam-dev-api`, alias `live`, RoutingConfig null). cc-2201 keep-warm now holds a live DB connection + connect headroom (kills the sparse cold-path apigw-5xx). cc-2132 zod input-validation. cc-2130 declared `@aws-sdk/client-dynamodb`. cc-2127 dropped the `gt_customer_photos` RLS vestige. cc-2126 jobId org preflight + shared FP client. cc-2125 gated the last unauth forms routes. cc-2124 `DB_PASSWORD` out → **env holds ZERO secrets** (config + `SECRETS_PATH`); cc-2123 ~17 app secrets out. cc-2118 HS256→Cognito-RS256-only. On v330 base: cc-2106 multer/node-forge/node-apn, cc-2102 DB TLS.
- **iOS build:** BUILD SUCCEEDED — **now warning-clean** (the 2 standing `CLGeocoder`/`reverseGeocodeLocation` iOS-26 deprecations in `PMJobViews.swift` migrated to MapKit `MKReverseGeocodingRequest`, commit `aae8044`). cc-1100–1110, cc-1200–1202, cc-1300, cc-2116 cert-pinning, cc-2117 jailbreak-detect, cc-1700 password checker on `main`. Tests: 50 outbox/offline + 9 JailbreakDetector = 59 in GunnerTeamTests.
- **Last session:** cc-2201 (2026-06-21) — **killed the sparse cold-path apigw-5xx** (commit `665fdc9`, deployed **v346**, rollback v344). Root cause (confirmed via a 3-day Logs Insights gate): the 5-min keep-warm kept the container alive but returned before any DB use, and `db.js idleTimeoutMillis` was 30s → the pooled RDS-Proxy connection died ~30s after each request; every post-idle request re-borrowed against the connect budget and occasionally blew it → `db.connect failed ms~5000 Connection terminated due to connection timeout` (POST /validate 503, auth/forgot-password 500, cold scheduled-task fails). Fix: `idleTimeoutMillis`→`intEnv('DB_IDLE_TIMEOUT_MS',360000)` (outlives the 5-min ping); `connectionTimeoutMillis` default→8000 (query_timeout/statement_timeout stay 3000 — slow QUERIES still fail fast); the keepWarm branch now pre-warms `loadSecrets()` + `pool.query('SELECT 1')` (best-effort, swallowed). **Env override caught:** `DB_CONNECT_TIMEOUT_MS` was set in SSM to 5000 (env wins over the code default) → bumped `/gunnerteam/dev/DB_CONNECT_TIMEOUT_MS`→8000 (v2) + targeted `terraform apply`. Verified: live env=8000, keepWarm→`warm` (SELECT 1 OK, 0 `pre-warm failed`), /health 200, migration ok:true, 0 connect-timeouts post-deploy. ⏳ **Pending: 24h watch of `apigw-5xx`/`lambda-errors` (target zero new) — re-run the Phase 0 Logs Insights query tomorrow to confirm.** prior cc-1700 password checker
- **🔓 Superuser-demotion readiness (cc-2127):** GunnerTeam app code is now safe for the DB app-role to be demoted off superuser — `gt_customer_photos` (the last RLS table) no longer has RLS, and all `gt_*` tenant isolation is app-level explicit `org_id` filters (no RLS, no reliance on superuser-bypass). **Colin still owns the actual `NOSUPERUSER`/`NOBYPASSRLS` flip** in the `gunner-masterdb` SST stack (the real tenant-isolation backstop) — pre-second-tenant gate, tracked separately. See `GunnerTeam-TenantIsolation-Decision-2026-06-20.md`.
- **🧪 Isolation suite + migrations module (cc-2128):** GunnerTeam migrations now live in **`src/migrations.js`** (exported object; `lambda.js` requires it; the on-demand `_migration` runner is unchanged). `npm run test:isolation` (needs `TEST_DB=1` + a throwaway localhost pg; CI `isolation` job provides postgres:16) is the regression net for app-layer `org_id` isolation. Test-only affordances, inert in prod: `db.js` skips TLS + reads `DB_PASSWORD` from env under `TEST_DB=1`; `secrets.js` `__setTestCache`. The bootstrap stubs masterdb-owned base tables then applies the REAL migrations (index/alter on un-stubbed masterdb tables are skipped). ✅ The cc-2128 `@aws-sdk/client-dynamodb` dep-gap was **fixed in cc-2130** (declared + bundled). **Next:** extend the suite to assert the DB-level RLS backstop once Colin's superuser demotion lands.
- **🚧 Org-scope CI guard (cc-2129):** `npm run check:orgscope` (backend CI step) is a heuristic tripwire — a NEW db.js `query()` on a tenant `gt_*` table MUST carry `org_id`, use `queryWithTenant`, or be annotated `// org-scope-ok <reason>` (reviewed global/cron/by-validated-id read). Regression net, NOT proof (cc-2128 isolation tests are the proof). Excludes `client.query` (hand-rolled SET-LOCAL transactions, e.g. the auth/users account-deletion cascades). Global tables allowlisted in the script (catalog/config/idempotency).
- **✅ cc-2118 regression RESOLVED (cc-2121) + EC2 chain CLEANED (cc-2122):** the abandoned assistant-stream Function URL Lambda is fully removed (Lambda + URL + log group destroyed, `lambda-assistant.tf` gone); the `var.jwt_secret`→`terraform.tfvars`→`user_data.sh` **EC2** chain is now also removed (cc-2122). No source-of-truth gap, no dangling public endpoint, no dead EC2 vars/scripts.
- **⚠️ Account-hygiene (cc-2122 audit, NOT GunnerTeam — separate owner review):** 6 EC2 in us-east-2 (+2 in us-east-1). Running long-lived dev boxes on the `devopsFrontend` key since 2024: `dev-gunner-salesPortalEc2`, `dev-gunner-CorpProtal-frontend`, `dev-gunner-hrPortalEc2`; plus `wl-companycam-dev-bastion` (Colin), `db-tunnel`; stopped `testindqp2-hubspot`. None is GunnerTeam's — flag for the relevant app owners (cost + possible userdata secrets); don't touch from GunnerTeam scope.
- **🔑 Runtime secrets (cc-2123/2124) — the env is now SECRET-FREE.** All secrets (incl. `DB_PASSWORD` as of cc-2124) live as SSM SecureString under `/gunnerteam/dev/`, fetched once/container by `lib/secrets.js` `loadSecrets()` (awaited at the top of `lambda.js`), read via `getSecretSync('NAME')` (drop-in for `process.env`; `getSecret()` = async fail-loud). `lib/db.js` builds its pg Pool lazily via `getPool()` → `getSecret('DB_PASSWORD')` (no module-load DB read). **New secret → `aws ssm put-parameter --type SecureString` under the path + read via `getSecretSync`/`getSecret`; do NOT add it to `lambda-api.tf` env.** Config/IDs/flags still go in env. IAM allows `ssm:GetParametersByPath` (cc-2107). ⚠️ SSM `DB_PASSWORD` must still equal the RDS Proxy's Secrets Manager secret (drift = outage) — no prompt changed either value. **Future:** read straight from the proxy's Secrets Manager secret to make that drift structurally impossible. Dead unreferenced `variable "db_password"`/tfvars line remains (harmless, pre-existing) — clean up opportunistically.
- **📝 Forms auth contract (cc-2125):** every forms route now requires `requireAuth`; the iOS create requests must set `FormSubmitPayload(requiresAuth: true)` (the executor attaches the Cognito Bearer only then; the outbox dispatcher supplies the token). ⚠️ **Rollout caveat:** existing app installs on the pre-cc-2125 build (requiresAuth:false) get **401 on IT-request/AP until they update** — unavoidable with backend gating, acceptable in dev (Monday is being removed pre-white-label). Could not run a live authed create (no Cognito RS256 token to forge) → authed path verified by construction + parity with the working `/submit-co`. One junk AP Monday item (`12329001233`) was created during a pre-propagation probe. iOS build NOT re-run (changes were literal bool flips, compile-safe).
- **OMP:** 16.1.6
- **Terraform drift:** current full `terraform plan` = **1 add / 0 change / 1 destroy = only `null_resource.clear_alias_routing` replace** (benign local-only re-trigger, no AWS infra). The cc-1635 VPC drift (9/1/4 in `RECONCILE-vpc-2026-06-19.md`) is no longer in the plan — resolved by the cc-2107/2109/2112 applies + reconcile.
- **Compliance reference (ingested 2026-06-20):** [[gunnerteam/soc2-technical-summary]] = canonical SOC 2 control posture by TSC (the cc-21xx work); [[gunnerteam/security-compliance-roadmap]] = org-wide program roadmap (frameworks, SOC 2 process, Hexnode→Jamf, SIEM, CMMC, CISO cert track — pricing/timelines are flagged estimates).

## Deploy Recipe (CRITICAL — both fixes required)
```bash
rm -f /tmp/gunnerteam-deploy.zip && \
zip -r /tmp/gunnerteam-deploy.zip . -x "*.git*" "node_modules/.cache/*" > /dev/null && \
aws s3 cp /tmp/gunnerteam-deploy.zip s3://gunnerteam-lambda-deploy-useast2/gunnerteam-deploy.zip \
  --region us-east-2 --profile mfa && \
aws lambda update-function-code --function-name gunnerteam-dev-api \
  --s3-bucket gunnerteam-lambda-deploy-useast2 --s3-key gunnerteam-deploy.zip \
  --region us-east-2 --profile mfa --query 'FunctionName' --output text && \
aws lambda wait function-updated --function-name gunnerteam-dev-api --region us-east-2 --profile mfa && \
VERSION=$(aws lambda publish-version --function-name gunnerteam-dev-api \
  --region us-east-2 --profile mfa --query 'Version' --output text) && \
aws lambda update-alias --function-name gunnerteam-dev-api --name live \
  --function-version "$VERSION" \
  --routing-config '{"AdditionalVersionWeights":{}}' \
  --region us-east-2 --profile mfa --query 'FunctionVersion' --output text && \
echo "v$VERSION"
```
- `rm -f` first — `zip -r` merges into existing archive; `npm ci` before zip if node_modules drifted (e.g. after the cc-2101 branch)
- `--routing-config`: shorthand is a no-op. **And inline single-quoted `'{"AdditionalVersionWeights":{}}'` gets MANGLED by the OMP bash tool → leaves a stale `{ver:1.0}` weight routing 100% to the WRONG version (cc-867/cc-2102). Pass JSON via an ENV VAR: `--routing-config "$RC"` with RC in env.**
- **`get-alias` lies (eventual consistency):** shows phantom `{oldVer:1.0}` even when the update returned `RoutingConfig:null`. To know which version actually serves, read CloudWatch log-stream `[version]` tags (`describe-log-streams --order-by LastEventTime`), NOT get-alias.
- **Post-deploy propagation lag (cc-2119):** right after an alias flip, a warm OLD-version container can still serve a few requests for ~30-60s even with alias=newVer/routing=null. A brand-NEW route will 404 on those (old code lacks it) → don't conclude the deploy failed. Confirm the serving version per request via the `[version]` log-stream tag, **wait ~45s, and re-test** (cc-2119: new `/device/integrity` 404'd on a warm `[331]`, then 401 once `[332]` served).
- **Safe deploy iteration:** `publish-version` → candidate vN (alias unchanged) → probe DB/TLS via `aws lambda invoke --qualifier vN --payload '{"_migration":"20260610_task_photos_unique","_secret":"<MIGRATION_SECRET>"}'` (does pool.connect() + no-op idempotent index; auth-free) → promote alias only if `[{"ok":true}]`.

## Env-change flow (Terraform)
1. Edit SSM param + add `data "aws_ssm_parameter"` + env line in `lambda-api.tf`
2. `AWS_PROFILE=mfa terraform plan -target=aws_lambda_function.api` — expect env-only diff
3. `AWS_PROFILE=mfa terraform apply -target=aws_lambda_function.api`
4. Publish version + update alias (deploy recipe steps 5–7)

## What's Live (v319)

### Alerting (cc-1630)
- **Email:** `admin@gunnerroofing.com` only (tyler.suffern removed)
- **Google Chat:** `GOOGLE_CHAT_WEBHOOK_URL` wired; `await postToGoogleChat(...)` (fixed freeze bug)
- **Timestamps:** Eastern time via `fmtET` in email + Chat
- **ok_actions:** all 4 alarms wired → RESOLVED fires to both channels
- **CloudWatch link:** IAM Identity Center SSO deep link

### Backend — receipt scanner (v283)
- `POST /fieldportal/jobs/:jobId/receipt/extract`: Textract AnalyzeExpense; unit-price model
- `POST /fieldportal/jobs/:jobId/receipt/commit`: `gt_receipts` + `gt_receipt_line_items`
- `POST /time/location-batch`: offline-buffered breadcrumbs with client `recorded_at`

### Backend — location consent (v277+)
- `POST /auth/validate` returns `location_consent`
- `POST /time/request-location`: APNs silent push ping

### iOS — receipt scanner (cc-1100–1110)
- `ReceiptImageProcessor`: Vision + CoreImage single-shot (no VisionKit)
- `ReceiptVerifyView`: side-push, `themeManager.theme.secondary`, unit-price model
- SCAN mode: live preview, framing guide, single-shot capture

### iOS — location (cc-1200–1201)
- `applyTrackingMode()`: off-job coarse accuracy (1km/900s), checked-in precise (100m/300s)
- `LocationPingQueue`: disk-backed FIFO, flush on reconnect + foreground

### iOS — offline uploads / outbox (cc-2002, cc-2010, cc-2012, cc-2013, cc-2014)
- `UploadOutbox`: disk-backed enqueue/dispatch; per-kind executors (photo, video, inspection, form, taskPatch)
- cc-2010 transport: `prepareTransfer` (presign → background `URLSession` S3 PUT) / `finalize` (confirm); resume-by-`s3Key`
- **cc-2012:** job videos now route through outbox (`VideoUploadExecutor`); `JobPhotoSessionView.submit()` enqueues video like photos; survives offline + relaunch; Pending Uploads shows `video.fill` + "Job video" + first-frame thumb
- Video confirm sends **no `tag`** (parity with old inline path); `tag` is only `MiddlePhaseCameraSession` / `PhaseDetailView+Actions`
- **cc-2013:** BGProcessingTask activated — `processing` UIBackgroundMode + `BGTaskSchedulerPermittedIdentifiers` (`com.gunnerroofing.outbox.presign`) in Info.plist; `registerBGTask()` in `didFinishLaunching`; `scheduleBGPresignIfNeeded()` on enqueue + scenePhase `.background` + handler reschedule. iOS-discretionary; foreground stays guaranteed trigger. Test: `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.gunnerroofing.outbox.presign"]`
- **cc-2014:** outbox invariants now unit-tested (decision points extracted to `App/OutboxLogic.swift` + executor statics; pure-logic, no network)

### iOS — unit testing (NEW, cc-2014 — first test target)
- Target `GunnerTeamTests` (hosted) + shared `GunnerTeam` scheme. **50 tests** (41 cc-2014 + 5 cc-2018 + 4 cc-2019), ~0.05s, 0 network.
- Run: `cd GunnerForms && xcrun simctl boot "iPhone 17" && xcodebuild test -scheme GunnerTeam -destination 'id=<UDID>' -only-testing:GunnerTeamTests`
- **MUST boot the sim first** — hosted bundle launches the app; cold sim → "preflight checks failed (Busy)".
- Adding targets to this project (objectVersion 77, synchronized groups): `xcodeproj` gem on **brew Ruby only** (`/opt/homebrew/opt/ruby/bin/ruby`); system Ruby 2.6 can't load it. `new_target` 5th arg = product group → pass `nil`. Script: `/tmp/add_test_target.rb`.
- **Swift-6 prep (cc-2021):** project is `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor`, so test classes touching @MainActor types/Codable-conformances from XCTest's nonisolated context warn ("main actor-isolated conformance … in nonisolated context" — Swift-6 errors). Fix: mark each test class (and the OutboxTestSupport helper enum) **`@MainActor`**. All GunnerTeamTests classes are now annotated. Did NOT flip SWIFT_VERSION/isolation (that's the actual migration, separate).

### Terraform
- `aws_s3_bucket_versioning` + `aws_s3_bucket_object_lock_configuration` in state (WORM)
- `gunner-audit-logs-dev`: GOVERNANCE/7yr Object Lock + versioning Enabled
- `monitoring.tf`: all 4 alarms have `alarm_actions`, `ok_actions`, `insufficient_data_actions`
- **Residual drift**: 9 add / 1 change / 4 destroy — VPC data source mismatch; see `RECONCILE-vpc-2026-06-19.md`

## Pending (priority order)
- **cc-1635:** Terraform VPC reconcile maintenance window (`RECONCILE-vpc-2026-06-19.md`)
- **SSP Addendum 1 sign-off:** route IT-SSP-001-A1 to Eric, Eddie, Andrew → [[gunnerteam/ssp-addendum-1-product-environment]]
- **Flip WORM to COMPLIANCE** before formal SOC 2 audit (currently GOVERNANCE)
- **`LOCATION_PING_FORWARD` flag:** off until CT/NJ consent #37 signed
- **Colin P&L endpoint:** `COLIN_PNL_API_URL` set but Colin's endpoint status unknown
- **Colin service key:** wire to `GET /time/location-compliance`
- **`REWARDS_ENABLED=false`:** set true when policy approved
- **`idle_in_transaction_session_timeout = 30000`** on RDS cluster param (pending-reboot)
- **`gt_location_history` 90-day prune:** recurring EventBridge schedule
- **`GUNNERCAM_POINTS_WEBHOOK_TOKEN`:** set real value in Lambda console
- **Employee notice** (`employee-notice-points-location.md`): HR/legal/IT sign-off
- **Terraform stash reconcile:** `stash@{0}`

## Key Facts
- Gunner org ID: `69aad261-347c-44db-8e9e-6c25a8509aa3`
- MFA ARN: `arn:aws:iam::980921733684:mfa/tylerMFA`; base profile `default`; mfa profile `mfa`
- Deploy bucket: `gunnerteam-lambda-deploy-useast2`, key `gunnerteam-deploy.zip`
- Migration secret: `gunner-migrate-2026`; invoke with `--qualifier <version>`
- `gt()` shell function in `~/.zshrc`: run `gt-setup` once; exports `$TOKEN` + `$API`

## Schema Gotchas
- `users.id` VARCHAR → `u.id::uuid`; `gt_user_profile` VARCHAR org_id/user_id → `::text` casts
- `SET LOCAL` rejects `$1` → string interpolation
- `gt_user_profile`: no `role`, no `display_name`
- Single flag owner rule: one function owns HUD state end-to-end; two functions guarding the same flag causes silent bail

## Operating Conventions (CLAUDE.md cc-1632)
- **Lambda freeze:** `await` all async before handler resolves — never fire-and-forget after `res.json()`
- **Secret handling:** `read -rs`; `printf '%s'` to verify; never dump Lambda env
- **De-pin rule:** hot reads with `org_id` WHERE clause → `query()` not `queryWithTenant()`
- **DB TLS (cc-2102):** `db.js` ssl = `{ ca: [...rdsBundle, ...tls.rootCertificates], rejectUnauthorized: true }`. RDS **Proxy** presents an Amazon Trust Services PUBLIC cert (Amazon Root CA 1 / Starfield G2), NOT an RDS CA — the RDS bundle alone fails `unable to get local issuer certificate`. Cert vendored at `gunnerteam-api/certs/` (un-gitignored), path `../../certs/` from src/lib. Never fall back to `rejectUnauthorized:false`.
- **Lambda IAM least-privilege (cc-2107):** `aws_iam_role_policy.lambda_api` in `terraform/lambda-api.tf`. CognitoAdmin = AdminCreateUser/SetUserPassword/DeleteUser/**AdminUserGlobalSignOut** scoped to `userpool/us-east-2_hFVBSrcnn` (the live pool). CloudWatchLogs scoped to `/aws/lambda/gunnerteam-dev-api:*` (no CreateLogGroup — group TF-managed). SES scoped to `identity/gunnerroofing.com`. VPCAccess ec2-ENI stays `*` (no resource-level support). Preserve these scopes on future edits; verify a new Cognito action with `aws iam simulate-principal-policy`.
- **S3 app-bucket baseline (cc-2109):** `terraform/s3.tf` references (not lifecycle-manages) `gunner-fleet-dev` (inspection photos, `var.s3_bucket`) + `gunner-assistant-docs` (`ASSISTANT_DOCS_BUCKET` SSM). Both have PAB (4×true) + `aws_s3_bucket_policy` DenyInsecureTransport (TLS-only) codified. **SSE deliberately NOT codified** (cc-2113 PARKED): both buckets enforce AES256 + `BlockedEncryptionTypes:[SSE-C]` (AWS Apr-2026 default) live, but the `blocked_encryption_types` arg landed in **aws provider 6.22.0** (drift-fixed in **6.40.0**) — NOT in our pinned `~> 5.0` (5.100.0). Codifying via `aws_s3_bucket_server_side_encryption_configuration` does a full PutBucketEncryption replace that would DROP the SSE-C block. **Only codify once the repo is on aws ≥6.40** (major 5→6 migration — don't do it just for this). Presigned PUT/GET (`src/lib/s3.js`) are https+SigV4 → unaffected by PAB or TLS-only.
- **DB topology + force_ssl (cc-2111):** the dev Lambda's DB is the **PRODUCTION** Aurora cluster despite the proxy name — `gunnerteam-dev-masterdb-proxy` (RequireTLS=False, but our client forces TLS) → `TRACKED_CLUSTER gunner-masterdb-production-masterdbcluster-sczazkvf` (Aurora PG 17.7, shared w/ Colin). CPG `gunner-masterdb-production-masterdbclusterparametergroup-bzfauowx` (cc-1503 `idle_in_transaction_session_timeout=30000` user param identifies it). `rds.force_ssl` is **already =1 / enforced** via the Aurora PG 17 engine default (dynamic, Source=system) → CC6.7 met; a separate unused `gunner-masterdb-dev-*` cluster has no proxy targets. **RDS gotcha:** `modify-db-cluster-parameter-group` to a value that EQUALS the engine default is silently deduped — no user-override is recorded (param stays Source=system). So force_ssl can't be pinned Source=user while 1 is the default; durable pinning would need TF to manage the CPG (not in TF today). Safe DB-TLS probe = migration runner (`{"_migration":"20260610_task_photos_unique","_secret":"gunner-migrate-2026"}` → `ok:true`).
- **⚠️ masterdb IaC ownership (cc-2114):** the shared prod Aurora cluster + its CPG are owned by a **separate SST/Pulumi app**, NOT our Terraform — tags `sst:app=gunner-masterdb` / `sst:stage=production`, CPG Description "Managed by Pulumi". So **never `terraform import` the masterdb cluster/CPG/proxy into `gunner-ios/terraform/`** — that creates dual-IaC ownership and `sst deploy` would fight TF on shared prod. Param changes (e.g. pinning `rds.force_ssl=1` Source=user) must go through the `gunner-masterdb` SST app (coordinate with its owner — likely Colin/DevOps). cc-2114 ABORTED for this reason.
- **Env-change:** SSM → tf → plan -target → apply → publish → alias
- **Routing-config:** always explicit JSON `'{"AdditionalVersionWeights":{}}'`. After `update-alias`, `get-alias` can return STALE routing (e.g. a phantom `{"<old>":1.0}`) for a few seconds — eventual consistency; re-read before assuming a stuck canary (cc-2017).
- **iOS actor isolation (cc-2014 fix):** project builds with `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor` (Xcode 26 Approachable Concurrency). Do NOT `await` synchronous `@MainActor` methods (e.g. `UploadOutbox.updateItemProgress`) — the call never suspends → "No async operations occur within await expression" warning. Just call it directly.
- **iOS verification lesson:** `xcodebuild` grep MUST include `warning:`, not just `error:|BUILD SUCCEEDED`. Filtering to errors hid 12 redundant-await warnings across the outbox executors through cc-2012/2013/2014.
- **iOS safeAreaInset × NavigationStack (cc-2016):** a `.safeAreaInset(edge:.top)` on a `TabView` (or on a `NavigationStack` itself) renders ABOVE/over the per-tab nav bar → covers the back button. Apply it to the navigated CONTENT inside the NavigationStack → bar stays above, banner below. Caveat: inset on the tab ROOT does NOT propagate to pushed views (banner shows on tab roots only; back button uncovered everywhere). Per-push banner would need per-destination insets (~25 scattered points — skipped as brittle).
- **iOS UI verification trick:** to ground a SwiftUI layout fix, build a throwaway harness app via the `xcodeproj` gem, use `NavigationStack(path: .constant([1]))` to auto-push to a detail, `xcrun simctl install/launch/io screenshot`, then read the PNG. Definitive without the real app's auth.
- **⚠️ iOS cert pinning (cc-2116) — cc-2110 dependency:** `App/CertificatePinning.swift` pins the API hosts to Amazon RSA 2048 M04 (intermediate) + Amazon Root CA 1 (backup) SPKI hashes; all app traffic goes through `API.session` (the pinned URLSession). **When the Cloudflare proxy (cc-2110) is flipped, the app will see Cloudflare's cert chain, not Amazon's — the pins in `CertificatePinning.swift` MUST be updated to Cloudflare's intermediate IN THE SAME RELEASE that enables the proxy, or every API call hard-fails (fail-closed).** Re-extract pins via `openssl s_client -connect <host>:443 -showcerts` → SPKI-SHA256 of the intermediate. Leaf is NOT pinned (rotates). Amplify/Cognito + S3 are pass-through (not pinned).

## CI / SAST (cc-2101)
- `.github/workflows/ci.yml` (monorepo root): jobs `backend` (npm ci → SBOM → check → test → `npm audit --audit-level=high` ENFORCING, no `|| true`) + parallel `sast` (Semgrep).
- **Semgrep gotcha:** anonymous registry packs (p/javascript, p/command-injection, …) do NOT bundle the `child_process` exec-sink rule — that taint analysis is Pro/login-gated. CI has no login → packs alone miss command injection. Committed local rule **`.semgrep/command-injection.yml`** (ERROR, taint req.* → exec/spawn) + `--config .semgrep` makes the gate real/deterministic.
- Semgrep scans **git-tracked files only** — `git add` a probe before local testing.
- SBOM: `@cyclonedx/cyclonedx-npm --output-file sbom.json` → uploaded as `sbom` artifact (CycloneDX 1.6).
- Deps bumped to clear audit: `multer` 2.2.0, `@parse/node-apn` 8.1.0 (node-forge 1.4.0; node-apn 8.0 only breaking change = drops Node 18, we run Node 20).
- PR flow: `github` tool `pr_create` defaulted head→main (broken); use `gh pr create --head <branch>`. Branch CI work off **origin/main** (local main carries unpushed iOS commits).
- **Log hygiene (cc-2104):** `scripts/check-log-hygiene.js` (`npm run check:logs`) fails CI when a `console.*` references req.body/headers/secret-ish tokens; opt out per-line with `// log-hygiene-ok` (only for digests/labels, never real secrets). Wired into `backend` after the syntax check. `scripts/` is gitignored at root → committed via a `!gunnerteam-api/scripts/` exception. Committed to **main** (not PR #6).
- **ci.yml divergence — RESOLVED (cc-2105):** PR #6 rebased onto main + merged (bf52df5). `backend` job is now the union (npm ci → SBOM+upload → check → log-hygiene → test → `npm audit --audit-level=high` ENFORCING) + parallel `sast` (with `--config .semgrep`). The cc-2101→main rebase auto-merged clean (non-overlapping step additions). multer/node-forge highs cleared in main's lock — not yet deployed.

## Dev Environment
- **iTerm scrollback:** `Settings → Profiles → Terminal → Scrollback lines` → ~1000
- **awsmfa:** must run in interactive terminal (not OMP bash tool — dumb terminal can't read code)
