---
type: meta
title: "Lint Report 2026-06-19"
created: 2026-06-19
updated: 2026-06-19
tags:
  - meta
  - lint
status: stable
---

# Lint Report: 2026-06-19

## Summary
- Pages scanned: 226
- Issues found: 9 (actionable — orphans were false positives)
- Auto-fixed: 9
- Needs review: 0

---

## Orphan Pages
**All 4 flagged as false positives.** Scanner resolved from top-level `wiki/` namespace and missed path-relative wikilinks in `wiki/tyler/index.md`. All are linked:

- [[tyler/runbooks/incident-response]]: linked from `tyler/index.md` line 125 ✅
- [[tyler/summaries/system-security-plan]]: linked from `tyler/index.md` line 149 ✅
- [[tyler/concepts/_index]]: linked from `tyler/index.md` line 222 (full concepts listing, not scaffold) ✅
- [[tyler/sources/_index]]: linked from `tyler/index.md` line 212 (15 ingested sources by category, not scaffold) ✅

---

## Dead Links

### Real dead links (fixed)
- `[[gunnerteam/hot.md]]` in [[gunnerteam/git-source-of-truth-policy]]: `wiki/gunnerteam/hot.md` does not exist. The GunnerTeam section has no hot.md; policy should point to `wiki/tyler/hot.md`. **→ Fixed to `[[tyler/hot.md]]`.**

### Low-priority / archive noise
- `[[shared/decisions/]]` in [[gunnerteam/git-source-of-truth-policy]]: directory-style link is non-standard. **→ Fixed to `[[shared/decisions/README]]`.**
- Old session notes (cc-369, cc-299, cc-403) reference `[[tyler/hot.md]]` and `[[tyler/Memory.md]]` with path prefixes — files exist, Obsidian resolves correctly. No action needed.
- Old lint report cross-references (`[[meta/lint-report-2026-04-16]]`, `[[meta/lint-report-2026-06-02]]`, etc.) in archived session notes reference removed lint files. Acceptable in historical session notes.

---

## Stale Claims

### Lambda version (fixed)
- [[gunnerteam/overview]]: `Lambda v277 live` — **→ Updated to v294.**
- [[gunnerteam/aws-environment]]: Live version row `v277` — **→ Updated to v294.**

### Historical references (not stale — left as-is)
- [[gunnerteam/git-source-of-truth-policy]]: references v233 in postmortem context (historical, accurate).
- [[gunnerteam/POSTMORTEM-2026-06-15]]: references v233 (incident-accurate, not a current claim).
- [[gunnerteam/gunnerteam-project-structure]]: references v127 (historical baseline, accurate).

---

## Missing Pages
- `wiki/gunnerteam/hot.md` — referenced from [[gunnerteam/git-source-of-truth-policy]] (dead link). The GunnerTeam section intentionally has no separate hot.md; [[tyler/hot.md]] is the canonical state file. Link corrected; no page creation needed.

---

## Frontmatter Gaps

### Fixed (gunnerteam policy docs)
- [[gunnerteam/POSTMORTEM-2026-06-15]]: added `created: 2026-06-15`, `updated: 2026-06-15`
- [[gunnerteam/git-source-of-truth-policy]]: added `updated: 2026-06-19`
- [[gunnerteam/employee-notice-points-location]]: added `updated: 2026-06-19`
- [[gunnerteam/CONTRIBUTING]]: added `created: 2026-06-15`
- [[gunnerteam/CHANGE_MANAGEMENT_POLICY]]: added `created: 2026-06-15`

### Low-priority structural files (not fixed)
Hot caches, indexes, and scaffold READMEs for doug/leo/colin sections intentionally omit some frontmatter fields — they are operational files, not knowledge pages. No action taken.

---

## Empty Sections
False positives dominate (44 of 47 flagged are code-comment lines inside fenced blocks in `secure-coding-guide.md` being parsed as headings). Real empty sections:

- [[gunnerteam/overview]], [[gunnerteam/aws-environment]], [[tyler/overview]]: top-level h1 is a document title with no body before the first subsection — standard Obsidian pattern, not a problem. No action.

---

## Stale Index Entries
None. All entries in [[index]] resolve to existing files.

---

## Cross-Reference Gaps
No systematic scan run this pass (low signal in a vault this structured). Spot-check clean.

---

## Writing Style Check
Not flagged this pass — all recently created session and decision pages use declarative present tense correctly.

---

## Previous Lint
[[meta/lint-report-2026-06-18]]
