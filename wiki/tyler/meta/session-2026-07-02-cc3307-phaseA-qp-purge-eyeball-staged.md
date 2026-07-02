---
type: session
title: "Session 2026-07-02: cc-3307 Phase A — prod qp-rehearsal purge + eyeball staged; blocked on Leo's prod export"
created: 2026-07-02
updated: 2026-07-02
tags:
  - session
  - crm
  - masterdb
  - backfill
  - purge
status: stable
related:
  - "[[tyler/meta/session-2026-07-01-cc3305-3306-crm-author-fix-qp-notes-backfill]]"
  - "[[leo/qp/crm-sell]]"
---

# Session 2026-07-02: cc-3307 Phase A + eyeball staging (Phase B / export / backfill blocked on Leo)

Goal was the full close-out sequence (Phase A → eyeball → prod export → Phase B → backfill → go).
Ran everything reachable from this seat; the sequence is now paused at its one genuinely
external dependency: **Leo's `export_qp_notes_prod.sql` exists only on Leo's machine, and prod
QP's DB is not reachable from Tyler's AWS account.**

## cc-3307 Phase A — DONE, exact counts

Throwaway runner `cc3307-purge-tmp` (crm-transform zip + `cc3307_purge.py`, same VPC
`vpc-0530…`/SG `sg-00717…`/role `crm-transform-lambda-role`/secret `crm-app-masterdb-proxy`,
`AWS_PROFILE=mfa`), connecting as `crm_app` (owner-DELETE post-`x1`, FORCE-RLS `_org` policy
permits). Per cc-3307: counts only, never row bodies.

- Read-only pre-check: `pre_count = 192` ✓ (gate was: abort if ≠ 192)
- Phase A delete (`dedup_key <> 'qpmsg-110603'`): **191 deleted, post_count = 1** ✓
- Retained row still contact-attached: `contact_id = 692cf941-ca83-4417-81ed-174748e0197d`
- Runner + `/tmp/cc3307` scratch **deleted immediately after** (no standing DELETE path;
  recreating it for Phase B is a 2-minute zip+create from the documented recipe).

## Joint eyeball — data half done, pixel half handed to Leo

Posted through the REAL write path (`crm-write-api` direct invoke, genuine
`sso-authorizer-v1` shape: JSON-encoded `user` string + the constant `cognitoSub` ignored):

- Comment (`is_internal:false`): `76d22c41-23dc-46c4-aaf7-041569ba0487` → 201
- Work note (`is_internal:true`): `64a09225-6a85-482c-a5b3-316e6c69e0aa` → 201

Verified via `get-crm-timeline-api-v1` (the exact Lambda Sell reads) for the retained
contact's phone: **3 activities, all render** — `qpmsg-110603` (`source=qp`), Comment
(`manual`/false), Work note (`manual`/true); contact id matches; `lead: null` (leads pipeline
still unbuilt, expected). Leo's remaining half = Sell pixel check on qp-stage.
⚠️ **Cleanup owed:** the two `cc-3307 joint eyeball` notes are `source='manual'` → Phase B
will NOT remove them. Delete by id after Leo's sign-off (ids above; targeted
`DELETE … WHERE id = ANY(…)` as crm_app, cc-3305 pattern).

## The blocker, precisely

`export_qp_notes_prod.sql`: searched FS+Spotlight, both Obsidian vaults, gunner-brain
git (all branches/authors), GunnerRoofing org code+commit search, `s3://dev-gg/crm-backfill/`
(only `qp-notes-stage.jsonl`), Google Drive/OneDrive/Sync, `/tmp` — **not Tyler-reachable; it
is Leo's local file.** Independently, prod QP DB access doesn't exist from this seat: profiles
here = `default`/`mfa` (both dev acct 980921733684); QP prod acct is separate and still
"pending" per [[leo/apps/quote-portal]]; the dev cluster's `prod_oct17` is a stale snapshot,
NOT live `gg.message`. Dev-acct SSM `DB_CONNECTION_STRING` → `dev-gunner-aurorapgdb` /
`prod_oct17` (so the cc-3306 "stage" export actually read the dev-restored snapshot — noted
for the record).

**Sequence state:** Phase A ✅ → eyeball (Leo pixel check) ⏳ → prod export (Leo) ⏳ →
Phase B (purge to 0, recreate runner) ⏸ gated → dry-run (resolve-rate gate: must be ≫12.5%)
⏸ → real load ⏸ → go ⏸. Correspondence:
`correspondence/for-leo-cc3307-phaseA-done-need-prod-export-2026-07-02.md`; my
reconstruction of his SELECT (diff aid, 3 joins marked TO-VERIFY):
`reference/export_qp_notes_prod-reference.sql`.

## Side fix

`crm-transform` local main was **2 commits ahead of origin** (`bcc5ec2` cc-3305, `49bf8b0`
cc-3306 — deployed 2026-07-01 but never pushed = deployed≠git incident class). Pushed;
`main...origin/main` clean now.

## Reusable facts

- **Purge-runner recipe:** `cp crm-transform.zip runner.zip && zip runner.zip <handler>.py`,
  create-function w/ crm-transform's VPC/SG/role/env (`CRM_DB_HOST=gunnerteam-dev-masterdb-proxy…`,
  `CRM_DB_NAME=gunner_masterdb`, `CRM_DB_SECRET_ID=crm-app-masterdb-proxy`), handler imports
  `lambda_function._connect`. pg8000.native autocommits per statement.
- **`crm_app` can owner-DELETE `crm_activities`** org-scoped rows (post-`x1` ownership +
  FORCE-RLS `FOR ALL` `_org` policy) — no grant, no master exception. Verified live tonight.
- **cc-3306's stage export source was the DEV-restored `prod_oct17`** (dev acct SSM), not the
  stage-acct cluster. Same snapshot lineage, different cluster than the wiki implies.
