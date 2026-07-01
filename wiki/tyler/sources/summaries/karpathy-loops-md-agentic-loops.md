---
type: source
title: "LOOPS.md: Field Notes on Agents That Run for Days"
created: 2026-07-01
updated: 2026-07-01
tags:
  - source
  - agentic-workflows
  - llm
  - harness-design
status: developing
related:
  - "[[entities/Andrej Karpathy]]"
  - "[[concepts/Agentic Loops]]"
  - "[[concepts/omp-tasks-subagents]]"
  - "[[concepts/LLM Wiki Pattern]]"
sources: []
source_type: article
author: "Andrej Karpathy"
date_published: ""
url: ""
confidence: high
key_claims:
  - "Most agent-system failures trace to a weak harness, not a weak model — the model can write and verify code against a rubric, but cannot decide when to stop, when to restart, or where to persist results on its own."
  - "The loop, not the prompt, is the unit of leverage once a model is good enough to follow an unsupervised procedure — five verbs: gather, reason, act, verify, repeat."
  - "Three separated roles (planner, generator, evaluator) with three separate context windows prevent the single most common failure: a model grading its own work and converging on slop."
  - "A generator/evaluator pair should negotiate a written contract (~10-27 testable criteria) before any code is written; the contract, not the original spec, is what gets graded."
  - "State belongs on disk (feature_list.json, progress.md, contract.md, append-only log.md), never only in context — context windows compact and rot."
  - "Letting a healthy loop discard a bad run and restart from iteration N is correct behavior for current frontier models, not a failure to interrupt."
  - "Subjective quality (taste) is gradable if reduced to weighted axes (design, originality, craft, functionality) and calibrated against known-good/known-bad reference examples."
  - "Debugging insight comes from reading raw agent transcripts (grep for the divergence point), not from running more experiments."
  - "Harnesses should be deleted, not accumulated — re-audit scaffolding against each new model release and remove what the model now does natively."
  - "The bottleneck is not fixed: solving coding surfaces planning as the bottleneck, solving planning surfaces verification, solving verification surfaces taste — the loop's job is to keep making the current bottleneck visible."
---

# LOOPS.md: Field Notes on Agents That Run for Days

**Subtitle:** A Short List of Rules for Letting the Model Drive
**Author:** Andrej Karpathy (independent researcher)
**Form:** Independent reformatting of working notes on long-running agent loops (`loops.md`, version stamp `v060728`) into a conference-style document. Personal use permitted; ideas subject to revision as models change.

Ingested from a page image (OCR + transcription), not a linked URL.

---

## Abstract (as stated)

Most agent systems fail not from a weak model but from a weak harness. The model can write code; it can verify its own output against a rubric it agreed to ten minutes earlier. What it cannot do on its own is decide when to stop, when to restart, or where to write the result — that is the harness's job. The pattern in the source treats the loop as a first-class object: roles are separated, state lives on disk, contracts are negotiated between agents before the first line of code is written, and the harness is read like a stack trace whenever something goes wrong. Short loops, simple state, clean contracts. Everything else is decoration.

**Index terms:** agentic loops, Claude Code, harness design, generator-evaluator pattern, sprint planning, file-system state, contract negotiation, trace reading, deletable scaffolding.

---

## I. Write the Loop, Not the Prompt

A prompt is typed once and forgotten. A loop runs while you sleep. The unit of leverage stopped being the prompt the moment models became good enough to follow a procedure without supervision. Iterating on a single message at three in the morning means you're still in the prompting era — close the tab, write the loop instead. The loop reduces to five verbs: **gather, reason, act, verify, repeat.**

## II. Separate the Roles

Three roles, three context windows, three system prompts:
- **Planner** — turns a vague human sentence into a sprint spec; never touches code.
- **Generator** — writes everything; forbidden from grading its own work.
- **Evaluator** — reads diffs, launches Playwright, plays the app; told from the first message that the code is broken and its job is to prove it.

