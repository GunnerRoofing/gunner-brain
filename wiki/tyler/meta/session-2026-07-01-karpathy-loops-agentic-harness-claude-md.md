---
type: session
title: "Session — Karpathy LOOPS.md Ingest + Agentic Loop Discipline Pushed to CLAUDE.md Across 4 Repos"
owner: tyler
created: 2026-07-01
updated: 2026-07-01
tags:
  - agentic-workflows
  - harness-design
  - claude-md
  - session
status: stable
related:
  - "[[tyler/concepts/Agentic Loops]]"
  - "[[tyler/sources/summaries/karpathy-loops-md-agentic-loops]]"
  - "[[tyler/concepts/omp-tasks-subagents]]"
  - "[[tyler/concepts/LLM Wiki Pattern]]"
  - "[[shared/entities/Andrej Karpathy]]"
sources:
  - "[[tyler/sources/summaries/karpathy-loops-md-agentic-loops]]"
---

# Session — Karpathy LOOPS.md Ingest + Agentic Loop Discipline Pushed to CLAUDE.md

Two-part session: ingest Andrej Karpathy's `LOOPS.md` (field notes on running agent harnesses unsupervised for hours/days) as wiki reference material, then — on follow-up challenge from Tyler ("will you actually be operating with the new loop guidance?") — operationalize the applicable rules into this vault's own `CLAUDE.md` and the three engineering repos' `CLAUDE.md` files.

**Key distinction surfaced this session:** a wiki concept page is passive reference material. Per this vault's own `CLAUDE.md` §2 session read order, a session only auto-reads `CLAUDE.local.md` → section `hot.md` → vault `hot.md` → `index.md`. A concept page under `tyler/concepts/` is outside that path — filing it as an ingest does not change agent behavior. Behavior only changes if the guidance lands in a file that's actually read every session (a `CLAUDE.md`).

## Part 1 — The Ingest

Source: a page image of Karpathy's `LOOPS.md` (OCR'd, no URL). Full transcription: [[tyler/sources/summaries/karpathy-loops-md-agentic-loops]]. Extracted concept: [[tyler/concepts/Agentic Loops]].

**Core claim:** most agent-system failures trace to a weak harness, not a weak model — the model can write and verify code against an agreed rubric, but cannot decide on its own when to stop, restart, or where to persist results.

**The nine rules** (full detail on the concept page):
1. Write the loop, not the prompt — five verbs: gather, reason, act, verify, repeat.
2. Separate the roles — planner / generator / evaluator, three context windows. Mixing roles → the model grades itself → converges on slop.
3. Negotiate the contract first — ~10–27 testable assertions agreed before code is written. The contract, not the original spec, is what gets graded. Karpathy's single highest-leverage change.
4. Write to disk, not to context — `feature_list.json`, `progress.md`, `contract.md`, append-only `log.md`. Context windows compact and rot; files don't.
5. Let the loop restart — a healthy loop discarding a bad run and rebuilding is correct behavior for current frontier models, not a failure to interrupt. Intervene only when the contract is wrong.
6. Score the subjective — taste is gradable if reduced to weighted axes (design, originality, craft, functionality) calibrated against labeled good/slop references.
7. Read the traces — debugging insight comes from grepping the raw transcript for the divergence point, not from running more experiments.
8. Delete the harness — re-audit scaffolding against every model release; a harness that only grows is a harness nobody is re-reading.
9. The bottleneck always moves — solving coding surfaces planning, solving planning surfaces verification, solving verification surfaces taste. The loop's job is to keep the current bottleneck visible.

