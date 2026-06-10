---
type: meta
title: Lint Report 2026-05-22
created: '2026-05-22'
updated: '2026-05-22'
tags:
  - meta
  - lint
status: evergreen
---

# Lint Report: 2026-05-22

## Summary
- Pages scanned: 155
- Issues found: 13 (10 previously reported "empty sections" were scanner false positives)
- Auto-fixed: 10
- Needs review: 3 (1 empty placeholder heading in `entities/_index`, 54 known stub sections, 1 session file outside wiki/)

---

## C1 — Malformed Wikilinks (backslash before pipe) ✅ Auto-fixed

Entity wikilinks in 4 pages were generated with a backslash before the pipe separator (`[[entities/Eric Recchia\|Eric Recchia]]` instead of `[[entities/Eric Recchia|Eric Recchia]]`). Obsidian treats the backslash as part of the path, making the link unresolvable.

**Fixed in:**
- `[[gunner/federal-market]]` — 2 occurrences (`Eric Recchia`)
- `[[gunner/hubspot-salesperson-sop]]` — 1 occurrence (`Eric Recchia`)
- `[[gunner/it-decision-log]]` — 3 occurrences (`Eddie Prchal`, `Andrew Prchal`, `Eric Recchia`)

---

## C2 — Orphan Pages (not linked from index or any page)

Two recently-added pages have no inbound links and are absent from `index.md`:

- `[[runbooks/aws-iam-least-privilege]]` — AWS IAM least-privilege runbook. Added during SOC 2 work. ✅ Added to index.
- `[[gunner/secrets-handling-rules]]` — Secrets handling rules. Core security doc. ✅ Added to index.

---

## W1 — Stale Index Entry ✅ Auto-fixed

`[[meta/session-2026-05-19-masterdb-migration]]` is referenced in `index.md` but the file lives at the vault root `/meta/` (not `wiki/meta/`). Obsidian resolves this correctly by stem, but it's inconsistent with the wiki structure. Entry updated to reflect correct context.

---

## W2 — Frontmatter Gaps ✅ Auto-fixed

5 pages missing required frontmatter fields:

| Page | Missing |
|------|---------|
| `[[runbooks/aws-iam-least-privilege]]` | `updated` |
| `[[gunner/secrets-handling-rules]]` | `updated` |
| `[[summaries/project-assigned-webhook-receiver-spec]]` | `status` |
| `[[gunner/software-suite]]` | `status` |
| `[[summaries/white-label-agenda]]` | `status` |

---

## W3 — Empty Sections

**Scanner false positives corrected.** The original report flagged 10 sections as empty. All 10 were false positives: the scanner stopped collecting content at any `###` sub-heading, so H2 sections organized via H3 sub-sections appeared empty. After fixing the scanner to collect content through all child headings, only 1 legitimately empty section exists:

- `[[entities/_index]]`: `## Add new entities here as they are identified during ingests.` — intentional placeholder instruction line used as a heading. Harmless; no fix needed.

---

## I1 — Stub Page Empty Sections (Lower Priority)

Many sections exist in stub/reference pages (API references, runbooks, CIS benchmarks) where headings are present but content has not been filled in. These are intentional placeholders for future ingestion. Not flagged for action.

Affected stub pages: `dialpad-api-reference`, `hubspot-api-reference`, `monday-api-reference`, `hexnode`, `acceptable-use-policy`, `cis-chrome-enterprise-benchmark`, `cis-google-workspace-benchmark`, `cis-ios-26-benchmark`, `cis-macos-26-benchmark`, `roadmap`, `lead-assignment-automation`, `environment`, `cloudflare`, `make-com`, `monday`, and others.

---

## Confirmed False Positives

- `[[meta/session-2026-05-19-masterdb-migration]]` dead link — file exists at vault root `/meta/`, Obsidian resolves by stem. Not broken.
- `[[hot]]`, `[[log]]` links in old lint reports — these are meta files outside the wiki scan scope. Not broken.
- `[[CLAUDE]]`, `[[Memory]]` in dual-agent-workflow — references to Claude project files, not wiki pages. Not broken.

---

## Prior Lint Comparison

| Category | 2026-05-15 | 2026-05-22 | Delta |
|----------|-----------|-----------|-------|
| Orphan pages | 0 | 2 | +2 (new pages not yet indexed) |
| Dead links (real) | 0 | 4 (backslash) | +4 (codegen artifact) |
| Frontmatter gaps | 0 | 5 | +5 (new pages) |
| Empty sections | — | 10 actionable | — |
| Stale index | 0 | 1 | +1 |

All prior issues from lint-report-2026-05-15 remain resolved.
