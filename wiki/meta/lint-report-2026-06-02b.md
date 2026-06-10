---
type: meta
title: "Lint Report 2026-06-02 (run 2)"
created: 2026-06-02
updated: 2026-06-02
tags:
  - meta
  - lint
status: stable
---

# Lint Report: 2026-06-02 (run 2)

## Summary
- Pages scanned: 182
- Issues found: 6
- Auto-fixed: 2
- Needs review: 4

---

## Orphan Pages

_None. All pages have at least one inbound link._

---

## Dead Wikilinks (4)

- `[[handoff masterdb]]` in `wiki/gunner/masterdb-developer-handoff.md`
- `[[How does the LLM Wiki pattern work]]` in `wiki/meta/session-2026-06-02-cc87-89-91-phase-workflow-models.md`
- `[[claude-obsidian-ecosystem]]` in `wiki/meta/session-2026-06-02-cc87-89-91-phase-workflow-models.md`
- `[[handoff masterdb]]` in `wiki/meta/session-2026-06-02-cc87-89-91-phase-workflow-models.md`

> **Note:** Three of these appear in the new session note `session-2026-06-02-cc87-89-91-phase-workflow-models.md` as historical documentation of what the previous lint found — they reference `[[claude-obsidian-ecosystem]]`, `[[How does the LLM Wiki pattern work]]`, and `[[handoff masterdb]]`. The fourth (`[[handoff masterdb]]` in `masterdb-developer-handoff.md`) may not have had the prior fix applied successfully.

---

## Frontmatter Gaps

- `wiki/meta/session-2026-05-19-omp-finalization.md`: missing `title`
- `wiki/meta/session-2026-05-19-omp-professional-setup.md`: missing `title`

> **Fixed.** Both files had `type: meta` (not `type: session`) so the prior regex substitution never matched. Title field added directly.
>
> **Session note dead links (3):** `[[handoff masterdb]]`, `[[How does the LLM Wiki pattern work]]`, `[[claude-obsidian-ecosystem]]` in the cc-87/89-91 session note are inside backtick prose descriptions of prior lint fixes. They do not render as live links in Obsidian — benign false positives in historical text. No fix needed.

---

## Stale Index Entries

_None. All index.md wikilinks resolve to existing pages._

---

## Empty Sections (26 across 3 files)

Top files:

**`wiki/log.md`**: `## [2026-04-10] ingest | Gunner brand colors — created wiki/gunner/brand-colors.md`, `## [2026-04-10] migration | Converted index.md, log.md, ciso-track/roadmap.md from RTF to markdown`, `## [2026-04-10] setup | Vault initialized — CLAUDE.md, Memory.md, index.md created`, `## [2026-04-13] ingest | CMMC Presentation.txt — federal market strategy; created concepts/cmmc.md and gunner/federal-market.md; moved to study/`, `## [2026-04-13] ingest | IT_Tasks_1775773048.xlsx — full completed Monday IT task history (Nov 2025–Apr 2026); created gunner/completed-projects.md; updated environment.md (NJ network), app-inventory.md (Make.com, GoTo, Sendgrid, Owl); moved to runbooks/`, `## [2026-04-13] ingest | Stripe API Reference.pdf — Stripe sandbox reference for Gunner CT; Stripe added to app-inventory; test API key flagged (store in Keeper)`, `## [2026-04-13] lint | Lint pass completed — report at wiki/lint-report.md; no broken links; onboarding/offboarding runbooks created; missing vendor pages (Dialpad, Monday, HubSpot) flagged`, `## [2026-04-13] new | runbooks/onboarding.md and runbooks/offboarding.md created`, `## [2026-04-13] update | JAMF status corrected — under evaluation (approval expected late April 2026), not rejected. Chrome Enterprise Core compatibility is the key technical gate.`, `## [2026-04-14] save | Session note filed — wiki/meta/session-2026-04-14b-setup-chrome.md`, `## [2026-04-14] save | Session note — claude-obsidian install and customizations filed at wiki/meta/session-2026-04-14-claude-obsidian.md`, `## [2026-04-17] save | Session note — wiki/meta/session-2026-04-17-lint-fix-pass.md`, `## [2026-04-24] lint | Session 14 full pass — 90 pages, 3 issues (8 orphans, 28 unlinked mentions, 1 malformed anchor)`, `## [2026-04-24] lint-fix | W4 + W7m resolved — 28 unlinked mentions wikilinked across 5 pages; malformed pipe in index.md fixed; W1 false positive (all 8 pages already in index.md)`, `## [2026-04-24] save | runbook — Transfer Starship prompt config to new Mac (MesloLGS NF, zshrc init, iTerm2 font troubleshooting)`, `## [2026-04-24] save | runbook — mac-tool-setup: iTerm2 + Starship + Claude Code + Obsidian full stack install guide`, `## [2026-04-24] save | session 14 end — hot cache updated; 3 lint issues open (W1/W4/W7m); mac-tool-setup genericized for sharing`, `## [2026-04-24] update | runbook — mac-tool-setup: added full Claude-Obsidian brain usage section`, `## [2026-04-27] update | gunner/gunner-forms-app — major architecture update: Cloudflare Worker routes, native IT Request + Change Order forms, user/project typeahead, file upload, version scheme, branch strategy`, `## [2026-04-28] save | session — GunnerForms auth system build: D1 schema, Resend setup, worker auth routes complete; iOS screens + admin bootstrap pending`, `## [2026-04-28] update | gunner/gunner-forms-app — updated version approved (native IT Request + Change Order via Cloudflare Worker)`, `## [2026-05-01] update | GunnerTeam app — nav fix (Forms/Referrals), button press feedback, red nav titles, QR fullscreen, UserDetailView title, managerId save fix, Marketing dept`, `## [2026-05-01] update | GunnerTeam backend — D1 gunner-team-db created, schema migrated, wrangler.toml updated, bootstrap admin created (tyler), bootstrap endpoint removed`, `## [2026-05-01] update | getgunner.com — Cloudflare Pages deploy, favicon, sign-in modal JS fix, Enter key support, Cloudflare security hardening (HSTS, Bot Fight Mode, TLS 1.2+)`

**`wiki/entities/_index.md`**: `## Add new entities here as they are identified during ingests.`

**`wiki/hot.md`**: `## [2026-05-21] Chrome Policy Diagnosis`

