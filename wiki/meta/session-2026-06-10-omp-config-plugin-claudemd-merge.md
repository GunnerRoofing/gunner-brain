---
type: session
owner: tyler
title: "OMP Config Fixes, Plugin Refresh, and CLAUDE.md Merge"
created: 2026-06-10
updated: 2026-06-10
tags:
  - omp
  - config
  - plugins
  - claude-md
  - meta
status: complete
related:
  - "[[meta/omp-config-full-audit-2026-05-22]]"
  - "[[meta/omp-config-tuning-2026-05-22]]"
  - "[[runbooks/mac-tool-setup]]"
  - "[[runbooks/omp-hang-fix]]"
---

# OMP Config Fixes, Plugin Refresh, and CLAUDE.md Merge

**Date:** 2026-06-10  
**Owner:** Tyler (vault-owner)  
**Scope:** OMP global config, plugins, vault project settings, CLAUDE.md

---

## 1. OMP Global Config — 5 Regressions Fixed

**File:** `~/.omp/agent/config.yml`

| Key | Was | Now | Why |
|---|---|---|---|
| `lastChangelogVersion` | `15.8.3` | `15.10.8` | Changelog spam on every startup across 2 minor versions |
| `modelRoles.default` | `sonnet-4-6:high` | `sonnet-4-6:minimal` | Extended thinking on routine edits is expensive; all prior audits explicitly set `:minimal` |
| `modelRoles.task` | `opus-4-8:high` | `sonnet-4-6:minimal` | Subagent fan-out at opus + high thinking price is ruinous; set per audit intent |
| `theme.light` | `dark-gruvbox` | `light-github` | Dark theme rendering in light mode |
| `memories` block | `enabled: true` only | Full 4-key block | 4h idle, 60-day window, 8k injection limit, 100 rollouts/startup were stripped |

Full corrected `memories` block:
```yaml
memories:
  enabled: true
  minRolloutIdleHours: 4
  maxRolloutAgeDays: 60
  summaryInjectionTokenLimit: 8000
  maxRolloutsPerStartup: 100
```

Also corrected `task.isolation.mode` from `worktree` → `rcopy`, and confirmed `rewind`, `checkpoint`, `search_tool_bm25` all explicitly enabled.

---

## 2. MCP Config — Restored

**File:** `~/.omp/agent/mcp.json` (did not exist; only a `.bak` with `{}`)

Restored:
```json
{
  "mcpServers": {
    "obsidian-vault": {
      "command": "/opt/homebrew/bin/mcpvault",
      "args": ["/Users/tyler.suffern/Documents/Obsidian/gunner-brain"]
    }
  }
}
```

`aws-core` MCP comes from the installed plugin, not this file — no entry needed for it.

---

## 3. Vault Project Settings — New

**File:** `gunner-brain/.omp/settings.json` (created; `.omp/` added to `.gitignore`)

```json
{
  "modelRoles": {
    "default": "anthropic/claude-sonnet-4-6:minimal",
    "smol": "anthropic/claude-sonnet-4-6:off",
    "task": "anthropic/claude-sonnet-4-6:minimal"
  }
}
```

Acts as a local guard: even if the global config drifts again, wiki sessions stay at minimal cost. Gitignored — machine-local.

---

## 4. Plugin Changes

**Removed:**
- `terraform@claude-plugins-official` — requires Docker + `TFE_TOKEN`; explicitly flagged as useless for local Terraform workflow in 2026-05-27 session

**Installed:**
| Plugin | Version | Why |
|---|---|---|
| `aws-serverless` | `1.1.0` | GunnerTeam's entire API is Lambda + API Gateway + Express. Adds Lambda cold-start, CORS, SAM/CDK, Powertools skills directly applicable to every cc-prompt session |
| `context7` | `0.0.0` | Up-to-date library docs (Swift SDKs, Express, Next.js, Cognito, etc.) resolved mid-session from source rather than stale training data |
| `stripe` | `0.1.0` | Stripe in vendors wiki; adds payment integration skills for Doug or GunnerTeam billing work |

**Known broken — never reinstall:**
- `@oh-my-pi/swarm-extension` — 50GB RAM spike on load; removed permanently
- `swift-lsp` (marketplace) — recursive cleanup crash on session exit; Xcode auto-detects Swift LSP, no manual install needed
- `terraform` — moved to removed list above

---

## 5. CLAUDE.md Merge — Old Vault Rules Ported

`CLAUDE.md` in `gunner-brain/` was missing Tyler's personal rules from `~/Documents/Obsidian/Gunner Vault/CLAUDE.md`. Five new sections appended:

**§10 (augmented):** Added two missing never-do rules:
- "Let a session end without updating `wiki/<owner>/hot.md`" — even if `/save` wasn't invoked
- "Guess at Gunner-specific details — flag unknowns explicitly"

**§11 — Vault owner context (Tyler):**  
Tyler Suffern, IT Manager, Gunner Roofing. ~36 employees, 3 offices. IT stack: Hexnode MDM, Google Workspace, Chrome Enterprise, Keeper, Dialpad, HubSpot, Monday.com, ABM, Unifi. Home lab: Debian/Docker, OPNsense. Certs: A+, Net+, Sec+, CySA+, PenTest+, MS Cybersecurity (WGU, July 2025). Next: CISSP. Goal: CISO/Director of InfoSec (~10yr). Dual-domain: IT/sec ops ↔ security research — always cross-link between them.

**§12 — Ingest protocol:**  
8-step ingest workflow. Key additions over old: dual-domain question (study → Gunner implication? Gunner doc → concept/threat page?), and explicit security flag protocol (`> ⚠ CRITICAL: credential present — not copied`).

**§13 — Query protocol:**  
3-mode query: Quick (hot.md + index), Standard (traverse pages), Deep (full sweep + web). Citation format: `(Source: [[Page Name]])`. Offer to save good syntheses as questions pages.

**§14 — Specialized page conventions:**  
- Threat pages: MITRE-aligned, include tactic + technique ID + Gunner-specific exposure + runbook links
- Runbook pages: scope, procedure, last-verified date, escalation path
- Vendor pages: usage at Gunner, configs/quirks, support contacts, renewal info

**§15 — Skills quick reference table:**  
Trigger → skill mapping for all 9 skills in the vault.

**`CLAUDE.local.md` also updated** with Tyler's full context (stack, certs, career goal, dual-domain intent) so session-start identity reads are complete without re-reading §11 every time.

---

## Files Changed This Session

| File | Change |
|---|---|
| `~/.omp/agent/config.yml` | 5 regressions fixed |
| `~/.omp/agent/mcp.json` | Restored (was missing) |
| `~/.omp/agent/installed_plugins.json` | `terraform` removed; `aws-serverless`, `context7`, `stripe` added |
| `.omp/settings.json` | Created (vault project settings) |
| `.gitignore` | Added `.omp/` entry |
| `CLAUDE.md` | §10 augmented; §§11–15 appended |
| `CLAUDE.local.md` | Enriched with Tyler's full profile |
| `wiki/tyler/hot.md` | OMP status section updated (version, plugins, MCP, project settings) |
| `wiki/log.md` | This entry |
| `wiki/index.md` | This entry |
