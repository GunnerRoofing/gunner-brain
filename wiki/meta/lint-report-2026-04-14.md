---
title: "Lint Report 2026-04-14"
type: meta
created: 2026-04-14
updated: 2026-04-14
tags: [meta, lint]
status: stable
---

# Lint Report

Generated: 2026-04-14 (full-vault health check post upstream claude-obsidian merge)

Previous report notes preserved at bottom of file.

---

## Summary

- **Pages scanned:** 68
- **Issues found:** 24 (5 critical, 10 warnings, 9 suggestions)
- **Vault structure:** Healthy — raw-sources/ clean, all 4 hooks wired, all required files present
- **Credentials:** No actual credentials found (2 false positives confirmed safe)

---

## Critical (must fix)

### C1 — Broken wikilink: [[meta/boss-setup-guide]] in index.md

**Affected page:** [[index]]
**Problem:** `index.md` links to `[[meta/boss-setup-guide]]` in the Meta section. This file does not exist. The actual file is `wiki/meta/claude-obsidian-setup-guide.md` (renamed during upstream merge).
**Fix:** In `index.md`, change `[[meta/boss-setup-guide]]` to `[[meta/claude-obsidian-setup-guide]]`.

---

### C2 — Broken wikilinks: upstream demo pages in comparisons/claude-obsidian-ecosystem

**Affected page:** `comparisons/claude-obsidian-ecosystem` (since deleted)
**Problem:** This upstream template page contains three broken wikilinks pointing to demo content never migrated to this vault:
- `[[cherry-picks]]` (3 occurrences) — exists only in `_system/claude-obsidian-main/wiki/concepts/`
- `[[claude-obsidian-ecosystem-research]]` — exists only in `_system/claude-obsidian-main/wiki/sources/`
- `[[Andrej Karpathy]]` — exists only in `_system/claude-obsidian-main/wiki/entities/`

**Fix:** Delete this upstream demo page (it is also orphaned — nothing links to it), or strip the broken links if the content is useful.

---

### C3 — Broken wikilink: [[Andrej Karpathy]] across upstream concept pages

**Affected pages:** [[concepts/LLM Wiki Pattern]], [[concepts/Compounding Knowledge]], [[entities/_index]], [[sources/_index]]
**Problem:** Four pages link to `[[Andrej Karpathy]]` which does not exist in this vault. These are upstream template pages that reference a demo entity only found in `_system/claude-obsidian-main/`.
**Fix:** Remove `[[Andrej Karpathy]]` links and replace with plain text references, or create a stub entity page at `wiki/entities/Andrej Karpathy.md`.

---

### C4 — Broken wikilink: [[concepts/_index]] does not exist

**Affected pages:** [[concepts/LLM Wiki Pattern]], [[concepts/Compounding Knowledge]], [[concepts/Hot Cache]], [[sources/_index]], [[entities/_index]]
**Problem:** Five pages link to `[[concepts/_index]]` but no such file exists. The `entities/_index.md` and `sources/_index.md` files exist but `concepts/` has no equivalent.
**Fix:** Create `wiki/concepts/_index.md` as a simple index of all concept pages, or remove the broken links from the five affected pages.

---

### C5 — Malformed wikilinks with backslash in gunner/environment.md

**Affected page:** [[gunner/environment]]
**Problem:** Three wikilinks in the SaaS Stack table use `\|` instead of `|` for the display alias separator. This is broken syntax in Obsidian — the backslash corrupts the link.

Lines 74–76:
```
[[vendors/hexnode\|Hexnode MDM]]
[[vendors/keeper\|Keeper]]
[[vendors/knowbe4\|KnowBe4]]
```
**Fix:** Replace `\|` with `|` in all three links.

---

## Warnings (should fix)

### W1 — Orphan pages (no inbound links)

Three pages have no inbound links from anywhere in the wiki:

| Page | Notes |
|------|-------|
| [[comparisons/Wiki vs RAG]] | Upstream template; not in index, not referenced by any page |
| `comparisons/claude-obsidian-ecosystem` | Upstream template with broken links (see C2) — page since deleted |
| [[meta/claude-obsidian-setup-guide]] | Renamed from boss-setup-guide; index still points to old name |

**Fix:** Add index entries for the two comparisons pages (or decide to delete/archive), and fix the index entry for `meta/claude-obsidian-setup-guide` (resolves C1 simultaneously).

---

### W2 — Eight pages missing from index.md

