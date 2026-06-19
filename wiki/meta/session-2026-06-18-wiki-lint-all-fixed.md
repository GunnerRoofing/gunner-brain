---
type: session
title: session-2026-06-18-wiki-lint-all-fixed
created: '2026-06-18'
updated: '2026-06-18'
tags:
  - meta
  - lint
  - vault
status: stable
related:
  - '[[meta/lint-report-2026-06-18]]'
  - '[[wiki/index]]'
  - '[[gunnerteam/overview]]'
  - '[[gunnerteam/aws-environment]]'
---

# Session: 2026-06-18 — Wiki Lint Pass (all 13 issues fixed)

**Date:** 2026-06-18  
**Vault size:** 227 notes, 28 folders  
**Full report:** [[meta/lint-report-2026-06-18]]

---

## What Was Found

13 issues across 8 categories. All resolved in the same session.

### Dead Links (3) — fixed
- `[[lint-report]]` in `tyler/index.md` → no such file existed. Updated to `[[meta/lint/lint-report-2026-06-13]]`.
- `[[meta/lint-report-2026-06-09]]` in `tyler/index.md` → no June 9 report exists. Replaced with the June 13 report + new June 18 report.
- `[[meta/lint/lint-report-2026-06-02]]` in `tyler/index.md` → file never existed in `wiki/meta/lint/`. Removed.

### Missing Sessions in wiki/index.md (3) — fixed
Sessions cc-766–788, cc-789–815, cc-815–842 existed in `wiki/meta/` but were never added to the top-level `wiki/index.md` Meta section. Added all three with descriptions.

### Stale Claims (3) — fixed

| Page | Was | Now |
|---|---|---|
| `wiki/hot.md` | `Lambda v233 live` | Removed version number; delegates to `[[tyler/hot]]` |
| `wiki/gunnerteam/overview.md` | `Lambda ~v140 live`, `release/3.0.0 frozen for App Store release` | Updated to v277; removed App Store branch note; added ABM distribution note |
| `wiki/gunnerteam/aws-environment.md` | `Live version: v127`; outdated deploy recipe | Updated to v277; replaced deploy recipe with corrected version |

**Deploy recipe fix (cc-867 learnings now in the wiki):**
The aws-environment.md deploy recipe now includes both hard-won corrections:
1. `rm -f /tmp/gunnerteam-deploy.zip` before every zip — `zip -r` merges into an existing archive
2. `--routing-config '{"AdditionalVersionWeights":{}}'` explicit JSON — the shorthand `AdditionalVersionWeights={}` is silently a no-op; prior canary weights persist and route 100% to old version

### Structural Issues (2) — fixed
- Duplicate vendor table in `tyler/index.md`: second 6-row copy removed.
- `wiki/hot.md` stale inline note `GunnerTeam Lambda: approximately v140` removed.

### Orphan Pages (2) — fixed
- `wiki/gunnerteam/CONTRIBUTING.md` — linked from `gunnerteam/overview.md` Related section.
- `wiki/gunnerteam/gamification-original-brief.md` — fixed dead internal link `[[wiki/gunnerteam/index]]` → `[[meta/session-2026-06-13-cc608-742-bundle-perf-gamification-ios-polish]]`; linked from `gunnerteam/overview.md`.

### Frontmatter Gaps (2) — fixed
- `wiki/index.md`: added `status: stable`, `tags: [index, vault]`, `updated: 2026-06-18`.
- `wiki/gunnerteam/overview.md`: added `updated: 2026-06-18`.

---

## Files Modified

| File | Change |
|---|---|
| `wiki/index.md` | Added 3 missing sessions; added lint report reference; added frontmatter fields |
| `wiki/hot.md` | Removed stale Lambda version; delegated to tyler/hot |
| `wiki/tyler/index.md` | Fixed 3 dead lint-report links; removed duplicate vendor table |
| `wiki/gunnerteam/overview.md` | Lambda v277; removed App Store note; added Related links; added `updated` |
| `wiki/gunnerteam/aws-environment.md` | v277; corrected deploy recipe; updated frontmatter |
| `wiki/gunnerteam/gamification-original-brief.md` | Fixed dead link; now reachable via overview |
| `wiki/log.md` | Lint entry added |

---

## Notes for Future Lint Passes

- **`gunner/` path prefix in tyler/index.md** — all `[[gunner/...]]` links resolve globally via Obsidian's filename search (the files live at `wiki/gunnerteam/`). Not dead, but technically using a stale path prefix. Low priority; would require rewriting ~30 index entries.
- **`wiki/tyler/meta/` is empty** — session notes live in top-level `wiki/meta/`. The empty directory is harmless; leave it.
- **50+ older session notes** not in any index — by design. Session notes don't need to be individually listed; they're discoverable via search.
