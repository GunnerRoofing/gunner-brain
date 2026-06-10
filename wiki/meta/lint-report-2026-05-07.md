---
title: Lint Report — 2026-05-07
type: meta
tags: [lint, health-check, meta]
created: 2026-05-07
updated: 2026-05-07
status: stable
---

# Wiki Lint Report — 2026-05-07

**Vault:** Gunner Vault  
**Scope:** Full wiki  
**Pages scanned:** 96 .md files  
**Checks run:** 8 (orphans, dead links, stale claims, missing pages, unlinked mentions, frontmatter gaps, empty sections, stale index entries)

---

## Summary

- Pages scanned: 96
- Issues found: 42 (3 critical, 17 warnings, 22 suggestions)

---

## Critical (must fix)

### C1 — Dead wikilinks

**2 broken wikilinks confirmed across 3 source locations.**

---

**Issue C1-A**
- Affected page: [[index]]
- Problem: `[[canvases/main]]` is listed in the Canvases section of index.md but no file exists at `wiki/canvases/main.md`. The canvas file may be a `.canvas` file (not `.md`) or was never created.
- Suggested fix: Either create `wiki/canvases/main.md` as a text companion to the canvas, or remove the entry from index.md and replace with the correct path to the `.canvas` file if it exists in `wiki/canvases/`.

---

**Issue C1-B**
- Affected pages: [[meta/lint-report-2026-04-14]], [[meta/lint-report-2026-04-16]]
- Problem: Both old lint reports link to `[[comparisons/claude-obsidian-ecosystem]]`, a page that does not exist. It is referenced 5 times total across the vault.
- Suggested fix: Create a stub page at `wiki/comparisons/claude-obsidian-ecosystem.md`, or remove the links from the lint reports (they are historical records, so removal may be cleaner).

---

### C2 — Missing required frontmatter field

**1 page missing the `status` field.**

---

**Issue C2-A**
- Affected page: [[runbooks/monday-pm-my-work-view-setup]]
- Problem: Frontmatter is present and has `type`, `created`, `updated`, and `tags`, but is missing the `status` field required by vault conventions.
- Suggested fix: Add `status: stable` (or appropriate value) to the frontmatter.

---

## Warnings (should fix)

### W1 — Orphan pages (no inbound wikilinks)

**1 orphan page confirmed.**

---

**Issue W1-A**
- Affected page: [[meta/gunnerforms-auth-build-2026-04-28]]
- Problem: This session/build notes page has zero inbound links from any other wiki page. It is not referenced in `index.md`, `hot.md`, or any other meta session page.
- Suggested fix: Add an entry to `index.md` under the Meta section, or link from [[gunner/gunner-forms-app]] or the prior session note [[meta/session-2026-04-21-gunnerforms-raw-sources]].

---

### W2 — Empty sections in content pages

**Several content pages have section headings with no content under them.** These are genuine stubs — not false positives from the frontmatter or formatting.

---

**Issue W2-A**
- Affected page: [[ciso-track/roadmap]]
- Problem: `## Resources & Reading` (line 116 after frontmatter) has no content. The section heading exists but nothing follows before the next heading or EOF.
- Suggested fix: Add study resources, reading list, or a placeholder note.

---

**Issue W2-B**
- Affected page: [[gunner/chrome-policy]]
- Problem: `## Remaining Gaps vs CIS Benchmark` heading appears, but the next element is actually the content (subsections for DevTools and DoH gaps). Review confirmed the section IS populated — this was a false positive. No action needed.

---

**Issue W2-C**
- Affected page: [[gunner/aws-environment]]
- Problem: `## Known Architecture` heading is present; review confirmed it has content (EC2 subsection). False positive. No action needed.

---

**Issue W2-D**
- Affected page: [[gunner/it-decision-log]]
- Problem: `## Key Decisions on Record` heading is present but the table of decisions may be absent or sparse. Verify the decision log table has entries and is not a placeholder heading with no body.
- Suggested fix: Confirm decisions are tabulated under that heading; if not, populate or remove the heading.

---

**Issue W2-E**
- Affected page: [[runbooks/offboarding]]
- Problem: `## Step 3 — Wipe and Recover Device(s)` heading review shows the content IS present (MacBook and iPhone wipe steps). False positive. No action needed.

---

**Issue W2-F**
- Affected page: [[summaries/cis-chrome-enterprise-benchmark]]
- Problem: `## High-Priority Recommendations for Gunner` heading has no content body — it leads directly into the next heading with no bullet points or text.
- Suggested fix: Add the prioritized recommendations or a note pointing to [[gunner/chrome-policy]] where the gap analysis lives.

