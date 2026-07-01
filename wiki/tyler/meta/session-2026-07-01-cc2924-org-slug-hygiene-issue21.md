---
type: session
title: 'Session cc-prompt-2924: resolve gunner org by slug=gunnerroofing, kill the decoy (issue #21)'
created: '2026-07-01'
updated: '2026-07-01'
status: stable
tags:
  - session
  - masterdb
  - soc2
  - cc6.1
  - alembic
  - rls
  - org-slug
related:
  - '[[tyler/masterdb/masterdb-developer-handoff]]'
  - '[[tyler/masterdb/b1-soc2-cc6-least-privilege-db-roles]]'
  - '[[tyler/meta/session-2026-06-25-bedrock-billing-qp-key-org-reconcile]]'
  - '[[tyler/meta/session-2026-06-24-cc1800-2157-llm-engine-b1-cutover]]'
  - '[[tyler/hot]]'
---

# Session cc-prompt-2924: resolve gunner org by slug='gunnerroofing', kill the decoy (issue #21)

`gunner-masterdb` PR [#24](https://github.com/GunnerRoofing/gunner-masterdb/pull/24) → `main`, closes issue #21. SOC 2 CC6.1 data-hygiene, source-only, all 5 CI gates green.

## Root cause

Code resolved "the gunner org" by `slug='gunner'`, which matches the **decoy** shell org
`7d6db1bb-fc40-4063-9b08-a39e4ba95fb5`, not the real `gunnerroofing`/`69aad261` (the org this whole
B1 lineage — [[tyler/meta/session-2026-06-25-bedrock-billing-qp-key-org-reconcile]],
[[tyler/meta/session-2026-06-24-cc1800-2157-llm-engine-b1-cutover]] — spent multiple sessions
reconciling). Prod is already correct: p17 reconciled the RLS policies, p18 soft-retired the shell
(`is_active=false`), PR #20 fixed `comms_admin_ro`. The remaining risk was **source only** — a
fresh/restored rebuild re-running these from source would silently re-bind the decoy. This closes
that landmine class before the §12 fresh-rebuild work.

## Fix

1. **Stopped creating/resolving the decoy in non-migration source:**
   - `db/migrate.py::_seed_prod` — lookup + create → `slug='gunnerroofing'` (idempotent no-op on
     current prod; correct on a fresh cluster).
   - `db/migrate.py::_provision_gunnerteam_app_guc` — **deleted** (dead code, ABANDONED per its own
     docstring, superseded by p16's role-scoped RLS) + its handler dispatch branch, rather than
     just patching the slug literal.
   - `db/seed.py:30` — dev seed slug fixed.
   - `db/imports/gunner_team/steps/s01_orgs.py:31` — traced: resolves `:slug` from live donor data
     (`tenants.subdomain`), not a source literal. No change needed.

2. **Fixed the two applied migrations that resolve by slug** (content-drift correction — prod
   unaffected, applied migration bodies never re-run there, but a fresh rebuild replays them):
   - `p16_gt_app_rls.py:85` — `slug='gunner'` → `slug='gunnerroofing'`.
   - `e5f6a7b8c9d0_add_gt_weather_tables.py:127` — same fix. **Second occurrence found in the
     audit, not in the original issue #21 report** (Tyler's audit comment on the issue caught it).

3. **Made `p17_reconcile_gt_org.py` idempotent** — this was the real complication, not called out
   in the original scope. Once p16 resolves `slug='gunnerroofing'` directly, a fresh rebuild bakes
   `CANONICAL` (`69aad261`) into the 18 `gunnerteam_app_org` policies on the *first pass* and never
   produces the shell-pointing (`7d6db1bb`) state p17 was written to repair. p17's `_repoint` guard
   previously hard-failed (`RuntimeError`) if it found zero policies referencing `SHELL` — which is
   exactly what happens once p16 is fixed. Changed the guard to treat "already at `target`" as a
   no-op, only raising for a genuinely unrecognized third state. **Verified locally**: upgrade →
   downgrade → re-upgrade round-trip against a real Postgres 16 instance — downgrade still correctly
   re-points to `SHELL`, re-upgrade still correctly re-points to `CANONICAL`. Reversibility intact.

4. **CI fixture alignment** — `.github/workflows/rls-isolation.yml`: the shell org seed (`slug='gunner'`)
   is now needed only for p18's existence guard (`id='7d6db1bb' AND slug='gunner'`), not for p16's
   lookup anymore. Updated the stale comments to say so. `tests/test_rls_isolation.py`'s own pytest
   fixture already seeded the canonical org under `slug='gunnerroofing'` — no change needed there.

## Verification (not just "should work")

Spun up local Postgres 16 (`brew services start postgresql@16`), replicated `rls-isolation.yml`'s
exact seed fixture and upgrade sequence against a scratch DB:
- Full Alembic chain `o15 → p16 → p17 → p18 → p19 → p20 → q1` applies clean.
- Inspected `pg_policies` directly: confirmed p16 bakes `CANONICAL` (`69aad261…`) straight away,
  never touches `SHELL` — and p17 no-ops instead of erroring.
- `tests/test_rls_isolation.py`: 2 passed.
- p17 downgrade → re-upgrade round-trip on a second scratch DB: confirmed reversible both directions.
- `ruff check api db` clean; `bandit -r api db --exclude db/migrations -ll` no medium+; `semgrep
  --config p/python --config p/security-audit` 0 findings; `alembic heads` = 1.
- Pushed → watched real CI: **security, migration-graph, tests, lock-drift, rls-isolation all green**
  (run `28529064497` / `28529064630`).

## Out of scope (logged, not touched)

- **Raw-literal-id class** — `p20_dialpad_agents.py`, `q1_crew_members_rls.py`,
  `t1_crm_sales_schema.py` hardcode `69aad261` directly. Prod-specific, non-portable to a genuinely
  fresh §12 rebuild (a fresh org gets a random id). Separate §12 cutover item — needs either
  re-scoping those policies to the fresh id post-creation, or a deterministic org id scheme.
- **Decoy row retirement** — NOT run as part of this PR (shared cluster, needs a coordinated window
  with Colin). Documented in the PR body as an out-of-band `UPDATE`:
  ```sql
  UPDATE organizations SET slug = 'gunner-shell-retired'
   WHERE id = '7d6db1bb-fc40-4063-9b08-a39e4ba95fb5' AND slug = 'gunner' AND is_active = false;
  ```
  Rename not delete — reversible, no FK sweep needed, belt-and-suspenders once source resolution
  never targets `slug='gunner'` for the org anymore.

## Key insight for future migration-hardening work

A migration written to repair a specific historical bug state (p17: shell→canonical re-point) needs
an idempotent guard, not just a defensive "refuse if unexpected" guard — once the *upstream* bug
(p16's slug literal) is fixed at the source, the downstream repair migration's precondition
(policies pointing at the wrong place) stops being true on a fresh replay, and a guard written only
to detect "is this the state I expect to fix" will hard-fail instead of correctly recognizing
"already fixed, nothing to do." This is a general pattern for any Alembic migration in this repo
that reconciles a specific bad state — the guard should have three outcomes (needs fix / already
fixed / genuinely unexpected), not two (needs fix / error).

## Audit trail

```
grep -rn "slug\s*=\s*['\"]gunner['\"]" api db --include=*.py | grep -v gunnerroofing
```
Only remaining hits: `p18_org_cleanup.py`'s intentional shell-id+slug guard (pins the shell by id
*and* slug together, by design) and prose in `p17`/`migrate.py` doc comments narrating the historical
bug. No code resolves "the gunner org" by `slug='gunner'` anymore. App-slugs (`gunner-ops`/
`gunner-team`) are a different table/concept, untouched.
