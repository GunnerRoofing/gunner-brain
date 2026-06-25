---
type: index
title: Tyler Wiki Index
owner: tyler
created: '2026-05-22'
updated: '2026-06-24'
status: stable
tags:
  - index
  - tyler
---
# Wiki Index

Maintained by Claude. Updated on every ingest. Read this first when answering queries to find relevant pages.

## Gunner Operations

| [[tyler/meta/session-2026-06-25-bedrock-billing-qp-key-org-reconcile]] | cc-1807 half-flip recovery + atomic-role guardrail; cc-1808 QP draft key live (200/403); Bedrock INVALID_PAYMENT_INSTRUMENT → LLM_PROVIDER=anthropic bridge (v371); cc-2901 two-org RLS reconcile (69aad261 real / 7d6db1bb shell, Colin p17/p18) |
| [[tyler/meta/session-2026-06-24-cc1800-2157-llm-engine-b1-cutover]] | cc-1800–1806 (LLM engine: lib/llm.js, /assistant/run, Bedrock, assessTier, quote_advisor, service-key auth) + cc-2152–2157 (B1 cutover chain: proxy, Cognito tenantId mismatch root cause, resolveUser fix, Tyler admin role) |
| [[meta/session-2026-06-22-cc2133-2135-hygiene-key-voip]] | cc-2133–2135 + VOIP ingest: read-only account hygiene sweep (8 public Function URLs / 8 IAM static-key users / 8 untagged EC2 — 0 GunnerTeam), `gunner-fleet-worker-dev` key deactivated (delete after soak), A4 fieldportal diagnostic (we forward the user's own email at role=user, 0 projects — not our bug), VOIP/softphone research ingested |
| [[meta/session-2026-06-10-cc279-288-customer-photos-debug]] | cc-279–288: customer photo upload debug — PayloadTooLargeError root cause (Express 100kb→20mb), photoObj unwrap, source field null, Lambda v139; UI polish (haptics, photo cell hit area, Customer badge) |
| [[meta/session-2026-06-02-cc87-89-91-phase-workflow-models]] | cc-87, 89–91: CompletedTasksSheet, PhaseWorkflowModels (data layer), JobGuidedView, PhaseDetailView+PhaseItemGridCell |
| [[meta/session-2026-06-02-cc82-86-guided-tasks-complete]] | cc-82–86: highAlert tasks, GuidedJobsListView, list/grid toggle, TaskDetailSheet+uncheck, in-app task creation (v108) |
| [[meta/lint/lint-report-2026-06-10]] | Lint report 2026-06-10: pages scanned, orphans, dead links, index gaps |
| [[meta/session-2026-06-02-cc76-80-notion-workspace-soc2-fixes]] | cc-76–80: Notion workspace build (8 DBs, Tasks, notion-sync.js), SOC 2 #36 CompanyCam org scope, SOC 2 #37 fleet doc ownership + audit(), CLAUDE.md long-term context scaffolded |
| [[meta/session-2026-05-27-cc38-45-cc69-75-fleet-perf-webhooks]] | cc-38–45, 69–75: CompanyCam webhook push fix (user_devices), fleet perf sweep (query() migration, onAppear guards, indexes, Lambda migration runner), iOS doc upload fixes |
| [[meta/session-2026-05-27-cc64-67-password-policy-cognito-email]] | cc-64–67: password policy validation, Cognito SES email + branded template, admin reset Cognito sync, iOS hint text |
| [[meta/session-2026-05-27-cc57-63-invite-registration-fix]] | cc-57–63: invite/registration fix chain — missing columns, explicit id/timestamps on users INSERT, Cognito AdminCreateUser+SetUserPassword, IAM state drift fix, audit() orgId on unauthenticated endpoints |
| [[meta/session-2026-05-27-omp-plugins-cc51-53]] | OMP 15.5.2 + full plugin inventory (semgrep, github MCP, typescript-lsp, etc.) + cc-51 InspectionCameraSession, cc-52 steps race, cc-53 admin delete FK fix |
| [[meta/session-2026-05-26-cc-prompts-33-38-dual-camera-orientation]] | cc-prompts 33–38: dual-camera orientation fixes (BGRA pool, portrait, .oriented(.right)/.leftMirrored), GunnerTaskRow glassmorphism, async auth fixes |
| [[runbooks/omp-hang-fix]] | OMP hang fix — kill suspended processes holding lock; swarm extension incompatible with 15.4.1 |
| [[meta/session-2026-05-26-omp-reinstall]] | OMP v15.3.2 reinstall — full config, plugins, skills, MCP restored |
| [[meta/session-2026-05-22-gunnerteam-handoff]] | EOD handoff: corrected paths/scheme/auth, cc-27 nav regression, iOS patterns, Colin API, full backlog |
| [[meta/session-2026-05-22-cognito-auth-api-ios]] | cc-05+06: GunnerTeam API Cognito JWKS migration (410 login, requireAuth rewrite) + iOS Amplify auth (AuthManager rewrite, 53 callsites, forgot 2-step); user_devices NOT NULL fix deployed |
| [[meta/session-2026-05-22-apns-backlog-fixes]] | APNs stale token fix, user_devices updated_at constraint, Lambda alias deploy pattern, cc-29 nav revert |
| [[meta/session-2026-05-22-cc-prompt-26-27-announcements-omp]] | cc-26/27 hero image passthrough + static bg; announcements Post button + UUID decode fix; OMP full audit; repo cleanup |
| [[gunner/gunnerteam-project-structure]] | GunnerTeam monorepo layout — API routes, Swift files, sizes, hotspots, CLAUDE.md rules reference |
| [[concepts/omp-tasks-subagents]] | OMP tasks/subagents — mental model, agent types, when to use, subagents bar behavior |
| [[meta/session-2026-05-22-cc-prompt-25-colin-v2-api]] | cc-prompt-25: GunnerTask completedByEmail/completedAt added; companycam.js already correct; smoke test vs Colin's dev API passed |
| [[meta/session-2026-05-22-project-folder-migration]] | Project folder migration — all Gunner projects moved to ~/Documents/Gunner/; GunnerTeam/docs, cc-prompts, subportal/backend/db/scripts all verified |
| [[meta/session-2026-05-22-cc-prompt-24-branch-merge]] | cc-prompt-24: Three-branch merge (color-tokens + hero-bg + typed-tasks) into main; BUILD SUCCEEDED, 0 errors |
| [[meta/session-2026-05-22-schema-defaults-announcements-masterdb]] | Schema DEFAULT audit (35 migrations, 0 failures), announcements fix, masterdb architecture + secure coding guide ingested |
| [[meta/session-2026-05-21-gunnerteam-ios-feature-sprint]] | GunnerTeam iOS sprint: Guided Tasks feature, SFSpeechRecognizer voice comment, nav bar flash fix, branch merge strategy |
| [[meta/session-2026-05-21-post-cutover-stabilization]] | GunnerTeam API v51-v58: 17 schema migrations, s3.js SDK fix, UUID type fixes in iOS, pending inspections navCard, CLAUDE.md schema rules |

| Page | Description |
|------|-------------|
| [[gunner/environment]] | Network topology, devices, SaaS stack, office locations, personnel — anchor page |
| [[gunner/app-inventory]] | Full application inventory with SSO status and offboarding actions |
| [[gunner/system-security-plan]] | SSP summary — roles, incident response, POAM, data recovery |
| [[gunner/brand-colors]] | Gunner brand hex color palette |
| [[gunner/federal-market]] | Federal contract strategy — CMMC, surety bonding, Davis-Bacon, target facilities |
| [[gunner/completed-projects]] | Full completed IT project history — Stamford/NJ network, Keeper rollout, KnowBe4, Google Chat migration, VoIP audit |
| [[gunner/it-decision-log]] | IT governance record — security decisions, config changes, vendor decisions, exceptions (IT-GOV-LOG-001) |
| [[gunner/departmental-comms]] | Tool-to-use-case communications map — which tool for what by department |
| [[gunner/gunner-forms-privacy-policy]] | GunnerForms iOS app public privacy policy — zero data collection, App Store required |
| [[gunner/hubspot-workflow-designs]] | HubSpot workflow designs — lead rotation, owner sync, no-activity alerts for leads and deals |
| [[gunner/hubspot-sales-pipeline]] | HubSpot stale deal management — reports and workflows for 120-day no-activity deals |
| [[gunner/hubspot-leads-project]] | HubSpot Lead object buildout — lead stages, deal stages, QP sync, round robin, open to-do list |
| [[gunner/hubspot-salesperson-sop]] | HubSpot Sales Workspace SOP — salesperson guide for Leads, Deals, Tasks, Schedule tabs (IT-SOP-HUB-002) |
| [[gunner/dialpad-hubspot-integration]] | Dialpad → HubSpot integration architecture — webhook receiver design, call/SMS logging flows, open items |
| [[gunnerteam/voip-softphone-research]] | In-app softphone (voice+SMS/MMS) platform research — Telnyx recommended over Twilio/Amazon Connect as a Dialpad replacement; CallKit/PushKit is the biggest risk; CT all-party recording consent + per-tenant 10DLC gating |
| [[gunner/lead-assignment-automation]] | Round-robin lead assignment — Dialpad availability check, 5-min call window, manager escalation; scripts in `_system/lead-assignment/` |
| [[gunner/chrome-policy]] | Chrome Enterprise policy export (2026-04-14) — CIS gap analysis; Safe Browsing + HTTPS-Only closed; DevTools + DoH open |
| [[gunner/gunner-forms-app]] | Gunner Team iOS app — fleet management, vehicle inspections, maintenance tracking, CompanyCam integration, announcements, native forms; Express API on EC2 |
| [[gunner/software-suite]] | Full software suite overview — 8 platforms (QP, Ops Portal, GunnerCam, Sub Portal, Marketing, Customer App, Fleet, Global Users), white-label architecture, partner onboarding, urgent vs future features |
| [[gunner/gunner-assistant]] | Gunner Assistant AI knowledge base — Claude Projects vs custom API+RAG options; decision pending boss approval |
| [[gunner/claude-team-setup]] | Claude AI team setup — Claude.ai Team integrations (HubSpot ✅, GitHub ❌), Claude Code GitHub MCP setup |
| [[gunner/claude-session-onboarding]] | Claude session onboarding prompt — paste at session start to prime vault context, skills, and stack |
| [[gunner/aws-environment]] | AWS environment — EC2 api-user.php (HubSpot contact/deal creation from WordPress), Dev/Prod/QA/Staging accounts |
| [[meta/session-2026-05-22-feature-sprint-and-reorg]] | Session 2026-05-22: cc-21 typed tasks, cc-22 hero bg, cc-23 color tokens, subportal frontend scaffold, folder reorg |
| [[gunner/subportal-cc-prompt-02-frontend]] | Subportal React+Vite+Amplify+shadcn+MSW frontend — white-label CSS vars, contact-reveal audit pattern, mock dev workflow |
| [[gunner/subportal-cc-prompt-01-scaffold]] | Subcontractor Portal backend scaffold spec — Python/Lambda/SQLAlchemy/SST v3, models, auth, search (8-cap), Leo webhook HMAC |
| [[gunner/secure-coding-guide]] | OWASP Top 10 applied to Python/Lambda/Cognito/Aurora stack — pre-PR checklist, SOC 2 control map, Pydantic patterns |
| [[gunner/secrets-handling-rules]] | Secrets handling rules — SSM retrieval order, credential categories, rotation policy, SOC 2 alignment |
| [[gunner/gunnerteam-performance-standards]] | **REQUIRED READING** — GunnerTeam performance standards: query() vs queryWithTenant, N+1/LATERAL, pool max, indexes, onAppear guard, alias ARN rules |
| [[gunner/masterdb-architecture]] | masterdb platform architecture — Python Lambda + Aurora + Cognito + SST; replaces HubSpot/Monday/CompanyCam; multi-schema multi-tenant |
| [[gunner/masterdb-developer-handoff]] | masterdb developer handoff — live resources, tech stack, 13-table schema, API routes, deploy process, migration chain, tech debt |
| [[gunner/gunnerteam-api-aws-migration]] | GunnerTeam API migration — Express.js + RDS PostgreSQL live on EC2 (3.134.224.29); multi-tenancy, Terraform IaC, SaaS/compliance roadmap |
| [[gunner/tls-cutover-2026-05-14]] | TLS cutover 2026-05-14 — EC2 recreated, ALB + ACM TLS 1.3, HSTS, api.team.gunnerroofing.com canonical; open issues: SSM, SSH:22, Cloudflare token, pm2 wiring |

## Questions & Troubleshooting

| Page | Description |
|------|-------------|
| [[questions/app-store-guideline-4-8-webview-login]] | App Store Guideline 4.8 — WebView app login rejection fix; remove app-level sign-in UI |
| [[questions/hexnode-custom-app-deployment]] | Deploy a private App Store app through ABM → Hexnode without public App Store listing |
| [[questions/ios-dev-workflow-claude-xcode-github]] | iOS dev workflow — Claude Code edits files, Xcode builds, git tracks history, branches explained |
| [[questions/keeper-web-vault-login-loop]] | Keeper web vault login redirect loop in Chrome — diagnosis and fix steps |
| [[questions/claude-code-hook-tooluse-error]] | Claude Code startup hook ToolUseContext error — root cause, workarounds, version notes |

## Vendors

| Page | Description |
|------|-------------|
| [[vendors/hexnode]] | Hexnode MDM — iPhone and Mac policies (CIS IG1 and Total Lockdown), ABM integration, JAMF evaluation |
| [[vendors/google-workspace]] | Google Workspace — OU structure, Chrome policies, SSO/SCIM, email security, CIS control mapping |
| [[vendors/keeper]] | Keeper password manager — usage, offboarding role, admin notes |
| [[vendors/knowbe4]] | KnowBe4 phishing simulation — implementation, contract details, CIS 14.1 |
| [[vendors/dialpad]] | Dialpad VoIP — customer communication, VoIP audit history, OOO setup |
| [[vendors/dialpad-api-reference]] | Dialpad API v2 — webhooks, call/SMS payloads, contacts API, HubSpot integration build notes |
| [[vendors/hubspot-api-reference]] | HubSpot API — contact search by phone, call/note engagements, deal associations, auth |
| [[vendors/stripe-api-reference]] | Stripe API — auth, objects, errors, pagination, metadata, idempotency (Gunner CT Sandbox active) |
| [[vendors/monday-api-reference]] | Monday.com GraphQL API — search items by column, create/update items, column value formats |
| [[vendors/monday]] | Monday.com — operations PM, IT Dev board, Gunner Forms integration |
| [[vendors/hubspot]] | HubSpot CRM — sales pipeline, Lead object buildout, Google Chat integration |
| [[vendors/companycam]] | CompanyCam — field photo documentation; Gunner Team iOS integration; internal instance at companycam.dev.gunnerroofing.com |

## Concepts

| Page | Description |
|------|-------------|
| [[concepts/cis-ig1]] | CIS Controls v8.1.2 IG1 — Gunner's security baseline framework; control mapping; NIST CSF 2.0 alignment |
| [[concepts/nist-csf]] | NIST CSF 2.0 — six functions (GOVERN new), Profiles, Tiers; Gunner tier estimates; CISO-track study |
| [[concepts/cmmc]] | CMMC Level 1 — federal certification; Gunner's gap analysis and 4-phase process; AV gap is blocker |
| [[concepts/sso]] | Single Sign-On — Google as IdP, SSO app list, non-SSO offboarding risk |
| [[concepts/mfa]] | Multi-Factor Authentication — OU-based MFA settings, session durations, coverage gaps |
| [[concepts/email-security]] | Email security stack — DMARC p=reject, SPF, DKIM, MTA-STS, BIMI; SendGrid |
| [[concepts/apple-business-manager]] | Apple Business Manager — zero-touch provisioning with Hexnode DEP, Gunner Forms app |
| [[concepts/incident-response]] | Incident Response — authority, defined scenarios, POAM gaps, relevant threats |
| [[concepts/poam]] | Plan of Action and Milestones — open Gunner gaps, CMMC relationship, NIST alignment |
| [[concepts/soc2]] | SOC 2 — AICPA Trust Services Criteria, Type I/II, Gunner Phase 1 findings + Phase 2 open items |

## Threats

| Page | Description |
|------|-------------|
| [[threats/t1566-phishing]] | T1566 Phishing — Initial Access; KnowBe4, DMARC, Chrome Safe Browsing controls |
| [[threats/t1078-valid-accounts]] | T1078 Valid Accounts — credential abuse; offboarding gap, OneNote credential exposure |
| [[threats/t1110-brute-force]] | T1110 Brute Force — credential stuffing; MFA and Keeper as primary mitigations |
| [[threats/t1486-data-encrypted-for-impact]] | T1486 Ransomware — flat network and backup gap are primary exposure |
| [[threats/t1199-trusted-relationship]] | T1199 Trusted Relationship — contractor OU, Make.com, DevOps AWS exposure |

## Runbooks

| Page | Description |
|------|-------------|
| [[runbooks/onboarding]] | Full employee onboarding ("New Crew") — Google Workspace, devices, Keeper, apps, AUP |
| [[runbooks/offboarding]] | Full employee offboarding ("Kill-Switch") — account disable, device wipe, credential rotation |
| [[runbooks/incident-response]] | Incident Response — lost device, account compromise, ransomware procedures |
| [[runbooks/new-laptop-setup]] | Step-by-step MacBook enrollment via Hexnode and Apple Business Manager |
| [[runbooks/new-phone-setup]] | Step-by-step iPhone enrollment via Hexnode and Apple Business Manager |
| [[runbooks/acceptable-use-policy]] | AUP summary — device ownership, tech stack, AI policy, incident reporting |
| [[runbooks/it-comms-style-guide]] | 4-tier IT communication system (RED/ORANGE/BLUE/GREEN) with templates |
| [[runbooks/monday-pm-my-work-view-setup]] | Monday.com PM My Work view — boards, date, status, and priority column settings |
| [[runbooks/dialpad-out-of-office]] | Dialpad OOO setup — vacation status, DND, SMS auto-reply, personal working hours |
| [[runbooks/hubspot-google-chat]] | HubSpot Google Chat notifications — connect app, map email, configure notification preferences |
| [[runbooks/starship-transfer]] | Transfer Starship prompt config to a new Mac — MesloLGS NF font, shell init, iTerm2 troubleshooting |
| [[runbooks/mac-tool-setup]] | Full stack setup on a new Mac — iTerm2, MesloLGS NF, Starship, Claude Code, Obsidian, one-liner install |
| [[runbooks/aws-iam-least-privilege]] | AWS IAM least-privilege runbook — IAM policy design, SOC 2 CC6.3, role patterns for Lambda and CI/CD |
| [[runbooks/chrome-safesites-policy]] | Chrome SafeSites filter diagnosis — Google Admin CBCM policy, BlockList vs SafeSites, fix procedure |
| [[runbooks/iterm2-nerd-fonts-omp-setup]] | iTerm2 Nerd Fonts + OMP setup — MesloLGM Nerd Font Mono v3, powerline config, glyph troubleshooting |

## CISO Track

| Page | Description |
|------|-------------|

## Summaries

| Page | Description | Source |
|------|-------------|--------|
| [[summaries/it-governance]] | Google Workspace OU design, Chrome CIS policies, app SSO inventory | Gunner IT Governance.xlsx |
| [[summaries/system-security-plan]] | SSP key contents, POAM items | System Security Plan.docx |
| [[summaries/my-notebook-gunner-roofing]] | OneNote quick-notes export — Dialpad OOO, HubSpot pipeline, brand color conflict flag | My Notebook @ Gunner Roofing.pdf |
| [[summaries/cmmc-level1-assessment-guide]] | CMMC L1 Assessment Guide v2.0 — 17 practices, 6 domains, scoring, Gunner gap analysis | AG_Level1_V2.0_FinalDraft_20211210_508.pdf |
| [[summaries/nist-csf-2]] | NIST CSF 2.0 — six functions, GOVERN, Profiles, Tiers, CIS Controls alignment | NIST.CSWP.29.pdf |
| [[summaries/cis-controls-v8-1-2]] | CIS Controls v8.1.2 — 18 controls, NIST CSF 2.0 GOVERN mapping added | CIS Controls Guide + XLSX |
| [[summaries/cis-google-workspace-benchmark]] | CIS Google Workspace v1.3.0 — L1/L2 recommendations, Gunner gap analysis | CIS_Google_Workspace_Foundations_Benchmark_v1.3.0.pdf |
| [[summaries/cis-chrome-enterprise-benchmark]] | CIS Chrome Enterprise Core v1.0.0 — first dedicated benchmark; sign-in, extensions, GenAI | CIS_Google_Chrome_Enterprise_Core_Browser_Benchmark_v1.0.0.pdf |
| [[summaries/cis-ios-26-benchmark]] | CIS iOS 26 v1.0.0 — institutionally-owned device profile; passcode gap identified | CIS_Apple_iOS_26_Benchmark_v1.0.0.pdf |
| [[summaries/cis-macos-26-benchmark]] | CIS macOS 26 Tahoe v1.0.0 — 7 sections; sharing, logging, FileVault, MDM | CIS_Apple_macOS_26_Tahoe_Benchmark_v1.0.0.pdf |
| [[summaries/cis-ms-office-benchmark]] | CIS Microsoft Office Enterprise v1.2.0 — macro security, Protected View (study ref, low Gunner relevance) | CIS_Microsoft_Office_Enterprise_Benchmark_v1.2.0.pdf |
| [[summaries/keeper-workshop]] | Keeper staff training — master password, security audit, priority accounts to rotate | Keeper Workshop.pptx |
| [[summaries/project-assigned-webhook-receiver-spec]] | project.assigned webhook receiver contract — HMAC-SHA256 sig, PM-only filter, APNs push, 3s timeout | project-assigned-webhook-receiver-spec.md |
| [[summaries/white-label-agenda]] | White-label SaaS agenda — partner Q&A, 8-platform feature matrix, system-of-truth assignments | white label agenda.xlsx |
| [[summaries/external-api-handoff]] | Project Hub external API — 7 endpoints, auth, 3-step S3 upload, comment threads + replies, gap list, dev fixtures (verified 2026-05-15) | EXTERNAL_API_HANDOFF.local.md |

## Canvases

| Canvas | Description |
|--------|-------------|
| *(Canvas files — open in Obsidian directly)* | `wiki/Wiki Map.canvas` — visual vault overview |

## Meta

| Page | Description |
|------|-------------|
| [[meta/lint-report-2026-06-24]] | Lint report 2026-06-24 — 32 issues (current) |
| [[meta/lint-report-2026-06-18]] | Lint report 2026-06-18 — 13 issues |
| [[meta/lint/lint-report-2026-06-13]] | Lint report 2026-06-13 — 31 issues |
| [[meta/lint-report-2026-06-18]] | Lint report 2026-06-18 — 227 pages, 13 issues (3 dead links, 3 stale claims, 3 index gaps, 2 structural, 2 orphans, 2 frontmatter gaps) |
| [[meta/session-2026-06-08-cc167-233-ios-tab-markup-themes]] | Session 2026-06-08 — cc-167–233: 4-tab architecture, PhotoMarkupEditor UIKit inset fix, ThemeManager Gunner teal, 360 photo capture, scroll-aware titles, Lambda v127, OMP 15.10.4 |
| [[meta/session-2026-06-04-cc148-193-ios-co-fixes]] | Session 2026-06-04 — cc-148–193: guided job overhaul, CO flow, home screen redesign, FAB, Lambda v119 |
| [[meta/session-2026-06-04-cc148-160-ios-co-fixes]] | Session 2026-06-04 — cc-148–160: field task fixes, PDF CO form, leads nearby, phase workflow |
| [[meta/session-2026-06-03-wiki-lint-run]] | Wiki lint run 2026-06-03 — 184 pages, 7 auto-fixes |
| [[meta/session-2026-06-03-omp-update-config]] | OMP update + config 2026-06-03 — 15.2.4→15.8.3, memories/rewind enabled, S3 staging bucket |
| [[meta/session-2026-06-03-cc126-147-ios-refactor-splits-fixes]] | Session 2026-06-03 — cc-126–147: 5 file splits, folder reorg, fleet fixes, markup toolbar, photo fixes |
| [[meta/session-2026-05-27-cc54-56-admin-delete-fk-sweep]] | Session 2026-05-27 — cc-54–56: admin delete user FK sweep (5 deploys, 10 NULL-outs, audit_log preserved) |
| [[meta/session-2026-05-26-dual-camera-avassetwriter-crash-fix]] | Session 2026-05-26 — AVAssetWriter crash fix: startSession missing, stopRecording teardown race |
| [[meta/session-2026-05-26-cc-prompts-39-50-guided-tasks-camera]] | Session 2026-05-26 — cc-39–50: guided tasks camera rebuild, UIImagePickerController, shutter positioning |
| [[meta/session-2026-05-21-masterdb-cutover-complete]] | Session 2026-05-21 — masterdb cutover complete: all 7 migrations applied, import succeeded |
| [[meta/session-2026-05-22-ios-fixes-repo-cleanup]] | iOS fixes (hero image passthrough, announcements UUID bug), gunner-ios repo cleanup, Cognito auth smoke test |
| [[gunner/subportal-cognito-auth]] | Subportal Cognito auth — pool live, SSM params, Tyler's user, adding future users, what was removed |
| [[meta/omp-config-full-audit-2026-05-22]] | OMP config full schema audit — dead key removed, status bar redesigned (git+context_pct+cost), 9 new settings, dark-tokyo-night theme |
| [[meta/omp-config-tuning-2026-05-22]] | OMP config tuning — task/commit model roles added, memory pipeline tuned for daily multi-session workflow |
| [[meta/session-2026-05-19-omp-finalization]] | Session 2026-05-19 — ansi-dark theme fix, git branch cleanup (8 deleted, compliance merged), shell aliases, DB migration handoff doc |
| [[meta/session-2026-05-19-omp-professional-setup]] | Session 2026-05-19 — OMP config finalized: ansi-dark theme, powerline footer, sonnet-4-6 default, 3 custom skills (obsidian-second-brain, hindsight, discovery-mode) |
| [[meta/session-2026-05-19-omp-plugins-themes]] | Session 2026-05-19 — OMP plugin installation (powerline-footer, obsidian-context, swarm), bun runtime, 3 custom ANSI themes (ansi-dark, gruvbox-dark, dracula) |
| [[meta/session-2026-05-19-photo-comments-ui]] | Session 2026-05-19 — Photo comments UI v1.2 + v2 (tab separation, activity row thumbnail, border reactivity, count badges), job comment button, vault .claude/context/ setup |
| [[meta/session-2026-05-15-lint-fix-pass]] | Session 2026-05-15 — Wiki lint fix pass: C1/C2/W2/W6/W7 applied; Tyler Suffern + soc2 pages created; dialpad + ciso-track confirmed as false positives |
| [[meta/session-2026-05-15-compliance-apns]] | Session 2026-05-15 (cont.) — Compliance audit P0+P1 fixes, legacy EC2+ALB destroyed, APNs #11 fixed (APNS_KEY_CONTENT from SSM), PRs 1+2 pushed |
| [[meta/session-2026-05-15-photo-comments]] | Session 2026-05-15 (cont.) — Photo comments v1+v1.1, Lambda alias + provisioned concurrency, webhook refactor for multiple event types, CompanyCam 401 diagnosis |
| [[meta/session-2026-05-15-co-upload-fix]] | Session 2026-05-15 — CO upload fix (malformed Content-Disposition), Terraform branch-mismatch lesson, branch cleanup, login timeout investigation started |
| [[meta/session-2026-05-14-soc2-phase1]] | Session 2026-05-14 — SOC 2 Phase 1: audit logging (33 events), RDS exposure fix, secrets → SSM Parameter Store, .env deleted |
| [[meta/session-2026-05-12-companycam-s13]] | Session 2026-05-12 — CompanyCam feature S13: 4-tab JobDetailView (Activity/Photos/Comments/Files), upload flow, QuickLook, camera fixes |
| [[meta/session-2026-05-13-gunner-assistant-branch-mgmt]] | Session 2026-05-13 — Gunner Assistant RAG chatbot, branch strategy, iOS patterns, trademark update, white-label suite velocity |
| [[meta/dual-agent-workflow]] | Protocol for interleaved use of Claude Code and Gemini CLI |
| [[meta/gunnerforms-auth-build-2026-04-28]] | GunnerForms auth system build session — D1 schema, Resend setup, worker auth routes complete |
| [[meta/session-2026-04-21-gunnerforms-raw-sources]] | Session 10 — GunnerForms 4.8 fix + resubmission, raw-sources batch ingest, raw-sources reorg |
| [[meta/session-2026-04-17-lint-fix-pass]] | Lint auto-fix pass — W1–W9, W18, S2–S6, S8, S11, S13, S17; 6 new pages created |
| [[meta/session-2026-04-14-claude-obsidian]] | claude-obsidian install — skills, agents, hooks, CLAUDE.md rewrite, frontmatter convention |
| [[meta/session-2026-04-14b-setup-chrome]] | Vault setup completion (MCP, plugins, hooks wired) + Chrome policy CIS gap analysis |
| [[meta/vault-commands-reference]] | Commands reference and weekly maintenance schedule |
| [[meta/boss-setup-guide]] | Fresh claude-obsidian vault setup guide for new users (plugin install method) |
| [[meta/claude-obsidian-setup-guide]] | claude-obsidian install session notes — skills, hooks, CLAUDE.md setup |
| [[meta/dashboard]] | Live dashboard — Bases + Dataview queries across all wiki sections |
| [[meta/lint-report-2026-06-18]] | Running lint report — 2026-06-18 (227 pages, 13 issues) |
| [[sources/_index]] | Index of all ingested source summaries, organized by category |
| [[getting-started]] | Vault onboarding and quick start guide |

## Concepts (Knowledge Management)

| Page | Description |
|------|-------------|
| [[concepts/LLM Wiki Pattern]] | The Karpathy pattern this vault is built on — persistent compounding knowledge base |
| [[concepts/Hot Cache]] | Session context optimization — wiki/hot.md loads at session start |
| [[concepts/Compounding Knowledge]] | Why the wiki pattern produces more value over time |
| [[concepts/_index]] | Full concepts index |

## Vendors

| Page | Description |
|------|-------------|
| [[vendors/jamf]] | JAMF Pro — under evaluation as MDM alternative; Chrome Enterprise Core is the key gate |
| [[vendors/quote-portal]] | Quote Portal — quote customization tool; stub |
| [[vendors/make-com]] | Make.com — HubSpot → Google Chat automation; stub |
| [[vendors/sendgrid]] | SendGrid — transactional email; stub |
| [[vendors/bitdefender]] | Bitdefender GravityZone — AV/EDR candidate; CMMC blocker; stub |
| [[vendors/cloudflare]] | Cloudflare — DNS, Pages, legacy Workers/D1 (migrating to AWS), WAF |
| [[vendors/stripe]] | Stripe — payments platform; planned for invoicing + white-label billing (stub) |
| [[vendors/docusign]] | DocuSign — e-signature; heavily used for customer contracts, change orders, HR docs |

## Comparisons

| Page | Description |
|------|-------------|
| [[comparisons/Wiki vs RAG]] | Why a persistent wiki beats RAG at human scale |

## Entities

| Page | Description |
|------|-------------|
| [[entities/_index|Entities Index]] | People, Organizations, and Products hub |
| [[entities/Andrej Karpathy]] | AI researcher; originator of the LLM Wiki pattern |
| [[entities/Eddie Prchal]] | Co-owner of Gunner Roofing; authorizing official for the SSP |
| [[entities/Andrew Prchal]] | Co-owner of Gunner Roofing; authorizing official for the SSP |
| [[entities/Eric Recchia]] | VP of Strategy; System Owner (SSP); IR backup responder |
| [[entities/Tyler Suffern]] | IT Support & System Administrator; sole IT admin; vault owner |
| [[entities/Colin]] | Colin — GunnerCam/CompanyCam integration owner; phase API and 360 photo contract (stub) |
| [[entities/Leonard]] | Leonard (aka Leo) — LeoPortal owner; holds masterdb repo/DB credentials |
| [[entities/Ruchir]] | Ruchir — former developer; Quote Portal owner; no longer engaged as of 2026-06-09 |