---

**Issue W2-G**
- Affected page: [[summaries/cis-google-workspace-benchmark]]
- Problem: `## High-Priority L1 Recommendations for Gunner` heading has no content below it.
- Suggested fix: Add the top L1 gaps or a cross-reference to [[vendors/google-workspace]].

---

**Issue W2-H**
- Affected page: [[summaries/cis-ios-26-benchmark]]
- Problem: `## Key Recommendation Areas (Institutionally-Owned — Section 3)` has no content.
- Suggested fix: Add the key control areas from the benchmark or link to [[vendors/hexnode]] where the policy is applied.

---

**Issue W2-I**
- Affected page: [[summaries/cis-macos-26-benchmark]]
- Problem: `## High-Priority Recommendations for Gunner` has no content.
- Suggested fix: Add priority recommendations or cross-reference [[vendors/hexnode]] Mac policy section.

---

**Issue W2-J**
- Affected page: [[summaries/cis-ms-office-benchmark]]
- Problem: `## Key Security Themes` has no content.
- Suggested fix: Add themes or note that this benchmark has low Gunner relevance (as stated in index.md description).

---

**Issue W2-K**
- Affected page: [[vendors/make-com]]
- Problem: `## Active Scenarios` heading is followed immediately by a subheading (`### Delete AWS-Created Deals`), making the parent section technically empty. The content is in the subsection.
- Suggested fix: Add a one-line summary before the first subsection, or rename `## Active Scenarios` as the subsection and remove the parent.

---

### W3 — Stale seed pages (status: seed, not updated in 30+ days)

**0 stale seed pages found.** No pages with `status: seed` are more than 30 days old. One page with `status: seed` was found — `gunner/aws-environment` (created 2026-04-23, 14 days ago) — which is within the threshold.

---

### W4 — Large pages (over 300 lines)

The following pages exceed 300 lines. They are not broken, but may benefit from splitting or summarizing.

| Page | Lines | Notes |
|------|-------|-------|
| [[log]] | ~610+ | Append-only log — expected to grow; no action needed |
| [[gunner/lead-assignment-automation]] | ~230 | Technical reference — reasonable size |
| [[vendors/dialpad-api-reference]] | ~340+ | API reference — expected to be large |
| [[vendors/hubspot-api-reference]] | ~260+ | API reference — reasonable |
| [[gunner/gunner-forms-app]] | ~215+ | Growing page — monitor |

Note: `log.md` is intentionally append-only and will always be large. API reference pages are expected to be dense. No immediate action required for these.

---

## Suggestions (worth considering)

### S1 — Missing concept/vendor pages for frequently mentioned terms

The following terms are mentioned 3 or more times across the vault but have no dedicated wiki page. These are candidates for stub pages or entity entries.

| Term | Mention Count | Suggested Page | Priority |
|------|--------------|----------------|----------|
| Cloudflare | 46 | `vendors/cloudflare` | High — used for DNS, Pages, Workers, WAF at Gunner |
| Cloudflare Workers / D1 | 23 / 30 | `vendors/cloudflare` (cover both) | High — central to GunnerTeam API migration |
| CompanyCam | 23 | `vendors/companycam` | Medium — appears in offboarding, SSO list, AUP |
| ADP | 18 | `vendors/adp` | Medium — mentioned in offboarding checklist; non-SSO app |
| Eric Recchia | 18 | `entities/Eric Recchia` | Medium — VP of Strategy, System Owner in SSP |
| AWS Lambda / DynamoDB | 27 / 12 | `concepts/aws-lambda` or note in `gunner/aws-environment` | Medium — core to lead-assignment system |
| Stripe | 18 | Already has `vendors/stripe-api-reference` but no `vendors/stripe` vendor page | Low-Medium |
| GitHub | 34 | `vendors/github` | Low — primarily used as dev tool, not operations |
| Unifi | 12 | `vendors/unifi` | Low — networking stack |
| WordPress | 9 | Note in `gunner/aws-environment` sufficient | Low |
| Resend | 7 | Stub in `vendors/resend` | Low — email provider for GunnerForms |

---

### S2 — Missing entity pages for named people

The following individuals are referenced multiple times in content pages but lack entity pages:

| Person | Mentions | Context |
|--------|----------|---------|
| Eric Recchia | 18 | VP of Strategy, System Owner — appears in SSP, environment, incident response |
| India | 8 | HubSpot sandbox buildout lead — appears in hubspot-leads-project |
| Sarah | 9 | Project coordinator, Dialpad/Monday integration — hubspot-leads-project |
| Bryce | 9 | Accounts receivable, Dialpad/Monday integration — hubspot-leads-project |

