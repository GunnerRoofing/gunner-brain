---
type: meta
title: "Lint Report 2026-05-27"
created: 2026-05-27
updated: 2026-05-27
tags:
  - meta
  - lint
status: complete
---

# Lint Report: 2026-05-27

## Summary
- Pages scanned: 169
- Issues found: 15 real issues (151 "empty sections" filtered — mostly log.md entries, expected)
- Auto-fixed: 0 (pending review)
- Needs review: 2 orphans

---

## Orphan Pages (2)
Pages with no inbound wikilinks.

- `meta/session-2026-05-21-masterdb-cutover-complete.md` — valid session note, no inbound links. Suggest: add to index.
- `meta/session-2026-05-26-cc-prompts-33-38-dual-camera-orientation.md` — displaced from index during recent edits. **Fix: add back to index.**

---

## Stale Index Entries (3)
Links in `wiki/index.md` pointing to non-existent pages.

- `[[Wiki Map]]` — canvas file, not a wikilink target. Remove from index.
- `[[canvases/main.canvas]]` — same. Remove from index.
- `[[meta/session-2026-05-19-masterdb-migration]]` — page was never created (migration session was filed differently). Remove from index.

---

## Missing from Index (2)
Session notes on disk not appearing in `wiki/index.md` due to edit displacement:

- `meta/session-2026-05-27-omp-plugins-cc51-53.md` — OMP 15.5.2 + plugin inventory + cc-51–53
- `meta/session-2026-05-26-cc-prompts-33-38-dual-camera-orientation.md` — dual-camera orientation series

---

## Dead Links (4 real, 5 historical)
After filtering template noise from old lint reports and log.md:

**Real (in content pages):**
- `[[canvases/main.canvas]]` in `index.md` — stale canvas reference
- `[[meta/session-2026-05-19-masterdb-migration]]` in `index.md` — page doesn't exist

**Historical (in old session notes — low priority):**
- `[[canvases/main.canvas]]` in `session-2026-05-15-compliance-apns` — old canvas ref
- `[[comparisons/claude-obsidian-ecosystem]]` in `session-2026-05-15-compliance-apns` — page deleted
- `[[dashboard.base]]`, `[[entities/Eric Recchia\]]`, `[[entities/Eddie Prchal\]]`, `[[entities/Andrew Prchal\]]` in `session-2026-05-15-lint-fix-pass` — escaped backslash wikilinks (malformed, but only in a lint fix session note, harmless)

---

## Frontmatter Gaps (4)
Operational files (`hot.md`, `log.md`, `index.md`, `lint-report.md`) intentionally lack frontmatter — excluded.

Real gaps in content pages:
- `meta/session-2026-05-22-ios-fixes-repo-cleanup.md`: missing `status`
- `meta/session-2026-05-15-photo-comments.md`: missing `status`
- `meta/session-2026-05-15-compliance-apns.md`: missing `status`
- `meta/session-2026-05-21-masterdb-cutover-complete.md`: missing `updated`

---

## Empty Sections
151 total detected — almost entirely in `log.md` (each log entry heading has sub-items, not paragraph content) and `hot.md` (operational files). No real content pages have empty sections. **No action needed.**

---

## Proposed Auto-Fixes

Safe to apply without review:
1. Add `session-2026-05-27-omp-plugins-cc51-53` and `session-2026-05-26-cc-prompts-33-38-dual-camera-orientation` back to `index.md`
2. Remove stale index entries: `[[Wiki Map]]`, `[[canvases/main.canvas]]`, `[[meta/session-2026-05-19-masterdb-migration]]`
3. Add `status: stable` to the 3 session pages missing it; add `updated: 2026-05-21` to masterdb-cutover-complete

Needs review before fixing:
- Orphan `session-2026-05-21-masterdb-cutover-complete.md` — confirm it should be in index or is intentionally isolated
