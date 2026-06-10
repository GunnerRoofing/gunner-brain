---
type: meta
title: Lint Report 2026-05-23
created: '2026-05-23'
updated: '2026-05-23'
tags:
  - meta
  - lint
status: evergreen
---

# Lint Report: 2026-05-23

## Summary
- Pages scanned: 161
- Issues found: 0 real (1 known false positive carry-over)
- Auto-fixed: 0
- Needs review: 0

**Vault is clean.**

---

## Confirmed False Positive (carry-over from 2026-05-22)

`[[meta/session-2026-05-19-masterdb-migration]]` is referenced in `index.md` but the file lives at the vault root `/meta/` (not `wiki/meta/`). Obsidian resolves wikilinks by stem and finds the file correctly — no broken link in practice. Index entry already annotated with `*file at vault root /meta/*` in the 2026-05-22 fix pass.

**No action needed.**

---

## Delta Since Last Lint (2026-05-22)

New pages added today:
- `[[meta/session-2026-05-22-cognito-auth-api-ios]]` — cc-05/06/06b + debugging, all wired correctly
- `[[meta/session-2026-05-22-gunnerteam-handoff]]` — EOD handoff with overrides, all wired correctly
- `[[meta/omp-config-tuning-2026-05-22]]` — OMP settings decision

All new pages:
- Have complete frontmatter ✅
- Are linked from `index.md` ✅
- Are linked from `wiki/hot.md` or other pages ✅

---

## Prior Lint Comparison

| Category | 2026-05-22 | 2026-05-23 | Delta |
|---|---|---|---|
| Orphan pages | 0 (after fix) | 0 | — |
| Real dead links | 0 (after fix) | 0 | — |
| Frontmatter gaps | 0 (after fix) | 0 | — |
| Stale index entries | 1 (annotated) | 1 (same) | — |
