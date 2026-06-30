## [2026-06-30] save | Session — comms-admin full stack + iOS fixes + masterdb migrations
- Type: session
- Location: wiki/tyler/meta/session-2026-06-29-cc2820-3002-comms-admin-full-stack.md
- From: gunner-comms-admin repo built end-to-end (cc-01 scaffold → cc-02 auth+audit → cc-03 REST reads → cc-04 gated media → cc-05 React frontend → cc-07 monitoring); iOS cc-3000 UploadOutbox race fix, cc-3001 black thumbnails, cc-3002 discard escape; gunnerteam-api cc-2205 crew webhook + cc-2820 enrich updated_at; masterdb cc-2821 crm_activities.external_number + migration-graph CI guard PR #14; cc-2206 sub key provisioning plan

## [2026-06-29] save | Gunner Platform Overview
- Type: synthesis
- Location: wiki/shared/gunner-platform-overview.md
- From: conversation compiling cross-team ecosystem map for infrastructure onboarding (GunnerTeam iOS, GunnerCam, gunner-ops, Doug's tools, QP, Eddie's window quoting tool, Eric's Gunner Notes, shared AWS/Aurora infra)

## 2026-06-29 save | Session — cc-3100 + cc-3102: Weather feature (OpenWeather foundation + NWS default)
- Type: session
- Location: wiki/gunnerteam/meta/session-2026-06-29-cc3100-3102-nws-weather-provider.md
- From: cc-3100 (lib/weather stack, OpenWeather One Call 3.0, GET /weather/job/:jobId, Lambda v400); cc-3102 (contract.js eventToKind, nws.js 3-request flow + caches, flip WEATHER_PROVIDER=nws, 28/28 unit tests, Lambda v403)

## 2026-06-26 save | Session — cc-2807–2809: Dialpad updated_at + monitoring
- Type: session
- Location: wiki/tyler/meta/session-2026-06-26-cc2807-2809-dialpad-updated-at-monitoring.md
- From: cc-2807 (masterdb p21 `updated_at` + cursor indexes), cc-2808 (rate limit + updated_at touches + dialpad-health task, Lambda v389), cc-2809 (Terraform 4-alarm event-loss monitoring + PutMetricData IAM + hourly EventBridge health schedule, Lambda v390)

## 2026-06-26 save | Session — Dialpad full capture: dp_events, lossless ingest, recordings bucket
- Type: session
- Location: wiki/tyler/meta/session-2026-06-26-cc2810-2812-dialpad-full-capture.md
- From: cc-2810 p22 prod (dp_events + dp_calls cols); cc-2811 lossless raw write (v391); cc-2812 recordings bucket + IAM (v392)

## 2026-06-26 save | Session — masterdb Phase 4: TLS, alerting, IAM least-priv
- Type: session
- Location: wiki/tyler/meta/session-2026-06-26-cc2918-2921-masterdb-phase4-tls-iam.md
- From: cc-2918 Phase 4 verification sweep; cc-2919 verify-full TLS PR#8; cc-2920 auth/RLS/connect alarms; cc-2921 IAM tightened (SecretsManager removed, subnet/namespace conditions)

## 2026-06-26 save | Session — CI fixes, crew_members RLS to prod, IAM key audit
- Type: session
- Location: wiki/tyler/meta/session-2026-06-26-cc2912-2917-ci-fixes-rls-iam.md
- From: cc-2912 PR#5 CI green; cc-2913 q1 to prod (throwaway Lambda + prod VPC lesson); cc-2915 PR#7 closed; cc-2916/2917 IAM inventory (leads-finder-dk = Tyler's 2nd admin key, spare-macbook-runner never-used)

## 2026-06-25 save | Session — masterdb CI gates, vault restructure, wiki lint
- Type: session
- Location: wiki/tyler/meta/session-2026-06-25-cc2908-ci-gates-vault-restructure-lint.md
- From: cc-2908 CI gates (ruff+bandit+semgrep+pip-audit+SBOM, PR #3 open); vault restructure (12 project files → tyler/{gunner-assistant,masterdb,gunnerteam}/); lint 308 pages 23 auto-fixed, soc2-roadmap stub created

## 2026-06-25 lint | Wiki health check + fixes
- Type: meta
- Location: wiki/meta/lint-report-2026-06-25.md
- Pages scanned: 308, issues found: 35, auto-fixed: 23
- Fixed: stale [[gunner/...]] in 9 moved files; 12 orphan sessions indexed; ssp-addendum backslash links; dead GunnerMasterDB-SOC2-Roadmap refs; cc2016 dead link removed
- Created: wiki/tyler/masterdb/soc2-roadmap.md stub

## 2026-06-24 lint | Wiki health check + fixes
- Type: meta
- Location: wiki/meta/lint-report-2026-06-24.md
- Pages scanned: 304, real issues: 18 (371 raw dead links filtered to ~8 genuine; 264 raw orphans mostly path-style false positives)
- Fixed: `[[hot.md]]`/`[[log.md]]` → `[[hot]]`/`[[log]]` in index.md; dead `[[tyler/masterdb/soc2-roadmap]]` link → b1 evidence page; b1 evidence doc updated to reflect prod completion (p16 live, GUC retired); masterdb-developer-handoff head updated k12→p16; tyler/hot "What's Live v319" → v359 summary; 3 frontmatter gaps patched.
- Also: DumpsterSwapView `itemId → _` Swift warning fixed (`8d918bc`).

## 2026-06-24 save | Session — B1 prod provisioning, photo OOM fixes, dumpster email, Firebase
- Type: session
- Location: wiki/tyler/meta/session-2026-06-24-cc2136-2700-b1-bugfixes-firebase.md
- From: ~30 cc-prompts across masterdb B1, iOS photo bugs, dumpster email feature, Crashlytics
- Key insight: Aurora PG 17 rds_superuser cannot ALTER ROLE SET for custom GUCs — role-scoped RLS policies (p16) are the correct replacement; masterdb migrate Lambda was hitting dev cluster, not prod (two-cluster topology finding).

## 2026-06-22 ingest | B1 SOC 2 CC6 Least-Privilege DB Roles evidence doc
- Source: cc-2142 `gunnerteam_app` grant audit + B1 control evidence (pasted)
- Summary: [[gunnerteam/b1-soc2-cc6-least-privilege-db-roles]]
- Pages created: [[gunnerteam/b1-soc2-cc6-least-privilege-db-roles]]
- Pages updated: [[gunnerteam/masterdb-developer-handoff]] (migration head g7→k12, B1 chain), [[tyler/hot]] (B1 blockers + gunner-ops direct-connect finding)
- Key insight: `gunnerteam_app` role is provisioned on dev with correct grants (k11+k12); cutover is gated on Colin adding `app` to Aurora `custom_variable_classes` for the GUC, k12 deploy (expired MFA), and password set — plus `crew_members` has no FORCE RLS (pre-existing gap, tracked for remediation).

## [2026-06-22] save | tyler | Session cc-2133–2135 + VOIP ingest
- Type: session
- Location: wiki/tyler/meta/session-2026-06-22-cc2133-2135-hygiene-key-voip.md
- From: conversation covering the cc-2133 account hygiene sweep close-out, cc-2134 `gunner-fleet-worker-dev` key remediation, cc-2135 A4 fieldportal diagnostic, and the VOIP/softphone research ingest.
- Indexed in [[tyler/index]]; hot cache updated. Committed this `/save` (vault commits only on explicit `/save`).

## [2026-06-22] ingest | In-App Softphone — VOIP Platform Research & Recommendation
- Source: `~/Documents/Claude/Projects/Gunner Team App/VOIP-Platform-Research.md` (prepared 2026-06-22).
- Summary: [[gunnerteam/voip-softphone-research]] — platform research for an in-app voice + SMS/MMS second line on the GunnerTeam iOS app (Lambda + Postgres backend), multi-tenant/white-label, ~36 users CT/NJ/OH; a **Dialpad replacement**.
- Pages created: [[gunnerteam/voip-softphone-research]]
- Pages updated: [[gunnerteam/dialpad-hubspot-integration]] (cross-link + evolution note), [[gunnerteam/overview]] (index + `updated`), [[tyler/hot]] (ingest note + cache date).
- Key insight: **Telnyx recommended** (Twilio runner-up); **Amazon Connect disqualified** — AWS verbatim "one phone number shared for voice and SMS isn't supported", forcing two numbers/rep, which breaks the single-business-card-number requirement. Biggest eng risk is the iOS CallKit/PushKit/WebRTC audio handoff, not the telephony.
- Evolution flag: supersedes/broadens the earlier "don't replace Dialpad, just fix logging" stance in [[gunnerteam/dialpad-hubspot-integration]] — the webhook bridge is the near-term logging fix; the softphone is the strategic full replacement. Compliance edge: **CT all-party recording consent** (disclosure on every recorded call) + per-tenant 10DLC lead time (1–3 wks) gating white-label. Research, not a committed decision; not legal advice (run compliance past counsel).
- Vault uncommitted (writes only; commit on explicit `/save`).

## [2026-06-20] save | Session cc-2135: A4 close-out diagnostic — what we forward vs what comes back
- Type: temporary GunnerTeam-side diagnostic (deploy temp → reproduce → read → revert). File `gunnerteam-api/src/routes/fieldportal.js`. **Net-zero code** (added then removed). `--profile mfa`.
- Phase 1-2: added temp `console.log('[cc-2135] …')` on `/jobs` (combined role+email+count, `data.projects`) and `/jobs/bundle` (role+email right after `resolveTargetEmail`; count `jobs.length` on the full-rebuild = cache-miss path). Deployed **v347** (alias `live`).
- Phase 3: Tyler signed into the iOS app **as the test account** and opened Jobs (app showed "no jobs are assigned to you" after the skeleton). Logs (`filter-pattern '"[cc-2135]"'`, last 30 min):
  - `[cc-2135] bundle gtRole=user forwardedEmail=admin@gunnerroofing.com`
  - `[cc-2135] jobs gtRole=user forwardedEmail=admin@gunnerroofing.com projectsReturned=0` (×N, every refresh)
- Phase 4 (decision tree): **`gtRole=user`** (not admin), **`forwardedEmail=admin@gunnerroofing.com`** = the test account's **own** email (no `userEmail` query param → `resolveTargetEmail` returns `req.user.email`; no privilege escalation, no wrong identity), **`projectsReturned=0`**. → **NOT a GunnerTeam bug.** We forward the correct scoped email at `user` role; Colin correctly returns 0 for that email (membership-scoped, unknown/unassigned email → empty by design). The app's "no jobs assigned" is the correct render of 0. The earlier "seeing all jobs" symptom is **no longer reproducible** — consistent with stale client cache (JobPreloadStore) before Colin's scoping went live / before a fresh fetch. ⚠️ If `admin@gunnerroofing.com` is *supposed* to have assignments, that's a Colin-side FP-membership question, not ours.
- Phase 5: deleted the 3 `[cc-2135]` blocks (file byte-identical to pre-task, tag back to original); `grep` clean, `node --check` + require-load pass; redeployed **v348** (alias `live` → 348; v348 code == cc-2201 v346). No temp logging left in prod (cc-1624 lesson).

## [2026-06-20] save | Session cc-2134: Remediate the `gunner-fleet-worker-dev` static access key (CC6.1)
- Type: IAM remediation (reversible-first). `--profile mfa`, account `980921733684`. The one GunnerTeam-tagged item from the cc-2133 sweep.
- Phase 0 (read-only) — confirmed abandoned: key `AKIA…GP2P` created 2026-05-04, **last used 2026-05-05** (S3, us-east-2; ~7 wks idle); **zero CloudTrail events in 90d** (us-east-1 + us-east-2 — and its only actions are S3 data-plane anyway, so the authoritative signal is last-used + repo-clean). Repo grep across `~/Dev/GunnerTeam` for the key id / `AWS_ACCESS_KEY` / `accessKeyId` / `secretAccessKey` = **clean** (app holds no static creds → runs on the Lambda execution role). Blast radius is narrow: one managed policy `gunner-fleet-worker-dev-policy` = `s3:PutObject/GetObject/DeleteObject` on `arn:aws:s3:::gunner-fleet-dev/*` only (no inline, no groups). `gunner-fleet-dev` is the app's inspection-photo bucket (`s3_bucket` tf var) — reached via the Lambda role, not this key.
- Phase 1 — **deactivated** the key: `aws iam update-access-key … --status Inactive`. Verified `list-access-keys` → Status **Inactive**. App unaffected: `https://api.team.gunnerroofing.com/health` → **200** (deactivation touched nothing the app uses).
- Phase 2 — **deliberately NOT run this session**: the prompt mandates a ~1-week soak after deactivation (reversible kill — reactivate instantly if anything unexpected breaks). ⏳ **~2026-06-27:** if no new `AccessDenied`/auth-fail tied to the key, `aws iam delete-access-key --user-name gunner-fleet-worker-dev --access-key-id <full-id>` (get it via `list-access-keys`) → detach `gunner-fleet-worker-dev-policy` → `aws iam delete-user --user-name gunner-fleet-worker-dev` (user has no other purpose).
- Scope discipline: the same no-static-keys standard applies to the other sweep-flagged keys, but they belong to other owners (`leonard.fuentes`→Leo, `KinesisDataStreamFabricUser`→DevOps, `gunner-content-engine`/`leads-finder-dk`→Doug) — routed, not touched.
- Report `wiki/gunnerteam/account-hygiene-sweep-2026-06-20.md` updated: the `gunner-fleet-worker-dev` row + routing line now read RESOLVING (deactivated 2026-06-20, delete after soak).

## [2026-06-20] save | Session cc-2133: Account-wide security hygiene sweep (READ-ONLY) — Gunner-Dev 980921733684
- Type: read-only AWS inventory + report. NO changes (nothing terminated/deleted/detached/modified). `--profile mfa`, all regions. Report: `wiki/gunnerteam/account-hygiene-sweep-2026-06-20.md`.
- Phase 1 EC2 (all regions): 8 instances, **all `Owner`-untagged, 0 GunnerTeam** (EC2 chain confirmed retired). NEW since cc-2122: `gunner-autolabel` (g5.xlarge GPU, us-east-1, running — cost flag) + `gunner-leads-bastion`. Rest = the cc-2122 dev-portal boxes (DevOps) + wl-companycam-dev-bastion + db-tunnel (Colin/DevOps).
- Phase 2 IAM (credential report): **8 users, all with active static keys; only `tyler-cli` has MFA**. HIGH: `leonard.fuentes@…` (human, console + static key, no MFA → Leo); **root MFA=false**. Service-key users route to owners (Doug: content-engine/leads-finder-dk; Colin: wl-companycam-app-dev; DevOps: KinesisDataStreamFabricUser). Only possibly-GunnerTeam item: `gunner-fleet-worker-dev` (static key — verify ownership, migrate to role/rotate).
- Phase 3 Lambda Function URLs (all regions): **8, all `AuthType=NONE`, 0 GunnerTeam** (ours deleted cc-2121). `permit-poc-live` (the known POC, HIGH); `hubspot-dialpad-dev`/`-webhook`/`dialpad-hubspot-sync` (public webhooks — verify HMAC, IT/DevOps); 4× `wl-companycam-*` (Colin, Lambda Web Adapter web app, NONE by design).
- Phase 4 IAM roles: 92 total; `AdministratorAccess` only on the expected `AWSReservedSSO_AdministratorAccess_…` + `OrganizationAccountAccessRole`; **no app/Lambda exec role with admin, no inline `*:*`** anywhere. Clean.
- Phase 5 network/storage: **account-level S3 PAB NOT set** (per-bucket only, cc-2109/2112). World-open SGs (all dev-gunner/wl-cc VPCs, **none in GunnerTeam's pinned prod VPC**): 5432 `wl-companycam-rds-dev` (HIGH, Colin), 6379 `redis-sg-dev` (HIGH, DevOps), SSH-22 on `dev-gunner-vpc-generalSG`/`gunnerFronendDevEc2`/`launch-wizard-1`/`-2`/`default` (HIGH), + 4 SGs with `0.0.0.0/0` null-port rules to verify (incl. `dev-gunner-auroraPgDb-rds-group`).
- Outcome: **GunnerTeam's own surface is clean** (no GunnerTeam EC2, our Function URL gone, Lambda role least-priv, buckets per-bucket-PAB'd). Findings tagged owner + severity + recommended action (recommend-only). Share with Colin to dedupe against his §C-6 sweep. Counts: 8 public Function URLs, 8 IAM users w/ keys, 8 untagged EC2.

## [2026-06-21] ingest | colin | GunnerCam knowledge base — 28 notes into wiki/colin/
- Type: ingest + synthesis (multi-agent). Owner: colin.
- Distilled one month of Codex + Claude Code build sessions (2026-05-21 → 2026-06-21, 266 sessions → 1,521 nuggets) into 28 GunnerCam reference notes.
- Location: `wiki/colin/` (+ `index.md`, `hot.md`, `overview.md` refreshed). Secrets scrubbed; no raw transcripts copied here.
- Team integration points: outbound external API consumed by GunnerTeam iOS ([[colin/external-api-integration]]); shared `gunner-masterdb` core with gunner-ops ([[colin/masterdb-sync]]).
- Source: personal `claude-obsidian` vault `wiki/wl-companycam/` (full session catalog + transcripts kept local, not synced here).

## [2026-06-21] save | Session cc-2201: kill sparse cold-path apigw-5xx (DB pool idles out between keep-warm pings) — v346
- Type: backend perf/reliability fix + deploy. Commit `665fdc9`. Lambda **v346** live. Rollback v344.
- Phase 0 GATE (3-day Logs Insights, `/aws/lambda/gunnerteam-dev-api`): CONFIRMED the predicted root cause — 5xx dominated by `[timing] db.connect failed ms≈5005 error=Connection terminated due to connection timeout` → `POST /validate 503 ms≈5007`, `auth.resolveUser`/`forgot-password` 500s, and cold scheduled-task (`Overdue inspection`/`Maintenance check`) failures. The `ms` cluster at **~5000 = the env `DB_CONNECT_TIMEOUT_MS=5000`** (env overrides the 3000 code default). Not a route/logic error → proceeded. (The high-ms `location-ping forward failed timeoutMs=10000` lines are swallowed FP-upstream best-effort timeouts, unrelated to apigw-5xx.)
- Root cause: keep_warm rule (eventbridge.tf, rate(5min), {keepWarm:true}) kept the CONTAINER alive but the keepWarm branch returned before any DB use, and `db.js idleTimeoutMillis` was 30s → the pooled RDS-Proxy connection died ~30s after each real request and was never refreshed by the ping → every post-idle request re-borrowed against the connect budget and occasionally blew it → 500/503.
- Fix (db.js): `idleTimeoutMillis` → `intEnv('DB_IDLE_TIMEOUT_MS', 360000)` so the warmed connection outlives the 5-min ping; `connectionTimeoutMillis` default → `8000` for genuinely-cold borrows (RDS-Proxy borrow + TLS can exceed the old budget). `query_timeout`/`statement_timeout` left at 3000 — slow QUERIES still fail fast. (lambda.js): the `keepWarm` branch now pre-warms `await loadSecrets()` + `pool.query('SELECT 1')` inside a best-effort try/catch (a warm-up failure must not fail the ping) so each ping refreshes a live pooled connection the next real request reuses.
- Env-override handling (Phase 0 flagged it): `DB_CONNECT_TIMEOUT_MS` was set in SSM to 5000 (env wins over `intEnv` default) → `aws ssm put-parameter /gunnerteam/dev/DB_CONNECT_TIMEOUT_MS 8000` (String, v2) + `terraform apply -target=aws_lambda_function.api` (1 change). The data source re-reads SSM → env now 8000. `DB_IDLE_TIMEOUT_MS` has no env override → the 360000 code default applies.
- Deploy: SSM bump → targeted tf apply (env) → S3 code deploy → publish **v346** → alias live (rollback v344). Verified: live env `DB_CONNECT_TIMEOUT_MS=8000`; keepWarm invoke → `{statusCode:200, body:'warm'}` with **0** `[keepWarm] pre-warm failed` (the SELECT 1 succeeded); /health 200; migration probe ok:true; **0** connect-timeout/`db.connect failed` in logs post-deploy. No proxy-pin concern (SELECT 1 is autocommit, returns to pool; just an idle keep-alive, not a SET-LOCAL pin).
- ⏳ PENDING (ongoing verification per Phase 3): watch `gunnerteam-dev-apigw-5xx` + `gunnerteam-dev-lambda-errors` for 24h (target zero new datapoints) and re-run the Phase 0 query tomorrow to confirm no new `status=5` lines.

## [2026-06-20] save | iOS: migrate reverseGeocode off deprecated CLGeocoder → MapKit
- Type: iOS only — NO deploy (Lambda stays v344). Commit `aae8044` on `main`. (Ad-hoc follow-up; user surfaced the 2 warnings via an Xcode screenshot.)
- `CLGeocoder` + `reverseGeocodeLocation` were deprecated in iOS 26 — the 2 standing `PMJobViews.swift` warnings. Min deployment target is **iOS 26.0**, so swapped cleanly (no availability guards) to MapKit `MKReverseGeocodingRequest(location:)` → `(try? await request.mapItems)?.first` → `mapItem.address?.fullAddress ?? .shortAddress`. The address String is extracted BEFORE the `MainActor.run` hop because `MKMapItem` is not Sendable. Verified the iOS-26 API by web-search/Apple docs before writing (didn't invent it).
- Verify: `xcodebuild build -scheme GunnerTeam` → **BUILD SUCCEEDED, warning-clean** (the project's 2 issues → 0). The iOS app build now has no deprecation warnings.

## [2026-06-20] save | Session cc-1700: iOS live password-requirements checker (invite + reset)
- Type: iOS only — NO deploy (Lambda stays v344). Commit `ef70a58` on `main`.
- Goal: real-time requirement checklist so users see the rules and never submit a password the backend rejects; single source of truth mirroring `gunnerteam-api/src/routes/auth.js validatePasswordPolicy()`.
- Verified the policy 1:1 against auth.js (lines 46-58): `≥12`, `/[A-Z]/`, `/[a-z]/`, `/[0-9]/`, `/[^A-Za-z0-9]/` → the Swift `PasswordPolicy.rules` regexes match exactly.
- New `GunnerForms/GunnerTeam/Auth/PasswordPolicy.swift`: `PasswordRule`/`PasswordPolicy` (rules + `isValid`) + `PasswordRequirementsChecklist` view (each rule row flips ✓green when met; optional "Passwords match" row). Fixed a markdown-corrupted `spacing: 😎` → `spacing: 8` from the prompt. White-label clean: system semantic colors only (.green/.secondary/.primary), `.appCaption`, no `Color(hex:)`/per-view palette/brand strings. (`.appCaption` confirmed to exist — used in ResetPasswordView.)
- Wired into `AcceptInviteView.swift` + `ResetPasswordView.swift`: checklist inserted after the form card, before the error block, shown `if !password.isEmpty`; `.disabled(...)` gated on `!PasswordPolicy.isValid(password) || password != confirmPassword`; the old `password.count >= 12` guards in `complete()`/`submit()` replaced with `guard PasswordPolicy.isValid(password)` (the `password == confirmPassword` match guard kept above each).
- Verify: `xcodebuild build -scheme GunnerTeam` (sim iPhone 17) → **BUILD SUCCEEDED**; PasswordPolicy.swift auto-compiled via the synchronized folder group (no pbxproj edit). Only warnings = the pre-existing CLGeocoder/reverseGeocodeLocation deprecations in PMJobViews.swift (untouched). Live UI flips are deterministic from the SwiftUI bindings (build + construction; not run interactively).
- ⚠️ Keep `PasswordPolicy.swift` in sync if `auth.js validatePasswordPolicy()` changes (it carries a comment saying so).

## [2026-06-20] save | Session cc-2132: zod input-schema validation on the write surface (CC6.1/CC7.1) — v344
- Type: backend framework + first batch + deploy. Commits `120ccbf` (code) + `3851a4f` (CLAUDE.md note). Lambda **v344** live. Rollback v343.
- Goal: replace ad-hoc `if(!field)` checks with declarative zod schemas + a `validate()` middleware so every accepted payload is type-checked, length-bounded, and consistently 400'd (field/message only, no internals) before handler logic. Defense-in-depth, not a specific gap. Framework + the security-relevant WRITE surface; read/query endpoints are a follow-on.
- Framework: `lib/validate.js` (`validate({body,query,params})` → parses+strips unknowns, 400 `{error,fields:[{path,message}]}`); `schemas/common.js` shared zod primitives (zod v4 top-level `z.uuid()`/`z.email()`; `nonEmptyStr` has NO `.trim()` so it mirrors `!field` exactly). Added `zod ^4.4.3` (declared per the standards).
- iOS-COMPAT (make-or-break, cf. cc-2125 which broke the app): each schema mirrors the CURRENTLY-ACCEPTED payload — required set = the route's prior `if`-checks (which the app already satisfies), everything else the handler reads is OPTIONAL, unknown keys stripped; ids/amounts accept `number|string`; never newly-reject a field the app sends/omits.
- Converted: forms.js (`/`, `/submit-ap`, `/submit-co`, `/submit-dumpster`, `/submit-material` — base if-checks→schemas; ALLOWED_BOARD_IDS + material switch kept); auth.js (forgot-password, reset-password, complete-invite — `validatePasswordPolicy` untouched, password schema = presence only); time.js (`/checkin` — jobId required, lat/lng optional because devices omit them; cc-2126 ccFetch preflight intact); users.js (PATCH/DELETE `/users/:id` + location-consent — **`:id` is `nonEmptyStr` NOT uuid** per the users.id-is-VARCHAR caveat, all body fields optional, membership pre-flight + AdminUserGlobalSignOut + invalidateUserCache kept); webhooks via **in-handler `safeParse` AFTER HMAC+dedup** (points `/webhook`, `/redemption-webhook`, fieldportal photo+project comment) — order unchanged, `points`=nonNegInt, envelopes optional-leaning (handlers already guard).
- Execution: built the framework + the riskiest domain (forms) myself as the exemplar, then **fanned out auth/webhooks/time/users to 4 parallel `task` subagents** (disjoint files) against that pattern + strict iOS-compat rules; each wrote its schema + wired routes + a real-payload test. Then I verified/deployed.
- Verified: **79/79 `node --test` pass** incl. real-client-payload fixtures per schema (the runnable iOS-compat proof — every converted route's real payload parses, malformed throws, unknowns stripped); check/check:logs/check:orgscope green; all 6 edited route files require-load (no missing-ref, CLAUDE.md cc-1108); HMAC confirmed before every webhook safeParse (points 86→91, redemption →202, fieldportal 88→94 / 140→146). Deployed v344: /health 200, migration probe ok:true (validation layer loads), forms+checkin unauthed→401 (requireAuth before validate), webhook bad-sig→401 (HMAC first), no validation/module errors in logs.
- Limitation (honest): live authed-200 not exercised (no Cognito RS256 token) — covered by the fixture tests + construction. CLAUDE.md updated: "new routes ship with a zod schema by default" (Input validation subsection). **Follow-on:** read/query endpoint schemas.

## [2026-06-20] save | Session cc-2131: Codify 2026-06 engineering/security standards in CLAUDE.md
- Type: doc-only — NO deploy (Lambda stays v343). Commit `ba14315`. File: `~/Dev/GunnerTeam/CLAUDE.md`.
- Purpose: make the conventions established across the hardening arc (cc-2101–2130) durable so every future Claude Code session builds to them. Caps the cc-2101–2131 block.
- Added a consolidated **"## Security & Engineering Standards (2026-06 hardening) — cc-2101–2130"** section near the top (after cc-prompt workflow), structured: Secrets (none in env; `lib/secrets.js`/`getPool`), Auth (Cognito RS256 only; deprovision = delete + AdminUserGlobalSignOut + invalidateUserCache), Tenant isolation (app-level `org_id`; RLS OFF; org-scope guard + isolation suite; pre-second-tenant role split), Database (TLS verified, never `rejectUnauthorized:false`; inline `src/migrations.js`; proxy-pin rule), CI gates (npm ci/lockfile, Semgrep + committed taint rule, SBOM, `npm audit` enforcing, log-hygiene, org-scope, isolation; declare every `@aws-sdk/*`), iOS (pinned API.session + re-pin-with-Cloudflare warning, ATS defaults, jailbreak report→enforce flag, `requiresAuth:true`), S3/IAM (PAB+encryption+TLS-only; least-privilege), Infra ownership (Terraform `gunner-ios` vs SST/Pulumi `gunner-masterdb`; never `terraform import` masterdb; mfa profile; lifecycle ignore_changes on code), Deploy (file-based routing-config, `[version]` log-stream verify, canary-before-alias for DB changes), White-label, Lambda-freeze. **References** the existing detailed sections instead of duplicating.
- **Superseded the now-wrong older rules** (the control changed across the arc): reframed the Security-rules + Multi-tenant 'raw `query()` for user data = P0 / `query()` bypasses RLS / RLS overhead exception' language → RLS is OFF (cc-2127), explicit `org_id` is the control, `query()`+`org_id` is correct/preferred, fixed the stale 'RLS still required on mutations' clause; scoped the cc-1505 env-var flow to **config/flag vars only** + a ⚠️ SUPERSEDED-for-secrets banner (secrets are runtime-fetched, never an env var / TF data source); added a file-based `--routing-config` + `[version]`-verify note to the deploy block; added a ⚠️ note to the cc-343 block (never dump `Environment.Variables`; verify via `[version]` log-stream + migration probe).
- Verify: balanced code fences (30, even), no residual contradictory phrasing (grep for 'bypasses RLS' / 'RLS is still required' / 'SecureString for secrets' → none), renders. 657 → 763 lines. Doc-only.

## [2026-06-20] save | Session cc-2130: Declare implicit @aws-sdk/client-dynamodb dependency (CC7.1/CC8.1) — v343
- Type: backend deps + deploy. Commit `b55e4ee`. Lambda **v343** live. Rollback v342.
- Goal: `idempotency.js` + `rateLimitStore.js` `require('@aws-sdk/client-dynamodb')` but it was NOT in package.json — it resolved only because the Lambda nodejs20 runtime bundles a v3 SDK. Blind spot: absent from lockfile + SBOM (cc-2101), a runtime SDK change could break it, local require of those modules failed (surfaced in cc-2128). Same fix class as cc-2123 (adding client-ssm).
- Audit (`grep -rho '@aws-sdk/[a-z-]*' src/` vs deps): **client-dynamodb was the ONLY undeclared one**; the other 6 (cognito-identity-provider / s3 / ses / ssm / textract / s3-request-presigner) are all declared. So one add, no others.
- `npm install @aws-sdk/client-dynamodb@3.1073.0` → package.json `^3.1073.0` (matches the newest declared client, client-ssm from cc-2123), lockfile pins 3.1073.0 (+5 transitive deps now locked). Now bundled in the deploy zip (deterministic, SBOM-visible) instead of relying on the runtime SDK. No src changes.
- Verify: modules load locally (rateLimitStore + idempotency + lambda.js require-load OK — the cc-2128 failure gone); npm run check + npm test (5 pass) + npm audit (high+) all green. Deployed v343. Live: /health 200, migration probe ok:true (cold-start require chain through rateLimitStore→client-dynamodb loads), **DynamoDB rate-limit path exercised end-to-end** — hammered POST /points/webhook (limiter runs before the sig check, so bad-sig requests count): 120 requests → 401, request **121 → first 429** (DynamoRateLimitStore.increment via UpdateItemCommand), 15×429 after, 0 errors. Log scan: no `Cannot find module` / DynamoDB errors. Idempotency path uses the SAME bundled client (loads at init; verified by construction + the rate-limit proof).
- Result: next CI SBOM run lists client-dynamodb; the supply-chain blind spot is closed.

## [2026-06-20] save | Session cc-2129: CI guard — org-scoping on gt_* queries (CC6.1)
- Type: CI-only — NO deploy (Lambda stays v342). Commit `6ea4b60`.
- Goal: isolation rests entirely on app-layer `org_id` filtering (no RLS/superuser backstop yet — cc-2127/2128). The real regression risk is one NEW query that forgets it. A heuristic static guard (same pattern as `check-log-hygiene.js`) that fails CI when a `gt_*` query looks unscoped. NOT a proof (cc-2128 isolation tests are the proof) — a regression tripwire.
- `scripts/check-org-scope.js` (dependency-free, multi-line aware): flags a db.js `query()` HELPER call whose inline SQL references a tenant `gt_*` table with NO `org_id` and NO `// org-scope-ok`. OK conditions: `queryWithTenant(` (never matched), `org_id` present in SQL, or the opt-out comment within the call's line span. Matches the helper only — destructured `query(` + `require('…db').query(` — and deliberately EXCLUDES `client.query(`/`pool.query(` (the hand-rolled `pool.connect()`→BEGIN→`SET LOCAL app.current_org_id` transaction blocks). Allowlist of genuinely-global tables: gt_rewards_catalog, gt_phase_templates, gt_template_sections/items, gt_achievements, gt_point_rules, gt_point_multipliers, gt_webhook_deliveries (idempotency ledger, no org_id column).
- Wired: `package.json` `check:orgscope`; `ci.yml` backend job runs it after the log-hygiene step (scripts/ stays tracked via the cc-2104 `!scripts/` gitignore exception). Negative-tested: a temp `query('SELECT * FROM gt_time_entries …')` → checker exit 1; removed → exit 0. Backend gate (check / check:logs / check:orgscope / test) all green.
- **Phase-3 reconcile — 13 helper-call hits, ALL legitimate (ZERO real findings)**, each annotated `// org-scope-ok <reason>`:
  - `lib/scheduler.js` (8): cron sweeps that run across ALL tenants (no req context), scoped by the swept row's user_id/id — incl. the 90-day `gt_location_history` retention prune.
  - `routes/fleet/index.js` (2): manager-permission checks (does the target user report to req.user.id) — relationship-scoped, not a tenant data read.
  - `routes/time.js` (2): caller's own `gt_user_profile.location_consent` by authenticated user_id (one preceded by an explicit `user_organizations` org-membership validation).
  - `routes/points.js` (1): service-key `last_used_at` touch by the id resolved+authenticated via the key_hash lookup above (which carries org_id).
- The ~30 auth.js/users.js account-deletion cascades are `client.query` inside BEGIN+SET LOCAL transactions (scoped by a validated user_id) — a separate reviewed pattern intentionally outside this heuristic's scope (excluded by the matcher, not annotated).
- Honest scope: heuristic — proves a filter is PRESENT, not that it's correct. Pair with cc-2128 for evidence; its job is to stop the silent regression.

## [2026-06-20] save | Session cc-2128: Cross-tenant isolation test suite + CI postgres job (CC6.1)
- Type: test/CI only — NO deploy (Lambda stays v342). Commit `2b83d60`.
- Goal: isolation rests on app-layer `org_id` filtering with no DB backstop (until the superuser demotion). This suite seeds TWO orgs and proves org A's context can never read org B's rows — the audit evidence for the multi-tenant control + its regression net.
- `test/isolation.test.js` (node:test), data-driven over gt_time_entries / gt_customer_photos / gt_points_ledger / gt_location_history / gt_vehicle_inspections:
  - **Query layer:** `queryWithTenant(orgA, 'SELECT ... WHERE org_id=$1', [orgA])` returns only A's seeded row, never B's (+ mirror for B; + every returned row's org_id === caller).
  - **Negative control:** an UNSCOPED `query('SELECT org_id FROM gt_time_entries')` returns BOTH orgs — proves the suite can detect a leak. Verified per Phase 3: temporarily dropped the `WHERE org_id` filter → 5 query-layer tests went red ("B row must NOT be visible to A"), then restored → 14/14 green.
  - **Handler layer (cc-2126 preflight):** pulled the final `POST /time/checkin` handler off the Express router and invoked it with a STUBBED req (req.orgId/req.user set directly — no Cognito/RS256). Field Portal stubbed via a local http server (GET /projects/okjob* → 200, else 404). Valid job → 200 + an A-scoped gt_time_entries row that `queryWithTenant(B)` cannot see; unknown/other-org job → 404 job_not_found, nothing written (fail-closed).
- Safety: `test/helpers/isolationDb.js` `assertTestDb()` REFUSES to run unless `TEST_DB=1` AND DB_HOST is localhost/127.0.0.1, and explicitly rejects any `.proxy-` endpoint — never the masterdb/RDS Proxy. Every destructive helper calls it. Bootstrap = DROP SCHEMA public CASCADE → minimal stubs for masterdb-owned base tables (organizations/users/user_organizations/gt_vehicle_inspections/audit_log) → apply the REAL production migrations → seed two orgs.
- **Extracted the `migrations` object from lambda.js → `src/migrations.js`** (verbatim, via a one-shot codemod; lambda.js now `require('./migrations')`; the on-demand `_migration` runner unchanged) so the test schema == prod schema (33 keys). Index/alter statements on un-stubbed masterdb tables are skipped on 42P01/42703 (logged).
- Test-only enablers, inert in prod: `db.js` disables TLS + reads `DB_PASSWORD` from env only under `TEST_DB=1` (prod env has no DB_PASSWORD → always falls through to SSM), + `end()` for clean pool shutdown; `secrets.js` `__setTestCache` (refuses unless TEST_DB=1, used to satisfy ccFetch's `getSecretSync('FIELD_PORTAL_API_KEY')`).
- CI: new `isolation` job (postgres:16 service container) runs `npm run test:isolation`; the `backend` job (no TEST_DB) skips the suite cleanly (`npm test` → exit 0). Verified locally against a throwaway postgresql@16 on :5433 → 14/14 pass.
- Flagged (PRE-EXISTING, not cc-2128): `@aws-sdk/client-dynamodb` is required by `idempotency.js` + `rateLimitStore.js` but is NOT in package.json — resolves from the Lambda runtime SDK in prod; a local `require` of those modules fails (surfaced when smoke-loading lambda.js). Future: extend the suite to assert the DB-level RLS backstop once Colin's superuser demotion lands.

## [2026-06-20] save | Session cc-2127: Resolve the gt_customer_photos RLS vestige (CC6.1) — v342
- Type: backend migration + deploy. Commit `304013a`. Lambda **v342** live. Rollback v341.
- Goal: `gt_customer_photos` was the ONLY RLS-enabled table (lambda.js:166, policy `gt_customer_photos_org` keyed on `current_setting('app.current_org_id')`). Inert today only because the app connects as DB superuser (bypasses RLS). The instant Colin sets the role `NOSUPERUSER`/`NOBYPASSRLS` the policy activates, and since cc-769 dropped the general `SET LOCAL app.current_org_id`, org context can be unset → reads return EMPTY. A half-built control = landmine; resolve before the demotion.
- Decision: we standardized on app-level `org_id` scoping (cc-769/1628), so DROP the RLS to match every other `gt_*` table rather than wire `SET LOCAL` (which reintroduces RDS-Proxy connection pinning). Confirmed via grep the table's only queries already filter org_id explicitly: read `SELECT cc_photo_id ... WHERE org_id=$1 AND job_id=$2` (fieldportal.js tagCustomerPhotos) + write `INSERT ... (org_id,...) VALUES ($1=req.orgId,...)` — both via queryWithTenant. So isolation survives without RLS; disabling RLS only removes a restriction (reads/writes can't break, regardless of role).
- Change: added inline migration `20260620_drop_gt_customer_photos_rls` to the `migrations` object in lambda.js: `DROP POLICY IF EXISTS gt_customer_photos_org ON gt_customer_photos` + `ALTER TABLE gt_customer_photos DISABLE ROW LEVEL SECURITY` + a self-verifying DO-block guard that RAISEs unless `pg_policies` lacks the policy AND `relrowsecurity=false` (the runner returns only per-statement {ok}, not SELECT rows, so the guard is how the prompt's DB-check is made observable). All idempotent.
- Migrations model: the `migrations` object is invoked on-demand via `aws lambda invoke --payload '{"_migration":"KEY","_secret":"..."}'` (no auto-run on deploy, no tracking table — statements are idempotent). Runner uses the cc-2124 lazy `pool.connect()`; `_secret` = `getSecretSync('MIGRATION_SECRET')`.
- Deploy v342 (rollback v341). Ran the migration → `200` with all three `ok:true` (DROP / DISABLE / verify-guard). **Verify guard passing = pg_policies no longer lists gt_customer_photos_org AND relrowsecurity=false** — the prompt's DB check, satisfied. Idempotent re-run all ok:true; /health 200. (First `--qualifier live` run 404'd = alias-resolution lag ~2s post-flip; confirmed the deployed S3 artifact contained the key, ran on `$LATEST` → ok, then live after ~45s → ok.)
- Result: GunnerTeam app code is now safe for the DB app-role superuser demotion (no RLS landmine). **Colin still owns the actual `NOSUPERUSER`/`NOBYPASSRLS` flip** in the gunner-masterdb SST stack — see GunnerTeam-TenantIsolation-Decision-2026-06-20.md.

## [2026-06-20] save | Attack-Surface Reduction — cc-2123→2126 (synthesis) + Secrets Handling Rules (update)
- Type: synthesis + canonical-page update (consolidating this conversation's cc-2123→2126 hardening block).
- Location: `wiki/gunnerteam/attack-surface-reduction-cc2123-2126.md` (new synthesis); `wiki/gunnerteam/secrets-handling-rules.md` (updated — was stale: said secrets live in the Lambda env / "Terraform owns env vars"; now reflects the secret-free env + runtime SSM fetch model).
- From: the cc-2123 (runtime secrets) → cc-2124 (DB_PASSWORD lazy pool) → cc-2125 (forms auth lockdown) → cc-2126 (jobId org preflight) conversation. The 4 per-session notes already exist in `wiki/meta/`; this adds the connective synthesis + reusable patterns and corrects the canonical secrets runbook. Lambda v335→v341.

## [2026-06-20] save | Session cc-2126: Org-ownership preflight on client jobId (time.js) (CC6.1) — v341
- Type: backend (security preflight + shared-client extraction). Commit `e607ae2`. Lambda **v341** live. Rollback v340.
- Goal: `POST /time/checkin` took `req.body.jobId` and (a) wrote it into org-scoped `gt_time_entries` AND (b) forwarded it to Field Portal — WITHOUT verifying the job belongs to `req.orgId`. Violates the CLAUDE.md rule (client-supplied resource IDs must be org-verified before writes/upstream proxy, 404 on miss; CC6.1 tenant scoping). Single-tenant today so no real cross-tenant exposure, but a clear rule violation / standard pentest finding.
- Phase 0 map: only ONE route consumes a client jobId — `/checkin` (line 109). It both writes org-scoped + forwards to FP. Checkout uses server-side `rows[0].job_id` (already org-scoped, NOT client-supplied) → no preflight needed. (forms.js/Monday IDs deliberately out of scope — integration being removed.)
- Preflight (mirrors fieldportal.js's proven org-verify): after the `if(!jobId)` 400 and BEFORE any write/proxy — `const job = await ccFetch(\`/projects/${encodeURIComponent(jobId)}\`).catch(()=>null); if(!job) return res.status(404).json({error:'job_not_found'});`. ccFetch throws on non-2xx (incl 404) → caught → 404, never leaking existence; ccFetch's default ~5s `UPSTREAM_TIMEOUT_MS` bounds it (no hang).
- Single Field-Portal client (prompt: 'keep a single client'): `ccFetch` lived in routes/fieldportal.js, un-exported, with BASE(22 uses)/apiKey(20)/upstreamFetch(19) used all over that 1781-line file. Extracted the whole client block (BASE, apiKey, upstreamTimeoutMs, upstreamFetch, ccFetch) verbatim into **`lib/fieldPortalClient.js`**; fieldportal.js now imports `{BASE, apiKey, upstreamFetch, ccFetch}` (dropped the now-dead `upstreamTimeoutMs` import) — one deletion block (lines 183-213) + one import, ~40 internal callsites unchanged. time.js imports `{ccFetch}` from the shared module. No import cycle (client → perf+secrets only). FIELD_PORTAL_API_URL is config (env); FIELD_PORTAL_API_KEY is the cc-2123 runtime secret (apiKey() stays a function).
- Deploy v341 (rollback v340). Verified: /health 200, migration probe `ok:true` (the full refactored module graph — incl. fieldportal.js importing the shared client — loads live; DB fine), unauthed `POST /time/checkin` → 401 (requireAuth intact; preflight runs only after auth), require-load smoke OK. First probe hit `/checkin` (root) → 404 = Express unmatched-route default; correct path is `/time/checkin` (time.js mounted at /time).
- Limitations (honest): authed 200(valid job)/404(bogus job) not exercised live — no Cognito RS256 token to forge. Verified by construction + parity: the preflight is byte-identical in pattern to fieldportal.js lines 582-587/636-640 and now calls the literally-same shared ccFetch. **TRADEOFF (prompt-accepted fail-closed):** check-in now requires Field Portal reachable — if FP is down, check-in returns 404 instead of the old succeed-and-fire-and-forget-push; bounded to ~5s.
- Flagged (out of scope, per prompt): the real tenant-isolation backstop = a NOSUPERUSER/NOBYPASSRLS app DB role + the RLS-vs-app-scoping decision, partly in the `gunner-masterdb` SST stack (Colin); pre-second-tenant gate, tracked separately.

## [2026-06-20] save | Session cc-2125: Lock down the unauthenticated forms routes (CC6.1/CC7.2) — v340
- Type: backend gating + iOS client auth-flag fix. Commit `9763fc7`. Lambda **v340** live. Rollback target v339.
- Goal: `POST /` (IT request) and `POST /submit-ap` had no `requireAuth`, no rate limiter, and /submit-ap had no `audit()` — anonymous callers could create Monday items / AP entries under the shared token. Every sibling forms route was already `requireAuth`'d. Cheap insurance until Monday is removed pre-white-label.
- forms.js: added a distributed `formsLimiter` (express-rate-limit + `DynamoRateLimitStore`, windowMs 60s / max 30, prefix `forms`, in-memory fallback if `RATE_LIMIT_TABLE` unset) — **default import** `const rateLimit = require('express-rate-limit')` to match the working points-webhook sibling (the prompt's named-import snippet would be undefined on older majors; v8.5.2 exports both but one convention wins). Gated both routes: `requireAuth, formsLimiter, idempotency` (requireAuth first so the limiter keys on the principal). Fixed audits: added `req` to the IT `forms.submitted` audit (was missing org/user/IP) + a new `forms.submitted` audit on /submit-ap (mirrors /submit-co). Confirmed via audit.js that `audit({req})` pulls org_id/user_id/ip from req.
- **iOS finding (supersedes the prompt's 'app unaffected' premise):** `FormSubmitExecutor` attaches the Cognito Bearer ONLY when `payload.requiresAuth` is true. `ITRequestView` (POST /) and `APFormView` (/submit-ap) both built `FormSubmitPayload(requiresAuth: false)` → gating the backend alone would 401 the app. Flipped both to `true`. **Plus a LATENT BUG:** `ChangeOrderView` (/submit-co) also had `requiresAuth: false` while /submit-co was ALREADY backend-gated → online CO submits were 401ing/dead-lettering; flipped to `true` too (risk-free — valid tokens are always accepted; aligns with the gated backend). Dumpster/Material were already `true`. All 5 forms now match their backends.
- Deploy + verify (full S3 deploy → v340, alias flipped, rollback v339). **Propagation lag (cc-2119) bit again**: first unauthed probes hit warm v339 containers (POST / → 500 Monday err, /submit-ap → 200 created a real item `12329001233`) while /submit-co 401'd (gated in both versions). Re-tested after ~75s with **empty bodies** (so stale v339 returns 400 pre-Monday, no side effect; v340 returns 401 pre-validation): both routes **401 ×3/3**, /submit-co 401, /health 200. Confirmed the deployed v340 artifact's forms.js carries `requireAuth, formsLimiter` on both routes.
- Limitations (honest): could not run a live authed create (no Cognito RS256 token to forge) → authed path verified by construction (requireAuth → unchanged handler → audit mirrors working /submit-co). iOS build NOT re-run (changes were literal `false→true` bool flips, compile-safe). **Rollout caveat:** old app installs (requiresAuth:false) will 401 on IT/AP until they update — unavoidable with backend gating, acceptable in dev.

## [2026-06-20] save | Session cc-2124: DB_PASSWORD out of the env via lazy pool init (CC6.1) — v339
- Type: backend (db.js lazy pool + targeted TF apply + careful canaried deploy). Commit `f766dbc`. Lambda **v339** live. Rollback target v337. The env is now **secret-free** (0 secrets) after cc-2123 + this.
- Goal: `DB_PASSWORD` was the last secret in the Lambda env, and the hardest — `lib/db.js` built the pg `Pool` at module-load from `process.env.DB_PASSWORD`, before any async secret fetch could run. Plus proxy-secret-drift history (SSM DB_PASSWORD must equal the RDS Proxy's Secrets Manager secret).
- db.js: replaced the module-load `new Pool({...password: process.env.DB_PASSWORD...})` with a memoized async `getPool()` that, on first call, `await getSecret('DB_PASSWORD')` (cc-2123 loader, cached per container), builds the Pool once, caches it. `connect()` routes through `await getPool()`. **The exported `pool` is kept as a backward-compatible lazy facade `{connect:()=>getPool().then(p=>p.connect()), query:(...a)=>getPool().then(p=>p.query(...a))}`** — so all ~10 direct callers (`pool.connect()`×9, `pool.query()`×1 in fleet) are UNCHANGED (prompt scoped changes to db.js + lambda-api.tf only). ssl `{ca,rejectUnauthorized:true}` (cc-2102) / timeouts / RDS-Proxy detection unchanged — only the password source + init timing move. Grep confirmed no top-level pool use (all in functions) → lazy init is safe. node --check OK.
- No drift introduced: `getSecret('DB_PASSWORD')` reads the SAME `/gunnerteam/dev/DB_PASSWORD` SSM param Terraform used to bake into the env (verified present: SecureString, 32 chars). Delivery moves env→runtime; value untouched; the SSM-vs-proxy-secret rule is unchanged.
- TF: removed the `DB_PASSWORD = data.aws_ssm_parameter.db_password.value` env line + the now-unreferenced `data "aws_ssm_parameter" "db_password"` source from `lambda-api.tf` (kept DB_HOST/PORT/NAME/USER config). Targeted plan = 0 add / 1 change / 0 destroy (only `DB_PASSWORD → null`, 26 other env vars untouched). `var.db_password` is unreferenced (pre-existing dead var) → left alone (out of file scope), flagged.
- **Careful deploy (DB path → publish + test BEFORE alias):** apply env to $LATEST → S3 deploy db.js → publish **v339** (alias still v337). **Canary on v339 via `--qualifier 339` BEFORE aliasing**: migration probe `ok:true` = lazy pool builds from the runtime-fetched password + TLS-connects + runs SQL on the NEW version while live stays safe on v337. Only then flipped alias live→v339.
- Verified live: /health 200; serving v339; migration probe via `--qualifier live` `ok:true`; **live env = 0 DB_PASSWORD + 0 secrets total**; log scan (6 min + 3 min) shows NO db.connect/password-auth/ECONNREFUSED/ETIMEDOUT/TLS/`secrets] missing` errors. Only benign `NodeVersionSupportWarning` (AWS SDK v3, node20→22) on cold starts — unrelated. No rollback.
- Future: read straight from the RDS Proxy's Secrets Manager secret to make SSM-vs-proxy drift structurally impossible (noted, not built).

## [2026-06-20] save | Session cc-2123: Secrets out of the Lambda env → runtime SSM fetch (CC6.1) — v337
- Type: backend (new lib + multi-file conversion + targeted TF apply + deploy). Commit `6919e5b`. Lambda **v337** live. Rollback target v335.
- Goal: ~17 secrets were baked into the Lambda env (exposed via GetFunctionConfiguration — the incident class). Now fetched at runtime from SSM, cached per container.
- Discovery: mapped all reads. 13 secrets read by code; 4 CompanyCam secrets had ZERO reads (dead, superseded by FIELD_PORTAL_*); `routes/assistant-stream.js` orphaned (deleted — its only consumer was the cc-2121-removed Lambda). IAM already allows `ssm:GetParametersByPath` (cc-2107). **MIGRATION_SECRET was NOT in SSM** (env came from `var.migration_secret`/tfvars) → created the `/gunnerteam/dev/MIGRATION_SECRET` SecureString param (value preserved) so the migration probe keeps working.
- `lib/secrets.js` (new): `loadSecrets()` = one `GetParametersByPath(SECRETS_PATH, WithDecryption)` per container, memoized; `getSecret()` async fail-loud; `getSecretSync()` drop-in for process.env (throws only if called before load). Added `@aws-sdk/client-ssm`.
- `lambda.js`: `await loadSecrets()` at the top of EVERY invocation (after keepWarm; covers HTTP/scheduled/SNS/migration) → the cache is always populated before any handler → `getSecretSync` is safe in all contexts (incl. scheduled email/apns). Lowest-risk design: most reads became a mechanical `process.env.X → getSecretSync('X')` (no async/signature churn); the module-load `new Anthropic` became a lazy getter; webhook express.raw()+verify ordering untouched.
- Converted: apns (APNS_KEY_CONTENT), email (RESEND, GOOGLE_CHAT), assistant (ANTHROPIC, lazy), fieldportal (FIELD_PORTAL_API_KEY + 3 webhook secrets + OPENAI + COLIN_PNL), forms (MONDAY ×2), time (FIELD_PORTAL_API_KEY ×4), points-webhook (GUNNERCAM_POINTS_WEBHOOK_TOKEN), lambda.js (MIGRATION_SECRET). Grep confirms 0 remaining `process.env.<secret>`; node --check all green.
- TF: removed 17 secret env keys + 16 data sources from `lambda-api.tf`, added `SECRETS_PATH` config; removed the now-dead `migration_secret` var + tfvars line. Targeted plan = 0 add / 1 change / 0 destroy (env: -17 secrets, +SECRETS_PATH; no code/vpc change).
- Deploy (canary): terraform apply env → S3 deploy (ships secrets.js + getSecretSync + client-ssm) → publish v337 → alias (live switches atomically; v335 stays as rollback). Verified: **migration probe `ok:true`** (loadSecrets+IAM+getSecretSync+DB — proves the whole mechanism, since one call populates the full cache), /health 200, points-webhook bad-sig → 401 (a real getSecretSync webhook path, not 500), **live alias env = 0/17 secrets + SECRETS_PATH present**. Authed paths (assistant/monday/email/colin/google-chat) verified by construction (same cache + modules load clean) — couldn't trigger without a user token.
- NOT in scope: `DB_PASSWORD` (module-load pool init + proxy-secret-drift history → cc-2124). Future: Secrets Manager w/ managed rotation is the alternative if rotation is wanted.

## [2026-06-20] save | Session cc-2122: Remove orphaned EC2-era remnants + account audit (CC6.1)
- Type: infra config cleanup + AWS account audit (no live resource change). Commit `bb2198a` (variables.tf + user_data.sh; gitignored terraform.tfvars edited locally).
- Phase 1: grep confirmed all 4 candidate vars UNREFERENCED in *.tf — `ec2_instance_type`, `ec2_key_name`, `dev_ip` (no SG ingress uses it — the ⚠️ case checked, safe), `jwt_secret`. Removed all 4 blocks from `variables.tf`.
- tfvars: removed `ec2_key_name`, `jwt_secret`, `dev_ip` lines from the gitignored `terraform.tfvars` (kept live secrets db_password/cloudflare/migration). This wiped the **last copy** of the dead HS256 secret. Removing var + tfvars line together → no "undeclared variable" warning.
- Phase 2: deleted stray `terraform/user_data.sh` (EC2 bootstrap, no TF refs); `ssm-boothook.sh` was already absent.
- Phase 3 AUDIT (the substantive part): `aws ec2 describe-instances` (running/stopped). **No stray GunnerTeam EC2** — no instance keyed `gunnerteam-ec2` or named gunnerteam/gunner-forms → the EC2→Lambda migration's box was terminated, not just removed from TF. EC2 chain fully retired; no unmanaged compute holding the old JWT_SECRET.
  - ⚠️ Account-hygiene observation (NOT GunnerTeam, NOT touched): 6 EC2 in us-east-2 (+2 us-east-1). Long-lived dev boxes on key `devopsFrontend` since 2024 — `dev-gunner-salesPortalEc2`, `dev-gunner-CorpProtal-frontend`, `dev-gunner-hrPortalEc2`; plus `wl-companycam-dev-bastion` (Colin), `db-tunnel`; stopped `testindqp2-hubspot`. Flag for the relevant app owners (cost + possible userdata secrets) — own review, not GunnerTeam scope.
- Phase 4: `terraform validate` Success (only the pre-existing cosmetic cognito.tf:89 warning); `terraform plan` shows NO new changes from the removals (only the known leftover: null_resource.clear_alias_routing replace + cc-2121's assistant_stream_url output removal). Confirms variables/tfvars/scripts aren't state.

## [2026-06-20] save | Session cc-2121: Remove abandoned assistant-stream Lambda + final JWT_SECRET teardown (CC6.1/6.6) — v335
- Type: infra (targeted TF destroy + api env redeploy). Commit `befed66`. Lambda **v335** live. Resolves the cc-2118 regression; completes the JWT_SECRET teardown (cc-2118/2120/2121).
- Phase 0 gate: `get-metric-statistics` Invocations 30d for `gunnerteam-dev-assistant-stream` = `[]` (0 invocations) → abandoned confirmed. (Also: iOS uses `/assistant/chat` API-GW route, handler deleted cc-2118, broken verifyToken import, ASSISTANT_STREAM_URL unused.)
- Removed: deleted `terraform/lambda-assistant.tf` (the RESPONSE_STREAM Function URL Lambda — **authorization_type=NONE, CORS `*`**, env carried JWT_SECRET + DB creds + ANTHROPIC_API_KEY — a public unauthenticated secrets-bearing endpoint); removed `ASSISTANT_STREAM_URL` env (lambda-api.tf:200) + the now-orphaned `aws_ssm_parameter.jwt_secret` data source (lambda-api.tf:12). Confirmed blast radius first (only those two refs outside the deleted file).
- Plan/apply: full plan = `1 add / 1 change / 4 destroy` (3 assistant resources + the benign `null_resource.clear_alias_routing` replace; api in-place drops ASSISTANT_STREAM_URL; output removed). Verified the api block drops ONLY ASSISTANT_STREAM_URL (the `- JWT_SECRET` was under the assistant DESTROY block). No masterdb/cognito/rds CHANGES (refresh only). Targeted apply: **3 destroyed (fn+url+loggroup) + api in-place**. Published **v335**, alias live.
- Verify: old Function URL `https://xzmqry2…lambda-url…` → **403 (dead)**; /health 200; **/assistant/chat → 401** (the API-GW assistant route on the main Lambda is alive + auth-gated, NOT 404); live alias env free of ASSISTANT_STREAM_URL + JWT_SECRET. Deleted the dead **`/gunnerteam/dev/JWT_SECRET` SSM param** (ParameterNotFound confirms; nothing references it).
- Notes: targeted apply left the orphaned `assistant_stream_url` output + the pre-existing `null_resource.clear_alias_routing` drift in state — both clear on the next full reconcile (consistent with cc-2115/2119). OUT OF SCOPE (flagged): `var.jwt_secret`→`terraform.tfvars`→`user_data.sh` EC2 chain (separate secret value; likely dead post-migration; own prompt).

## [2026-06-20] ingest | SOC 2 Technical Summary + Security & Compliance Roadmap
- Sources: `~/Documents/Claude/Projects/Gunner Team App/GunnerTeam-SOC2-Technical-Summary-2026-06-20.md` + `security-compliance-roadmap.md` (copied verbatim).
- Pages created: [[gunnerteam/soc2-technical-summary]] (current SOC 2 control posture by TSC — the cc-21xx work), [[gunnerteam/security-compliance-roadmap]] (org-wide program roadmap: CIS/NIST/SOC 2/ISO/CMMC frameworks, SaaS tenant-isolation, Hexnode→Jamf, Google Workspace tiers, SIEM, CISO cert track).
- Pages updated: [[index]] (gunnerteam SOC 2 list), [[gunnerteam/overview]] (Related), [[gunnerteam/soc2-accomplishments-2026-06]] (related backlink), [[tyler/ciso-track/roadmap]] (Related — §8 cert sequence + restores a `[!gap]`-flagged page's pointer).
- Key insight: control *coverage* is strong + largely verified-live; the single gating SOC 2 item is the dev/prod split (one non-isolated dev account, one PM's real pilot data, no external-customer data) — environment isolation + AWS-native detection + tested DR all resolve at cutover. Roadmap pricing/timeline figures are flagged estimates (verify before budgeting).

## [2026-06-20] save | Session cc-2120: Remove dead JWT_SECRET + jsonwebtoken (CC6.1) — v334 + cc-2118 regression found
- Type: backend (dep + targeted TF apply + deploy). Commit `3431edf`. Lambda **v334** live.
- Phase 0: grep src = 0 for JWT_SECRET/jsonwebtoken/jwt.sign/signToken (cc-2118 left it clean). Confirmed dead in code.
- Phase 1: `npm uninstall jsonwebtoken` → `npm run check` (exit 0) + `npm test` (4 pass; DB-integration tests skip cleanly w/o DB_HOST). package.json + lock updated.
- Phase 2: removed `JWT_SECRET = data.aws_ssm_parameter.jwt_secret.value` from `lambda-api.tf` env. Targeted `terraform plan -target=aws_lambda_function.api` = **0 add / 1 change / 0 destroy**, diff = ONLY `- "JWT_SECRET" -> null` (no code change — ignore_changes; assistant untouched). Applied.
- Deploy: S3 block (ships the jsonwebtoken removal) + publish + alias → **v334**. Verified: LIVE alias `GetFunctionConfiguration` no longer exposes JWT_SECRET (the incident-class CC6.1 win), /health 200, v334 serving, rest of env intact (DB_HOST present). Existing auth unaffected (verifyCognitoToken unchanged; nothing read JWT_SECRET).
- **DEVIATION from prompt Phase 2/3 (delete data source + SSM param) — INFEASIBLE as written:** `data.aws_ssm_parameter.jwt_secret` (lambda-api.tf:12) is ALSO referenced by `lambda-assistant.tf:34`. Deleting the data source breaks TF; deleting the SSM param breaks that data source. So KEPT both. There's also a separate `var.jwt_secret`→`terraform.tfvars`→`user_data.sh` (EC2 user-data) chain — untouched.
- **⚠️ FOUND a cc-2118 regression:** cc-2118 deleted `src/assistant-stream.js` as "dead", but it's the **handler of the `gunnerteam-dev-assistant-stream` Function URL Lambda** (lambda-assistant.tf). That Lambda is abandoned (no invocations since ~May 15; `verifyToken` import already broken — jwt.js never exported it; iOS uses `/assistant/chat`, not the Function URL). Live Lambda runs old code (2026-06-19, still has the handler; `ignore_changes` protects it) so not live-broken, but repo lost the handler source + a future code-apply would break it. It also still carries JWT_SECRET env.
- FOLLOW-UP (recommended cc-prompt): REMOVE the abandoned `assistant-stream` Lambda entirely (lambda-assistant.tf) → then complete the JWT_SECRET teardown (data source + SSM param + the var/tfvars/user_data.sh EC2 chain). Did NOT do it here (removing a Lambda + Function URL is a separate decision/scope).

## [2026-06-20] save | Session cc-2119: Backend POST /device/integrity — lands the jailbreak signal (CC7.2) — v332
- Type: backend (deploy). Commit `01424b8` on main. Lambda **v332** live.
- Receiver for cc-2117's iOS DeviceIntegrityMonitor report (was 404ing → signal dropped). **Resolves the cc-2117 backend follow-up.**
- Phase 0 (match the contract — verified, not guessed): read the iOS client → POST `API.base + "/device/integrity"` (top-level, NOT `/auth`-prefixed like device-token), Bearer auth, body `{event, deviceModel, osVersion}`. The prompt's example used `model/os/reason` + suggested auth.js — both WRONG for this client; matched the real contract instead.
- New `routes/device.js` mounted `app.use('/device', ...)` in app.js (→ `/device/integrity`): `requireAuth → audit({action:'device.integrity_failed', req, metadata:{deviceModel:clamp64, osVersion:clamp32}}) → 204`; try/catch with status-before-json, no err.message to client, no PII.
- node --check OK; require-load OK; mount verified `/device + /integrity`.
- Deploy: full S3 block, env-var routing-config. Serving **v332** confirmed via log-stream.
- **Deploy gotcha (new durable lesson):** first post-deploy test of the NEW route 404'd — a warm **v331** container served it (alias was correctly v332/routing=null; pure propagation lag, ~confirmed via the request's `[331]` log-stream tag). After ~45s, `/device/integrity` returned **401** consistently (6/6) from `[332]`. Lesson: a brand-new route can 404 on warm old containers briefly post-deploy → wait + re-test, don't conclude failure.
- Verify: unauthed POST → **401 (route live, no more 404 → client report now received)**; v332 serving. Authed **204 + audit-row NOT run by me** — needs a valid Cognito user token (single-tester pilot creds gap, same as cc-2118); verified by construction (requireAuth is the proven 401 gate + the standard audit() helper used by 70+ callsites + correct route code). Recommend a supervised-device/token test to observe the 204 + the `device.integrity_failed` audit row.

## [2026-06-20] save | Session cc-2118: Retire legacy HS256 token end-to-end (CC6.1) — deployed v331
- Type: backend (deploy) + iOS. Commit `6ebb34e` on main. Lambda **v331** live.
- Backend (`gunnerteam-api`):
  - `routes/auth.js` complete-invite: removed `const jwtToken = signToken({...})` + `token:` from the 201 (now returns `{role, user:{...email...}}`); removed the `signToken` import (line 5) and the now-dead `orgSlug`/orgRes query (only fed the token). The handler already provisions Cognito (AdminCreateUser + permanent password), so the client signs in via Cognito next.
  - `lib/jwt.js`: deleted `signToken`/`jwt.sign`, the `jsonwebtoken` require, and the `SECRET`/`JWT_SECRET` ref. Kept `verifyCognitoToken` (now the sole export).
  - **Deleted dead `src/assistant-stream.js`** — unreferenced repo-wide (handler=src/app.js→routes/assistant), imported the never-exported HS256-era `verifyToken` (broke at load if ever required). Clean-cutover removal of the last legacy-token vestige.
  - Grep confirms NONE: signToken/jwt.sign/verifyToken/HS256/jsonwebtoken/JWT_SECRET in src → backend is Cognito-RS256-only. `node --check` OK on both edited files.
- iOS (`GunnerForms`):
  - `AcceptInviteView.complete()`: after a 201, calls `AuthManager.shared.login(email: email, password: password)` (email from the accept-invite validation) — the normal Cognito path (Amplify signIn → fetchIdToken → validate). No longer reads `token` from the response; graceful fallback to "please sign in" if auto-signin fails (Cognito propagation).
  - `AuthManager.swift`: deleted `legacyKeychainKey` (gunnerforms.jwt), `saveTokenPublic`, `legacyToken`, `validateLegacy`, the three legacy keychain helpers, and the restoreSession legacy-keychain `else` branch (now just sets isAuthenticated=false). Grep confirms no legacy refs remain (only unrelated GuidedTasksView "legacy" task-type aliases).
- Deploy: full S3 block, `--routing-config` via env var (RC) to dodge the bash-mangling gotcha. Serving **v331** confirmed via CloudWatch log-stream `[331]` tags (not get-alias).
- Verify: /health 200 (app loads ⇒ jwt.js/auth.js/middleware load ⇒ verifyCognitoToken intact ⇒ existing-user auth unaffected — /auth/validate + verifier unchanged); complete-invite(bad token)→400 "Invalid or expired invite" (route healthy, no 502/ReferenceError); iOS build SUCCEEDED.
- LIMITATION: full invite→complete→Cognito-signin→authed E2E + the `auth.invite.completed` audit-row observation NOT run by me — sending an invite needs admin Cognito creds (single-tester pilot, not held). Success-path verified by code-read + node --check + build + route health. Recommend the tester run a throwaway invite to confirm iOS auto-signin lands authed.
- Follow-up: remove `JWT_SECRET` SSM param + `lambda-api.tf` env line (separate TF change); drop `jsonwebtoken` from package.json (unused now).

## [2026-06-20] save | Session cc-2117: iOS jailbreak / tamper detection (CC6.1/6.8)
- Type: iOS feature (commit `e5eee61` on main). Build SUCCEEDED, 9 unit tests pass.
- `App/JailbreakDetector.swift` (@MainActor struct, self-contained, injectable probes): artifact paths (Cydia/Sileo/bash/sshd/apt/cydia), `cydia://`/`sileo://`/`zbra://` canOpenURL (schemes added to Info.plist LSApplicationQueriesSchemes), suspicious dylib markers via `_dyld_image_count`/`_dyld_get_image_name` (MobileSubstrate/Substrate/FridaGadget/frida/cycript/libhooker/SSLKillSwitch/TweakInject), sandbox-escape write probe to `/private/`. **`#if targetEnvironment(simulator)` → returns false** (sim shares the Mac FS where /bin/bash etc. exist → would false-positive). Normal devices also return false.
- `App/DeviceIntegrityMonitor.swift` (graduated, flag-gated): pilot/supervised = **report + audit, no block** — best-effort POST `device.integrity_failed` (no PII: hardware model via utsname + OS) over the pinned `API.session` (cc-2116) + a non-blocking orange warning banner. `JAILBREAK_ENFORCE` (default **false**) gates a full hard-block screen for the white-label/public build. `.deviceIntegrityGate()` ViewModifier wired at the app root (GunnerFormsApp), runs on launch (`.task`) + every foreground (scenePhase .active).
- Tests: `GunnerTeamTests/JailbreakDetectorTests.swift` — 9 cases (sim-never-flags-even-with-artifacts, normal-clean-not-flagged, each heuristic fires, legit-frameworks-not-flagged). Registered to the test target via the xcodeproj gem (test target uses explicit pbxproj refs, NOT synchronized groups — unlike the main app target). Build SUCCEEDED, 0 new warnings.
- HONEST SCOPE (control register): deterrent + audit signal, NOT tamper-proofing — Frida/Liberty Lite bypass in-app detection. Value = raising the bar on casual tampering + being the device-integrity control of record when MDM (Hexnode) is absent (white-label). Today on the supervised fleet Hexnode remains the real control.
- FOLLOW-UP (backend, separate cc-prompt): add `POST /device/integrity` → `audit({action:'device.integrity_failed', ...})`. iOS-only here, so the report is best-effort (swallows the 404) until the endpoint ships. Also: white-label release must flip `JAILBREAK_ENFORCE` (or wire it to remote config).

## [2026-06-20] save | Session cc-2116: iOS SPKI certificate pinning for the API hosts (CC6.7)
- Type: iOS feature (commit `4fd3ef9` on main). Build SUCCEEDED.
- New `GunnerForms/GunnerTeam/App/CertificatePinning.swift` — `PinnedSessionDelegate: NSObject, URLSessionDelegate` (nonisolated, required under `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor`). Server-trust challenge handler: scoped to the two API hosts only; standard `SecTrustEvaluateWithError` (chain+hostname) THEN SPKI-SHA256 pin check (rebuilds SPKI via RSA-2048 ASN.1 header + SecKeyCopyExternalRepresentation, CryptoKit SHA256); accepts if ANY chain cert matches, else `.cancelAuthenticationChallenge` (FAIL CLOSED); all other hosts → `.performDefaultHandling`.
- `API.session` (pinned URLSession) added to APIConfig.swift; migrated ALL ~178 `URLSession.shared` call sites → `API.session` (129 via ast_edit, 49 via Python in 16 tree-sitter-unparseable files). Delegate passes through non-API hosts, so the blanket swap is safe + Amplify/Cognito (own session) and S3 presigned are untouched.
- Pins (rotation-safe): primary = Amazon RSA 2048 M04 intermediate `G9LNNAql897egYsabashkzUCTEJkWBzgoEtk8X/678c=`; backup = Amazon Root CA 1 `++MBgDH5WGvL9Bcn5Be30cRcL0f5O+NyoXuWtQdX1aI=`. NOT the ACM leaf (rotates on renewal). Both extracted from the live chain (api-dev + api share it) and the root matches Amazon's authoritative download.
- Verify (standalone Swift vs LIVE api-dev, parameterized delegate so no app edit/revert needed): correct pins → `/health` 200; corrupt pins → ERROR -999 cancelled (fail-closed enforcement); non-pinned host (amazon.com) → 200 (pass-through). iOS build SUCCEEDED (only pre-existing CLGeocoder deprecations; 0 new warnings). Full interactive sign-in not run — covered by build + live pin-match + behavior-equivalent session swap + Amplify-own-session.
- ⚠️ cc-2110 dependency: when the Cloudflare proxy is enabled the app sees Cloudflare's chain — pins MUST be updated to Cloudflare's intermediate in the SAME release or the app hard-fails. Flagged in tyler/hot.md conventions.

## [2026-06-20] save | Session cc-2115: Pin TF backend + provider to the mfa profile (CC6.1)
- Type: infra (terraform config only, no infra change). Commit `b03eaca` (main.tf + CLAUDE.md).
- Problem: `terraform/main.tf` `backend "s3"` had no `profile` → state/lock used base `tyler-cli` creds → `GunnerRequireMFA` explicit-deny on the lock (recurring in cc-2107/2109/2111, worked around with force-unlock / `AWS_PROFILE=mfa`).
- Change: added `profile = "mfa"` to the `backend "s3"` (the prompt's one-liner) AND to the `provider "aws"` block. **The backend-only fix was insufficient** — empirically, `terraform plan` with `AWS_PROFILE` unset still threw ~60 `GunnerRequireMFA` denials on PROVIDER refresh/data-source calls (acm, apigateway, ssm, iam, ec2, cognito, etc.), because the provider also fell back to base creds. Pinning both meets the prompt's explicit verify ("plan … no GunnerRequireMFA denial") + goal ("not a per-invocation env var").
- Verify: `terraform init -reconfigure` (no env) succeeded; `terraform plan` with `AWS_PROFILE=[]` → exit 0, **0 GunnerRequireMFA denials**, clean lock. Requires a live `mfa` session (awsmfa) — else fails fast with a clear auth error (intended).
- Side observation (not acted on): current full plan = `1 add / 0 change / 1 destroy` = ONLY `null_resource.clear_alias_routing` being replaced (benign local re-trigger, no AWS infra). The cc-1635 VPC drift (9/1/4) is no longer in the plan — resolved by cc-2107/2109/2112 applies. hot.md drift line updated.
- CLAUDE.md: added a "Learned from mistakes" note that TF now pins the mfa profile (backend+provider); `AWS_PROFILE=mfa` prefixes in existing rules are now redundant (harmless).

## [2026-06-20] save | Session cc-2114: Import prod Aurora CPG to pin rds.force_ssl — ABORTED (foreign IaC ownership)
- Type: infra investigation / decision (no changes; highest-care shared-prod prompt)
- Goal: import the prod Aurora cluster parameter group into `terraform/rds-params.tf` to pin `rds.force_ssl=1` as Source=user (so a future engine-default change can't relax it).
- Phase 1 enumerate (prod CPG `gunner-masterdb-production-masterdbclusterparametergroup-bzfauowx`): family `aurora-postgresql17` (field is `DBParameterGroupFamily`); only one user-source param `idle_in_transaction_session_timeout=30000` (immediate); `rds.force_ssl`=1 Source=system (still not pinned).
- **STOP DISCOVERY: the CPG (and the whole masterdb cluster) is managed by a separate SST/Pulumi app**, not our Terraform. Evidence: CPG Description "Managed by Pulumi"; tags `sst:app=gunner-masterdb`, `sst:stage=production`, `sst:ref:password=...` on both CPG and cluster; auto-suffixed names; NOT in our terraform state. SST (sst.dev) v3 uses Pulumi under the hood.
- DECISION: **ABORT the Terraform import.** Importing an SST/Pulumi-owned shared-prod resource into our TF = dual-IaC ownership; the next `sst deploy` of `gunner-masterdb` would reconcile/fight TF and could reset Colin's params on shared prod — the exact catastrophe this prompt guards against. Did NOT create `terraform/rds-params.tf`, did NOT import (state untouched).
- Correct path: pin `rds.force_ssl=1` in the **`gunner-masterdb` SST app** (its actual owner — coordinate with Colin/DevOps). That's also where the realistic risk (someone setting it to 0) would originate, so the guard belongs there. Secondary: even absent the ownership conflict, force_ssl=1==engine-default → RDS dedup (cc-2111) would make a Source=user pin via plain modify non-trivial; SST/Pulumi asserts it declaratively in the param-group def, which is the right model.
- Durable fact recorded: the masterdb Aurora stack is a separate SST/Pulumi app (`gunner-masterdb`); never `terraform import` its cluster/CPG/proxy into gunner-ios/terraform.

## [2026-06-20] save | Session cc-2113: Codify S3 SSE — PARKED (provider-capability gate failed for 5.x)
- Type: infra investigation / decision (no code changes)
- Conditional task (codify `aws_s3_bucket_server_side_encryption_configuration` on the app buckets so SSE config gets drift detection). Gated on Phase 0: can the SSE-C block be expressed without regression?
- Phase 0 findings: current pin `~> 5.0` (5.100.0) has no `blocked_encryption_types` (confirmed: strings on binary = 0; schema check needs AWS_PROFILE=mfa for the backend). The arg was added in **aws provider 6.22.0** (2025-11-20, PR #45105) — NOT backported to 5.x — and had a perpetual-drift bug in 6.22–6.39 (issue #47320), fixed in **6.40.0** (Optional+Computed).
- DECISION: **PARK.** Codifying requires a major `~> 5.0`→`~> 6.x` provider migration (≥6.40), which carries breaking changes across the whole config (cognito/lambda/rds/vpc/cloudfront/iam/eventbridge/s3). That's disproportionate for drift-detection hardening on a control already enforced live (AES256 + SSE-C block), and is exactly the "stealth provider migration" cc-2113's own Phase-1 guard says to avoid. No edits to s3.tf or main.tf.
- Interim: AWS Config rule `s3-bucket-server-side-encryption-enabled` deferred to the group-3 Config rollout (don't build bespoke detection infra now). Revisit codification when/if the repo moves to aws ≥6.40 for other reasons — at that point it's a cheap no-functional-diff add.

## [2026-06-20] save | Session cc-2112: TLS-only policy on the audit-logs bucket (CC6.7)
- Type: infra (terraform S3, targeted apply, no Lambda code/deploy)
- File: terraform/audit-archiver.tf — added `aws_s3_bucket_policy.audit_logs` (DenyInsecureTransport) after the existing PAB. Closes the gap cc-2109 explicitly flagged on the 3rd bucket (`gunner-audit-logs-dev`, the SOC 2 audit trail). Bucket is TF-managed (real `aws_s3_bucket.audit_logs`), so refs use the resource not a data source.
- Apply: `terraform plan/apply -target=aws_s3_bucket_policy.audit_logs` (AWS_PROFILE=mfa) = **1 add / 0 change / 0 destroy**. Commit `ff07b2c`.
- Verify: http GET nonexistent key = `AccessDenied` (explicit deny) vs https GET = `NoSuchKey` → deny is transport-specific (the policy), not creds/existence. Archiver health invoke `{count:true}` on `gunnerteam-dev-audit-archiver` → 200 `{"total":842,"last24h":32,"last7d":365,...}` (DB connect fine, pipeline healthy). Archiver S3 writes are SDK/HTTPS → unaffected; Object Lock retention independent of bucket policy.
- Milestone: all 3 S3 buckets (gunner-fleet-dev, gunner-assistant-docs, gunner-audit-logs-dev) now enforce TLS-only.

## [2026-06-20] save | Session cc-2111: TF state versioning (A1.2) + Aurora rds.force_ssl (CC6.7)
- Type: infra (AWS CLI only; nothing in Terraform; no Lambda code/deploy)
- Part A — state-bucket versioning: `aws s3api get-bucket-versioning --bucket gunnerteam-terraform-state` → already `Status=Enabled`. No action; state rollback already protected.
- Part B — rds.force_ssl on the SHARED prod Aurora cluster (coordination-gated on Colin):
  - Disambiguated: TWO `masterdb` clusters exist (dev + production). Target = **production** (`gunner-masterdb-production-masterdbcluster-sczazkvf`, CPG `...bzfauowx`), confirmed by the cc-1503 `idle_in_transaction_session_timeout=30000` user param. Our dev Lambda actually uses this PROD cluster: `gunnerteam-dev-masterdb-proxy` → `TRACKED_CLUSTER ...production...`. The `gunner-masterdb-dev-*` cluster has no proxy targets (unused).
  - **Finding: force_ssl is already =1 and enforced** — Aurora PG 17.7 engine default for `rds.force_ssl` = 1 (verified via describe-engine-default-cluster-parameters), dynamic, Source=system, no override, no pending, cluster available. So the prompt's premise (it's 0; flipping risks Colin) was stale; CC6.7 already met and Colin's app is already TLS-compliant (it'd be broken otherwise). Gate effectively moot.
  - Verified our side under force_ssl=1: migration probe `pool.connect()` → `[{"ok":true}]`, /health 200.
  - Asked Tyler → chose to set explicit user-override. **RDS deduped it**: `modify-db-cluster-parameter-group ParameterValue=1 ApplyMethod=immediate` succeeds but records NO user override because 1 == engine default (param stayed Source=system across 35s; not in --source user list, unlike idle_in_transaction). Modify was a no-op; re-verified DB connect `ok:true` + /health 200 after.
  - Net: force_ssl=1 enforced (control met); cannot be pinned Source=user via CPG while value==default. Durable pinning would require Terraform managing the CPG (out of scope — not in TF). Rollback (set 0) never needed — no change took effect.
- Coordination note: Colin is a human teammate, not an IRC agent → could not confirm his SSL directly, but the already-enforced state makes his compliance a logical certainty.

## [2026-06-20] save | Session cc-2109: S3 CC6.1 baseline on app buckets — PAB + TLS-only (no SSE regression)
- Type: infra (terraform S3, targeted apply, no Lambda code/deploy)
- File: terraform/s3.tf (was a 7-line data-source-only reference; now references both app buckets + codifies the baseline).
- Buckets: `gunner-fleet-dev` (inspection photos, var.s3_bucket) + `gunner-assistant-docs` (ASSISTANT_DOCS_BUCKET SSM, new data source via existing data.aws_ssm_parameter.assistant_docs_bucket).
- Phase-1 audit (don't assume): both already had PAB (4×true) + SSE AES256 + `BlockedEncryptionTypes:[SSE-C]` (AWS Apr-2026 default), and NO bucket policy. So the only MISSING CC6.1 control was TLS-only.
- Added: `aws_s3_bucket_public_access_block` ×2 (codify already-true PAB → drift detection) + `aws_s3_bucket_policy` ×2 DenyInsecureTransport (the gap; standalone since no existing policy to merge). `terraform apply -target` = **4 add / 0 change / 0 destroy**.
- DECISION — SSE NOT codified: provider pinned `hashicorp/aws 5.100.0` (`strings` on the binary → 0 hits for `blocked_encryption_types`). `aws_s3_bucket_server_side_encryption_configuration` does a full PutBucketEncryption REPLACE → would silently drop the live SSE-C block for zero benefit (AES256 already on). "Add only what's missing" → SSE isn't missing. Re-audit post-apply confirmed SSE-C block intact on both.
- Verify (real app path, mirrors src/lib/s3.js getSignedUrl): presigned PUT /https = 200, presigned GET /https = 200+content, same GET /http = 403 AccessDenied "explicit deny in a resource-based policy"; docs bucket http GET = explicit-deny vs https = NoSuchKey (transport-specific). Probe object cleaned up.
- Gotcha: terraform S3 backend (main.tf:15, no `profile`) used base tyler-cli creds → GunnerRequireMFA explicit-deny on the state lock. Fix = run terraform with `AWS_PROFILE=mfa` env (drives backend + provider). Also: a node script in /tmp resolves modules from /tmp, not cwd → set NODE_PATH to gunnerteam-api/node_modules.
- Out-of-scope observation: the audit-logs bucket (`gunner-audit-logs-dev`, audit-archiver.tf) has PAB+SSE+lifecycle but NO TLS-only policy either — candidate follow-up (not touched; prompt scope = app buckets).

## [2026-06-20] save | Session cc-2107: IAM AdminUserGlobalSignOut grant + Cognito/logs/SES least-privilege (SOC 2 CC6.1/6.3)
- Type: infra (terraform IAM, targeted apply, no Lambda code/deploy)
- File: terraform/lambda-api.tf aws_iam_role_policy.lambda_api. Targeted `terraform apply -target` → 0 add / 1 change / 0 destroy (clean; broader VPC drift untouched).
- Required: added cognito-idp:AdminUserGlobalSignOut (cc-2103's delete-time sign-out was silently AccessDenied → refresh-token revocation no-op'd) + scoped CognitoAdmin Resource from userpool/* to userpool/us-east-2_hFVBSrcnn (= live COGNITO_USER_POOL_ID, verified). 
- Optional least-privilege (verified safe): CloudWatchLogs Resource → /aws/lambda/gunnerteam-dev-api:* and dropped logs:CreateLogGroup (group TF-managed); SES Resource → identity/gunnerroofing.com (verified domain identity).
- Verify: live policy confirmed; IAM simulate-principal-policy on the lambda role = AdminUserGlobalSignOut ALLOWED on the pool (definitive, IAM live-evaluated, no redeploy); app + platform logs land under the scoped logs policy (REQ_DONE verified). Did NOT run a throwaway-user delete (create flow is invite-email + multi-step; IAM sim is definitive). SES not live-smoked (low-risk domain scope). No prior AccessDenied in 3-day window → silent failure was latent, now pre-empted.
- Stale-lock note: cleared an abandoned 14h-old Plan state-lock via `terraform force-unlock` before planning.

## [2026-06-20] save | Session cc-2106: Deploy current main — multer/node-forge fixes live (SOC 2 CC7.1)
- Type: deploy
- Lambda v329→v330 live (deployed main 5801da0 = bf52df5/PR#6 + cc-2021 test-only). Alias routing reset to null (file-based --routing-config). No code change this session.
- Now in PROD: multer 2.2.0 (DoS highs), node-forge 1.4.0 (highs via @parse/node-apn 8.1.0). npm audit --audit-level=high --omit=dev exit 0; npm ls confirms versions.
- Runtime risk (node-apn 7→8 major) smoke-tested: cold-start logs no node-apn/node-forge load error; multer /upload parses multipart (file reached Monday add_file → bogus-item 500, past multer); node-apn 8 silent push via /time/request-location to self → devicesPinged:1, no [APNs]/runtime errors. Serving version [330] confirmed via log-stream tags (get-alias showed phantom {329:1.0} then settled to null — eventual consistency, cc-2102 pattern).
- Pushed cc-2021 to origin pre-deploy (origin/main = 5801da0).

## [2026-06-20] save | Session cc-2021: Clear Swift-6 actor-isolation warnings in test target (iOS)
- Type: fix (test-only, Swift-6 prep)
- iOS: TEST SUCCEEDED (50 tests, unchanged); commit 5801da0 on main (7 files +7 −0)
- Key: SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor → cc-2014 test classes exercising @MainActor types/Codable from XCTest's nonisolated ctx emitted 22 "main actor-isolated conformance in nonisolated context" warnings (Swift-6 errors). Marked the 6 cc-2014 test classes + OutboxTestSupport helper enum @MainActor (cc-2018/2019 classes already done). Helper @MainActor cascades to callers → all 6 need it. No prod code, no SWIFT_VERSION/isolation flip. Before 22 → after 0; no new warnings. Resolves the cc-2019 out-of-scope flag.
- Mishap (recovered): a chained bare `git stash pop` (after a failed targeted stash push) popped an UNRELATED pre-existing stash (fix/upload-monday-null-check) → UU conflicts in ChangeOrderView/ITRequestView; reverted those 2 to HEAD, stash preserved, my fix intact. Lesson: never bare `git stash pop`.

## [2026-06-20] save | Session cc-2105: Reconcile ci.yml + land PR #6 (SOC 2 CC8.1/CC7.1)
- Type: session (git + CI, no deploy)
- Pushed local main (14 commits cc-2012..cc-2020 incl. cc-2102/2103/2104) to origin; rebased PR #6 (cc-2101) onto main; squash-merged → main bf52df5; PR branch deleted
- ci.yml union: backend = npm ci → SBOM+upload → check → log-hygiene → test → `npm audit --audit-level=high` (enforcing) + parallel sast (`--config .semgrep`). cc-2101→main rebase auto-merged clean (non-overlapping additions in backend job). CI green (both jobs); post-merge local check:logs + audit exit 0.
- Deploy: NONE. multer 2.2.0 / node-forge 1.4.0 highs now in main's package-lock but v329 (live) predates the merge → reach prod on next normal deploy. FLAG: decide if a deploy of current main is wanted.
- Couldn't do the prompt's post-merge archive/registry step: cc-prompt-2101/2104 files + block-2100 registry are NOT on this machine (delivered via Cowork session, not saved to the repo) → Cowork-side housekeeping.

## [2026-06-20] save | Session cc-2020: Offline banner on every screen (iOS, supersedes cc-2016)
- Type: session (iOS)
- iOS: BUILD SUCCEEDED; commit 867bd83 on main (2 files +149 −19); no deploy
- Key: global offline banner via UIKit additionalSafeAreaInsets bridge (App/OfflineBannerBridge.swift) — one representable per tab's NavigationStack reaches the UINavigationController; banner shows below the nav bar on root AND any pushed depth, zero per-destination wiring. ContentView: removed offline from per-tab safeAreaInset (location-only kept), added .background(OfflineBannerBridge(showing:)) to all 4 tabs.
- UIKit gotchas (verified via sim harness, many iterations): (1) host must be a RAW subview of nav.view, NOT nav.addChild — a child VC floats in the content area; (2) additionalSafeAreaInsets on the nav CONTROLLER moves the bar — set per child VC via the willShow delegate; (3) CHAIN the nav delegate (forward to SwiftUI's) or NavigationStack path/pop sync breaks; (4) measure banner height ONCE + pin (live GeometryReader/viewDidLayout re-measure → feedback loops/oversize/blank).
- Verified: banner pinned below bar on 2-deep non-wired screen, back button visible, content not clipped; online → flush; toggles correct; large↔inline title handled; nav works with chained delegate.

## [2026-06-20] save | Session cc-2104: CI log-hygiene guardrail (SOC 2 CC6.1)
- Type: session (CI, no deploy)
- Commit a83a87f on main (not pushed)
- Key: scripts/check-log-hygiene.js fails CI on console.* referencing req.body/headers/secret-ish tokens (exempts .slice/.length/Len/prefix/.message/.name/.code + // log-hygiene-ok). package.json check:logs; ci.yml backend step after syntax check. Reconciled 3 false positives (password label words + HUBSPOT_API_KEY env-var name) with // log-hygiene-ok — none log secret values. scripts/ gitignored → committed via !gunnerteam-api/scripts/ exception.
- Verified: npm run check:logs clean; negative test (req.body + FOO_SECRET) fails. ci.yml on main diverges from PR #6 (sast/sbom) — future merge reconcile needed.

## [2026-06-20] save | Session cc-2103: Revoke tokens + auth cache on deprovision (SOC 2 CC6.2/6.3)
- Type: session (backend)
- Lambda: v329 live (commit c22a4a1 on main, not pushed); deployed via candidate→probe→promote
- Key: both delete routes (routes/auth.js admin delete, routes/users.js delete) now AdminUserGlobalSignOutCommand before AdminDeleteUserCommand (kills refresh tokens, non-fatal) + invalidateUserCache(email,orgId) after Cognito block (drops resolveUser cache so deleted user 401s immediately on that container). middleware/auth.js exports invalidateUserCache.
- Verified: candidate probe ok:true (lambda.js require('./app') loads edited routes + DB), /health 200, /auth/validate bogus→401, authed DB 200, serving [329] via log-stream tags, no new errors. NOT exercised: full throwaway-user delete→401-replay E2E (per-container cache can't be pinned via API Gateway; needs a real Cognito+DB user lifecycle) — logic verified by review + clean load.
- Mid-task blocker: MFA session expired during the long cc-2102/2103 work → deploy paused, resumed after user ran awsmfa. Residual: per-container cache; durable cross-container fix = shorter ID-token TTL (companion Cognito prompt).

## [2026-06-20] save | Session cc-2102: DB TLS verify RDS server cert (SOC 2 CC6.7)
- Type: session (backend, incident)
- Location: wiki/meta/session-2026-06-20-cc2102-db-tls-verify.md
- Lambda: v328 live (commits 0101da5 + 8b77c53 on main, not pushed); brief v325 outage (rolled back)
- Key: db.js ssl rejectUnauthorized false→true with ca=[...rdsBundle, ...tls.rootCertificates]. RDS PROXY presents a PUBLIC Amazon Trust Services cert (Amazon Root CA 1 / Starfield G2), not an RDS CA — RDS bundle alone failed "unable to get local issuer certificate". Captured chain via in-VPC peer-cert probe. Path ../../certs (db.js at src/lib).
- Gotchas (cost the outage): inline single-quoted --routing-config mangled by bash tool → stale {ver:1.0} weight routed 100% to wrong version (pass JSON via env var); get-alias eventual-consistency phantom weights → verify serving version via log-stream [version] tags; safe iteration via --qualifier + migration-runner DB probe before promoting alias.
- SOC 2: CC6.7 (encryption in transit, authenticated)

## [2026-06-20] fix | cc-2019: Cache assigned vehicle for offline inspections (iOS)
- Type: fix
- iOS: BUILD SUCCEEDED; 4 AssignedVehicleCacheTests green; commit d932e5a on main (5 files +116 −16)
- Key: offline inspection showed false "No Vehicle Assigned" because checkAndAdvanceCompanyVehicle treated any /fleet/my-vehicle fetch failure as no-assignment. FleetVehicle→Codable + AssignedVehicleCache (gt_assigned_vehicles, mirrors jobs.cache.data); write on every successful live fetch (login prefetchVehicle + inspection). Live response authoritative (alert ONLY when vehicle==nil); offline→seed plate from cache+advance; offline+no-cache→manual plate step (never false alert). prefillVehicle also falls back to cache.
- Flag: pre-existing Swift-6 actor-isolation warnings in cc-2014 test files (MainActor-isolated Codable/Equatable conformances used in nonisolated test ctx) — surfaced now that test runs grep warning:; warnings-not-errors under Swift 5.0; fix = @MainActor on those test classes (did so for the new AssignedVehicleCacheTests; left cc-2014 ones as out-of-scope follow-up).

## [2026-06-20] fix | cc-2018: Offline project search for forms (iOS)
- Type: fix
- iOS: BUILD SUCCEEDED; 5 OfflineProjectSearchTests green; commit 9888a35 on main (6 files +133 −1)
- Key: Dumpster/CO/Material project selection ran online /search-projects; offline → no results → selectedProject nil → submit disabled (blocked the offline dumpster-swap test, made cc-2005 outbox routing unreachable). Added ProjectResult.offlineSearch(term): shared helper filtering cached jobs (jobs.cache.data ∪ JobPreloadStore.bundle) by customer/name/address → ProjectResult(id, customer??name, address). Forms fall back to it when !isConnected; online unchanged. Fixed misleading Dumpster footer (only project is validated).

## [2026-06-20] save | cc-2017: Video capture date for gallery grouping (iOS + backend, v324)
- Type: session
- Location: wiki/meta/session-2026-06-20-cc2017-video-capture-date.md
- iOS: BUILD SUCCEEDED; backend: check + 4 tests pass; commit d8579d0 on main (3 files); deployed Lambda v324 (alias live, routing clean, smoke-invoke 200)
- Key: videos showed "Unknown Date" (confirm sent no capture date). iOS now sends capturedAt (ISO8601, from recorded file creation date, persisted at enqueue); backend forwards capturedAt || now() to Colin /files. BLOCKED on Colin /files returning createdAt (same as tag in block 1700) for the user-visible fix.
- Gotchas: after update-alias, get-alias returned stale {"323":1.0} for seconds (eventual consistency, not a stuck canary) → settled to null; npm ci before deploy to drop cc-2101 branch node_modules leftovers; v324=main lacks cc-2101 dep fixes (PR #6 unmerged)

## [2026-06-20] fix | cc-2016: Offline banner covered nav-bar back button (iOS)
- Type: fix
- iOS: BUILD SUCCEEDED; commit 32b3b60 on main (1 file +22 −13)
- Key: banner added via .safeAreaInset(edge:.top) on the TabView; per-tab NavigationStack nav bars ignore an ancestor inset → banner overlapped the bar, covering the back button on pushed views. Moved the inset INSIDE each tab's NavigationStack (shared bannerStack property) so the system nav bar renders above it. Verified with a SwiftUI simulator harness (3 variants, screenshots): inset-on-navigated-content = banner below bar + back button visible.
- Tradeoff: banner shows on tab-root screens (back button uncovered on all screens incl. pushes); not shown on deep pushes — per-destination insets (~25 points) skipped as brittle.

## [2026-06-20] fix | cc-2015: Pending Uploads relative date wrong epoch (iOS)
- Type: fix
- iOS: BUILD SUCCEEDED; commit d21f2b8 on main (1 file +1 −1)
- Key: relativeTime passed timeIntervalSinceReferenceDate (2001 epoch) to NetworkMonitor.relativeLabel which expects Unix (1970) → constant 978,307,200s = 11323-day offset on every row. Fixed to timeIntervalSince1970. Other 3 relativeLabel(since:) callers already correct.

## [2026-06-20] save | Session cc-2101: CI SAST + SBOM + enforce npm audit (SOC 2)
- Type: session
- Location: wiki/meta/session-2026-06-20-cc2101-ci-sast-sbom-audit.md
- CI-only (no Lambda); PR #6 on GunnerRoofing/gunner-ios, branch cc-2101-sast-sbom-audit, backend + sast both green
- Key: Semgrep SAST job (anonymous packs miss child_process exec rule → committed local .semgrep/command-injection.yml ERROR taint rule); CycloneDX SBOM artifact; flipped npm audit to enforcing (removed || true) after fixing 3 high — multer 2.2.0 + @parse/node-apn 8.1.0 (node-forge 1.4.0; node-apn 8.0 only breaking = drops Node 18, we run 20). Verified deliberate child_process.exec(req.query.x) probe fails sast in real CI, then reverted.
- SOC 2: CC8.1 (SDLC controls), CC7.1 (vuln detection)

## [2026-06-20] fix | Redundant await on synchronous updateItemProgress (iOS)
- Type: fix (follow-up to cc-2012/2013/2014)
- iOS: BUILD SUCCEEDED + 41 outbox tests green; commit 51bbe56 on main (4 files +12 −12)
- Key: project uses SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor (Xcode 26) → executors are implicitly @MainActor → awaiting the synchronous @MainActor UploadOutbox.updateItemProgress never suspends → 12 "No async operations occur within await expression" warnings. Removed redundant await (runtime no-op).
- Lesson: xcodebuild verification grep must include warning:, not just error: — error-only filtering hid these through 3 sessions.

## [2026-06-20] save | Session cc-2014: Unit tests for the upload outbox (iOS)
- Type: session
- Location: wiki/meta/session-2026-06-20-cc2014-outbox-unit-tests.md
- iOS: TEST SUCCEEDED (41 tests, 0 network); commit 63ccd91 on main (14 files +935 −60); no Lambda change
- Key: Phase 6 offline — first test target. Extracted pure decision points (App/OutboxLogic.swift: recover/classify/idempotencyKey + executor statics) so invariants test without network. Covers persistence round-trip, restart recovery, resume-no-dup, idempotency stability, error classification (4xx permanent/409+5xx transient/exhaustion dead-letter/403 re-presign), finalize-once. Spot-checked a deliberate break (reverted)
- Setup gotchas: xcodeproj gem on brew Ruby only; hosted test bundle needs sim booted first (preflight Busy); new_target 5th arg = product group (nil)

## [2026-06-20] save | Session cc-2013: Activate BGProcessingTask presign window (iOS)
- Type: session
- Location: wiki/meta/session-2026-06-20-cc2013-bgtask-activate.md
- iOS: BUILD SUCCEEDED; commit 5fdfb03 on main (2 files +11 −2); no Lambda change
- Key: Phase 6 offline — registered cc-2010 BGTask. Info.plist gains `processing` UIBackgroundMode (required, else submit() throws notPermitted) + BGTaskSchedulerPermittedIdentifiers (com.gunnerroofing.outbox.presign); registerBGTask() in didFinishLaunching; scheduleBGPresignIfNeeded() on scenePhase .background (enqueue + reschedule already existed). Discretionary scheduling; foreground stays guaranteed trigger
- Note: runtime simulate-launch flow not exercised (build/wiring-verified only)

## [2026-06-20] save | Session cc-2012: Route job videos through the outbox (iOS)
- Type: session
- Location: wiki/meta/session-2026-06-20-cc2012-video-outbox.md
- iOS: BUILD SUCCEEDED; commit 2bea608 on main (4 files +193 −134); no Lambda change
- Key: Phase 2 offline — videos now use outbox + background URLSession (VideoUploadExecutor mirrors PhotoUploadExecutor); JobPhotoSessionView.submit() enqueues video like photos; removed inline uploadWithRetry/attemptSingleUpload; Pending Uploads renders video icon/title/first-frame thumb; verified no-tag confirm = parity with inline path (tag only in MiddlePhaseCameraSession/PhaseDetailView+Actions)
- Note: vault session protocol (CLAUDE.md §1/§2/§9 read-order) was skipped at start, filed retroactively; runtime QA not executed (build-verified only)

## [2026-06-19] onboard | leo | Leo onboards to gunner-brain (gunner-ops + QP + masterdb + Dialpad)
- Type: onboard / migration
- Migrated Leo's knowledge from his personal claude-obsidian vault into wiki/leo/
- Pages created: [[leo/apps/gunner-ops]], [[leo/apps/masterdb-integration]], [[leo/apps/quote-portal]], [[leo/qp/quote-wizard]], [[leo/qp/teardown]], [[leo/qp/pricing-formula]], [[leo/integrations/dialpad-hubspot]], [[leo/concepts/ops-lifecycle]]
- Pages updated: [[leo/overview]], [[leo/index]], [[leo/hot]]
- Scope: gunner-ops (in prod on masterdb, go-live ~2026-06-26), QP quote-wizard rebuild, ops↔masterdb B-lite/RLS contract, two Dialpad↔HubSpot Lambdas. Linked to canonical [[gunnerteam/masterdb-architecture]] / [[shared/vendors/dialpad]] rather than duplicating.
- Excluded: non-Gunner content (DragonScale/SEO/plugin-dev). Did not write into other sections or root index/hot.
- Flagged: ops_app DB password + JWT and the v1 asphalt-calc DB creds need rotation → Secrets Manager (values not copied).

## [2026-06-19] lint | Wiki health check
- Type: lint
- Location: wiki/meta/lint-report-2026-06-19.md
- Pages scanned: 226 | Issues: 9 | Fixed: 9 | Needs review: 0 (4 orphans were false positives — all linked from tyler/index.md)
- Fixed: v277→v294 ×2; dead links ×2; frontmatter ×5

## [2026-06-19] save | Session cc-1500–1505: Terraform infra hardening + iOS receipt fixes
- Type: session
- Location: wiki/meta/session-2026-06-19-cc1500-1505-terraform-infra-hardening.md
- Lambda: v291→v294 (3 publishes); iOS: BUILD SUCCEEDED, no new build
- Key: Lambda env drift → tf (11 keys), COMPANYCAM_API_KEY restored, NOTION_TOKEN pruned, REWARDS_ENABLED=true (dev), daily 90-day location prune (EventBridge cron), null_resource canary-routing no-op fixed, stash@{0} dropped (fully superseded), Aurora idle_in_tx 24h→30s (dynamic param, no reboot), iOS receipt phantom row + editable total

## [2026-06-18] save | Session cc-1111–1126 + cc-1400: Receipt Scanner Phase 2
- Type: session
- Location: wiki/meta/session-2026-06-18-cc1111-1126-receipt-scanner-phase2.md
- Lambda: v283→v291 (8 deploys); iOS: cc-1111–1126 + cc-1400 committed to main
- Key: 502 fix (parseAmount→num), Sales Tax + Freight lines, trailing-minus detection (ABC), dual-image best-of OCR (garbageFraction guard), cleanDescription rewrite (segment/longest), verify UI (category grouping, compact fee rows, Items vs Receipt total), Requests row icons contrast

## [2026-06-17] save | Session cc-815–842: location compliance, iOS file split, service keys
- Type: session
- Location: wiki/meta/session-2026-06-17-cc815-842-compliance-refactor-service-keys.md
- Lambda: v249→v259; iOS: cc-815–842 committed to main
- Key: location consent gate (ct/nj), permission status reporting, compliance roster (dual-auth + service key), iOS file rules sweep (18 files split/trimmed), inspection submit 500 fix (awardPoints path), service-key mint fix + rotate endpoints, omp 16.0.5 `/clear` updated, awsmfa fixed

## [2026-06-16] save | Session cc-789–815: always-on location, Monday forms, 360 gallery
- Type: session
- Location: wiki/meta/session-2026-06-16-cc789-815-location-forms-360gallery.md
- Lambda: v238 → v249; iOS: cc-789–815 committed to main; omp 15.11.8 → 16.0.5
- Key: always-on device location store (gt_location_history, fleet-locations, location-history, 90d retention); geofence auto-check-in across 20 nearest jobs; Dumpster Swap + Material Shortage Monday forms; 360 tags persist + gallery confirm + grouped review + tag pill; masterdb schema gotchas (varchar id/org_id, no role/display_name on gt_user_profile); awsmfa rewritten; confirmationDialog picker pattern

## [2026-06-15] save | Session cc-766–788: App Store hardening, 360 camera redesign, polish sprint
- Type: session
- Location: wiki/meta/session-2026-06-15-cc766-788-appstore-hardening-polish.md
- Lambda: v234 → v237; iOS: cc-766–788 all committed to main
- Key: App Store v3.0.0 build 9 (aps-environment→production, zero URL!, all prints gated); leaderboard always-on; 360 arm-before-shoot; phase complete confetti; activity lightweight route; field task chips exclude completed; governance docs filed; employee notice draft; solo-maintainer process rule finalized

## [2026-06-13] save | Session cc-608–742: Bundle Perf, Gamification Phase 2–3, iOS Polish
- Type: session
- Location: wiki/meta/session-2026-06-13-cc608-742-bundle-perf-gamification-ios-polish.md
- Lambda: v183 → v220 (38 versions)
- iOS: cc-608 through cc-742
- Key: GunnerCam bundle TCP-abort root cause confirmed (Colin's endpoints); gamification Phase 2–3 shipped; iOS UX sprint (geofence, job list, phases, points hub, check-in); wiki lint auto-fix pass (31 issues, 8 auto-fixed)

## [2026-06-11] save | cc-299–338: GunnerCam Perf Sprint, Color Tokens, Prod Infra, UX Polish
- Type: session
- Location: wiki/meta/session-2026-06-11-cc299-338-perf-polish-prod-infra.md
- From: ~40 cc-prompts — incremental sync + ETag + cursor pagination, PhotoImageCache, color token migration (AppBackground/AppSurface), prod Aurora seed via _stmts Lambda runner, pull-to-refresh, toast consolidation, haptics, accessibility 44pt + labels, password flicker fix, loadError sweep, announcement reads + urgent modal, email PII redaction, scheduler dual-push fix, Lambda v156

## [2026-06-10] save | OMP Config Fixes, Plugin Refresh, and CLAUDE.md Merge
- Type: session
- Location: wiki/meta/session-2026-06-10-omp-config-plugin-claudemd-merge.md
- From: OMP config regressions fixed (5 keys), mcp.json restored, .omp/settings.json created, terraform plugin removed, aws-serverless/context7/stripe installed, CLAUDE.md §§10-15 appended from old Gunner Vault CLAUDE.md

## [2026-06-10] save | Save Skill Workflow Test
- Type: session
- Location: wiki/meta/session-2026-06-10-save-skill-test.md
- From: Single-turn meta-session testing the /save workflow end-to-end

## [2026-06-10] session | cc-279–288 Customer Photos Debug
- Type: session
- Location: wiki/meta/session-2026-06-10-cc279-288-customer-photos-debug.md
- From: Customer photo upload debugging (PayloadTooLargeError root cause), UI polish (haptics, hit area, badge)

## [2026-06-09] update | Stale claims resolved — 4 wiki pages rewritten
- aws-environment.md: full rewrite — Lambda v127/no-EC2/no-ALB, RDS proxy, deploy commands, Terraform scope
- gunnerteam-project-structure.md: updated to cc-234, current file sizes, ~/Dev/GunnerTeam/, Lambda v127
- omp-hang-fix.md: updated to v15.10.4; powerline working, swarm removed permanently; compaction fix noted
- mac-tool-setup.md: Starship removed; OMP as primary harness; MesloLGM Nerd Font Mono; Claude Code as secondary

## [2026-06-09] lint | Wiki Health Check + Entity/Vendor fixes
- 191 pages scanned; 0 dead links, 0 frontmatter gaps, 0 empty sections
- Auto-fixed: 11 index gaps (9 session notes + 2 runbooks); 5 pages created (Colin, Leonard, Ruchir, Stripe, DocuSign)
- Stale claims flagged (20 across 10 pages) — needs human review: aws-environment, gunnerteam-project-structure, omp-hang-fix, mac-tool-setup
- Leonard confirmed = Leo (alias added); Ruchir = former contractor (departed 2026-06-09); DocuSign = active/heavily used
- Report: [[meta/lint/lint-report-2026-06-10]]

## [2026-06-08] save | iOS cc-167–233: Tab Architecture, Markup Fix, ThemeManager, Polish Sprint
- Type: session
- Location: wiki/meta/session-2026-06-08-cc167-233-ios-tab-markup-themes.md
- From: ~66 cc-prompts — PhotoMarkupEditor UIKit inset fix, 4-tab architecture, ThemeManager Gunner teal, 360 photo capture, scroll-aware nav titles, SFSafariViewController, high-alert banner, Lambda v127, OMP 15.10.4

## [2026-06-04] save | iOS cc-148–193 full-day session
- Type: session
- Location: wiki/meta/session-2026-06-04-cc148-193-ios-co-fixes.md
- From: home redesign, guided job overhaul, CO flow, section views, toolbar fixes, Lambda v119

## [2026-06-04] lint-fix | Auto-filled 14 empty sections across 6 wiki pages
- secure-coding-guide (4), performance-standards (2), omp-tasks-subagents (1), dialpad (3), hubspot (4), monday (4)

## [2026-06-04] lint | Lint Report 2026-06-04
- 331 pages, 0 wiki dead links, 0 FM gaps, 0 orphans, 25 empty sections

## [2026-06-04] save | iOS cc-148–160 session
- Type: session
- Location: wiki/meta/session-2026-06-04-cc148-160-ios-co-fixes.md
- From: cc-148–160 — field task fixes, guided view redesign, PDF CO form, leads nearby, Lambda v119

## [2026-06-03] save | OMP Update & Config Optimization
- Type: session
- Location: wiki/meta/session-2026-06-03-omp-update-config.md
- From: OMP 15.2.4→15.8.3, plugin fixes, config: memories/rewind/search_tool_bm25 enabled

## [2026-06-03] save | Wiki Lint Run — 2026-06-03
- Type: session
- Location: wiki/meta/session-2026-06-03-wiki-lint-run.md
- From: automated wiki health check — 184 pages, 0 real issues, 1 false-positive fix

## [2026-06-03] lint | Lint Report 2026-06-03
- Type: meta
- Location: wiki/meta/lint-report-2026-06-03.md
- 184 pages scanned, 0 orphans, 0 dead links, 6 empty-section pages (15 instances), 3 utility frontmatter gaps

## [2026-06-03] save | iOS Refactor: File Splits cc-126–147 + Photo/UI Fixes
- Type: session
- Location: wiki/meta/session-2026-06-03-cc126-147-ios-refactor-splits-fixes.md
- From: cc-prompts 126–147 — 5 Swift file splits, folder reorg, Fleet structural fixes, photo markup toolbar, photo viewer and orientation bugs

## [2026-06-02] save | cc-87, 89-91: Phase Workflow Data Layer + Completed Tasks View
- Type: session
- Location: wiki/meta/session-2026-06-02-cc87-89-91-phase-workflow-models.md
- From: cc-87 pending-only view+CompletedTasksSheet; cc-89 PhaseWorkflowModels.swift (data layer); cc-90 JobGuidedView+PhaseCard+GuidedJobRow routing; cc-91 PhaseDetailView+PhaseItemGridCell; wiki lint 7 auto-fixes; OMP config opus-4-8

## [2026-06-02] lint | Wiki Health Check
- Pages scanned: 180
- Issues: 1 orphan, 3 dead links, 3 frontmatter gaps, 151 empty sections, 0 stale index
- Auto-fixed: 0
- Report: wiki/meta/lint-report-2026-06-02.md

## [2026-06-02] save | cc-prompts 82–86: Guided Tasks Feature Complete + OMP 15.8.0
- Type: session
- Location: wiki/meta/session-2026-06-02-cc82-86-guided-tasks-complete.md
- From: cc-82 highAlert field+sort+badge+banner; cc-83 GuidedJobsListView+GuidedJobRow+JobsView mode toggle; cc-84 GuidedTasksView grid/list toggle+GunnerTaskGridCell; cc-86 pinned progress bar+TaskDetailSheet+uncompleteTask+isUncheckable; cc-85 in-app task creation (backend+iOS)+v108 deploy; OMP 15.8.0 update+pi-powerline-footer removal

## [2026-06-02] save | cc-prompts 76–80: Notion Workspace Build + SOC 2 Fixes
- Type: session
- Location: wiki/meta/session-2026-06-02-cc76-80-notion-workspace-soc2-fixes.md
- From: Notion workspace (8 DBs, Tasks DB, notion-sync.js + task command, gap fill from wiki audit); SOC 2 #36 CompanyCam org scope (3 queries); SOC 2 #37 fleet doc ownership + audit() (2 routes); CLAUDE.md long-term context files scaffolded; IT email Dialpad/HubSpot
## [2026-05-27] save | cc-prompts 38–45, 69–75: Fleet Performance + CompanyCam Webhooks
- Type: session
- Location: wiki/meta/session-2026-05-27-cc38-45-cc69-75-fleet-perf-webhooks.md
- From: CompanyCam webhook push fix (user_devices JOIN), assignedRole filter removed, photo.comment field mismatch; iOS myVehicleId cache+prefetch, doc upload sheet .id fix, full reload; fleet query() migration (8 calls), 11-view onAppear guard sweep, Lambda migration runner, indexes
## [2026-05-27] ingest | GunnerTeam Performance Standards
- Summary: [[gunner/gunnerteam-performance-standards]]
- Pages created: [[gunner/gunnerteam-performance-standards]]
- Pages updated: [[index]]
- Key insight: query() vs queryWithTenant is root cause of 25-30s hangs; onAppear must be guarded with hasFetched; EventBridge must target live alias; pool max must be ≥ 5
## [2026-05-27] ingest | masterdb Developer Handoff
- Summary: [[gunner/masterdb-developer-handoff]]
- Pages created: [[gunner/masterdb-developer-handoff]]
- Pages updated: [[gunner/masterdb-architecture]] (added cross-ref), [[index]]
- Key insight: masterdb API is FastAPI/Python with internal HS256 JWT (not Cognito); SST `run()` is empty so Lambda has no IaC — current head migration is `g7_fix_c3d4_schema_drift`
## [2026-05-27] save | cc-prompts 64–67: Password Policy + Cognito Email
- Location: wiki/meta/session-2026-05-27-cc64-67-password-policy-cognito-email.md
- From: validatePasswordPolicy helper, reset-password/admin-reset Cognito sync, Cognito SES branded email template, iOS hint text updated in 3 auth views from 8→12 chars
## [2026-05-27] lint | Wiki health check — 15 issues, 12 auto-fixed
- Location: wiki/meta/lint-report-2026-05-27.md
- 169 pages scanned. Fixed: 2 sessions restored to index (omp-plugins-cc51-53, cc-prompts-33-38), 2 sessions added to index (cc-57-63, cc-54-56 already there), 3 stale index entries removed (Wiki Map, canvases/main.canvas, session-2026-05-19-masterdb-migration), 4 frontmatter gaps patched (status: stable on 3 pages, updated: added to masterdb-cutover). Open: 2 orphan pages (masterdb-cutover-complete, cc-prompts-33-38 — both valid session notes)
## [2026-05-27] save | cc-prompts 57–63: Invite Registration Fix Chain
- Location: wiki/meta/session-2026-05-27-cc57-63-invite-registration-fix.md
- From: 7 sequential fixes: missing invite_tokens columns, explicit users INSERT id/timestamps, Cognito AdminCreateUser+SetUserPassword post-invite, IAM Terraform state drift, audit() orgId null on unauthenticated routes
## [2026-05-27] save | cc-prompts 54–56: Admin Delete User FK Sweep
- Location: wiki/meta/session-2026-05-27-cc54-56-admin-delete-fk-sweep.md
- From: 5-deploy iterative FK fix for POST /auth/admin-delete — users.org_id doesn't exist, queryWithTenant breaks transactions, 10 NULL-outs for secondary FKs, audit_log preserved (SOC 2), complete FK map via information_schema diagnostic route
## [2026-05-27] save | OMP Plugins Setup + cc-prompts 51–53
- Location: wiki/meta/session-2026-05-27-omp-plugins-cc51-53.md
- From: OMP 15.5.2 update, marketplace manual-clone workaround, full plugin install (semgrep/github-MCP/typescript-lsp/etc.), cc-51 InspectionCameraSession replaces UIImagePickerController, cc-52 steps race fix, cc-53 admin delete FK transaction fix + Cognito cleanup
## [2026-05-26] save | cc-prompts 39–50: Guided Tasks Camera System Rebuild
- Location: wiki/meta/session-2026-05-26-cc-prompts-39-50-guided-tasks-camera.md
- From: UIImagePickerController + GuidedCameraOverlay camera rebuild (cc-39–47), shutter positioning root cause (ConditionalContent safe-area breakage), haptics (cc-44/48), merge all branches (cc-49), CheckboxTaskSheet (cc-50), audit_log req.orgId backend fix, UIScreen.main deprecation fix
## [2026-05-26] update | cc-prompts 36–37: front camera rotation + GuidedTasksView safe area fix
- Location: wiki/meta/session-2026-05-26-cc-prompts-33-38-dual-camera-orientation.md
- From: cc-36 = `.oriented(.left)` on frontCI in compositeAndAppend; cc-37 = moved `.ignoresSafeArea` off ZStack onto heroBackground + 56pt top padding

## [2026-05-26] save | cc-prompts-33–38: Dual Camera Orientation + Glassmorphism Polish
- Type: session
- Location: wiki/meta/session-2026-05-26-cc-prompts-33-38-dual-camera-orientation.md
- From: six cc-prompts fixing dual-camera black video, landscape output, front/back pixel orientation, GunnerTaskRow glassmorphism, async auth callsite errors

## [2026-05-26] update | OMP Hang Fix runbook — updated with full 15.4.1 findings
- Type: runbook update
- Location: wiki/runbooks/omp-hang-fix.md
- From: full troubleshooting session — swarm incompatible, powerline broken on fresh install, swift-lsp recursive cleanup crash, plugins.bak recovery procedure

## [2026-05-26] save | OMP Hang Fix — Suspended Processes & Incompatible Extensions
- Type: runbook
- Location: wiki/runbooks/omp-hang-fix.md
- From: OMP 15.4.1 hang after update — root causes: suspended processes holding lock, swarm extension incompatible, extension discovery reading Claude settings

## [2026-05-26] save | cc-prompt-30: Dual-Camera AVAssetWriter Crash Fix
- Type: session
- Location: wiki/meta/session-2026-05-26-dual-camera-avassetwriter-crash-fix.md
- From: hard crash on record in dual-camera mode — startSession never called (startWriting moved writer to .writing before first buffer, making the .unknown guard always false); stopRecording teardown race fixed; isMultiCamSupported guard added to startRecording

## [2026-05-26] save | OMP Reinstall — Full Config Restoration
- Type: session
- Location: wiki/meta/session-2026-05-26-omp-reinstall.md
- From: reinstalling OMP v15.3.2 — full config.yml, mcp.json, 13 skills, 4 commands, 3 npm plugins, marketplace

## [2026-05-23] lint | Wiki health check — clean (0 real issues)
- Type: meta
- Location: wiki/meta/lint-report-2026-05-23.md
- 161 pages scanned, 0 orphans, 0 dead links, 0 frontmatter gaps; 1 known false positive carry-over

## [2026-05-22] save | GunnerTeam EOD handoff — corrected context + full backlog
- Type: session
- Location: wiki/meta/session-2026-05-22-gunnerteam-handoff.md
- From: ingesting handoff doc with overrides applied (repo path, auth, Lambda v68, scheme, cc-prompt numbering)

## [2026-05-22] save | Cognito auth debug — jwks-rsa ESM fix, Lambda env vars, login confirmed
- Type: session update
- Location: wiki/meta/session-2026-05-22-cognito-auth-api-ios.md (updated)
- From: jwks-rsa → aws-jwt-verify, COGNITO env vars missing from Lambda config, login confirmed on v68

## [2026-05-22] save | GunnerTeam Cognito Auth Migration — API + iOS
- Type: session
- Location: wiki/meta/session-2026-05-22-cognito-auth-api-ios.md
- From: cc-prompt-05 (API JWKS migration, 410 login, requireAuth), cc-prompt-06 (iOS Amplify, 53 callsites), user_devices NOT NULL fix, Lambda PC removal context, OMP settings exploration

## [2026-05-22] lint | Wiki health check — 24 issues, 10 auto-fixed
- Type: meta
- Location: wiki/meta/lint-report-2026-05-22.md
- Fixed: 7 backslash wikilinks, 2 orphans added to index, 5 frontmatter gaps
- Needs review: 10 empty sections in knowledge pages

## [2026-05-22] save | Subportal Cognito Auth + iOS Fixes Session
- Type: decision + session
- Location: wiki/gunner/subportal-cognito-auth.md + wiki/meta/session-2026-05-22-ios-fixes-repo-cleanup.md
- From: cc-prompt-04 Cognito auth full implementation, cc-26/27 iOS hero background, announcements UUID bug, gunner-ios repo cleanup, OMP config audit

## [2026-05-22] session | APNs push fixes, backlog audit, cc-29 nav revert
- Type: session
- Location: wiki/meta/session-2026-05-22-apns-backlog-fixes.md
- From: APNs stale token root cause + fix, user_devices updated_at constraint, Lambda alias deploy lesson, cc-28 backlog audit, cc-29 revert of broken nav restructure

## [2026-05-22] session | cc-26/27 hero image, announcements fixes, OMP tuning, repo cleanup
- Type: session
- Location: wiki/meta/session-2026-05-22-cc-prompt-26-27-announcements-omp.md
- From: cc-26 UIImage passthrough, cc-27 static background, announcements Post button + UUID bug, OMP full config audit, iTerm2 Nerd Fonts, repo gitignore/README

## [2026-05-22] save | OMP Tasks and Subagents — When and How to Use
- Type: concept
- Location: wiki/concepts/omp-tasks-subagents.md
- From: explaining OMP task/subagent model, agent types, when to use for GunnerTeam build; subagents bar behavior

## [2026-05-22] save | GunnerTeam Project Structure
- Type: synthesis
- Location: wiki/gunner/gunnerteam-project-structure.md
- From: explore subagent map of ~/Documents/Gunner/GunnerTeam/ — routes, Swift files, sizes, hotspots

## [2026-05-22] session | cc-prompt-25: Colin v2 API integration — field fixes + smoke test
- Type: session
- Location: wiki/meta/session-2026-05-22-cc-prompt-25-colin-v2-api.md
- From: companycam.js status validator audit (already correct), GunnerTask completedByEmail/completedAt added, smoke test vs Colin's dev API passed

## [2026-05-22] save | OMP config full schema audit + redesign
- Type: decision
- Location: wiki/meta/omp-config-full-audit-2026-05-22.md
- From: full audit of all OMP settings against settings-schema.ts; dead key removed, status bar redesigned, 9 new settings added, dark-tokyo-night theme

## [2026-05-22] session | Project folder migration — ~/Documents/Gunner/ canonical root
- Type: session
- Location: wiki/meta/session-2026-05-22-project-folder-migration.md
- From: migrating all Gunner projects from legacy Claude/Projects path; verified 6 destinations, 0 diff gaps; legacy folder preserved

## [2026-05-22] save | OMP config tuning — model roles + memory pipeline
- Type: decision
- Location: wiki/meta/omp-config-tuning-2026-05-22.md
- From: exploring OMP settings via filesystem + TUI; tuning config for multi-repo daily workflow

## [2026-05-22] session | cc-prompt-24: Three-branch iOS merge into main
- Type: session
- Location: wiki/meta/session-2026-05-22-cc-prompt-24-branch-merge.md
- From: merging feat/color-tokens + feat/guided-tasks-hero-bg + feat/typed-tasks into gunner-ios main; BUILD SUCCEEDED

## [2026-05-21] save | Chrome SafeSitesFilterBehavior — site blocking diagnosis
- Type: synthesis
- Location: wiki/runbooks/chrome-safesites-policy.md
- From: diagnosing "Your organization doesn't allow you to view this site" Chrome block message

## [2026-05-19] session | Photo comments UI v1.2+v2, job comment button, vault setup
- Created: wiki/meta/session-2026-05-19-photo-comments-ui.md
- Created: wiki/gunner/claude-session-onboarding.md
- Updated: wiki/index.md, wiki/log.md, wiki/hot.md
- 7 commits merged to main: photo comment tab separation, activity row thumbnail, border reactivity (onCommentPosted callback chain), viewer count badge, amber thumbnail badge, job comment button, inspection compression fix
- .claude/context/session/ + kb/ + prompts/ structure created in vault; CLAUDE.md updated with GunnerTeam engineering section

## [2026-05-15] lint-fix | Wiki lint fixes — C1 remainder, W2, W6, W7, C2, new pages
- C1: system-security-plan.md line 121 \| escape fixed
- C2: dashboard.md — removed broken ![[dashboard.base]] embed (Bases file never created)
- W2: session-2026-05-12-companycam-s13 added to index.md
- W6: entity wikilinks wired in it-decision-log.md (Eric Recchia, Eddie Prchal, Andrew Prchal)
- W7: Eric Recchia cross-linked in federal-market.md, gunner-forms-privacy-policy.md, hubspot-salesperson-sop.md; Eddie/Andrew cross-linked in each other's entity pages
- Created: wiki/entities/Tyler Suffern.md
- Created: wiki/concepts/soc2.md (seeded with Phase 1 audit findings + Phase 2 open items)
- Dialpad-api-reference.md and ciso-track/roadmap.md confirmed as lint false positives — no action needed

## [2026-05-15] save | Session — Compliance audit fixes, legacy EC2+ALB destroy, APNs fix
- Type: session
- Location: wiki/meta/session-2026-05-15-compliance-apns.md
- Wiki lint C1/C3/S9 fixed; compliance audit filed; PR1 (EC2/ALB destroy) applied to AWS; PR2 (maybeAuth + log retention) branch pushed; APNs #11 fixed (APNS_KEY_CONTENT from SSM), deployed Lambda v5

## [2026-05-15] save | Session — Photo comments v1+v1.1, Lambda PC, webhook refactor
- Created: wiki/meta/session-2026-05-15-photo-comments.md
- Lambda alias + provisioned concurrency (2 containers, ~$22/mo); API GW wired through alias ARN
- Photo comments v1: GET/POST proxy routes, CCPhotoComment struct, PhotoCommentsSheet, CCPhotoViewer bubble.right button
- Photo comments v1.1: verifyHmac refactor (per-event secret), photo.comment.added webhook handler, photo border indicator, PATCH/DELETE routes, edit/delete iOS UI
- Updated: wiki/vendors/companycam.md — new routes table, webhook section, iOS views
- Updated: wiki/hot.md, wiki/index.md

## [2026-05-15] save | Session — CO upload fix, Terraform branch-mismatch, login timeout investigation
- Created: wiki/meta/session-2026-05-15-co-upload-fix.md
- Root cause documented: stray `;` in Content-Disposition header dropped boardContext → wrong Monday column
- Terraform branch-mismatch gotcha documented
- Login timeout investigation state captured (debug/login-trace deployed, hypothesis: queryWithTenant hang)

## [2026-05-15] ingest | EXTERNAL_API_HANDOFF.local.md — Project Hub external API (Colin's app)
- Created: wiki/summaries/external-api-handoff.md — 7 endpoints, auth, 3-step upload, comment replies, gotchas, gap list, dev fixtures
- Updated: wiki/vendors/companycam.md — added Project Hub external API section; marked old internal CC upload bug as superseded
- Updated: wiki/index.md — new summary entry
- SECURITY: API key NOT ingested — stays in SSM as COMPANYCAM_API_KEY; source file is git-ignored

# Wiki Log

## [2026-06-19] save | session-2026-06-19-cc1630-1634-alerting-terraform-ops
- Type: session
- Location: wiki/meta/session-2026-06-19-cc1630-1634-alerting-terraform-ops.md
- From: cc-1630 (Chat alert await fix + ok_actions on all alarms, v319), cc-1631 (DB clean — closed), cc-1632 (CLAUDE.md Lambda freeze + secret rules), cc-1633 (regression probe 16/17 PASS), cc-1634 (S3 WORM to TF state, VPC reconcile doc). OMP 16.1.6.

## [2026-06-19] ingest | GunnerTeam SOC2 Accomplishments + SSP Addendum 1
- Sources: `GunnerTeam-SOC2-Accomplishments-Summary.md`, `SSP-Addendum-1-Product-Environment-Controls.md`
- Pages created: [[gunnerteam/ssp-addendum-1-product-environment]], [[gunnerteam/soc2-accomplishments-2026-06]]
- Pages updated: [[tyler/concepts/soc2]] (Phase 2 complete), [[gunnerteam/system-security-plan]] (addendum cross-ref), [[tyler/ciso-track/roadmap]] (SOC2 progress)
- Key insight: APP-01…APP-09 all implemented & verified; SSP Addendum 1 DRAFT pending sign-off by Tyler, Eric, Eddie, Andrew; Lambda fire-and-forget freeze and RDS Proxy pinning documented as operating conventions.

## [2026-06-18] save | session-2026-06-18-cc1100-1300-receipt-scanner-location-batch
- Type: session
- Location: wiki/meta/session-2026-06-18-cc1100-1300-receipt-scanner-location-batch.md
- From: receipt scanner feature (cc-1100–1110, 11 prompts), location batch + offline buffer (cc-1200–1202), address geocoding on PMLocationView (cc-1300), OMP 16.0.7. Lambda v279→v283.

## [2026-06-18] save | session-2026-06-18-wiki-lint-all-fixed
- Type: session
- Location: wiki/meta/session-2026-06-18-wiki-lint-all-fixed.md
- From: wiki lint pass — 13 issues found, all 13 fixed in same session; deploy recipe corrections from cc-867 now in aws-environment.md

## [2026-06-18] lint | Vault health check — 227 pages, 13 issues, 8 auto-fixed
- Type: lint
- Location: wiki/meta/lint-report-2026-06-18.md
- Auto-fixed: 3 dead links (tyler/index.md lint-report refs), 3 missing sessions in wiki/index.md, duplicate vendor table in tyler/index.md, stale Lambda version in wiki/hot.md
- All 13 issues resolved same session: stale versions updated, deploy recipe fixed, orphans linked, frontmatter gaps filled

## [2026-06-18] session | cc-864–871 — Lock Contention Fix, Location Ping Consent, Docs Refresh
- Type: session
- Location: wiki/meta/session-2026-06-18-cc864-871-lockfix-ping-consent.md
- Lambda: v275→v277 live; v278 pending MFA
- iOS: cc-864–871 committed to main
- From: audit_log 12-min lock root cause (NodeJsExit + stranded Proxy txn); full silent-push debug chain; /validate missing location_consent → consent=false on device; PMLocationView 90s poll + map recenter + graceful fallback; docs/gunnerteam-app-summary.md refreshed to current architecture

## 2026-05-22 | save | Session: Feature Sprint + Folder Reorg
- Type: session
- Location: wiki/meta/session-2026-05-22-feature-sprint-and-reorg.md
- From: cc-21 typed tasks (photo_single/multi, text), cc-22 hero bg, cc-23 color tokens, subportal frontend scaffold, ~/Documents/GunnerTeam → ~/Documents/Gunner/GunnerTeam reorg

## 2026-05-22 save | Schema DEFAULT Audit + Announcements Fix + masterdb Platform Ingestion
- Type: session
- Location: wiki/meta/session-2026-05-22-schema-defaults-announcements-masterdb.md
- From: cc-prompts 21-23 (announcements 500, migration cleanup, comprehensive DEFAULT audit + INSERT hardening); masterdb architecture + secure coding guide ingested

## 2026-05-21 save | GunnerTeam iOS Feature Sprint — Guided Tasks, Voice Comment, Nav Fixes
- Type: session
- Location: wiki/meta/session-2026-05-21-gunnerteam-ios-feature-sprint.md
- From: cc-prompts 14-20 — Guided Tasks feature, visual polish, voice comment SFSpeechRecognizer replacement, branch merges, nav bar flash fix

## 2026-05-21 save | Post-Cutover Stabilization — GunnerTeam API v51-v58
- Type: session
- Location: wiki/meta/session-2026-05-21-post-cutover-stabilization.md
- From: afternoon/evening session — 17 schema migrations, s3.js execFile→SDK, iOS UUID type fixes, pending inspections card refactor, explicit id/timestamp INSERTs, CLAUDE.md schema rules, Lambda v51→v58, gt_vehicles dedup

## 2026-05-19 — OMP Finalization & Branch Cleanup

- **ansi-dark theme fix:** 7 background tokens changed from ANSI `0` (black) to `""` (terminal default) — eliminates black rectangles on dark gray iTerm background
- **Git cleanup:** merged compliance PR into main, deleted 8 stale branches (local + remote), pushed main
- **Branch model documented:** `main` = v3.0 dev, `forms-quick-fix-2026-05` = production v2.x (never converge)
- **Shell aliases:** `brain` → omp, `brain2` → claude code
- **DB handoff doc:** `raw-sources/gunnerteam-db-migration-reference.md` (16K chars, full schema + migration notes)
- Created: [[meta/session-2026-05-19-omp-finalization]]
- Updated: [[hot.md]], [[index.md]]

## 2026-05-19 — OMP Professional Setup Finalization

- **Config:** theme→ansi-dark, symbolPreset→nerd, statusLine→full+powerline, memories→enabled, discoveryMode→all
- **Models:** default=sonnet-4-6:minimal, smol=sonnet-4-6:off (was opus-4-6)
- **Skills created:** obsidian-second-brain, hindsight, discovery-mode (all `alwaysApply: true` in `~/.omp/agent/skills/`)
- **Plugins confirmed:** swarm-extension, powerline-footer, obsidian-context
- Created: [[meta/session-2026-05-19-omp-professional-setup]]
- Updated: [[hot.md]]

## [2026-05-19] save | Session 2026-05-19 — OMP Plugins & Theme Setup
- Type: session
- Location: wiki/meta/session-2026-05-19-omp-plugins-themes.md
- From: conversation on installing omp plugins (powerline-footer, obsidian-context, swarm, exa) and creating custom terminal themes (ansi-dark, gruvbox-dark, dracula)

Append-only. Format: `## [YYYY-MM-DD] operation | description`

## [2026-05-14] save | TLS Cutover — EC2 recreated, ALB + ACM TLS live, api.team.gunnerroofing.com canonical
- EC2 recreated: i-0448d430b169b0ff5, EIP 3.134.224.29 preserved
- ALB live: TLS 1.3, HSTS preload-ready; Cloudflare CNAME api.team → ALB (proxied=false)
- API base URL changed: http://3.134.224.29:3000 → https://api.team.gunnerroofing.com
- main branch now canonical; feature/tls-alb and feature/gunner-assistant merged
- GH_APP_ID, GH_APP_INSTALLATION_ID, GH_APP_PRIVATE_KEY added to SSM
- SOC 2 CC6.1, CC6.7, CC7.2 controls satisfied
- Open: SSM Session Manager broken, SSH:22 still open, Cloudflare token personal, start.sh not pm2-wired
- Created: wiki/gunner/tls-cutover-2026-05-14.md

## [2026-05-14] save | SOC 2 Phase 1 — audit logging, RDS hardening, SSM secrets
- `audit_logs` table created on RDS (`migrations-audit.sql`)
- `src/lib/audit.js` — fire-and-forget audit writer
- 33 audit events wired: auth.js (13), users.js (3), announcements.js (2), fleet/index.js (15)
- `terraform/rds.tf`: `publicly_accessible = false` applied
- `terraform/iam.tf`: `ssm_params` policy added to EC2 role
- All 22 secrets migrated to SSM Parameter Store `/gunnerteam/dev/*`
- `start.sh` bootstrap script replaces `.env` — PM2 now runs `start.sh`
- `.env` deleted from `/home/app/gunnerteam-api/`
- Pages: created `meta/session-2026-05-14-soc2-phase1`; updated `gunner/gunnerteam-api-aws-migration`

## [2026-05-13] save | Session — Gunner Assistant + Branch Management
- Location: wiki/meta/session-2026-05-13-gunner-assistant-branch-mgmt.md
- Covers: RAG chatbot build + token costs, branch strategy decisions, iOS patterns (nav bar title, typing indicator, chat persistence, MarkdownUI headings), trademark update, white-label velocity note

## [2026-05-13] ingest | White Label Agenda — Full Software Suite
- Created: wiki/gunner/software-suite.md — 8 platforms, urgent/future features, white-label architecture, partner onboarding flow, systems of truth
- Created: wiki/summaries/white-label-agenda.md — source summary with Q&A and feature matrix
- Updated: wiki/index.md — two new entries

## [2026-05-13] ingest | project.assigned Webhook Receiver Spec
- Created: wiki/summaries/project-assigned-webhook-receiver-spec.md — endpoint, HMAC-SHA256 sig verification, PM filter, dedup, 3s response requirement
- Updated: wiki/vendors/companycam.md — added inbound webhook section
- Updated: wiki/index.md — added summary entry
- CRITICAL: Shared secret NOT copied to wiki — must be stored in EC2 .env as WEBHOOK_SECRET

## [2026-05-12] update | CompanyCam Feature — Session 13 continued (activity thumbnails + deep links)
- Updated: wiki/meta/session-2026-05-12-companycam-s13.md — added activity photo thumbnails section and deep link scroll pattern
- From: livePhotos(for:) cross-reference for fresh thumbnail URLs; ScrollViewReader + onAppear/onChange scroll to photo date group, comment id, file id from activity feed rows

## [2026-05-12] save | CompanyCam Feature — Session 13 (4-Tab UI, Upload Flow, QuickLook)
- Type: session
- Location: wiki/meta/session-2026-05-12-companycam-s13.md
- Updated: wiki/vendors/companycam.md — new routes table, S3 upload flow, iOS views list, activity feed notes, upload bug resolved
- From: CompanyCam 4-tab JobDetailView build, activity/comments/files tabs, presign/confirm upload, camera flip, video recording, photo grid fix, ZoomableImageView, QuickLook filename + markup fixes

## [2026-05-12] lint-fix | Full fix pass — 11 issues resolved, 2 false positives confirmed

C1: Dead wikilink in lint-report-2026-04-14.md W2 table → plain text. Lint-04-16 occurrences confirmed false positives (backtick code spans). W1: Updated index.md gunner-forms-app description to Gunner Team current state. W2: Created wiki/vendors/companycam.md — internal instance, SSO, upload bug, API proxy. W3: Updated jamf.md date; gap callout remains pending Tyler's decision confirmation. W4+W5: Confirmed false positives — CIS benchmark sections and it-decision-log are populated. S1: Created wiki/entities/Eric Recchia.md; added to index. S2: Wikilinks for Eric Recchia, Eddie Prchal, Andrew Prchal added across 10 pages (concepts/cis-ig1, concepts/incident-response, gunner/completed-projects, gunner/environment, gunner/system-security-plan, runbooks/incident-response, summaries/system-security-plan, vendors/google-workspace, vendors/knowbe4, summaries/my-notebook-gunner-roofing). S4: vendors/sendgrid.md updated (GunnerForms context, status→stable); vendors/bitdefender.md updated (JAMF/Defender relationship noted). Open: W3 (JAMF status), S4 quote-portal, S5 CC API bug tracking.

## [2026-05-12] lint | Full vault health check — 114 pages, 14 issues
1 critical (dead link in old lint reports), 5 warnings (stale index entry, missing companycam vendor page, JAMF stale, empty CIS summary sections, it-decision-log empty section), 6 suggestions. 4 issues resolved since 2026-05-07. Timestamped report at wiki/meta/lint-report-2026-05-12.md.

## [2026-05-12] update | wiki/gunner/gunner-forms-app.md — CompanyCam feature + vehicle doc bug fixes (session 12)
CompanyCam jobs integration built: JobsView, JobDetailView, JobPhotoSession, CCPhotoViewer. Camera shutter GeometryReader fix. Express body-parser limit raised to 20MB. CC internal API returns 400/500 for all upload formats — server-side bug, not fixable from GunnerTeam side. VehicleDocViewer giant image fixed (removed unconstrained ScrollView). OtherDocViewer share file extension fixed (doc.fileName not doc.documentName). Branch: feature/companycam-jobs pushed to GitHub.

## [2026-05-11] update | wiki/gunner/gunner-forms-app.md — maintenance bug fixes, notifications, vehicle card tinting (session 11)
Notifications bell wired to NotificationsView + NotificationStore. Maintenance scroll bounce fixed (LazyVStack). Auto-interval presets on type select. Quick complete (inline Mark Complete button on overdue/upcoming rows). current_mileage numeric→string bug fixed in GET maintenance + complete endpoint; corrupted DB record corrected. Other docs row tap area fixed. Vehicle card maintenance tinting (yellow/red wash via maintenance_status subquery on FleetVehicle). CompanyCam questions saved to auto-memory.

## [2026-05-11] update | wiki/gunner/gunner-forms-app.md — vehicle maintenance + other documents feature
Vehicle maintenance views (VehicleMaintenanceView, add/detail/receipt sheets), other documents bucket, maintenance scheduler (upcoming 500mi + 3-day overdue), hasMaintenanceDue badge, mandate_pending persistence, daily overdue push cadence, cross-account notification isolation, role-based editRow locking. Build verified. API deployed to EC2.

## [2026-05-11] update | wiki/gunner/gunner-forms-app.md — fleet feature expansion
Overdue inspection scheduler, overdue UX (red banner/card), mandate inspection, user fleet hub + "My Vehicle" view, document upload UX fixes, registration expiry date formatting, role badge color fix.

## [2026-05-11] decision | wiki/meta/dual-agent-workflow.md
Created dual-agent workflow protocol for interleaved use of Claude Code and Gemini CLI.

## [2026-05-07] update | gunnerteam-api-aws-migration — iOS URL swap incomplete; route prefix documented; ATS/TLS fix done

Info.plist ATS exception confirmed; NSExceptionMinimumTLSVersion fixed TLSv1.0 → TLSv1.2. iOS URL sed from session 6 did not persist — most Swift files still reference Cloudflare Worker URL. Shell broken (working dir deleted); must restart Claude before resuming. Route prefix documented: Express routes are at `/auth/login` etc. with NO `/api/` prefix — `/api/*` returns 404. Migration page status checklist updated.

## [2026-05-07] lint | Full vault health check — 96 pages, 42 issues, 7 fixed

Auto-fixed: canvases/main dead link, comparisons/claude-obsidian-ecosystem plain-text conversion, monday-pm-my-work-view-setup status field, gunnerteam-api-aws-migration index description, gunnerforms-auth-build-2026-04-28 orphan added to index, jamf.md stale evaluation callout, cloudflare vendor stub created. lint-report.md overwritten with current state. 15 warnings + 19 suggestions remain open (see wiki/meta/lint-report-2026-05-07.md).

## [2026-05-07] update | gunner/gunnerteam-api-aws-migration — EC2 deployed, API live, DB connected, login working end-to-end

Updated wiki/gunner/gunnerteam-api-aws-migration.md: Full Terraform infrastructure deployed (EC2 i-002be9ba8cdfbf0da, EIP 3.134.224.29, SGs, IAM role). Express API running via PM2. DB connection fixed (db.js switched to individual env vars; dotenv `#` comment bug in password documented). Login returns JWT — confirmed end-to-end. Admin user tyler.suffern seeded. Next: iOS URL swap + ATS exception, HTTPS, D1 data migration.

## [2026-05-06] save | gunner/gunnerteam-api-aws-migration — Express.js + RDS PostgreSQL architecture, multi-tenancy, SaaS/compliance roadmap

Created wiki/gunner/gunnerteam-api-aws-migration.md: Full migration decision from Cloudflare Workers + D1 → Express.js + RDS PostgreSQL. Multi-tenancy via tenant_id + RLS on every table. Express project scaffolded (auth, users, announcements, fleet routes, S3 proxy, APNs). RDS gunnerteam-dev live in us-east-2, schema applied clean. SaaS/government compliance roadmap documented (SOC 2 → CMMC → FedRAMP). EC2 deploy and data migration still pending.

Updated wiki/gunner/aws-environment.md — GunnerTeam API section added.
Updated wiki/gunner/gunner-forms-app.md — Architecture note updated to reflect migration target.

## [2026-05-05] update | gunner/gunner-forms-app — fleet hub, vehicle inspection form, manager fleet permissions

Updated wiki/gunner/gunner-forms-app.md: Full fleet/vehicle inspection system. VehicleInspectionHubView restructured to Manage Vehicles + Team Schedules full pages. Step-based inspection form (15 steps) with 4 vehicle types (Company Vehicle, Gutter Van, Metal Machine, Dump Trailer). Company Vehicle skips plate step and guards on assigned vehicle; shared types show picker from fleet endpoints. FleetVehicle.currentMileage made Double? to prevent silent decode failure on NULL. Manager permissions enforced backend + frontend: managers see only reports' vehicles, can only edit mileage/notes/reg-expires, assign to reports only, no unassign. Settings shows assigned vehicle as year/make/model · plate. MyVehicleResponse declared once in SettingsView.swift — not redeclared in VehicleInspectionView.swift. wrangler deploy pending.

## [2026-05-04] update | gunner/gunner-forms-app — UTM referral system, push fix, DB hardening, user hierarchy, getgunner.com mobile

Updated wiki/gunner/gunner-forms-app.md: UTM referral URL redesigned (utm_campaign=App_Sales|App_PM, utm_source=lastName, utm_medium=Referral — confirmed in HubSpot); APNs push fixed (InvalidProviderToken — re-paste secrets via CLI not dashboard); unique index on users.email; duplicate email/pending invite checks in handleInvite; user list hierarchy with dept badges and visual indentation; granular manager permission split (canEditProfile/Security/Name/Role); AcceptInviteView read-only name fields; forms list scrolls from top; getgunner.com mobile locked (position:fixed, font-size:16px input, brand hex colors).

## [2026-05-01] update | gunner/gunner-forms-app — manager permissions, UserDetailView, first/last name, Referrals QR, new home screen

Updated wiki/gunner/gunner-forms-app.md: home screen redesigned to Forms + Referrals cards; Referrals QR feature (CoreImage, UTM URL, ShareLink); UserDetailView replaces inline expansion (push-nav, swipe-back, haptics); first/last name added to AppUser model + worker + AcceptInviteView; manager permissions on worker (ownership check) + iOS (canEdit/canDelete logic); StringPickerSheet/UserPickerSheet fix for confirmationDialog popover bug in sheets. D1 migration pending (first_name, last_name columns).

## [2026-04-30] save | session — Gunner Team rename, announcements + push notifications, home nav, StablePasswordField fix, pbxproj cleanup

Updated wiki/gunner/gunner-forms-app.md: full rewrite to reflect rename (GunnerForms → Gunner Team), auth system, announcements feature with APNs push, home screen navigation rewrite, branch strategy, D1 migrations pending, Cloudflare APNs secrets checklist.

Key session work: app renamed (bundle ID com.gunner.team, URL scheme gunnerteam://), StablePasswordField focusTrigger fix eliminates Passwords bar flicker, announcements CRUD + APNs ES256 JWT push in worker.js, home nav with Forms/Vehicle Inspection/Schedules stubs, pbxproj productName + INFOPLIST_FILE path corrected via sed.

## [2026-04-28] save | session — GunnerForms auth system build: D1 schema, Resend setup, worker auth routes complete; iOS screens + admin bootstrap pending

## [2026-04-28] update | gunner/gunner-forms-app — updated version approved (native IT Request + Change Order via Cloudflare Worker)

## [2026-04-27] update | gunner/gunner-forms-app — major architecture update: Cloudflare Worker routes, native IT Request + Change Order forms, user/project typeahead, file upload, version scheme, branch strategy

## [2026-04-24] lint-fix | W4 + W7m resolved — 28 unlinked mentions wikilinked across 5 pages; malformed pipe in index.md fixed; W1 false positive (all 8 pages already in index.md)

## [2026-04-24] save | session 14 end — hot cache updated; 3 lint issues open (W1/W4/W7m); mac-tool-setup genericized for sharing

## [2026-04-24] update | runbook — mac-tool-setup: added full Claude-Obsidian brain usage section

## [2026-04-24] save | runbook — mac-tool-setup: iTerm2 + Starship + Claude Code + Obsidian full stack install guide

## [2026-04-24] lint | Session 14 full pass — 90 pages, 3 issues (8 orphans, 28 unlinked mentions, 1 malformed anchor)

## [2026-04-24] save | runbook — Transfer Starship prompt config to new Mac (MesloLGS NF, zshrc init, iTerm2 font troubleshooting)

## [2026-04-23] lint | Auto-fix pass — W3, W7, W8, S1, S2

**W3 — sources/_index.md missing keeper-workshop:**
- wiki/sources/_index.md — added "Vendor & Tool Training" section with `[[summaries/keeper-workshop]]` entry

**W7 — entities/_index.md Organizations and Products sections populated:**
- wiki/entities/_index.md — Organizations section: 11 vendor/org entries (hexnode, google-workspace, keeper, knowbe4, dialpad, hubspot, monday, make-com, jamf, bitdefender, sendgrid)
- wiki/entities/_index.md — Products & Tools section: 5 API reference and tool entries (dialpad-api-reference, hubspot-api-reference, monday-api-reference, stripe-api-reference, quote-portal)

**W8 — ciso-track/roadmap.md stale updated date:**
- wiki/ciso-track/roadmap.md — `updated:` bumped from 2026-04-10 to 2026-04-23; `[[ciso-track/cissp]]` added to related frontmatter and Resources section

**S1 — Created wiki/gunner/aws-environment.md:**
- New stub page: EC2 api-user.php, WordPress → HubSpot contact/deal creation, Make.com workaround, Dev/Prod/QA/Staging accounts, credential risk flag, [!gap] callouts for unknown security posture
- wiki/index.md — added to Gunner Operations table
- wiki/vendors/hubspot.md — added `[[gunner/aws-environment]]` to frontmatter related and Integrations table + Related section
- wiki/vendors/make-com.md — added `[[gunner/aws-environment]]` to frontmatter related and body references

**S2 — Created wiki/ciso-track/cissp.md:**
- New stub page: 8 CISSP domains (CBK), exam details (CAT format, 100–150 Qs, 700/1000 passing, ~$749), Gunner experience mapped to domains, cross-links to existing vault concept pages, [!gap] callouts for study plan/materials/timeline
- wiki/index.md — added to CISO Track table
- wiki/ciso-track/roadmap.md — added `[[ciso-track/cissp]]` to related frontmatter and Resources section

## [2026-04-23] save | Make.com deal deletion scenario + HubSpot SOP lead tags

Updated vendors/make-com.md — documented Delete AWS-Created Deals scenario; wp_project_id numeric filter (greater than 0, not "has any value"); Watch Objects polling behavior; workaround status.
Updated gunner/hubspot-salesperson-sop.md — added Lead Tags to The Lead Card section.

## [2026-04-22] save | GunnerForms approval + Hexnode custom app deployment

Updated gunner/gunner-forms-app.md — approved 2026-04-22, pull-to-refresh + error state implemented (feature/webview-improvements), WKWebView CGAffineTransform insight, deployment via ABM/Hexnode.
Created questions/hexnode-custom-app-deployment.md — private App Store → ABM → Hexnode deployment workflow.

## [2026-04-22] note | Hexnode WiFi policy change

Enabled WiFi access in Hexnode profile temporarily to allow GunnerForms testing on device. Change made by Tyler. Revert or formalize after testing is complete.

## [2026-04-21] save | GunnerForms App Store Guideline 4.8 fix

Updated gunner/gunner-forms-app.md with current app state (resubmitted, branch strategy, new features).
Created questions/app-store-guideline-4-8-webview-login.md — WebView login rejection diagnosis and fix.
Canvas cleanup: welcome.canvas deleted, Wiki Map + main.canvas indexed.

## [2026-04-21] lint | Wiki health check — session 9

Auto-fixed 7 issues:
- Removed duplicate "Questions" section from index.md (legacy leftover)
- Added lint-report.md and entities/_index.md to index
- Qualified 3 unqualified wikilinks (questions/claude-code-hook-tooluse-error.md, entities/_index.md)
- Fixed non-standard `status: in-progress` → `developing` in hubspot-workflow-designs.md
Open item: 3 canvas files (Wiki Map, main, welcome) not in index — needs review
Created: wiki/meta/lint-report-2026-04-21.md; updated wiki/lint-report.md

## [2026-04-21] save | Claude Code startup hook ToolUseContext error

Created `wiki/questions/claude-code-hook-tooluse-error.md`:
- Root cause: prompt hooks fire before ToolUseContext initializes; MCP tool calls fail silently
- Hot cache content still injects correctly despite error — cosmetic issue
- Workarounds: do nothing / switch to bash cat / file bug on GitHub
- Observed on 2.1.98; upgraded to 2.1.104 (fix unconfirmed)
Added "Questions & Troubleshooting" section to wiki/index.md

## [2026-04-20] save | Claude AI — Team Setup & Integration Options

Created `wiki/gunner/claude-team-setup.md`:
- Claude.ai Team integrations: HubSpot available, GitHub not available as of 2026-04-20
- Claude Code GitHub MCP setup (Docker method + PAT)
- Use case decision guide: Claude.ai Team vs Claude Code for different goals

## [2026-04-20] save | HubSpot Workflow Designs — Lead Assignment & Activity Hygiene

Created `wiki/gunner/hubspot-workflow-designs.md`:
- Workflow A: Rotate lead if no owner (5-min delay, branch check, rotate)
- Workflow B: Owner sync Lead Owner → Contact Owner (+ known trigger limitation)
- Workflow C: No activity alert for leads (3 active stages)
- Workflow D: No activity alert for deals (3 active stages, "Contract Sent" → "Expecting to Close")
- HubSpot quirks table: rotation token, workflow-to-workflow triggers, Next activity date edge cases

## [2026-04-16] ingest | HubSpot Leads Project 4.15.26.md + 4.16.26.md + HubSpot Lead Phases.md

Updated wiki/gunner/hubspot-leads-project.md:

**From HubSpot Lead Phases.md (4.16.26):**
- Added "Project Go-Live Phases" section (Phase 1–4) near top of page
- Phase 1: limited go-live (no reassignment, daily reports, workspace, pipeline hygiene workflow)
- Phase 2: round-robin via AWS Lambda — confirms _system/lead-assignment/ is the WFM
- Phase 3: Dialpad → Monday integration — named staff: PMs + Sarah (project coordinator) + Bryce (AR) + Mike Ushka (service manager)
- Phase 4: HubSpot cleanup (reports, workflows, properties, commissions)

**From HubSpot Leads Project 4.15.26.md:**
- Updated workflow 7b: web leads (Lead Source = Web Submission) are excluded from round-robin; workflow now sends webhook to Lambda instead of native HubSpot rotation
- Resolved "Reassignment Timing — Clarification Needed" → confirmed two windows: 5 min (Lambda, Dialpad call check) + 24 hr (HubSpot workflow 7c)
- Updated Known Problems: round robin row updated to "Being addressed in Phase 2"

**From HubSpot Leads Project 4.16.26.md:**
- Added Open Questions section: lead tags, lead type/label use case, task creation automation, web estimator lead_source field
- Added Dialpad → Monday Phase 3 section with named staff

Also added: lead-assignment-automation + dialpad + monday cross-links to frontmatter. Moved all 3 source files to raw-sources/runbooks/.

## [2026-04-16] build | Lead assignment automation v2 — contact sync, location routing, Monday PM logging

Extended `_system/lead-assignment/` with three new features:

**HubSpot → Dialpad contact sync:**
- `src/lib/contactSync.js` — upsert contact on lead creation (non-blocking)
- `src/lib/dialpad.js` — added `createContact`, `updateContact`
- `src/lib/state.js` — added `DIALPAD_CONTACT#` cache records
- `src/lib/hubspot.js` — expanded `getContactDetails` (name, email, phone, state, address)

**Location-based rep routing:**
- NJ contacts → `REPS_NJ` pool; default contacts → `REPS` pool
- Each pool has its own DynamoDB round-robin pointer (`RR#SALES`, `RR#SALES_NJ`)
- `src/lib/assign.js` — `getRepPool()` helper, namespace-aware RR pointer calls
- `src/config.js` — added `REPS_NJ`, `PMS`, Monday config fields

**Monday.com PM activity logging:**
- `src/lib/monday.js` — GraphQL client: `createJobItem`, `postUpdate`, call/SMS formatters
- `src/handlers/dealReadyToBuild.js` — creates Monday item when deal → Ready to Build; stores MONDAY# record
- `src/handlers/dialpadEvents.js` — extended to handle SMS events; PM hangup/SMS → looks up job by contact phone → posts update
- `src/lib/state.js` — added `MONDAY#` records, `getMondayJobByPhone` scan, PM RR pointer

Also updated: serverless.yml (new dealReadyToBuild function, new env vars), .env.example, wiki page.

## [2026-04-16] build | Round-robin lead assignment automation — scripts written

Created `_system/lead-assignment/` (7 source files, serverless.yml, package.json, .env.example):
- `src/lib/assign.js` — core algorithm: round-robin first attempt, random retries, manager escalation
- `src/lib/state.js` — DynamoDB: pending assignments, rep availability cache, RR pointer
- `src/lib/dialpad.js` — call history query, JWT webhook verification, user availability
- `src/lib/hubspot.js` — lead fetch, contact phone, owner PATCH
- `src/handlers/leadCreated.js` — triggered by HubSpot workflow webhook on lead creation
- `src/handlers/checkAssignments.js` — scheduled every 1 min, processes expired 5-min windows
- `src/handlers/dialpadEvents.js` — receives Dialpad connected/hangup webhooks, updates availability cache
- `serverless.yml` — Lambda + API Gateway + DynamoDB + EventBridge; two URLs output on deploy

Created wiki/gunner/lead-assignment-automation.md — architecture, setup steps, open items before go-live.

Key design decisions:
- Dialpad webhook cache (connected/hangup) is source of truth for rep availability
- DynamoDB conditional write prevents duplicate processing across Lambda invocations
- Round-robin for first attempt; random selection for reassignments
- All-reps-on-calls edge case: assigns anyway (falls back to busy pool)
- No phone number on lead: assignment still happens, call check skipped

## [2026-04-16] save | Dialpad → HubSpot integration architecture

Created wiki/gunner/dialpad-hubspot-integration.md:
- Decision: build custom webhook receiver to replace unreliable native Dialpad integration
- Architecture: Dialpad webhooks → Lambda/Cloudflare Workers → HubSpot API (+ optional Monday)
- Full call logging and SMS logging flows with exact API steps
- Phone normalization pattern, no-contact/no-deal edge cases, duplicate prevention
- HubSpot association type IDs, recording URL requirements
- 7 open items before build can start

## [2026-04-16] ingest | HubSpot + Monday.com API docs — fetched from live developer docs

Created wiki/vendors/hubspot-api-reference.md:
- Auth: Private App token (Bearer), required scopes
- Contact search by phone: POST /crm/objects/2026-03/contacts/search — must use hs_searchable_calculated_phone_number (last 10 digits, no country code)
- Deal associations: GET /crm/objects/2026-03/contact/{id}/associations/deal — returns deal IDs
- Create call engagement: POST /crm/v3/objects/calls — all fields, association typeIDs (contact: 194, deal: 206)
- Create note (SMS): POST /crm/v3/objects/notes — association typeIDs (contact: 202, deal: 214)
- Full integration flow for call logging and SMS logging

Created wiki/vendors/monday-api-reference.md:
- Auth: Authorization header (no Bearer prefix), token from Developers menu
- Search items by column: items_page with query_params.rules (any_of, contains_text operators)
- Create item: create_item mutation with column_values as JSON string
- Update columns: change_multiple_column_values mutation
- Column value JSON formats: text, status, date, phone, people
- Gotchas: JSON.stringify required, no combining query_params + cursor, phone column format varies

## [2026-04-16] ingest | dialpadapi.json — Dialpad API v2 full spec

Created wiki/vendors/dialpad-api-reference.md:
- Auth: API key (Bearer) + OAuth2 scopes needed (calls:list, recordings_export, message_content_export)
- Webhooks: endpoint registration, JWT/HS256 signing, subscription management
- Call event payload: exact field names (external_number, duration in ms, call_recording_share_links, contact.phone)
- SMS event payload: from_number, to_numbers, text (needs scope), created_date (ISO 8601)
- Contacts API: list/get/create; phone numbers always E.164
- HubSpot integration build notes: phone normalization pattern, call logging flow, SMS logging flow
Updated vendors/dialpad.md: added HubSpot Integration section + link to API reference page

## [2026-04-16] ingest | HubSpot Leads Project 4.15.26.md

Updated wiki/gunner/hubspot-leads-project.md:
- Added Known Problems / Open Issues table (10 items)
- Added Reassignment Timing clarification — 5-min initial vs 24-hr no-task; needs Glen/India confirm
- Added Make.com Lead Activity to Deal scoping section
- Updated Deferred section: Dialpad → HubSpot integration now being scoped

## [2026-04-16] save | Gunner Assistant + GunnerForms app pages created

- wiki/gunner/gunner-assistant.md — AI knowledge base project; Options 1/2/3 evaluated; RAG architecture; decision pending boss
- wiki/gunner/gunner-forms-app.md — GunnerForms Swift app architecture; Monday.com forms; git initialized on gunner-ios repo

## [2026-04-14] lint | Full vault review + fix pass — all criticals resolved, vault ready for projects

**24 issues identified (lint pass). All 5 criticals and all major warnings resolved.**

**Criticals fixed:**
- wiki/gunner/environment.md — backslash-corrupted wikilinks (`\|` → `|`) in 3 alias rows
- wiki/comparisons/claude-obsidian-ecosystem.md — deleted (broken upstream wikilinks to non-existent pages)
- wiki/concepts/_index.md — created (dead link from 5 pages now resolves)
- wiki/entities/Andrej Karpathy.md — created stub entity page
- wiki/meta/boss-setup-guide.md — written to disk (MCP write had not persisted)

**Warnings fixed:**
- wiki/vendors/jamf.md — created (JAMF mentioned 16× with no dedicated page; under evaluation)
- wiki/concepts/poam.md — created (POAM mentioned 33× with no dedicated page)
- wiki/threats/t1110-brute-force.md — added `[[runbooks/incident-response]]` link (lint W3)
- wiki/concepts/LLM Wiki Pattern.md — fixed `.raw/` → `raw-sources/` references
- wiki/sources/_index.md — populated with all 11 summaries in 3 categories
- wiki/canvases/main.canvas — expanded Vendors zone (h=480), added file-jamf + file-poam nodes
- wiki/index.md — updated with all new pages (JAMF, POAM, Karpathy, comparisons, concepts _index, boss-setup-guide, claude-obsidian-setup-guide)

**Remaining minor items (accepted/deferred):**
- welcome.canvas — broken GIF/video embeds (Cosmic Brain Clean.gif, 2026-04-07 14-19-00.mkv don't exist in vault)
- entities/_index.md — empty placeholder sections
- dashboard.base — [[dashboard.base]] self-embed fragility (cosmetic)

## [2026-04-14] setup | claude-obsidian upstream sync — gaps filled, all files adapted for Gunner

**Files added/adapted from claude-obsidian-main (upstream v1.4.3):**
- skills/wiki/references/ — 6 reference files (css-snippets, frontmatter, mcp-setup, modes, plugins, rest-api)
- commands/ — wiki.md, save.md, autoresearch.md, canvas.md (wiki.md updated: .raw/ → raw-sources/)
- _templates/ — comparison.md, entity.md, question.md, source.md added
- .obsidian/snippets/vault-colors.css — rewritten for Gunner folder color scheme
- .obsidian/plugins/ — calendar, obsidian-banners, thino added
- .obsidian/community-plugins.json — updated with new plugins
- wiki/meta/dashboard.md — adapted for Gunner folder structure + Dataview queries
- wiki/meta/dashboard.base — adapted for Gunner types (threats, runbooks, vendors, summaries)
- wiki/getting-started.md — adapted: raw-sources/ paths, Gunner vault structure, Gunner commands
- wiki/Wiki Map.canvas — created Gunner-specific hub-and-spoke map (replaces upstream cosmic brain)
- wiki/canvases/welcome.canvas — added from upstream
- wiki/concepts/ — LLM Wiki Pattern.md, Hot Cache.md, Compounding Knowledge.md added
- wiki/comparisons/ — Wiki vs RAG.md, claude-obsidian-ecosystem.md added
- wiki/sources/_index.md, wiki/entities/_index.md — directory index files added
- WIKI.md — upstream schema reference added to vault root; .raw/ → raw-sources/ throughout
- agents/wiki-ingest.md, agents/wiki-lint.md — kept Gunner-customized versions (already correct)
- .claude/settings.json — PostToolUse hook added (auto-git-commit; guarded by [ -d .git ])
- _system/claude-obsidian-main/ — upstream source moved here from raw-sources/

## [2026-04-14] question | Keeper web vault login redirect loop — wiki/questions/keeper-web-vault-login-loop.md

Chrome extension intercepts web vault login causing redirect loop; extension popup works fine. Fixes: clear keepersecurity.com cookies, disable extension temporarily, test in Incognito. HTTPS-Only Chrome policy flagged as possible secondary cause.

## [2026-04-14] meta | Vault maintenance docs + canvas populated

- wiki/meta/vault-commands-reference.md — commands reference and weekly maintenance schedule
- wiki/meta/boss-setup-guide.md — fresh claude-obsidian vault setup guide (plugin install method)
- wiki/canvases/main.canvas — all 49 wiki pages across 6 color-coded zones

## [2026-04-14] update | hubspot-leads-project.md — full 9-phase step-by-step sandbox build guide

Conflict resolutions noted (meeting notes win on stage names, reassignment timing, deal creation gating).

## [2026-04-14] save | Session note filed — wiki/meta/session-2026-04-14b-setup-chrome.md

## [2026-04-14] ingest | Chrome Enterprise policy export — CIS gap analysis

**Source:** chrome-policy-export-2026-04-14.md → raw-sources/runbooks/

**Gaps closed (were flagged in lint report):**
- SafeBrowsingProtectionLevel = 2 (Enhanced) ✅
- HttpsOnlyMode = force_enabled ✅
- GenAI fully disabled (GenAiDefaultSettings=2, BuiltInAIAPIsEnabled=false) ✅

**Remaining gaps:**
- DeveloperToolsAvailability = 0 (should be 2) — Medium
- DnsOverHttpsMode = automatic (should be secure) — Low
- 3 deprecated policies to clean up — Low
- DownloadRestrictions = 4 (consider 2) — Low

**Files created:** wiki/gunner/chrome-policy.md  
**Files updated:** summaries/cis-chrome-enterprise-benchmark.md (gap table updated), wiki/index.md

## [2026-04-14] update | Frontmatter convention — status field + quoted wikilinks applied to 49 wiki pages

All wiki pages updated: `status:` field added (stable/developing by type); `related:` wikilinks converted to quoted YAML format `"[[page/name]]"`. Orphan identified: wiki/gunner/brand-colors.md (one inbound link — low priority).

## [2026-04-14] save | Session note — claude-obsidian install and customizations filed at wiki/meta/session-2026-04-14-claude-obsidian.md

## [2026-04-14] setup | claude-obsidian skill system installed + Gunner customizations

**Skills installed (skills/):** wiki, wiki-ingest, wiki-query, wiki-lint, save, autoresearch (with Gunner program.md), canvas, defuddle, obsidian-markdown, obsidian-bases

**Agents installed (agents/):** wiki-ingest.md, wiki-lint.md

**Hooks installed (hooks/):** hooks.json — sessionStart (loads Memory.md + hot.md), postCompact (reloads both), stop (prompts hot.md update)

**Templates created (_templates/):** concept.md, vendor.md, threat.md, runbook.md, summary.md

**Directories created:** wiki/questions/, wiki/sources/, wiki/entities/, wiki/meta/, wiki/canvases/, _attachments/images/canvas/

**CLAUDE.md:** Replaced RTF stub with full markdown — merged Tyler's operating rules with claude-obsidian conventions. Now the authoritative session instructions.

**wiki/hot.md:** Created — ~500-word session cache, populated with current vault state.

**Key adaptations from upstream claude-obsidian:**
- raw-sources/ (with subdirectories) replaces .raw/
- Memory.md kept as rich persistent layer; hot.md is the lightweight session cache
- Tyler's wiki structure (concepts/vendors/threats/runbooks/ciso-track/gunner/summaries) preserved
- save skill maps to Tyler's folder types (not generic sources/entities/questions)
- autoresearch program.md customized for IT/security/CISO domains
- lint-report stays at wiki/lint-report.md with timestamped copies to wiki/meta/

## [2026-06-25] save | Session — Bedrock Billing Block, QP Key, B1 Org-Reconcile Prep
- Type: session
- Location: wiki/tyler/meta/session-2026-06-25-bedrock-billing-qp-key-org-reconcile.md
- From: cc-1807 (half-flip recovery + atomic-role-flip guardrail), cc-1808 (QP draft key verified), Bedrock INVALID_PAYMENT_INSTRUMENT block → LLM_PROVIDER=anthropic bridge (v371) → RESOLVED: card on member acct 980921733684 → re-created agreements → flipped back to bedrock (v372, in-account), cc-2901 two-org RLS reconcile diagnostic (69aad261 real vs 7d6db1bb shell; Colin p17/p18 plan)

## [2026-06-24] save | Session — LLM Engine + B1 Cutover Root-Cause Chain
- Type: session
- Location: wiki/tyler/meta/session-2026-06-24-cc1800-2157-llm-engine-b1-cutover.md
- From: cc-1800–1806 (LLM/assistant engine, Bedrock, task dispatch, service keys) + cc-2152–2157+ (B1 gunterteam_app cutover — proxy, Cognito org-ID mismatch, resolveUser diagnostic, role fix)

## [2026-04-14] ingest | 9 new documents — CIS benchmarks, NIST CSF 2.0, CMMC Assessment Guide

**Sources ingested (moved to raw-sources/study/):**
- AG_Level1_V2.0_FinalDraft_20211210_508.pdf — CMMC L1 Assessment Guide v2.0 (Dec 2021)
- NIST.CSWP.29.pdf — NIST CSF 2.0 (Feb 2024)
- CIS_Controls_Guide_v8.1.2_0325_v2.pdf — CIS Controls v8.1.2 narrative guide (Mar 2025)
- CIS_Controls_Version_8.1.2___March_2025.xlsx — CIS Controls v8.1.2 reference spreadsheet
- CIS_Google_Workspace_Foundations_Benchmark_v1.3.0.pdf — GWS hardening benchmark (Jun 2025)
- CIS_Google_Chrome_Enterprise_Core_Browser_Benchmark_v1.0.0.pdf — Chrome Enterprise Core benchmark v1.0.0 (Jun 2025, first edition)
- CIS_Apple_iOS_26_Benchmark_v1.0.0.pdf — iOS 26 hardening benchmark (Oct 2025)
- CIS_Apple_macOS_26_Tahoe_Benchmark_v1.0.0.pdf — macOS 26 Tahoe hardening benchmark (Oct 2025)
- CIS_Microsoft_Office_Enterprise_Benchmark_v1.2.0.pdf — MS Office hardening (study ref, low Gunner relevance)

**Previously unsorted files moved:**
- Hubspot_ Lead Object Buildout.xlsx → raw-sources/runbooks/
- HubSpot Leads Project 4.13.26.md → raw-sources/runbooks/
- My Notebook @ Gunner Roofing.pdf → raw-sources/transcripts/

**Files created:**
- wiki/concepts/nist-csf.md — NIST CSF 2.0 concept page; six functions, Tiers, Profiles, Gunner tier estimates
- wiki/summaries/cmmc-level1-assessment-guide.md — 17 practices by domain; SI antivirus gap is CMMC submission blocker
- wiki/summaries/nist-csf-2.md — CSF 2.0 source summary; GOVERN function detail
- wiki/summaries/cis-controls-v8-1-2.md — v8.1.2 update; GOVERN mapping added
- wiki/summaries/cis-google-workspace-benchmark.md — GWS L1/L2 gap analysis; admin hardware key gap
- wiki/summaries/cis-chrome-enterprise-benchmark.md — Chrome Enterprise Core first benchmark; HTTPS-Only and Enhanced Safe Browsing gaps
- wiki/summaries/cis-ios-26-benchmark.md — iOS 26 institutionally-owned profile; passcode simple-value gap vs Hexnode policy
- wiki/summaries/cis-macos-26-benchmark.md — macOS 26 Tahoe; audit log retention gap identified
- wiki/summaries/cis-ms-office-benchmark.md — MS Office study reference

**Files updated:**
- wiki/concepts/cis-ig1.md — version bump to v8.1.2; NIST CSF 2.0 alignment section; benchmark links; threat links added
- wiki/concepts/cmmc.md — Assessment Guide source added; 17 practices domain table; blocker callout
- wiki/vendors/hexnode.md — CIS benchmark alignment section; 3 priority gap actions identified
- wiki/vendors/google-workspace.md — CIS GWS and Chrome benchmark links; 4 priority actions
- wiki/index.md — 8 new summary entries; concepts/nist-csf added

**Gaps surfaced by benchmarks (action required):**
- iPhone: Hexnode CIS IG1 allows "simple value" passcode — CIS iOS 26 (institutionally-owned) requires alphanumeric
- Mac: Verify all sharing services explicitly disabled in Hexnode policy
- Mac: No formal audit log retention policy documented
- Google Workspace: Admin accounts — verify hardware key or assess risk
- Chrome: Safe Browsing should be Enhanced; HTTPS-Only mode not confirmed
- CMMC blocker: SI.L1-3.14.2 (endpoint AV) not met — Bitdefender GravityZone ~$1.1k/yr

## [2026-04-13] baseline | Vault baseline — missing pages, threat seeds, concept pages, index rebuild

**Vendor pages created:**
- wiki/vendors/dialpad.md — VoIP platform, VoIP audit history, SSO status flag, OOO runbook link
- wiki/vendors/monday.md — Operations PM, IT Dev board, Gunner Forms integration, Make.com automations
- wiki/vendors/hubspot.md — Sales CRM, Lead buildout project, pipeline config, Google Chat integration

**Concept pages created:**
- wiki/concepts/sso.md — Google as IdP, SSO app list, non-SSO offboarding risk, SCIM
- wiki/concepts/mfa.md — OU-based MFA settings, session durations, Admin OU requirements, coverage gaps
- wiki/concepts/email-security.md — DMARC p=reject, SPF, DKIM, MTA-STS, BIMI, SendGrid security flag
- wiki/concepts/apple-business-manager.md — Zero-touch provisioning, DEP, Gunner Forms app distribution
- wiki/concepts/incident-response.md — IR authority, defined scenarios, POAM gaps, threat links

**Threat pages created (MITRE ATT&CK seeded):**
- wiki/threats/t1566-phishing.md — KnowBe4, DMARC, Chrome Safe Browsing controls; gap: no email gateway
- wiki/threats/t1078-valid-accounts.md — Offboarding kill-switch; OneNote credential exposure flagged as CRITICAL
- wiki/threats/t1110-brute-force.md — MFA and Keeper as primary mitigations; non-SSO app gap
- wiki/threats/t1486-data-encrypted-for-impact.md — Flat network + backup gap as primary exposure
- wiki/threats/t1199-trusted-relationship.md — Contractor OU, Make.com tokens, DevOps AWS exposure

**Runbook created:**
- wiki/runbooks/incident-response.md — Three procedures: lost device, account compromise, ransomware

**Updated:**
- wiki/index.md — full rebuild with all new pages
- Memory.md (vault) — converted from RTF stub to markdown; reflects current state

## [2026-04-13] ingest | Hubspot_ Lead Object Buildout.xlsx + HubSpot Leads Project 4.13.26.md

Created wiki/gunner/hubspot-leads-project.md — full Lead object buildout spec: lead stages, deal stages with weighted averages, three lead source flows (call-in human, call-in message, website), lead properties, round robin/reassignment automation, open questions, and to-do list. Updated wiki/index.md.

## [2026-04-13] update | JAMF status corrected — under evaluation (approval expected late April 2026), not rejected. Chrome Enterprise Core compatibility is the key technical gate.

## [2026-04-13] confirm | Brand colors confirmed by Tyler — wiki values correct; OneNote values were incorrect

Blue `#1b538f`, Red `#dd141e` are authoritative. Full palette in wiki/gunner/brand-colors.md confirmed. Open flag closed.

## [2026-04-10] setup | Vault initialized — CLAUDE.md, Memory.md, index.md created

## [2026-04-10] migration | Converted index.md, log.md, ciso-track/roadmap.md from RTF to markdown

## [2026-04-10] ingest | Gunner brand colors — created wiki/gunner/brand-colors.md

## [2026-04-13] lint | Lint pass completed — report at wiki/lint-report.md; no broken links; onboarding/offboarding runbooks created; missing vendor pages (Dialpad, Monday, HubSpot) flagged

## [2026-04-13] new | runbooks/onboarding.md and runbooks/offboarding.md created

## [2026-04-13] ingest | IT_Tasks_1775773048.xlsx — full completed Monday IT task history (Nov 2025–Apr 2026); created gunner/completed-projects.md; updated environment.md (NJ network), app-inventory.md (Make.com, GoTo, Sendgrid, Owl); moved to runbooks/

## [2026-04-13] ingest | CMMC Presentation.txt — federal market strategy; created concepts/cmmc.md and gunner/federal-market.md; moved to study/

## [2026-04-13] ingest | Stripe API Reference.pdf — Stripe sandbox reference for Gunner CT; Stripe added to app-inventory; test API key flagged (store in Keeper)

## [2026-04-13] ingest | My Notebook @ Gunner Roofing.pdf — OneNote export (20 pages)

**Filed:**
- wiki/runbooks/dialpad-out-of-office.md (created) — Dialpad OOO: vacation status, DND, SMS auto-reply, working hours
- wiki/gunner/hubspot-sales-pipeline.md (created) — Sales pipeline stale deal reports and workflows
- wiki/summaries/my-notebook-gunner-roofing.md (created)

**Not filed (ephemeral/operational):** Epson ticket refs, overdue payment note, Dialpad delete list, empty phone replacement page, Gemini internal system prompt

**Open flag:** Brand color conflict — OneNote says Blue `#2b528b` / Red `#cb312b`, wiki has `#1b538f` / `#dd141e`. Awaiting Tyler confirmation before updating brand-colors.md.

## [2026-04-13] ingest | My Notebook @ Gunner Roofing.pdf — full 112-page ingest (pages 21–112)

**Filed:**
- wiki/runbooks/hubspot-google-chat.md (created) — HubSpot → Google Chat notification setup (per-user + admin)
- wiki/vendors/knowbe4.md (updated) — PAB section added; real phishing example documented
- wiki/vendors/hexnode.md (updated) — JAMF vs Hexnode pricing comparison; Chrome Enterprise Core as deciding factor
- wiki/vendors/google-workspace.md (updated) — DMARC migration history (p=none → p=reject 2026-02-03), MTA-STS enforce, BIMI, delegated admin account
- wiki/ciso-track/roadmap.md (updated) — Added planned certs: SecurityX, MD-102, MS-102, SC-300, Apple ACIT, Power BI, CISM
- wiki/gunner/environment.md (updated) — Added main phone (866-262-6005), DUNS# (121897089), weatherTAP GPS coords, AWS account list, email security note
- wiki/gunner/app-inventory.md (updated) — Added QuickMeasure, SSO vs email/password classification section; updated SSO status per 2026-01-16 audit
- wiki/gunner/hubspot-sales-pipeline.md (updated) — Added lifecycle stages (Inbound→Lead→Not Qualified→Opportunity→Customer→Win Back), lead statuses, 15-min reassignment, round robin, HubSpot SOPs reference
- wiki/summaries/my-notebook-gunner-roofing.md (updated) — Full page-by-page disposition for all 112 pages

**Not filed (ephemeral/operational):**
Conference room evaluation (no decision), Whip Around failure form, OOO calendar event, Monday My Work tasks, Fixed Office list, Frank secondary number, Greenhouse training, PM team filter, Loom video links

**SECURITY FLAGS (immediate action required):**
- Page 111: AWS DevOps credentials (username/password + Aurora prod DB string) — CRITICAL
- Page 101: Keeper admin recovery codes (8 codes stored outside Keeper) — CRITICAL
- Page 102: Hexnode MDM admin password in OneNote
- Page 103: Netgear switch login in OneNote
- Page 99: Google GAM Client ID + Client Secret in OneNote
- Page 98: Anil's 10 2FA backup codes in OneNote
- Page 107: SendGrid backup code in OneNote
- Page 95: DevOps HubSpot 2FA codes file in OneNote
- Page 46: Leslie's PIN (153731) in OneNote
- Page 34: Leslie harassment incident (Kevin Freeman, Dialpad) — sensitive, not filed

**Open flag:** Brand color conflict unresolved — see wiki/summaries/my-notebook-gunner-roofing.md

## [2026-04-13] ingest | Bulk ingest — 20 raw-source documents

**Sources ingested:**
- Acceptable Use Policy.docx (IT-POL-AUP-001 v1.1)
- AUP Acknowledgment Form.docx
- [TEMPLATE] Gunner IT SOP Base.docx (template only — no wiki page, reference only)
- CMMC Presentation Final.pptx (mostly image slides — no significant extractable content)
- Departmental Comms.xlsx
- Gunner Forms Privacy Policy.docx (content folded into gunner/app-inventory and gunner/environment)
- Gunner IT Governance.xlsx
- Hexnode iPhone Policy (CIS IG1).xlsx
- Hexnode iPhone Policy (Total Lockdown).xlsx
- Hexnode Mac Policy (CIS IG1).xlsx
- Hexnode Mac Policy (Total Lockdown).xlsx
- IT Communications Style Guide.docx (IT-SOP-COMMS-001 v1.1)
- IT Decision & Change Log.docx (IT-GOV-LOG-001 v1.1) — key decisions folded into wiki pages
- IT Standards Final.pptx (framework comparison — content in concepts/cis-ig1)
- IT Standards v2 Final.pptx (3-option framework selection — content in concepts/cis-ig1)
- Jamf_Microsoft v2 Final.pptx (rejected vendor evaluation — noted in vendors/hexnode)
- Keeper Workshop.pptx
- KnowBe4 Proposal.pptx
- new laptop set up.docx
- New Phone setup.docx
- Stripe API Reference.pdf (could not extract — poppler not installed; pending review)
- Switch to 365 Final.pptx (mostly image slides — no significant extractable content)
- System Security Plan.docx (IT-SSP-001 v1.1)
- Tyler Suffern - Performance Review 2026.docx (accomplishments folded into ciso-track/roadmap)

**Files created:**
- wiki/gunner/environment.md
- wiki/gunner/app-inventory.md
- wiki/gunner/system-security-plan.md
- wiki/vendors/hexnode.md
- wiki/vendors/google-workspace.md
- wiki/vendors/keeper.md
- wiki/vendors/knowbe4.md
- wiki/concepts/cis-ig1.md
- wiki/runbooks/new-laptop-setup.md
- wiki/runbooks/new-phone-setup.md
- wiki/runbooks/acceptable-use-policy.md
- wiki/runbooks/it-comms-style-guide.md
- wiki/summaries/it-governance.md
- wiki/summaries/system-security-plan.md

**Files updated:**
- wiki/index.md (full rebuild)
- wiki/ciso-track/roadmap.md (Practical Experience section — added all completed initiatives from performance review)

**Security flag:** Raw source files (new laptop set up.docx, New Phone setup.docx) contain plaintext credentials including Apple Business Manager password and default device passcodes. These should be migrated to Keeper and the raw docs should be considered sensitive.

## [2026-04-17] save | Session note — wiki/meta/session-2026-04-17-lint-fix-pass.md

## [2026-04-16] lint | Auto-fix pass (warnings + suggestions) — W1-W9, W18, S2-S6, S8, S11, S13, S17

Fixed:
- W1: `[[gunner/brand-colors]]` added to environment.md related frontmatter
- W2/S11: `[[concepts/poam]]` inline links added in incident-response.md, t1486.md, system-security-plan.md
- W3: `[[gunner/completed-projects]]` added to environment.md and roadmap.md related frontmatter
- W4: `[[vendors/jamf]]` added to hexnode.md related frontmatter + body link; environment.md related frontmatter
- W5: `[[comparisons/Wiki vs RAG]]` added to LLM Wiki Pattern.md and Compounding Knowledge.md Connections sections
- W8: roadmap.md — related frontmatter filled (nist-csf, cmmc, cis-ig1, summaries); Frameworks Being Studied updated (NIST CSF 2.0 + CIS Controls v8 → "In vault — studying" with concept/summary links)
- W9/W18: dialpad-hubspot-integration + lead-assignment-automation linked from dialpad.md and hubspot.md (frontmatter + body)
- S2: `wiki/vendors/quote-portal.md` created (stub)
- S3: `wiki/vendors/make-com.md` created (stub)
- S4: `wiki/vendors/sendgrid.md` created (stub)
- S5: `wiki/vendors/bitdefender.md` created (stub)
- S6: Vault Study Pages section added to roadmap.md Resources & Reading
- S8: `[[sources/_index]]` added to wiki/index.md Meta section
- S13: `wiki/entities/Eddie Prchal.md` and `wiki/entities/Andrew Prchal.md` created; entities/_index.md updated; index.md updated
- S17: `[[concepts/poam]]` added to concepts/_index.md Incident Management section

## [2026-04-16] lint | Auto-fix pass — 4 criticals resolved, 2 confirmed false positives

Fixed:
- C1: Removed dead link `[[concepts/LLM Wiki Pattern|How does the LLM Wiki pattern work]]` from `wiki/comparisons/Wiki vs RAG.md` frontmatter
- C2: Fixed 3 index entries — added `concepts/` prefix to `[[LLM Wiki Pattern]]`, `[[Hot Cache]]`, `[[Compounding Knowledge]]`
- C3: Added `status: stable` to `wiki/gunner/system-security-plan.md` and `wiki/summaries/cis-google-workspace-benchmark.md`
- C4: Added `created: 2026-04-14` to `wiki/entities/_index.md`, `wiki/getting-started.md`, `wiki/meta/dashboard.md`

False positives:
- C5: `[[page/name]]` / `[[other/page]]` in session note are inside fenced YAML code block — not live wikilinks
- C6: `[[dashboard.base]]` is a real .base file (Obsidian Bases); `[[page/name]]` in log.md is inside backtick inline code

Lint report: [[meta/lint-report-2026-04-16]] — 18 warnings and 18 suggestions remain for review.

## [2026-04-16] lint | Full vault health check — wiki/meta/lint-report-2026-04-16.md

69 pages scanned. 42 issues found: 6 critical, 18 warnings, 18 suggestions.

Key findings:
- 3 stale index entries (bare wikilinks missing concepts/ prefix: LLM Wiki Pattern, Hot Cache, Compounding Knowledge)
- 1 dead wikilink in comparisons/Wiki vs RAG (How does the LLM Wiki pattern work — page never existed)
- 5 pages missing required frontmatter fields (status or created)
- 3 near-orphan pages: concepts/poam, gunner/completed-projects, vendors/jamf
- 5 vendor/concept pages missing for frequently-mentioned items: Quote Portal (28x), Make.com (20x), SendGrid (18x), Bitdefender (10x), AWS Lambda (15x)
- 7 Gunner staff mentioned without entity pages (Eddie, Andrew Prchal, Glen, India, Sarah, Bryce, Mike Ushka)
- 2 dead links in meta infrastructure: dashboard.base (dashboard.md + log.md), placeholder links in session-2026-04-14-claude-obsidian.md

**Files written:**
- wiki/meta/lint-report-2026-04-16.md (timestamped copy)
- wiki/lint-report.md (overwritten with full report)

## [2026-05-01] ingest | Monday.com PM My Work view setup — 4 screenshots (boards, date, status, priority)

Created wiki/runbooks/monday-pm-my-work-view-setup.md — Customize panel settings for PM "My Work" view: boards (Project Take off, SM Ops Form Submission, *PM Change Order), date/status/priority column mappings per board. Updated wiki/index.md.

## [2026-05-01] update | GunnerTeam app — nav fix (Forms/Referrals), button press feedback, red nav titles, QR fullscreen, UserDetailView title, managerId save fix, Marketing dept

## [2026-05-01] update | getgunner.com — Cloudflare Pages deploy, favicon, sign-in modal JS fix, Enter key support, Cloudflare security hardening (HSTS, Bot Fight Mode, TLS 1.2+)

## [2026-05-01] update | GunnerTeam backend — D1 gunner-team-db created, schema migrated, wrangler.toml updated, bootstrap admin created (tyler), bootstrap endpoint removed

## [2026-04-24] save | Hexnode iPhone clipboard settings + Chrome ProfileSeparationSettings clarification

Updated vendors/hexnode.md — added full iPhone Business Container table (confirmed from xlsx); copy/paste from managed to unmanaged blocked on iPhone, not Mac.
Updated gunner/chrome-policy.md — ProfileSeparationSettings confirmed as "Suggest" (not enforce); no clipboard isolation on Mac from any policy in Gunner's stack.

## [2026-04-23] lint | Auto-fix pass — W1, C1, C2, C3

**W1 — hubspot-salesperson-sop added to index and linked from related pages:**
- wiki/index.md — added `[[gunner/hubspot-salesperson-sop]]` row to Gunner Operations table
- wiki/vendors/hubspot.md — added link in frontmatter related and Related section
- wiki/gunner/hubspot-leads-project.md — added link in frontmatter related and Related section
- wiki/gunner/hubspot-workflow-designs.md — added link in frontmatter related and Related section
- wiki/gunner/hubspot-salesperson-sop.md — frontmatter already contained correct related links; no change needed

**C1 — Added frontmatter to comparisons/Wiki vs RAG.md:**
- wiki/comparisons/Wiki vs RAG.md — added type, status, created, updated, tags; qualified bare wikilinks to concepts/ and entities/ paths

**C2 — Added frontmatter to meta/lint-report-2026-04-14.md:**
- wiki/meta/lint-report-2026-04-14.md — added title, type, created, updated, tags, status

**C3 — Fixed unqualified wikilinks across 7 pages:**
- `[[LLM Wiki Pattern]]` → `[[concepts/LLM Wiki Pattern]]`
- `[[Compounding Knowledge]]` → `[[concepts/Compounding Knowledge]]`
- `[[Hot Cache]]` → `[[concepts/Hot Cache]]`
- `[[Andrej Karpathy]]` → `[[entities/Andrej Karpathy]]`
- Pages fixed: comparisons/Wiki vs RAG.md, concepts/_index.md, concepts/Compounding Knowledge.md, concepts/Hot Cache.md, concepts/LLM Wiki Pattern.md, entities/Andrej Karpathy.md, getting-started.md
