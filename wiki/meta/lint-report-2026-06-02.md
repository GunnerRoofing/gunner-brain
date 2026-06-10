---
type: meta
title: "Lint Report 2026-06-02"
created: 2026-06-02
updated: 2026-06-02
tags:
  - meta
  - lint
status: stable
---

# Lint Report: 2026-06-02

## Summary
- Pages scanned: 180
- Issues found: 158
- Auto-fixed: 7
- Needs review: 055

---

## Orphan Pages
Pages with no inbound wikilinks (excluding intentionally standalone: index, hot, log).

- `wiki/meta/session-2026-05-21-masterdb-cutover-complete.md` (`[[session-2026-05-21-masterdb-cutover-complete]]`): no inbound links. Suggest: link from a related page or delete if outdated.

---

## Dead Wikilinks
Links that reference pages that do not exist.

- `[[How does the LLM Wiki pattern work]]` referenced in `wiki/log.md` — page does not exist. Suggest: create stub or remove link.
- `[[handoff masterdb]]` referenced in `wiki/gunner/masterdb-developer-handoff.md` — page does not exist. Suggest: create stub or remove link.
- `[[claude-obsidian-ecosystem]]` referenced in `wiki/meta/session-2026-05-15-compliance-apns.md` — page does not exist. Suggest: create stub or remove link.

> **Note:** 58 additional apparent dead links were triaged as false positives: backslash-escape artifacts in older lint reports, template placeholder links (`[[name]]`, `[[page]]`), and links in old lint report files. These do not need fixing.

---

## Frontmatter Gaps
Pages missing required fields.

- `wiki/lint-report.md`: missing `created, status, tags, title, type, updated`
- `wiki/meta/session-2026-05-19-omp-finalization.md`: missing `title`
- `wiki/meta/session-2026-05-19-omp-professional-setup.md`: missing `title`

---

## Empty Sections
151 empty `##` sections across 79 files. Top files listed below.

**`wiki/log.md`** (24 empty headings):
  - `## [2026-04-10] ingest | Gunner brand colors — created wiki/gunner/brand-colors.md`
  - `## [2026-04-10] migration | Converted index.md, log.md, ciso-track/roadmap.md from RTF to markdown`
  - `## [2026-04-10] setup | Vault initialized — CLAUDE.md, Memory.md, index.md created`
  - `## [2026-04-13] ingest | CMMC Presentation.txt — federal market strategy; created concepts/cmmc.md and gunner/federal-market.md; moved to study/`
  - `## [2026-04-13] ingest | IT_Tasks_1775773048.xlsx — full completed Monday IT task history (Nov 2025–Apr 2026); created gunner/completed-projects.md; updated environment.md (NJ network), app-inventory.md (Make.com, GoTo, Sendgrid, Owl); moved to runbooks/`
  - `## [2026-04-13] ingest | Stripe API Reference.pdf — Stripe sandbox reference for Gunner CT; Stripe added to app-inventory; test API key flagged (store in Keeper)`
  - `## [2026-04-13] lint | Lint pass completed — report at wiki/lint-report.md; no broken links; onboarding/offboarding runbooks created; missing vendor pages (Dialpad, Monday, HubSpot) flagged`
  - `## [2026-04-13] new | runbooks/onboarding.md and runbooks/offboarding.md created`
  - `## [2026-04-13] update | JAMF status corrected — under evaluation (approval expected late April 2026), not rejected. Chrome Enterprise Core compatibility is the key technical gate.`
  - `## [2026-04-14] save | Session note filed — wiki/meta/session-2026-04-14b-setup-chrome.md`
  - `## [2026-04-14] save | Session note — claude-obsidian install and customizations filed at wiki/meta/session-2026-04-14-claude-obsidian.md`
  - `## [2026-04-17] save | Session note — wiki/meta/session-2026-04-17-lint-fix-pass.md`
  - `## [2026-04-24] lint | Session 14 full pass — 90 pages, 3 issues (8 orphans, 28 unlinked mentions, 1 malformed anchor)`
  - `## [2026-04-24] lint-fix | W4 + W7m resolved — 28 unlinked mentions wikilinked across 5 pages; malformed pipe in index.md fixed; W1 false positive (all 8 pages already in index.md)`
  - `## [2026-04-24] save | runbook — Transfer Starship prompt config to new Mac (MesloLGS NF, zshrc init, iTerm2 font troubleshooting)`
  - `## [2026-04-24] save | runbook — mac-tool-setup: iTerm2 + Starship + Claude Code + Obsidian full stack install guide`
  - `## [2026-04-24] save | session 14 end — hot cache updated; 3 lint issues open (W1/W4/W7m); mac-tool-setup genericized for sharing`
  - `## [2026-04-24] update | runbook — mac-tool-setup: added full Claude-Obsidian brain usage section`
  - `## [2026-04-27] update | gunner/gunner-forms-app — major architecture update: Cloudflare Worker routes, native IT Request + Change Order forms, user/project typeahead, file upload, version scheme, branch strategy`
  - `## [2026-04-28] save | session — GunnerForms auth system build: D1 schema, Resend setup, worker auth routes complete; iOS screens + admin bootstrap pending`
  - `## [2026-04-28] update | gunner/gunner-forms-app — updated version approved (native IT Request + Change Order via Cloudflare Worker)`
  - `## [2026-05-01] update | GunnerTeam app — nav fix (Forms/Referrals), button press feedback, red nav titles, QR fullscreen, UserDetailView title, managerId save fix, Marketing dept`
  - `## [2026-05-01] update | GunnerTeam backend — D1 gunner-team-db created, schema migrated, wrangler.toml updated, bootstrap admin created (tyler), bootstrap endpoint removed`
  - `## [2026-05-01] update | getgunner.com — Cloudflare Pages deploy, favicon, sign-in modal JS fix, Enter key support, Cloudflare security hardening (HSTS, Bot Fight Mode, TLS 1.2+)`

