---
title: "OMP Hang Fix — Suspended Processes & Incompatible Extensions"
type: runbook
tags: [omp, troubleshooting, plugins, terminal]
created: 2026-05-26
updated: 2026-06-09
sources: []
related:
  - "[[meta/session-2026-05-26-omp-reinstall]]"
  - "[[runbooks/iterm2-nerd-fonts-omp-setup]]"
status: stable
---

# OMP Hang Fix — Suspended Processes & Incompatible Extensions

## Current Status (2026-06-09)

OMP runs stably. No hang is currently occurring — this runbook documents a resolved incident and stays available in case a hang recurs.

- **OMP version:** 15.10.4
- **Powerline footer:** working (`pi-powerline-footer@0.5.6`)
- **Swarm extension:** removed permanently (incompatible) — do **not** reinstall
- **O(N²) compaction hang:** fixed in v15.10.3
- **`workflow`/`workflows` keyword:** renamed to `workflowz` in v15.10.2 to prevent accidental subagent fan-out

The troubleshooting steps below remain valid if a hang recurs.

**Symptom:** `omp` or `brain` alias hangs on launch with no output, or produces a `setRawMode failed with errno: 25 (ENOTTY)` error. May also manifest as 50GB+ RAM spike crashing the machine.

**Last verified:** 2026-06-09 (OMP v15.10.4)

---

## Known Bad Plugins (as of 2026-05-26)

| Plugin | Issue |
|---|---|
| `@oh-my-pi/swarm-extension` | Hangs OMP on startup; 50GB RAM spike; incompatible. Removed permanently — do **not** reinstall. |
| `pi-powerline-footer@0.5.4` | Hung on fresh install (bad npm publish). Fixed in `0.5.6` — now working. |
| `swift-lsp@claude-plugins-official` | Crashes with "Cleanup invoked recursively" on exit; corrupts startup on next launch |

**Working plugins (2026-06-09):** `pi-obsidian-context@0.1.1` and `pi-powerline-footer@0.5.6`. `swift-lsp` auto-detected via Xcode — do not install manually.

---

## Root Causes (in order of likelihood)

### 1. Suspended OMP processes holding a file lock
Prior OMP sessions suspended with Ctrl+Z hold a lock, preventing new instances from starting. OMP blocks indefinitely — no log output, no error, process goes straight to `T` state.

**Fix:** `pkill -9 -f "bun.*omp"`

### 2. Corrupted plugins directory
A bad plugin install/uninstall cycle (especially swarm) can leave the plugins dir in a state that hangs OMP before logger init. No log entries = plugins dir is the culprit.

**Fix:** Move plugins dir aside and rebuild from scratch (see procedure below).

### 3. swift-lsp marketplace plugin registered
Installing `swift-lsp@claude-plugins-official` via `omp marketplace` adds it to `installed_plugins.json`. On subsequent launches it crashes with "Cleanup invoked recursively" from `lsp/client.ts`, leaving OMP unlaunchable.

**Fix:** Clear `installed_plugins.json` — edit to `{"version": 2, "plugins": {}}`.

### 4. Extension discovery reading `~/.claude/settings.json`
OMP extension discovery reads Claude Code settings and attempts to load listed plugins. Can hang on network/git operations.

**Workaround:** `omp --no-extensions` (temporary — disables all extensions).

---

## Diagnostic Procedure

```bash
# 1. Check for suspended processes
ps aux | grep "bun.*omp" | grep -v grep

# 2. Check log for clues (no entries = pre-logger failure)
tail -20 ~/.omp/logs/omp.$(date +%Y-%m-%d).log

# 3. Check installed_plugins.json for rogue marketplace plugins
cat ~/.omp/plugins/installed_plugins.json
```

---

## Fix Procedure

### Step 1 — Kill all suspended OMP processes

```bash
pkill -9 -f "bun.*omp"
```

### Step 2 — Test bare OMP

```bash
omp
```

If it opens, a plugin is the issue — proceed to Step 3. If still hanging, go to Step 4.

### Step 3 — Clear corrupted plugins dir

```bash
mv ~/.omp/plugins ~/.omp/plugins.bak
omp  # should open clean
```

Then reinstall safe plugins one at a time, testing after each:

```bash
omp plugin install pi-obsidian-context@0.1.1
# test: brain
# DO NOT install: swarm (incompatible — never reinstall), swift-lsp (auto-detected). powerline-footer@0.5.6 is safe.
```

### Step 4 — Clear swift-lsp from installed_plugins.json

```bash
# Edit to: {"version": 2, "plugins": {}}
nano ~/.omp/plugins/installed_plugins.json
```

### Step 5 — Restore MCP config if disabled during troubleshooting

```bash
mv ~/.omp/agent/mcp.json.bak ~/.omp/agent/mcp.json 2>/dev/null
```

---

## Plugin Status (2026-06-09)

| Plugin | Status | Notes |
|---|---|---|
| `pi-obsidian-context@0.1.1` | ✅ | Installed and working |
| `pi-powerline-footer@0.5.6` | ✅ | Installed and working — earlier `0.5.4` hung on fresh install |
| `swift-lsp@claude-plugins-official` | ❌ | Do not install — auto-detected via Xcode |
| `@oh-my-pi/swarm-extension` | ❌ | Removed permanently — incompatible, never reinstall |

---

## Notes

- `brain` alias: `cd "/Users/tyler.suffern/Documents/Obsidian/Gunner Vault" && omp` (in `~/.zshrc`)
- OMP config: `~/.omp/agent/config.yml` — see [[meta/session-2026-05-26-omp-reinstall]] for full schema
- OMP log: `~/.omp/logs/omp.YYYY-MM-DD.log` — no entries = pre-logger failure (plugins issue)
- OMP binary: `~/.bun/bin/omp` v15.10.4
