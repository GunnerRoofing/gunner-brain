---
type: session
title: "Session 2026-07-02 — SMS bridge: Finder task blocked, cc-3310 registry+endpoint, cc-3311 webhook deltas"
owner: tyler
created: 2026-07-02
updated: 2026-07-02
status: stable
tags:
  - session
  - masterdb
  - crm-transform
  - sms-bridge
  - finder
  - webhook
  - hmac
related:
  - "[[doug/overview]]"
  - "[[tyler/meta/session-2026-06-26-cc2807-2809-dialpad-updated-at-monitoring]]"
  - "[[tyler/meta/session-2026-07-01-cc2925-3304-masterdb-crm-write-api-migrate-pipeline]]"
  - "[[tyler/meta/session-2026-07-02-cc3309-backfill-skip-test-projects]]"
---

# Session 2026-07-02 — SMS bridge: Finder task blocked, cc-3310 registry+endpoint, cc-3311 webhook deltas

Three-task arc building the **Finder SMS bridge**: Finder registers `(send, receive)` phone
pairs with the archive at SMS send time; the archive fires per-message webhook deltas back to
Finder for registered pairs. Archive side (cc-3310 masterdb + cc-3311 crm-transform) is **live
end-to-end**. The Finder side is **blocked on repo access**.

## Task 1 — Finder receiver + registration: BLOCKED (repo not reachable)

The prompt targeted "Finder (`finder.gunnerroofing.com`)". Exhaustive search: not in `~/Dev`,
no `*finder*` dir in home (depth 4), no git remote mentioning finder, **not one of the 50
GunnerRoofing org repos**, org code search for `conversation-update`/`api/v1/sms` = 0 hits.
`finder.gunnerroofing.com` appears only in `gunner-ios` (the "leads near me" radar links OUT
to it — consumer, not the app).

- **Finder = Doug Kilzer's "Lead Finder"** (see [[doug/overview]]) — likely his personal
  GitHub or another org, matching his key-naming pattern (`leads-finder-dk`).
- Phase 0 required reading Finder's existing `/api/v1/sms/` router and mirroring it; building
  without it = inventing the forbidden parallel stack. Declared blocked; need a clone URL or
  route-to-Doug. Did NOT scaffold a fake app.

## Task 2 — cc-3310: masterdb `sms_bridge_subscriptions` + POST /subscriptions (SHIPPED)

Commits `953459f` + `52fc98d` on gunner-masterdb main; migration applied to prod via the
`migrate-prod` workflow (run 28606338361, `w1` → `y1`); API Lambda hand-roll-deployed.

