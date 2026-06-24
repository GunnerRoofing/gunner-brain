---
type: meta
title: Lint Report 2026-06-24
created: '2026-06-24'
updated: '2026-06-24'
tags:
  - meta
  - lint
status: stable
---

# Lint Report: 2026-06-24

## Summary
- Pages scanned: 318 (all vault notes)
- Issues found: 32
- Auto-fixed: 0 (per skill — report first, ask before fixing)
- Needs review: 32

---

## Dead Links (1 confirmed)

| Link | Referenced In | Status |
|---|---|---|
| `[[GunnerMasterDB-SOC2-Roadmap-2026-06-22]]` | `gunnerteam/masterdb-developer-handoff.md` | Page never created. Likely intended to point to `[[gunnerteam/b1-soc2-cc6-least-privilege-db-roles]]`. |

---

## Stale Index Entries (2)

| Index Entry | Issue |
|---|---|
| `[[meta/lint-report-2026-06-19]]` in `wiki/index.md` | Superseded — `lint-report-2026-06-24` is current. Update to point to today's report. |
| `wiki/meta/dashboard.md` references `[[meta/lint/lint-report-2026-06-13]]` as "latest" | Wrong subfolder path (`lint/`) AND stale date. Current reports live flat at `meta/lint-report-YYYY-MM-DD.md`. |

---

## Stale Claims (4)

| Page | Claim | Correction |
|---|---|---|
| `tyler/hot.md` | Section heading `## Key features as of v359 (2026-06-24)` | Live Lambda is v368, not v359. Heading is 9 versions stale. |
| `gunnerteam/aws-environment.md` | `Live version: v294` hardcoded in table | 74 versions stale. Should say "see [[tyler/hot]] for current" or be removed. |
| `gunnerteam/masterdb-developer-handoff.md` | Migration head shown as `k12` | Prod Alembic head is `p16_gt_app_rls` (applied cc-2150, 2026-06-24). |
| `gunnerteam/b1-soc2-cc6-least-privilege-db-roles.md` | Status "IN PROGRESS", GUC blocker listed as open | GUC approach was **retired** (p16 role-scoped policies implemented, cc-2151). Status should be PROD-PROVISIONED or reflect the actual current state. |

---

## Orphan Pages (4 — no confirmed inbound wikilinks)

| Page | Notes |
|---|---|
| `gunnerteam/querywithtenant-diag-2026-06-24.md` | Just created this session. Referenced from session note but no index/overview link. Suggest: link from `gunnerteam/b1-soc2-cc6-least-privilege-db-roles.md` evidence table. |
| `gunnerteam/voip-softphone-research.md` | Referenced in `tyler/hot.md` and `log.md` as text but no clean `[[wikilink]]`. Suggest: add `[[gunnerteam/voip-softphone-research]]` to hot.md or overview. |
| `gunnerteam/dialpad-hubspot-integration.md` | Inbound links use old `[[gunner/dialpad-hubspot-integration]]` prefix → Obsidian resolves by filename so functionally works, but path-style resolution may fail. Cross-linked to `voip-softphone-research.md`. |
| `tyler/meta/session-2026-06-24-cc1800-2157-llm-engine-b1-cutover.md` | New session note. Linked from `tyler/hot.md` but not from `tyler/index.md` or vault `wiki/index.md`. Suggest: add to `tyler/index.md` session table. |

---

## Fragile Wrong-Prefix Links (widespread — ~10 files)

Multiple pages use the old `[[gunner/xxx]]` prefix instead of current `[[gunnerteam/xxx]]` or `[[tyler/xxx]]`. Obsidian resolves by filename so they mostly work, but path-style resolvers and any vault tooling that checks strict paths will fail.

Affected files using `[[gunner/...]]`:
- `gunnerteam/aws-environment.md` → `[[gunner/environment]]`, `[[gunner/gunnerteam-project-structure]]`, `[[gunner/gunnerteam-api-aws-migration]]`, `[[gunner/masterdb-architecture]]`
- `tyler/concepts/cis-ig1.md` → `[[gunner/system-security-plan]]`
- `tyler/concepts/cmmc.md` → `[[gunner/federal-market]]`
- `tyler/concepts/soc2.md` → `[[gunner/app-inventory]]`, `[[gunner/system-security-plan]]`
- `gunnerteam/dialpad-hubspot-integration.md` → `[[gunner/hubspot-leads-project]]`

These are **safe to update** to the canonical `[[tyler/xxx]]` or `[[gunnerteam/xxx]]` paths since filenames are unique and both link forms resolve to the same page in Obsidian.

---

## Missing Cross-References (3)

