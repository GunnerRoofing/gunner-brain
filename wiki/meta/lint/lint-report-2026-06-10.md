---
type: meta
title: "Lint Report 2026-06-10"
created: 2026-06-10
updated: 2026-06-10
tags: [meta, lint]
status: complete
---

# Lint Report: 2026-06-10

## Summary
- **Pages scanned:** 197 markdown files (177 content pages analyzed; 20 excluded: index.md, log.md, hot.md + 17 prior lint-reports). 2 canvas files cross-checked for link targets.
- **Issues found:** 76 (62 orphans — all index-linked/acceptable, 5 cross-reference gaps, 9 stale-claim items)
- **Auto-fixed:** 0 (frontmatter gaps = 0 and genuine dead links = 0; nothing fell in the auto-fix whitelist)
- **Needs review:** 14 (5 cross-reference gaps + 9 stale-claim items). Orphans are informational.

Vault health is strong: dead links, frontmatter gaps, empty sections, and stale index entries are all **0**. All four HIGH stale-claim pages flagged in [[meta/lint-report-2026-06-09]] were rewritten on 2026-06-09 and are now current. The remaining issues are unlinked entity/vendor stubs and one-day drift in fast-moving GunnerTeam facts (centered on `hot.md`).

---

## Orphan Pages (62) — flag only, no action

Pages with no inbound link from a *content* page (excluding index/log/hot/lint-reports). **All 62 are linked from `index.md`** — zero true zero-inbound pages, zero pages reachable only via log/reports. This is the expected steady state for a session-notes-heavy vault.

By folder: meta 42, gunner 6, vendors 4, entities 3, runbooks 3, questions 2, concepts 1, summaries 1.

36 are `session-*` notes (intentionally index-only — no action). The 26 non-session orphans below are knowledge/reference pages that *could* gain inbound links from related content pages but are not broken:

- Entities: [[entities/Colin]], [[entities/Leonard]], [[entities/Ruchir]] — newly created stubs; see Cross-Reference Gaps below (linking their mentions will clear these).
- Vendors: [[vendors/cloudflare]], [[vendors/companycam]], [[vendors/docusign]], [[vendors/stripe]]
- Gunner: [[gunner/claude-team-setup]], [[gunner/gunnerteam-performance-standards]], [[gunner/secrets-handling-rules]], [[gunner/subportal-cc-prompt-01-scaffold]], [[gunner/subportal-cc-prompt-02-frontend]], [[gunner/tls-cutover-2026-05-14]]
- Runbooks: [[runbooks/aws-iam-least-privilege]], [[runbooks/chrome-safesites-policy]], [[runbooks/monday-pm-my-work-view-setup]]
- Questions: [[questions/claude-code-hook-tooluse-error]], [[questions/keeper-web-vault-login-loop]]
- Concepts/Meta/Summaries: [[concepts/omp-tasks-subagents]], [[meta/dashboard]], [[meta/dual-agent-workflow]], [[meta/boss-setup-guide]], [[meta/claude-obsidian-setup-guide]], [[meta/vault-commands-reference]], [[meta/gunnerforms-auth-build-2026-04-28]], [[summaries/white-label-agenda]]

Suggest: leave session notes as-is. For vendor/entity stubs, prefer adding inbound links over deletion (see Cross-Reference Gaps).

---

## Dead Links (0)
Clean. All wikilinks across the vault resolve. The 21 files my scanner initially flagged were verified by hand to be **false positives**: every unresolved target sits inside a fenced code block, an inline backtick code span, or a table-escaped pipe (`\|`, valid Obsidian alias syntax). Lint-report and session-note files legitimately quote example/illustrative links (`[[page/name]]`, `[[other/page]]`, `[[claude-obsidian-ecosystem]]`, `[[dashboard.base]]`) when describing prior fixes — none are live references.

---

## Missing Pages (0 new)
All missing-page candidates from [[meta/lint-report-2026-06-09]] now have pages: [[entities/Colin]], [[entities/Leonard]] (reconciles the Leonard/Leo naming gap), [[entities/Ruchir]], [[vendors/docusign]], [[vendors/stripe]]. No new concept/entity is mentioned across multiple pages without a dedicated page. The frequent multi-page proper nouns (Google Workspace, Lambda, Claude Code, GunnerForms) already have pages or are external tools/table headers, not missing concepts.

---

## Frontmatter Gaps (0)
All 177 analyzed content pages carry the required fields: `type`, `title`, `status`, `created`, `updated`, `tags`. Only `index.md`, `log.md`, and `hot.md` lack frontmatter by design (navigation/cache files).

---

## Empty Sections (0)
0 truly empty headings (a heading with no prose, list, table, or code anywhere in its scope before the next equal-or-higher heading). Parent headings whose content lives entirely in subsections are correctly counted as non-empty.

---

## Stale Index Entries (0)
Every wikilink in `index.md` resolves, and every content page is reachable from `index.md`. The 11 coverage gaps fixed in the 2026-06-09 cycle are holding.