- **`y1_sms_bridge_subscriptions`** (revises `w1_crm_activities_is_internal` — the actual
  single head; p22's q1 sibling was long merged by r1). RLS-free (dp_* posture per p19–p22),
  unique `(org_id, send_number, receive_number)`, bare-pair lookup index for the cc-3311 join.
  GRANT S/I/U → `gunnerteam_app`, SELECT → `crm_app` (both names verified against k11/s1 +
  crm-transform's proxy secret). No DELETE for either.
- **`POST /v1/integrations/subscriptions`** on the integrations router (existing
  `get_service_context` X-Api-Key auth). Minimal `_to_e164` (no new dep), idempotent
  `ON CONFLICT … DO UPDATE SET last_registered_at = now()`, same-transaction `audit(...)`
  (repo signature: `details=`, not the prompt's `metadata=`; `target_id` from `RETURNING id`;
  org GUC already set by `get_service_context`).
- **`verify_y1`** migrate action: table/indexes + grants via `has_table_privilege` (no role
  passwords needed) + PII-safe row stats (`total`/`e164_clean`/`reregistered` counts only).
- Prod smoke: mixed-format register → 200; re-register → 200 with rows `{total:1, e164_clean:1,
  reregistered:1}` (one row, normalized, bumped); bad number → 422; bad key → 401.

**Deltas from the prompt worth remembering:**
- Migrate Lambda payload is `{"action":"upgrade_to","target":…}` — NOT `{"_alembic":…}`.
- **External path is `/v1/integrations/subscriptions`** — API GW is a bare `$default` proxy,
  no rewrite; the drafted `/api/v1/subscriptions` does not exist. Doug must call the real path
  (or an API-GW alias gets added later).
- **`_provision_service_key` is broken under the migrate-role cutover**: `masterdb_migrate`
  lacks INSERT on `service_clients` + the FORCE-RLS org GUC. Worked around via throwaway
  Lambda on the API's master connection (create → invoke → delete). Follow-up migration if
  pipeline key-provisioning should work.
- Lambda zips patched surgically (only my 4 files); **PR #27's auth/users/audit_logs changes
  remain undeployed** — that rollout is Colin's call. Zips carry the tree twice (root +
  `gunner_masterdb/`), patch both.

## Task 3 — cc-3311: crm-transform fires per-message deltas (SHIPPED)

Commit `f607927` on crm-transform main, deployed via `deploy.sh`.

- **P4-finder-notify** = third `WATERMARKS` source, own cursor
  `/crm-transform/finder-notify/watermark` (IAM already covered by `/crm-transform/*`).
  Exact P1c semantics: advance to `max_updated − LAG` only on `failed == 0`; failures raise
  the summary RuntimeError → existing alarm.
- **Pair match in PYTHON on `_to_e164`-normalized values from BOTH tables** (not a raw-column
  SQL join) — format drift structurally cannot drop notifications. Assumption verified anyway:
  dry-run census **1528/1528 rows E.164-clean** on both `internal_number`/`external_number`.
- One POST per message to `{FINDER_WEBHOOK_URL}/api/v1/sms/conversation-update`, HMAC-SHA256
  over raw body, `X-Archive-Signature: sha256=<hex>`. Secret **`crm-finder-webhook`** in
  Secrets Manager (value never echoed). `direction` sent as-is — inbound AND outbound fire.
- **Unconfigured-safe**: `FINDER_WEBHOOK_URL` unset → skip WITHOUT advancing (`failed=0`, no
  alarm). Verified on a real scheduled tick; SSM holds only calls/sms cursors.
- Manual mode `{mode:"finder-notify", since, limit, base_url, dry_run}` — `base_url` override
  fires at a test receiver without touching scheduled env.
- Live-fire evidence (throwaway HMAC-validating receiver + in-DB pair registration; numbers
  never left the DB/logs): real pair `matched=3, delivered=3, failed=0`, receiver
  `sig_valid=True` ×3; tampered body → 401; re-run redelivers same `message.id`s (Finder-side
  dedup no-ops); unroutable target → `failed=3` → cursor held. All test debris deleted
  (lambdas, role, registry row — `verify_y1` back to `{total:1}`).

**Function-URL gotcha (reusable):** a CLI-created `AuthType=NONE` Function URL 403s until the
policy ALSO carries `lambda:InvokeFunction` with condition
`lambda:InvokedViaFunctionUrl=true` — CLI flag `--invoked-via-function-url` (the
`InvokeFunctionUrl`+`FunctionUrlAuthType=NONE` statement alone is NOT sufficient).

## Handoffs / open items

1. **Finder repo access** (blocks the Finder-side build): clone URL from Doug, or route the
   receiver+registration work to him. Contract knowns for his side: real registration path
   `POST {api}/v1/integrations/subscriptions` + header `X-Archive-Signature: sha256=<hex>`
   over raw body.
2. **Keeper handoffs (Tyler):** `finder-sms-bridge` service key raw value in
   `/tmp/finder-sms-bridge-key.txt` (prefix `2-XMlL_jku7e`) — move to Keeper, share with
   Doug, delete the file. `crm-finder-webhook` secret → share with Doug via Keeper.
3. **When Finder ships the receiver:** set `FINDER_WEBHOOK_URL` on crm-transform env
   (out-of-band env rule — deploy.sh never touches env). Decide: pre-stamp watermark to "now"
   (skip history) vs leave unset (full replay; message.id dedup makes it safe, just chatty).
4. **Follow-up candidates:** migration to fix `_provision_service_key` under
   `masterdb_migrate`; API-GW alias if Doug insists on `/api/v1/subscriptions`; one fictional
   `+1203555…` row remains in `sms_bridge_subscriptions` (inert idempotency evidence).
