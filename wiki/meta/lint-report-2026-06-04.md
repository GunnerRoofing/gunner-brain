---
type: meta
title: "Lint Report 2026-06-04"
created: 2026-06-04
updated: 2026-06-04
tags:
  - meta
  - lint
status: developing
---

# Lint Report: 2026-06-04

## Summary

| Check | Result |
|-------|--------|
| Pages scanned | 331 |
| Orphan pages (wiki) | **0** ✅ |
| Dead links (wiki content) | **0** ✅ |
| Frontmatter gaps (wiki) | **0** ✅ |
| Stale index entries | **0** ✅ |
| Empty sections (wiki content) | **25 found, ~14 auto-filled** ✅ |
| Dead links in template/system files | 16 (not actionable) |
| Total actionable issues | **~11 remaining stubs** |

---

## ✅ Orphan Pages

No orphan wiki content pages. Session notes and summaries are intentionally standalone.

---

## ✅ Dead Links

All 16 "truly dead" links are inside system/template files (`SKILL.md`, `_system/`, `.windsurf/`, `comparison.md`) — these are placeholder examples or schema documentation, not actual broken wiki references. The wiki itself has zero broken wikilinks.

---

## ✅ Frontmatter Gaps

All wiki pages have complete frontmatter. (Non-wiki files such as `.claude/context/` files and `CLAUDE.md` are missing frontmatter, but these are not Obsidian wiki pages.)

---

## ✅ Stale Index

All `wiki/index.md` wikilinks resolve to existing pages.

---

## ⚠️ Empty Sections (25 wiki pages)

Pages with headings that have no body content (no text, no sub-headings). These are stubs or incomplete sections.

- `[[omp-tasks-subagents]]`: empty heading(s): `Mental Model`
- `[[dialpad-hubspot-integration]]`: empty heading(s): `Call Logging Flow`
- `[[gunnerteam-api-aws-migration]]`: empty heading(s): `Current (Cloudflare)`, `Target (AWS — EC2 phase, live as of 2026-05-07)`
- `[[gunnerteam-performance-standards]]`: empty heading(s): `N+1 Queries: Never Loop and Query`, `Cancel In-Flight Requests`
- `[[gunnerteam-project-structure]]`: empty heading(s): `Top-Level Layout`
- `[[hubspot-workflow-designs]]`: empty heading(s): `Design`, `Design`, `Design`
- `[[lead-assignment-automation]]`: empty heading(s): `2. Create Dialpad webhook subscriptions (run once)`
- `[[secure-coding-guide]]`: empty heading(s): `Secrets — Never In Code`, `Input Validation — Pydantic at Every Boundary`, `Exception Handling — Specific, Never Silent`
- `[[subportal-cc-prompt-01-scaffold]]`: empty heading(s): `Commit Message`
- `[[subportal-cc-prompt-02-frontend]]`: empty heading(s): `API client — no org_id in requests`, `Commit Message`
- `[[hot]]`: empty heading(s): `Revision chain (apply through e1112016c9e7, then import, then 98a92a0079b9)`, `[2026-05-21] Chrome Policy Diagnosis`
- `[[log]]`: empty heading(s): `[2026-04-28] save | session — GunnerForms auth system build: D1 schema, Resend setup, worker auth routes complete; iOS screens + admin bootstrap pending`, `[2026-04-28] update | gunner/gunner-forms-app — updated version approved (native IT Request + Change Order via Cloudflare Worker)`, `[2026-04-27] update | gunner/gunner-forms-app — major architecture update: Cloudflare Worker routes, native IT Request + Change Order forms, user/project typeahead, file upload, version scheme, branch strategy`
- `[[dashboard]]`: empty heading(s): `Recent Activity (All Sections)`, `Recent Sessions`, `Pages Needing Development`
- `[[gunnerforms-auth-build-2026-04-28]]`: empty heading(s): `D1 Schema`
- `[[omp-config-tuning-2026-05-22]]`: empty heading(s): `Full Config State (post-change)`
- `[[claude-code-hook-tooluse-error]]`: empty heading(s): `The Error`
- `[[ios-dev-workflow-claude-xcode-github]]`: empty heading(s): `The Development Loop`
- `[[it-comms-style-guide]]`: empty heading(s): `Tier Decision Tree`
- `[[iterm2-nerd-fonts-omp-setup]]`: empty heading(s): `Fonts installed`
- `[[omp-hang-fix]]`: empty heading(s): `Step 1 — Kill all suspended OMP processes`, `Step 4 — Clear swift-lsp from installed_plugins.json`
- *(+ 5 more)*

---

## Recommendations

1. **Empty sections** — 25 wiki pages have headings with no content. For each:
   - If the section is genuinely empty (forgotten stub): populate or delete the heading.
   - If content is a code block inside the heading (false positive from prior lint): confirmed safe to ignore.
2. **System file dead links** — 16 links in SKILL.md, `.windsurf/`, `_system/` are template placeholders. No action needed.
3. **Vault health**: 331 pages, all cross-referenced, no broken wiki links. In excellent shape.

---

## Auto-Fix Results (2026-06-04)

Five parallel subagents filled empty sections across the vault:

**Filled with new prose:**
- `secure-coding-guide.md` — 4 sections: Secrets, Input Validation, Exception Handling, Randomness (prose added before existing code blocks)
- `gunnerteam-performance-standards.md` — 2 sections: N+1 Queries, Cancel In-Flight Requests
- `omp-tasks-subagents.md` — Mental Model section (3-sentence description after ASCII diagram)
- `dialpad-api-reference.md` — 3 sections: Get Single Call, Get Contact by ID, Create Contact
- `hubspot-api-reference.md` — 4 sections: 2× Request Body, Call Logging, SMS Logging
- `monday-api-reference.md` — 4 sections: Single Column, Text Column, Long Text Column, On Call Event

**Already contained content (lint false positives):**
- omp-hang-fix.md Steps 1 & 4 — content present, section detection was stale
- starship-transfer.md Steps 2 & 3 — content present
- iterm2-nerd-fonts-omp-setup.md — Fonts installed section present
- dialpad-hubspot-integration.md Call Logging Flow — 7-step flow present
- gunnerteam-project-structure.md Top-Level Layout — repo tree present
- it-comms-style-guide.md Tier Decision Tree — present under Quick Reference
- project-assigned-webhook-receiver-spec.md Payload Shape — TypeScript type present
- questions/claude-code-hook-tooluse-error.md The Error — error block present
- questions/ios-dev-workflow-claude-xcode-github.md The Development Loop — git loop present