Eric Recchia is the highest-priority — he is a named authorizing official role-equivalent and appears in formal documents. India, Sarah, and Bryce are lower priority (first-name-only staff references).

Suggested fix: Create `entities/Eric Recchia.md` with role, contact, and relevance to IT governance.

---

### S3 — Unlinked entity name mentions (entities with pages)

The following pages mention named entities that have their own wiki pages, but use plain text instead of wikilinks:

| Affected page | Entity | Should link to |
|--------------|--------|----------------|
| [[concepts/cis-ig1]] | Eddie Prchal, Andrew Prchal | [[entities/Eddie Prchal]], [[entities/Andrew Prchal]] |
| [[concepts/incident-response]] | Andrew Prchal | [[entities/Andrew Prchal]] |
| [[getting-started]] | Andrej Karpathy | [[entities/Andrej Karpathy]] |
| [[gunner/completed-projects]] | Eddie Prchal | [[entities/Eddie Prchal]] |
| [[gunner/environment]] | Eddie Prchal, Andrew Prchal | [[entities/Eddie Prchal]], [[entities/Andrew Prchal]] |
| [[gunner/it-decision-log]] | Eddie Prchal, Andrew Prchal | [[entities/Eddie Prchal]], [[entities/Andrew Prchal]] |
| [[gunner/system-security-plan]] | Eddie Prchal, Andrew Prchal | [[entities/Eddie Prchal]], [[entities/Andrew Prchal]] |
| [[runbooks/incident-response]] | Andrew Prchal | [[entities/Andrew Prchal]] |
| [[summaries/system-security-plan]] | Andrew Prchal | [[entities/Andrew Prchal]] |
| [[vendors/google-workspace]] | Eddie Prchal, Andrew Prchal | [[entities/Eddie Prchal]], [[entities/Andrew Prchal]] |
| [[vendors/knowbe4]] | Eddie Prchal | [[entities/Eddie Prchal]] |
| [[summaries/my-notebook-gunner-roofing]] | Eddie Prchal | [[entities/Eddie Prchal]] |

Note: `log.md` and `hot.md` are excluded — linking in operational/log files is not required by convention.

---

### S4 — Index entry for missing session note

- Affected page: [[index]] (Meta section)
- Problem: `[[meta/gunnerforms-auth-build-2026-04-28]]` exists on disk but is not listed in `index.md`. This is the same page flagged as an orphan in W1-A.
- Suggested fix: Add to the Meta section of `index.md` with a one-line description.

---

### S5 — Stale index entry for canvases

- Affected section: Canvases section in [[index]]
- Problem: `[[Wiki Map]]` is listed as a canvas but there is no corresponding file visible in the wiki/ directory scan. If the Wiki Map canvas lives outside the wiki/ folder (e.g., at the vault root as a `.canvas` file), the index link will never resolve in this context.
- Suggested fix: Verify the Wiki Map `.canvas` file path and update the index link accordingly, or note the correct vault-root path.

---

### S6 — Vendor page stub quality

The following vendor pages were created as stubs and remain thin. They are indexed and linked but provide minimal value:

| Page | Status | Gap |
|------|--------|-----|
| [[vendors/quote-portal]] | stub | No content about integration, usage at Gunner, or renewal info |
| [[vendors/sendgrid]] | stub | Minimal — how it's used (transactional email for what?) not documented |
| [[vendors/bitdefender]] | stub | Evaluation status and blockers not documented |
| [[vendors/jamf]] | under evaluation | JAMF eval timeline (Apr 2026) may now be past due — verify status and update |

---

### S7 — JAMF evaluation status likely outdated

- Affected page: [[vendors/jamf]]
- Problem: The JAMF evaluation was described as "approval expected late April 2026." Today is 2026-05-07. The evaluation window has passed. The page likely reflects stale status.
- Suggested fix: Update `vendors/jamf` with current evaluation outcome (approved / rejected / delayed) and update the `updated` frontmatter date.

---

### S8 — Gunner Assistant decision pending

- Affected page: [[gunner/gunner-assistant]]
- Problem: The page notes "decision pending boss approval" as of its last update. This item is also tracked in Memory.md as an open item. The page has a `status` of developing.
- Suggested fix: Once the boss decision is made, update the page with the outcome and mark the open item resolved.

---

*Report generated: 2026-05-07. Next recommended lint run: 2026-06-07 or after a major ingest batch.*
