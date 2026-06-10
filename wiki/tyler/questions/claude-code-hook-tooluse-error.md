---
title: "Claude Code: ToolUseContext Error in Startup Hooks"
type: question
tags: [claude-code, hooks, debugging]
created: 2026-04-21
updated: 2026-04-21
sources: []
related:
  - "[[gunner/claude-team-setup]]"
status: stable
---

# Claude Code: ToolUseContext Error in Startup Hooks

## The Error

```
SessionStart:startup hook error — Failed to run: ToolUseContext is required for prompt hooks. This is a bug.
```

## Root Cause

This is a **Claude Code platform bug**. Prompt hooks (like `SessionStart`) fire before the tool execution context is fully initialized. If the hook attempts to invoke any tool (e.g., `mcp__obsidian-vault__read_note`, `Read`, etc.), Claude Code throws this error because ToolUseContext isn't available at that phase.

## Observed Behavior

Despite the error, the hot cache content injected correctly into the `system-reminder` block. The error is cosmetic — the hook ran and the content loaded, but Claude Code logged an error for the tool call attempts made during that phase.

## Workarounds

1. **Do nothing** — if content is loading correctly, the error is cosmetic and can be ignored.
2. **Switch to shell tools** — replace MCP tool calls in the hook with a bash `cat` of the target file. Shell commands may not require ToolUseContext.
3. **File a bug** — report at `https://github.com/anthropics/claude-code/issues` with the error text.

## Version Notes

- Error observed on Claude Code **2.1.98**
- Upgraded to **2.1.104** (2026-04-21) via `brew upgrade claude-code` — not yet confirmed whether the fix landed in this release
