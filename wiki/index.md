---
type: index
updated: '2026-06-18'
owner: vault
status: stable
tags:
  - index
  - vault
---

# gunner-brain — Master Index

Shared knowledge base for the Gunner Roofing engineering team. Start at [[hot.md]] for
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

- [[shared/api-contracts/README]] — cross-app API & event contracts (one file per integration).
- [[shared/decisions/README]] — architecture decision records (ADRs).
- [[shared/architecture/README]] — architecture diagrams and high-level design docs.
- `shared/entities/` — people, orgs, and shared entities.
- `shared/vendors/` — third-party vendor / API reference pages.

## Meta

- `meta/` — session notes (from `/save`) and lint reports (from `/lint`). Latest: [[meta/lint-report-2026-06-19]].
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
- [[log.md]] — append-only activity log across all sections.

## How This Vault Works

- **Each person owns their section.** Tyler owns `tyler/` and `gunnerteam/`; Colin owns
  `colin/`; Leo owns `leo/`; Doug owns `doug/`. `shared/` is read by all, written with
  coordination.
- **`/save`** files a session into your own section's `meta/`, updates your section's
  `hot.md` and `index.md`, and appends to the top-level `log.md`.
- **`/lint`** sweeps every section and writes a report to `meta/lint-report-YYYY-MM-DD.md`.
- Identity is declared per-checkout in `CLAUDE.local.md` (gitignored). The vault owner
  (Tyler) maintains the system-wide `hot.md` and `index.md`.