| Page | Notes |
|------|-------|
| [[comparisons/Wiki vs RAG]] | Upstream template |
| comparisons/claude-obsidian-ecosystem | Upstream template with broken links (page since deleted) |
| [[concepts/Compounding Knowledge]] | Upstream concept |
| [[concepts/Hot Cache]] | Upstream concept |
| [[concepts/LLM Wiki Pattern]] | Upstream concept |
| [[entities/_index]] | Index page; should be in Meta section |
| [[meta/claude-obsidian-setup-guide]] | Renamed page (replaces broken boss-setup-guide entry) |
| [[sources/_index]] | Index page; should be in Meta section |

**Fix:** Add a "System / Reference" section to `index.md` for the three upstream concept pages and two comparisons pages. Add `sources/_index` and `entities/_index` to the Meta section. Fix the `boss-setup-guide` entry (C1).

---

### W3 — Threat page missing runbook link: threats/t1110-brute-force

**Affected page:** [[threats/t1110-brute-force]]
**Problem:** The only threat page with no `[[runbooks/...]]` wikilink. T1110 links to `[[concepts/mfa]]` and `[[vendors/keeper]]` but does not link to `[[runbooks/incident-response]]` (account compromise procedures) or `[[runbooks/offboarding]]` (deprovisioning as mitigation).
**Fix:** Add links to `[[runbooks/incident-response]]` and `[[runbooks/offboarding]]` in the T1110 Related or Mitigations section.

---

### W4 — Missing frontmatter field: status

| Page | Missing field |
|------|--------------|
| [[gunner/system-security-plan]] | `status` |
| [[summaries/cis-google-workspace-benchmark]] | `status` |

**Fix:** Add `status: stable` (or appropriate value) to both pages' frontmatter.

---

### W5 — Missing frontmatter field: created

| Page | Missing field |
|------|--------------|
| [[entities/_index]] | `created` |
| [[getting-started]] | `created` |
| [[meta/dashboard]] | `created` |
| [[sources/_index]] | `created` |

**Fix:** Add `created: 2026-04-14` to frontmatter of all four pages.

---

### W6 — Stale .raw/ references in upstream files

Several files still use the old `.raw/` path instead of `raw-sources/`. The `commands/wiki.md` was already corrected. Remaining files:

| File | Occurrences |
|------|-------------|
| `wiki/canvases/welcome.canvas` | 1 (text node instructing users to drop files into `.raw/`) |
| `wiki/concepts/LLM Wiki Pattern.md` | 2 (diagram and ingest description) |
| `skills/wiki/references/frontmatter.md` | 1 (example sources field) |
| `skills/wiki/references/plugins.md` | 2 (Web Clipper folder setup) |
| `skills/wiki/references/modes.md` | 6 (mode diagrams) |

**Fix (priority):** Update `wiki/concepts/LLM Wiki Pattern.md` lines 46 and 57 — this is the most visible wiki-facing page. The `skills/wiki/references/` files are upstream documentation and can be updated opportunistically.

---

### W7 — Empty placeholder headings in _index files

**Affected pages:** [[sources/_index]], [[entities/_index]]
**Problem:** Both files end with a heading `## Add new sources/entities here after each ingest.` with nothing beneath it. This is a template remnant.
**Fix:** Remove the placeholder headings, or replace with actual content as the vault grows.

---

### W8 — welcome.canvas references a missing file

**Affected file:** `wiki/canvases/welcome.canvas`
**Problem:** The canvas contains a file node referencing `wiki/meta/workflow-loop.gif`, which does not appear to exist in the vault. This renders as a broken embed in Obsidian.
**Fix:** Add `workflow-loop.gif` to `wiki/meta/` or `_attachments/`, or remove the node from the canvas.

---

### W9 — claude-obsidian-main present in _system/

**Affected path:** `_system/claude-obsidian-main/`
**Problem:** The upstream bundle was moved to `_system/` rather than removed. It contains its own `.raw/` folder, demo content, and the source of broken wikilinks in C2 and C3. Not harmful to vault function but adds confusion and disk weight.
**Fix:** Confirm no content is needed, then delete. If kept, it should not be referenced by any wiki pages.

---

### W10 — [[meta/dashboard]] links to [[dashboard.base]] without path qualifier

**Affected page:** [[meta/dashboard]]
**Problem:** `dashboard.md` uses `[[dashboard.base]]` (short link) for both an inline mention and an embed (`![[dashboard.base]]`). Obsidian resolves this by global search, which works — but if another `.base` file is added, the link could break. The actual file is `wiki/meta/dashboard.base`.
**Fix (low urgency):** Change to `[[meta/dashboard.base]]` for explicit path resolution.

