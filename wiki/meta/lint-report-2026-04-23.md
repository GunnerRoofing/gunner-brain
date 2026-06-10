---
title: "Lint Report 2026-04-23"
type: meta
tags: [meta, lint, health-check]
created: 2026-04-23
updated: 2026-04-23
status: evergreen
related:
  - "[[index]]"
  - "[[lint-report]]"
  - "[[meta/lint-report-2026-04-21]]"
---

# Lint Report — 2026-04-23

**Generated:** 2026-04-23 (session 13 — full 8-check pass)
**Scope:** Full wiki/ directory
**Pages scanned:** 99 (all .md files under wiki/)
**Previous report:** [[meta/lint-report-2026-04-21]]

---

## Summary

- Pages scanned: 99
- Issues found: 19 (3 critical, 8 warnings, 8 suggestions)

| Severity | Count | Description |
|----------|-------|-------------|
| Critical | 3 | Missing required frontmatter, dead wikilinks in active pages |
| Warning | 8 | Orphan page, stale lint-report.md content, unqualified links, unindexed page, sources/_index gap, large pages |
| Suggestion | 8 | Frequently mentioned concepts without pages, cross-reference gaps, entities/_index stub sections |

---

## Critical (must fix)

### C1 — Missing required frontmatter: comparisons/Wiki vs RAG.md

**Affected page:** [[comparisons/Wiki vs RAG]]

**Problem:** The file has only a `related:` field in frontmatter. It is missing all five required fields: `type`, `status`, `created`, `updated`, `tags`.

**Suggested fix:** Add full frontmatter block:
```yaml
type: comparison
status: stable
created: 2026-04-14
updated: 2026-04-14
tags: [knowledge-management, rag, wiki, llm]
```

---

### C2 — Missing required frontmatter: meta/lint-report-2026-04-14.md

**Affected page:** `wiki/meta/lint-report-2026-04-14.md`

**Problem:** The archived 2026-04-14 lint report has no frontmatter at all (file starts directly with `# Lint Report`). All other lint report archives have complete frontmatter.

**Suggested fix:** Add standard meta frontmatter block matching the pattern used in `meta/lint-report-2026-04-16.md` and `meta/lint-report-2026-04-21.md`.

---

### C3 — Dead wikilinks in active (non-meta) pages

The following wikilinks appear in active wiki pages (outside of meta/, log.md) and point to pages that do not exist. They fail resolution as full relative paths. Obsidian's global name search may rescue some of these in the app, but they are structurally broken.

**Unqualified links to concepts/ pages (resolve ambiguously or not at all):**

| Dead link | Found in | Correct target |
|-----------|----------|----------------|
| `[[LLM Wiki Pattern]]` | comparisons/Wiki vs RAG.md (×2), concepts/_index.md, concepts/Compounding Knowledge.md (×3), concepts/Hot Cache.md (×2), entities/Andrej Karpathy.md (×2), getting-started.md (×2) | `[[concepts/LLM Wiki Pattern]]` |
| `[[Compounding Knowledge]]` | comparisons/Wiki vs RAG.md (×2), concepts/_index.md, concepts/LLM Wiki Pattern.md (×2), concepts/Hot Cache.md (×2), entities/Andrej Karpathy.md (×2) | `[[concepts/Compounding Knowledge]]` |
| `[[Hot Cache]]` | concepts/_index.md, concepts/Compounding Knowledge.md (×2), concepts/LLM Wiki Pattern.md (×2), entities/Andrej Karpathy.md | `[[concepts/Hot Cache]]` |
| `[[Andrej Karpathy]]` | concepts/LLM Wiki Pattern.md (×3), concepts/Compounding Knowledge.md (×2), entities/_index.md | `[[entities/Andrej Karpathy]]` |

Note: These were previously flagged in the 2026-04-16 and 2026-04-21 lints as needing qualification. They are not fixed in the source pages — only the index.md entries were updated. The source pages still carry the unqualified forms.

**Suggested fix:** In each page listed above, replace bare `[[Name]]` with the fully qualified `[[subfolder/Name]]` form. This affects approximately 8 active pages across concepts/ and entities/.

---

## Warnings (should fix)

### W1 — Orphan page: gunner/hubspot-salesperson-sop.md

**Affected page:** [[gunner/hubspot-salesperson-sop]]

