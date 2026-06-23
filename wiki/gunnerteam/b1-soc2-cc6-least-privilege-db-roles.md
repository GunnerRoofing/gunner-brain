---
type: soc2-evidence
title: 'B1 — SOC 2 CC6.1/CC6.3/CC6.6: Least-Privilege DB Roles (masterdb)'
created: '2026-06-22'
updated: '2026-06-22'
status: in-progress
control_owner: Tyler Suffern
tsc:
  - CC6.1
  - CC6.3
  - CC6.6
tags:
  - soc2
  - security
  - masterdb
  - rls
  - b1
  - least-privilege
  - gunnerteam_app
related:
  - '[[gunnerteam/masterdb-developer-handoff]]'
  - '[[tyler/hot]]'
---

# B1 — SOC 2 CC6.1/CC6.3/CC6.6: Least-Privilege DB Roles (masterdb)

**Control owner:** Tyler Suffern · **Date:** 2026-06-22
**Status:** IN PROGRESS — role provisioned on dev; org-context (GUC) and production cutover pending (§5).
**TSC:** CC6.1 (logical access — least privilege) · CC6.3 (role-based access / segregation) · CC6.6 (boundary — RLS tenant isolation)

---

## 1. Control Statement

Each application connecting to the shared masterdb cluster authenticates as a **dedicated database role** holding the minimum privileges required for its function, and **cannot bypass row-level security**. No application connects as the database master/owner role. Tenant isolation is enforced at the database layer (FORCE row-level security keyed on `app.current_org_id`), independent of application code.

---

## 2. Risk Addressed

Before B1, applications connected as the Aurora master role, which carries `BYPASSRLS` — the database-level tenant boundary (FORCE RLS) was not actually enforced for application traffic, and a single credential had unrestricted access to all tenants' data across every app on the shared cluster. B1 retires that shared, over-privileged connection in favor of per-app least-privilege roles that are themselves subject to RLS.

---

## 3. Implementation (GunnerTeam — the template app)

- **Dedicated role** `gunnerteam_app`, created `NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE` (Alembic revision `k11_provision_gunnerteam_app`, commit `176bef5`). Fully subject to FORCE RLS.
- **Least-privilege grants** scoped to exactly the shared identity/auth tables the GunnerTeam backend uses (verified by cc-2142 grant audit — see §4). The application's own `gt_*` tables are owned by the role (full DML via ownership).
- **Tenant scoping at login** via a role-default GUC (`ALTER ROLE … SET app.current_org_id = <gunner org>`), so every query is org-scoped without per-request configuration and without RDS Proxy connection pinning. GunnerTeam is single-org by design — a static role default is correct here. *(GUC step currently blocked — see §5.)*
- **Change control:** role + grants + table ownership are provisioned **in Alembic (in source control)**, not out-of-band — reproducible and auditable. Committed to `main` (`176bef5`), deployed == committed (live reconciled to `main` in the same change, cc-2138).
- **Reversible:** the migration's `downgrade()` cleanly returns table ownership and drops the role; the master role is untouched throughout, so cutover rollback is a credential re-point.

---

## 4. Evidence Artifacts

| Artifact | Location | Notes |
|---|---|---|
| Role + grants migration | `db/migrations/versions/k11_provision_gunnerteam_app.py` | Role, grants, `gt_*` ownership reassign, `users` INSERT policy |
| Missing grant fix | `db/migrations/versions/k12_crew_members_delete_grant.py` | `crew_members` DELETE (found by cc-2142 audit) |
| Least-priv trim | `db/migrations/versions/k13_least_priv_trim.py` | Revoke 4 over-granted tables (post-cutover) |
| Commit | `176bef5` on `origin/main` | Verified in sync 2026-06-22 (cc-2143) |
| Grant audit | cc-2142 (`gunnerteam_app-grant-audit-2026-06-22`) | Backend table-usage matrix vs. granted privileges; one missing + four extra identified and remediated |
| Cutover procedure | `cc-prompt-2137-b1-cutover-gunnerteam-side.md` | GunnerTeam credential swap + canary plan |
| Verification plan | `b1-verification-plan-2026-06-22.md` | Role attributes, ownership counts, cross-tenant 0-row probe, pinning metric |
| Post-cutover RLS proof | *(to capture at cutover)* | Wrong-org context → 0 rows on a FORCE-RLS table; `gunnerteam_app` reads own-org rows only |

