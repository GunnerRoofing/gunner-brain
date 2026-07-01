---
type: session
title: "Session 2026-07-01: masterdb org_slug hardening, crm-write-api Lambda, migrate pipeline live"
created: 2026-07-01
updated: 2026-07-01
tags:
  - session
  - masterdb
  - crm
  - oidc
  - alembic
  - iac
status: stable
related:
  - "[[tyler/meta/session-2026-07-01-cc2924-org-slug-hygiene-issue21]]"
  - "[[tyler/meta/session-2026-07-01-cc3300-cc20-crm-internal-flag-dialpad-transcript-clean]]"
  - "[[tyler/masterdb/masterdb-developer-handoff]]"
  - "[[shared/rds-proxy-tls-and-sst-python-packaging]]"
---

# Session 2026-07-01: masterdb org_slug hardening → crm-write-api Lambda → migrate pipeline live (cc-2925–3304)

Six chained prompts on `gunner-masterdb` and `crm-transform`, closing the loop from the issue-#21
decoy-org fix through to a real, working prod migration pipeline. The headline: two genuine infra
bugs were found and fixed along the way that no prompt anticipated — an OIDC trust condition that
silently never authorizes, and a table-ownership gap that blocks all future `crm_*` DDL, not just
the one migration in front of it.

---

## cc-2925/2926 — org_slug decoy-org fix, part 2

Follow-up to [[tyler/meta/session-2026-07-01-cc2924-org-slug-hygiene-issue21]] (issue #21).

- **cc-2925:** `admin/src/Login.jsx` defaulted `org_slug: 'gunner'` — resolves to the decoy shell org
  `7d6db1bb` (empty), not the real `gunnerroofing`/`69aad261`. Changed the default to `'gunnerroofing'`.
  PR #25, merged, CI green.
- **cc-2926:** `/v1/auth/login` resolved the org **only** by slug. Added optional `org_id` on
  `LoginRequest`; `login()` now resolves by `org_id` first (immutable, slug-independent), falls back
  to `org_slug`, else 401 uniform. Backward-compatible — no breaking change for existing callers.
  PR #26, merged, CI green. Consumers (AdminUi, WL `masterdb-client`) should migrate to `org_id` as a
  follow-up (not done this session).

---

## cc-3301 — crm-write-api Lambda (initially blocked, later unblocked in cc-3304)

New standalone Lambda `crm-write-api` in the `crm-transform` repo — `POST /crm/activity`, `type='note'`
only. Reuses `crm-transform`'s `_connect`/`_to_e164` helpers (same zip, `lambda_function.py` never
edited — the batch job stays byte-for-byte). Auth is API Gateway's `google-authorizer`; the handler
never validates the token, only reads a best-effort principal from `requestContext.authorizer` for
author attribution (unresolved → `handled_by_agent_id = NULL`, never a 4xx).

Deployed clean, 404-on-unknown-contact verified live. **The real 201-insert path was blocked**: prod's
`crm_activities` table was missing the `is_internal` column — the migration (`w1_crm_activities_is_internal`,
landed in [[tyler/meta/session-2026-07-01-cc3300-cc20-crm-internal-flag-dialpad-transcript-clean]])
was merged to `main` but never applied to the production cluster. A manual handler-swap attempt to
apply it directly (the old documented fallback) was aborted **on purpose** — `CONTRIBUTING.md §2` now
explicitly bans hand-run/handler-swap migrations, and the deployed API Lambda's bundled migrations dir
turned out to be stale relative to `main` anyway (`KeyError: 'p20_dialpad_agents'` — confirmed no DDL
ran; prod schema unchanged). This gap is exactly what cc-3302/3303/3304 exist to close.

---

## cc-3302 — prod deploy: fresh bundle + migrate pipeline infra

Goal: redeploy the prod SST stack (fixes the stale-bundle `KeyError`) and stand up the migrate
pipeline (`MasterdbMigrate` Lambda + GitHub OIDC + `gha-masterdb-migrate` role).

