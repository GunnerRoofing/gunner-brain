---
title: "Mac Tool Setup: iTerm2 + OMP + Claude Code + Obsidian"
type: runbook
tags: [runbook, macos, iterm2, omp, claude-code, obsidian, dotfiles, setup]
created: 2026-04-24
updated: 2026-06-09
sources: []
related:
  - "[[runbooks/new-laptop-setup]]"
  - "[[runbooks/iterm2-nerd-fonts-omp-setup]]"
  - "[[runbooks/omp-hang-fix]]"
status: stable
---

# Mac Tool Setup
## iTerm2 · OMP · Claude Code · Obsidian

> **Requires:** macOS Ventura or later

---

## Overview

The Mac development environment is four tools layered together:

| # | Tool | Role |
|---|------|------|
| 1 | **iTerm2** | Terminal emulator |
| 2 | **MesloLGM Nerd Font Mono** | Nerd Font that renders OMP powerline glyphs |
| 3 | **OMP (oh-my-pi)** | Primary AI coding harness |
| 4 | **Claude Code** | Secondary AI tool for specific tasks |
| 5 | **Obsidian** | Wiki vault editor |

OMP is the primary harness — it drives day-to-day coding work and carries its own powerline status bar. Claude Code is a separate Anthropic CLI kept around for specific tasks; it is not the primary tool.

---

## iTerm2

Download iTerm2 from [iterm2.com](https://iterm2.com) and install the app.

Configure the profile (**iTerm2 → Settings → Profiles**):

- **Text → Non-ASCII font:** MesloLGM Nerd Font Mono, size 13. This is the font that renders OMP's powerline glyphs; the regular ASCII font can stay whatever you prefer.
- **Terminal → Scrollback:** enable **Unlimited scrollback** so long OMP sessions are not truncated.

---

## Nerd Font

OMP's powerline status bar uses glyphs that only render with a Nerd Font. Without it, the status bar shows boxes or `?` placeholders.

1. Download **MesloLGM Nerd Font Mono v3** from [nerdfonts.com](https://www.nerdfonts.com).
2. Install the `.ttf` files into `~/Library/Fonts`.
3. Set it in iTerm2 under **Settings → Profiles → Text → Non-ASCII font** (MesloLGM Nerd Font Mono, size 13).

> [!note] Mono variant
> Use the **Mono** variant specifically — the proportional version misaligns the powerline segments.

---

## OMP (oh-my-pi)

OMP is the primary AI coding harness.

1. Download the binary from the GitHub releases page: <https://github.com/can1357/oh-my-pi/releases> (current version: **15.10.4**).
2. Install it to `~/.omp/omp` and make it executable (`chmod +x ~/.omp/omp`).
3. Add the init line to `~/.zshrc`:

   ```sh
   eval "$(~/.omp/omp init zsh)"
   ```

4. Reload the shell: `source ~/.zshrc`.

Configuration lives at `~/.omp/agent/config.yml`. Start OMP by running `omp` in any project directory.

---

## Claude Code

Claude Code is a secondary AI tool from Anthropic, used for specific tasks. It is **not** the primary harness — OMP is.

**Install:**

```sh
npm install -g @anthropic-ai/claude-code
```

**Invoke:**

```sh
claude
```

The first run opens a browser to authenticate with your Anthropic account. Credentials are stored per-machine, so authenticate on each new Mac.

---

## Obsidian

Download Obsidian from [obsidian.md](https://obsidian.md) and install the app.

- **Vault:** `~/Documents/Obsidian/Gunner Vault/`
- **Raw sources:** `~/Documents/Obsidian/Gunner Vault/raw-sources/`

Open the vault folder with **Open folder as vault**. Community plugins and settings are stored inside the vault and restore automatically; click **Trust and Enable** when prompted.

---

## Shell config

`~/.zshrc` additions:

```sh
# OMP init — primary AI coding harness
eval "$(~/.omp/omp init zsh)"
```

Add any personal aliases below the init line. Reload with `source ~/.zshrc` after editing.

---

## Working directories

| Purpose | Path |
|---------|------|
| GunnerTeam repo | `~/Dev/GunnerTeam/` |
| Wiki vault | `~/Documents/Obsidian/Gunner Vault/` |

See [[tyler/gunnerteam/gunnerteam-project-structure]] for the repo layout and [[gunnerteam/aws-environment]] for the deploy environment.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Powerline glyphs show as boxes or `?` | Set MesloLGM Nerd Font Mono as the iTerm2 **Non-ASCII** font |
| OMP status bar not loading in new tabs | Confirm `eval "$(~/.omp/omp init zsh)"` is in `~/.zshrc`, then `source ~/.zshrc` |
| `omp` not found | Ensure `~/.omp/omp` exists, is executable, and the init line is sourced |
| OMP session hangs | See [[runbooks/omp-hang-fix]] |
| `claude` not found after npm install | Open a new tab or run `source ~/.zshrc` |
| Obsidian vault shows no plugins | Click **Trust and Enable**, or **Settings → Community Plugins → Enable** |
