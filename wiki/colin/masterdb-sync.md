---
type: reference
owner: colin
app: GunnerCam
created: 2026-06-21
updated: 2026-06-21
tags: [wl-companycam, masterdb, integration]
status: active
---

# gunner-masterdb Shared-Core Sync

`gunner-masterdb` is the **canonical source of truth** for identity, tenancy, RBAC, audit logs, and core shared records (organizations, users, contacts, projects, crews, services) across every Gunner white-label app. GunnerCam (WL-CompanyCam, app slug `COLIN`) links to it over an **HTTP sync/linking layer** — it is **not** migrated onto the shared cluster as of 2026-06-21.

Leonard Fuentes owns masterdb and is the gatekeeper for secrets, API keys, app registration, and admin roles. See [[colin/people-and-context]] for the ecosystem map.

## Ownership model

- **Master-primary propagation, not multi-master.** masterdb owns all identity/org/auth/role records; downstream apps mirror by reference. Two independently-writable copies of the same record are prohibited.
- **Master schema owns** these core tables: `organizations`, `users`, `user_organizations`, `apps`, `app_roles`, `user_app_roles`, `service_clients`, `user_devices`, `audit_log`, `contacts`, `projects`, `crews`, `services`. Projects live in masterdb as connective tissue across sales → procurement → execution → finance. Raw files/blobs stay in S3; masterdb owns metadata/keys only.
- **App-scoped tables use explicit prefixes**: `gt_*` (GunnerTeam), `leo_*` (LEO/ops), `qp_*` (QP). Apps own workflow extensions via side-car tables keyed on `project_id`.
- **Permissions are app-scoped rows** in `user_app_roles`, never a column on `users` — a user holds different roles per app. 6 apps are registered (QP, LEO, COLIN, GunnerTeam, Crew Portal, Marketing), each with its own role set.
- **Cross-app data access is via the HTTPS REST API, not cross-schema SQL.** masterdb uses String-UUID PKs (`new_uuid` helper) in a single shared `public` schema. The intended end state (`master`/`ops`/`qp`/`colin` schemas on one Aurora cluster, no cross-schema FKs, links via `external_ids`, RLS as defense-in-depth) is future Phase 1/2 work.

## MasterDB API contract

Two base URLs exist — pointing at the wrong one returns `Invalid credentials` on login.

| URL | Status (as of 2026-06-21) | Auth | Dataset |
|---|---|---|---|
| `https://3rf6zulfok.execute-api.us-east-2.amazonaws.com` | **live** | Bearer (`org_slug: gunner`) | Leonard / Tyler / Colin / Glen |
| `https://of4rvaa43c.execute-api.us-east-2.amazonaws.com` | **stale** | X-Api-Key (read-only) | a different 7-user set |

> Earlier sessions (through 2026-05-31) treated `of4rvaa43c` as live — superseded. The cutover to `3rf6zulfok` landed ~2026-06-11.

**Two auth schemes, never mixed on one request:**
- **JWT Bearer** for human users — `POST /v1/auth/login` with `{email, password, org_slug}`. Token payload is `{sub: user_id, org_id, exp}` with **no role claim**; every query is server-side scoped to `auth.org_id` and clients cannot override the org. Login returns a uniform **401** (not 403) for non-members to avoid leaking membership.
- **X-Api-Key** for service clients, covering only `/v1/integrations/{users,contacts,projects,crews}`. Keys are bcrypt-hashed and unrecoverable after issuance; only Leonard provisions/rotates them.

**Endpoint facts (verified against live OpenAPI, supersedes older handoff docs):**
- Full CRUD as of 2026-05-29: `POST/PATCH` on contacts/projects/users, plus `GET` on `/v1/crews`, `/v1/integrations/crews`, `/v1/services`, `/v1/app-roles`, `/v1/invites`, `/v1/me`, `/v1/service-clients`. (Early sessions saw the API as read-only over the wire — superseded.)
- Audit path is `/v1/audit-logs` (**hyphen**), not `/v1/audit_logs`.
- `POST /v1/users` requires an admin role server-side; a regular token returns **403**.
- **No `DELETE` route exists anywhere** — created records (especially users) cannot be undone via the API. This makes dry-run / identity-collision checks a hard safety gate.
- Docs at `/docs` (Swagger), `/redoc`, `/openapi.json`. CORS allowlist is hardcoded in `main.py` (only `localhost:3000`/`5173`), not in API Gateway.

## MasterDB backend internals

Python 3.12 / FastAPI / SQLAlchemy 2.0 / Alembic. API Gateway v2 `$default` catch-all → single Lambda does all routing → Aurora Serverless v2 Postgres. No EC2, queues, or runtime S3.

