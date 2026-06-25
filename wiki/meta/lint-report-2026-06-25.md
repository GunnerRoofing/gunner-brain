---
type: meta
title: Lint Report 2026-06-25
created: '2026-06-25'
updated: '2026-06-25'
tags:
  - meta
  - lint
status: active
---

# Lint Report: 2026-06-25

## Summary
- Pages scanned: 308
- Issues found: 35 (excluding noise — see below)
- Auto-fixable: 23 (stale `[[gunner/...]]` links in moved files + orphan index entries)
- Needs review: 12

---

## Orphan Pages (12)
Session notes from 2026-06-20/21 never linked from `tyler/index.md`. Not broken — just unindexed.

- [[meta/session-2026-06-20-cc1700-ios-password-checker]]
- [[meta/session-2026-06-20-cc2014-outbox-unit-tests]]
- [[meta/session-2026-06-20-cc2017-video-capture-date]]
- [[meta/session-2026-06-20-cc2112-audit-logs-tls]]
- [[meta/session-2026-06-20-cc2113-codify-sse-parked]]
- [[meta/session-2026-06-20-cc2114-aurora-cpg-import-aborted]]
- [[meta/session-2026-06-20-cc2115-tf-mfa-profile]]
- [[meta/session-2026-06-20-cc2119-device-integrity-endpoint]]
- [[meta/session-2026-06-20-cc2122-ec2-remnants-audit]]
- [[meta/session-2026-06-20-cc2129-org-scope-ci-guard]]
- [[meta/session-2026-06-21-cc2201-keepwarm-db-connection]]
- [[tyler/meta/session-2026-06-24-cc2136-2700-b1-bugfixes-firebase]]

Suggest: add all 12 to the Gunner Operations table in `tyler/index.md`.

---

## Dead Links — Stale `[[gunner/...]]` in Moved Files (auto-fixable)
The file restructure (`wiki/gunnerteam/` → `wiki/tyler/{project}/`) left stale internal links inside the moved files' body text and frontmatter `related:` fields.

| File | Stale links |
|------|-------------|
| `tyler/gunner-assistant/gunner-assistant.md` | `[[gunner/gunner-forms-app]]` × 3 |
| `tyler/masterdb/masterdb-developer-handoff.md` | `[[gunner/masterdb-architecture]]`, `[[gunner/gunnerteam-api-aws-migration]]`, `[[gunner/aws-environment]]` |
| `tyler/masterdb/masterdb-architecture.md` | `[[gunner/gunnerteam-api-aws-migration]]`, `[[gunner/masterdb-developer-handoff]]` |
| `tyler/gunnerteam/gunnerteam-api-aws-migration.md` | `[[gunner/gunner-forms-app]]`, `[[gunner/aws-environment]]` |
| `tyler/gunnerteam/subportal-cc-prompt-02-frontend.md` | `[[gunner/subportal-cc-prompt-01-scaffold]]`, `[[gunner/masterdb-architecture]]`, `[[gunner/secure-coding-guide]]` |
| `tyler/gunnerteam/subportal-cognito-auth.md` | `[[gunner/masterdb-architecture]]`, `[[gunner/secure-coding-guide]]`, `[[gunner/aws-environment]]`, `[[gunner/subportal-cc-prompt-01-scaffold]]` |
| `tyler/gunnerteam/gunnerteam-project-structure.md` | `[[gunner/gunnerteam-api-aws-migration]]`, `[[gunner/aws-environment]]`, `[[gunner/masterdb-architecture]]`, `[[gunner/secure-coding-guide]]` |
| `tyler/gunnerteam/gunnerteam-performance-standards.md` | `[[gunner/gunnerteam-api-aws-migration]]`, `[[gunner/gunnerteam-project-structure]]`, `[[gunner/secure-coding-guide]]` |
| `tyler/gunnerteam/subportal-cc-prompt-01-scaffold.md` | `[[gunner/masterdb-architecture]]`, `[[gunner/secure-coding-guide]]` |

