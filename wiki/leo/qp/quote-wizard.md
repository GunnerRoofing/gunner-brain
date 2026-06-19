---
type: reference
owner: leo
created: 2026-06-19
updated: 2026-06-19
tags: [qp, quote-portal, quote-wizard, frontend, pricing]
status: active
---

# QP — Quote Wizard (rebuild)

The active rebuild of the sales-rep quote flow as a guided **4-step wizard** (Property → Scope → Package → Send), replacing the legacy `ProjectDetails.js` — a 4,343-line tab-based JSON-tree mega-form — in `GunnerRoofing/sales-portal-frontend`. Part of [[leo/apps/quote-portal]].

## Approach

- **Goal:** a guided, opinionated quoting experience instead of the legacy mega-form.
- **Location:** `src/app/components/Project/QuoteWizard/`.
- A wizard-only `useQuoteServices.js` hook **reuses legacy pure math helpers but never refactors the live legacy `ProjectDetails`** — that file stays the flagged fallback being replaced.
- **Round-trips with legacy:** wizard persists via **merge-patch of `selections_json`**, so state round-trips cleanly with the legacy form.
- Team applies a "Three Questions" (Architect / Operator / 10-year-old) review on everything built.

## Shipping mechanics

- **Branch:** `redesign/quote-wizard`.
- **Feature flag:** `NEXT_PUBLIC_QUOTE_WIZARD=true` (build-time). Deployed **only to qp-stage**; the prod flag stays **OFF**.
- **Deploy:**
  ```
  gh workflow run deploy.yaml --repo GunnerRoofing/sales-portal-frontend \
    --ref redesign/quote-wizard -f environment=stage -f branchName=redesign/quote-wizard
  ```
- **Gotchas:**
  - Must pass `branchName` — omitting it **silently builds the dev branch** (= the old QP).
  - CI builds from the GitHub **remote**, so `git push` BEFORE every deploy.
  - EC2 SSM rollout lags the workflow "success" by ~2–3 min.

## What's built + live on stage (2026-06-19)

### Shells, tiers, persistence
- 4-step shells; service toggle for simple services.
- Tier selection **Good / Better / Best** with live total.
- Persistence of tier + roof structure (merge-patch `selections_json`, round-trips with legacy).
- Per-pitch roof structure override.

### Roof pricing — Phase C COMPLETE (all 4 roof materials)
- Auto-recompute on change (**debounced 1.2s**).
- Translates `roofing_selection_data` + GAF → flat per-side fields (`lib/roofPricingFields.js`, **differential-tested 10/10** vs legacy helpers) → `fetch_price` per gate-active material → writes `price[label]`.
- Materials: **Asphalt** (`/pricing/asphalt`), **EPDM**, **Liberty**, **Metal** (own endpoints).
- **Specialty / synthetic roof DEFERRED** — needs a product-type/color picker; the calc gates on `product_subtype`, not a yes-flag.

### Metal / flat-roof
- Single flat result under `data.primary`; slider + takeoff work.
- GBB tier cards absent for these single-product materials — **pending decision** whether metal should be tiered.

### Native Hover services — Siding + Windows (PER-BUILDING)
- Fully working on stage (verified 2026-06-18), **per-building**.
- **Siding** calc is `siding-pricing-calculator-api-v3` (repo yaml was stale showing v1). v3 is per-building: `GET /pricing/siding/<projectId>?tab_name="Siding <BuildingName>"`, reads `selections_json.jvalue.hover_services_data[TAB].field_values`. So one job can have e.g. Hardie on Main + vinyl on Garage.
- **Windows** = `windows-calculator-api-v3`, same per-building plumbing (MVP: manufacturer + work type + count; grids/colors deferred).
- Price tree stores per-building keys: `price["Siding Main"]`, `price["Windows Patio"]`, etc. (matches legacy).
- **Doors** still on the temporary bridge (`pricing-calculator-door-api-v3`, per-building, counts per door variant) — **next to build natively**.

### Add-a-service handoff bridge
- **Phase 1 done:** tap to add any service. Hover services route to a temporary **"handoff bridge"** that renders legacy `ProjectDetails` on demand via a runtime `showLegacy` state in `page.js`.
- **Strategy:** wizard-native is the destination; the bridge is temporary and retired per service as native lands (Siding + Windows now native, **Doors next**).

### Guided product tiers on Scope (siding/windows value-engineering)
- Decision 2026-06-19: each building's siding product options are **ordered + badged Value / Mid / Premium by cost** on the Scope step (rep downgrades → live reprice).
- Backed by a NEW portal-backend feed: `project-overview-api-v1` now returns `product_costs.siding = {product_name: costPerSq}` (branch `feat/product-costs-overview`, deployed stage). Frontend consumer deployed (commit `550793d`).
- **Windows tiering deferred** — no clean product-line tiers.

### Price adjuster v2 — Package step (`PriceStrip.js`)
- Always-visible price strip between the G/B/B tiers and the Total.
- **Hybrid "value-engineer then floor":** sliding price DOWN first cheapens the BUILD via a downgrade ladder (margin held); only past the cheapest legit build does it eat margin down to a min-margin floor → red chip → existing **discount-approval flow**.
- **v2 deployed:** tiers-as-slider (slider bounds tier-independent, tier markers on the track, smooth dragging); persistence (`priceTarget` → `selections_json.price_adjustment`); Match-competitor-price input.
- **Placeholders still:** `MIN_MARGIN_PCT=20` + `MAX_MARGIN_BONUS=10` (need real per-trade floor %s from business); the siding/windows material-swap ladder (needs downgrade order from EP); full proposal-PDF integration; independent feature flag.

### Takeoff (materials & quantities) — INTERNAL ONLY
- Headed for the **invoice, NOT customer-visible** — customers see only tier "What's included" quality.
- Send step has a collapsed **"Internal — materials & quantities"** view with product + qty + cost.
- **Units (`uom`):** frontend renders qty+uom once backend supplies it. Backend **PR #212 merged to portal-backend main** (migration `ADD COLUMN uom` + `get-material-price-api` + v2 calc), but still needs: per-env migration + applying the one-liner to deployed v1 artifacts + data-entry backfill before units appear.

## Pricing / calculator contract

- All trade calcs use the **generic DB-formula-driven engine** (string-substitute + `Function()`-eval `base_metric` / `condition` rows). Calc code does not change — pricing edits are DB row updates. See [[leo/qp/pricing-formula]].
- Roof formulas in `gg.product_materials_prices`; rates in `gg.margin` / `lk_state_tax` / `product_additional_charges`.
- Wizard roof flow: `roofing_selection_data` + GAF → flat per-side fields (`lib/roofPricingFields.js`) → `fetch_price` per gate-active material → `price[label]`.
- Per-building Hover services read `selections_json.jvalue.hover_services_data[TAB].field_values` and write per-building price keys.

## Open / deferred

- **Doors** → next native build (currently on the temporary bridge).
- **Windows tiering** — deferred (no clean product-line tiers).
- **Specialty / synthetic roof** — deferred (needs product-type/color picker; gates on `product_subtype`).
- **Metal tiering** — pending decision (GBB cards absent for single-product materials).
- **Price adjuster:** real per-trade floor %s, siding/windows downgrade ladder from EP, full proposal-PDF integration, independent feature flag.
- **Takeoff units:** per-env migration + one-liner on deployed v1 artifacts + data-entry backfill.

## Links
- [[leo/apps/quote-portal]] — QP overview, repo + env map
- [[leo/qp/teardown]] — deployed-gateway version drift (why siding is v3)
- [[leo/qp/pricing-formula]] — the DB-formula calc engine + EP workbook work
