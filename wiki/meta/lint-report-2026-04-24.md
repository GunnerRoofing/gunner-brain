---
type: meta
title: "Lint Report 2026-04-24"
created: 2026-04-24
updated: 2026-04-24
tags: [meta, lint]
status: developing
---

# Lint Report: 2026-04-24

## Summary
- Pages scanned: 90
- Issues found: 10 (actionable)
- Auto-fixed: 0
- Needs review: 10

---

## W1 — Orphan Pages (8)

Pages with no inbound wikilinks from any other wiki page.

| Page | Path |
|------|------|
| Getting Started | `wiki/getting-started.md` |
| Departmental Comms | `wiki/gunner/departmental-comms.md` |
| GunnerForms Privacy Policy | `wiki/gunner/gunner-forms-privacy-policy.md` |
| IT Decision Log | `wiki/gunner/it-decision-log.md` |
| Claude Code Hook ToolUse Error | `wiki/questions/claude-code-hook-tooluse-error.md` |
| iOS Dev Workflow | `wiki/questions/ios-dev-workflow-claude-xcode-github.md` |
| Keeper Web Vault Login Loop | `wiki/questions/keeper-web-vault-login-loop.md` |
| Starship Transfer | `wiki/runbooks/starship-transfer.md` |

Suggest: link each from an appropriate index page or parent page. `starship-transfer` was just created this session — link from `new-laptop-setup`.

---

## W2 — Dead Links

All 12 dead wikilinks are intentional references to root-level utility files (`index`, `log`, `hot`) or `meta/` pages. **No action needed.**

---

## W3 — Missing Pages

None found. All frequently-mentioned concepts and tools have dedicated pages.

---

## W4 — Unlinked Mentions (28 instances across 5 pages)

Plain-text vendor/concept names that should be wikilinks.

### `concepts/cmmc.md` (7)
- `Google Workspace` → `[[vendors/google-workspace]]`
- `Hexnode` → `[[vendors/hexnode]]`
- `Bitdefender` → `[[vendors/bitdefender]]`
- `NIST` → `[[concepts/nist-csf]]`
- `SSO` → `[[concepts/sso]]`
- `MFA` → `[[concepts/mfa]]`

### `gunner/app-inventory.md` (9)
- `HubSpot` → `[[vendors/hubspot]]`
- `Dialpad` → `[[vendors/dialpad]]`
- `Keeper` → `[[vendors/keeper]]`
- `KnowBe4` → `[[vendors/knowbe4]]`
- `Make.com` → `[[vendors/make-com]]`
- `Monday` → `[[vendors/monday]]`
- `Stripe` → `[[vendors/stripe-api-reference]]`
- `SendGrid` → `[[vendors/sendgrid]]`
- `SSO` → `[[concepts/sso]]`

### `gunner/federal-market.md` (2)
- `Bitdefender` → `[[vendors/bitdefender]]`
- `NIST` → `[[concepts/nist-csf]]`

### `gunner/system-security-plan.md` (3)
- `Dialpad` → `[[vendors/dialpad]]`
- `Keeper` → `[[vendors/keeper]]`
- `SSO` → `[[concepts/sso]]`

### `vendors/jamf.md` (7)
- `Google Workspace` → `[[vendors/google-workspace]]`
- `KnowBe4` → `[[vendors/knowbe4]]`
- `Bitdefender` → `[[vendors/bitdefender]]`
- `CMMC` → `[[concepts/cmmc]]`
- `CIS` → `[[concepts/cis-ig1]]`
- `MFA` → `[[concepts/mfa]]`

---

## W5 — Frontmatter Gaps

**PASS.** All 90 pages have complete frontmatter.

---

## W6 — Empty Sections

50 empty section headings found. All are intentional scaffolding placeholders. **No action needed.**

---

## W7 — Stale Index Entries

All apparent dead links in `index.md` are intentional references to `meta/` or root-level pages. **No action needed.**

**Minor fix:** Line 171 of `index.md` has a malformed pipe: `[[entities/_index\|Entities Index]]` — backslash before pipe may break rendering. Should be: `[[entities/_index|Entities Index]]`

---

## S1 — Pages Not In Index (1)

`wiki/runbooks/starship-transfer.md` — created this session, already added to index. ✓

---

## Recommended Fixes

| ID | Issue | Auto-fixable | Priority |
|----|-------|-------------|----------|
| W1 | 8 orphan pages | Partial — add links from parent pages | Medium |
| W4 | 28 unlinked mentions in 5 pages | Yes | High |
| W7-minor | Malformed pipe in index.md line 171 | Yes | Low |