| Entity | Mentioned Without Link In |
|---|---|
| `querywithtenant-diag-2026-06-24` | `gunnerteam/b1-soc2-cc6-least-privilege-db-roles.md` evidence table — diagnostic exists but isn't linked |
| `session-2026-06-24-cc1800-2157` | `tyler/index.md` session table — new session note not yet added |
| `gunnerteam/masterdb-developer-handoff.md` | `gunnerteam/b1-soc2-cc6-least-privilege-db-roles.md` references it correctly; `masterdb-developer-handoff.md` references a dead link (`[[GunnerMasterDB-SOC2-Roadmap-2026-06-22]]`) instead of the actual evidence page |

---

## Frontmatter Gaps (15 pages)

### Missing ALL frontmatter
| Page | Notes |
|---|---|
| `wiki/log.md` | Append-only log — intentional? But missing type/created/updated/tags entirely. |
| `wiki/tyler/index.md` | Tyler's page catalog — no frontmatter block at all. |

### Missing `title`
| Page |
|---|
| `wiki/hot.md` |
| `wiki/tyler/hot.md` |
| `wiki/tyler/Memory.md` |
| `wiki/gunnerteam/CHANGE_MANAGEMENT_POLICY.md` |
| `wiki/gunnerteam/CLAUDE_CODE_RULES_ONBOARDING.md` (also missing `updated`) |
| `wiki/gunnerteam/CONTRIBUTING.md` |
| `wiki/gunnerteam/POSTMORTEM-2026-06-15.md` |
| `wiki/gunnerteam/employee-notice-points-location.md` |
| `wiki/gunnerteam/git-source-of-truth-policy.md` |
| `wiki/tyler/meta/session-2026-06-22-cc2133-2135-hygiene-key-voip.md` |

### Missing `status` / `created` / `tags`
| Page | Missing |
|---|---|
| `wiki/hot.md` | status, created, tags |
| `wiki/tyler/hot.md` | status, created, tags |
| `wiki/index.md` | created |
| `wiki/meta/dashboard.md` | created |
| `wiki/tyler/meta/session-2026-06-24-cc1800-2157-llm-engine-b1-cutover.md` | status |

---

## Empty / Placeholder Sections (3)

| Page | Section | Issue |
|---|---|---|
| `wiki/hot.md` | `## Leo` | Contains only `_Leo: add your current state here_` placeholder — no real content |
| `wiki/hot.md` | `## Open Questions Across Apps` | Contains only `_Empty._` placeholder |
| `wiki/meta/dashboard.md` | `## Open Questions` | Dataview query targets `wiki/tyler/questions/` which may not exist |

---

## Layout / Structure Issues (2)

| Issue | Detail |
|---|---|
| `meta/lint/` subfolder vs flat `meta/` | Older lint reports (`lint-report-2026-06-13.md`, `lint-report-2026-06-10.md`) live in `wiki/meta/lint/` but current reports (2026-06-19, 2026-06-24) are flat at `wiki/meta/lint-report-*.md`. Dashboard references the old subfolder path. Standardise on flat. |
| `wiki/meta/dashboard.md` stale | Last updated 2026-06-13. Dataview "last lint" block references 2026-06-13 report. Update `updated` date and lint reference. |

---

## Safe to Auto-Fix (awaiting approval)

1. **Frontmatter `title` additions** — add `title` field to 10 gunnerteam/tyler pages that are missing it (derive from filename/H1)
2. **Fix dead link** in `masterdb-developer-handoff.md` — replace `[[GunnerMasterDB-SOC2-Roadmap-2026-06-22]]` with `[[gunnerteam/b1-soc2-cc6-least-privilege-db-roles]]`
3. **Update `tyler/hot.md` section heading** — `Key features as of v359` → `Key features as of v368`
4. **Update `wiki/index.md`** — replace `[[meta/lint-report-2026-06-19]]` with `[[meta/lint-report-2026-06-24]]`
5. **Update `wiki/meta/dashboard.md`** — fix lint reference and updated date
6. **Add session note to `tyler/index.md`** — add `session-2026-06-24-cc1800-2157-llm-engine-b1-cutover` row
7. **Link `querywithtenant-diag-2026-06-24`** from `b1-soc2-cc6-least-privilege-db-roles.md`

## Needs Review Before Fixing

1. **Stale content in `b1-soc2-cc6-least-privilege-db-roles.md`** — status and GUC section need rewrite; human should approve the wording
2. **Stale content in `aws-environment.md`** — v294 → remove or redirect; may affect other references
3. **Stale `masterdb-developer-handoff.md` migration chain** — k12 → p16 update; confirm correct head
4. **Orphan `voip-softphone-research.md` and `dialpad-hubspot-integration.md`** — confirm still relevant before adding inbound links
5. **Wrong-prefix `[[gunner/xxx]]` links** — safe technically but confirm page paths before bulk-rewriting
6. **`wiki/log.md` frontmatter** — the log is append-only; adding frontmatter changes the format; confirm intentional