---

## Cross-Reference Gaps (5) — needs review (flag only)

The 5 entity/vendor stubs created last cycle exist but their mentions in *living* knowledge pages are still plain text, not wikilinks. Linking these would also clear the corresponding orphans above.

- **Colin** → [[entities/Colin]]: plain-text mentions across ~18 pages. Living-page targets: [[summaries/external-api-handoff]] (3). (Most other mentions are frozen session notes — leave those.)
- **Leonard / Leo** → [[entities/Leonard]]: [[gunner/masterdb-developer-handoff]] (3, "Leonard"); [[gunner/subportal-cc-prompt-01-scaffold]] (3, "Leo"); [[gunner/software-suite]] (1, "Leo"); [[gunner/subportal-cognito-auth]] (1, "Leo").
- **Ruchir** → [[entities/Ruchir]]: [[gunner/software-suite]] (1); [[summaries/white-label-agenda]] (1).
- **Stripe** → [[vendors/stripe]]: [[vendors/stripe-api-reference]] (6); [[gunner/software-suite]] (3); [[gunner/secure-coding-guide]] (2); [[gunner/gunnerteam-api-aws-migration]] (1).
- **DocuSign** → [[vendors/docusign]]: [[gunner/software-suite]] (2); [[summaries/white-label-agenda]] (2); [[gunner/app-inventory]] (1); [[gunner/environment]] (1).

Suggest: add wikilinks on the living pages only (not historical session notes). Per this run's auto-fix scope, left unmodified for review.

---

## Stale Claims (9) — needs human review (flag only)

### Resolved since last cycle (good — no action)
All four HIGH items from [[meta/lint-report-2026-06-09]] were rewritten on 2026-06-09 and are now accurate: [[gunner/aws-environment]] (Lambda-first, EC2 gone), [[runbooks/omp-hang-fix]] (v15.10.4, powerline working), [[runbooks/mac-tool-setup]] (OMP primary, correct font/paths), [[gunner/gunnerteam-project-structure]] (refreshed). The drift below is new and accumulated in the ~1 day since.

### HIGH — `hot.md` internal contradictions
`wiki/hot.md` (the hot cache) carries several self-contradictions where the top "Current State" block has advanced past lower historical sections:

1. **Lambda version conflict (3 values in one file):** top says `Lambda: v139 live` (line 7), the Backend section says `Lambda v127 live` (line 41), and the API Architecture table says `version 5 live` (line 104). Reconcile to the true live version.
2. **OMP version conflict:** top says `OMP: 15.10.8` (line 9) but the "OMP Status (2026-05-26)" section says `Version: 15.4.1` + "stay on 15.4.1" (line 117). The lower section is stale; [[runbooks/omp-hang-fix]] says v15.10.4.
3. **Powerline plugin conflict:** OMP Status section marks `pi-powerline-footer@0.5.4 ❌ broken` (line 129) and lists a "Tomorrow's Plugin Retry Plan", but [[runbooks/omp-hang-fix]] confirms powerline `0.5.6` is working. Stale.
4. **Theme conflict:** line 120 says theme `dark-gruvbox`; "Active Threads" line 195 says `ansi-dark theme`. (Custom `ansi-dark` was lost in the 2026-05-26 reinstall.)
5. **Page count:** "Vault Status — **129 pages. Lint clean.**" (line 64). Actual vault is 197 markdown files. Stale by ~68.
6. **Masterdb migration status:** the "gunner-ios → gunner-masterdb Migration (READY TO CUT OVER)" section (lines 68–93) describes a pending cutover, but [[meta/session-2026-05-21-masterdb-cutover-complete]] records the cutover as done. The "Pending Actions" list (lines 147–168) still references `cc-prompt-27/28` though the project is at cc-288.

Suggest: prune/refresh `hot.md` — collapse the stale OMP-Status, migration, and Pending-Actions blocks; keep only the current top section. (Flagged only; `hot.md` is normally rewritten at session end, not by lint.)

### MEDIUM — cross-page fact drift (1-day)
7. **Lambda live version:** [[gunner/aws-environment]] and [[gunner/gunnerteam-project-structure]] both say `v127`; `hot.md` top says `v139`. One is stale — verify the alias.
8. **Provisioned concurrency contradiction:** [[gunner/aws-environment]] states "No provisioned concurrency is configured" (line 20), but `hot.md` says "2 containers always warm (~$22/mo)". Direct conflict — confirm and align both.
9. **cc-prompt count / HEAD:** [[gunner/gunnerteam-project-structure]] says `cc-234` latest and `main` HEAD `be90174`; `hot.md` (2026-06-10) says cc-288 and HEAD `dec91fd`. Expected fast-moving drift; refresh project-structure "Current State" when convenient.

---

## Naming & Style
No filename-convention or wikilink-format violations found. Filenames are unique across the vault; entity files use Title Case, folders use lowercase-with-dashes. No backslash-pipe resolution failures in live content.
