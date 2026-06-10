---
type: session
title: "Wiki Lint Run — 2026-06-03"
created: 2026-06-03
updated: 2026-06-03
tags:
  - meta
  - lint
  - wiki
status: evergreen
related:
  - "[[meta/lint-report-2026-06-03]]"
  - "[[concepts/LLM Wiki Pattern]]"
  - "[[meta/dashboard]]"
---

# Wiki Lint Run — 2026-06-03

Full automated health check of the Gunner Vault (184 pages). Run after the cc-126–147 iOS refactor session.

---

## Results Summary

| Check | Result |
|-------|--------|
| Pages scanned | 184 |
| Orphan pages | **0** ✅ |
| Dead links (real) | **0** ✅ |
| Stale index entries | **0** ✅ |
| Frontmatter gaps | **3** (hot/index/log — utility files) |
| Empty sections (real) | **1** (auto-fixed) |
| Total actionable | **1** |

Vault is in excellent shape.

---

## Methodology

Ran as a multi-cell Python eval workflow:

1. **Scout** — `VAULT.rglob('*.md')` → 184 files across 13 folders.
2. **Link map** — Parsed all `[[wikilinks]]` (1,187 total) with a stem→path index; built inbound-link map.
3. **Parallel checks** — 5 checks ran simultaneously:
   - Orphan pages (excluding navigation files and session notes by design)
   - Dead links (stem lookup against page map)
   - Frontmatter gaps (YAML parse, required fields: type, status, created, updated, tags)
   - Empty sections (heading regex over body-only text)
   - Stale index entries (parse `wiki/index.md` wikilinks)
4. **Triage** — Dead links split into: real vs lint-report-only noise vs template placeholders. Empty sections re-checked with scope-aware logic (container sections = heading followed immediately by sub-heading = not empty).
5. **False-positive discovery** — Second pass stripped code blocks before applying heading regex. 5 of 6 "empty sections" were `#`-prefixed bash/Python comments inside fenced code blocks misdetected as markdown headings.
6. **Auto-fix** — One genuine empty heading fixed in `entities/_index.md`.

---

## Key Finding: Lint Regex False Positive

**Problem:** A naive heading regex (`^#{1,4} .+`) matches `#`-prefixed comment lines inside fenced code blocks:

```python
# ❌ Never: f"SELECT * FROM ... WHERE state = '{state}'"
```

This line is a Python comment inside a ```` ```python ```` fence. It matches `^# ❌ Never...` as a heading. Same issue for bash:

```bash
# 2. Claude Code edits files
# test: brain
# → save the returned endpoint id
```

**Fix:** Strip fenced code blocks from the body before running heading detection:
```python
CODE_FENCE_RE = re.compile(r'```.*?```', re.DOTALL)
txt_body = CODE_FENCE_RE.sub('', txt_body)
```

**Lesson:** Always strip code fences before running structural analysis on markdown.

---

## The One Real Fix

`wiki/entities/_index.md` had a stray markdown section heading with no body:

```markdown
## Add new entities here as they are identified during ingests.
```

This was instruction text accidentally formatted as a heading. Fixed to:

```markdown
> [!note] Maintenance
> Add new entity pages here as they are identified during ingests.
```

---

## Folder Coverage

| Folder | Pages |
|--------|-------|
| meta | 62 |
| gunner | 33 |
| vendors | 18 |
| runbooks | 16 |
| concepts | 15 |
| summaries | 15 |
| entities | 6 |
| wiki (root) | 5 |
| questions | 5 |
| threats | 5 |
| ciso-track | 2 |
| comparisons | 1 |
| sources | 1 |

---

## Dead Link Noise (Historical, Not Actionable)

Six link targets appear only in old lint-report or session files — these are historical artifacts, not live page references:
- `[[claude-obsidian-ecosystem]]` — referenced in multiple old lint reports; page was never created (ingest never ran for that topic)
- `[[session-2026-05-19-masterdb-migration]]` — session note that lives outside the wiki vault (in `~/`)
- `[[wiki map]]` — canvas file, not a `.md` page
- `[[how does the llm wiki pattern work]]` — a questions-style link, never created as a page
- Plus 2 others (old escaped-link artifacts from early lint reports)

None require action.

---

## Report Location

[[meta/lint-report-2026-06-03]] — full findings with per-file detail.
