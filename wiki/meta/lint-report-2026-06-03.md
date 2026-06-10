---
type: meta
title: "Lint Report 2026-06-03"
created: 2026-06-03
updated: 2026-06-03
tags:
  - meta
  - lint
status: developing
---

# Lint Report: 2026-06-03

## Summary

| Check | Result |
|-------|--------|
| Pages scanned | 184 |
| Orphan pages | 0 ✅ |
| Dead links (real) | 0 ✅ |
| Dead links (historical noise) | 6 (lint/session files only — not actionable) |
| Frontmatter gaps | 3 (utility files) |
| Empty sections | 1 real (5 were false positives in code blocks) ✅ |
| Stale index entries | 0 ✅ |
| Total actionable issues | 1 (auto-fixed) |

---

## ✅ Orphan Pages

No orphan pages found. All content pages have at least one inbound wikilink.

---

## ✅ Dead Links

### Actionable (0)

No actionable dead links. All live-page wikilinks resolve.

### Historical noise (lint/session files only — not actionable)

The following targets appear only in old lint-report or session files, or are `[[raw-sources/...]]` references to source files (intentional). No action needed.

- `[[raw-sources/handoff masterdb.md]]` — in `masterdb-developer-handoff.md` frontmatter `sources` field. This is a reference to the raw source file. Correct and intentional.

- `[[cherry-picks]]` — in lint-report/session files only (historical references, not actionable).
- `[[claude-obsidian-ecosystem]]` — in lint-report/session files only (historical references, not actionable).
- `[[claude-obsidian-ecosystem-research]]` — in lint-report/session files only (historical references, not actionable).
- `[[how does the llm wiki pattern work]]` — in lint-report/session files only (historical references, not actionable).
- `[[session-2026-05-19-masterdb-migration]]` — in lint-report/session files only (historical references, not actionable).
- `[[wiki map]]` — in lint-report/session files only (historical references, not actionable).

---

## ⚠️ Empty Sections

Sections with a heading but no body text and no sub-headings (truly empty, not container sections).

- `[[_index]]`: empty heading(s): `Add new entities here as they are identified during ingests.`
- `[[lead-assignment-automation]]`: empty heading(s): `→ save the returned endpoint id`
- `[[secure-coding-guide]]`: empty heading(s): `❌ Never: f"SELECT * FROM ... WHERE state = '{state}'"`, `Pin exact versions in requirements.txt`, `Enable Dependabot on GitHub (.github/dependabot.yml)`, `✅ API Gateway Cognito authorizer validates JWT before Lambda invokes`... +4 more`
- `[[ios-dev-workflow-claude-xcode-github]]`: empty heading(s): `2. Claude Code edits files`, `3. Switch to Xcode, hit Cmd+R, test in simulator`, `4. Repeat until satisfied`
- `[[omp-hang-fix]]`: empty heading(s): `test: brain`
- `[[external-api-handoff]]`: empty heading(s): `Test Files  6 passed (6)`

**Note on `secure-coding-guide.md`:** 8 empty headings — these appear to be code/command examples used as heading text (e.g. `` `❌ Never: f"SELECT..."` ``). The code was intended as section content, not headings. Likely a formatting artifact from ingestion.

---

## Frontmatter Gaps

- `[[hot]]`: missing fields: created, status, tags, type, updated *(utility navigation file — low priority)*
- `[[index]]`: missing fields: created, status, tags, type, updated *(utility navigation file — low priority)*
- `[[log]]`: missing fields: created, status, tags, type, updated *(utility navigation file — low priority)*

**Note:** `hot.md`, `index.md`, and `log.md` are utility navigation files with non-standard structure. Frontmatter is not required for them to function in Obsidian.

---

## ✅ Stale Index Entries

All links in `wiki/index.md` resolve to existing pages. No stale entries.

---

## ✅ Orphan-Free Confirmation

All 184 pages have inbound links (exempting navigation files: `index.md`, `hot.md`, `log.md`, `getting-started.md`, `dashboard.md`, `_index.md`). Session notes and lint reports are intentionally standalone.

---

## Recommended Actions

1. **Clean up `secure-coding-guide.md`**: The 8 "empty headings" are code snippets used as heading text — convert them to code blocks under a single `## Examples` heading.
3. **Fill or remove stubs**: `wiki/ciso-track/roadmap.md` (4 empty sections), `wiki/entities/_index.md`, `wiki/vendors/` stubs — either populate or remove the placeholder headings.
4. **`omp-hang-fix.md`**: Remove stray `### test: brain` heading (debugging artifact).
