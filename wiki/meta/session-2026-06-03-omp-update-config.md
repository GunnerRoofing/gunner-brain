---
type: session
title: "OMP Update & Config Optimization — 2026-06-03"
created: 2026-06-03
updated: 2026-06-03
tags:
  - omp
  - tooling
  - config
status: evergreen
related:
  - "[[runbooks/omp-hang-fix]]"
  - "[[runbooks/iterm2-nerd-fonts-omp-setup]]"
  - "[[meta/session-2026-05-26-omp-reinstall]]"
---

# OMP Update & Config Optimization — 2026-06-03

## OMP Updated

**15.2.4 → 15.8.3** via `~/.local/bin/omp update`.

Binary lives at `~/.local/bin/omp`.

---

## Plugins

### Removed
- `@oh-my-pi/swarm-extension@13.17.0` — uninstalled. Was causing 50GB RAM spikes / startup hangs. The npm package is abandoned at 13.17.0; the new swarm lives in the oh-my-pi monorepo (`packages/swarm-extension`) and isn't published to npm separately.

### Reinstalled
- `pi-powerline-footer@0.5.6` — was previously broken at v0.5.4 (startup hang). v0.5.6 has "harden fixed editor terminal state" fix (last week). Safe again.

### Kept
- `pi-obsidian-context@0.1.1` — working, kept
- All marketplace plugins — unchanged

### Swarm extension status
Swarm is **not installed**. To get the new working version you'd need to clone `can1357/oh-my-pi` and register `packages/swarm-extension` as a local extension. Not worth it unless unattended YAML pipelines become a need — the `task` agent already handles parallel subagent fan-out.

---

## Config Changes (`~/.omp/agent/config.yml`)

| Key | Before | After | Why |
|-----|--------|-------|-----|
| `lastChangelogVersion` | 15.4.1 | 15.8.3 | Suppresses repeat changelog display |
| `memories.enabled` | false | **true** | Enables `retain`/`recall`/`reflect` Hindsight memory tools |
| `rewind.enabled` | (absent) | **true** | Enables rewind tool (collapse exploratory context) |
| `search_tool_bm25.enabled` | (absent) | **true** | BM25 search over hidden tool index — activates tools mid-session |

### Left unchanged (already optimal)
- `modelRoles`: sonnet-4-6 default/smol, opus-4-8 slow/plan/task — right for this workload
- `checkpoint.enabled: true` — was already on
- `github.enabled: true` — was already on
- `task.isolation: rcopy` — correct for parallel subagents on macOS APFS
- `statusLine` / `theme` / `symbolPreset` — user-configured, untouched

---

## New Capabilities Now Active

### Hindsight Memory (`memories.enabled: true`)
- `retain` — queue durable facts into the active memory bank mid-run
- `recall` — search the bank for raw memories
- `reflect` — synthesize an answer over the bank

Project-scoped by default. Facts retained about this repo stay with this repo.

### `rewind`
Collapse exploratory checkpoint context down to a concise report. Useful during long investigation turns.

### `search_tool_bm25`
When a needed tool isn't in the active set, BM25 can pull it back mid-session. Activates when `tools.discoveryMode` allows it.

---

## Key Learnings from README

- `omp completions zsh` generates shell completions from live CLI metadata — never drift from actual flags
- `omp commit` does atomic split commits ordered by dependency — worth trying instead of manual `git add -A`
- `/model` slash command or Ctrl+P cycles models mid-session
- `search_tool_bm25` / `retain` / `recall` / `reflect` / `inspect_image` / `render_mermaid` are all setting-gated off by default
- swarm-extension: old npm package dead at 13.17.0; monorepo version at 15.8.3 but requires local clone to use
- `pi-powerline-footer` fixed editor is on by default in v0.5.6; Alt+S stashes editor content
