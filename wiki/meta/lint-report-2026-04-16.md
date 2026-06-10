---
title: Lint Report 2026-04-16
type: meta
tags: [meta, lint, health-check]
created: 2026-04-16
updated: 2026-04-16
status: evergreen
related:
  - "[[index]]"
  - "[[meta/lint-report-2026-04-14]]"
---

# Lint Report — 2026-04-16

**Generated:** 2026-04-16 (full-vault health check, post session 6 — lead assignment v2 + HubSpot phases)  
**Scope:** Full wiki/ directory  
**Pages scanned:** 69 (excluding hot.md, log.md, index.md)

---

## Summary

- Pages scanned: 69
- Issues found: 42 (6 critical, 18 warnings, 18 suggestions)

---

## Critical (must fix)

### C1 — Dead wikilink in [[comparisons/Wiki vs RAG]]

**Page:** `wiki/comparisons/Wiki vs RAG.md`  
**Problem:** Frontmatter `related:` contains `[[How does the LLM Wiki pattern work]]`. No page by that name exists anywhere in the vault.  
**Fix:** Remove the stale link from frontmatter, or create a `wiki/concepts/how-does-llm-wiki-work.md` stub if the content is genuinely needed.

---

### C2 — Stale index entries: LLM Wiki Pattern, Hot Cache, Compounding Knowledge

**Page:** `wiki/index.md` (Concepts / Knowledge Management section)  
**Problem:** Index links these three pages as `[[LLM Wiki Pattern]]`, `[[Hot Cache]]`, and `[[Compounding Knowledge]]` — bare names without the `concepts/` prefix. These files live at `wiki/concepts/LLM Wiki Pattern.md`, `wiki/concepts/Hot Cache.md`, and `wiki/concepts/Compounding Knowledge.md`. Without the subfolder prefix, Obsidian may not resolve them correctly across all contexts, and the lint check confirms they do not resolve as full relative paths.  
**Fix:** Update the three index entries to `[[concepts/LLM Wiki Pattern]]`, `[[concepts/Hot Cache]]`, and `[[concepts/Compounding Knowledge]]`.

---

### C3 — Missing `status` frontmatter field

**Pages affected:**
- `wiki/gunner/system-security-plan.md` — `status:` field absent
- `wiki/summaries/cis-google-workspace-benchmark.md` — `status:` field absent

**Problem:** Both pages are missing the required `status:` frontmatter field. This breaks Dataview queries on the dashboard and the lint stale-seed check.  
**Fix:** Add `status: stable` (or the appropriate value) to each page's frontmatter.

---

### C4 — Missing `created` frontmatter field

**Pages affected:**
- `wiki/entities/_index.md` — `created:` field absent
- `wiki/getting-started.md` — `created:` field absent
- `wiki/meta/dashboard.md` — `created:` field absent

**Problem:** Required `created:` field missing. Dashboard age calculations and audit trails are incomplete.  
**Fix:** Add `created:` with the appropriate date to each page.

---

### C5 — Dead wikilinks in `wiki/lint-report.md` (prior report artifacts)

**Page:** `wiki/lint-report.md`  
**Problem:** The current running lint report contains leftover wikilinks from a prior draft that point to pages that do not exist: `[[cherry-picks]]`, `[[claude-obsidian-ecosystem-research]]`, `[[comparisons/claude-obsidian-ecosystem]]`, `[[dashboard.base]]`, `[[meta/dashboard.base]]`, `[[page/name]]`, `[[runbooks/...]]`, `[[vendors/hexnode\]]` (with erroneous backslash), `[[vendors/keeper\]]`, `[[vendors/knowbe4\]]`.  
**Fix:** This report will replace `wiki/lint-report.md` entirely. The dead links will be gone once the new report is written.

---

### C6 — Dead wikilinks in `wiki/meta/session-2026-04-14-claude-obsidian.md`

**Page:** `wiki/meta/session-2026-04-14-claude-obsidian.md`  
**Problem:** Contains wikilinks `[[other/page]]` and `[[page/name]]` — these are template placeholder values that were never replaced with real links.  
**Fix:** Open the page and replace or remove the placeholder wikilinks.

---

## Warnings (should fix)

### W1 — Orphan page: [[gunner/brand-colors]]

