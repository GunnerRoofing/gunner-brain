---
type: session
title: Session 2026-05-19 — OMP Plugins & Theme Setup
created: '2026-05-19'
updated: '2026-05-19'
tags:
  - omp
  - plugins
  - themes
  - terminal
status: complete
related:
  - '[[runbooks/mac-tool-setup]]'
  - '[[runbooks/starship-transfer]]'
---
# Session 2026-05-19 — OMP Plugin Installation & Theme Setup

## Summary

Installed and configured Oh My Pi (omp) plugins and custom ANSI themes for the terminal coding agent environment.

## Plugin Operations

### Installed
- **pi-powerline-footer@0.5.4** — Powerline-style status bar extension (editor stash, working vibes, context awareness, bash mode)
- **pi-obsidian-context@0.1.1** — Bridges Obsidian vault with omp; surfaces active file, open tabs, and selected text as LLM context via `.obsidian/context.json`
- **@oh-my-pi/swarm-extension@13.17.0** — Swarm extension for omp
- **pi-ansi-themes** — ANSI theme pack, linked from `~/.omp/agent/packages/pi-ansi-themes` (cloned from `github.com/leblancfg/pi-ansi-themes`)

### Installed & Removed
- **@oh-my-pi/exa@1.3.3710** — Exa AI web search and websets tools; removed before session end

### Prerequisites Installed
- **Bun** runtime — required by omp plugin system; installed to `~/.bun/bin/bun`, added to `~/.zshrc` PATH

## Theme Setup

Three custom themes created at `~/.omp/agent/themes/`:

| Theme | File | Style |
|-------|------|-------|
| `ansi-dark` | `~/.omp/agent/themes/ansi-dark.json` | Pure ANSI color indices — inherits iTerm palette colors |
| `gruvbox-dark` | `~/.omp/agent/themes/gruvbox-dark.json` | Gruvbox Dark hex colors — warm retro palette |
| `dracula` | `~/.omp/agent/themes/dracula.json` | Dracula hex colors — purple/pink/cyan palette |

Active dark theme set to `ansi-dark` via `omp config set theme.dark ansi-dark`.

The `ansi-dark` theme from the pi-ansi-themes plugin was missing required tokens for the current omp schema (`statusLineBg`, `statusLineSep`, `pythonMode`, etc.). A complete version was written to the themes directory with all required tokens filled in.

## Key Paths

| Item | Path |
|------|------|
| omp binary | `/Users/tyler.suffern/.local/bin/omp` |
| bun binary | `~/.bun/bin/bun` |
| Plugin state | `~/.omp/plugins/` |
| Custom themes | `~/.omp/agent/themes/` |
| pi-ansi-themes repo | `~/.omp/agent/packages/pi-ansi-themes` |
| Plugin config | `~/.omp/agent/config.yml` |

## Notes

- **pi-obsidian-context** requires the **obsidian-agent-context** Obsidian community plugin to write the `context.json` file that the extension reads
- **ansi-themes** package only ships `ansi-dark` and `ansi-light`; gruvbox-dark and dracula were custom-created
- To update pi-ansi-themes: `cd ~/.omp/agent/packages/pi-ansi-themes && git pull`
- To switch themes: `omp config set theme.dark <name>` where name is `ansi-dark`, `gruvbox-dark`, or `dracula`
