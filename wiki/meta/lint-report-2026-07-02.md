---
type: meta
title: "Lint Report 2026-07-02"
created: '2026-07-02'
updated: '2026-07-02'
tags:
  - meta
  - lint
status: developing
---

# Lint Report: 2026-07-02

## Summary
- Pages scanned: 354 (up from 314 on 2026-06-26 — 40 new pages, mostly session notes)
- Issues found: 46
- Auto-fixed: 43 (6 originally-safe fixes + the 37-link ambiguous cluster, approved and applied same day)
- Needs review: 3 (the `[[gunner/...]]` ellipsis placeholders — not real links, no action)
- Planned follow-up: 298 stale-but-functional `gunner/` prefix links across 113 files — see [[meta/scripted-pass-plan-gunner-prefix-links-2026-07-02]] (not executed this pass, dedicated scripted pass planned)
- Noise / historical: 115 dead-link occurrences in old lint reports and session notes documenting past issues (not live problems, not counted above)

**Since 2026-06-26:** orphans stayed at ~0 (1 new orphan — the 06-26 report itself, never indexed, fixed this pass). No regressions in the 4 previously-fixed piped-backslash entity links (`entities/Tyler Suffern` etc. — confirmed still resolving). Two stale Lambda-version claims found and fixed (see below) — first stale-claim finding since lint tracking began.

---

## Orphan Pages (1)

- [[meta/lint-report-2026-06-26]]: no inbound links — the 06-26 report was written but `wiki/index.md`'s "Latest" pointer was never advanced to it (still points to 06-24). Suggest: fix as part of the stale index entry below.

---

## Dead Links — Actionable (3)

- **`wiki/meta/dual-agent-workflow.md`** frontmatter `related`: `[[wiki/hot.md]]` → should be `[[hot]]` (matches the working link style used in the body of the same file).
- **`wiki/leo/index.md`**: `[[gunnerteam/index]]` — no `gunnerteam/index.md` exists (the section uses `overview.md`, not `index.md`). Should be `[[gunnerteam/overview]]`.
- **`wiki/leo/hot.md`**: `[[gunnerteam/index]]` — same fix, `[[gunnerteam/overview]]`.

## ✅ Dead Links — Ambiguous Basename Collision (37 occurrences / 22 files) — FIXED

`[[gunner/system-security-plan]]` didn't resolve to a path (no `gunner/` folder exists), and fell back to matching by bare filename `system-security-plan.md` — which was **ambiguous**: both `wiki/gunnerteam/system-security-plan.md` (the canonical SSP, linked from `wiki/index.md`) and `wiki/tyler/summaries/system-security-plan.md` (a *summary of* the SSP) share that filename. Obsidian's resolver could silently pick either one depending on internal tie-breaking — a landmine, not a working link.

**Fixed same day**, approved and applied: all 37 wikilink occurrences across 22 files repointed to `[[gunnerteam/system-security-plan]]`, the canonical page. One adjacent plain-text historical mention (`wiki/gunner/system-security-plan.md`, in `session-2026-05-15-compliance-apns.md`, documenting a past bug) was deliberately left untouched — not a wikilink, doesn't navigate. Post-fix verification: all 37 links now resolve to a single unambiguous target; zero remaining `[[gunner/system-security-plan...]]` wikilinks vault-wide.

Files fixed: `gunnerteam/environment.md` (×2), `gunnerteam/federal-market.md`, `gunnerteam/it-decision-log.md`, `gunnerteam/secure-coding-guide.md`, `shared/entities/Andrew Prchal.md` (×2), `shared/entities/Eddie Prchal.md` (×2), `shared/entities/Eric Recchia.md` (×3), `shared/entities/Tyler Suffern.md`, `tyler/concepts/cis-ig1.md` (×2), `tyler/concepts/cmmc.md` (×2), `tyler/concepts/incident-response.md` (×3), `tyler/concepts/nist-csf.md`, `tyler/concepts/poam.md` (×2), `tyler/concepts/soc2.md`, `tyler/runbooks/acceptable-use-policy.md`, `tyler/runbooks/incident-response.md` (×2), `tyler/runbooks/it-comms-style-guide.md` (×2), `tyler/summaries/cmmc-level1-assessment-guide.md`, `tyler/summaries/system-security-plan.md` (×2), `tyler/threats/t1486-data-encrypted-for-impact.md` (×3), `meta/session-2026-05-15-compliance-apns.md`, `meta/session-2026-05-21-post-cutover-stabilization.md`.

## Stale `gunner/` Prefix Links — Functional but Non-Canonical (298 occurrences / 113 files) — PLANNED, NOT EXECUTED