**Problem:** Created 2026-04-22 (366 lines). Zero inbound links from any other wiki page. Not listed in index.md. Not referenced in any related: frontmatter on other pages.

**Suggested fix:**
1. Add to index.md Gunner Operations table: `| [[gunner/hubspot-salesperson-sop]] | HubSpot Sales Workspace SOP — salesperson guide for leads, deals, CRM workflow |`
2. Add cross-reference links from `[[gunner/hubspot-leads-project]]` and `[[vendors/hubspot]]`.

---

### W2 — Stale content in wiki/lint-report.md (running report)

**Affected page:** [[lint-report]]

**Problem:** The running lint-report.md was last updated 2026-04-21 and contains stale information:
- References `wiki/canvases/welcome.canvas` as an unindexed canvas file — this file was deleted on 2026-04-21 (confirmed in hot.md session notes). The open item should be closed.
- The "Open Items" section still lists the canvas indexing question as unresolved, but hot.md confirms Wiki Map.canvas and canvases/main.canvas were indexed in a Canvases section in index.md.
- The report does not reflect any of the new pages added in sessions 10–12.

**Suggested fix:** Replace wiki/lint-report.md content with a pointer to this report (2026-04-23) as the current state. Update the header, summary, and open items to reflect current findings.

---

### W3 — sources/_index.md is missing 5 recently ingested summaries

**Affected page:** [[sources/_index]]

**Problem:** Five summary pages ingested in sessions 10–12 (2026-04-21) are in the main index.md and in wiki/summaries/ but are absent from wiki/sources/_index.md:
- `[[summaries/keeper-workshop]]` — Keeper Workshop.pptx
- `[[summaries/cis-ios-26-benchmark]]` — CIS iOS 26 v1.0.0
- `[[summaries/cis-macos-26-benchmark]]` — CIS macOS 26 Tahoe v1.0.0
- `[[summaries/cis-ms-office-benchmark]]` — CIS MS Office v1.2.0
- `[[summaries/cis-chrome-enterprise-benchmark]]` — CIS Chrome Enterprise Core v1.0.0

Note: The last four are listed in sources/_index.md under CIS Benchmarks — confirmed present. Only `[[summaries/keeper-workshop]]` is genuinely missing from sources/_index.md.

**Suggested fix:** Add to sources/_index.md under a new "Vendor Training" section:
`- [[summaries/keeper-workshop]] — Keeper Workshop.pptx — staff training, master password, security audit, priority accounts`

---

### W4 — Unqualified wikilinks remaining in active pages (after previous fix passes)

**Affected pages:** Multiple (see C3 above for full list)

**Problem:** Despite fix passes in sessions 7 and 9, unqualified wikilinks persist in the source concept/entity pages themselves. The previous fixes only updated index.md and entities/_index.md — not the pages where the links originate. This is a recurring issue across:
- `concepts/Compounding Knowledge.md` — 5 unqualified links
- `concepts/LLM Wiki Pattern.md` — 5 unqualified links
- `concepts/Hot Cache.md` — 3 unqualified links
- `entities/Andrej Karpathy.md` — 3 unqualified links
- `comparisons/Wiki vs RAG.md` — 4 unqualified links
- `concepts/_index.md` — 3 unqualified links
- `getting-started.md` — 2 unqualified links

**Suggested fix:** Do a targeted pass on these 7 files, qualifying all bare `[[Name]]` links to `[[subfolder/Name]]`. Covered by C3 above — fixing C3 resolves W4.

---

### W5 — wiki/lint-report.md "Open Items" references deleted file

**Affected page:** [[lint-report]]

**Problem:** The running lint-report.md Open Items section lists `wiki/canvases/welcome.canvas` as an existing file requiring a decision. This file was deleted on 2026-04-21 per hot.md ("wiki/canvases/welcome.canvas — deleted (stale claude-obsidian demo template, broken GIF refs)"). The open item is now a false entry.

**Suggested fix:** Remove the `welcome.canvas` bullet from the running lint-report.md open items. The canvas indexing issue is resolved — both active canvases (Wiki Map, canvases/main) are now indexed.

---

### W6 — Large pages over 300 lines

**Problem:** The following pages exceed 300 lines. Not a blocking issue, but large pages are harder to maintain and may need splitting as content grows.

