---
type: session
title: "Session 2026-07-02 — crm-transform / QP-CRM cutover: cc-3308 + cc-3309 + cc-3307 Phase B"
owner: tyler
created: 2026-07-02
updated: 2026-07-02
status: stable
tags:
  - session
  - crm-transform
  - qp
  - masterdb
  - backfill
  - cors
  - cutover
related:
  - "[[tyler/meta/session-2026-07-02-cc3308-crm-write-api-cors]]"
  - "[[tyler/meta/session-2026-07-02-cc3309-backfill-skip-test-projects]]"
  - "[[tyler/meta/session-2026-07-02-cc3307-phaseB-purge-manual-notes]]"
  - "[[tyler/meta/session-2026-07-01-cc3305-3306-crm-author-fix-qp-notes-backfill]]"
  - "[[tyler/meta/session-2026-07-02-cc3307-phaseA-qp-purge-eyeball-staged]]"
  - "[[leo/qp/crm-sell]]"
---

# Session 2026-07-02 — crm-transform / QP-CRM cutover (cc-3308, cc-3309, cc-3307 Phase B)

Umbrella for three consecutive `crm-transform` tickets, all serving the same goal: making the **QP "Sell"
CRM write+backfill path production-ready**. Per-ticket detail lives in the three linked notes; this page is
the cross-ticket arc, the shared facts, and the one thing that gates go-live.

## The three tickets (what shipped)

| Ticket | Scope | Outcome | Artifact |
|---|---|---|---|
| **cc-3308** | `crm-write-api` (`write_api.py`) emits `Access-Control-*` on ALL responses | **Shipped** — commit `f5a99fb`, deployed, verified live | code |
| **cc-3309** | `backfill_qp_notes` skips offshore-dev test projects `{92,96,94,113}` | **Code shipped** `d69ccd1` — but dry-run tripped a STOP | code |
| **cc-3307 Phase B** | Purge 4 test/eyeball `source='manual'` notes from prod `crm_activities` | **Done** — 4 deleted, `qpmsg-110603` kept | destructive, throwaway-only, no commit |

## The throughline (why these are one story)

The QP Sell timeline reads from masterdb `crm_activities` via `get-crm-timeline-api-v1`; reps write notes
via `crm-write-api` (POST `/crm/activity`). Making that loop real needed: (1) the browser able to READ write
responses (cc-3308 CORS), (2) a clean historical backfill of QP notes (cc-3309 loader), and (3) the
prod table cleaned of the stage-rehearsal rows that backfill left behind (cc-3307). cc-3308 is done and
unblocks the UI. **cc-3309 + cc-3307 together gate the actual notes backfill — and it is NOT ready to load.**

## The gate: prod notes-backfill is BLOCKED on Leo, on two independent grounds

1. **Export quality (cc-3309 dry-run).** Leo's `qp-notes-prod.jsonl` (243 rows): after skipping the 133
   test-project rows exactly as designed, only 91/110 of the remainder resolve, and of those 91, **72 are
   system "requested a GAF measurement" auto-notifications**, not notes. All 5 resolvable phones are
   test/placeholder contacts — incl. `+15555555555` collapsing 54 rows from ~20 projects onto ONE contact
   ("Andrew Smeallie") = false-attribution. **Effectively zero legit customer notes.** The export reads as a
   stage/QA snapshot, not clean prod. Per the ticket's own guardrail, the real load was NOT run.
2. **Right export doesn't exist here yet** (from cc-3307 Phase A, prior session): `export_qp_notes_prod.sql`
   is Leo-machine-only; prod QP DB is unreachable from the dev account.

