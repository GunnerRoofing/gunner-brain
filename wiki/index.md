---
type: index
updated: '2026-06-24'
owner: vault
status: stable
tags:
  - index
  - vault
created: '2026-04-10'
---

# gunner-brain — Master Index

Shared knowledge base for the Gunner Roofing engineering team. Start at [[hot]] for
current system state, then drill into the section you need.

## Team

| Person | Section | App | Description |
|---|---|---|---|
| Tyler Suffern | [[tyler/overview]], [[gunnerteam/overview]] | GunnerTeam iOS + IT/Ops | Vault owner. iOS app + Express/Lambda API, plus company IT & operations. |
| Colin | [[colin/overview]] | GunnerCam | Multi-tenant AWS / Next.js field-operations app. |
| Leo | [[leo/overview]] | gunner-ops | Job-lifecycle CRM, replacing Monday.com. |
| Doug | [[doug/overview]] | Lead Finder, Review Engine, Content Creator, WP Local Page Template | Four standalone apps. |

## App Sections

- [[tyler/overview]] — Tyler: IT / Ops.
- [[gunnerteam/overview]] — Tyler: GunnerTeam iOS app + API.
  - [[gunnerteam/system-security-plan]] — IT-SSP-001 (corporate IT boundary)
  - [[gunnerteam/ssp-addendum-1-product-environment]] — IT-SSP-001-A1 DRAFT (product environment; APP-01…APP-09; pending sign-off)
  - [[gunnerteam/soc2-accomplishments-2026-06]] — June 2026 implementation summary; reliability incidents; operating conventions
  - [[gunnerteam/soc2-technical-summary]] — SOC 2 technical control posture by TSC (cc-21xx work; 2026-06-20)
  - [[gunnerteam/security-compliance-roadmap]] — org-wide security/compliance roadmap (frameworks, SOC 2 process, Hexnode→Jamf, SIEM, CMMC, CISO cert track)
- [[colin/overview]] — Colin: GunnerCam.
- [[leo/overview]] — Leo: gunner-ops.
- [[doug/overview]] — Doug: Lead Finder, Review Engine, Content Creator, WP Local Page Template.

## Shared

Read by everyone; write with coordination.

- [[shared/gunner-platform-overview]] — high-level map of every application and shared infrastructure; written for infrastructure onboarding (as of 2026-06-29).
- [[shared/rds-proxy-tls-and-sst-python-packaging]] — RDS Proxy presents a PUBLIC-CA cert (trust public roots, not just the RDS regional bundle; verify-ca not verify-full); SST `bundle:` Python Lambdas install no deps + build in place — `hook.postbuild` uv install into gitignored `.deps/`, x86_64-pinned. Cross-app (comms-admin + gunnerteam-api).
- [[shared/api-contracts/README]] — cross-app API & event contracts (one file per integration).
- [[shared/decisions/README]] — architecture decision records (ADRs).
- [[shared/architecture/README]] — architecture diagrams and high-level design docs.
- `shared/entities/` — people, orgs, and shared entities.
- `shared/vendors/` — third-party vendor / API reference pages.

## Meta