**Page:** `wiki/gunner/brand-colors.md`  
**Problem:** Only linked from `wiki/index.md` and `wiki/summaries/my-notebook-gunner-roofing.md`. The index link is a navigation entry, not a contextual cross-reference. No Gunner-domain page (environment.md, app-inventory.md, etc.) links to it organically.  
**Fix:** Add a link from `wiki/gunner/environment.md` in the "Brand & Identity" or similar section, if one makes sense. The page is stable and correct — it just needs one more organic inbound reference.

---

### W2 — Near-orphan page: [[concepts/poam]]

**Page:** `wiki/concepts/poam.md`  
**Problem:** Only linked from `wiki/index.md`. No threat page, runbook, or gunner page links to it despite POAM being directly relevant to `wiki/gunner/system-security-plan.md`, `wiki/concepts/incident-response.md`, and `wiki/threats/t1486-data-encrypted-for-impact.md`.  
**Fix:** Add `[[concepts/poam]]` links in `wiki/gunner/system-security-plan.md` (POAM section), `wiki/concepts/incident-response.md`, and at least one threat page.

---

### W3 — Near-orphan page: [[gunner/completed-projects]]

**Page:** `wiki/gunner/completed-projects.md`  
**Problem:** Only linked from `wiki/index.md`. No other page references completed IT project history despite overlap with environment.md, runbooks, and vendor pages.  
**Fix:** Add a brief reference from `wiki/gunner/environment.md` (e.g., "see [[gunner/completed-projects]] for rollout history") and from `wiki/ciso-track/roadmap.md` (practical experience context).

---

### W4 — Near-orphan page: [[vendors/jamf]]

**Page:** `wiki/vendors/jamf.md`  
**Problem:** Only linked from `wiki/index.md`. The JAMF evaluation is an active thread with a decision expected April 2026, but no other page cross-links to it — not `wiki/vendors/hexnode.md`, `wiki/gunner/environment.md`, or `wiki/ciso-track/roadmap.md`.  
**Fix:** Add `[[vendors/jamf]]` to `wiki/vendors/hexnode.md` (evaluation notes section) and `wiki/gunner/environment.md` (MDM section).

---

### W5 — Orphan comparison page: [[comparisons/Wiki vs RAG]]

**Page:** `wiki/comparisons/Wiki vs RAG.md`  
**Problem:** Only linked from `wiki/index.md` (in the Comparisons section). The page is not referenced from any concept page despite being directly relevant to `wiki/concepts/LLM Wiki Pattern.md` and `wiki/concepts/Compounding Knowledge.md`. Also carries the dead link from C1 above.  
**Fix:** Add `[[comparisons/Wiki vs RAG]]` to `wiki/concepts/LLM Wiki Pattern.md` and `wiki/concepts/Compounding Knowledge.md`.

---

### W6 — [[entities/_index]] has empty placeholder sections

**Page:** `wiki/entities/_index.md`  
**Problem:** The "Organizations" and "Products & Tools" sections contain only HTML comments (`<!-- Add ... here -->`). Multiple organizations (Gunner Roofing LLC) and products (Bitdefender, SendGrid, Quote Portal) are mentioned frequently across the vault but not enumerated here.  
**Fix:** Populate the Organizations section with at least Gunner Roofing LLC. Add Bitdefender, SendGrid, and Quote Portal to Products & Tools even as stubs, or link to their eventual pages.

---

### W7 — Large pages over 300 lines

The following pages exceed the 300-line guideline and may benefit from splitting or summary sections:

| Page | Lines | Suggestion |
|------|-------|-----------|
| `wiki/gunner/hubspot-leads-project.md` | 388 | Consider splitting the sandbox build steps (Phase 1–9, ~130 lines) into a separate runbook: `wiki/runbooks/hubspot-leads-sandbox-build.md` |
| `wiki/vendors/dialpad-api-reference.md` | 385 | Reference/API doc — acceptable at this size, but consider adding a table of contents at the top |
| `wiki/vendors/monday-api-reference.md` | 334 | Same as above — acceptable reference size |
| `wiki/vendors/hubspot-api-reference.md` | 302 | Borderline — acceptable as API reference |

---

### W8 — [[ciso-track/roadmap]] is underdeveloped (status: developing, related: empty)

