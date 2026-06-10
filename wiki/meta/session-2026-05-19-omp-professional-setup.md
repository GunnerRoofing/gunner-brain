---
type: meta
title: "OMP Professional Setup — 2026-05-19"
status: complete
created: '2026-05-19'
updated: '2026-05-19'
tags:
  - session
  - omp
  - configuration
  - setup
---
# Session: OMP Professional Setup Finalization

## Summary

Finalized Oh My Pi coding harness configuration for daily use. Changed default model from opus to sonnet, set up ansi-dark theme with powerline footer, enabled swarm extension and discovery mode, created three persistent user-level skills.

## Changes Made

### Config (`~/.omp/agent/config.yml`)

| Setting | Before | After |
|---------|--------|-------|
| `theme.dark` | `dark-gruvbox` | `ansi-dark` |
| `symbolPreset` | `unicode` | `nerd` |
| `statusLine.preset` | `default` | `full` |
| `statusLine.separator` | `powerline-thin` | `powerline` |
| `memories.enabled` | `false` | `true` |
| `memory.backend` | — | `local` |
| `tools.discoveryMode` | `off` | `all` |
| `modelRoles.default` | `claude-opus-4-6:low` | `claude-sonnet-4-6:minimal` |
| `modelRoles.smol` | `claude-opus-4-6:minimal` | `claude-sonnet-4-6:off` |

### Skills Created (`~/.omp/agent/skills/`)

- **obsidian-second-brain** — `alwaysApply: true`. Auto-save sessions and insights to the Obsidian wiki vault. Triggers on "save", "done", or `/save`.
- **hindsight** — `alwaysApply: true`. Cross-session memory reference. Documents Hindsight config keys and usage.
- **discovery-mode** — `alwaysApply: true`. Dynamic tool discovery via MCP and runtime providers.

### Plugins Confirmed Active

- `@oh-my-pi/swarm-extension@13.17.0`
- `pi-powerline-footer@0.5.4`
- `pi-obsidian-context@0.1.1`

## Model Role Rationale

- **default** (sonnet-4-6:minimal) — fast, cheap, good enough for 90% of tasks
- **smol** (sonnet-4-6:off) — zero thinking overhead for trivial lookups
- **slow** (opus-4-7:high) — deep reasoning for architecture, debugging, security
- **plan** (opus-4-7:high) — planning needs the same depth as slow

## Related

- [[meta/session-2026-05-19-omp-plugins-themes]] — earlier session that installed the plugins and created custom themes
- [[runbooks/mac-tool-setup]] — Mac developer environment setup
- [[runbooks/starship-transfer]] — Starship prompt config (matches ansi-dark theme)
