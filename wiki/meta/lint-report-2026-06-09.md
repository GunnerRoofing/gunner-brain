---
type: meta
title: "Lint Report 2026-06-09"
created: 2026-06-09
updated: 2026-06-09
tags:
  - meta
  - lint
status: stable
---

# Lint Report: 2026-06-09

## Summary
- **Pages scanned:** 191 (172 analyzed; 19 excluded: hot.md, log.md, index.md, 16 prior lint-reports)
- **Issues found:** 109 (66 orphans, 11 index gaps, 20 stale claims, 8 missing cross-refs, 4 todos)
- **Auto-fixed:** 15 (11 index gaps filled, 2 wikilinks added, 2 stub pages created — see below)
- **Needs review:** 10 stale-claim pages (human verification required)

---

## Orphan Pages (66)

Pages linked only from index/log/hub pages — no content-page inbound links. This is expected for a session-notes-heavy vault. **8 are true zero-inbound** (not even in index.md):

### True Zero-Inbound (not in index.md either)
- [[meta/session-2026-05-26-cc-prompts-39-50-guided-tasks-camera]] — ✅ added to index
- [[meta/session-2026-05-26-dual-camera-avassetwriter-crash-fix]] — ✅ added to index
- [[meta/session-2026-05-27-cc54-56-admin-delete-fk-sweep]] — ✅ added to index
- [[meta/session-2026-06-03-cc126-147-ios-refactor-splits-fixes]] — ✅ added to index
- [[meta/session-2026-06-03-omp-update-config]] — ✅ added to index
- [[meta/session-2026-06-03-wiki-lint-run]] — ✅ added to index
- [[meta/session-2026-06-04-cc148-160-ios-co-fixes]] — ✅ added to index
- [[meta/session-2026-06-04-cc148-193-ios-co-fixes]] — ✅ added to index

### Hub-only orphans (linked from index/log only — acceptable)
58 session notes and knowledge pages. These are intentionally reachable only via index.md. No action needed.

---

## Dead Links (0)
Clean. All 558 wikilinks resolve correctly.

---

## Index Coverage Gaps (11) — ✅ All fixed

Pages existing in wiki/ but absent from index.md:

| Page | Fix Applied |
|------|-------------|
| `meta/session-2026-05-21-masterdb-cutover-complete` | ✅ added to index |
| `meta/session-2026-05-26-cc-prompts-39-50-guided-tasks-camera` | ✅ added |
| `meta/session-2026-05-26-dual-camera-avassetwriter-crash-fix` | ✅ added |
| `meta/session-2026-05-27-cc54-56-admin-delete-fk-sweep` | ✅ added |
| `meta/session-2026-06-03-cc126-147-ios-refactor-splits-fixes` | ✅ added |
| `meta/session-2026-06-03-omp-update-config` | ✅ added |
| `meta/session-2026-06-03-wiki-lint-run` | ✅ added |
| `meta/session-2026-06-04-cc148-160-ios-co-fixes` | ✅ added |
| `meta/session-2026-06-04-cc148-193-ios-co-fixes` | ✅ added |
| `runbooks/chrome-safesites-policy` | ✅ added to Runbooks section |
| `runbooks/iterm2-nerd-fonts-omp-setup` | ✅ added to Runbooks section |

---

## Stale Claims (20) — Needs human review

### HIGH — Likely wrong now
- **[[gunner/aws-environment]]**: "EC2 deploy pending" + "Replacing Cloudflare Workers + D1" — GunnerTeam API moved to Lambda months ago; EC2 was never the target. Needs full section rewrite.
- **[[gunner/gunnerteam-project-structure]]**: "cc-prompts cc-01 → cc-25" — now at cc-234. File line counts from 2026-05-22 drifted significantly. Needs refresh.
- **[[runbooks/omp-hang-fix]]**: Version-keyed to OMP v15.4.1 (now v15.10.4). Powerline plugin shown as "broken" — now working. Working plugins list is stale.
- **[[runbooks/mac-tool-setup]]**: Entire guide references Claude Code CLI — harness has migrated to OMP. Font recommendation (MesloLGS NF Mono) conflicts with [[runbooks/iterm2-nerd-fonts-omp-setup]] (recommends MesloLGM Nerd Font Mono for OMP). raw/ path should be raw-sources/.

### MEDIUM — Verify before relying on
- **[[gunner/masterdb-developer-handoff]]**: Migration HEAD "g7_fix_c3d4_schema_drift" likely advanced. CloudFormation resource names invalidate on stack rebuild. SST run() empty status may have been resolved.
- **[[gunner/software-suite]]**: 60-day Urgent/Future horizon anchored to 2026-05-13; needs rebaselining. TBD items (Roadmap xlsx, Revenue Dashboard, HubSpot integration cost) may be resolved.
- **[[gunner/aws-environment]]**: RDS instance class db.t4g.micro / endpoint — verify still current. api-user.php/Make.com deal-creation fix status unknown.
- **[[gunner/claude-session-onboarding]]**: Skill list incomplete (shows ~6 skills, 13 now installed). Memory.md path reference may be stale.
- **[[runbooks/aws-iam-least-privilege]]**: Status still "pending"; IAM Identity Center may now be enabled. Template placeholders (USERS array, `<INSTANCE_ID>`, MFA codes) unfilled — runbook cannot be executed as-is.

### LOW — Minor drift
- **[[runbooks/iterm2-nerd-fonts-omp-setup]]**: Example CWDs show ~/Documents/Gunner/ (moved to ~/Dev/ on 2026-05-22).
- **[[runbooks/hubspot-google-chat]]**: Last verified 2026-01-16; HubSpot settings UI changes frequently.
- **[[runbooks/starship-transfer]]**: May be superseded by OMP powerline — verify if Starship is still in use.

---

## Missing Cross-References (8)

### Created stub pages (2) ✅
- **Colin** → `entities/Colin.md` created (stub)
- **Stripe** → `vendors/stripe.md` created (stub; Stripe API PDF is in raw-sources/articles/)

### Needs human input to create
- **Leonard / Leo**: "Leonard" in [[gunner/masterdb-developer-handoff]] (repo/DB/M2M credentials owner). "Leo" in [[gunner/software-suite]] (LeoPortal owner). Possibly the same person — reconcile naming before creating entity page.
- **Ruchir**: Named in [[gunner/software-suite]] as Quote Portal owner. No entity page.
- **DocuSign**: Mentioned in [[gunner/software-suite]]. No vendor page.

### Wikilinks added (2) ✅
- `Tyler Suffern` → added `[[entities/Tyler Suffern|Tyler Suffern]]` in [[runbooks/incident-response]]
- `Eddie Prchal` → added `[[entities/Eddie Prchal|Eddie]]` in [[runbooks/aws-iam-least-privilege]]

---

## Frontmatter Gaps (0)
All required fields (type, title, status, created, updated, tags) present on all 172 analyzed pages.

---

## Empty Sections (0)
0 empty headings across 1,943 headings scanned.

---

## Outstanding TODOs

| Page | Issue |
|------|-------|
| [[runbooks/aws-iam-least-privilege]] | Template placeholders unfilled (USERS array, instance IDs, MFA codes). Cannot execute as-is. |
| [[gunner/masterdb-developer-handoff]] | "Ask Leonard" for repo/DB credentials — no actual values recorded. |
| [[gunner/software-suite]] | 4 open items: Roadmap xlsx, Revenue Dashboard, HubSpot integration cost, DocuSign cost — TBD. |
| [[gunner/claude-session-onboarding]] | Self-flagged: "Update this prompt if skill names change" — trigger met. |