| Item | Value |
|---|---|
| Lambda (do **not** rename — load-bearing in CFN/SST; note typo "masterd") | `gunner-masterd-dev-MasterApi2RouteBbovcaHandlerFunction-wssoombt` (py3.12, 512 MB, 30 s, handler `api/main.handler`) |
| Aurora dev | `gunner-masterdb-dev-masterdbcluster-kdsmbssw` (Serverless v2 0.5–4 ACU, PG 17.7, db `gunner_masterdb`) |
| Aurora prod | `gunner-masterdb-production-masterdbcluster-sczazkvf` (`vpc-0530f022b0273f215`, private) |
| Second dev cluster | `dev-gunner-aurorapgdb-db-cluster` (purpose undocumented — clarify with Leonard) |

**Security hardening (2026-06-12):** RLS via an `org_session` helper threaded through `auth_utils.py` / `routers/users.py`; the substring-`'admin'` role check (a privilege-escalation bug — would match `"non-admin"`) replaced with exact-match against `ADMIN_ROLE_SLUGS`; login auditing records success **and** failure with `ip_address`. **Password scheme:** legacy pbkdf2 verified alongside bcrypt with lazy rehash to bcrypt on successful login.

**Deploy is a manual zip-swap** (SST `run()` intentionally empty — flagged High tech debt): download live zip → overlay changed `api/` + `db/` modules into the `gunner_masterdb/` prefix (keep Linux-built deps at zip root) → re-zip → `aws lambda update-function-code`. All changed model files must ship in one deploy or imports break. Alembic migrations run via the migration Lambda, never directly against the DB.

## GunnerCam ↔ masterdb sync (the COLIN side)

GunnerCam keeps its own `wl-companycam-dev` Postgres (via the `wl-companycam-dev-proxy` RDS Proxy — see [[colin/aws-infra]]). `src/db/schema.ts` still uses unqualified `pgTable`/`pgEnum` (no `pgSchema('colin')`) as of 2026-06-21.

**Sync is HTTP, not direct DB reads:**

| File | Role |
|---|---|
| `src/lib/masterdb-client.ts` | plain Bearer HTTP client; deliberately **no** `server-only` import so it runs under `tsx` |
| `scripts/sync-from-masterdb.mts` | inbound (masterdb → GunnerCam) |
| `scripts/push-to-masterdb.mts` | outbound (GunnerCam → masterdb) |

Mirror fields (migration `0016`, plus `users.external_ids` in `0035`): `corporations.external_ids` (jsonb) holds `masterdb_org_id` / `masterdb_user_id` / `masterdb_project_id`; project mirror fields (`trade`, `contract_amount`, `balance`, `payment_status`, `last_synced_at`, `sync_source`). See [[colin/data-model]].

