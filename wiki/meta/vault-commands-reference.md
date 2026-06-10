---
title: Vault Commands & Maintenance Schedule
type: gunner
tags:
  - meta
  - commands
  - reference
created: '2026-04-14'
updated: '2026-04-14'
status: stable
related:
  - '"[[meta/session-2026-04-14-claude-obsidian]]"'
---

# Vault Commands & Maintenance Schedule

---

## Automatic (no action needed)

These run at the end of every Claude Code session:

- `wiki/log.md` — appended with session changes
- `wiki/hot.md` — session cache updated
- `wiki/index.md` — updated if pages added/removed
- `wiki/canvases/main.canvas` — updated if pages added/removed

---

## Commands You Run

| Command | When | What it does |
|---------|------|--------------|
| `ingest [filename]` | After adding a file to `raw-sources/` | Reads source, extracts entities, updates concept/vendor/threat pages, updates index/log/hot/canvas |
| `lint the wiki` | Weekly | Scans for broken links, orphan pages, stale runbooks, missing cross-refs. Updates `wiki/lint-report.md` |
| `/save` | After any important decision or conversation | Files current conversation as a structured wiki note in the appropriate folder |
| `/autoresearch [topic]` | When you want deep research on a topic | 3-round autonomous web research loop → files results as wiki pages |
| `/canvas` | Status check | Reports node counts, lists zones |
| `/canvas new [name]` | When you want a new visual board | Creates a new canvas in `wiki/canvases/` |

---

## Recommended Weekly Routine

1. Drop any new source files into `raw-sources/` (articles, runbooks, study material, transcripts)
2. Run `ingest [file]` for each one
3. Run `lint the wiki` once a week (Monday or Friday)
4. Run `/save` after any important decisions or conversations worth keeping

---

## Ending a Session

Just close the terminal or Claude Code window — the session-end hook runs automatically.

To manually trigger a mid-session save before closing: `/save`

---

## Adding to the Canvas

The canvas updates automatically on ingest. To manually add something:

| Command | What it does |
|---------|--------------|
| `/canvas add note [page]` | Add a wiki page as a linked card |
| `/canvas add image [path]` | Add an image (downloads if URL) |
| `/canvas add text [content]` | Add a text card |
| `/canvas zone [name] [color]` | Add a new labeled zone |
| `/canvas list` | List all canvases with node counts |
