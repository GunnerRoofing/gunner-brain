---
type: reference
owner: leo
created: 2026-06-19
updated: 2026-06-19
tags: [qp, quote-portal, pricing, formulas, database, migrations]
status: active
---

# QP — Pricing Formula Update (EP workbook → calc DB)

Side-quest started 2026-06-18: applying Leonard's updated quote-engine workbook (`Gunner_Quote_Tool EP Edit.xlsx`) to QP's pricing. Part of [[leo/apps/quote-portal]].

## Decision & job shape

- **Apply to the BACKEND calc DB** (`portal-backend`), **NOT the frontend wizard**. Cover **all trades**. **Stage-only** deploys (prod untouched until separate approval).
- All trades are **DB-formula-driven**: calcs string-substitute and `Function()`-eval `base_metric` / `condition` rows from the DB, so pricing edits are live immediately and the work = `UPDATE` formula/rate rows via SQL migrations (`portal-backend/migrations`). **Calc code does not change.** Same engine described in [[leo/qp/quote-wizard]].
- Roof formulas live in `gg.product_materials_prices`; rates in `gg.margin` / `lk_state_tax` / `product_additional_charges`.

## Stage DB access

- Aurora PG cluster **`stage-gunner-aurorapgdb`** (acct `127214181149`), DB **`prod_oct17`** — a prod snapshot restored into the stage cluster, isolated from dev, ~93 test projects, safe to write.
- **Access:** SSM port-forward through app EC2 **`i-01a18718706e85336`** → `psql localhost:5433`.

> ⚠ CRITICAL: credential present — not copied. DB admin creds for this database appear in plaintext in a git-committed v1 asphalt calc — value omitted, rotate + move to SSM. See [[leo/qp/teardown]].

## Method — diff-report-first

- NOT a clean formula swap: the workbook and the live DB express the same lines in **different unit conventions**. So the approach is **diff-report-first** (`~/qp-formula-diff.md`): apply only **genuine** changes (waste %, condition, which-measurements, new/removed lines), not cosmetic differences.
- **Conclusion:** EP's workbook is **~95% already matching live**; genuine edits concentrate in **ROOF ASPHALT**.

## Applied to stage (2026-06-18)

All reversible via `*_bak_20260618*` tables; live immediately since calc is data-driven:

- roof hip & ridge coverage `/25` (`*0.04`)
- roof shield (GAF Weather Watch) waste → `0.08`
- siding Color / Quad Max waste `0` → `0.3825`
- NY state tax `4` → `8` (state-only → state+local)
- ridge vent → default 50ft rolls @ 5% waste
- **Held** CT/RI/NJ tax (live rates more accurate).

## Still pending

- **Commission / finance base:** the calc applies on a **post-margin** base vs the workbook's **cost** base (= a code change, held for finance sign-off).
- **Location-based material rules — SCOPED 2026-06-19, not built:** some states require certain materials (flex seal, ice & water); coastal / "by the beach" homes need saltwater-grade (galvanized → stainless nails). Coastal = auto-detect from address + rep override. Foundation verified (every calc already evals condition formulas with state mapped in). **Blocked on EP** filling a rule-matrix template.

## Links
- [[leo/apps/quote-portal]] — QP overview, stage Aurora access path
- [[leo/qp/quote-wizard]] — the wizard that consumes these prices; the DB-formula engine
- [[leo/qp/teardown]] — the security flag on the asphalt calc creds