- `meta/` — session notes (from `/save`) and lint reports (from `/lint`). Latest: [[meta/lint-report-2026-06-24]].
  - [[gunnerteam/meta/session-2026-06-30-cc2213-2215-orgname-join-fix-deploy-drift]] — 2026-06-30: `resolveOrgName` uuid=varchar join bug — `LEFT JOIN gt_org_theme t ON t.org_id = o.id` threw `operator does not exist: uuid = character varying` (organizations.id varchar vs gt_org_theme.org_id uuid), swallowed by catch → every white-label caller rendered `'your company'` (cc-2211 regression). Fix = `::text` cast + log-on-catch (cc-2213). Certs-omission deploy outage → rollback + patch-artifact recovery. fieldportal.js deployed≠git drift reconciled (cc-2214, orgscope false-positive annotated). README deploy zip fixed to whole-dir + certs/migrations guard (cc-2215). Lambda v421→v424.
  - [[gunnerteam/meta/session-2026-06-30-cc2211-3201-whitelabel-audit-flush]] — 2026-06-30: white-label copy de-hardcode (cc-2211 invite email + join push, v418; cc-2212 reset email + shared FROM/`<title>` param + invite/reset deep-link pages, v420) via `resolveOrgName`; audit flush-before-freeze (cc-3201 AsyncLocalStorage per-request queue bounded by `AUDIT_FLUSH_TIMEOUT_MS`, v421, SOC 2 CC7.2); + comms_admin_ro topology investigation (belongs on PROD `sczazkvf`; dev-named proxy fronts prod). Lambda v418→v421.
  - [[gunnerteam/meta/session-2026-06-30-cc3101-3103-weather-danger-engine]] — 2026-06-30: dangerous-weather alert engine (cc-3101 `evaluate.js` danger-only classifier + `weather-sweep` two-leg scheduler + APNs critical push + FORCE-RLS `gt_weather_alerts` upsert/close-out, provider flipped to NWS, v416) + read endpoints (cc-3103 ops poll `GET /weather/alerts/active` w/ `gtsk_` service-key scope + per-job badge `GET /weather/job/:jobId`, v417). Lambda v416→v417. Commits d3eb7d2, b9d95a1.
  - [[tyler/meta/session-2026-06-30-cc08-09-comms-admin-tls-packaging]] — 2026-06-30: comms-admin (SST/Python Lambda) DB TLS verify-full→verify-ca + the real fix (RDS **Proxy** presents a public-CA cert → `proxy-ca-bundle.pem` = RDS regional + public roots); brought the never-deployed dev stage to `/health` `db:ok` (cert-path, SST/CloudFront/vpc config, IAM SSM+KMS, public-subnet→private egress, cc-03 route-header reconstruction) (cc-08, `18a202b`); replaced vendored wheels with `hook.postbuild` uv packaging into gitignored `.deps/` + pyproject extra fixes (cc-09, `5aacc41`). Branch `cc-08-db-tls-verify-ca` (local).
  - [[tyler/meta/session-2026-06-29-cc2820-3002-comms-admin-full-stack]] — 2026-06-29/30: comms-admin full stack (cc-01–07, cc-2206 provisioning); iOS fixes (cc-3000/3001/3002 UploadOutbox race/black-thumbnails/discard); masterdb cc-2821 crm_activities.external_number + migration-graph CI guard PR #14; cc-2820 enrich updated_at; cc-2205 crew webhook. Lambda v404→v405.
  - [[gunnerteam/meta/session-2026-06-29-cc3100-3102-nws-weather-provider]] — 2026-06-29: Weather feature foundation (cc-3100 OpenWeather stack + route) + NWS provider + flip default (cc-3102). Lambda v400→v403. Free, no-key weather for CT/NJ jobs via api.weather.gov.
  - [[tyler/meta/session-2026-06-26-cc2807-2809-dialpad-updated-at-monitoring]] — 2026-06-26: Dialpad consumer-polling cursor (p21 `updated_at` + indexes, masterdb), app-side `updated_at` touches + `dialpad-health` task + CloudWatch metric (cc-2808), Terraform 4-alarm event-loss monitoring + PutMetricData IAM + hourly health schedule (cc-2809). Lambda v390.
  - [[tyler/meta/session-2026-06-24-cc1800-2157-llm-engine-b1-cutover]] — 2026-06-24: LLM engine (lib/llm.js, /assistant/run, Bedrock, assessTier, quote_advisor, service-key auth cc-1800–1806) + B1 cutover chain (Cognito tenantId mismatch, resolveUser fix, Tyler admin role cc-2152–2157).
  - [[meta/session-2026-06-19-cc1500-1505-terraform-infra-hardening]] — 2026-06-19: Lambda env drift → Terraform (11 keys, COMPANYCAM_API_KEY restored, NOTION_TOKEN pruned); REWARDS_ENABLED=true for dev; daily 90-day location prune (EventBridge); stash@{0} dropped; Aurora idle_in_tx 24h→30s; iOS receipt phantom row + editable total. Lambda v291→v294. Fixed null_resource canary-routing no-op bug.
  - [[meta/session-2026-06-18-cc1111-1126-receipt-scanner-phase2]] — 2026-06-18: Receipt scanner phase 2 (cc-1111–1126 + cc-1400): 502 fix, Sales Tax/Freight lines, trailing-minus detection, dual-image best-of OCR (original preferred, B&W only when clearly better and not garbled), cleanDescription rewrite (segment-split/longest-wins), verify UI (category grouping, compact fee rows, Items vs Receipt total reconciliation, multi-line descriptions), Requests row icon contrast. Lambda v283→v291.
  - [[meta/session-2026-06-19-cc1630-1634-alerting-terraform-ops]] — 2026-06-19: Google Chat alerts (await fix + ok_actions, v319); cc-1631 closed (DB clean); CLAUDE.md Lambda freeze + secret rules (cc-1632); regression probe 16/17 PASS (cc-1633); S3 WORM codified + VPC reconcile doc (cc-1634). OMP 16.1.6.
  - [[meta/session-2026-06-18-cc1100-1300-receipt-scanner-location-batch]] — 2026-06-18: Receipt scanner feature (VisionKit→ReceiptImageProcessor, Textract extract, commit+P&L push, verify screen, cc-1100–1110); location battery optimization + offline buffer + batch ingest (cc-1200–1202); address geocoding on PMLocationView (cc-1300). Lambda v279→v283.
  - [[meta/session-2026-06-18-wiki-lint-all-fixed]] — 2026-06-18: Wiki lint pass — 227 pages, 13 issues found and all fixed (3 dead links, 3 stale Lambda versions, 3 index gaps, 2 structural, 2 orphans, 2 frontmatter gaps). Deploy recipe corrected in aws-environment.md.
  - [[meta/session-2026-06-18-cc864-871-lockfix-ping-consent]] — 2026-06-18: Audit_log 12-min lock root cause (NodeJsExit + stranded Proxy txn, cc-864); silent-push debug chain (cc-865–870); /validate missing location_consent → device consent=false fixed (cc-867); PMLocationView 90s poll + map recenter + graceful fallback (cc-869); docs/gunnerteam-app-summary.md refreshed (cc-871). Lambda v275–v277 live.
  - [[meta/session-2026-06-17-cc815-842-compliance-refactor-service-keys]] — 2026-06-17: Location compliance system (consent column, PATCH /time/location-permission, GET /time/location-compliance); service key lifecycle (revoke/expire/last_used); iOS file structure sweep; CC/FP comments split; v252–v269 deployed.
  - [[meta/session-2026-06-16-cc789-815-location-forms-360gallery]] — 2026-06-16: Always-on PM locate; PMLocationView full-bleed map; Dumpster Swap + Material Shortage forms (Monday board 18406336489); 360 photo tagging + gallery confirm; geofences across 20 nearest jobs.
  - [[meta/session-2026-06-15-cc766-788-appstore-hardening-polish]] — 2026-06-15: App Store hardening and polish.
  - [[meta/session-2026-06-13-cc608-742-bundle-perf-gamification-ios-polish]] — 2026-06-13: Bundle perf investigation (v183–v220), gamification Phase 2–3 (achievements/leaderboard/redemption/payroll), iOS polish (cc-608–742), wiki lint auto-fix.
  - [[meta/session-2026-06-11-cc403-412-fleet-inspection-hub-polish]] — 2026-06-11: AuxComponents (StatusBadge, EmptyStateView, StickyEditBar, DestructiveConfirmSheet), aux screen UX sprint.
  - [[meta/session-2026-06-11-cc390-402-fleet-inspection-hub-polish]] — 2026-06-11: Fleet inspection single-camera, driver feedback, hub redesign, notification animation.
  - [[meta/session-2026-06-11-cc370-389-fieldportal-rename-fleet-ux]] — 2026-06-11: Field Portal rename (CC*→FP*, /companycam→/fieldportal), fleet UX.
  - [[meta/session-2026-06-11-cc369-393-time-tracking-geofence-travel]] — 2026-06-11: Time tracking, geofencing, travel GPS.
  - [[meta/session-2026-06-11-cc299-338-perf-polish-prod-infra]] — 2026-06-11: Perf sprint (ETag, cursor, N+1), prod Aurora seed, fleet time tracking.
  - [[meta/session-2026-06-10-omp-config-plugin-claudemd-merge]] — 2026-06-10: OMP config fixes, plugin refresh (aws-serverless, context7, stripe), CLAUDE.md merge from old vault.
  - [[meta/session-2026-06-10-save-skill-test]] — 2026-06-10: Save skill workflow test.
- [[log]] — append-only activity log across all sections.

## How This Vault Works

- **Each person owns their section.** Tyler owns `tyler/` and `gunnerteam/`; Colin owns
  `colin/`; Leo owns `leo/`; Doug owns `doug/`. `shared/` is read by all, written with
  coordination.
- **`/save`** files a session into your own section's `meta/`, updates your section's
  `hot.md` and `index.md`, and appends to the top-level `log.md`.
- **`/lint`** sweeps every section and writes a report to `meta/lint-report-YYYY-MM-DD.md`.
- Identity is declared per-checkout in `CLAUDE.local.md` (gitignored). The vault owner
  (Tyler) maintains the system-wide `hot.md` and `index.md`.
