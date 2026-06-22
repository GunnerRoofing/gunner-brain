---
type: session
title: session-2026-06-20-cc2128-isolation-test-suite
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - backend
  - security
  - soc2
  - tenant-isolation
  - testing
  - ci
status: stable
related:
  - '[[meta/session-2026-06-20-cc2127-drop-customer-photos-rls]]'
  - '[[gunnerteam/attack-surface-reduction-cc2123-2126]]'
  - '[[gunnerteam/soc2-technical-summary]]'
---

# Session cc-prompt-2128 — Cross-tenant isolation test suite + CI postgres job (CC6.1)

Isolation rests on app-layer `org_id` filtering with no DB backstop (until the superuser demotion).
This suite seeds TWO orgs and proves org A's context can never read org B's rows — the audit evidence
for the multi-tenant control and its regression net. **Test/CI only, NO deploy** (Lambda stays v342).
Commit `2b83d60`.

## What the suite asserts (`test/isolation.test.js`, node:test)
Data-driven over `gt_time_entries`, `gt_customer_photos`, `gt_points_ledger`, `gt_location_history`,
`gt_vehicle_inspections` (add a table to the list → it's covered):
1. **Query layer** — `queryWithTenant(orgA, 'SELECT … WHERE org_id=$1', [orgA])` returns only A's
   row, never B's (+ mirror for B; + every returned row's `org_id` === caller).
2. **Negative control** — an UNSCOPED `query('SELECT org_id FROM gt_time_entries')` returns BOTH orgs,
   proving the suite can detect a leak.
3. **Handler layer (cc-2126 preflight)** — the final `POST /time/checkin` handler is pulled off the
   Express router and invoked with a STUBBED req (`req.orgId`/`req.user` set directly — no Cognito).
   Field Portal is stubbed via a local http server. Valid job → 200 + an A-scoped entry `queryWithTenant(B)`
   cannot see; unknown/other-org job → 404 `job_not_found`, nothing written (fail-closed).

## Safety guard (the most important line)
`test/helpers/isolationDb.js` `assertTestDb()` REFUSES to run unless `TEST_DB=1` AND `DB_HOST` is
localhost/127.0.0.1, and explicitly rejects any `.proxy-` endpoint — never the masterdb/RDS Proxy.
Every destructive helper calls it. Bootstrap: `DROP SCHEMA public CASCADE` → minimal stubs for
masterdb-owned base tables (`organizations`/`users`/`user_organizations`/`gt_vehicle_inspections`/
`audit_log`) → apply the REAL production migrations → seed two orgs.

## Key structural change — migrations module
Extracted the `migrations` object out of `lambda.js` into **`src/migrations.js`** (verbatim, via a
one-shot codemod). `lambda.js` now `require('./migrations')`; the on-demand `_migration` runner is
unchanged. This lets the test apply the EXACT production schema (33 keys) — "schema == prod". The
migrations assume masterdb-owned base tables exist, so the bootstrap stubs them first and skips
index/alter statements on un-stubbed masterdb tables (Postgres 42P01/42703), logging which keys.

## Test-only enablers (gated, inert in prod)
- `db.js`: under `TEST_DB=1`, disables TLS and reads `DB_PASSWORD` from env (prod env has no
  `DB_PASSWORD` after cc-2124 → always falls through to SSM). Added `end()` for clean pool shutdown so
  `node --test` exits.
- `secrets.js`: `__setTestCache` (refuses unless `TEST_DB=1`) seeds the cache so `ccFetch`'s
  `getSecretSync('FIELD_PORTAL_API_KEY')` works in the handler-layer test.

## CI + verification
New CI `isolation` job (postgres:16 service container) runs `npm run test:isolation`; the `backend`
job (no `TEST_DB`) skips the suite cleanly (`npm test` → exit 0). Verified locally against a throwaway
`postgresql@16` on :5433 → **14/14 pass**. Phase 3 leak check: dropped a `WHERE org_id` filter → 5
query-layer tests went red, then restored → green.

## Flagged (PRE-EXISTING, not introduced here)
`@aws-sdk/client-dynamodb` is required by `idempotency.js` + `rateLimitStore.js` but is NOT in
`package.json` — it resolves from the Lambda runtime SDK in prod, but a local `require` of those two
modules fails (surfaced only when smoke-loading `lambda.js` locally; CI/tests don't load them). Worth
adding to `package.json` (or to a devDependency) for local fidelity — separate task.

## Next
When Colin's superuser demotion + RLS decision lands, extend this same suite to assert the DB-level
backstop: a query with the wrong/no org context returns empty under RLS.
