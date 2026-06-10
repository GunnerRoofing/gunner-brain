---
title: "Lint Report 2026-05-15"
type: meta
tags: [lint, health-check, meta]
created: '2026-05-15'
updated: '2026-05-15'
status: developing
---

# Lint Report: 2026-05-15

## Summary
- Pages scanned: 129
- Issues found: 30 (7 C/W dead links, 3 stale-claim C/W, 13 missing pages W, 5 cross-ref W, 64 empty sections W, 1 orphan W)
- Auto-fixed (this session): C1 — 14 `\|` escapes across environment.md, system-security-plan.md (4 of 5), incident-response.md; C3 monday-pm path; S9 index.md canvas link
- Needs review: items below
- Frontmatter: clean (all 125 content pages have required fields)
- Stale index: clean (all 60+ index entries resolve)

---

## Dead Links — C (Critical / Broken)

### C1 — Remaining escaped pipe in system-security-plan.md
`wiki/gunner/system-security-plan.md` line 121: `[[entities/Eric Recchia\|Eric Recchia]]`
Backslash before the pipe breaks Obsidian's wikilink parser. The earlier fix pass resolved lines 39, 40, 55, 56 but missed line 121.
**Fix:** `[[entities/Eric Recchia|Eric Recchia]]`

### C2 — dashboard.base missing
`wiki/meta/dashboard.md` references `[[dashboard.base]]` (an Obsidian Bases embed). This file does not exist in the vault. Also referenced in `log.md` (lines 373, 385) and `meta/lint-report-2026-04-14.md`.
**Fix options:** Create the `.base` file, or remove the embed and replace with static content.

### C3 — Dead links in archived lint reports (low impact)
Multiple old lint reports (`meta/lint-report-2026-04-14.md` etc.) contain `[[comparisons/claude-obsidian-ecosystem]]`, `[[claude-obsidian-ecosystem-research]]`, `[[How does the LLM Wiki pattern work]]` — none of these pages exist. These are historical artifacts in archive files, not active content.
`meta/lint-report-2026-05-15.md` (current run) also referenced `[[comparisons/claude-obsidian-ecosystem]]` in a prior pass — confirmed false positive (inside code spans in that version).

---

## Dead Links — W (Warning)

### W1 — CLAUDE.md and Memory.md wikilinks
- `meta/dual-agent-workflow.md` links `[[CLAUDE.md]]`
- `meta/lint-report-2026-05-15.md` links `[[Memory.md]]`
Both files exist at vault root (not in `wiki/`). Obsidian resolves them vault-wide so the link may render; technically they are not wiki pages.
**Fix:** Leave as-is (intentional cross-vault links) or replace with plain text.

---

## Orphan Pages — W

### W2 — session-2026-05-12-companycam-s13 not in index
`wiki/meta/session-2026-05-12-companycam-s13.md` exists but has no entry in `wiki/index.md`. All other session pages are indexed.
**Fix:** Add entry to index.md Meta table.

Three archived lint report snapshots (`lint-report-2026-04-23.md`, `lint-report-2026-04-24.md`, `lint-report-2026-05-07.md`) are also unlinked — expected for archive files.

---

## Stale Claims — C/W

### W3 — environment.md anchor page severely outdated
`wiki/gunner/environment.md` — `updated: 2026-04-13`. Missing:
- `api.team.gunnerroofing.com` as the canonical API URL (set 2026-05-14 during TLS cutover)
- Lambda migration facts (EC2 destroyed 2026-05-15)
- `## SaaS Stack` section is empty (see Empty Sections)
- JAMF evaluation status — "late April 2026" target has passed
This is the vault anchor page. It is the highest-priority stale-claim item.

### W4 — gunner-forms-app.md mixed architecture references
`wiki/gunner/gunner-forms-app.md` contains Cloudflare Worker references alongside EC2/Express references in different sections. The old Cloudflare Worker backend (gunner-team-api.anil-nair.workers.dev) is superseded but the page does not clearly mark what is current vs. historical.

### W5 — system-security-plan.md missing SOC 2 Phase 1 outcomes
`wiki/gunner/system-security-plan.md` — `updated: 2026-04-13`. SOC 2 Phase 1 work (2026-05-14: audit logging, secrets → SSM, `.env` deleted, RDS exposure fix) is not reflected.

---

## Missing Pages — W

Pages with no wiki entry despite 10+ mentions across the vault:

