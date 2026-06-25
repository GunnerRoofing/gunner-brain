---
type: session
title: 'Session 2026-06-25: Bedrock Billing Block, QP Key, B1 Org-Reconcile Prep'
created: '2026-06-25'
updated: '2026-06-25'
status: stable
tags:
  - session
  - bedrock
  - billing
  - assistant
  - qp-key
  - b1
  - org-reconcile
  - rls
  - incident
related:
  - '[[tyler/meta/session-2026-06-24-cc1800-2157-llm-engine-b1-cutover]]'
  - '[[gunnerteam/b1-soc2-cc6-least-privilege-db-roles]]'
  - '[[gunnerteam/querywithtenant-diag-2026-06-24]]'
  - '[[tyler/hot]]'
---

# Session 2026-06-25: Bedrock Billing Block, QP Key, B1 Org-Reconcile Prep

Continuation of the cc-1800–2157 arc. Three threads: the half-flip recovery + guardrail (cc-1807), the QP draft service key (cc-1808), and the Bedrock-billing saga that ended in a temporary Anthropic bridge. Plus the decisive B1 org-reconcile diagnostic that reframes the whole cutover.

---

## 1. Half-flip recovery + guardrail (cc-1807)

**Incident:** `503` / `password for role gunnerteam_app is wrong`. Root cause: cc-2137 staged `DB_USER=gunnerteam_app` in SSM but never synced `DB_PASSWORD`; the cc-1806 deploy (v367) re-baked env from SSM and promoted the half-flip → app presented `gunnerteam_app` + master password → 28P01 on every masterdb query.

**Recovery:** reverted `DB_USER` → `postgres` (SSM v6), targeted `terraform apply` re-baked `$LATEST`, published v369, alias → v369. Logs clean. **Did NOT touch DB_PASSWORD** (churning it mid-incident poisons the per-container `getSecret` cache — the 28P01 lesson).

**Guardrails added to CLAUDE.md (committed `15d2017`):**
1. DB role flip must be atomic — `DB_USER` + `DB_PASSWORD` move together or not at all; any unrelated re-bake promotes a half-staged flip.
2. Migration added ≠ applied — the runner only fires on explicit `aws lambda invoke {"_migration":...}`.

---

## 2. QP draft service key (cc-1808)

Key row was already stored correctly from an earlier run — the `403` on the `extract` task proves it (a bad hash → 401, not 403; 403 = key resolved + scope enforced). Row: `b6e2e834`, org `69aad261`, `allowed_tasks=['draft']`, `revoked_at=null`, description "QP draft - Leo".

The `_sql` in-VPC admin path (MIGRATION_SECRET-gated) is how service-key rows get written without a psql tunnel. Hash entered via `read -rs` in Tyler's shell, never echoed; only the SHA-256 hash sent to the DB.

**Final verify:** `draft → 200`, `extract → 403`. Leo clear, Keeper value correct, no re-share.

---

## 3. Bedrock billing block → Anthropic bridge

**The saga:** `/assistant/run` draft returned 502. Root cause chain:
- IAM was fine (cc-1803 `bedrock:Converse`).
- The model IDs **must** be cross-region inference profiles (`us.anthropic.claude-…`) — direct foundation-model IDs throw `on-demand throughput isn't supported`.
- But invoking the inference profile threw `AccessDeniedException` — AWS Marketplace subscription needed.
- `tyler-cli` IAM **allows** `aws-marketplace:Subscribe` (with MFA) — confirmed via `simulate-principal-policy`. The `explicitDeny` without MFA is just `GunnerRequireMFA`.
- Ran the **explicit agreement API** (`create-foundation-model-agreement`) for both models — **agreements created successfully**.
- But `converse` still failed, now with the precise error: **`INVALID_PAYMENT_INSTRUMENT: A valid payment instrument must be provided`**.

**Definitive diagnosis:** account `980921733684` (member of org `o-swi7tgve0n`, payer `661095510147` / Eddie) has no valid payment instrument. `get-foundation-model-availability` shows `authorizationStatus: AUTHORIZED`, `entitlementAvailability: AVAILABLE`, `regionAvailability: AVAILABLE`, but `agreementAvailability: ERROR` (payment). Model agreements are **already accepted** — the moment a valid card resolves for `980921733684`, Bedrock works with zero further change.

**Eddie ask (precise):** confirm a valid/verified payment instrument resolves for account `980921733684` specifically — either directly on its Billing → Payment preferences, or (if consolidated under `661095510147`) the payer card is valid AND member-account Marketplace purchasing is enabled. Eddie reportedly added a card but 10+ min later the error persisted, so it didn't take effect for the right account — still open.

