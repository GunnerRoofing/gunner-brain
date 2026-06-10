---
type: meta
title: Getting Started
updated: 2026-04-23T00:00:00.000Z
tags:
  - meta
  - onboarding
status: evergreen
related:
  - '[[index]]'
  - '[[concepts/LLM Wiki Pattern]]'
  - '[[meta/vault-commands-reference]]'
created: '2026-04-14'
---

# Getting Started — Gunner Vault

This vault is the Gunner Roofing IT knowledge base — a persistent, compounding wiki built with Claude and Obsidian. Every source ingested becomes 8–15 cross-referenced wiki pages. Every question pulls from everything that's been ingested.

---

## Three-Step Quick Start

### 1. Drop a source

Put any document into `raw-sources/` (use the appropriate subfolder):
- `raw-sources/articles/` — web clips, vendor docs, advisories
- `raw-sources/runbooks/` — raw SOPs and IT docs
- `raw-sources/study/` — cert material, frameworks, benchmarks
- `raw-sources/transcripts/` — meeting notes, call logs

### 2. Ingest it

Tell Claude in any Claude Code session pointed at this vault:

```
ingest [filename]
```

Claude reads the source, creates wiki pages, cross-references everything, and updates `wiki/index.md`, `wiki/log.md`, and `wiki/hot.md`.

### 3. Ask questions

```
what do you know about [topic]?
```

Claude reads the hot cache, scans the index, drills into relevant pages, and synthesizes an answer with citations to wiki pages.

---

## How the Hot Cache Works

`wiki/hot.md` is a ~500-word summary of recent vault context. It loads automatically at the start of every Claude Code session (via the SessionStart hook in `.claude/settings.json`).

Claude starts every session knowing what you've been working on — no recap needed.

---

## Key Commands

| You say | Claude does |
|---------|-------------|
| `ingest [file]` | Reads source, creates 8–15 wiki pages |
| `what do you know about X?` | Queries wiki, cites pages |
| `/save` | Files current conversation as a wiki note |
| `/autoresearch [topic]` | Autonomous 3-round web research loop |
| `lint the wiki` | Health check — finds orphans, gaps, stale links |
| `/canvas` | View or update the visual canvas |

---

## Vault Structure

```
raw-sources/        ← Drop source files here (immutable)
wiki/               ← Claude-maintained knowledge base
  gunner/           ← Gunner-specific: environment, decisions, projects
  vendors/          ← Tool and vendor pages
  concepts/         ← Security concepts, frameworks
  threats/          ← MITRE ATT&CK aligned threat pages
  runbooks/         ← Maintained IT procedures
  ciso-track/       ← Career development, cert study
  summaries/        ← Per-source summary pages
  questions/        ← Saved Q&A synthesis
  canvases/         ← Obsidian visual canvases
  meta/             ← Dashboards, lint reports
```

---

## Navigate the Vault

- **[[index]]** — master catalog, all pages by section
- **[[meta/vault-commands-reference]]** — commands and weekly maintenance schedule
- **[[concepts/LLM Wiki Pattern]]** — how the wiki pattern works
- **[[meta/dashboard]]** — live dashboard (Bases + Dataview)
- Open `wiki/canvases/main.canvas` in Obsidian for the visual map

---

*Gunner Vault — built on the LLM Wiki pattern by Andrej Karpathy. Powered by claude-obsidian v1.4.3.*
