---
type: decision
title: "OMP Config Full Schema Audit — 2026-05-22"
created: 2026-05-22
updated: 2026-05-22
decision_date: 2026-05-22
status: active
tags:
  - omp
  - tooling
  - config
related:
  - "[[meta/omp-config-tuning-2026-05-22]]"
  - "[[gunnerteam/claude-session-onboarding]]"
---

# OMP Config Full Schema Audit — 2026-05-22

## Decision

A full audit of `~/.omp/agent/config.yml` against the complete OMP settings schema (`settings-schema.ts`) was performed. The config was substantially expanded from the initial tuning pass. Final config written to `~/.omp/agent/config.yml`.

---

## What Was Wrong Before

### Dead key removed
`tools.discoveryMode: all` is not a valid schema key. The closest valid keys are `mcp.discoveryMode` (boolean) and `tools.intentTracing`, `tools.maxTimeout`, etc. This key was silently ignored by OMP. The desired behavior (all MCP tools visible) is the schema default (`mcp.discoveryMode: false`), so no replacement needed.

### Status bar had wrong segments
The `full` preset showed `hostname` (always `tyler-MBP`, zero value) and `token_in` but was missing `git` branch, `context_pct`, and `cost`. For a workflow spanning three repos and multiple active branches, git branch visibility and context percentage are both critical.

### Theme was functional but unpolished
`ansi-dark` maps to the terminal's own ANSI color palette. It works but provides no control over 24-bit color rendering. `dark-tokyo-night` is a full 24-bit theme with proper syntax highlighting, diff colors, and status segment colors. `light-github` replaces `dracula` for the light slot.

### Unused local discovery providers were probed on startup
With `disabledProviders` unset, OMP probes Ollama (`localhost:11434`), llama.cpp (`localhost:8080`), and LM Studio (`localhost:1234`) on every startup. None are running. This adds latency and network noise with zero benefit.

---

## All Changes Made

### Status line — switched to custom preset

| Segment | Side | Before | Why |
|---|---|---|---|
| `pi` | left | ✓ | Keep |
| `hostname` | left | ✓ removed | Always tyler-MBP — zero information |
| `model` | left | ✓ | Keep |
| `git` | left | ✗ → added | Branch awareness across iOS main/forms-quick-fix-2026-05, masterdb, subportal |
| `path` | left | ✓ | Keep |
| `session` | right | ✓ | Keep |
| `context_pct` | right | ✗ → added | Know when approaching compaction before it happens |
| `cost` | right | ✗ → added | Visibility into Opus-heavy session spend |
| `token_rate` | right | ✓ | Keep — signals whether model is thinking or stuck |
| `token_in` | right | ✓ removed | Less useful without context_pct alongside it |

### New settings added

| Setting | Value | Rationale |
|---|---|---|
| `disabledProviders` | `[ollama, llama.cpp, lm-studio]` | Eliminates 3 localhost port probes on every startup |
| `autoResume` | `true` | Resumes last session in CWD on startup — fits multi-repo switching workflow |
| `startup.quiet` | `true` | Skips welcome screen and startup status messages |
| `github.enabled` | `true` | Enables `gh_*` read-only tools (issues, PRs, diffs, search) |
| `secrets.enabled` | `true` | Obfuscates API keys/DB connection strings/AWS creds before sending to Anthropic |
| `task.isolation.mode` | `worktree` | Swarm subagents get isolated git worktrees — prevents file stomping during parallel work |
| `async.enabled` | `true` | Background bash jobs; useful for parallel build/test workflows |
| `checkpoint.enabled` | `true` | Checkpoint/rewind tools — high value before DB cutovers and risky migrations |
| `memories.threadScanLimit` | `500` | Raised from 300; 60-day window + 3 repos + multiple sessions/day approaches the cap |
| `display.showTokenUsage` | `true` | Per-turn token count on assistant messages |

### Settings audited and left at defaults (verified correct)

| Setting | Default | Rationale |
|---|---|---|
| `defaultThinkingLevel` | `high` | Irrelevant in practice — all model roles already pin `:minimal`/`:off`/`:high` via role suffix |
| `compaction.strategy` | `context-full` | In-place compaction maintains session continuity; `handoff` starts fresh — continuity wins for long refactor sessions |
| `compaction.enabled` | `true` | Keep |
| `contextPromotion.enabled` | `true` | Auto-promotes to larger-context model before compacting — correct |
| `steeringMode` | `one-at-a-time` | Correct for focused work; `all` would let queued messages stack and run continuously |
| `lsp.diagnosticsOnWrite` | `true` | Already on |
| `edit.mode` | `hashline` | OMP default — keep |
| `mcp.discoveryMode` | `false` | All MCP tools visible (obsidian-vault active) — correct |
| `retry.maxRetries` | `3` | Fine |
| `task.maxConcurrency` | `32` | Fine for swarm usage |

---

## Final Config State

```yaml
modelRoles:
  default: anthropic/claude-sonnet-4-6:minimal
  smol: anthropic/claude-sonnet-4-6:off
  slow: anthropic/claude-opus-4-7:high
  plan: anthropic/claude-opus-4-7:high
  task: anthropic/claude-sonnet-4-6:minimal
  commit: anthropic/claude-sonnet-4-6:off

theme:
  dark: dark-tokyo-night
  light: light-github

statusLine:
  preset: custom
  separator: powerline
  leftSegments:
    - pi
    - model
    - git
    - path
  rightSegments:
    - subagents
    - context_pct
    - cost
    - token_rate

symbolPreset: nerd

autoResume: true

memories:
  enabled: true
  minRolloutIdleHours: 4
  maxRolloutAgeDays: 60
  summaryInjectionTokenLimit: 8000
  maxRolloutsPerStartup: 100
  threadScanLimit: 500

memory:
  backend: local

disabledProviders:
  - ollama
  - llama.cpp
  - lm-studio

startup:
  quiet: true

github:
  enabled: true

secrets:
  enabled: true

task:
  isolation:
    mode: worktree

async:
  enabled: true

checkpoint:
  enabled: true

display:
  showTokenUsage: true
```

---

## How Config Takes Effect

Changes to `config.yml` take effect on the **next session start** — not live. The precedence stack is:

```
schema defaults ← config.yml (global) ← project settings.json ← runtime overrides
```

`config.yml` is the only persistent write target. Project settings (`.omp/settings.json` in CWD) layer on top, read-only.

## Settings Not Evaluated (Out of Scope)

Settings left at defaults without deep evaluation (no evidence they need changing):
- Sampling parameters (`temperature`, `topP`, `topK`, `minP`, `presencePenalty`) — provider defaults are correct for agentic use
- `compaction.idleEnabled` — not needed; sessions are active enough
- `task.eager` — prefer explicit delegation over auto-delegation
- `todo.eager` — prefer explicit todos
- `lsp.formatOnWrite` — formatter should be project-specific, not global
- `bashInterceptor.enabled` — would intercept Claude's own bash tool calls
- `branchSummary.enabled` — not a common workflow pattern here
- `stt.*` — no speech-to-text use
- `exa.*` — no Exa subscription
