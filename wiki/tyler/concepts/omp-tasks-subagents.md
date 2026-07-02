---
type: concept
title: OMP Tasks and Subagents — When and How to Use
created: '2026-05-22'
updated: '2026-05-22'
tags:
  - omp
  - workflow
  - claude
  - subagents
status: active
related:
  - '[[gunnerteam/claude-session-onboarding]]'
  - '[[meta/omp-config-tuning-2026-05-22]]'
  - '[[concepts/Agentic Loops]]'
sources: []
---

# OMP Tasks and Subagents — When and How to Use

## What a Task Is

A task is a full Claude session spawned as a subprocess. It has its own tool access, its own context window, and runs independently. Multiple tasks can run simultaneously. They do not share context with each other or with the main session — communication happens through files on disk.

Tasks are not parallel chat windows. They are dispatched with a complete self-contained assignment and run to completion. There is no back-and-forth mid-task.

## Mental Model

```
main session  ← makes decisions, reviews code, talks to you
   └── task: explore / scout   (read-only recon, returns a report)
   └── task: isolated edit     (one file, clear spec, no ambiguity)
   └── task: batch operation   (grep across 50 files, lint check, etc.)
```

Each task runs as an independent worker with its own context window, so the main session stays lean while several workers make progress in parallel. Because contexts are isolated, a task only knows what its assignment spells out — front-load every fact, path, and constraint it needs. Workers coordinate live through the `irc` tool: a task asks the main session or a sibling a quick question, or broadcasts to avoid colliding on the same files, without waiting for the batch to finish.

## When Tasks Help

**File-boundary separable work.** Two tasks editing different files with no shared dependency can run simultaneously and finish faster than sequential main-session work.

**Grunt recon.** "Read all 30 cc-prompts and summarize what's been built" — scout work that would burn main context without adding judgment. Use the `explore` agent.

**Batch operations.** Audit every Lambda route for missing `requireAuth`. Grep across the full codebase for a pattern. These are mechanical and don't require mid-task decisions.

## When Tasks Don't Help

**Sequential dependencies.** If task B needs task A's output, they must run sequentially — the overhead isn't worth it for small work.

**Mid-task decisions needed.** Subagents don't ask; they act. If a feature requires judgment calls mid-way (ambiguous spec, conflicting patterns), keep it in the main session.

**Small edits.** Spawn overhead isn't worth it for a 5-line change.

## Available Agent Types

| Agent | Use case |
|---|---|
| `explore` | Read-only recon; maps structure, summarizes files. Returns a report. |
| `task` | General-purpose worker for edits with full tool access. |
| `quick_task` | Low-reasoning; mechanical updates only (rename a field, update constants). |
| `plan` | Architect for complex multi-file decisions. |
| `reviewer` | Code review — quality/security analysis. |

## Practical Pattern for GunnerTeam Build

Most cc-prompts are single-session work because they involve judgment calls. Tasks shine for **prep work**:

- Before starting a new cc-prompt: dispatch `explore` to read current file state, so the main session starts with fresh context rather than spending the first 10 messages on recon.
- Parallel non-overlapping fixes: backend validator fix + Swift struct fix can run as two tasks simultaneously.
- Post-session: dispatch `quick_task` to update log/index/hot cache while continuing main work.

## Status Bar Indicator

The `subagents` segment in the OMP right status bar shows active subagent count. It is **hidden when count = 0** — this is normal. It appears and disappears with task lifecycle. Color token: `statusLineSubagents`.


## Connections

See [[concepts/Agentic Loops]] — Karpathy's `LOOPS.md` frames this same role split (planner/generator/evaluator) as a general harness-design rule: mixing roles causes a model to grade its own work and converge on slop. The `explore` (read-only) vs `task` (edit) split above is this vault's concrete instance of that rule.