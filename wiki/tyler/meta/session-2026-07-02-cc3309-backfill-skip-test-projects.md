---
type: session
title: "Session 2026-07-02 — cc-3309: backfill_qp_notes skip test projects + export-quality STOP"
owner: tyler
created: 2026-07-02
updated: 2026-07-02
status: stable
tags:
  - session
  - crm-transform
  - backfill
  - qp
  - data-quality
  - blocked
related:
  - "[[leo/qp/crm-sell]]"
  - "[[tyler/meta/session-2026-07-01-cc3305-3306-crm-author-fix-qp-notes-backfill]]"
  - "[[tyler/meta/session-2026-07-02-cc3307-phaseA-qp-purge-eyeball-staged]]"
---

# Session 2026-07-02 — cc-3309: backfill_qp_notes skip test projects + export-quality STOP

## Code shipped (commit `d69ccd1`, main)

`lambda_function.py` `backfill_qp_notes` mode now excludes offshore-dev internal test projects.

- `SKIP_PROJECT_IDS = {92, 96, 94, 113}` (module default), payload-overridable via
  `"skip_project_ids":[…]` (None → default; explicit `[]` = skip nothing).
- Skip check is the first thing in the row loop — a skip-set row is counted `skipped_test_projects`
  and `continue`d **before** contact resolution, so it's never inserted and never parked.
- `project_id` compared as **str** on both sides (JSONL emits int, CSV str) — normalized once into
  `skip_ids`. Stats also echo `skip_project_ids` (sorted) so a dry-run is self-documenting.
- Everything else unchanged (type=note, source='qp', is_internal=true, dedup `qpmsg-`||id,
  phone→contact, ON CONFLICT DO NOTHING, per-row try/except logging dedup only).

## Dry-run (`{"mode":"backfill_qp_notes","s3_key":"crm-backfill/qp-notes-prod.jsonl","dry_run":true}`)

```
source_rows            243
skipped_test_projects  133   ← exactly as ticket predicted
would_insert           110
contact_resolved        91   (82.7% of kept — NOT the ~100% the ticket expected)
parked                  19
already_present          0
failed                   0
```

Mechanically perfect: 243 → skip 133 → 110 kept, matching the ticket's numbers to the row. **The
real load was NOT run** — the dry-run tripped the ticket's own STOP guardrail ("If … the resolve rate
on non-test rows looks low, STOP and reconcile with Leo before the real load").

## ⚠ STOP — the dry-run disproves the ticket's premise ("~110 real notes resolving ~100%")

The skip set itself is **clean**: all 133 skipped rows have `contact_phone = None` and offshore-dev
senders (`@arjan.kiran` ×70, `@amit.maurya` ×18, `@amitm` ×14, …) — no real customer note was wrongly
excluded. The problem is that the **remaining 110 are also almost entirely non-customer content**:

- **79 of 110 are system auto-notifications**, not notes — "X has successfully/failed to request a GAF
  measurement for project N with order_id M." (numeric senders `359/360/361/…`). 72 of these resolve,
  7 park.
- **Only 5 distinct phones resolve at all**, and every one is a test/placeholder contact:
  - `+12032202249` → `arjan.kiran+june05test012026@gunnerroofing.com` (test alias) — 28 rows, all system GAF msgs
  - `+14339239494` → `doug.kilzer+qpjune5@gunnerroofing.com` ("Test-June TestqpRoofing") — 4 rows
  - `+14567890366` → `qaisar.anjum+04june2026@gunnerroofing.com` (test alias) — 3 rows
  - `+16575675677` → `qaisar.anjum+june082026a11aa@gunnerroofing.com` ("Test Test") — 2 rows
  - `+15555555555` → **one** contact "Andrew Smeallie" `info@growthoperationsco.com` — a **placeholder
    phone collapsing 54 rows from ~20 different projects onto a single contact** (false-attribution bomb).
- Of the 19 human-authored rows that resolve, **17 attach to the `+15555555555` placeholder**; the only 2
  on a non-placeholder phone are junk (`"yo"`, `"unknown user?"` on p282, sender empty).
- The 19 parked rows are likewise all test chatter (p123 `"testmessage"` ×10 on `+12134567890`) or system
  GAF notifications to phones absent from `crm_contacts`.

**Net: effectively zero of the 110 kept rows are legitimate customer notes correctly resolving to a real
customer.** Loading them would (a) spray 79 system notifications into the CRM note timeline and (b) mis-file
54 unrelated notes onto "Andrew Smeallie" via the shared placeholder phone.

## What Leo needs to decide before the real load

1. **Is this the right export?** `qp-notes-prod.jsonl` reads as a stage/QA snapshot (test-alias emails,
   `+15555555555`/`+1555…` placeholders, `+june…test…` addresses), not clean prod customer data. This is
   consistent with [[tyler/meta/session-2026-07-02-cc3307-phaseA-qp-purge-eyeball-staged]] — the prod QP
   export was the blocked item there too.
2. **Should system GAF-measurement notifications be in scope at all?** They're not rep notes; if excluded,
   the filter is a sender/text rule (numeric sender + "requested a GAF measurement"), not a project rule —
   out of cc-3309's scope, needs a decision.
3. **Placeholder-phone false attribution** (`+15555555555`, `+1555…` family): any note whose only contact
   key is a shared placeholder should probably park (unattached), not resolve. Also a resolution-rule
   decision, not a project-skip.

I did **not** infer extra filters (system-msg exclusion, placeholder-phone parking) — cc-3309's scope is
the project skip, which is done and correct. Those are reconcile items for Leo.

## Verification mechanics / method notes
- All contact/phone lookups done read-only via the documented throwaway-Lambda pattern (reuse
  `crm-transform-lambda-role`/VPC/SG, `crm_app` creds; deploy → invoke → **delete immediately**, each
  confirmed gone). Three probes total (phone-existence, contact-detail), all deleted.
- `crm-transform` redeployed with the skip code (`deploy.sh`, env untouched); ping OK (crm_app, PG 17.7,
  31,886 contacts). DB is the **production** masterdb cluster via `gunnerteam-dev-masterdb-proxy` (cc-2111).
- Local analysis of the 243-row export corroborated the live dry-run exactly (243/133/110).

## Links
- [[tyler/meta/session-2026-07-01-cc3305-3306-crm-author-fix-qp-notes-backfill]] — the mode this extends
- [[tyler/meta/session-2026-07-02-cc3307-phaseA-qp-purge-eyeball-staged]] — prod-export blocker, same theme
- [[leo/qp/crm-sell]] — the CRM Sell timeline these notes feed