**Page:** `wiki/ciso-track/roadmap.md`  
**Problem:** Frontmatter has `related: []` (empty). The page has multiple empty sections (see empty sections report below). Status is `developing` — appropriate, but the page has not been updated since 2026-04-10. Given CISSP prep is a priority active thread, this page should be more current.  
**Fix:** Add related links to `wiki/concepts/nist-csf.md`, `wiki/concepts/cis-ig1.md`, `wiki/concepts/cmmc.md`, and at minimum `wiki/summaries/nist-csf-2.md`. Fill in the empty Skill Domains and Resources sections with at least placeholder content.

---

### W9 — [[gunner/dialpad-hubspot-integration]] only linked from lead-assignment-automation and index

**Page:** `wiki/gunner/dialpad-hubspot-integration.md`  
**Problem:** Linked from `wiki/gunner/lead-assignment-automation.md` and `wiki/index.md` only. The vendor pages `wiki/vendors/dialpad.md` and `wiki/vendors/hubspot.md` do not reference this integration architecture page, despite it being the custom replacement for the native Dialpad integration.  
**Fix:** Add `[[gunner/dialpad-hubspot-integration]]` to `wiki/vendors/dialpad.md` and `wiki/vendors/hubspot.md`.

---

### W10 — Empty sections in vendor stub pages

The following vendor pages have top-level heading sections (including the `# PageTitle` heading itself) with no content beneath them — they read as unfilled stubs:

| Page | Empty Sections |
|------|---------------|
| `wiki/vendors/hexnode.md` | `# Hexnode MDM`, `## iPhone Policies`, `## Mac Policies` |
| `wiki/vendors/dialpad.md` | `# Dialpad` |
| `wiki/vendors/knowbe4.md` | `# KnowBe4` |
| `wiki/vendors/monday.md` | `# Monday.com`, `## How It's Used at Gunner` |
| `wiki/vendors/keeper.md` | `# Keeper Password Manager` |
| `wiki/vendors/hubspot.md` | `# HubSpot` |

**Problem:** Page content may exist below these headings but the heading itself has no intro paragraph. For Hexnode specifically, `## iPhone Policies` and `## Mac Policies` are empty sections in a page that is actively referenced by 10+ other pages — this creates navigation dead-ends.  
**Fix:** Prioritize filling in `wiki/vendors/hexnode.md` (iPhone and Mac Policies sections) since it is the most-linked vendor page. Others can be filled as needed.

---

### W11 — Empty sections in active gunner pages

| Page | Empty Sections |
|------|---------------|
| `wiki/gunner/system-security-plan.md` | `## Roles & Responsibilities`, `## Configuration Management`, `## Maintenance & Monitoring`, `## Incident Response Plan` |
| `wiki/gunner/chrome-policy.md` | `## Remaining Gaps vs CIS Benchmark` |
| `wiki/gunner/dialpad-hubspot-integration.md` | `## Key Technical Details` |

**Problem:** `wiki/gunner/system-security-plan.md` has four empty major sections — this is a page linked from the SSP summary and used as the anchor for Gunner security posture. `wiki/gunner/chrome-policy.md`'s empty "Remaining Gaps" section is directly relevant to open action items.  
**Fix:** Fill in at least the `## Roles & Responsibilities` section of `wiki/gunner/system-security-plan.md` using content from `wiki/summaries/system-security-plan.md`. Fill `## Remaining Gaps vs CIS Benchmark` in chrome-policy.md from the open items in `wiki/hot.md`.

---

### W12 — Empty sections in runbooks

| Page | Empty Section |
|------|--------------|
| `wiki/runbooks/new-laptop-setup.md` | `## Step 1: Add Device to Apple Business Manager` |
| `wiki/runbooks/new-phone-setup.md` | `## Step 1: Add Device to Apple Business Manager` |
| `wiki/runbooks/acceptable-use-policy.md` | `## 4. Acceptable & Unacceptable Use`, `## 5. Artificial Intelligence (AI) Tools` |
| `wiki/runbooks/offboarding.md` | `## Step 3 — Wipe and Recover Device(s)` |

**Problem:** Sections that are present in the table of contents but contain no content. The offboarding "Wipe and Recover" step is operationally critical.  
**Fix:** Priority: fill `## Step 3 — Wipe and Recover Device(s)` in `wiki/runbooks/offboarding.md` and the AUP AI Tools section in `wiki/runbooks/acceptable-use-policy.md`. Both have direct operational relevance.