> Sync boundary: masterdb owns company identity / customer-contact / financials; GunnerCam owns schedule, field execution, photos, media. Status mapping needs an explicit translation table (GunnerCam's status enum is richer).

**Inbound sync — COMPLETE on dev (2026-06-11/12):** the corp record was repointed from the stale org_id (`69aad261…`) to the live masterdb org_id (`7d6db1bb…`); 4 masterdb users (Leonard, Tyler, Colin, Glen) linked via `masterdb_user_id`. Run with `SYNC_PROVISION_COGNITO=0` (pure additive DB update). prod masterdb held exactly those 4 users.

**Outbound push — BLOCKED on admin role.** `npm run push:masterdb` is a safe dry-run (0 writes); `push:masterdb:apply` is gated on `SYNC_APPLY=1`. Idempotent, email-matched. Final 2026-06-15 dry-run: **32 create / 0 link / 4 already-linked / 10 skip**. Push reads source from the dev WL RDS (`127.0.0.1:5432` SSM tunnel via the dev bastion) and writes to **prod** masterdb — the tunnel must be up first. Two open issues: it runs with `NODE_TLS_REJECT_UNAUTHORIZED=0` (TLS verification disabled — to fix); tsx CommonJS interop needs `ns.default ?? ns` when importing the client.

**Identity collisions** are handled via `SKIP_EMAILS` (the only safety lever, since no `DELETE` exists): Joe Massari canonical = `joe@gunnerroofing.com` (skip the `joe.massari@` dup); Glen Tacinelli canonical = `glen@gunner.com`. Foreign/test accounts (revgravy, qatest, axeautomation) are skipped. New Gunner staff would be created with default password `TestPass123!`.

## Sibling migrations (summary — link out for depth)

- **gunner-ios → masterdb (~90% done, 2026-05-27).** Donor `gunner-ios` (Express/Node `gunnerteam-api/`). `tenants` → `organizations`; `users` merged (bcrypt replaces salt; role → `user_app_roles`); ~28 live tables incl. `gt_vehicles`/`gt_user_profile`. **Loose end:** two audit tables — `audit_log` (165 rows, live) vs `audit_logs` (0 rows, never written) — reconciliation still unresolved.
- **gunner-ops (LEO) integration.** 8-step critical path (Alembic baseline → `org_id` → Numeric money → UUID PKs → masterdb identity → `crew_id` UUID → app_roles → JWT `{sub, org_id}`). Actual schema is **8 tables** (handoff doc wrongly says 6 — omits `vendors`/`faqs`). Foundation done but uncommitted on `feat/alembic-baseline`; steps 5–9 (masterdb wiring) not started — need Leonard-side app registration + a service key, and the deployed gunner-ops Lambda has an IGW but **no NAT** so it cannot yet reach the public masterdb URL.
- **GunnerTeam Lambda RDS-Proxy hotfix (2026-06-15).** `gunnerteam-dev-api` was connecting directly to the **prod** masterdb cluster (1.7 s warm / 20–25 s cold connection-acquire). Fixed by a fresh `gunnerteam-dev-masterdb-proxy` (imperative, not IaC) + SSM `/gunnerteam/dev/DB_HOST` update + alias cutover to Lambda v233. Gotcha: pg client sent `statement_timeout` as a PG startup option, which RDS Proxy rejects — v232/233 skips server-side timeout options when the host is a proxy. **IaC drift:** proxy/SG/IAM aren't captured in IaC — reconcile before the next SST deploy.

For Monday/CompanyCam project sync (the EventBridge cron, fuzzy address matching, one-time CompanyCam import) see [[colin/monday-integration]] and [[colin/feature-inventory]] — that pipeline is distinct from the masterdb identity layer.

## Access & credentials

- Colin has **AdministratorAccess** on AWS account **`980921733684`** via SSO; the only guardrails are process conventions + Leonard for secrets. See [[colin/aws-infra]].
- **DB credentials cannot be pulled from Secrets Manager by an agent** — they come from Leonard. dev masterdb creds (user `postgres`, db `gunner_masterdb`) live in secret `gunner-masterdb-dev-MasterDbProxySecret-ekcuoour`. New `/v1/integrations/*` API keys route through Leonard.
- **dev masterdb access:** bastion `db-tunnel` (`i-0a343c43b1c531300`, `18.219.16.20`) is **SSH-only, not SSM-managed** — `ssh -i <key>.pem -N -L 15432:<rds-endpoint>:5432 ec2-user@18.219.16.20`. DBeaver's in-process tunnel does not expose an OS port, so terminal `psql` needs its own `ssh -L`. masterdb VPC = `vpc-0eb66556f100c7b3c` (no bastion).
- **prod masterdb is private** (`sczazkvf` in `vpc-0530f022b0273f215`, inbound 5432 only from itself + `10.0.0.0/16`, RDS Data API disabled). The dev bastion cannot reach prod. Self-serve SQL needs: enable RDS Data API, a temp EC2 bastion in the prod VPC, or an in-VPC Lambda.

## Open questions / TODOs (as of 2026-06-21)

- **Outbound push blocked on admin.** Needs Leo to grant admin or supply a credential. The only existing admin-slugged role is `qp-super-admin` (held by Glen); the proper `master-db-admin` role was never created. Granting `colin.wong` `qp-super-admin` (substring loophole, direct `user_app_roles` INSERT) is a known workaround — decision deferred on whether to revoke after push.
- **gunner-ops masterdb wiring (steps 5–9) not started**; Alembic baseline not yet stamped/deployed on live dev (the `create_all()` + raw `ALTER` block in `main.py` still runs every cold start and must be removed in its own commit once stamped).
- **gunner-ios audit-table reconciliation** unresolved.
- **GunnerCam shared-Aurora cutover blocked** pending an unmangled DB hostname, a non-superuser `colin_app` runtime role, an RDS-Proxy ownership decision, and clean VPC/subnet/SG values.
- **Secrets exposed in chat must be rotated** — masterdb prod postgres password (2026-06-15), plus colincam + GunnerTeam API keys / DB password (2026-06-14). Store replacements in SST Secrets / Secrets Manager. See [[colin/decisions]].
- **GunnerTeam RDS-Proxy hotfix not in IaC** — reconcile before the next SST deploy.
- **Second masterdb Aurora cluster** `dev-gunner-aurorapgdb-db-cluster` purpose undocumented — clarify with Leonard.

---
*Sources: 120 nuggets, 2026-05-27 → 2026-06-17, ~23 work sessions across the WL-CompanyCam, gunner-ops, and gunner-masterdb repos.*
