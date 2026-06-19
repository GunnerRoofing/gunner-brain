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
