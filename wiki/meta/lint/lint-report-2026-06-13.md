---
type: meta
title: Lint Report 2026-06-13
created: '2026-06-13'
updated: '2026-06-13'
tags:
  - meta
  - lint
status: complete
---

# Lint Report: 2026-06-13

## Summary
- Pages scanned: 214
- Issues found: 31
- Auto-fixed: 0
- Needs review: 31

---

## Orphan Pages (6)
Session files from cc-11 sprint missing from `index.md`:

- `meta/session-2026-06-11-cc299-338-perf-polish-prod-infra.md` — not linked anywhere. Suggest: add to index.md recent sessions list.
- `meta/session-2026-06-11-cc369-393-time-tracking-geofence-travel.md` — same.
- `meta/session-2026-06-11-cc370-389-fieldportal-rename-fleet-ux.md` — same.
- `meta/session-2026-06-11-cc390-402-fleet-inspection-hub-polish.md` — same.
- `meta/session-2026-06-11-cc403-412-fleet-inspection-hub-polish.md` — same.
- `meta/lint/lint-report-2026-06-10.md` — previous lint report not linked from index or dashboard.

---

## Dead Links (13)

| Dead Link | Source | Note |
|---|---|---|
| `[[ciso-track/roadmap]]` | 9 pages across concepts/, summaries/, gunnerteam/ | Folder never created; planned CISO track abandoned. Remove or create stub. |
| `[[meta/lint-report-2026-06-09]]` | log.md, tyler/index.md | Wrong path. Current report is at `meta/lint/lint-report-2026-06-10.md`. |
| `[[meta/lint-report-2026-06-02]]` | tyler/index.md, session file | Old report; path no longer matches. |
| `[[meta/lint-report-2026-06-04]]` | session file | Same. |
| `[[meta/lint-report-2026-05-15]]` | session file | Same. |
| `[[dashboard.base]]` | log.md | `.base` files are not `.md`; Obsidian bases not linkable as wikilinks. Remove. |
| `[[ciso-track/cissp]]` | log.md | Never created. Remove or create stub. |
| `[[page/name]]`, `[[other/page]]`, `[[Page Name]]` | log.md, 2 session files | Template placeholders left in content. Remove. |
| `[[How does the LLM Wiki pattern work]]` | session file | Planned question page never created. Create stub or remove. |
| `[[meta/session-2026-05-19-masterdb-migration]]` | tyler/hot.md | Session file doesn't exist (was it saved under a different name?). |
| `[[handoff masterdb]]` | session file | No matching page. Possibly `masterdb-developer-handoff`. |
| `[[claude-obsidian-ecosystem]]` | session file | Planned comparison page never created. |
| `[[raw-sources/handoff masterdb.md]]` | gunnerteam/masterdb-developer-handoff.md | `raw-sources/` folder doesn't exist in vault. |

---

## Root-Level Strays (2)

- `Gamify Gunner App.md` — ungrouped note at vault root, not inside `wiki/`. Suggest: ingest into `wiki/gunnerteam/gamification.md` or delete if superseded by cc-603–712 gamification work.
- `Untitled.md` — empty note at vault root. Delete.

---

## Frontmatter Gaps (15 pages)

Pages missing required fields (`type`, `status`, `created`):

- `log.md` — no frontmatter at all (intentional append-only log; low priority)
- `tyler/hot.md` — no frontmatter (intentional hot cache; low priority)
- `tyler/index.md` — no frontmatter
- `wiki/hot.md`, `wiki/index.md` — missing `status`, `created`
- `doug/hot.md`, `doug/index.md` — missing `status`, `created`
- `leo/hot.md`, `leo/index.md` — missing `status`, `created`
- `colin/hot.md`, `colin/index.md` — missing `status`, `created`
- `shared/decisions/README.md` — missing `status`, `created`
- `shared/architecture/README.md` — missing `status`, `created`
- `shared/api-contracts/README.md` — missing `status`, `created`
- `shared/decisions/000-template.md` — missing `created`

---

## Empty Sections (notable)

- `doug/hot.md` — sections "Current Focus", "Recent Changes", "Active Issues", "Key Decisions" all empty. Doug's wiki is unpopulated.
- `doug/index.md` — app sections (Lead Finder, Review Engine, Content Creator, WP Local Page Template) all empty.
- `log.md` — many 2026-04 entry headings have content; structure is fine but older entries have empty bodies (log was append-only, older entries trimmed).

---

## Stale Index Entries

`wiki/index.md` recent sessions list only goes to 2026-06-10. Five cc-11 sessions are unlinked:

```
[[meta/session-2026-06-11-cc299-338-perf-polish-prod-infra]]
[[meta/session-2026-06-11-cc369-393-time-tracking-geofence-travel]]
[[meta/session-2026-06-11-cc370-389-fieldportal-rename-fleet-ux]]
[[meta/session-2026-06-11-cc390-402-fleet-inspection-hub-polish]]
[[meta/session-2026-06-11-cc403-412-fleet-inspection-hub-polish]]
```

---

## Stale Hot Cache

`tyler/hot.md` last updated 2026-06-11 (cc-403–412). Current Lambda is v220; iOS is at cc-742. Hot cache is ~1 month of work behind. Should be refreshed at the /clear session end.

---

## Suggested Actions

**Safe to auto-fix (ask first):**
1. Add 5 missing cc-11 sessions to `wiki/index.md`
2. Link `lint-report-2026-06-10.md` from dashboard
3. Delete `Untitled.md`
4. Remove template placeholder links (`[[page/name]]`, etc.) from log.md and session files

**Needs human review:**
1. `Gamify Gunner App.md` at root — ingest as gunnerteam/gamification.md?
2. `[[ciso-track/roadmap]]` in 9 pages — was CISO track abandoned? Remove links or create the page.
3. `[[meta/session-2026-05-19-masterdb-migration]]` in hot.md — find the actual file or remove the link.
4. Doug's wiki — populate or mark as stub.
