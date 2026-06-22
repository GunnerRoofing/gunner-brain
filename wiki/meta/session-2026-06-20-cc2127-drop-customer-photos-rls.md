---
type: session
title: session-2026-06-20-cc2127-drop-customer-photos-rls
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - backend
  - security
  - soc2
  - tenant-isolation
  - rls
  - migration
  - deploy
status: stable
related:
  - '[[meta/session-2026-06-20-cc2126-time-jobid-preflight]]'
  - '[[gunnerteam/attack-surface-reduction-cc2123-2126]]'
  - '[[gunnerteam/soc2-technical-summary]]'
---

# Session cc-prompt-2127 — Resolve the gt_customer_photos RLS vestige (CC6.1) — v342

`gt_customer_photos` was the ONLY RLS-enabled table (`lambda.js:166`, policy `gt_customer_photos_org`
keyed on `current_setting('app.current_org_id')`). Inert today only because the app connects as DB
**superuser** (bypasses RLS). The instant the role is set `NOSUPERUSER`/`NOBYPASSRLS`, the policy
activates — and since cc-769 dropped the general `SET LOCAL app.current_org_id`, org context can be
unset → reads return **empty**. A half-built control = landmine; resolved before the demotion. Commit
`304013a`, deployed **v342** (rollback v341).

## Decision
We standardized on **app-level `org_id` scoping** (cc-769/1628), so **drop the RLS** to match every
other `gt_*` table rather than wire `SET LOCAL` (which reintroduces RDS-Proxy connection pinning).
Grep confirmed the table's only queries already filter `org_id` explicitly:
- read: `SELECT cc_photo_id FROM gt_customer_photos WHERE org_id=$1 AND job_id=$2`
  (`fieldportal.js` `tagCustomerPhotos`)
- write: `INSERT INTO gt_customer_photos (id, org_id, job_id, ...) VALUES (..., $1=req.orgId, ...)`

Both via `queryWithTenant`. So isolation survives without RLS; disabling RLS only **removes** a
restriction → reads/writes can't break, regardless of role.

## Change
Added the inline migration `20260620_drop_gt_customer_photos_rls` to the `migrations` object in
`lambda.js`:
1. `DROP POLICY IF EXISTS gt_customer_photos_org ON gt_customer_photos`
2. `ALTER TABLE gt_customer_photos DISABLE ROW LEVEL SECURITY`
3. self-verifying `DO $$` guard that RAISEs unless `pg_policies` lacks the policy AND
   `relrowsecurity=false` — the runner returns only per-statement `{ok}` (not SELECT rows), so the
   guard is how the prompt's DB-check becomes observable. All idempotent.

## Migrations model (reusable)
The `migrations` object is invoked **on-demand**: `aws lambda invoke --payload
'{"_migration":"KEY","_secret":"..."}'`. No auto-run on deploy, no tracking table — every statement is
idempotent (`IF EXISTS` / `IF NOT EXISTS` / guarded `DO` blocks). The runner uses the cc-2124 lazy
`pool.connect()`; `_secret` is checked against `getSecretSync('MIGRATION_SECRET')`.

## Deploy + verify
Deployed v342 (rollback v341). Ran the migration → `200`, all three `ok:true` (DROP / DISABLE /
verify-guard). **Guard passing = `pg_policies` no longer lists `gt_customer_photos_org` AND
`relrowsecurity=false`** — the prompt's DB check, satisfied. Idempotent re-run all `ok:true`;
`/health` 200.

Gotcha: the first `--qualifier live` run 404'd "Unknown migration" — **alias-resolution lag** (~2s
after the alias flip, `live` still mapped to v341 which lacks the key). Confirmed the deployed S3
artifact contained the key, ran on `$LATEST` → ok (DB change is version-independent), then `live` after
~45s → ok.

## Result / handoff
GunnerTeam app code is now safe for the DB app-role to be demoted off superuser — no RLS landmine, all
tenant isolation is app-level explicit `org_id` filters. **Colin still owns the actual
`NOSUPERUSER`/`NOBYPASSRLS` flip** in the `gunner-masterdb` SST stack (the real tenant-isolation
backstop, pre-second-tenant gate). See `GunnerTeam-TenantIsolation-Decision-2026-06-20.md`.
