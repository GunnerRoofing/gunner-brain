---
type: concept
title: "Agentic Loops"
complexity: intermediate
domain: agentic-workflows
aliases:
  - "LOOPS.md"
  - "Harness Design"
  - "Generator-Evaluator Pattern"
created: 2026-07-01
updated: 2026-07-01
tags:
  - concept
  - agentic-workflows
  - llm
  - harness-design
status: developing
related:
  - "[[sources/summaries/karpathy-loops-md-agentic-loops]]"
  - "[[entities/Andrej Karpathy]]"
  - "[[concepts/omp-tasks-subagents]]"
  - "[[concepts/LLM Wiki Pattern]]"
  - "[[concepts/_index]]"
sources:
  - "[[sources/summaries/karpathy-loops-md-agentic-loops]]"
---

# Agentic Loops

A pattern (Andrej Karpathy, `LOOPS.md`) for running agent systems unsupervised for hours or days. Core claim: most agent-system failures come from a weak **harness**, not a weak model. The model can write code and verify it against an agreed rubric; it cannot decide on its own when to stop, when to restart, or where to persist results. That is the harness's job, and the loop — not the prompt — is the unit of leverage once a model is capable of following an unsupervised procedure.

---

## The Nine Rules

1. **Write the loop, not the prompt.** A prompt is typed once. A loop runs while you sleep. Five verbs: gather, reason, act, verify, repeat.
2. **Separate the roles.** Planner (spec, never touches code), generator (writes, never grades itself), evaluator (reads diffs, runs the app, told upfront the code is broken) — three roles, three context windows. Mixing roles → the model turns sycophantic grading itself → converges on slop.
3. **Negotiate the contract first.** Generator and evaluator argue over a written checklist (~10–27 testable assertions) before code exists. The contract, not the original spec, is what gets graded. Single highest-leverage change Karpathy names.
4. **Write to disk, not to context.** Context windows compact and rot; files don't. Minimum viable state: `feature_list.json`, `progress.md`, `contract.md`, append-only `log.md`. If state needs more than three files to describe, it's too complicated.
5. **Let the loop restart.** Frontier models discarding a bad run and rebuilding from scratch is correct behavior, not something to interrupt. Intervene only when the *contract* is wrong — never when the build merely looks messy mid-flight.
6. **Score the subjective.** Taste is gradable if written down: four weighted axes (design, originality, craft, functionality), calibrated against reference examples explicitly labeled good/slop. Output = score 0–1 + explanation.
7. **Read the traces.** Debugging insight comes from grepping the raw transcript for the moment judgment diverged, not from running more experiments. Same muscle as reading a stack trace, in English.
8. **Delete the harness.** Scaffolding compensates for model weakness; as models improve, re-audit and delete what the model now does natively. A harness that only grows is a harness nobody's re-reading.
9. **The bottleneck always moves.** Coding solved → planning is the bottleneck. Planning solved → verification is the bottleneck. Verification solved → taste is the bottleneck. The loop's job is to keep the current bottleneck visible, not to reach a finished state.

---

## Why It Works

The generator/evaluator split (#2) is a structural fix for a specific failure mode: a single model instance cannot honestly grade its own output because it has no incentive (and often no visibility) to fail its own review. Splitting context windows forces an independent check, the same reason code review by a second party catches things self-review doesn't.

The contract-first move (#3) converts "done" from a vibe into a checklist both sides already agreed to, so disputes at evaluation time are checklist disputes, not scope disputes.

Disk-based state (#4) exists because LLM context is lossy and non-durable — it gets compacted or summarized, and a summary is not the same artifact as what was actually said. This is the identical argument behind [[concepts/LLM Wiki Pattern]]: a wiki is disk-based state for long-running *knowledge* work, the way `progress.md`/`contract.md` are disk-based state for long-running *build* work. Same failure this vault is built to avoid.

## Comparison to This Vault's Own Tooling

| Rule | Karpathy's harness | This vault / OMP |
|---|---|---|
| Separate roles | planner / generator / evaluator | `plan`, `task`, `reviewer`, `explore` agents — see [[concepts/omp-tasks-subagents]] |
| Disk state | `feature_list.json`, `progress.md`, `contract.md`, `log.md` | `index.md`, `hot.md`, `log.md` per wiki section |
| Read the traces | grep raw agent transcript | reading OMP session traces / meta session notes to debug an agent's decision |
| Delete the harness | re-audit scaffolding per model release | periodic `/lint` passes should also prune stale skill/CLAUDE.md rules, not just wiki pages |

## Open Questions

- Karpathy's contract negotiation (#3) assumes a generator and evaluator model of comparable capability arguing to convergence. Untested here: whether this vault's single-session Claude workflows would benefit from an explicit generator/evaluator split for cc-prompts, versus the current single-pass task + optional `code-reviewer`/`pr-test-analyzer` agent pattern.
- No worked example in the source of the contract negotiation transcript itself — the claim (~27 criteria reasonable, ~10 too few) is stated, not derived.

## Connections

See [[sources/summaries/karpathy-loops-md-agentic-loops]] for the full source transcription.
See [[entities/Andrej Karpathy]] for the author and his other contribution to this vault, [[concepts/LLM Wiki Pattern]].
See [[concepts/omp-tasks-subagents]] for the existing OMP role-separation pattern this concept extends.
