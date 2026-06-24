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
- Pages scanned: 304
- Real issues found: 18
- False positives filtered: ~350 (path-style wikilinks that Obsidian resolves natively)
- Auto-fixed: 0 (awaiting review)
- Needs review: 18

> **Note on methodology:** The raw scan flagged 371 dead links and 264 orphans. The vast majority are **path-style links** (`[[colin/aws-infra]]`, `[[gunner/environment]]`) that DO resolve in Obsidian — the vault uses path-style linking extensively and those pages exist. Confirmed via filesystem check. Only genuinely broken links are listed below.

---

## Dead Links (confirmed broken)

### Genuine missing pages
- `[[GunnerMasterDB-SOC2-Roadmap-2026-06-22]]` referenced in [[gunnerteam/masterdb-developer-handoff]] — page never created. The B1 evidence doc exists at [[gunnerteam/b1-soc2-cc6-least-privilege-db-roles]] but the roadmap page is separate and missing. **Action:** remove or replace the link.

### Index.md syntax issues
- `[[hot.md]]` in index.md — `.md` extension shouldn't appear in wikilinks. Should be just `[[hot]]`.
- `[[log.md]]` in index.md — same issue.

### Path-prefix mismatch (gunner/ vs gunnerteam/)
Multiple gunnerteam pages use `[[gunner/xxx]]` prefix (old naming) instead of `[[gunnerteam/xxx]]`. Found in: `environment.md`, `brand-colors.md`, `claude-session-onboarding.md`, `lead-assignment-automation.md`, `completed-projects.md`. Pages exist under `gunnerteam/` — links just use wrong prefix. Obsidian may still resolve these by filename, but it's fragile.

**Affected links:**
- `[[gunner/environment]]` → should be `[[gunnerteam/environment]]` (or stem-only `[[environment]]`)
- `[[gunner/brand-colors]]` → `[[gunnerteam/brand-colors]]`
- `[[gunner/aws-environment]]` → `[[gunnerteam/aws-environment]]`
- `[[gunner/claude-team-setup]]` → `[[gunnerteam/claude-team-setup]]`
- `[[gunner/completed-projects]]` → `[[gunnerteam/completed-projects]]`

---

## Orphan Pages (confirmed — no inbound links)

Path-style link confusion inflates this count heavily. Genuine orphans in Tyler's section:

- [[gunnerteam/b1-soc2-cc6-least-privilege-db-roles]] — created this session, not yet linked from masterdb-developer-handoff beyond the broken `GunnerMasterDB-SOC2-Roadmap` link
- [[gunnerteam/voip-softphone-research]] — ingested 2026-06-22, referenced only in tyler/hot.md (not a wikilink)
- [[gunnerteam/dialpad-hubspot-integration]] — referenced in lead-assignment-automation.md as `[[gunner/dialpad-hubspot-integration]]` (wrong prefix = broken inbound)
- [[tyler/meta/session-2026-06-24-cc2136-2700-b1-bugfixes-firebase]] — just created, linked only from tyler/hot.md

Most of the 264 "orphans" in colin/, doug/, leo/ sections are reachable via path-style links from their respective overview/index pages — not truly orphaned.

---

## Frontmatter Gaps (Tyler/gunnerteam sections only)

| Page | Missing fields |
|---|---|
| [[gunnerteam/overview]] | title, tags |
| [[tyler/overview]] | title, tags, updated |
| [[tyler/hot]] | title, created, status, tags |
| [[tyler/index]] | no frontmatter at all |
| [[tyler/Memory]] | title |
| [[gunnerteam/CHANGE_MANAGEMENT_POLICY]] | title |
| [[gunnerteam/CLAUDE_CODE_RULES_ONBOARDING]] | title, updated |
| [[gunnerteam/CONTRIBUTING]] | title |
| [[gunnerteam/POSTMORTEM-2026-06-15]] | title |
| [[gunnerteam/employee-notice-points-location]] | title |
| [[gunnerteam/git-source-of-truth-policy]] | title |
| [[tyler/meta/session-2026-06-22-cc2133-2135-hygiene-key-voip]] | title |
| [[tyler/meta/session-2026-06-24-cc2136-2700-b1-bugfixes-firebase]] | status |

---

## Duplicate Filenames

These are intentional by design (per-section hot/index/overview). No action needed except awareness:
- `hot`: wiki/hot.md, tyler/hot.md, colin/hot.md, leo/hot.md, doug/hot.md
- `index`: same pattern
- `overview`: same pattern

**Genuinely ambiguous duplicates** (could cause wikilink resolution issues):
- `system-security-plan`: exists at `gunnerteam/` AND `tyler/summaries/` — two different documents
- `dialpad`: exists at `colin/dialpad.md` AND `shared/vendors/dialpad.md`
- `quote-portal`: `leo/apps/` AND `shared/vendors/`
- `incident-response`: `tyler/runbooks/` AND `tyler/concepts/`

For these, always use path-style links to be unambiguous.

---

## Stale Claims

- [[gunnerteam/masterdb-developer-handoff]]: Migration head shown as `k12_crew_members_delete_grant` but **prod is now at `p16_gt_app_rls`** (applied 2026-06-24, cc-2150). The table in the developer handoff shows through k13 but not o15, p16.
- [[gunnerteam/b1-soc2-cc6-least-privilege-db-roles]]: Status says "IN PROGRESS" and lists GUC as blocked. **GUC approach was abandoned in cc-2151** — p16 role-scoped policies are the actual implementation. Evidence doc needs update.
- [[tyler/hot]]: "What's Live (v319)" section at the bottom is very stale — v359 is live.

---

## Missing Cross-References

- [[gunnerteam/masterdb-developer-handoff]] mentions `p16_gt_app_rls` in the migration chain but doesn't link to [[gunnerteam/b1-soc2-cc6-least-privilege-db-roles]].
- tyler/hot.md references `[[tyler/meta/session-2026-06-24-cc2136-2700-b1-bugfixes-firebase]]` as text but the B1 evidence doc `[[gunnerteam/b1-soc2-cc6-least-privilege-db-roles]]` isn't wikilinked from the hot cache properly.

---

## Recommended Actions (priority order)

1. **Fix the two stale content issues** (b1-soc2 evidence doc + masterdb-developer-handoff prod head) — these affect SOC 2 evidence accuracy.
2. **Fix `[[GunnerMasterDB-SOC2-Roadmap-2026-06-22]]`** dead link in masterdb-developer-handoff — replace with `[[gunnerteam/b1-soc2-cc6-least-privilege-db-roles]]`.
3. **Fix `[[hot.md]]`/`[[log.md]]`** in index.md — remove `.md` extension.
4. **Add status field** to the new session note (minor).
5. **The `gunner/xxx` prefix links** — low urgency since Obsidian resolves by filename, but worth cleaning.
6. **tyler/hot.md "What's Live (v319)" section** — either delete or update to v359.

Safe to auto-fix items 2, 3, 4. Items 1 and 5–6 need human review first.
