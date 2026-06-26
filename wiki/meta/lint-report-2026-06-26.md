---
type: meta
title: Lint Report 2026-06-26
created: '2026-06-26'
updated: '2026-06-26'
tags:
  - meta
  - lint
status: active
---

# Lint Report: 2026-06-26

## Summary
- Pages scanned: 314 (up from 308 last lint — 6 new session notes)
- Issues found: 25 (down from 35 last lint)
- Auto-fixable: 4 (ssp-addendum piped-backslash links)
- Needs review: 1 (dual-agent-workflow CLAUDE.md/Memory.md refs)
- Noise / historical: 20 (old lint reports + session notes documenting past issues)

**Improvement since 2026-06-25:** Orphans dropped from 12 → 0 (all 12 indexed). No new dead links in the 6 session notes added this session.

---

## Orphan Pages
**None.** All 12 orphans from the last lint were resolved (added to tyler/index.md). Zero orphans this run.

---

## Dead Links — Auto-fixable (4)

**`wiki/gunnerteam/ssp-addendum-1-product-environment.md` — piped backslash links:**

The previous lint fixed `[[shared/entities/Tyler Suffern\]]` (path-prefixed backslash), but left the piped variant `[[Tyler Suffern\|Tyler Suffern]]` (backslash before pipe). All four people links are affected:

| Current (broken) | Fix to |
|---|---|
| `[[Tyler Suffern\|Tyler Suffern]]` | `[[entities/Tyler Suffern\|Tyler Suffern]]` |
| `[[Eric Recchia\|Eric Recchia]]` | `[[entities/Eric Recchia\|Eric Recchia]]` |
| `[[Eddie Prchal\|Eddie Prchal]]` | `[[entities/Eddie Prchal\|Eddie Prchal]]` |
| `[[Andrew Prchal\|Andrew Prchal]]` | `[[entities/Andrew Prchal\|Andrew Prchal]]` |

Suggest: auto-fix (safe, exact substitution).

---

## Dead Links — Needs Review (2)

**`wiki/meta/dual-agent-workflow.md`:**
- `[[CLAUDE.md]]` and `[[Memory.md]]` — these reference files by their `.md`-suffixed names rather than as wikilinks. `CLAUDE.md` is gitignored by design; `Memory.md` lives at `wiki/tyler/Memory.md`. Both are likely prose references, not navigation links.
- Suggest: change to `[[Memory]]` for the vault file; leave `CLAUDE.md` as inline code `` `CLAUDE.md` `` since it's a repo file, not a wiki page.

---

## Dead Links — Historical Noise (not actionable)

These are in old lint reports and session notes *documenting* past issues — not actual live broken links in the vault:

**Old `[[gunner/...]]` prefix (8):** In `log.md`, `lint-report-2026-06-18`, `lint-report-2026-06-24`, `lint-report-2026-06-25`, `session-2026-06-18-wiki-lint-all-fixed`, `session-2026-06-25-cc2908-*` — these are historical documentation of the path restructure work.

**Template placeholders (19):** `[[page/name]]`, `[[wikilink]]`, `[[dashboard.base]]`, `[[runbooks/x]]` etc. in old session notes and lint reports.

**Old lint report cross-refs (22):** `[[meta/lint-report-2026-06-09]]`, `[[meta/lint-report-2026-06-02]]` etc. — reports that were never saved.

**`log.md` file-extension refs (3):** `[[hot.md]]`, `[[log.md]]`, `[[index.md]]` — very old log entries using `.md`-suffixed wikilinks. Harmless, historical.

**`claude-obsidian-ecosystem`, `How does the LLM Wiki pattern work` (multiple):** Concept pages mentioned in early session notes but never created. Low priority.

---

## Frontmatter Gaps (9 — same as previous lint)
All system/template files — no change needed:

| File | Missing fields |
|---|---|
| `wiki/hot.md` | `created`, `status`, `tags` |
| `wiki/log.md` | `created`, `status`, `tags`, `type`, `updated` |
| `wiki/tyler/hot.md` | `created`, `status`, `tags` |
| `wiki/colin/hot.md` | `created` |
| `wiki/doug/hot.md` | `created`, `status`, `tags` |
| `wiki/doug/index.md` | `created`, `status`, `tags` |
| `wiki/doug/overview.md` | `tags`, `updated` |
| `wiki/shared/api-contracts/_template.md` | `tags`, `updated` |
| `wiki/shared/decisions/000-template.md` | `created`, `tags`, `updated` |

---

## Empty Sections
289 detected — 274 are `log.md` entries (by design). Not actionable.

---

## Previous Issues — Resolved
- ✅ **12 orphan session notes** — all indexed in tyler/index.md
- ✅ `[[GunnerMasterDB-SOC2-Roadmap]]` in log.md + lint-report-2026-06-24 → `[[tyler/masterdb/soc2-roadmap]]`
- ✅ `session-2026-06-20-cc2016-banner-navbar` dead link removed from cc2017
- ✅ `[[shared/entities/X\]]` path+backslash format fixed in ssp-addendum
- ⚠️ `[[Tyler Suffern\|Tyler Suffern]]` piped-backslash format — still present (fix pending approval)