**Found: the reconcile-status doc's "accepted" SST-version bump was never actually committed.**
`docs/masterdb-iac-reconcile-status.md` documents a decision to bump SST 3.19.3→4.15.2 and pin the aws
provider to 7.20.0 (to dodge the pulumi-aws `aws@6.66.2` `BucketV2`/`getAvailabilityZones` schema bug —
same class blocking `gunner-comms-admin`, see [[shared/rds-proxy-tls-and-sst-python-packaging]] session
lineage). `sst diff` failed outright on a clean checkout because that bump only ever happened
ad hoc in a prior interactive session — `package.json` still pinned `sst: "^3.0.0"`. **Fixed for
real this time**: `package.json` → `"sst": "4.15.2"`, `sst.config.ts` → `providers.aws.version: "7.20.0"`,
committed.

OIDC provider already existed in the account (created 2024-10-25, another repo's stack) — imported via
`{ import: <arn> }` rather than created (AWS allows only one per URL/account). Live thumbprint (GitHub
rotated their intermediate CA) mirrored into config to avoid a spurious update-in-place on import —
same lesson the reconcile doc already taught about SG descriptions.

`sst diff` pre-deploy: additive-only (migrate pipeline resources + API code/bundle), zero
cluster/proxy/SG/parameter-group churn. Deployed. Verified the `p20_dialpad_agents.py` KeyError was
fixed by downloading and inspecting the fresh zip directly (read-only — never touched the live
handler). `MasterdbMigratePassword` SST secret set (value never echoed).

---

## cc-3303 — provision `masterdb_migrate` role (master exception)

`v1_provision_masterdb_migrate` creates the role — documented as a **master-path exception** (the
migrate role can't `CREATE ROLE` itself, `NOCREATEROLE`). Confirmed the applicable mechanism first: the
cc-2913 precedent (applying `q1_crew_members_rls` to prod) — a throwaway migration Lambda in the prod
VPC, credentialed with **master** creds baked into `DATABASE_URL` at creation (never printed to any
tool output), running the bundled `db/migrate.py` handler directly, deleted immediately after. Same
pattern used for `s1_provision_crm_app` (the still-live `crm_app` role).

Applied `v1` (idempotent `CREATE ROLE`), verified via a zip-local temporary `validate_v1` action (never
committed — cc-2913's "patch migrate.py in the zip, not the repo" pattern): `masterdb_migrate` is
`LOGIN NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE`, member of `crm_app`/`gunnerteam_app`/`ops_app`,
`USAGE,CREATE` on `public`, full DML on `alembic_version`. Set the role password to the `MasterdbMigratePassword`
secret value (never echoed). Verified the **real** `MasterdbMigrate` Lambda connects and reports `v1`.

---

## cc-3304 — run w1 via migrate-prod: two real bugs found, both fixed

### Bug 1: `job_workflow_ref`-based OIDC trust never authorizes

The first `migrate-prod` run failed at `AssumeRoleWithWebIdentity` with a generic `AccessDenied` /
`"An unknown error occurred"` (STS redacts the real reason for this API). Added a temporary workflow
step to decode the actual OIDC token claims — `job_workflow_ref` matched the trust policy condition
**byte-for-byte**. Still denied.

Root cause not fully explained (no policy-eval detail surfaced anywhere, not even in CloudTrail), but
resolved empirically: every other OIDC role in this AWS account (`dev-lambda-deployment-github-assume-role`,
`dev-salesPortal-github-assume-role`, etc. — 26 historical successes, 0 on `job_workflow_ref`) uses a
`sub`-based `StringEquals` condition. Switching `gha-masterdb-migrate` to the same pattern
(`repo:GunnerRoofing/gunner-masterdb:ref:refs/heads/main`) worked immediately. Trade-off: `sub` scopes
to the branch, not the specific workflow file — `concurrency: migrate-prod` plus the workflow's own
`confirm=='apply'` gate remain as the defense against an unrelated main-branch workflow invoking the role.

**Takeaway for future OIDC roles in this account:** default to `sub`-based conditions. `job_workflow_ref`
looks correct on paper (and other AWS accounts/setups do use it successfully) but is proven **not to
work** in this specific account/provider configuration — don't spend time debugging it again, switch
straight to `sub`.

### Bug 2: `crm_app` grants ≠ `crm_app` ownership — DDL fails

`w1`'s `ALTER TABLE crm_activities ADD COLUMN ...` failed live: `must be owner of table crm_activities`.
Root cause: `s1_provision_crm_app` granted `crm_app` `SELECT/INSERT/UPDATE` on the `crm_*` tables, but
`t1_crm_sales_schema` **created** those tables while connected as master — so all 6 tables remained
master-owned. `masterdb_migrate`'s `GRANT crm_app` (from `v1`) confers `crm_app`'s privileges via role
membership, but Postgres DDL (`ALTER TABLE`) requires **ownership**, not membership — the two are
orthogonal, a distinction that's easy to miss (`GRANT` reads like it should be enough for anything
`crm_app` can do, but it isn't for table structure changes).

Same class as `k11_provision_gunnerteam_app`'s `gt_*` reassignment. Fixed with a new migration
`x1_crm_ownership_to_crm_app` (master-path exception, same self-grant/reassign/revoke pattern as k11),
inserted between `v1` and `w1` (`w1.down_revision` re-pointed `v1`→`x1`; single head preserved,
`alembic heads` = 1, verified locally before commit). Closes the gap for **all future** `crm_*` DDL, not
just this one column.

### Result

`migrate-prod` run succeeded: pre-flight `x1_crm_ownership_to_crm_app` → apply → `w1_crm_activities_is_internal`.
Column verified live (`is_internal | boolean | NO | true`). `crm-write-api` end-to-end verified: worknote
(`is_internal:true`) → 201, comment (`is_internal:false`) → 201, both rows confirmed persisted with
correct `type=note, source=manual`, contact linked, author `NULL` (test principal wasn't a seeded
Dialpad agent — expected, by design never a 4xx). `cc-prompt-3301-crm-post-activity-write-lambda.md`
archived.

---

## Reusable facts (promote if referenced again)

- **This AWS account's OIDC federation only reliably authorizes on `sub`-based trust conditions.**
  `job_workflow_ref` looked correct (claim matched the policy exactly, confirmed via decoded-token
  dump) and was still denied with no diagnosable reason. Default to `sub:repo:<org>/<repo>:ref:<ref>`
  for any new GitHub Actions OIDC role in `980921733684`.
- **Postgres `GRANT <role> TO <role>` ≠ ownership.** A role can have full SELECT/INSERT/UPDATE via
  membership and still fail `ALTER TABLE` with `must be owner of table` if it doesn't own the object.
  Any table created while connected as master needs an explicit ownership-reassignment migration
  (`k11`/`x1` pattern: self-grant temporary membership, `ALTER TABLE ... OWNER TO`, revoke) before a
  least-privilege role can run DDL against it — grants alone are not sufficient.
- **"Accepted" IaC decisions documented in a reconcile/status doc are not real until they're in
  `package.json`/config and committed.** The SST 4.15.2 / aws-provider-7.20.0 bump was written up as
  done in `docs/masterdb-iac-reconcile-status.md` after the 2026-06-29 session, but only ever applied
  as a local/uncommitted version bump — a clean checkout still hit the old `aws@6.66.2` bug. Verify
  against the actual committed files, not the doc's prose.
- **`gunner-masterdb`'s documented master-path exception mechanism** (for role-creating/ownership-
  changing migrations that the least-priv `masterdb_migrate` role can't run itself): a throwaway
  Lambda in the prod VPC, master creds baked into `DATABASE_URL` at creation (never echoed), invoke,
  delete immediately. Same pattern for verification: zip-local-patch a temporary read-only debug
  action into the migrate handler, invoke, revert — never commit the patch.

## Version / commit ledger

- `gunner-masterdb`: PR #25 (`fix/adminui-login-org-slug`, merged), PR #26 (`feat/auth-login-by-org-id`,
  merged), `3bcc6fb` (cc-3302 SST/OIDC/migrate-pipeline deploy), `648924b` (cc-3304 OIDC sub-fix +
  `x1_crm_ownership_to_crm_app`). Migration head: `w1_crm_activities_is_internal`.
- `crm-transform`: `3f46433` (cc-3301 `write_api.py` + `deploy-write.sh`).
- Live: `crm-write-api` Lambda (`arn:aws:lambda:us-east-2:980921733684:function:crm-write-api`),
  `MasterdbMigrate` Lambda, `gha-masterdb-migrate` IAM role, `masterdb_migrate` DB role — all new this
  session.