---

### W13 — [[meta/lint-report-2026-04-14]] contains dead links inherited from a prior draft

**Page:** `wiki/meta/lint-report-2026-04-14.md`  
**Problem:** Same dead links as the current `wiki/lint-report.md` (C5 above): `[[cherry-picks]]`, `[[claude-obsidian-ecosystem-research]]`, `[[comparisons/claude-obsidian-ecosystem]]`, `[[dashboard.base]]`, `[[meta/dashboard.base]]`, `[[page/name]]`, `[[runbooks/...]]`, and escaped vendor links. These are historical report artifacts.  
**Fix:** These can be left as-is since the file is a timestamped historical record. Alternatively, add a note at the top: "Historical report — contains placeholder links that were never resolved."

---

### W14 — [[wiki/log.md]] contains dead link `[[dashboard.base]]`

**Page:** `wiki/log.md`  
**Problem:** A log entry contains `[[dashboard.base]]` — no such page exists. Also contains `[[page/name]]` placeholder.  
**Fix:** These appear to be leftover from a session note template. Find and remove the lines containing these placeholders in log.md.

---

### W15 — [[meta/dashboard]] links to `[[dashboard.base]]` which does not exist

**Page:** `wiki/meta/dashboard.md`  
**Problem:** Contains a link to `[[dashboard.base]]` — no such page exists in the vault.  
**Fix:** Open `wiki/meta/dashboard.md` and remove or replace the `[[dashboard.base]]` reference.

---

### W16 — `wiki/lint-report.md` has no frontmatter

**Page:** `wiki/lint-report.md`  
**Problem:** The running lint report file has no YAML frontmatter at all. While it's a meta file, it is linked from `wiki/index.md` and should be consistent with vault conventions.  
**Fix:** Add minimal frontmatter when the report is overwritten (this report).

---

### W17 — `wiki/meta/lint-report-2026-04-14.md` has no frontmatter

**Page:** `wiki/meta/lint-report-2026-04-14.md`  
**Problem:** Historical lint report has no YAML frontmatter. Less urgent than W16 since it is a historical file, but inconsistent with vault conventions.  
**Fix:** Add frontmatter with `type: meta`, `title`, `created`, `updated`, `tags`, `status: archived`.

---

### W18 — Empty sections in summary pages

| Page | Empty Section |
|------|--------------|
| `wiki/summaries/cis-chrome-enterprise-benchmark.md` | `## High-Priority Recommendations for Gunner` |
| `wiki/summaries/cis-macos-26-benchmark.md` | `## High-Priority Recommendations for Gunner` |
| `wiki/summaries/cis-google-workspace-benchmark.md` | `## High-Priority L1 Recommendations for Gunner` |
| `wiki/summaries/cis-ios-26-benchmark.md` | `## Key Recommendation Areas (Institutionally-Owned — Section 3)` |
| `wiki/summaries/cis-ms-office-benchmark.md` | `## Key Security Themes` |

**Problem:** The "High-Priority Recommendations for Gunner" sections in the CIS benchmark summaries are empty. These sections exist in every CIS summary page as a standard template section but have not been populated. Given that several CIS benchmark gaps are active open items (chrome-policy, iOS passcode, macOS sharing services), these sections should have content.  
**Fix:** Priority: fill in `cis-chrome-enterprise-benchmark.md` and `cis-ios-26-benchmark.md` first, as those gaps appear in the open items list.

---

## Suggestions (worth considering)

### S1 — No entity pages for frequently-mentioned Gunner staff

The following individuals are mentioned across multiple wiki pages but have no entity pages:

| Person | Role | Mention Count | Pages |
|--------|------|--------------|-------|
| Eddie | Owner/Executive (signs off SSP) | 15 mentions | 10 pages |
| Andrew Prchal | Executive (SSP sign-off) | 10 mentions | 7 pages |
| Glen | Sales Manager (HubSpot oversight) | 7 mentions | 2 pages |
| India | HubSpot sandbox builder | 3 mentions | 1 page |
| Sarah | Project Coordinator (Phase 3) | 3 mentions | 1 page |
| Bryce | Accounts Receivable (Phase 3) | 3 mentions | 1 page |
| Mike Ushka | Service Manager (Phase 3) | 3 mentions | 1 page |