**`wiki/vendors/dialpad-api-reference.md`** (7 empty headings):
  - `## Authentication`
  - `## Call Event Subscriptions`
  - `## Calls API`
  - `## Contacts API`
  - `## HubSpot Integration — Build Notes`
  - `## SMS Event Subscriptions`
  - `## Webhooks`

**`wiki/meta/lint-report-2026-05-15.md`** (5 empty headings):
  - `## Dead Links — C (Critical / Broken)`
  - `## Dead Links — W (Warning)`
  - `## Missing Cross-References — W`
  - `## Orphan Pages — W`
  - `## Stale Claims — C/W`

**`wiki/gunner/gunner-forms-app.md`** (4 empty headings):
  - `## Bug Fixes (2026-05-12)`
  - `## Maintenance Bug Fixes & Enhancements (2026-05-11, session 11)`
  - `## Vehicle Inspection & Fleet Management (updated 2026-05-11)`
  - `## Vehicle Maintenance & Other Documents (added 2026-05-11)`

**`wiki/runbooks/it-comms-style-guide.md`** (3 empty headings):
  - `## Quick Reference`
  - `## Sending Rules`
  - `## Standardized Section Labels`

**`wiki/meta/lint-report-2026-04-14.md`** (3 empty headings):
  - `## Critical (must fix)`
  - `## Suggestions (worth considering)`
  - `## Warnings (should fix)`

**`wiki/meta/lint-report-2026-04-16.md`** (3 empty headings):
  - `## Critical (must fix)`
  - `## Suggestions (worth considering)`
  - `## Warnings (should fix)`

**`wiki/meta/lint-report-2026-04-23.md`** (3 empty headings):
  - `## Critical (must fix)`
  - `## Suggestions (worth considering)`
  - `## Warnings (should fix)`

**`wiki/meta/lint-report-2026-05-07.md`** (3 empty headings):
  - `## Critical (must fix)`
  - `## Suggestions (worth considering)`
  - `## Warnings (should fix)`

**`wiki/meta/lint-report-2026-05-12.md`** (3 empty headings):
  - `## Critical (must fix)`
  - `## Suggestions (worth considering)`
  - `## Warnings (should fix)`

**`wiki/ciso-track/roadmap.md`** (3 empty headings):
  - `## Certifications`
  - `## Resources & Reading`
  - `## Skill Domains`

**`wiki/meta/session-2026-05-27-cc38-45-cc69-75-fleet-perf-webhooks.md`** (3 empty headings):
  - `## CompanyCam Webhook Push Fixes (cc-38–40)`
  - `## Fleet Performance Fixes (cc-69–75)`
  - `## iOS Fleet Fixes (cc-41–45)`

**`wiki/runbooks/acceptable-use-policy.md`** (2 empty headings):
  - `## 4. Acceptable & Unacceptable Use`
  - `## 5. Artificial Intelligence (AI) Tools`

**`wiki/gunner/gunnerteam-performance-standards.md`** (2 empty headings):
  - `## Backend — Node.js / Lambda / Aurora`
  - `## iOS — SwiftUI`

**`wiki/vendors/hexnode.md`** (2 empty headings):
  - `## Mac Policies`
  - `## iPhone Policies`

**`wiki/hot.md`** (2 empty headings):
  - `## Session Changes (2026-05-19 — Photo Comments UI + Job Comment Button)`
  - `## [2026-05-21] Chrome Policy Diagnosis`

**`wiki/gunner/hubspot-leads-project.md`** (2 empty headings):
  - `## Lead Source Flows`
  - `## Step-by-Step Sandbox Build`

**`wiki/meta/lint-report-2026-04-21.md`** (2 empty headings):
  - `## W2 — Orphan Pages (Not in Index)`
  - `## W4 — Unqualified Wikilinks`

**`wiki/vendors/monday-api-reference.md`** (2 empty headings):
  - `## 4. Update Column Values`
  - `## Integration Flow for Dialpad`

**`wiki/meta/omp-config-full-audit-2026-05-22.md`** (2 empty headings):
  - `## All Changes Made`
  - `## What Was Wrong Before`

**`wiki/runbooks/omp-hang-fix.md`** (2 empty headings):
  - `## Fix Procedure`
  - `## Root Causes (in order of likelihood)`

**`wiki/meta/session-2026-05-15-lint-fix-pass.md`** (2 empty headings):
  - `## Fixes Applied`
  - `## New Pages Created`

**`wiki/meta/session-2026-05-15-photo-comments.md`** (2 empty headings):
  - `## Photo Comments v1`
  - `## Photo Comments v1.1`

**`wiki/meta/session-2026-05-19-photo-comments-ui.md`** (2 empty headings):
  - `## Photo Comment Reactivity Fixes (fix/photo-comments-ui-v2)`
  - `## Photo Comments UI Fixes (fix/photo-comments-ui)`

**`wiki/meta/session-2026-05-22-apns-backlog-fixes.md`** (2 empty headings):
  - `## APNs Push Notification Fix`
  - `## user_devices updated_at Constraint Fix`

_...and 54 more files with empty sections._

---

## Stale Index Entries

_None found. All index.md wikilinks resolve to existing pages._

---

## Notes
- **Stale claims** and **missing cross-references** not run — require semantic analysis; flag for a future deep-lint pass.
- **Style check** not run — requires reading every page; flag for a future pass.
- Empty sections in `wiki/summaries/cis-*.md` and `wiki/vendors/dialpad-api-reference.md` are scaffolded stubs awaiting content. Most actionable targets are in `wiki/gunner/` and `wiki/runbooks/`.
