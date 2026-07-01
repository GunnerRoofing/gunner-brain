---
type: concept
owner: leo
created: 2026-06-23
updated: 2026-06-23
tags: [gunner-ops, qp, procurement, concept, demo]
status: developing
related: ["[[leo/qp/pricing-formula]]", "[[leo/qp/quote-wizard]]", "[[leo/apps/gunner-ops]]"]
---

# Material Order Automation — Concept

VP/CEO demo replacing the manual Excel process for verifying + placing build-material
orders. If stakeholders approve → migrate into **procurement in [[leo/apps/gunner-ops]]**.
Started 2026-06-22.

**Artifact:** single self-contained `~/gunner-concepts/material-order-automation.html`
(~1.87 MB — carries inlined libs, see below). Source data alongside: `qp_pricing_rows.json`.

**Hosted demo:** CloudFront `d3v92mu0wsgmfh.cloudfront.net`, behind basic-auth
(gunner-stage AWS, acct 127214181149; S3 `gunner-mat-order-concept-c5ed48`, dist
`E2L331P1TH2HND`). ⚠ Holds REAL Gunner unit costs — don't widen distribution.
Basic-auth creds are **not stored here** (ask Leo). Update = `aws s3 cp … index.html`
+ `create-invalidation … "/*"` (profile gunner-stage). **Teardown owed when demo done.**

## How it works

Ingests a QP quote → auto-generates the material takeoff **and** an aligned Scope of
Work → Sales VP reviews/edits → submits to a Procurement VP who verifies + places the
order. Roofing / siding / both.

**Uses the REAL QP pricing engine, not approximations.** Actual rows pulled from stage
`gg.product_materials_prices` (asphalt subtype 2 tiered Good/Better/Best; siding subtype
14, James-Hardie product-style driven) are embedded, and the backend calc is replicated
client-side: `qty = roundup(eval(base_metric) × (1+waste) × (factor||1))`,
`ext = qty × unit_cost`. So quantities + costs match QP line-for-line. See
[[leo/qp/pricing-formula]] for the calc engine + DB-access path.

## Features (as of 2026-06-23)

- **Verify panel** — coverage vs scope, waste %, QP duplicate-row dedupe/flag, simulated
  stock, live cost vs QP-priced baseline.
- **Drag-and-drop takeoff editing** — reorder / remove / add real QP SKUs.
- **Measurement upload fallback** — left-panel "Job" source. For when the QP quote isn't
  trusted for a job. Upload supplies **measurements + SOW only**; the **QP engine still
  prices the materials** (story intact). Accepts **.csv** (native) and **.pdf** (pdf.js
  bundled inline, offline). Vendor-aware PDF parsers tuned to real reports: **HOVER**
  complete-measurements → siding; **Nearmap** roof report → roofing (handles feet-inches,
  comma numbers, sqft→squares). Parsed values land in editable inputs → re-price live.
  Validation: on a Nearmap job the engine's bundle/roll counts landed inside Nearmap's
  own suggested-material table.
- **Multi-job list** — QP Quotes (canonical, load as clones so demos never corrupt them →
  lets stakeholders "lock in" QP acceptance) + Uploaded jobs. Upload defaults to **new
  job** (QP grabs untouched); "overwrite current" toggle also available.
- **PO PDF export** — real downloadable Purchase Order (jsPDF bundled inline, hand-rolled
  layout, auto-paginates). Fires on place-order (auto-download FINAL), from the PO preview
  modal, and on the sales "submitted" state (DRAFT). GUNNER header + trade-grouped line
  table w/ supplier multiplier + totals.

## Bug surfaced → real pricing fix

CEO caught Good-tier ice & water computing qty 1 instead of following the formula. Root
cause = the `Good_Roofing_Material` I&W row carried a stray `factor:0.1` (Better/Best have
none). Demo hotfixed. **The same `factor=0.1` is REAL in stage `gg.product_materials_prices`
row 745 → live Good quotes under-order I&W ~10×.** Tracked as a pending SQL migration in
[[leo/qp/pricing-formula]] — not just a demo bug.

## Concept-only boundary (IMPORTANT)

Manual **"new job" creation is a demo affordance only.** In gunner-ops procurement, jobs
arrive from the workflow — do **not** port new-job to ops. The upload-override and PO-PDF
ideas may be worth porting; manual job creation is not.

## Honest caveats / simulated

Stock + supplier deltas (ABC/SRS/Beacon) are simulated — real distributor feed = the
separate supplier-pricing track. Siding upgrade toggles default to "none".

## Pending — one pass when CEO's SOW examples arrive

1. Rewrite the auto-SOW templates to match Gunner's real scope language (per trade,
   likely per tier), kept measurement-driven.
2. **Two-file upload** — multi-file drop + auto-classification so a rep can drop a
   measurement report **and** a separate scope doc and the app sorts which is which
   (with a visible "detected X / Y" + flip-if-wrong). Today's dropzone is one file only.
3. Tune scope-doc (prose → SOW bullets) parsing against the real examples; verify on both
   sample jobs; re-push.

Open question for Leo to confirm with CEO: should the scope read **differently by tier**?