---

## Suggestions (worth considering)

### S1 — High-frequency concepts with no dedicated page

| Concept | Mentions | Suggested action |
|---------|----------|-----------------|
| JAMF | 16 | Create `vendors/jamf.md` stub — actively under evaluation (Apr 2026) |
| Make.com | 20 | Create `vendors/make-com.md` — mentioned as exposure vector in T1199 |
| AWS | 21 | Create `vendors/aws.md` stub — DevOps contractor exposure; T1199 context |
| POAM | 33 | Create `concepts/poam.md` — referenced in SSP, CMMC, incident response |
| SCIM | 11 | Create `concepts/scim.md` or add to `[[concepts/sso]]` |
| Unifi | 11 | Create `vendors/unifi.md` stub — core networking stack |
| SendGrid | 19 | Confirm coverage in `[[concepts/email-security]]`; add vendor stub if warranted |
| BIMI | 14 | Confirm coverage in `[[concepts/email-security]]` |
| Cloudflare | 8 | Create `vendors/cloudflare.md` stub — home lab and DNS |

Note: ABM (27 mentions) is already covered by `[[concepts/apple-business-manager]]`. MDM (52 mentions) is a generic term for Hexnode; no separate page needed. AUP (39 mentions) is covered by `[[runbooks/acceptable-use-policy]]`.

---

### S2 — Cross-link gap: concepts/mfa does not link to threats/t1110-brute-force

The forward link (MFA page → Brute Force threat) is missing, though the reverse link exists. Adding it strengthens the dual-domain interlinking.

---

### S3 — JAMF evaluation deserves a vendor page stub now

JAMF is the most likely major infrastructure change in the near term (approval expected Apr 2026). A stub `wiki/vendors/jamf.md` with status `seed` would allow tracking of evaluation criteria, key configs, and the migration decision from Hexnode.

---

### S4 — sources/_index.md and entities/_index.md are empty stubs

The vault has 11 ingested summary pages. `sources/_index.md` should list them. The `entities/` directory has no entity pages at all beyond the index. Consider populating both as a housekeeping task.

---

### S5 — comparisons/ pages need a decision: adopt or archive

Both `comparisons/Wiki vs RAG.md` and `comparisons/claude-obsidian-ecosystem.md` are upstream template pages. They are orphaned, unlisted, and one has broken links. Either adapt them to Gunner context (fix links, add index entries) or move to `_system/` as reference material.

---

### S6 — ciso-track/ has only one page

Given active CISSP prep, consider creating `ciso-track/cissp-prep.md` as cert study notes accumulate. The roadmap page is solid; supporting study pages would strengthen the CISO track section.

---

### S7 — meta/claude-obsidian-setup-guide.md is orphaned and undiscoverable

Comprehensive setup documentation with no inbound links and no index entry. It should be linked from `wiki/getting-started.md` or the Meta index section so it is discoverable.

---

### S8 — Upstream concept pages (Hot Cache, LLM Wiki Pattern, Compounding Knowledge) not indexed

Useful system documentation. Add a "How This Vault Works" section to `index.md` listing these three pages, or link them from `getting-started.md`.

---

### S9 — No entity pages exist in wiki/entities/

The entities directory is a stub. Key candidates: contractor organizations mentioned in T1199, key personnel entities if ever relevant, or major vendor entities as structured records.

---

## Infrastructure Checks

| Check | Result |
|-------|--------|
| `raw-sources/` root has no stray content files | PASS (only `.DS_Store`) |
| `raw-sources/` subdirectories correct | PASS |
| `claude-obsidian-main` not in `raw-sources/` | PASS (correctly in `_system/`) |
| All 4 hooks in `.claude/settings.json` | PASS |
| `wiki/Wiki Map.canvas` non-empty | PASS (8433 bytes) |
| `wiki/canvases/main.canvas` non-empty | PASS (7221 bytes) |
| `wiki/meta/dashboard.md` non-empty | PASS |
| `wiki/meta/dashboard.base` non-empty | PASS |
| `wiki/getting-started.md` non-empty | PASS |
| `wiki/concepts/LLM Wiki Pattern.md` | PASS |
| `wiki/concepts/Hot Cache.md` | PASS |
| `wiki/concepts/Compounding Knowledge.md` | PASS |
| `wiki/comparisons/Wiki vs RAG.md` | PASS |
| `wiki/sources/_index.md` | PASS |
| `wiki/entities/_index.md` | PASS |
| `WIKI.md` at vault root | PASS (26336 bytes) |
| `commands/wiki.md`, `save.md`, `autoresearch.md`, `canvas.md` | PASS |
| `skills/wiki/references/` has 6+ files | PASS (7 files) |
| `wiki/gunner/environment.md` exists | PASS (19 inbound links) |
| Credential scan | PASS (2 false positives: password policy note, Keeper setup instruction) |
| Stale seed pages (>30 days, status=seed) | PASS (none found) |
| Pages over 300 lines | PASS (none) |
| Runbooks older than 2025-10-01 | PASS (all current, updated 2026-04-13/14) |