Fix mapping (moved files → new path; stayed files → `gunnerteam/`):
- `[[gunner/masterdb-architecture]]` → `[[tyler/masterdb/masterdb-architecture]]`
- `[[gunner/masterdb-developer-handoff]]` → `[[tyler/masterdb/masterdb-developer-handoff]]`
- `[[gunner/gunnerteam-api-aws-migration]]` → `[[tyler/gunnerteam/gunnerteam-api-aws-migration]]`
- `[[gunner/gunnerteam-project-structure]]` → `[[tyler/gunnerteam/gunnerteam-project-structure]]`
- `[[gunner/subportal-cc-prompt-01-scaffold]]` → `[[tyler/gunnerteam/subportal-cc-prompt-01-scaffold]]`
- `[[gunner/gunner-forms-app]]` → `[[gunnerteam/gunner-forms-app]]`
- `[[gunner/aws-environment]]` → `[[gunnerteam/aws-environment]]`
- `[[gunner/secure-coding-guide]]` → `[[gunnerteam/secure-coding-guide]]`

---

## Dead Links — Needs Review (8)

**`GunnerMasterDB-SOC2-Roadmap` — page never created:**
- `wiki/log.md` → `[[GunnerMasterDB-SOC2-Roadmap]]`
- `wiki/meta/lint-report-2026-06-24.md` → `[[GunnerMasterDB-SOC2-Roadmap-2026-06-22]]`
- Suggest: create a stub at `wiki/tyler/masterdb/soc2-roadmap.md` or remove refs from log.

**`session-2026-06-20-cc2016-banner-navbar` — referenced but never filed:**
- `wiki/meta/session-2026-06-20-cc2017-video-capture-date.md` links to it
- Suggest: remove the reference (cc-2016 work either wasn't a separate session or was folded in).

**`ssp-addendum-1-product-environment.md` — malformed wikilinks (backslash escaping):**
- Links to `[[shared/entities/Tyler Suffern\]]`, `[[shared/entities/Eric Recchia\]]`, etc.
- Trailing `\` makes them unresolvable. Fix: strip the backslash.

**`[[shared/entities/Tyler Suffern]]` etc. — entity pages missing:**
- `ssp-addendum-1-product-environment.md` expects pages at `wiki/shared/entities/` for Tyler, Eric, Eddie, Andrew.
- Those entities exist at `wiki/tyler/` (e.g. `entities/Tyler Suffern.md`) but not under `shared/`.
- Suggest: either move links to `[[entities/Tyler Suffern]]` or create stubs in `shared/entities/`.

---

## Dead Links — Noise (excluded from count)
These are template placeholders and historical cross-references in old lint reports — not actionable:
- `[[page/name]]`, `[[other/page]]`, `[[Page Name]]`, `[[filename]]` — template examples in old session notes
- `[[dashboard.base]]` — `.base` files are not `.md`, can't be wikilinked
- `[[meta/lint-report-2026-06-09]]`, `[[meta/lint-report-2026-06-02]]` etc. — old reports never saved
- `[[gunner/...]]`, `[[gunner/xxx]]` — placeholder text in old lint reports themselves
- `[[claude-obsidian-ecosystem]]`, `[[How does the LLM Wiki pattern work]]` — referenced but never created; low priority concept stubs

---

## Frontmatter Gaps (9)
Low priority — mostly system/template files:

| File | Missing fields |
|------|---------------|
| `wiki/hot.md` | `created`, `status`, `tags` |
| `wiki/log.md` | `created`, `status`, `tags`, `type`, `updated` |
| `wiki/tyler/hot.md` | `created`, `status`, `tags` |
| `wiki/colin/hot.md` | `created` |
| `wiki/doug/hot.md` | `created`, `status`, `tags` |
| `wiki/doug/index.md` | `created`, `status`, `tags` |
| `wiki/doug/overview.md` | `tags`, `updated` |
| `wiki/shared/api-contracts/_template.md` | `tags`, `updated` |
| `wiki/shared/decisions/000-template.md` | `created`, `tags`, `updated` |

---

## Empty Sections
289 detected — 274 are log.md entries (each entry IS the heading; no body by design). Not actionable.
Remaining 15 are in old session notes and lint reports — historical, not fixable.

---

## Previous Issues — Resolved
- ✅ `[[gunner/...]]` links in `tyler/index.md` — fixed in this session (bulk replace)
- ✅ `wiki/gunnerteam/` project files restructured into `wiki/tyler/{gunner-assistant,masterdb,gunnerteam}/`
