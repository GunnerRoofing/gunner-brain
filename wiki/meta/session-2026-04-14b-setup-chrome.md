---
title: "Session Note — Vault Setup Completion + Chrome Policy (2026-04-14)"
type: meta
tags: [meta, obsidian, chrome, setup, session-note]
created: 2026-04-14
updated: 2026-04-14
status: stable
sources: [chrome-policy-export-2026-04-14.md]
related: ["[[gunnerteam/chrome-policy]]", "[[summaries/cis-chrome-enterprise-benchmark]]", "[[meta/session-2026-04-14-claude-obsidian]]"]
---

# Session Note — Vault Setup Completion + Chrome Policy (2026-04-14)

## Vault Setup Completed

### Obsidian Plugins Installed (programmatically)

Downloaded and placed in `.obsidian/plugins/`, enabled in `community-plugins.json`:

| Plugin | ID | Purpose |
|--------|-----|---------|
| Templater | `templater-obsidian` | Required for `_templates/` — handles `{{date}}` and `{{title}}` syntax |
| Dataview | `dataview` | Query frontmatter across vault (type, status, tags) |

Obsidian Git was installed then removed — Tyler keeps vault local only, no git.

Templater config written to `data.json`: template folder = `_templates`.

### MCP Server (obsidian-vault)

Selected **Option B: MCPVault** (filesystem-based, `@bitbonsai/mcpvault`):
- No Obsidian plugin required
- No TLS bypass (unlike Option A with Local REST API)
- Obsidian v1.10.6 — below 1.12 threshold for native CLI (Option D)

Registered with `--scope user` so available in all Claude Code sessions:
```
npx @bitbonsai/mcpvault@latest "/Users/tyler.suffern/Documents/Obsidian/Gunner Vault"
```

### Hooks Wired

Root cause: `.claude/settings.local.json` only had permissions — no hooks. Upstream `hooks/hooks.json` had proper Claude Code format but was never copied to project settings.

Created `.claude/settings.json` with three hooks (git-dependency removed since local-only):
- **SessionStart**: cats `wiki/hot.md` + injects prompt to load context silently
- **PostCompact**: prompt to re-read hot.md after compaction
- **Stop**: emits SESSION_END signal prompting hot.md + Memory.md update if wiki was modified

---

## Chrome Policy Analysis

**Source:** Chrome Enterprise Core policy export, tyler-MacBook-Pro, 2026-04-14

### Gaps Closed (were flagged in CIS benchmark summary)

| Policy | Value | Gap Closed |
|--------|-------|-----------|
| SafeBrowsingProtectionLevel | 2 (Enhanced) | ✅ |
| HttpsOnlyMode | force_enabled | ✅ |
| GenAiDefaultSettings | 2 (disabled) | ✅ |
| BuiltInAIAPIsEnabled | false | ✅ |

### Remaining Gaps

| Policy | Current | Target | Priority |
|--------|---------|--------|----------|
| DeveloperToolsAvailability | 0 (always on) | 2 (disabled) | Medium |
| DnsOverHttpsMode | automatic | secure | Low |
| ManagedAccountsSigninRestriction | set (deprecated) | Remove | Low |
| PromotionalTabsEnabled | set (deprecated) | Remove | Low |
| ProxyMode | set (deprecated) | Replace with ProxySettings | Low |
| DownloadRestrictions | 4 | 2 (consider) | Low |

### Extensions Confirmed

| ID | Name | Status |
|----|------|--------|
| `bfogiafebfohielmmehodmfbbebbbpei` | Keeper Password Manager | Force-installed, toolbar-pinned ✅ |
| `lmecinlocgbbcdgbhkidmeijhdhlngjp` | Dialpad Chrome CTI | Allowlisted, required ✅ |

### Notable Strengths

Policy is well-hardened overall: sign-in locked to @gunnerroofing.com, Safe Browsing Enhanced, HTTPS-Only forced, all GenAI off, telemetry off, site isolation on, remote access/debugging disabled, post-quantum crypto enabled, Keeper force-installed, idle sign-out at 240min.

Full analysis: [[gunnerteam/chrome-policy]]

---

## HubSpot Sandbox Instructions

Full step-by-step setup guide written in this session. Not saved as a separate wiki page — instructions are synthesis of existing wiki pages:
- [[gunnerteam/hubspot-leads-project]] (Lead object, stages, flows, automations)
- [[gunnerteam/hubspot-sales-pipeline]] (CRM lifecycle stages, stale deal workflows)

Key priority order: CRM rebuild base → Excel Lead project (overwrites parts) → 4.13.26 meeting notes (top priority). Key conflict resolved: 24-hour reassignment (from Excel) applies to Lead object; meeting notes confirmed "In Communication/Qualifying Lead" name and deals-from-any-stage rule.