### Grant Matrix (as of k12)

| Table | Grants | Source |
|---|---|---|
| `users` | SELECT, INSERT, UPDATE, DELETE | k11 |
| `user_organizations` | SELECT, INSERT, UPDATE, DELETE | k11 |
| `user_app_roles` | SELECT, INSERT, UPDATE, DELETE | k11 |
| `user_devices` | SELECT, INSERT, UPDATE, DELETE | k11 |
| `invite_tokens` | SELECT, INSERT, UPDATE, DELETE | k11 |
| `reset_tokens` | SELECT, INSERT, UPDATE, DELETE | k11 |
| `audit_log` | INSERT | k11 |
| `service_clients` | SELECT | k11 |
| `organizations` | SELECT | k11 |
| `apps` | SELECT | k11 |
| `app_roles` | SELECT | k11 |
| `contacts` | SELECT, INSERT, UPDATE, DELETE | k11 — ⚠️ unused; revoked in k13 |
| `services` | SELECT | k11 — ⚠️ unused; revoked in k13 |
| `organization_services` | SELECT | k11 — ⚠️ unused; revoked in k13 |
| `crew_members` | DELETE | k12 — added after cc-2142 audit |
| `gt_*` (17 tables) | Full DML via ownership | k11 — `ALTER TABLE … OWNER TO gunnerteam_app` |

---

## 5. Current Status & Residual Items

- ✅ `gunnerteam_app` provisioned on dev; 17 `gt_*` tables reassigned; `users` INSERT policy in place.
- ✅ `crew_members` DELETE grant added (k12, cc-2142 fix).
- ⏳ **Role-default GUC not yet active** — Aurora PG 17 blocks `ALTER ROLE … SET` of the unregistered `app.*` GUC. Requires Colin to add `app` to `custom_variable_classes` in the Aurora parameter group + cluster reboot. Until then, cutover does not proceed (documented blocker, not a silent gap). Invoke `provision_gunnerteam_app_guc` migrate-Lambda action after the reboot.
- ⏳ **k12 not yet applied to dev** — MFA session expired during cc-2142 deploy. Apply before the cutover window.
- ⏳ **k13 (least-priv trim)** not yet applied — planned post-cutover after a fresh scan confirms no new backend usage.
- ⏳ **Production cutover pending** a coordinated window; control is implemented on dev only.

---

## 6. Known Exception

`crew_members` is **not** under FORCE RLS (absent from all RLS migrations). It is an exception to the "every table is tenant-isolated at the DB layer" assertion — currently mitigated only by application-level `user_id` scoping. Tracked for remediation on the masterdb roadmap (RLS-completeness); coordinate with all apps on the shared cluster before adding.

---

## 7. Rollout to Remaining Apps

| App | Role | Connection | Org context | Status |
|---|---|---|---|---|
| GunnerTeam | `gunnerteam_app` | RDS Proxy | Role-default GUC (single-org) | In progress (this doc) |
| gunner-ops | `ops_app` | Direct (confirmed cc-2144) | Per-request `SET LOCAL` (multi-tenant-ready) | Planned cc-2141 |
| WL-CompanyCam | `wl_companycam_app` | RDS Proxy | TBD | Planned |
| QP | `qp_app` | TBD | TBD | On hold per app owner |

Same pattern per app: dedicated `NOSUPERUSER NOBYPASSRLS` role, provisioned in Alembic, org context by the mechanism appropriate to its connection path and tenancy.