---

## Previous Report (2026-04-13)

*Archived below for reference — findings from the pre-upstream-merge lint pass.*

### Frontmatter Convention Pass (2026-04-14)

Applied the new frontmatter schema to all 49 wiki pages:

- `status:` field added to all pages (was missing from 100% of pages)
- `related:` wikilinks quoted — converted `[[page/name]]` to `"[[page/name]]"` for valid YAML

Status values assigned by type: `concept/vendor/runbook/summary/gunner → stable`, `threat/ciso-track → developing`

**Remaining orphan:** `wiki/gunner/brand-colors.md` has only one inbound link (from `summaries/my-notebook-gunner-roofing`). Low priority.

### Previous Broken Wikilinks

None found at that time (pre-upstream merge).

### Previously Flagged Missing Vendor Pages

All resolved: Dialpad, Monday.com, HubSpot created. CompanyCam deferred (low priority).

### Previously Flagged Missing Concept Pages

All resolved: SSO, MFA, Email Security, Apple Business Manager, Incident Response created.

### Threats Section

All five threat pages created: T1566, T1078, T1110, T1486, T1199.

**Suggested next threat pages:**

| Technique | Gunner Relevance |
|-----------|-----------------|
| T1531 — Account Access Removal | Insider threat; offboarding edge case |
| T1190 — Exploit Public-Facing Application | Gunner Forms iOS app; Stripe API in development |
| T1098 — Account Manipulation | Admin OU compromise scenario |

### Open POAM Items (No Wiki Page Yet)

- [ ] Network segmentation (CIS 12.5) — flat network risk
- [ ] Backup scope, testing, and off-site storage — highest consequence gap (ransomware exposure)
- [ ] Formal risk register
- [ ] Written BCP
- [ ] Physical security walkthrough schedule
- [ ] Full written IR plan (current runbook is partial)
- [ ] CMMC gaps: antivirus (~$1.1k/yr Bitdefender), visitor log process

### Contradictions / Flags Requiring Tyler Input

| Item | Detail |
|------|--------|
| Dialpad SSO status | 2026-01-16 audit lists Dialpad under "Google SSO enabled" but app inventory also lists it under "Apps Without SSO." Likely: SSO for login, but manual seat deprovision still required. Verify. |
| CompanyCam SSO | Listed under Google SSO in audit but also appeared under email/password in another section. Verify current state. |
| ABM admin account | becky@gunnerroofingcom1.appleid.com — verify still correct admin contact and credentials are current in Keeper. |

### New Gaps Surfaced (2026-04-14 Ingest)

| Gap | Source | Priority |
|-----|--------|----------|
| iPhone: Hexnode CIS IG1 allows "simple value" passcode — CIS iOS 26 requires alphanumeric | CIS iOS 26 Benchmark | High |
| Mac: Verify all sharing services explicitly disabled in Hexnode policy | CIS macOS 26 Benchmark | Medium |
| Mac/GWS: No formal audit log retention policy | CIS macOS 26 Benchmark | Medium |
| GWS Admin: Hardware security key requirement — verify or accept risk | CIS GWS Benchmark | Medium |
| Chrome: Safe Browsing Enhanced; HTTPS-Only mode | CIS Chrome Benchmark | Closed 2026-04-14 |
| CMMC blocker: SI.L1-3.14.2 (endpoint AV) — Bitdefender GravityZone ~$1.1k/yr | CMMC Assessment Guide | High (if pursuing CMMC) |

### Suggested New Sources to Acquire

| Source | Why |
|--------|-----|
| Vendor contracts / renewal dates | Hexnode, KnowBe4, Keeper, Dialpad — not documented |
| Network diagram | NJ and Stamford topology only in prose |
| CISSP study materials | Drop into raw-sources/study/ when prep begins |
| Incident log | Real-world context for threat pages |
| Hexnode current policy export | Gap analysis against CIS iOS 26 and macOS 26 requires current policy |

---

*Report generated: 2026-04-14. Next lint recommended: 2026-05-14 or after next major ingest batch.*