**Cross-references made during ingest:**
- [[shared/entities/Andrej Karpathy]] — now credits both [[tyler/concepts/LLM Wiki Pattern]] and [[tyler/concepts/Agentic Loops]].
- [[tyler/concepts/omp-tasks-subagents]] — Connections section added: OMP's `explore`/`task`/`reviewer` split is the concrete instance of Rule II (role separation) already in use.
- [[tyler/concepts/LLM Wiki Pattern]] — noted the shared "state belongs on disk, not context" argument (Rule IV applied to knowledge work vs. builds — this vault's `hot.md`/`index.md`/`log.md` already *is* Rule IV, just never named that).

## Part 2 — Operationalizing (the actual point of the session)

Confirmed with Tyler which scope to push into: "vault and the repos I actually work on." Located all four `CLAUDE.md` files on disk (`gunner-brain`, `~/Dev/GunnerTeam`, `~/Dev/gunner-masterdb`, `~/Dev/gunner-comms-admin`) and read each fully before editing, to add only genuine gaps rather than duplicate what each repo already had.

**Audit of what was already covered before touching anything** (avoids Rule VIII violation — don't add scaffolding that restates existing behavior):
- GunnerTeam already had: writer/tester agent separation (Rule II), a retry cap (partial Rule V), and a `claude-md-improver` maintenance pointer (Rule VIII) — all pre-existing, left untouched.
- cc-prompts across all three engineering repos are explicitly "pre-written, pre-approved plans, execute directly" — this **is** Rule III (contract negotiated) already satisfied, just negotiated by the human at cc-prompt authoring time rather than by two agents at runtime. Did not touch the cc-prompt workflow section in any repo.

**Gaps filled, one edit per repo:**

| Repo | File status | Addition |
|---|---|---|
| `gunner-brain` (this vault) | tracked, committed via normal vault flow | `/lint` §6 gained step 6: "harness audit" — every lint pass also checks `CLAUDE.md` itself for redundant/superseded/default-behavior rules, flags candidates in the report, never silently deletes from the shared file (requires Tyler's confirmation). Cites [[tyler/concepts/Agentic Loops]] Rule VIII directly. |
| `~/Dev/GunnerTeam/CLAUDE.md` | git-tracked | Two subsections added to existing "Engineering workflow": **Contract before code** (non-cc-prompt work only — state back a testable "done" checklist before writing code on ad-hoc asks) and **Read the failure before retrying** (the existing retry cap now explicitly requires each retry be informed by the actual trace, not a blind guess). Committed `a2e663c`. |
| `~/Dev/gunner-masterdb/CLAUDE.md` | **gitignored, local-only** — not committed, none needed | Had no Engineering workflow section at all. Added: contract-before-migration (state exact tables/columns/policies + verification plan before writing Alembic), a 2-retry cap scoped to migration/deploy failures, and mandatory upgrade→downgrade→re-upgrade round-trip before touching dev/prod — citing this repo's own history (cc-2148, cc-2150) of migrations that looked correct and weren't. |
| `~/Dev/gunner-comms-admin/CLAUDE.md` | git-tracked | Added a full "Engineering workflow (loop discipline)" section (repo had none): contract-before-code for ad-hoc work, a retry cap citing the repo's own CORS postmortem as the "read the trace" example, and a note to prune "Learned from mistakes" instead of letting it accumulate forever. Committed `8614354`. |

**Verification performed:** read each file's diff stat before committing (`GunnerTeam +6/-0`, `comms-admin +13/-0` — clean additive edits, no accidental restructuring); confirmed `gunner-masterdb/CLAUDE.md` is `.gitignore`d (line 1) so no commit was needed there, only the local file update; confirmed heading counts (`grep -c "^##"`) were sane post-edit on all four files; committed the two tracked repos using each repo's own stated convention ("chore: update CLAUDE.md — [one-line lesson]").

## Why This Matters

The distinction between "filed in the wiki" and "changes what the agent does" is the actual lesson here, and it's a direct instance of the material just ingested: Rule IV (disk not context) only has teeth if the disk location is one that's actually read on the load path. A concept page is disk state nobody re-reads automatically — functionally equivalent to context that never gets compacted back in. The fix wasn't "write more wiki pages," it was "identify the four files that are actually read every session (one per repo Tyler drives) and add the minimum non-duplicative delta to each."

## Open Items

- No push was performed on the two tracked-repo commits (`GunnerTeam`, `gunner-comms-admin`) — left for Tyler's normal push cadence since pushing wasn't part of either repo's stated CLAUDE.md-edit convention.
- The vault's own harness-audit step (added to `/lint` §6) hasn't been exercised yet — first real test is the next `/lint` run, which should surface whether any existing CLAUDE.md rules are now stale.
- Karpathy's Rule VI (score the subjective via weighted axes) has no obvious application in any of the three engineering repos (backend/iOS work, not generative/creative output) — deliberately not forced in anywhere.
