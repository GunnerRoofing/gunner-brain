---
title: Lint Report — 2026-05-12
type: meta
tags:
  - lint
  - health-check
  - meta
created: '2026-05-12'
updated: '2026-05-12'
status: stable
---

# Wiki Lint Report — 2026-05-12

**Vault:** Gunner Vault
**Scope:** Full wiki (delta focus: changes since 2026-05-07)
**Pages scanned:** ~114 .md files
**Checks run:** 8 (orphans, dead links, stale claims, missing pages, unlinked mentions, frontmatter gaps, empty sections, stale index entries)

---

## Summary

- Pages scanned: 114
- Issues found: 14
- Carried forward from 2026-05-07 (not yet fixed): 9
- New since 2026-05-07: 5
- Fixed 2026-05-12: 11 (C1, W1, W2, W3, S1, S2, S4 — see Resolved section below)
- False positives confirmed: 2 (W4, W5)

---

## Critical (must fix)

### C1 — Dead wikilinks in old lint reports ✅ RESOLVED 2026-05-12

- **Affected pages:** [[meta/lint-report-2026-04-14]], [[meta/lint-report-2026-04-16]]
- **Fix applied:** `lint-report-2026-04-14.md` W2 table had an actual `[[comparisons/claude-obsidian-ecosystem]]` wikilink — replaced with plain text.
- **Note:** Occurrences in `lint-report-2026-04-16.md` (C5 and W13 sections) are inside backtick code spans and do not generate live wikilinks — confirmed false positive for that file.

---

## Warnings (should fix)

### W1 — Index entry for `gunner-forms-app` is significantly stale ✅ RESOLVED 2026-05-12

- **Fix applied:** Updated `wiki/index.md` description to: *"Gunner Team iOS app — fleet management, vehicle inspections, maintenance tracking, CompanyCam integration, announcements, native forms; Express API on EC2"*

---

### W2 — `vendors/companycam` page missing ✅ RESOLVED 2026-05-12

- **Fix applied:** Created `wiki/vendors/companycam.md` — internal instance URL, SSO, API proxy architecture, upload bug callout, links to [[gunner/gunner-forms-app]].

---

### W3 — JAMF vendor page not updated after evaluation deadline ⚠️ PARTIALLY ADDRESSED 2026-05-12

- **Fix applied:** Updated `updated` frontmatter to 2026-05-12. Existing gap callout on the page already flags the unknown decision status.
- **Remaining:** Tyler to confirm current JAMF evaluation status (approved / rejected / delayed / on hold) and record the decision.

---

### W4 — Empty `## High-Priority Recommendations` sections in CIS benchmark summaries ✅ FALSE POSITIVE (confirmed 2026-05-12)

- **Status:** All 5 CIS benchmark summary pages were verified by reading current file content. Each "High-Priority Recommendations" section IS populated with content (filled in a prior session not reflected in the 2026-05-07 lint snapshot). No action needed.

---

### W5 — `gunner/it-decision-log` key decisions section may be empty ✅ FALSE POSITIVE (confirmed 2026-05-12)

- **Status:** File verified by read — the "Key Decisions on Record" table is fully populated (SEC-001, SEC-002, CHG-2026-001/002/003, vendor table, exceptions). No action needed.

---

## Suggestions (worth considering)

### S1 — `entities/Eric Recchia` still missing ✅ RESOLVED 2026-05-12

- **Fix applied:** Created `wiki/entities/Eric Recchia.md` — role, SSP System Owner, CIS IG1 authorization, IR escalation path. Added to `wiki/index.md` Entities section.

---

### S2 — Unlinked Prchal mentions across 12 pages ✅ RESOLVED 2026-05-12

