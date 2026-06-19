---
type: meta
title: Lint Report 2026-06-18
created: '2026-06-18'
updated: '2026-06-18'
tags:
  - meta
  - lint
status: stable
---

# Lint Report: 2026-06-18

## Summary
- Pages scanned: 227
- Issues found: 13
- Auto-fixed: 0 (pending review)
- Needs review: 13

---

## Dead Links (3)

### 1. `[[lint-report]]` in tyler/index.md
Referenced in the Meta section of `wiki/tyler/index.md`. No file named `lint-report.md` exists anywhere in the vault. The actual lint reports are in `wiki/meta/lint/lint-report-2026-06-10.md` and `lint-report-2026-06-13.md`.
**Suggest:** Update the link to `[[meta/lint/lint-report-2026-06-13]]` (most recent).

### 2. `[[meta/lint-report-2026-06-09]]` in tyler/index.md
Referenced in the Meta table of `wiki/tyler/index.md`. The `wiki/meta/lint/` directory contains only `lint-report-2026-06-10.md` and `lint-report-2026-06-13.md` — no June 9 report exists.
**Suggest:** Remove this entry or update to the 06-10 report.

### 3. `[[meta/lint/lint-report-2026-06-02]]` in tyler/index.md
Referenced in the Gunner Operations table as an inline session note entry. The `wiki/meta/lint/` directory has no file from 2026-06-02.
**Suggest:** Remove the entry; that lint run's results were folded into the adjacent session note.

---

## Stale Claims (3)

### 1. `wiki/hot.md` (system-level) — Lambda version
The System State table shows `Lambda **v233** live`. Current live version is **v277**. The inline note also says `GunnerTeam Lambda: approximately v140`.
**Status:** Very stale — off by ~130 versions.
**Suggest:** Update to v277 (or note that `tyler/hot.md` is authoritative for the current version and remove the version number from the system hot.md, since it can't be kept in sync).

### 2. `wiki/gunnerteam/overview.md` — Lambda version and App Store claim
Shows `Lambda ~v140 live` and `release/3.0.0 frozen for the App Store release`. Current Lambda is v277. The `release/3.0.0` branch claim is from ~cc-140 era.
**Suggest:** Update version to v277. Remove the App Store release branch note (the app ships via Apple Business Manager, not the public App Store — or if the App Store submission is active, clarify the current state).

### 3. `wiki/gunnerteam/aws-environment.md` — Live version and deploy recipe
Shows `Live version: v127` in the API Layer table. The deploy recipe is also missing the two critical fixes added in cc-867:
- Missing `rm -f /tmp/gunnerteam-deploy.zip` before `zip -r`
- Missing `--routing-config '{"AdditionalVersionWeights":{}}'` on the `update-alias` call
**Suggest:** Update live version to v277 and sync the deploy recipe from `CLAUDE.md`.

---

## Index Gaps — wiki/index.md (3)

The top-level `wiki/index.md` Meta section is missing three recent sessions that exist in `wiki/meta/` and are listed in `wiki/tyler/index.md`:

| Missing entry | File exists in wiki/meta/ |
|---|---|
| `[[meta/session-2026-06-15-cc766-788-appstore-hardening-polish]]` | ✅ |
| `[[meta/session-2026-06-16-cc789-815-location-forms-360gallery]]` | ✅ |
| `[[meta/session-2026-06-17-cc815-842-compliance-refactor-service-keys]]` | ✅ |

**Suggest:** Add these three entries between the cc-864-871 entry (just added) and the cc-608-742 entry.

---

## Structural Issues (2)

### 1. Vendor table duplicated in tyler/index.md
The Vendors section in `wiki/tyler/index.md` contains two separate markdown tables with partially overlapping entries. The second table starts mid-section after the DocuSign row. The duplicate rows include jamf, quote-portal, make-com, sendgrid, bitdefender, and cloudflare.
**Suggest:** Merge into a single table; remove the duplicate header `| Page | Description |`.

### 2. `wiki/tyler/meta/` is an empty directory
The directory `wiki/tyler/meta/` exists but contains no files. All session notes live in `wiki/meta/` (top-level). Links from `wiki/tyler/index.md` using `[[meta/...]]` resolve to `wiki/meta/` via global search, not to this empty directory.
**Suggest:** Leave as-is (Obsidian ignores empty dirs) or document that tyler's meta notes live in top-level `wiki/meta/`.

---

## Orphan Pages (2)

These gunnerteam pages have no inbound wikilinks from any index or session note found during scan:

| Page | Last modified | Suggest |
|---|---|---|
| `wiki/gunnerteam/CONTRIBUTING.md` | 2026-06-15 | Link from `wiki/gunnerteam/overview.md` or `wiki/hot.md` |
| `wiki/gunnerteam/gamification-original-brief.md` | 2026-06-13 | Link from session note cc-608-742 or gunnerteam/overview |

Note: `employee-notice-points-location.md`, `git-source-of-truth-policy.md`, `CHANGE_MANAGEMENT_POLICY.md`, and `POSTMORTEM-2026-06-15.md` are referenced in `wiki/hot.md` or `wiki/log.md` — not orphans.

---

## Frontmatter Gaps (2)

| Page | Missing fields |
|---|---|
| `wiki/index.md` | `status`, `tags` (has `type`, `updated`, `owner`) |
| `wiki/gunnerteam/overview.md` | `updated` (has `type`, `owner`, `app`, `created`, `status`) |

Minor — these are infrastructure pages. Low priority.

---

## Not Issues (False Positives Noted)

- **`[[gunner/...]]` links in tyler/index.md** — these use the old `gunner/` path prefix, but Obsidian resolves them globally to `wiki/gunnerteam/` files because the filenames are unique in the vault. They render correctly in Obsidian even though the path is technically a mismatch.
- **50+ older session notes in wiki/meta/** not listed in wiki/index.md — session notes don't need to appear in the top-level index; they're filed and accessible. No action needed beyond the 3 recently-missing entries above.
- **`wiki/shared/api-contracts/README.md`**, `wiki/shared/decisions/README.md`, `wiki/shared/architecture/README.md` — all exist ✅; links resolve correctly.

---

## Resolution Status (all 5 review items fixed 2026-06-18)

| # | Fix | Status |
|---|---|---|
| 9 | overview.md: Lambda v277, removed App Store branch note, added ABM distribution note | ✅ |
| 10 | aws-environment.md: v277, deploy recipe corrected (rm -f + routing-config JSON) | ✅ |
| 11 | CONTRIBUTING.md orphan: linked from overview.md Related section | ✅ |
| 12 | gamification-original-brief.md: dead link fixed + inbound link from overview.md | ✅ |
| 13 | Frontmatter: status/tags/updated added to index.md + overview.md | ✅ |

## Recommended Fix Order

1. **wiki/index.md** — add 3 missing session entries (safe, additive)
2. **wiki/hot.md** — update Lambda version or delegate to tyler/hot.md (stale, misleading)
3. **wiki/gunnerteam/overview.md** — update Lambda version (quick)
4. **wiki/gunnerteam/aws-environment.md** — update version + deploy recipe (moderate)
5. **tyler/index.md** — fix 3 dead lint-report links + deduplicate vendor table (structural)
6. **CONTRIBUTING.md + gamification-original-brief.md** — add one inbound link each (low)
7. **wiki/index.md + gunnerteam/overview.md frontmatter** — add missing fields (cosmetic)