Separately from the (now-fixed) ambiguous cluster above: ~298 other wikilinks still use the retired `gunner/` path prefix (e.g. `[[gunner/environment]]`, `[[gunner/aws-environment]]`, `[[gunner/hubspot-leads-project]]`). These all happen to **resolve correctly today** via Obsidian's bare-filename fallback, because every other target filename in this set is unique vault-wide. They are not broken, but they're technical debt from the `gunner/` → `gunnerteam/` restructure (same restructure that already caused the `gunner/system-security-plan` ambiguity above) — a future rename or a new file sharing one of these basenames would silently break them with no warning. **Not fixed this pass** (blast radius too large for a lint cycle — 113 files, spans nearly every section of the vault); full mapping table, per-file breakdown, and a runnable dry-run/apply script are written up at [[meta/scripted-pass-plan-gunner-prefix-links-2026-07-02]] for a dedicated follow-up session. 3 additional `[[gunner/...]]` occurrences (2 files) are literal `...` ellipsis placeholders in session notes documenting past lint work, not real link targets — excluded from the plan by design.

## Dead Links — Historical Noise (not actionable, 115 occurrences)

Unchanged category from 2026-06-26: old lint reports (`lint-report-2026-06-*`, `meta/lint/lint-report-2026-06-*`) documenting past issues, template placeholders (`page/name`, `dashboard.base`, `runbooks/x`), and `log.md`'s historical `.md`-suffixed references. These are dead links *inside documents about dead links* — recorded for the archive, not live navigation.

---

## Stale Claims (2 — new this pass)