| Priority | Missing Page | Mention Count | Suggested Location |
|---|---|---|---|
| W | Lambda (AWS) | 100+ | `wiki/concepts/lambda.md` or `wiki/gunner/aws-environment.md` |
| W | Terraform | 57 | `wiki/concepts/terraform.md` |
| W | S3 | 52 | `wiki/gunner/aws-environment.md` |
| W | RDS | 51 | `wiki/gunner/aws-environment.md` |
| W | SOC 2 | 22 | `wiki/concepts/soc2.md` |
| W | IAM (AWS) | 25 | `wiki/gunner/aws-environment.md` |
| W | pm2 | 29 | `wiki/gunner/aws-environment.md` or deferred |
| W | Resend | 12 | `wiki/vendors/resend.md` (stub) |
| W | Tyler Suffern | 21 | `wiki/entities/Tyler Suffern.md` — only named principal without an entity page |
| S | PostgreSQL | 12 | Fold into RDS page |
| S | Unifi | 16 | `wiki/vendors/unifi.md` or fold into `wiki/gunner/environment.md` |
| S | SSM Parameter Store | 8 | Fold into `wiki/gunner/aws-environment.md` |
| S | ACM | 6 | Fold into `wiki/gunner/aws-environment.md` |

Vendor stubs that exist but are effectively empty: `make-com.md`, `sendgrid.md`, `bitdefender.md`, `quote-portal.md`, `jamf.md`, `dialpad-api-reference.md`.

---

## Missing Cross-References — W

### W6 — Entity wikilinks missing in it-decision-log.md
`wiki/gunner/it-decision-log.md` mentions Eric Recchia, Eddie Prchal, and Andrew Prchal by name without wikilinks. This is the governance record — the highest-priority cross-ref gap.

### W7 — Entity wikilinks missing in other content pages
| Person | File |
|---|---|
| Eric Recchia | `gunner/federal-market.md`, `gunner/gunner-forms-privacy-policy.md`, `gunner/hubspot-salesperson-sop.md` |
| Eddie Prchal | `entities/Andrew Prchal.md` |
| Andrew Prchal | `entities/Eddie Prchal.md` |
| Andrej Karpathy | `getting-started.md` |

---

## Frontmatter Gaps

**Clean.** All 125 content pages have type, created, updated, and tags. `hot.md`, `index.md`, `log.md`, `lint-report.md` have no frontmatter by design.

---

## Empty Sections — W (selected high-priority)

| File | Empty Section |
|---|---|
| `gunner/environment.md` | `## SaaS Stack` |
| `gunner/system-security-plan.md` | `## Roles & Responsibilities`, `## Configuration Management`, `## Maintenance & Monitoring`, `## Incident Response Plan` |
| `gunner/gunnerteam-api-aws-migration.md` | `## Architecture` |
| `gunner/aws-environment.md` | `## Known Architecture` |
| `gunner/it-decision-log.md` | `## Key Decisions on Record` |
| `ciso-track/roadmap.md` | `## Certifications`, `## Skill Domains`, `## Resources & Reading` |
| `runbooks/acceptable-use-policy.md` | `## 4. Acceptable & Unacceptable Use`, `## 5. Artificial Intelligence (AI) Tools` |
| `runbooks/new-laptop-setup.md` | `## Step 1: Add Device to Apple Business Manager` |
| `runbooks/new-phone-setup.md` | `## Step 1: Add Device to Apple Business Manager` |
| `vendors/dialpad-api-reference.md` | 7 empty sections (entire page is shell) |
| `vendors/hexnode.md` | `## iPhone Policies`, `## Mac Policies` |
| `vendors/make-com.md` | `## Active Scenarios` |
| `vendors/cloudflare.md` | `## How It Is Used at Gunner` |

Total: 64 empty sections across 35 files.

---

## Stale Index Entries

**Clean.** All 60+ entries in `wiki/index.md` resolve to existing files.

---

## Prioritized Fix List

| Priority | Fix | Effort |
|---|---|---|
| **C1** | `system-security-plan.md:121` — fix `\|` escape | 1 line |
| **C2** | `dashboard.md` — remove or create `dashboard.base` embed | Small |
| **W2** | Add `session-2026-05-12-companycam-s13` to index | 1 line |
| **W3** | Update `environment.md` — API URL, Lambda arch, JAMF status, SaaS Stack | Medium |
| **W5** | Update `system-security-plan.md` — SOC 2 Phase 1 outcomes | Medium |
| **W6** | Wire entity wikilinks in `it-decision-log.md` | Small |
| **W4** | Clarify architecture in `gunner-forms-app.md` | Small |
| **W7** | Cross-link entity mentions in federal-market, privacy-policy, hubspot-sop, entity pages | Small |
| **Missing** | Create `wiki/entities/Tyler Suffern.md` | Small |
| **Missing** | Create `wiki/concepts/soc2.md` stub | Small |
| **Empty** | Fill or deprecate `dialpad-api-reference.md` (7 empty sections) | Tyler input needed |
| **Empty** | Fill `ciso-track/roadmap.md` cert sections | Tyler input needed |
