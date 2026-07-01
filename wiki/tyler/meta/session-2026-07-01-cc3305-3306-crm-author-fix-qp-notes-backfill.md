---
type: session
title: "Session 2026-07-01: crm-write-api author resolution fix + QP notes backfill loader"
created: 2026-07-01
updated: 2026-07-01
tags:
  - session
  - crm
  - masterdb
  - lambda
  - backfill
status: stable
related:
  - "[[tyler/meta/session-2026-07-01-cc2925-3304-masterdb-crm-write-api-migrate-pipeline]]"
  - "[[tyler/meta/session-2026-07-01-cc3300-cc20-crm-internal-flag-dialpad-transcript-clean]]"
  - "[[tyler/masterdb/masterdb-developer-handoff]]"
---

# Session 2026-07-01: crm-write-api author fix (cc-3305) + QP notes backfill loader (cc-3306)

Two chained prompts on `crm-transform`, both closing gaps ahead of the CRM cutover: the
manual-note author-attribution bug (every note landed `handled_by_agent_id = NULL`), and the
one-time loader that carries QP rep notes (`gg.message`) into `crm_activities`.

---

## cc-3305 — crm-write-api author resolution (authorizer shape)

**Bug:** `_principal()` read top-level authorizer keys (`cognito_sub`/`sub`/`principalId`/`email`)
that `sso-authorizer-v1` never injects. The authorizer puts exactly two keys in
`requestContext.authorizer`:

- `user` — a **JSON-encoded string** (`json.loads` required) carrying `email`, `user_id`,
  `cognito_sub`, etc.
- `cognitoSub` — a **hardcoded constant** (`31db25e0-…`), identical for every user. **Trap:
  never attribute from it.** It looks like a per-user Cognito sub and is not.

Result: `_principal` always returned `None` → every manual note wrote
`handled_by_agent_id = NULL`. No 4xx (graceful degradation by design), so it failed silently.

**Fix** (`write_api.py`, commit `bcc5ec2`): dropped `_PRINCIPAL_KEYS`; `_principal` now
`json.loads(authorizer.user)` and returns `email or user_id` (email preferred — the
`dialpad_email` join is safer while the `gt_user_id` true-up is pending). `_resolve_agent`
unchanged: its `WHERE gt_user_id = :p OR lower(dialpad_email) = lower(:p)` already matches
either. Still never raises; unresolved → None.

**Verified live** (real authorizer shape, constant `cognitoSub` included):
- Seeded agent email → 201, DB row `handled_by_agent_id` = that agent's `dp_agents.id` ✓
- Bogus email → 201, `handled_by_agent_id` NULL ✓ (graceful, no 4xx)
- Test notes deleted afterward (targeted `DELETE … WHERE id = ANY(…) AND body LIKE 'cc-3305%'`).

**Deploy gotcha found:** `deploy-write.sh`'s `get-function … 2>/dev/null` swallows auth errors
and falls through to `create-function`. Under a non-MFA session the deploy failed with a
confusing `lambda:CreateFunction` explicit deny (`GunnerRequireMFA`) instead of the real cause
(no MFA session). Would also clobber env vars if the create ever succeeded. Flagged, not fixed
(out of scope). Rule: **deploy `crm-transform`/`crm-write-api` with `AWS_PROFILE=mfa`**.

---

## cc-3306 — `backfill_qp_notes` mode (gg.message → crm_activities)

One-time loader for Leo's QP rep-notes export, new mode on the `crm-transform` batch Lambda
(commit `49bf8b0`):

```
{"mode":"backfill_qp_notes","s3_key":"crm-backfill/qp-notes-stage.jsonl","dry_run":true}
```

(Repo convention is `mode`, not the prompt's `action` — the handler dispatches on
`event.get("mode")`.)

**Mapping:** `dedup_key='qpmsg-'||id`, `body=msg_text`, `occurred_at=msg_ts`, `type='note'`,
`source='qp'`, `is_internal=true`, `direction=NULL`, agent NULL (author backfill = v1 deferred).
`contact_phone` (E.164) → `_to_e164` → `_phone_to_contact` map; unmatched/missing phone loads
**unattached** (`contact_id NULL`), never dropped. `media_url`/`file_id`/`priority` skipped
(no columns; attachments fast-follow). `ON CONFLICT (org_id, dedup_key) DO NOTHING` = idempotent.
Per-row try/except; failures log `dedup` only, never `msg_text` (PII).