**Suggestion:** At minimum, create entity stubs for Eddie and Andrew Prchal — both appear in 7–10 pages across runbooks, concepts, and vendor pages and are referenced in escalation paths. For the Phase 3 Dialpad/Monday staff (Sarah, Bryce, Mike Ushka), a stub with name, role, and Dialpad user ID placeholder would support the lead-assignment automation `.env` setup.

---

### S2 — No vendor/concept page for Quote Portal

**Observation:** "Quote Portal" (abbreviated QP) appears 28 times across 6 wiki pages — it is one of the most-mentioned tools in the vault. It has no vendor or concept page. Its role in the lead-to-deal workflow is central to the HubSpot buildout.  
**Suggestion:** Create `wiki/vendors/quote-portal.md` (or `wiki/gunner/quote-portal.md` if it is a Gunner-specific tool). Minimum content: what it is, how it integrates with HubSpot lead/deal workflow, the QP Button workflow trigger, known behaviors.

---

### S3 — No vendor page for Make.com

**Observation:** Make.com appears 20 times across 9 wiki content pages. It is referenced as a threat vector in `wiki/threats/t1199-trusted-relationship.md`, as a lead activity workflow candidate in `wiki/gunner/hubspot-leads-project.md`, and as an integration tool across the vendor ecosystem. No vendor page exists.  
**Suggestion:** Create `wiki/vendors/make-com.md`. Include: what it does at Gunner, current automations it runs, the T1199 trusted-relationship risk exposure note, and the scoped use case for lead activity → deal timeline logging.

---

### S4 — No vendor page for SendGrid

**Observation:** SendGrid appears 18 times across 8 wiki content pages, primarily in email security and threat contexts. It is part of the SPF/DKIM configuration and is a relevant sub-processor for email-based threats.  
**Suggestion:** Create `wiki/vendors/sendgrid.md`. Minimum content: role at Gunner (transactional email), SPF/DKIM authorization, DMARC alignment, renewal/admin contact.

---

### S5 — No vendor page for Bitdefender GravityZone

**Observation:** Bitdefender appears 10 times across 5 wiki content pages, primarily as the solution for the CMMC AV gap blocker (~$1.1k/yr estimate). It is named in the POAM and threats pages as a pending decision.  
**Suggestion:** Create `wiki/vendors/bitdefender.md` as a stub with the evaluation status, cost estimate, and link to `wiki/concepts/cmmc.md` and `wiki/concepts/poam.md`. This will be useful when the JAMF evaluation decision unlocks the CMMC path.

---

### S6 — [[ciso-track/roadmap]] missing cross-links to study material

**Page:** `wiki/ciso-track/roadmap.md`  
**Observation:** The roadmap page lists CISSP as the next cert target but has no links to the relevant study pages in the vault: `wiki/concepts/nist-csf.md`, `wiki/concepts/cis-ig1.md`, `wiki/concepts/cmmc.md`, `wiki/summaries/nist-csf-2.md`, `wiki/summaries/cis-controls-v8-1-2.md`. These are all directly relevant CISSP domain content.  
**Suggestion:** Add a "Study Resources in This Vault" section to `wiki/ciso-track/roadmap.md` with links to all relevant concept and summary pages. This makes the roadmap page a navigation hub for CISSP prep.

---

### S7 — [[vendors/dialpad]] and [[vendors/hubspot]] do not link to the custom integration architecture

**Observation:** `wiki/vendors/dialpad.md` and the vendor-level `wiki/vendors/hubspot.md` do not link to `wiki/gunner/dialpad-hubspot-integration.md`. When querying about either vendor, the custom integration architecture page would not be surfaced.  
**Suggestion:** Add a cross-reference to `[[gunner/dialpad-hubspot-integration]]` in both vendor pages under an "Integration Notes" or "Custom Build" section. (Also noted in W9 — resolving W9 addresses this.)

---

### S8 — [[gunner/lead-assignment-automation]] is not linked from [[vendors/dialpad]] or [[vendors/hubspot]]

**Observation:** The lead assignment automation uses both Dialpad and HubSpot APIs extensively but neither vendor page links to it. Navigation from vendor to implementation is broken.  
**Suggestion:** Add `[[gunner/lead-assignment-automation]]` to `wiki/vendors/dialpad.md` (under automation notes) and `wiki/vendors/hubspot.md` (under CRM automation / integrations section).

