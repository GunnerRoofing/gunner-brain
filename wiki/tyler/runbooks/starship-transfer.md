---
title: "Transfer Starship Prompt to a New Mac"
type: runbook
tags: [starship, terminal, dotfiles, nerd-fonts, zsh]
created: 2026-04-24
updated: 2026-04-24
sources: []
related:
  - "[[runbooks/new-laptop-setup]]"
status: stable
---

# Transfer Starship Prompt to a New Mac

## Overview

Starship is a cross-shell prompt configured via a single TOML file. The config is fully portable — AirDrop or copy `~/.config/starship.toml` to the new machine. Icons require a Nerd Font to be installed **and** explicitly set in the terminal emulator.

Tyler's font: **MesloLGS NF** (confirmed 2026-04-24).

---

## Transfer Checklist

### 1. Copy the config file

AirDrop `~/.config/starship.toml` to the new machine, then move it into place:

```sh
mv ~/Downloads/starship.toml ~/.config/starship.toml
```

### 2. Install Starship

```sh
brew install starship
```

### 3. Install MesloLGS NF

```sh
brew install --cask font-meslo-lg-nerd-font
```

### 4. Set the font in iTerm2

**iTerm2 → Preferences → Profiles → Text → Font** → select **MesloLGS NF Mono**

> Use the **Mono** variant — proportional variants misalign the powerline segments.

### 5. Add shell init to `~/.zshrc`

```sh
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
source ~/.zshrc
```

---

## Troubleshooting

### Icons show as boxes or `?`

Font is installed but not set in the terminal. Go to iTerm2 font settings and select **MesloLGS NF Mono** explicitly.

### Verify glyph rendering

```sh
echo " "
```

If a battery icon renders, the font is working. If you see a box or question mark, the terminal isn't using the Nerd Font.

### Battery / CPU icons missing specifically

Most likely the font is set to the non-NF variant of Meslo (e.g. plain "Meslo LG" instead of "MesloLGS NF"). Confirm the full name includes **NF** in iTerm2 preferences.

### Starship doesn't appear on new terminal sessions

The shell init line is missing from `~/.zshrc`. Add it:

```sh
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
```

---

## Config Location

| File | Path |
|------|------|
| Starship config | `~/.config/starship.toml` |
| Shell init | `~/.zshrc` |

Tyler's config uses powerline segments with battery, memory, cmd duration, and time modules — all Nerd Font glyphs styled via terminal color codes (no emoji).
