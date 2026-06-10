---
title: "Lint Report 2026-04-21"
type: meta
tags: [meta, lint, health-check]
created: 2026-04-21
updated: 2026-04-21
status: evergreen
related:
  - "[[index]]"
  - "[[lint-report]]"
  - "[[meta/lint-report-2026-04-16]]"
---

# Lint Report — 2026-04-21

**Generated:** 2026-04-21 (session 9 — post-upgrade, hook error documented)
**Scope:** Full wiki/ directory
**Pages scanned:** 77 (excluding hot.md, log.md, index.md)
**Previous report:** [[meta/lint-report-2026-04-16]]

---

## Summary

| Check | Issues |
|-------|--------|
| Orphan pages | 3 (2 fixable, 1 cosmetic) |
| Dead links | 0 |
| Duplicate index sections | 1 (fixable) |
| Frontmatter gaps | 2 (fixable) |
| Unqualified wikilinks | 4 (fixable) |
| Canvas files unindexed | 3 (needs review) |
| Content gaps (deferred) | Carried from prior lint |

**Auto-fixable:** 8 issues across 4 files — safe to apply.

---

## W1 — Duplicate Index Section

**File:** `wiki/index.md`

The index has two overlapping sections for the same page:
- **"Questions & Troubleshooting"** (lines 25–31) — current; lists both `keeper-web-vault-login-loop` and `claude-code-hook-tooluse-error`
- **"Questions"** (lines 121–126) — legacy; only lists `keeper-web-vault-login-loop`

The old "Questions" section is a stale leftover and should be removed. `keeper-web-vault-login-loop` is already covered by the new section.

**Fix:** Remove lines 121–126 from `wiki/index.md`.

---

## W2 — Orphan Pages (Not in Index)

### wiki/lint-report.md

The running lint report file exists at the wiki root but has no index entry. It is referenced by its own frontmatter cross-links but is not discoverable from the index.

**Fix:** Add to Meta section: `| [[lint-report]] | Running lint report — current health status; timestamped copies in meta/ |`

### wiki/entities/_index.md

The entities hub page is not listed in the index (only the three individual entity pages are). This page serves as the navigation hub for the Entities section.

**Fix:** Add to Entities section: `| [[entities/_index\|Entities Index]] | People, Organizations, and Products hub |`

### meta/lint-report-2026-04-14.md and meta/lint-report-2026-04-16.md

Archived timestamped lint reports. Not in index. These are intentionally archival and cross-referenced from `wiki/lint-report.md`. No action needed — acceptable as archival.

---

## W3 — Canvas Files Not Indexed

Three canvas files exist and are not in the index:

| File | Location |
|------|----------|
| `wiki/Wiki Map.canvas` | Wiki root |
| `wiki/canvases/main.canvas` | canvases/ |
| `wiki/canvases/welcome.canvas` | canvases/ |

**Needs review:** Are these active canvases in use? If so, add a Canvases section to the index. If `Wiki Map.canvas` is outdated, consider archiving.

---

## W4 — Unqualified Wikilinks

### questions/claude-code-hook-tooluse-error.md

```yaml
related:
  - "[[claude-team-setup]]"   ← should be "[[gunner/claude-team-setup]]"
```

**Fix:** Qualify the wikilink with folder path.

### entities/_index.md

Three unqualified wikilinks inconsistent with vault convention:

| Current | Should Be |
|---------|-----------|
| `[[Andrej Karpathy]]` | `[[entities/Andrej Karpathy]]` |
| `[[LLM Wiki Pattern]]` | `[[concepts/LLM Wiki Pattern]]` |
| `[[hot]]` | `[[hot]]` ← acceptable; hot.md is at wiki root |

**Fix:** Qualify two wikilinks in entities/_index.md body.

---

## W5 — Non-Standard Status Value

**File:** `wiki/gunner/hubspot-workflow-designs.md`

```yaml
status: in-progress   ← not in standard vocab
```

Standard values: `developing`, `stable`, `evergreen`, `seed`, `archived`, `mature`

**Fix:** Change to `status: developing`.

---

## Carried Over (Deferred)

These were noted in the 2026-04-16 lint and remain open by choice:

- **W6** (content gap): `entities/_index.md` — Organizations and Products sections are empty HTML-comment placeholders. Will fill as new entities are identified.
- **S1** (missing stubs): Glen, India, Sarah, Bryce, Mike Ushka lack entity pages. Deferred pending content.
- **W10–W14** (content gaps): Empty sections in several vendor/runbook/CIS summary pages. Content pending.

---

## No Issues Found

- **Dead links:** 0 — all wikilinks in index resolve to existing files
- **Stale claims:** None detected
- **Frontmatter coverage:** 95%+ — title, type, tags, created, updated, status present on all active pages
- **Cross-references:** Well-maintained bidirectional linking; index serves as hub
