---
type: hot-cache
updated: '2026-06-22'
---

# Tyler Hot Cache — 2026-06-24

## Current State
- **Lambda:** **v372 live** (`gunnerteam-dev-api`, alias `live`, RoutingConfig null). `LLM_PROVIDER=bedrock` (in-account, billing resolved). `/assistant/run` draft→200 (`us.anthropic.claude-haiku-4-5-20251001-v1:0` inference profile), extract→403. DB_USER=postgres (B1 forward flip still pending p17). See [[tyler/meta/session-2026-06-25-bedrock-billing-qp-key-org-reconcile]].
- **✅ LLM provider = bedrock (v372, RESOLVED):** Bedrock billing block cleared — Visa `••5127` set as default directly on member acct `980921733684` (the fix: consolidated member accounts need their OWN payment instrument for Marketplace; payer-only card does nothing). Failed payments had dropped the agreements → re-created via `create-foundation-model-agreement` → both `AVAILABLE` → flipped to bedrock. Anthropic bridge retired. **Gate before any future bedrock flip:** `get-foundation-model-availability … agreementAvailability.status` must be `AVAILABLE` for both models.
- **🔑 QP draft key LIVE (cc-1808):** row `b6e2e834`, org `69aad261`, scope `[draft]`. draft→200, extract→403. Leo cleared; Keeper value correct, no re-share.
- **🚨 B1 BLOCKER = two-org split (cc-2901):** `69aad261`/slug `gunnerroofing` = REAL org (all gt_ data, 8 members, app hardcodes it, =GUNNERCAM_POINTS_ORG_ID). `7d6db1bb`/slug `gunner` = masterdb-dev SHELL (0 gt_ data). **All 18 p16 RLS policies hardcode the SHELL `7d6db1bb`** → forward flip 401s every real user. Fix = Colin's **p17** (re-point policies `7d6db1bb`→`69aad261`, reversible, down_revision `p16_gt_app_rls`) then **p18** (dedupe + `UNIQUE(slug)` + migrate shell/orphan FK rows). After p17: Tyler runs `SET ROLE gunnerteam_app; SELECT count(*) FROM users` → expect 4→8 = green → proxy re-add → cc-2157 flip (gate#2=`69aad261`). cc-2157 strays for p18: joe invite `6e9954cb`, capital-Tyler grant `bce91d0c`. Cognito tenantIds verified already `69aad261`.
- **iOS build:** BUILD SUCCEEDED — **Firebase Crashlytics added** (cc-2700, commit `5977edb`). **cc-1800**: session freshness 4h→30m + scenePhase foreground reset (commit `73f902e`). Tests: 59 in GunnerTeamTests (unchanged).
- **Last session (2026-06-26c):** [[tyler/meta/session-2026-06-26-cc2918-2921-masterdb-phase4-tls-iam]] — masterdb Phase 4: TLS verify-full (PR#8), auth/RLS/connect alarms live, IAM tightened.
- **masterdb §14 Phase 4 open Colin items:** proxy `RequireTLS=false`; DB audit logging (pgAudit + CW log exports).
- **PR#8 open** (`app-tls-verify-full`): db/session.py verify-full TLS — ships on next masterdb API Lambda deploy.
- **Last session (2026-06-26b):** [[tyler/meta/session-2026-06-26-cc2912-2917-ci-fixes-rls-iam]] — cc-2912 PR#5 CI green; cc-2913 q1 crew_members RLS live on prod; cc-2915 PR#7 closed; cc-2916/17 IAM inventory.
- **q1_crew_members_rls ON PROD** — CC6.1 closed. Prod at `q1_crew_members_rls`. FORCE RLS live, 0 cross-tenant rows, 2 policies (org_isolation + gunnerteam_app_org).
- **IAM §14 worklist:** `leads-finder-dk` = Tyler's 2nd full-admin key (24.47.22.44, SOC2 finding); `permit-ops-dev-spare-macbook-runner` = never-used, awaiting Tyler's "deactivate" word. KinesisDataStreamFabricUser/wl-companycam/leo/tyler-cli all deferred.
- **Last session (2026-06-25):** [[tyler/meta/session-2026-06-25-cc2908-ci-gates-vault-restructure-lint]] — cc-2908 masterdb CI gates (ruff+bandit+semgrep+pip-audit+SBOM, PR #3 open, Colin review); vault project restructure (12 project files → tyler/{gunner-assistant,masterdb,gunnerteam}/); lint 308 pages, 23 auto-fixed.
- **masterdb CI (cc-2908, PR #3):** `.github/workflows/ci.yml` added. Gates: ruff, bandit (migrations excluded — DDL false-positive class), semgrep, pip-audit, SBOM. Follow-ups pending: dep pin (`requirements.lock`) + RLS isolation test (Postgres service container).
- **Last session (2026-06-24):** [[tyler/meta/session-2026-06-24-cc1800-2157-llm-engine-b1-cutover]] — LLM/assistant engine (cc-1800–1806) + B1 cutover root-cause chain (cc-2152–2157).
- **🤖 LLM engine live (cc-1801–1806, v368):** `lib/llm.js` provider-agnostic (`LLM_PROVIDER=bedrock`, Converse API). `POST /assistant/run`: qa/summarize/draft/classify/score/extract tasks + `quote_advisor` (Sonnet, fixed tier). `assessTier()` Haiku pre-flight for auto-tier on `/run`. `/chat` pinned to Haiku (1 call). Service-key dual-auth (`gtsk_` prefix) + `allowed_tasks` scope for QP. Bedrock model: `us.anthropic.claude-sonnet-4-6` (smart), `us.anthropic.claude-haiku-4-5-20251001-v1:0` (fast).
- **🔑 ORG ID — CORRECTED AGAIN (cc-2901, supersedes the 06-24 note):** The REAL operating org is **`69aad261`** (slug `gunnerroofing`) — holds 100% of gt_ data (29 vehicles, 6 profiles, 48 time entries), 8 members, and the app hardcodes it (`GUNNER_ORG_ID`, points seeds); it also = `GUNNERCAM_POINTS_ORG_ID`. **`7d6db1bb`** (slug `gunner`, what `SELECT … WHERE slug='gunner'` returns) is the masterdb-dev team's empty SHELL — 0 gt_ data. The 06-24 conclusion that `7d6db1bb` was canonical was WRONG; p16 RLS policies wrongly hardcode it. Auth lookups must target `69aad261`. Fix = Colin's p17/p18 (see B1 BLOCKER bullet above).
- **🔐 B1 masterdb — PROD provisioned (cc-2150/2151/2152):** `gunnerteam_app` role on production cluster (`sczazkvf`) with k11→p16 applied. Role-scoped RLS policies (p16) provide org context — no GUC (Aurora blocks `ALTER ROLE SET` for custom GUCs on rds_superuser). Password set. Proxy wired (cc-2154). `ops_app` password reset (cc-2153), in Keeper → Leo for gunner-ops swap.
- **⚠️ masterdb two-cluster topology (cc-2147):** masterdb migrate Lambda → **dev cluster** (`kdsmbssw`). GunnerTeam Lambda → **prod cluster** (`sczazkvf`) via `gunnerteam-dev-masterdb-proxy`. Alembic head on dev: `p16_gt_app_rls`. Alembic head on prod: `p16_gt_app_rls` (applied cc-2150). masterdb API Lambda also hits dev — Colin's `/v1/integrations/*` reads have been hitting dev data. Separate fix needed.
- **🐛 photos/confirm 1ms timeout (cc-2405/2406 — FIXED):** `upstreamFetch(url, opts, intEnv(...), 'label')` had args 3+4 swapped → `timeoutMs='fieldportal photo confirm'` → NaN → 1ms → AbortError → 500. Every MiddlePhaseCameraSession upload failed. Fixed by replacing with `ccFetch`. Root cause of Windows B+C in cc-2500 alarm diagnosis.
- **📧 Dumpster email live (cc-2600–2604, v359):** Vendor lookup via Monday PM board (BoardRelationValue inline fragment required) → SES to vendor + CC procurement@. Reply-To = procurement. `DUMPSTER_VENDOR_EMAIL_OVERRIDE` SSM param for testing (active: tyler.suffern@). Optimistic success (no polling). Human-readable date format.
- **📱 Firebase Crashlytics (cc-2700, `5977edb`):** `FirebaseApp.configure()` first in AppDelegate. `CrashlyticsSetup.setUser(username:)` on login, `clearUser()` on logout. Username only — no email/PII, no Analytics.
- **cc-2134:** **remediated the `gunner-fleet-worker-dev` static access key** (the one GunnerTeam item the cc-2133 sweep flagged). Confirmed abandoned: last used **2026-05-05** (7 wks), **zero CloudTrail in 90d**, repo grep clean of static creds, narrow blast radius (`s3:Put/Get/DeleteObject` on `gunner-fleet-dev/*` — the inspection-photo bucket the app reaches via the **Lambda execution role**, NOT this key). **Key `AKIA…GP2P` → Inactive 2026-06-20** (reversible); `/health` 200, app unaffected. ⏳ **Phase 2 (~2026-06-27, after a ~1-week soak):** if no new `AccessDenied`, `aws iam delete-access-key --user-name gunner-fleet-worker-dev --access-key-id <full-id>` (get it via `aws iam list-access-keys --user-name gunner-fleet-worker-dev`) → then detach managed policy `gunner-fleet-worker-dev-policy` + `delete-user`. Same no-static-keys standard applies to the other flagged keys, but they route to other owners (Leo `leonard.fuentes`, DevOps `KinesisDataStreamFabricUser`, Doug `gunner-content-engine`/`leads-finder-dk`) — **don't touch**.
- **Account hygiene sweep (cc-2133):** read-only sweep of `980921733684` — report [[gunnerteam/account-hygiene-sweep-2026-06-20]]. 8 public Function URLs (`AuthType=NONE`, 0 GunnerTeam); 8 IAM users all with static keys (only `tyler-cli` has MFA; **root MFA=false** + `leonard.fuentes` no-MFA = HIGH); 8 EC2 all `Owner`-untagged (0 GunnerTeam, incl. NEW `gunner-autolabel` g5.xlarge GPU); world-open SGs 5432 `wl-companycam-rds-dev`/6379 `redis-sg-dev`/SSH-22 ×5 (all dev VPCs, **none in our pinned prod VPC**); no admin or inline-`*:*` roles; account-level S3 PAB unset. **GunnerTeam's own surface otherwise clean.** ⏳ cc-2201 (v346) 24h apigw-5xx watch still open.
- **🔐 B1 — least-privilege DB role (cc-2138/2142, 2026-06-22):** `gunnerteam_app` provisioned on dev (`k11`). `crew_members` DELETE grant added (`k12`, cc-2142 audit). 17 `gt_*` tables reassigned. `users` INSERT policy in place. Evidence doc: [[gunnerteam/b1-soc2-cc6-least-privilege-db-roles]]. **Blockers before cc-2137 cutover:** (1) GUC (`ALTER ROLE … SET app.current_org_id`) blocked on Aurora PG17 — Colin must add `app` to `custom_variable_classes` in Aurora param group + reboot + invoke `provision_gunnerteam_app_guc` migrate action; (2) k12 not yet deployed to dev (MFA session expired — deploy when session is live); (3) password not set (`set_gunnerteam_app_password` migrate action). gunner-ops confirmed **direct** connect (cc-2144) — no proxy, `SET LOCAL` fine for cc-2141.
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
- **VOIP/softphone research (ingested 2026-06-22):** [[gunnerteam/voip-softphone-research]] = platform research for an in-app voice+SMS/MMS second line (**Dialpad replacement**). **Telnyx recommended** (Twilio runner-up; **Amazon Connect disqualified** — AWS can't share one number for voice+SMS → 2 numbers/rep). Biggest eng risk = iOS **CallKit/PushKit/WebRTC audio handoff** (spike week 1); **CT recording consent = all-party** (play a disclosure on every recorded call); per-tenant **10DLC** lead time (1–3 wks) gates white-label go-live; cost delta Telnyx~$135 vs Twilio~$195/mo is noise. Cross-linked to [[gunnerteam/dialpad-hubspot-integration]] (webhook bridge = near-term logging fix; softphone = strategic replacement). Research, **not yet a committed decision**.
- **📁 Session saved (2026-06-22):** [[tyler/meta/session-2026-06-22-cc2133-2135-hygiene-key-voip]] — close-out for cc-2133 (account sweep), cc-2134 (fleet key deactivated), cc-2135 (A4 fieldportal diagnostic), + the VOIP/softphone research ingest. Committed on this `/save`.

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

## What's Live (v368)

### Key features as of v368 (2026-06-24)
- **Dumpster email (cc-2600–2604):** Monday PM board vendor lookup → SES to vendor + CC procurement@. Reply-To = procurement. `DUMPSTER_VENDOR_EMAIL_OVERRIDE` SSM for testing (currently active: tyler.suffern@).
- **Photo upload OOM fixes (cc-2401–2404):** autoreleasepool in submit(), camera stop on .reviewing, renderComposite + 4 resize helpers use `fmt.scale = src.scale`.
- **photos/confirm fix (cc-2405–2407):** replaced swapped-arg `upstreamFetch` (1ms timeout bug) with `ccFetch`; adds `contentType`+`byteSize` to payload.
- **Receipt PDF deferred (cc-2700):** Colin file registration happens at commit, not at scan.
- **Alerting:** `admin@gunnerroofing.com`, Google Chat, Eastern timestamps, ok_actions on all 4 alarms.
- **Firebase Crashlytics (iOS, `5977edb`):** username-only context, no Analytics.

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
- **REAL Gunner org ID** (all gt_ data, app hardcodes, =points org): `69aad261-347c-44db-8e9e-6c25a8509aa3` (slug `gunnerroofing`) ← auth/DB queries target this; also `GUNNERCAM_POINTS_ORG_ID`
- Shell org (masterdb-dev team, slug `gunner`, what `WHERE slug='gunner'` returns, 0 gt_ data): `7d6db1bb-fc40-4063-9b08-a39e4ba95fb5` — p16 wrongly hardcodes this; p17 re-points to `69aad261`
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
