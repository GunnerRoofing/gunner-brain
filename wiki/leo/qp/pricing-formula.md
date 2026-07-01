---
type: reference
owner: leo
created: 2026-06-19
updated: 2026-07-01
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

## Siding / Hardie — EP answers round (2026-07-01)

EP answered the 6 open Hardie/accessory questions from the order-comparison audit. **Reading the live
`gg.product_materials_prices` subtype-14 rows first collapsed 4 "quick wins" to one real change:**

- **Applied (reversible):** exterior screws `siding_soffit_sqft/3` → `/750` (row 1097). The audit's "+66"
  over-order was a **per-each vs per-box** unit mismatch — EP: 1 box per 7.5 squares (750 sq ft) of soffit,
  $27.99/box. Migration `20260701_siding_exterior_screws_box_fix.sql`, backup `gg.pmp_bak_20260701_ext_screws`.
  **Verified end-to-end** via `siding-pricing-calculator-api-v3` (proj 245, tab `Siding Main`): line now
  qty **1 / $27.99** (was 60 boxes / $1,679).
- **No-ops (already correct in live DB):** J-channel isn't in Hardie (only vinyl/certaplank); Henry Blueskin
  coverage `area/3.75 + 25% waste` already matches EP.
- **Held:** soffit price $18.75/each — no "beaded"/"Certainteed" product exists in the DB; only a vinyl
  vented soffit (row 501 @ $38). Won't change a live price on an uncertain product-identity match.
- **Needs EP / a build phase:** garage-door PVC jamb trim (`opening_LF ÷ 18`, new input + price); NT3 =
  James Hardie trim across 5 applications (fascia 20% / window-door 25% / corner 30% — mostly already
  compliant; inside-corner waste + per-application LF drivers to audit); Henry flashing-tape swap when
  Blueskin is used. Follow-up questions drafted: `~/qp-siding-ep-followup-questions.md`; spec `~/qp-siding-ep-answers.md`.
- **PROD promotion** of the screws migration pending (Leonard).

> Gotcha: `product_materials_prices.update_by` is a **bigint** user-id (not text) — don't stamp it with a
> string in a migration or the txn aborts. Stage DB `project_auto` PK column is `project_id` (not `id`).

## Links
- [[leo/apps/quote-portal]] — QP overview, stage Aurora access path
- [[leo/qp/quote-wizard]] — the wizard that consumes these prices; the DB-formula engine
- [[leo/qp/teardown]] — the security flag on the asphalt calc creds