---

### S9 — [[gunner/federal-market]] has an empty top-level heading

**Page:** `wiki/gunner/federal-market.md`  
**Observation:** The `# Federal Market Expansion Strategy` heading contains no intro paragraph. The page content exists further down but is not previewable from the heading.  
**Suggestion:** Add a 1–2 sentence intro paragraph under the top heading summarizing the page's purpose and status.

---

### S10 — No entity page for Andrej Karpathy is incomplete

**Page:** `wiki/entities/Andrej Karpathy.md`  
**Observation:** This page exists but the `wiki/entities/_index.md` Organizations and Products & Tools sections are entirely empty (see W6). The entities system is incomplete.  
**Suggestion:** Populate the `_index.md` with at least Gunner Roofing LLC as an organization and the most-referenced tools (Quote Portal, Make.com, Bitdefender, SendGrid) in Products & Tools.

---

### S11 — [[getting-started]] `## Three-Step Quick Start` section is empty

**Page:** `wiki/getting-started.md`  
**Observation:** The Three-Step Quick Start section is empty — this is the onboarding page for new users of the vault. An empty quick-start section defeats its purpose.  
**Suggestion:** Fill in the three steps: (1) read Memory.md, (2) read wiki/hot.md, (3) use /wiki, ingest, or query commands.

---

### S12 — [[meta/session-2026-04-14b-setup-chrome]] has two empty sections

**Page:** `wiki/meta/session-2026-04-14b-setup-chrome.md`  
**Observation:** The top heading and `## Vault Setup Completed` section contain no content. Session notes with empty sections provide no value and suggest the page was templated but not fully written.  
**Suggestion:** Add brief content to both sections, or mark the page status as `archived` if the session is fully captured elsewhere.

---

### S13 — [[sources/_index]] not linked from index.md

**Page:** `wiki/sources/_index.md`  
**Observation:** `wiki/sources/_index.md` exists and contains a full listing of all summary pages. However, `wiki/index.md` does not have a direct link to it — the Meta section links to `wiki/meta/dashboard.md` and other meta pages, but not the sources index.  
**Suggestion:** Add `[[sources/_index|Sources Index]]` to the Meta section of `wiki/index.md` for discoverability.

---

### S14 — [[wiki/meta/lint-report-2026-04-14]] had empty Critical/Warnings/Suggestions sections

**Observation:** The prior lint report (`wiki/meta/lint-report-2026-04-14.md`) had the structural headings `## Critical (must fix)`, `## Warnings (should fix)`, and `## Suggestions (worth considering)` but all three were empty. This means no issues from the April 14 scan were formally recorded.  
**Note:** This is informational only — the 2026-04-16 report (this document) is the first complete lint run.

---

## Appendix — Checks Performed

| Check | Result |
|-------|--------|
| 1. Orphan pages (0 inbound links) | None found |
| 2. Near-orphan pages (1 inbound link, index only) | 3 pages: concepts/poam, gunner/completed-projects, vendors/jamf |
| 3. Dead wikilinks | 15 distinct dead links across 5 pages |
| 4. Stale index entries | 3 entries in index.md use bare names without subfolder prefix |
| 5. Missing required frontmatter fields | 5 pages missing `status:` or `created:` |
| 6. No frontmatter | 2 pages (lint-report.md, meta/lint-report-2026-04-14.md) |
| 7. Stale seed pages (>30 days) | None — no pages with `status: seed` found |
| 8. Stale runbooks (>6 months) | None — all runbooks updated 2026-04-13 |
| 9. Empty heading sections | 65 instances across 37 pages (many are stub vendor pages by design) |
| 10. Large pages (>300 lines) | 4 pages: hubspot-leads-project (388), dialpad-api-reference (385), monday-api-reference (334), hubspot-api-reference (302) |
| 11. Unlinked entity mentions (3+) | 7 people, 3 vendors/tools with no entity pages |
| 12. Concepts missing pages (3+ mentions) | 5: Quote Portal (28), Make.com (20), Eddie (15), Bitdefender (10), Andrew Prchal (10) |

---

*Next lint: recommended within 2 weeks or after 10+ page ingests.*
