---
type: hot-cache
owner: leo
created: 2026-06-10
updated: 2026-07-01
tags: [gunner-ops, hot]
status: active
---

# Leo — Hot Cache

<!-- Leo: update this at the start of each session -->

## Current Focus

- **gunner-ops**: in production on masterdb (deployed 2026-06-10) but **not yet in use** — throwaway data, go-live target **~2026-06-26** (3-week MVP sprint). See [[leo/apps/gunner-ops]].
- **QP quote-wizard**: active rebuild on `qp-stage`. Roof Phase C (all 4 materials) + native per-building Siding/Windows live. Next: Doors native, proposal-PDF, real per-trade floor %s. See [[leo/qp/quote-wizard]].
- **CRM "Sell mode" (CRM-on-QP)**: record-workspace UI shipped to `qp-stage` — contact rail, unified activity timeline + note composer, Deal/Property/Quotes cards (the first HubSpot-strangler slice). Backend write path locked with Tyler + being built. **Cross-team (Tyler).** See [[leo/qp/crm-sell]].
- **QP pricing-formula (EP Edit)**: roof-asphalt + rate edits + **siding exterior-screws box fix (2026-07-01, verified on stage)** applied to the calc DB (reversible). Pending EP: siding soffit/garage/NT3 items, commission/finance cost-base, location rules. See [[leo/qp/pricing-formula]].
- **Material Order Automation concept**: VP/CEO demo live on CloudFront — QP-priced takeoff + SOW, PDF/CSV measurement upload (HOVER+Nearmap), multi-job list, downloadable PO PDF. Pending: auto-SOW rewrite + two-file upload when CEO sends SOW examples. See [[leo/concepts/material-order-automation]].

## Recent Changes

- 2026-07-01: **CRM Sell-mode record workspace** (Increments 1–4) live on qp-stage; **backend contract locked with Tyler** (write surface `PATCH /crm/lead` + `POST /crm/activity`, notes → masterdb `crm_activities`, backfill-then-switch cutover) — his build, my wiring queued. Open item: `main_quote_id` mapping (crm-transform doesn't populate it). **Cross-team (Tyler).** See [[leo/qp/crm-sell]].
- 2026-07-01: QP **siding exterior-screws fix** (`/3`→`/750`, box-vs-each unit bug) applied + **verified end-to-end** on stage (proj 245: 60 boxes → 1). EP answered the 6 Hardie questions; follow-ups drafted (`~/qp-siding-ep-followup-questions.md`). See [[leo/qp/pricing-formula]].
- 2026-06-23: material-order concept — added measurement upload (PDF/CSV), multi-job list (QP grabs stay pristine), PO PDF export; CEO-surfaced Good-tier ice&water `factor=0.1` bug (real stage-DB under-count, fix pending in pricing-formula).
- 2026-06-23: gunner-ops PROD masterdb cutover prep (Tyler now owns masterdb) — confirmed pure credential swap, ops_app SELECT-only (does NOT need crew_members DELETE — that's gunnerteam_app's), supplied k13-trim keep-list. **Cross-team (Tyler).**
- 2026-06-19: onboarded to gunner-brain — migrated gunner-ops, masterdb-integration, QP (wizard/teardown/pricing-formula), and Dialpad↔HubSpot into `wiki/leo/`.
- 2026-06-11: gunner-ops Stripe (credit-card + cash/check) + multi-contact deployed to prod.
- 2026-06-10: masterdb + gunner-ops deployed to **production**.
- 2026-06-09: masterdb security hardening + ops masterdb cutover (B-lite auth, RLS) + Dialpad SMS/call fixes.

## Active Issues / Open

- Rotate `ops_app` DB password + JWT_SECRET → Secrets Manager (currently plaintext in Lambda env).
- SRS/QXO supplier credentials pending (ABC Supply sandbox live).
- No gunner-ops deploy script yet (manual zip → S3 → update-function-code).
- **Security flag (QP):** git-committed v1 asphalt calc has plaintext DB admin creds — rotate + move to SSM. See [[leo/qp/teardown]].

## Integration Points

- **masterdb** ([[leo/apps/masterdb-integration]]): ops runs as the `ops_app` RLS-subject role inside masterdb; B-lite auth delegates login to masterdb. Shared foundation also used by GunnerTeam iOS + ColinCam.
- **GunnerTeam iOS** ([[gunnerteam/index]]): job data destined to flow into the iOS field app (via masterdb).
- **Stripe / ABC Supply / SRS**: gunner-ops billing + procurement.
- **Dialpad + HubSpot** ([[leo/integrations/dialpad-hubspot]]): call/SMS logging + lead owner assignment (prod HubSpot portal 24467359).

## Key Decisions

- Auth = **B-lite** (ops delegates to masterdb, no local users).
- gunner-ops stays on **AWS SAM** (not SST); masterdb is SST.
- QP wizard **reuses** legacy pricing math, never refactors legacy `ProjectDetails`.
- QP pricing edits are **stage-only** until separate prod approval; calc is DB-formula-driven (SQL migrations, not code).
