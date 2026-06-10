---
title: "Session Note — claude-obsidian Installation (2026-04-14)"
type: meta
tags: [meta, claude-obsidian, skills, setup, session-note]
created: 2026-04-14
updated: 2026-04-14
status: stable
sources: []
related: []
---

# Session Note — claude-obsidian Installation (2026-04-14)

## What Was Done

Installed the **claude-obsidian v1.4.3** skill system into the Gunner vault and customized all components for Tyler's IT/security domain.

### Installation Steps

1. Added `claude-obsidian-marketplace` to Claude Code via `claude plugin marketplace add`
2. SSH failure on install (`git@github.com: Permission denied (publickey)`) — fixed with `git config --global url."https://github.com/".insteadOf "git@github.com:"` to force HTTPS
3. Installed plugin: `claude plugin install claude-obsidian@claude-obsidian-marketplace`
4. Plugin cache landed at `~/.claude/plugins/cache/claude-obsidian-marketplace/claude-obsidian/1.4.3/`
5. Created local `skills/*/SKILL.md` files that take precedence over global plugin

### Key Customizations from Upstream

| Component | Upstream Default | Gunner Adaptation |
|-----------|-----------------|-------------------|
| Raw source folder | `.raw/` | `raw-sources/` with subdirectories (articles, study, runbooks, transcripts, screenshots) |
| Wiki structure | Generic sources/entities/questions | Tyler's full hierarchy (concepts/vendors/threats/runbooks/ciso-track/gunner/summaries) |
| Autoresearch domains | Generic | IT/security: CIS, NIST, MITRE ATT&CK, ISC2, CISSP domains, cloud/SaaS |
| Save skill targets | sources/entities/questions | concept/vendor/threat/runbook/gunner/ciso-track/summary/question/decision/session |
| Ingest skill | Basic routing | Added security flag protocol: never copy credentials into wiki pages |
| Memory system | single layer | Dual layer: Memory.md (rich, persistent) + wiki/hot.md (~500 word session cache) |

### Files Created

**Skills (local, Gunner-specific):**
- `skills/wiki/SKILL.md` — routes wiki requests, dual-layer memory loading
- `skills/wiki-ingest/SKILL.md` — source routing table, security flag protocol
- `skills/wiki-query/SKILL.md` — query procedure
- `skills/wiki-lint/SKILL.md` — Tyler-specific lint checks (POAM, raw-sources root, vendor renewals)
- `skills/save/SKILL.md` — note types mapped to Tyler's folder structure
- `skills/autoresearch/SKILL.md` — synthesis page includes Gunner Implications + CISO Relevance sections
- `skills/autoresearch/references/program.md` — domain config: security frameworks, endpoint, IAM, threat intel, CISSP, cloud
- `skills/canvas/SKILL.md` — canvas generation
- `skills/canvas/references/canvas-spec.md` — JSON Canvas spec (copied from plugin cache)
- `skills/defuddle/SKILL.md` — web page cleaning
- `skills/obsidian-markdown/SKILL.md` — Obsidian markdown conventions
- `skills/obsidian-bases/SKILL.md` — Obsidian Bases (.base files)

**Agents:**
- `agents/wiki-ingest.md` — autonomous ingest agent (sonnet, maxTurns: 30)
- `agents/wiki-lint.md` — lint agent; outputs to lint-report.md AND wiki/meta/lint-report-YYYY-MM-DD.md

**Hooks:**
- `hooks/hooks.json` — sessionStart loads Memory.md + hot.md; postCompact reloads both; stop prompts hot.md + Memory.md update

**Templates:**
- `_templates/concept.md`, `vendor.md`, `threat.md`, `runbook.md`, `summary.md` — Templater-syntax templates for each page type

**Vault config:**
- `CLAUDE.md` — replaced RTF stub with full markdown; merged Tyler's operating rules + claude-obsidian conventions

**Hot cache:**
- `wiki/hot.md` — created; populated with vault state, benchmark gaps, active threads

## Skill System Architecture

Two-layer resolution: when Claude Code runs inside the vault, local `skills/*/SKILL.md` files take precedence over the globally installed plugin at `~/.claude/plugins/cache/`. This means Gunner-customized skills are always active; the global install is a fallback for sessions outside the vault.

## Frontmatter Convention (New with This Session)

Added `status:` field to the page frontmatter standard:

```yaml
status: stable | developing | stale | seed
```

Wikilinks in YAML `related:` must be quoted:

```yaml
related: ["[[page/name]]", "[[other/page]]"]
```

Applied to all 49 existing wiki pages via bulk script (2026-04-14).

Status defaults by type:
- `concept`, `vendor`, `runbook`, `summary`, `gunner` → `stable`
- `threat`, `ciso-track` → `developing`

## How to Use Skills

| Command | What It Does |
|---------|-------------|
| `/wiki` | Route to wiki sub-skill |
| `/save` | Save current session/decision/note as a wiki page |
| `/autoresearch [topic]` | 3-round autonomous web research loop |
| `/canvas [topic]` | Generate Obsidian JSON canvas |
| `ingest [file]` | Full ingest pipeline: read → summarize → update pages → log |
| `lint` | Full wiki lint pass → wiki/lint-report.md |