| Page | Lines | Note |
|------|-------|------|
| `gunner/hubspot-leads-project.md` | 388 | Dense project doc; consider splitting Phase details into sub-pages |
| `gunner/hubspot-salesperson-sop.md` | 366 | New page; SOP may benefit from a condensed quick-reference version |
| `log.md` | 541 | Append-only; expected to grow; no action needed |
| `meta/lint-report-2026-04-14.md` | 362 | Archived; no action needed |
| `meta/lint-report-2026-04-16.md` | 400 | Archived; no action needed |
| `vendors/dialpad-api-reference.md` | 385 | API reference; long by nature; acceptable |
| `vendors/hubspot-api-reference.md` | 302 | API reference; acceptable |
| `vendors/monday-api-reference.md` | 334 | API reference; acceptable |

**Suggested fix:** Consider splitting `gunner/hubspot-leads-project.md` if it grows beyond 450 lines. All others are acceptable at current size.

---

### W7 — entities/_index.md Organizations and Products sections are empty

**Affected page:** [[entities/_index]]

**Problem:** The Organizations and Products & Tools sections contain only HTML comment placeholders (`<!-- Add ... here -->`). This was carried over from the 2026-04-16 lint. No entity pages have been created for organizations (Gunner Roofing LLC, CompTIA, WGU) or products (Hexnode, Google Workspace, etc.).

**Suggested fix:** Either populate with wikilinks to existing vendor/entity pages, or add a note that Organizations and Products are tracked in vendors/ and not duplicated here. The heading `## Add new entities here as they are identified during ingests.` (line 46) is also an empty section heading — consider converting it to an inline instruction comment.

---

### W8 — ciso-track/roadmap.md last updated 2026-04-10

**Affected page:** [[ciso-track/roadmap]]

**Problem:** Updated field is 2026-04-10, but the CISSP study has progressed (NIST CSF 2.0 and CIS Controls v8.1.2 now in vault as study material per hot.md). The Frameworks Being Studied table shows NIST CSF 2.0 and CIS Controls as "[x] In vault" but the updated date does not reflect this change. CISSP and SecurityX are the next certs per hot.md.

**Suggested fix:** Update the `updated:` date to today after making any content changes. Consider adding CISSP study materials progress and MS in Cybersecurity completion date (July 2025 — already in Completed table, confirmed accurate).

---

## Suggestions (worth considering)

### S1 — Concept gap: AWS / EC2 mentioned 39 times without a dedicated page

**Problem:** AWS appears 37 times and EC2 appears 2 times across active wiki pages (threats/t1199, gunner/completed-projects, ciso-track/roadmap, gunner/lead-assignment-automation, vendors/make-com, etc.). Gunner's AWS environment (api-user.php on EC2, Dev/Prod/QA/Staging accounts) is architecturally significant for the lead assignment automation and the Make.com deal deletion workaround. No wiki page covers Gunner's AWS setup.

**Suggested fix:** Create `wiki/gunner/aws-environment.md` or `wiki/vendors/aws.md` (stub acceptable) covering: account structure (Dev/Prod/QA/Staging), EC2 role (api-user.php), current open item (script rewrite to stop creating HubSpot deals), and link from `gunner/lead-assignment-automation.md` and `vendors/make-com.md`.

---

### S2 — Concept gap: CISSP mentioned 21 times without a dedicated page

**Problem:** CISSP appears 21 times across active pages (ciso-track/roadmap, hot.md, multiple summary pages) as Tyler's highest-priority certification. No concept or ciso-track page covers CISSP study structure, 8 domains, or study plan.

**Suggested fix:** Create `wiki/ciso-track/cissp.md` covering: 8 domains, exam format, study materials, target date, and cross-links to ciso-track/roadmap.md and relevant concept pages.

---

### S3 — Concept gap: DMARC / email authentication mentioned 37 times without a standalone concept page

**Problem:** DMARC appears 37 times and is the primary email authentication control at Gunner (p=reject, verified). It is covered within `concepts/email-security.md` but there is no dedicated DMARC page despite its importance as a CISO-track study topic and active Gunner control.

**Suggested fix:** Consider expanding `concepts/email-security.md` with a DMARC section if not already complete, or evaluate whether a separate `concepts/dmarc.md` page adds value. Current coverage in email-security.md may be sufficient — review before acting.

---

### S4 — Concept gap: Make.com has a vendor page but no scenario registry

