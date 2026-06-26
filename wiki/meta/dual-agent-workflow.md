---
title: "Dual-Agent Workflow: Claude Code & Gemini CLI"
type: decision
tags: [workflow, meta, setup]
created: 2026-05-11
updated: 2026-05-11
sources: [Current Session]
related:
  - "`CLAUDE.md`"
  - "[[Memory]]"
  - "[[wiki/hot.md]]"
status: stable
---

# Dual-Agent Workflow: Claude Code & Gemini CLI

## Overview
This vault is designed for concurrent or interleaved use by Claude Code and Gemini CLI. To prevent conflict ("stepping on toes"), roles are delineated by the instruction set in `CLAUDE.md`.

## Role Delineation
- **Claude Code:** Primary development, complex refactoring, and active coding sessions.
- **Gemini CLI:** Wiki maintenance, linting, source ingestion (SOPs, articles), and synthesis. Gemini serves as the "continuity agent" when Claude is token-limited or for systematic bookkeeping.

## Multi-Workspace Configuration
To enable full visibility across both the knowledge base (Obsidian Vault) and active codebases, Gemini CLI must be launched with multiple workspace flags:
`gemini --workspace "/path/to/Vault" --workspace "/path/to/Project"`

## Handover Protocol
1. **Memory Sync:** Both agents read `Memory.md` and `wiki/hot.md` at session start.
2. **Session Persistence:** Every session must end with an update to `wiki/log.md` and `wiki/hot.md` to ensure the next agent (regardless of flavor) has the latest context.