**IAM:** `s3:GetObject` on `arn:aws:s3:::dev-gg/crm-backfill/*` — added to the live role AND to
`deploy.sh`, because **`deploy.sh` re-puts `crm-transform-perms` wholesale on every deploy**; a
grant added only live gets silently stripped on the next deploy.

**Stage export had to be generated** (no export existed in S3 or locally). Done via a throwaway
in-VPC Node lambda (portal VPC `vpc-04f8`, shared layer `lambda-layer-v3`'s `dbClient`, SSM
`DB_CONNECTION_STRING`) running the export SELECT against the stage gg DB (`prod_oct17` snapshot).
Key schema finding: **`gunner_global.customer_contact` is EMPTY in stage** — customer phones come
from `gunner_global.hubspot_deals_data.phone` via `project.hubspot_deal_id`, E.164-normalized in
SQL. Export: 192 rows / 35 projects / 160 with a phone → `s3://dev-gg/crm-backfill/qp-notes-stage.jsonl`
(matches Leo's ~190/34 estimate).

**Verification (stage):**
- Dry-run: `source_rows 192, contact_resolved 24, parked 168, would_insert 192, failed 0`
- Real load: `inserted 192`; DB: **24 attached / 168 parked** (matches loader stats exactly)
- Re-run: `inserted 0, already_present 192` — idempotent ✓
- Timeline render: an attached note's contact phone through `get-crm-timeline-api-v1` returns the
  qp note (`type=note, source=qp, is_internal=true`) via the `contact_id` match — Leo's read
  surfaces contact-level notes. Joint eyeball with Leo on the Sell UI = remaining human step.
- Resolvable rate is **12.5%** (24/192), not Leo's ~30% guess — 160 rows carry a phone but only
  24 match a `crm_contacts.phone` (stage junk phones, e.g. nonexistent area codes). Loader parks
  them unattached as designed; prod should resolve much higher.

**Prod cutover sequence (NOT this session):** prod `gg.message` export (Leo one-session read or
hands over the dump) → prod dry-run → real load → verify → Leo flips `NEXT_PUBLIC_CRM_WRITE`.

---

## Reusable facts (promote if referenced again)

- **`sso-authorizer-v1` contract:** `requestContext.authorizer.user` = JSON-encoded string
  (parse it); `authorizer.cognitoSub` = hardcoded constant, same for every user — never use it
  for identity. Any lambda behind this authorizer reading author identity must
  `json.loads(authorizer.user)`.
- **`crm-transform`'s `deploy.sh` owns the role policy.** It re-puts `crm-transform-perms` on
  every run — IAM changes for this role MUST be made in the script, or they evaporate on the
  next deploy.
- **Stage gg DB (`prod_oct17`): `customer_contact` is empty.** Project→phone resolution goes
  `project.hubspot_deal_id → hubspot_deals_data.phone`.
- **In-VPC query pattern (portal side):** throwaway Node lambda + `lambda-layer-v3` layer
  (`/opt/nodejs/utils/dbClient.mjs`, SSM `DB_CONNECTION_STRING`) + portal SG/subnets/role =
  arbitrary read-only SQL against the gg DB. Masterdb side: same pattern in Python off the
  crm-transform zip/role/VPC (`cc3305-verify-tmp` / cc-2913 precedent). Both deleted after use.
- **The masterdb proxy SG admits only the three lambda SGs** — no bastion (`db-tunnel` is in the
  wrong VPC, `gunner-adops-mcp` SG not admitted). SELECT verification against masterdb requires
  an in-VPC lambda on `sg-00717b28af48812dd`.

## Version / commit ledger

- `crm-transform`: `bcc5ec2` (cc-3305 `_principal` fix), `49bf8b0` (cc-3306 loader + deploy.sh
  IAM). Both deployed (`crm-write-api`, `crm-transform` — `AWS_PROFILE=mfa`).
- Stage data: 192 qp notes live in `crm_activities` (24 attached / 168 parked),
  export at `s3://dev-gg/crm-backfill/qp-notes-stage.jsonl`.
- Temp lambdas `cc3305-verify-tmp`, `cc3306-query-tmp`, `cc3306-verify-tmp` created and deleted.