**Leo owes:** a clean prod export, plus decisions on (a) excluding system GAF-notifications (a sender/text
rule, out of cc-3309's project-skip scope), and (b) parking placeholder-phone rows instead of resolving.
Neither is code I should infer — both are product calls.

## Decisions made this session

- **cc-3307 `qpmsg-110603` → KEEP** (asked, not assumed). The ticket's stale "Phase B: 0 remain" line
  contradicts its own REVISED body, which defers pre-Oct-2025 note history to a Leo call and confirms it
  does not gate the load (snapshot ids ~110k vs live prod ≤7,370 are disjoint → no `qpmsg-` collision, so
  the blanket `source='qp'` purge premise is void). Final prod: `source='qp'`=1.
- **cc-3308 origins** sourced from the wiki QP env map (`qp-stage.gunnerroofing.com` + `qp.gunnerroofing.com`)
  + DNS, NOT from mirroring `get-crm-timeline-api-v1` literally — its `CORS_ALLOW_ORIGIN` is unset (live on
  `*`), and the ticket forbids `*`. Needs Leo's confirmation these are the literal browser `Origin` values.
- **cc-3309 / cc-3307 did NOT run the destructive/irreversible step** where the ticket said stop — dry-run
  only (3309), and only the 4 named ids (3307B). Held the rest for Leo.

## Reusable facts confirmed / reinforced this session

- **Throwaway in-VPC Lambda is the workhorse for prod masterdb ops** (probe AND destructive): reuse
  `crm-transform` `package/` (pg8000 + RDS CA bundle + `lambda_function`), handler imports
  `lambda_function._connect`; crm-transform VPC (`subnet-0481…`/`subnet-004a…`) + SG `sg-00717…` + role
  `crm-transform-lambda-role` + secret `crm-app-masterdb-proxy`; `AWS_PROFILE=mfa`. **deploy → invoke →
  delete immediately** (confirm gone via failed `get-function`). Used 5× this session; every one deleted.
- **`crm_app` owner-DELETEs** org-scoped `crm_activities` rows (post-`x1` ownership + FORCE-RLS `FOR ALL`
  `_org` policy) — no grant, no master exception.
- **The "dev" proxy is PROD.** `gunnerteam-dev-masterdb-proxy` → the production Aurora cluster
  (`…-production-masterdbcluster-sczazkvf`), per cc-2111. Every write/probe this session hit prod data.
- **`deploy-write.sh` env bug (fixed in cc-3308):** the update-function-code branch never synced env vars
  (only create-function did) → new env vars silently never reached an existing function. Added
  `update-function-configuration` on the update path. Class of bug worth checking in the other deploy script.
- **AWS CLI `--environment Variables={...}` shorthand breaks on a comma inside a value** — use `jq`-built
  JSON. (cc-3308.)
- **RDS SSL context must load system roots AND the RDS bundle additively** — `create_default_context(cafile=…)`
  alone drops the system store → `CERTIFICATE_VERIFY_FAILED`. Match `lambda_function._ssl_context()`. (cc-3309 probe.)
- **`python -c "import write_api"` fails locally** (`boto3`/`pg8000` not installed) — a pre-existing env gap,
  not a code defect; exercise imports with `PYTHONPATH=<boto3-target>:./package`.

## Operational note — MFA session expiry mid-task
cc-3308's cleanup was interrupted when the `mfa` STS session expired (`GunnerRequireMFA` explicit-denies
everything without a live MFA session; the token can't be refreshed without the user's device). User
re-ran `awsmfa`, work resumed. Expect this on any long prod-touching session; sequence destructive steps so
an expiry can't leave a half-done state.

## Loose ends (not this session's scope, flagged)
- **2 out-of-scope `source='manual'` test rows** remain in prod (`18b1d50f` + `d39fda47` on contact
  `2b842ad9`, cc-3301 verification cruft) — targeted 2-id delete when someone wants them gone.
- **Leo's cc-3308 origin confirmation** and the **cc-3309 export-quality reconcile** are the two open Leo items.

## Links
- [[tyler/meta/session-2026-07-02-cc3308-crm-write-api-cors]] — CORS fix detail
- [[tyler/meta/session-2026-07-02-cc3309-backfill-skip-test-projects]] — loader skip + STOP finding detail
- [[tyler/meta/session-2026-07-02-cc3307-phaseB-purge-manual-notes]] — Phase B purge detail
- [[tyler/meta/session-2026-07-02-cc3307-phaseA-qp-purge-eyeball-staged]] — Phase A (prior session)
- [[tyler/meta/session-2026-07-01-cc3305-3306-crm-author-fix-qp-notes-backfill]] — the write-api + loader origin
- [[leo/qp/crm-sell]] — the QP Sell feature all of this serves