Mixing roles is the most common failure: a model becomes sycophantic the moment it grades itself, and the loop quietly converges on slop.

## III. Negotiate the Contract First

Before the generator writes a single line, it proposes what "done" looks like and the evaluator pushes back. The two argue via markdown files on disk until they agree on a checklist of testable assertions. ~27 criteria is reasonable for a small app; ~10 is usually too few and the evaluator rubber-stamps. The original spec from the planner is the boundary, but **the contract is what gets graded.** Karpathy calls this the single change that moved his own runs from broken demos to working products.

## IV. Write to Disk, Not to Context

Context windows lie — they compact, they rot, they claim something was said an hour ago behind a summary that was never actually written. A file on disk does not lie. Keep `feature_list.json`, `progress.md`, `contract.md`, and an append-only `log.md` with `## [YYYY-MM-DD] op | title` entries. The model should be able to crash, lose its session, and resume by reading three files. If state can't be described in three files, the state is too complicated.

## V. Let the Loop Restart

Counter-intuitively, the best behavior seen from current frontier models is willingness to discard everything and start over when a run goes sideways. Older models patched a codebase until it resembled archaeology; newer ones, given a clean evaluator and a contract on disk, will delete the project at iteration nine and ship a working version at iteration eleven. Don't interrupt this — the restart is the loop working correctly. Insert a human only when the **contract** is wrong, not when the build is.

## VI. Score the Subjective

Taste is gradable if written down. Four weighted axes: design, originality, craft, functionality. Calibrate the evaluator against three reference sites it's told are good and three it's told are slop. Output is a number between zero and one plus a paragraph explaining the gap. The model won't invent taste — it converges toward whatever taste was described, so describe it carefully.

## VII. Read the Traces

Every debugging insight about agent loops comes from reading the raw transcript, not from running another experiment. Pipe the agent's output to a file, grep for the moment its judgment diverged from yours, edit the prompt for that exact moment, run again. Same muscle as reading a stack trace — except the trace is written in English and mostly consists of the model talking to itself. Skip this step and you're tuning by vibe.

## VIII. Delete the Harness

The harness exists to compensate for the model. As the model improves, half of what was written last quarter becomes overhead. Context-resetting between sessions was load-bearing for one model generation and dead weight for the next; sprint decomposition is the only thing keeping a four-hour build coherent, and is now a constraint on a model that holds two hours in one head. Re-audit the harness against every new release and delete whatever the model now does for free. **A harness that only grows is a harness you've stopped reading.**

## IX. The Bottleneck Always Moves

When coding stops being the bottleneck, planning becomes the bottleneck. When planning is solved, verification becomes the bottleneck. When verification is automated, taste becomes the bottleneck. You never finish — you fix the next thing. The point of the loop is to keep making the bottleneck visible. If everything is going smoothly, you're not looking carefully enough. Find the new bottleneck, fix it, ship a smaller harness, repeat.

---

## Why This Matters Here

Direct overlap with two things already in this vault:

- **[[concepts/omp-tasks-subagents]]** — OMP's planner/task/reviewer agent split is a concrete implementation of Rule II (separate the roles). The `explore` (read-only recon) vs `task` (edit) split mirrors generator/evaluator non-overlap.
- **[[concepts/LLM Wiki Pattern]]** — Rule IV ("write to disk, not to context") is the same load-bearing insight behind this vault's own existence: `index.md`/`hot.md`/`log.md` are exactly the "three files" pattern applied to long-running knowledge work instead of long-running builds.

Rule VIII ("delete the harness") is a useful lint against this vault's own `CLAUDE.md` and skill files accumulating dead weight — re-audit periodically instead of only appending.

## Connections

See [[concepts/Agentic Loops]] for the extracted concept page (the nine rules as a standalone reference).
See [[entities/Andrej Karpathy]] for the author and the related [[concepts/LLM Wiki Pattern]].