**Problem:** `vendors/make-com.md` now covers two active scenarios (delete AWS deals, HubSpot → Google Chat). As automation grows, tracking scenarios in one place becomes valuable. The page currently uses `## Active Scenarios` which is a good start.

**Suggested fix:** Ensure that every future Make.com scenario is documented in `vendors/make-com.md` as a subsection. No structural change needed now, but flag for ongoing maintenance.

---

### S5 — Cross-reference gap: gunner/hubspot-salesperson-sop.md lacks links from related pages

**Problem:** `gunner/hubspot-salesperson-sop.md` was created 2026-04-22 (IT-SOP-HUB-002 v1.0) but is not linked from `vendors/hubspot.md`, `gunner/hubspot-leads-project.md`, or `gunner/hubspot-workflow-designs.md`.

**Suggested fix:** Add a reference to `[[gunner/hubspot-salesperson-sop]]` in the Related or See Also section of each of those three pages.

---

### S6 — concepts/_index.md Knowledge Management section uses unqualified links (duplicates C3)

**Problem:** The Knowledge Management section of `concepts/_index.md` uses `[[LLM Wiki Pattern]]`, `[[Hot Cache]]`, and `[[Compounding Knowledge]]` without the `concepts/` prefix. This was supposed to be fixed in session 7 (C2 in 2026-04-16 lint). The index.md fix was applied but concepts/_index.md was not updated.

**Suggested fix:** Update lines 45–47 of `wiki/concepts/_index.md` to use fully qualified paths.

---

### S7 — getting-started.md uses unqualified [[LLM Wiki Pattern]] link

**Problem:** `wiki/getting-started.md` frontmatter (line 11) and body (line 96) both reference `[[LLM Wiki Pattern]]` without the `concepts/` prefix.

**Suggested fix:** Update both occurrences to `[[concepts/LLM Wiki Pattern]]`.

---

### S8 — entities/_index.md frontmatter has unqualified [[Andrej Karpathy]] link

**Problem:** `wiki/entities/_index.md` frontmatter `related:` field contains `'[[Andrej Karpathy]]'` (unqualified). The body was fixed in session 9 but the frontmatter was not.

**Suggested fix:** Change frontmatter line to `'[[entities/Andrej Karpathy]]'`.

---

## Check Results by Category

| Check | Result |
|-------|--------|
| 1. Frontmatter completeness | 2 pages missing required fields (C1, C2) |
| 2. Wikilink resolution | 4 unqualified link targets across 7+ pages (C3, W4) |
| 3. Headings with no content | No genuinely empty headings found in active pages (log.md entries use headings as log markers by design) |
| 4. Orphan pages | 1 orphan: gunner/hubspot-salesperson-sop.md (W1) |
| 5. Concepts without pages | AWS, CISSP, DMARC flagged as high-frequency without dedicated pages (S1–S3) |
| 6. Unlinked mentions | gunner/hubspot-salesperson-sop.md not linked from related pages (S5) |
| 7. Stale index entries | 0 — all index.md entries resolve to existing files |
| 8. Stale seed pages | 0 — all 5 seed/stub pages updated 2026-04-16 (within 30 days) |

---

## Pages Added Since Last Lint (2026-04-21)

New pages created in sessions 10–12 that were verified in this lint:

| Page | Created | Status |
|------|---------|--------|
| `vendors/stripe-api-reference` | 2026-04-21 | In index; linked; frontmatter complete |
| `summaries/keeper-workshop` | 2026-04-21 | In index; missing from sources/_index (W3) |
| `gunner/it-decision-log` | 2026-04-21 | In index; linked; frontmatter complete |
| `gunner/gunner-forms-privacy-policy` | 2026-04-21 | In index; linked; frontmatter complete |
| `gunner/departmental-comms` | 2026-04-21 | In index; linked; frontmatter complete |
| `vendors/make-com` | 2026-04-21/23 | In index; linked; frontmatter complete |
| `gunner/gunner-forms-app` | 2026-04-22 | In index; linked; frontmatter complete |
| `gunner/hubspot-salesperson-sop` | 2026-04-22 | Missing from index; no inbound links (W1) |
| `questions/hexnode-custom-app-deployment` | 2026-04-22 | In index; linked; frontmatter complete |

---

*Previous report: [[meta/lint-report-2026-04-21]]*
*Next lint: recommended within 2 weeks or after 10+ page ingests.*