- **Fix applied:** Added [[entities/Eddie Prchal]], [[entities/Andrew Prchal]], and [[entities/Eric Recchia]] wikilinks across: concepts/cis-ig1, concepts/incident-response, gunner/completed-projects, gunner/environment, gunner/system-security-plan, runbooks/incident-response, summaries/system-security-plan, vendors/google-workspace, vendors/knowbe4, summaries/my-notebook-gunner-roofing.
- **Note:** getting-started and gunner/it-decision-log had no plaintext name occurrences on review — skipped.

---

### S3 — Canvas index entry format (carried from C1-A in prior report, downgraded)

- **Affected page:** [[index]] (Canvases section)
- **Problem:** `[[canvases/main.canvas\|main]]` — the file `wiki/canvases/main.canvas` confirmed to exist, so this is not a dead link. However the escaped pipe syntax `\|` is unusual and may render oddly in some Obsidian views. `[[Wiki Map]]` at vault root is a `.canvas` file and links correctly.
- **Suggested fix:** Low priority. Test in Obsidian — if it renders correctly, no action needed.

---

### S4 — Stub pages still thin ⚠️ PARTIALLY RESOLVED 2026-05-12

| Page | Status |
|------|--------|
| [[vendors/quote-portal]] | Still thin — no usage context |
| [[vendors/sendgrid]] | ✅ Updated — GunnerForms transactional email context added; status promoted to stable |
| [[vendors/bitdefender]] | ✅ Updated — JAMF/Defender relationship documented; gap callout added |

---

### S5 — CompanyCam CC API upload bug should be tracked as an open item (NEW)

- **Affected page:** [[gunner/gunner-forms-app]] (CompanyCam Feature section)
- **Problem:** The CC API upload bug (returns 400/500 for all formats) is documented inline but has no dedicated tracking. It requires action from the CompanyCam app maintainer. Currently only in the Open Items checklist.
- **Suggested fix:** Ensure this is captured in Memory.md open items (check). When a `vendors/companycam` page is created (W2), move the bug note there for visibility.

---

### S6 — `comparisons/` and `sources/` sections are thin (minor)

- `wiki/comparisons/` has only `Wiki vs RAG.md` — one file for an entire directory.
- `wiki/sources/_index.md` is the only file in `wiki/sources/` — the index points elsewhere.
- Neither is broken, just noted for awareness.

---

## Resolved Since 2026-05-07

| Issue | Status |
|-------|--------|
| C2-A: `monday-pm-my-work-view-setup` missing `status` | ✅ Fixed — `status: stable` present |
| C1-A: `[[canvases/main]]` dead link | ✅ Re-evaluated — `wiki/canvases/main.canvas` exists; not a dead link |
| W1-A: `meta/gunnerforms-auth-build-2026-04-28` orphan | ✅ Fixed — added to index.md |
| S4: Same page missing from index | ✅ Fixed — listed in Meta section |

### Fixed 2026-05-12

| Issue | Status |
|-------|--------|
| C1: Dead wikilink in lint-report-2026-04-14.md W2 table | ✅ Replaced with plain text |
| C1 (04-16): Occurrences in backtick code spans | ✅ Confirmed false positive — code spans don't create live links |
| W1: Stale index description for gunner-forms-app | ✅ Updated to Gunner Team app description |
| W2: vendors/companycam missing | ✅ Created wiki/vendors/companycam.md |
| W3: vendors/jamf not updated | ⚠️ Updated date; status requires Tyler input |
| W4: CIS benchmark empty sections | ✅ Confirmed false positive — sections are populated |
| W5: it-decision-log empty decisions | ✅ Confirmed false positive — table is populated |
| S1: entities/Eric Recchia missing | ✅ Created wiki/entities/Eric Recchia.md; added to index |
| S2: Unlinked Prchal/Recchia mentions | ✅ Wikilinks added across 10 pages |
| S4: vendors/sendgrid thin | ✅ Added GunnerForms transactional email context |
| S4: vendors/bitdefender thin | ✅ Added JAMF/Defender relationship and gap callout |

---

*Report generated: 2026-05-12. Next recommended run: 2026-06-12 or after next major ingest/build session.*
