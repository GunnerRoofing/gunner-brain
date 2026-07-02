---
type: session
title: "Session 2026-07-02 — cc-3307 Phase B: purge 4 test/eyeball manual notes; keep qpmsg-110603"
owner: tyler
created: 2026-07-02
updated: 2026-07-02
status: stable
tags:
  - session
  - crm-transform
  - masterdb
  - purge
  - destructive
  - qp
related:
  - "[[tyler/meta/session-2026-07-02-cc3307-phaseA-qp-purge-eyeball-staged]]"
  - "[[tyler/meta/session-2026-07-02-cc3309-backfill-skip-test-projects]]"
  - "[[leo/qp/crm-sell]]"
---

# Session 2026-07-02 — cc-3307 Phase B (destructive, throwaway-runner only)

Closes cc-3307. Phase A (191 rehearsal `source='qp'` rows deleted, `qpmsg-110603` retained) was done
in the prior session — see [[tyler/meta/session-2026-07-02-cc3307-phaseA-qp-purge-eyeball-staged]].
This session ran the **REVISED-2026-07-02 Phase B**.

## The revision (Leo's plot twist)

The original blanket `source='qp'` purge premise is **void**: the rehearsal rows came from the
`prod_oct17` snapshot (msg ids ~110k); LIVE prod `gg.message` only reaches ~7,370. The `qpmsg-<id>`
ranges are **disjoint**, so the fresh prod export can't collide with the retained row — no purge
needed before the load. Revised Phase B therefore deletes ONLY the test/eyeball `source='manual'`
notes (Phase A's `source='qp'` filter never touched these).

## What ran

1. **Read-only probe first** (throwaway in-VPC Lambda, `crm_app`, ids/flags/contact/dedup only — never
   bodies). Confirmed:
   - `source='qp'` count = **1** (`qpmsg-110603` / `7fcd9b82-de1e-49c3-8fff-356df7ab056d`, contact
     `692cf941`) — Phase A still intact.
   - `source='manual'` count = **6**. Four match the ticket's delete list; two do not (see below).
   - Resolved Leo's **truncated** pixel-check UUIDs (ticket only gave `e3da304e-…` / `ab6cdb15-…`) to
     their full values by matching against live rows — did NOT guess UUIDs for a destructive op.

   | ticket id | full UUID | flag | contact | posted |
   |---|---|---|---|---|
   | eyeball comment | `76d22c41-23dc-46c4-aaf7-041569ba0487` | comment | `692cf941` | 07-02 04:21 |
   | eyeball worknote | `64a09225-6a85-482c-a5b3-316e6c69e0aa` | worknote | `692cf941` | 07-02 04:21 |
   | Leo pixel comment | `e3da304e-6757-4112-9fe6-0d3dcfd2a9d8` | comment | `692cf941` | 07-02 14:56 |
   | Leo pixel worknote | `ab6cdb15-58cf-4b4d-a20c-cf729ba8b29e` | worknote | `692cf941` | 07-02 14:55 |

   Leo's pixel-check notes existing (14:55–14:56 today) confirms **his eyeball is done** — retention of
   `qpmsg-110603` for the eyeball is no longer needed.

2. **Destructive delete** (throwaway runner, `crm_app` owner-DELETE, FORCE-RLS `_org` policy permits).
   Triple-guarded so a mistyped id can never touch the `qp` row or a `dialpad` row:
   `DELETE FROM crm_activities WHERE org_id = :o AND source = 'manual' AND id = ANY(:4ids) RETURNING id`.
   Result: **`deleted_count=4`** (exactly the 4 above), `targets_still_present_after=0`,
   `qp_count_after=1`, `manual_count_after=2`.

3. Runner + `/tmp` scratch **deleted immediately** (both probe and purge functions confirmed gone via
   failed `get-function`). No repo commit — throwaway-only, per ticket.

## Decision: KEEP qpmsg-110603 (asked, not assumed)

The ticket is internally contradictory: the stale completion line says "Phase B: 0 remain" (delete it),
but the REVISED Phase B body explicitly defers it — *"Decide, with Leo, whether pre-Oct-2025 note
history belongs in the CRM timeline… does NOT gate the fresh-export load."* Since it's destructive and
recoverable only from the `prod_oct17` snapshot, I surfaced the conflict and asked. **Chose KEEP**:
`qpmsg-110603` stays; `source='qp'` count remains 1. Re-loadable/removable later either way; does not
block the fresh-export load (disjoint ids).

## ⚠ Out-of-scope rows left in place (flagged, NOT deleted)

Two `source='manual'` rows are NOT in cc-3307's 4-id list and were left untouched:
- `18b1d50f-e329-457d-8b52-d7d57652580b` (worknote) + `d39fda47-1c31-40a2-a8e4-4425a24911cd` (comment),
  both on contact **`2b842ad9`** (different from the eyeball contact), posted 07-01 19:44 — ~8h before
  the eyeball. These match cc-3301's "verified 201 end-to-end (worknote + comment)" test cruft.
- **Follow-up:** if these should go, it's a targeted 2-id `DELETE … WHERE source='manual' AND id=ANY(…)`
  (same runner recipe). Deliberately not folded into cc-3307 — its scope is the 4 named ids only.

## Final prod state (org `69aad261-…`)
- `source='qp'`: **1** (`qpmsg-110603`, kept)
- `source='manual'`: **2** (the out-of-scope cc-3301 test rows — flagged above)
- `source='dialpad'`: untouched throughout

## Reusable facts (unchanged, re-confirmed)
- `crm_app` owner-DELETEs org-scoped `crm_activities` rows (post-`x1` ownership + FORCE-RLS `FOR ALL`
  `_org` policy) — no grant, no master exception.
- Purge-runner recipe: reuse `crm-transform` `package/` (pg8000 + RDS CA + `lambda_function`), handler
  imports `lambda_function._connect`, crm-transform VPC `subnet-0481…`/`subnet-004a…` + SG `sg-00717…`
  + role `crm-transform-lambda-role` + secret `crm-app-masterdb-proxy`; `AWS_PROFILE=mfa`. pg8000.native
  autocommits per statement. deploy → invoke → **delete immediately**.
- DB is the **production** masterdb via `gunnerteam-dev-masterdb-proxy` (cc-2111).

## Links
- [[tyler/meta/session-2026-07-02-cc3307-phaseA-qp-purge-eyeball-staged]] — Phase A + eyeball staging
- [[tyler/meta/session-2026-07-02-cc3309-backfill-skip-test-projects]] — the load this unblocks (also STOP-gated on export quality)
- [[leo/qp/crm-sell]] — the CRM Sell timeline these notes feed