**Bridge decision:** flipped `LLM_PROVIDER=anthropic` (v371) to unblock Leo while billing is sorted. Only the low-sensitivity `draft` task is live (`quote_advisor` customer-pricing path isn't wired). Verified: `draft → 200` (`model: claude-haiku-4-5-20251001`), `extract → 403`. `ANTHROPIC_MODEL_SMART/FAST` unset → llm.js defaults `claude-sonnet-4-6`/`claude-haiku-4-5` (valid Anthropic API names).

**Revert path (one-line, when Eddie fixes the card):** `ssm put LLM_PROVIDER=bedrock` → `terraform apply -target=aws_lambda_function.api` → publish → alias. In-account Bedrock posture is still the end state; Anthropic is the temporary bridge.

**Container-drain technique** (used twice this arc): provider is version-baked, but to force warm containers off old code — `delete-provisioned-concurrency-config --qualifier live` → `put-function-concurrency --reserved-concurrent-executions 0` → wait ~12s → `delete-function-concurrency`. Next request cold-starts fresh. (DB_PASSWORD is runtime-SSM-cached per container, so this is also the flush for stale-secret containers.)

---

## 4. B1 org-reconcile — the decisive finding (cc-2901 prep)

**There are two "Gunner Roofing" orgs, and p16's RLS policies point at the wrong (empty) one.**

| org_id | slug | created | members | GT grants | gt_ data |
|---|---|---|---|---|---|
| `69aad261-347c-44db-8e9e-6c25a8509aa3` | `gunnerroofing` | 06-11 | 8 | 4 | **ALL** (29 vehicles, 6 profiles, 48 time entries) |
| `7d6db1bb-fc40-4063-9b08-a39e4ba95fb5` | `gunner` | 06-10 | 4 | 1 | **none** |
| `87fc75b9-…` | *(no org row)* | — | 2 | 1 | none — dangling membership (fred@fred.com, joe@crew.com) |

`69aad261` (slug `gunnerroofing`) is the **real** operating org — all gt_ data, the app hardcodes it (`GUNNER_ORG_ID`, points seeds), and it = `GUNNERCAM_POINTS_ORG_ID`. `7d6db1bb` (slug `gunner`) is the **masterdb-dev team's shell** (Colin, Leo, Glen + capital-T `Tyler.Suffern@`), zero GunnerTeam data.

**All 18 p16 `gunnerteam_app_org` policies hardcode `7d6db1bb`** — so under FORCE RLS, `gunnerteam_app` resolves the empty org → every real user gets 0 rows → 401. This is THE blocker for the forward flip, and the reason cc-2155/cc-2157 flips failed.

**The cc-2156 diagnostic that "passed" was misleading:** `gt_time_entries=48` showed only because that table has **no** p16 policy; `gt_vehicles`/`gt_user_profile` correctly returned 0 under the `7d6db1bb` policy — which read as "empty tables" but actually meant "policy points at the wrong org."

**Duplicate Tyler:** `tyler.suffern@` (lowercase) = real, org `69aad261`, gt-admin (pre-existing). `Tyler.Suffern@` (capital) = shell, org `7d6db1bb`, gt-admin (the cc-2157 stray — redundant, delete in p18).

**Colin's p17/p18 split (the fix):**
- **p17** (reversible, down_revision `p16_gt_app_rls`): re-point the 18 policies `7d6db1bb` → `69aad261`. Clears the lockout alone. Ships today.
- **p18** (irreversible, after flip): dedupe orgs, migrate/delete shell + orphan FK rows, add `UNIQUE(slug)`. Load-bearing — `auth.js:172` forgot-password defaults `subdomain='gunner'` and slug-resolves non-deterministically across the two "Gunner Roofing" rows.

**Shell `7d6db1bb` FK fan-out (p18 targets):** user_organizations=4, user_app_roles=3, invite_tokens=1 (joe@gunnerroofing.com), reset_tokens=3, contacts=1, **audit_log=68** (immutable — migrate org_id, don't delete).

**cc-2157 strays to revert in p18:** joe's invite `6e9954cb` → repoint `69aad261` or delete; `Tyler.Suffern@` capital grant `bce91d0c` → delete. The 6 Cognito tenantIds are **verified already `69aad261`** (no action — checked live, correct for the forward direction).

**Validation Tyler owns after Colin ships p17:** `SET ROLE gunnerteam_app; SELECT count(*) FROM users` jumps **4 → 8** (shell roster → real roster) = green. Then proxy re-add (username-checked) → cc-2157 flip → gate #2 = `69aad261`.

---

## Cost note (AWS anomaly alert, verified not-ours)

GunnerTeam's `DB_HOST` → proxy → targets **only `gunner-masterdb-production-masterdbcluster-sczazkvf`** (prod). None of the flagged resources are GunnerTeam's:
- `gunner-autolabel` g5.xlarge (us-east-1 GPU) — not ours (flagged in cc-2133 sweep); safe to stop.
- dev Aurora `kdsmbssw` — masterdb-dev team's cluster; GunnerTeam never touches it. Decommission is Colin/Leo's call (their migrate Lambda historically pointed at it).
- `gunner-leads-prod-postgres` (us-east-1) — leads pipeline, not ours.

---

## Lambda version trail
v367 (cc-1806 service-key, promoted the half-flip) → v369 (cc-1807 DB_USER revert) → v370 (Bedrock direct model IDs, abandoned) → **v371 (LLM_PROVIDER=anthropic bridge, current live)**.
