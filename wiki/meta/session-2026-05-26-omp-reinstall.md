---
type: session
title: OMP Reinstall — Full Config Restoration
created: '2026-05-26'
updated: '2026-05-26'
tags:
  - omp
  - config
  - setup
  - session
status: complete
related:
  - '[[meta/omp-config-full-audit-2026-05-22]]'
  - '[[meta/session-2026-05-19-omp-plugins-themes]]'
  - '[[meta/session-2026-05-19-omp-professional-setup]]'
  - '[[runbooks/iterm2-nerd-fonts-omp-setup]]'
---

# OMP Reinstall — Full Config Restoration

## Summary

Tyler reinstalled Oh My Pi (OMP v15.3.2). Full user-level config, MCP server, plugins, skills, and commands were restored from the previous state documented in [[meta/omp-config-full-audit-2026-05-22]].

---

## What Was Done

### 1. `~/.omp/agent/config.yml` — Full schema restored

Restored from the 2026-05-22 audit. Key settings:

| Setting | Value |
|---|---|
| `modelRoles.default` | `anthropic/claude-sonnet-4-6:minimal` |
| `modelRoles.smol` | `anthropic/claude-sonnet-4-6:off` |
| `modelRoles.slow` | `anthropic/claude-opus-4-7:high` |
| `modelRoles.plan` | `anthropic/claude-opus-4-7:high` |
| `modelRoles.task` | `anthropic/claude-sonnet-4-6:minimal` |
| `modelRoles.commit` | `anthropic/claude-sonnet-4-6:off` |
| `theme.dark` | `dark-tokyo-night` |
| `theme.light` | `light-github` |
| `statusLine.preset` | `custom` — powerline, left: pi/model/git/path, right: subagents/context_pct/cost/token_rate |
| `symbolPreset` | `nerd` |
| `autoResume` | `true` |
| `memories.enabled` | `true` (4h idle, 60d window, 8000 token limit, 100 rollouts, 500 thread scan) |
| `memory.backend` | `local` |
| `disabledProviders` | `ollama, llama.cpp, lm-studio` (eliminates startup port probes) |
| `startup.quiet` | `true` |
| `github.enabled` | `true` |
| `secrets.enabled` | `true` |
| `task.isolation.mode` | `worktree` |
| `async.enabled` | `true` |
| `checkpoint.enabled` | `true` |
| `display.showTokenUsage` | `true` |

### 2. `~/.omp/agent/mcp.json` — obsidian-vault MCP

```json
{
  "mcpServers": {
    "obsidian-vault": {
      "command": "/opt/homebrew/bin/mcpvault",
      "args": ["/Users/tyler.suffern/Documents/Obsidian/Gunner Vault"]
    }
  }
}
```

MCP server: `@bitbonsai/mcpvault` v0.10.0 at `/opt/homebrew/bin/mcpvault`. Provides all `mcp__obsidian_vault_*` tools.

### 3. Skills — `~/.omp/agent/skills/`

**claude-obsidian skills (10)** — symlinked from `_system/claude-obsidian-main/skills/`:
`autoresearch`, `canvas`, `defuddle`, `obsidian-bases`, `obsidian-markdown`, `save`, `wiki`, `wiki-ingest`, `wiki-lint`, `wiki-query`

Symlinks point to live source — auto-updated when the upstream skill files change.

**Custom skills (3)** — recreated at `~/.omp/agent/skills/`:
- `obsidian-second-brain` — session save protocol and vault structure reference
- `hindsight` — cross-session memory protocol (hot.md + Memory.md)
- `discovery-mode` — active MCP servers, plugins, skills inventory

### 4. Commands — `~/.omp/agent/commands/`

Symlinked from `_system/claude-obsidian-main/commands/`: `/wiki`, `/save`, `/canvas`, `/autoresearch`

### 5. Plugins

**npm plugins (3) — reinstalled via `omp plugin install`:**
- `@oh-my-pi/swarm-extension@13.17.0` — parallel task/subagent orchestration
- `pi-powerline-footer@0.5.4` — powerline status bar
- `pi-obsidian-context@0.1.1` — Obsidian vault context bridge (requires obsidian-agent-context Obsidian plugin)

**Marketplace plugins:**
- `swift-lsp@claude-plugins-official` (v1.0.0) — SourceKit-LSP for Swift; also auto-detected by OMP natively if Xcode installed

**Marketplace added:** `anthropics/claude-plugins-official`

---

## Key Decisions

- **Skills via symlinks, not marketplace install:** The claude-obsidian plugin is already cloned locally at `_system/claude-obsidian-main/`. Symlinking is simpler, avoids network dependency, and keeps skills current with the local copy.
- **Custom themes not recreated:** Previous custom themes (ansi-dark, gruvbox-dark, dracula) were in `~/.omp/agent/themes/` which was lost in the reinstall. Built-in `dark-tokyo-night` is the active theme per the 2026-05-22 config audit — no custom theme files needed.
- **swift-lsp reinstalled from OMP marketplace** (not Claude Code `claude plugin`): OMP has its own marketplace system at `~/.omp/plugins/` distinct from `~/.claude/plugins/`. Claude Code plugins do not auto-transfer to OMP.

---

## What Was NOT Restored

- **Custom themes** (`~/.omp/agent/themes/ansi-dark.json`, `gruvbox-dark.json`, `dracula.json`) — lost in reinstall. Built-in themes suffice; recreate only if ansi-dark is needed for specific terminal compatibility.
- **pi-ansi-themes** package (`~/.omp/agent/packages/pi-ansi-themes`) — was a git clone, not an npm plugin. Recreate if needed: `git clone https://github.com/leblancfg/pi-ansi-themes ~/.omp/agent/packages/pi-ansi-themes`

---

## File Locations Reference

| Item | Path |
|---|---|
| OMP config | `~/.omp/agent/config.yml` |
| MCP config | `~/.omp/agent/mcp.json` |
| User skills | `~/.omp/agent/skills/` |
| User commands | `~/.omp/agent/commands/` |
| Plugin state | `~/.omp/plugins/` |
| OMP binary | `~/.bun/bin/omp` (v15.3.2) |
| mcpvault binary | `/opt/homebrew/bin/mcpvault` (v0.10.0) |
| claude-obsidian source | `_system/claude-obsidian-main/` |
