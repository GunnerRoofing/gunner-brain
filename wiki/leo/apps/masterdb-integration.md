---
type: reference
owner: leo
created: 2026-06-19
updated: 2026-06-19
tags: [masterdb, gunner-ops, integration, rls, auth]
status: active
related: ["[[leo/apps/gunner-ops]]", "[[gunnerteam/masterdb-architecture]]"]
---

# masterdb Integration (gunner-ops view)

The **ops ↔ masterdb contract** from the gunner-ops side. masterdb itself — its full architecture, schema, route reference, migration chain, and ADRs — is documented canonically by Tyler. This page is **only** the integration surface: how gunner-ops authenticates against masterdb, how it stays inside RLS, what conventions its `ops_*` tables must match, and the prod facts ops depends on.

> If you want the masterdb internals, go to the canonical pages (see [Canonical references](#canonical-references)). Do not duplicate them here.

---

## B-lite auth model (ops delegates login)

gunner-ops has **no local users table** and **never issues tokens**. masterdb owns login; ops only validates.

- **Login:** the ops frontend POSTs credentials to masterdb `POST /v1/auth/login` with body `{email, password, org_slug}` and gets back a JWT. masterdb CORS must allowlist the ops frontend origin.
- **Token:** HS256, signed with the shared `JWT_SECRET`. Payload = `{sub: user_id, org_id, exp}` — **no role in the token**. Expiry 480 min.
- **Validation:** ops validates the JWT and extracts `{sub, org_id}`. It does **not** mint tokens, store passwords, or keep a users table.
- **RBAC** is resolved per-request from `master.user_app_roles ⋈ app_roles`, scoped to the ops app. Admin = the ops admin `app_role.slug` containing `"admin"` (substring match — Company Admin).

### Frontend config
- `VITE_AUTH_URL` → masterdb auth base (the prod API below in non-local envs).
- `VITE_ORG_SLUG` → default org slug `"gunner"`.
- After login, the ops backend exposes `GET /api/auth/me` which the frontend uses to resolve the current user/org from the validated token.

> Everything masterdb-facing is **configuration, not hardcoded** (`VITE_AUTH_URL`, `DATABASE_URL`, `JWT_SECRET`) — this is what keeps ops independently sellable (shared masterdb in the full suite vs. a bundled lite-masterdb standalone).

Why B-lite: one credential handler, and structurally identical to the future Cognito end-state (central issuer, apps validate). See [[gunnerteam/masterdb-architecture]] for the Cognito target.

---

## RLS contract (every org-scoped query sets the org)

Core tables enforce Postgres **row-level security** keyed on the session variable `app.current_org_id`. ops must honor this or reads silently return nothing.

- **ops connects as the non-superuser `ops_app` Postgres role** — a role that is *subject* to RLS (not a superuser, which would bypass it). `ops_app` is created + granted in prod.
- Org isolation is applied per-transaction:

  ```python
  db.execute(text("SET LOCAL app.current_org_id = :org_id"), {"org_id": org_id})
  ```

- `SET LOCAL` auto-resets on COMMIT / ROLLBACK, which is safe with RDS-Proxy connection reuse — but is also the source of the gotcha below.

### ⚠ Mid-request-commit gotcha
A commit **inside** a request resets `SET LOCAL app.current_org_id`. Any RLS-dependent query *after* that commit runs with no org context and is blocked / returns 0 rows. Re-apply the org context after each commit — wire a SQLAlchemy **`after_begin` event listener** that re-issues `SET LOCAL app.current_org_id` whenever a new transaction begins, so the org context survives mid-request commits.

---

## `ops_*` table conventions (inside masterdb)

ops domain tables live alongside the core masterdb tables and **must match masterdb's conventions** so they behave under the same RLS / ORM stack:

- **String-UUID PKs** via `new_uuid()` + `TimestampMixin` (from masterdb `db/models/base.py`) — not native PG `UUID`, not Int.
- **`org_id` on every ops table** (indexed FK), so RLS applies.
- **`Numeric` money** columns (match `db/models/financials.py`) — never Float.
- Shared-entity references point at masterdb core tables: `crew_id UUID FK → master.crews.id`, `pm_id` / contact refs → `master.contacts` (contacts are global / shared edits, not ops-local copies).
- ops runs its **own separate `ops_alembic_version` table** — its migration history is tracked independently of masterdb's `alembic_version`, even though both live in the same database.

> In current prod everything is still in a single `public` schema; the documented `master` / `ops` schema separation is aspirational, not yet implemented. Build to the contract, not to a dedicated `ops` schema yet.

---

## Production facts ops depends on

| Resource | Value |
|----------|-------|
| masterdb prod API | `https://3rf6zulfok.execute-api.us-east-2.amazonaws.com` |
| Admin UI | `https://d3ufpy24e0ac4l.cloudfront.net` (Orgs, Users, Contacts, Projects, Audit Logs) |
| SST stage | `production` (stack `gunner-masterdb`) |
| DB | Aurora Serverless v2 Postgres 17, 2 ACU min |
| Migration head | `j10` |
| ops DB role | `ops_app` (non-superuser, RLS-subject) — provisioned in prod |
| Service keys | `colincam` + `gunnerteam` provisioned in prod |
| Default org slug | `gunner` |

These are the values ops points its `VITE_AUTH_URL` / `DATABASE_URL` config at in production. Account IDs and these public endpoints are safe to record here.

---

## Running masterdb DDL from ops (migration Lambda path)

When ops needs masterdb DDL run (e.g. registering the ops app + roles, adding `org_id` to shared refs), masterdb's Aurora sits in a private subnet — you cannot hit it directly. The **`db/migrate.py` Lambda handler is the migration path**:

1. **Swap handler:** `aws lambda update-function-configuration --handler db/migrate.handler`
2. **Invoke** with `{action: current | upgrade | grant_masterdb_admin}` (use `current` to read head, `upgrade` to apply).
3. **Restore** the API handler: set it back to `api/main.handler`.

Deploy itself is a manual bundle swap (download via `get-function` `Code.Location`, rsync `api/` + `db/` into `gunner_masterdb/`, rezip, `update-function-code`) — SST `run()` is empty, there is no IaC deploy path. Always run migrations through the Lambda, never directly against the DB. Full deploy detail lives in [[gunnerteam/masterdb-developer-handoff]].

---

## Open items (ops-relevant)

- **`ops_app` DB password + `JWT_SECRET` are still plaintext in the Lambda env** in prod — TODO: move both to AWS Secrets Manager.
  > ⚠ CRITICAL: credential present — not copied
- Mid-request-commit RLS reset — confirm the `after_begin` listener is wired before any RLS-dependent **write** path in ops, not just reads.
- Schema separation (`ops` schema vs. single `public`) — deferred; ops currently shares `public`.
- Stripe / billing boundary in ops is built conservative-local (collect-on-invoice + sig-verified webhook) behind an adapter, pending a decision on whether billing moves to the masterdb foundation. See [[shared/vendors/stripe]].

---

## Canonical references

Do not duplicate these — link to them:

- [[gunnerteam/masterdb-architecture]] — strategic architecture, multi-tenancy model, Cognito target, schema naming.
- [[gunnerteam/masterdb-developer-handoff]] — live resources, full schema (13 tables), route reference, migration chain, deploy + migration-Lambda process, service clients, tech debt, ADRs.
- [[leo/apps/gunner-ops]] — the gunner-ops app itself (sibling page).
- [[shared/vendors/stripe]] — Stripe vendor reference (ops billing boundary).