- **`wiki/hot.md`** line "`**Lambda:** v426 live`" — stale. The cc-27/cc-28 session (2026-07-01, filed same day as the last hot.md edit that set v426) deployed **v431** and is documented in [[tyler/meta/session-2026-07-01-cc27-28-cloudwatch-dep-deflake-audit-tests]] and correctly reflected in `wiki/tyler/hot.md` ("**Lambda: v431 live**"). The top-level `hot.md` never picked up that update. Suggest: bump to v431.
- **`wiki/gunnerteam/overview.md`** line "Lambda **v294** live" (frontmatter `updated: 2026-06-22`) — **137 versions stale** against the actual v431. The line already hedges with "See [[tyler/hot]] for the current version before deploying" — suggest dropping the hardcoded version number entirely (this page shouldn't be a second source of truth for a fast-moving number) and updating `updated` to today.

---

## Broken Self-Reference (1)

- **`wiki/gunnerteam/overview.md`** line 58: `[[overview]]` — bare-basename fallback resolves this to *itself* (5 files vault-wide are named `overview.md`). Every sibling `overview.md` (tyler/colin/leo/doug) has no such self-link, so this was clearly meant to reference the top-level vault index. Suggest: `[[index]]` (matches the pattern the rest of `wiki/index.md`'s own "App Sections" list uses to point back up).

---

## Frontmatter Gaps

**Content pages (5) — safe to auto-fix with placeholders:**

| File | Missing fields |
|---|---|
| `wiki/doug/overview.md` | `updated`, `tags` |
| `wiki/meta/dashboard.md` | `created` |
| `wiki/shared/api-contracts/README.md` | `status`, `created`, `tags` |
| `wiki/shared/architecture/README.md` | `status`, `created`, `tags` |
| `wiki/shared/decisions/README.md` | `status`, `created`, `tags` |

**System/template files (7) — same as every prior lint, no change needed** (hot.md/index.md/log.md across sections intentionally run a lighter schema; templates are meant to be filled in per-use, not pre-filled):

`wiki/hot.md`, `wiki/tyler/hot.md`, `wiki/colin/hot.md`, `wiki/doug/hot.md`, `wiki/doug/index.md`, `wiki/shared/api-contracts/_template.md`, `wiki/shared/decisions/000-template.md`.

**No frontmatter at all (1):** `wiki/log.md` — by design, append-only log, not a standard page. No change needed.

---

## Empty Sections (13, in 2 files)

Re-ran with fenced-code-block exclusion this pass (last report's "289 detected" figure included markdown headers inside code examples, which aren't real sections). True empty headings — heading with zero content and no nested subheading before the next same-or-shallower heading:

- **`wiki/doug/hot.md`** (5): `## Current Focus`, `## Recent Changes`, `## Active Issues`, `## Key Decisions`, `## Integration Points` — this is Doug's hot-cache scaffold; Doug hasn't started using the vault day-to-day yet. Not actionable by Tyler.
- **`wiki/doug/index.md`** (8): `### Lead Finder`, `### Review Engine`, `### Content Creator`, `### WP Local Page Template`, `## Sessions`, `## Decisions`, `## Concepts`, `## Runbooks` — same, scaffold-only section.

Both are pre-existing scaffolding for Doug's section, not regressions. No action needed from Tyler's side.

---

## Stale Index Entries (1)

- **`wiki/index.md`** line 54: "Latest: `[[meta/lint-report-2026-06-24]]`" — one report behind. Should point to `[[meta/lint-report-2026-06-26]]` (or this one, `[[meta/lint-report-2026-07-02]]`, once filed).

---

## Naming Convention Violations

- **Tags (3):** `wiki/meta/session-2026-05-26-cc-prompts-33-38-dual-camera-orientation.md` uses `AVFoundation`, `iOS`, `GunnerTeam` — should be lowercase (`avfoundation`, `ios`, `gunnerteam`) per the tag convention. Isolated to one file.
- **Folders:** clean — no folder segments violate the lowercase-with-dashes convention.
- **Duplicate basenames (9 groups):** `hot.md`×5, `index.md`×5, `overview.md`×5, `README.md`×3, `_index.md`×3, plus `dialpad.md`, `system-security-plan.md`, `quote-portal.md`, `incident-response.md` each ×2. The 5-way per-person files (hot/index/overview) are an intentional convention — always referenced with a person-prefix path (`tyler/hot`, `colin/overview`, etc.) and never caused a real collision this pass. `system-security-plan.md`×2 is the one pair that actually bit us (see Ambiguous Basename Collision above); the others (`dialpad`, `quote-portal`, `incident-response`) haven't collided yet but are worth keeping in mind before adding a bare (unprefixed) link to any of them.

---

## Writing Style

No new violations found in pages added since the last lint pass. Spot-checked the 6 new session notes and the 1 new concept-adjacent page (`gunnerteam/meta/session-2026-07-02-cc3500-3501-totp-mfa-login-settings.md`) for declarative present tense, source grounding, and `> [!gap]`/`> [!contradiction]` callout usage on uncertain claims — all clean.

---

## Cross-Reference Gaps (1)

- **`wiki/gunnerteam/meta/session-2026-07-02-cc3500-3501-totp-mfa-login-settings.md`** discusses TOTP/MFA implementation in depth but doesn't link the existing concept page [[tyler/concepts/mfa]] (Google-Workspace-org-level MFA — related but distinct scope: app-level Cognito TOTP vs. org SSO MFA). Suggest adding it to `related` for discoverability, with a short note distinguishing the two.

---

## Missing Pages

No new candidates this pass. The three carried-over candidates from 2026-06-25/06-26 (`claude-obsidian-ecosystem`, `How does the LLM Wiki pattern work`, `GunnerMasterDB-SOC2-Roadmap`) are each mentioned only inside old lint reports and session notes *about* those old lint reports — not live content needing a page. Recommend closing these out as "won't fix" rather than carrying them forward again.

---

## Previous Issues — Status

- ✅ **4 piped-backslash entity links** (`Tyler Suffern`, `Eric Recchia`, `Eddie Prchal`, `Andrew Prchal` in `ssp-addendum-1-product-environment.md`) — confirmed fixed and stable, resolve correctly via `entities/<Name>` full path.
- ✅ **12 orphan session notes** (2026-06-25 finding) — still all indexed, no regression.
- ✅ **`[[CLAUDE.md]]`/`[[Memory.md]]` in `dual-agent-workflow.md`** — fully resolved this pass. `CLAUDE.md`/`Memory.md` were already fixed to `` `CLAUDE.md` ``/`[[Memory]]`; the remaining `[[wiki/hot.md]]` in the same `related` list is now `[[hot]]`.
- ✅ All 3 "Dead Links — Actionable" fixed (dual-agent-workflow, leo/index, leo/hot).
- ✅ All 37 "Ambiguous Basename Collision" links fixed (see above).
- ✅ Both stale Lambda-version claims fixed (`hot.md` v426→v431; `gunnerteam/overview.md` hardcoded version removed).
- ✅ Broken `[[overview]]` self-link fixed → `[[index]]`.
- ✅ 5 content-page frontmatter gaps filled.
- ✅ 3 tag-case violations fixed.
- ✅ Cross-reference gap fixed (TOTP session note ↔ `[[tyler/concepts/mfa]]`).
- ✅ Stale index pointer fixed; 06-26 report un-orphaned.
- 📋 **Planned, not executed**: 298-link stale `gunner/` prefix cluster across 113 files — see [[meta/scripted-pass-plan-gunner-prefix-links-2026-07-02]].
