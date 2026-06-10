---
type: synthesis
title: iTerm2 Nerd Fonts Setup for OMP
created: '2026-05-22'
updated: '2026-05-22'
tags:
  - omp
  - tooling
  - iterm2
  - fonts
status: active
related:
  - '[[meta/omp-config-full-audit-2026-05-22]]'
  - '[[runbooks/mac-tool-setup]]'
---

# iTerm2 Nerd Fonts Setup for OMP

## The Problem: Nerd Fonts v2 vs v3

OMP uses Nerd Font glyphs for status bar icons. These glyphs live in the Unicode Private Use Area (PUA). Nerd Fonts v3 reorganized many code points from v2 — glyphs moved, were renamed, or remapped. This causes a split where some icons render correctly and others show as `?` boxes depending on which font version is installed.

**MesloLGS NF** (the Powerlevel10k-patched variant, Nerd Fonts v2) — missing some v3 glyphs OMP uses (e.g. the model/gear icon shows as `?`).

**MesloLGM Nerd Font Mono** (Homebrew `font-meslo-lg-nerd-font`, Nerd Fonts v3) — fixes most icons but breaks any remaining v2 code points OMP still uses.

There is no single font that covers both v2 and v3 completely. The Symbols Only Nerd Font (tried as iTerm2 non-ASCII fallback) did not resolve the remaining gaps in practice.

## Working Setup

### Fonts installed

```bash
brew install --cask font-meslo-lg-nerd-font
brew install --cask font-symbols-only-nerd-font
```

### iTerm2 configuration

**Profiles → Text:**
- **Font:** `MesloLGM Nerd Font Mono` — primary font for all text and v3 glyphs
- **Non-ASCII font:** `Symbols Nerd Font Mono` — supplementary PUA coverage

### OMP status bar segments (workaround)

The `session` segment used the GitHub octocat glyph (`\uF408` in v2), which maps to a different or missing character in v3 fonts. Since the segment only showed a raw session ID when unnamed (not useful), it was removed entirely rather than debugging the glyph.

Final right segments: `subagents → context_pct → cost → token_rate`

## Status Bar Behavior Notes

- **`git` segment** renders nothing when the CWD is not a git repo — this is expected, not a bug. It appears automatically when in any repo (`~/Documents/Gunner/GunnerTeam/`, `~/Documents/Gunner/subportal/`, etc.).
- **`context_pct`** shows as `█ 9.5%/1M` — percentage of context window used, essential for knowing when compaction is approaching.
- **`cost`** shows as `$1.84 (sub)` — cumulative session cost.
- **`token_rate`** shows as `↷ 36.9/s` — tokens/sec; drops to near zero when the model is stuck or waiting.

## Why `pi` and `π` Render Fine

`π` is a standard Unicode character (U+03C0), not a PUA glyph — it renders from any font regardless of Nerd Fonts version. PUA glyphs (U+E000–U+F8FF and supplementary ranges) are the ones that break across versions.

## If Glyphs Are Still Missing

1. Confirm iTerm2 non-ASCII font is set (checkbox must be enabled)
2. Verify `symbolPreset: nerd` is set in `~/.omp/agent/config.yml`
3. Check `Use built-in Powerline glyphs` is **unchecked** in iTerm2 Text settings — this overrides PUA Powerline glyphs with iTerm2's own versions and can conflict
