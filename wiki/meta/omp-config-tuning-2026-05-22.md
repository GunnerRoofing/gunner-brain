---
type: decision
title: "OMP Config Tuning — 2026-05-22"
created: 2026-05-22
updated: 2026-05-22
decision_date: 2026-05-22
status: active
tags:
  - omp
  - tooling
  - config
related:
  - "[[meta/session-2026-05-19-omp-professional-setup]]"
  - "[[meta/session-2026-05-19-omp-plugins-themes]]"
  - "[[gunnerteam/claude-session-onboarding]]"
---

# OMP Config Tuning — 2026-05-22

## Decision

`~/.omp/agent/config.yml` was updated with targeted changes to better support Tyler's multi-repo, multi-session daily workflow across GunnerTeam iOS, masterdb, and subportal.

## Changes Made

### Model Roles Added

```yaml
modelRoles:
  task: anthropic/claude-sonnet-4-6:minimal   # added
  commit: anthropic/claude-sonnet-4-6:off     # added
```

**`task` role:** Powers swarm subagents (`@oh-my-pi/swarm-extension`). Without an explicit role configured, swarm delegates fell through to the `default` role implicitly. Pinning it makes the behavior explicit and independently tunable.

**`commit` role:** Used for auto-generating commit messages. Commit generation requires no extended thinking — `off` thinking mode is faster and cheaper with no quality loss for this use case.

### Memory Pipeline Tuned

```yaml
memories:
  enabled: true
  minRolloutIdleHours: 4       # was: 12 (default)
  maxRolloutAgeDays: 60        # was: 30 (default)
  summaryInjectionTokenLimit: 8000   # was: 5000 (default)
  maxRolloutsPerStartup: 100   # was: 64 (default)
```

**`minRolloutIdleHours: 4`** — The default 12-hour minimum idle time meant sessions from earlier the same day were never processed into memory until the following morning. With multiple sessions per day across different projects, this caused meaningful signal loss. 4 hours captures same-day context while still avoiding processing active sessions.

**`maxRolloutAgeDays: 60`** — Gunner projects span months (masterdb migration started in May, iOS features track back further). The 30-day default was pruning sessions with relevant architectural context.

**`summaryInjectionTokenLimit: 8000`** — The memory summary injected at session start was hitting the 5000-token limit given the complexity of the multi-repo stack. Raising to 8000 allows the full masterdb + iOS + subportal context to survive into each session without truncation.

**`maxRolloutsPerStartup: 100`** — Higher cap ensures memory catches up fully after gaps (weekends, multi-day sessions) without requiring multiple startups.

## How OMP Config Works

OMP reads `~/.omp/agent/config.yml` as the global settings layer. Precedence:

```
schema defaults ← config.yml (global) ← project settings.json ← runtime overrides
```

- `config.yml` is the only persistent write target
- Project settings (`.omp/settings.json` in the CWD) layer on top, read-only
- Changes take effect on the next session start — not live

Config can be read and edited directly via the filesystem. The OMP Settings TUI (`/settings`) provides a navigable interface across 10 categories: Appearance, Model, Interaction, Context, Memory, Editing, Tools, Tasks, Providers, Plugins.

## Full Config State (post-change)

```yaml
modelRoles:
  default: anthropic/claude-sonnet-4-6:minimal
  smol: anthropic/claude-sonnet-4-6:off
  slow: anthropic/claude-opus-4-7:high
  plan: anthropic/claude-opus-4-7:high
  task: anthropic/claude-sonnet-4-6:minimal
  commit: anthropic/claude-sonnet-4-6:off
theme:
  dark: ansi-dark
  light: dracula
statusLine:
  preset: full
  separator: powerline
symbolPreset: nerd
memories:
  enabled: true
  minRolloutIdleHours: 4
  maxRolloutAgeDays: 60
  summaryInjectionTokenLimit: 8000
  maxRolloutsPerStartup: 100
memory:
  backend: local
tools:
  discoveryMode: all
```

## Plugins Active (unchanged)

- `@oh-my-pi/swarm-extension@13.17.0` — subagent swarm (uses `task` role)
- `pi-powerline-footer@0.5.4` — powerline status bar
- `pi-obsidian-context@0.1.1` — vault context bridge

## Skills Active (unchanged)

Located in `~/.omp/agent/skills/`:
- `obsidian-second-brain` — auto-save sessions/insights to vault
- `hindsight` — cross-session memory reference
- `discovery-mode` — dynamic MCP/runtime tool discovery
- `nice-attachments` — clean labels for file/image paths
