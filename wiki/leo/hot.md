---
type: hot-cache
owner: leo
created: 2026-06-10
updated: 2026-06-19
tags: [gunner-ops, hot]
status: active
---

# Leo — Hot Cache

<!-- Leo: update this at the start of each session -->

## Current Focus

- **gunner-ops**: in production on masterdb (deployed 2026-06-10) but **not yet in use** — throwaway data, go-live target **~2026-06-26** (3-week MVP sprint). See [[leo/apps/gunner-ops]].
- **QP quote-wizard**: active rebuild on `qp-stage`. Roof Phase C (all 4 materials) + native per-building Siding/Windows live. Next: Doors native, proposal-PDF, real per-trade floor %s. See [[leo/qp/quote-wizard]].
- **QP pricing-formula (EP Edit)**: roof-asphalt + a few rate edits applied to stage calc DB (reversible). Pending EP: commission/finance cost-base, location-based material rules. See [[leo/qp/pricing-formula]].

## Recent Changes

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
