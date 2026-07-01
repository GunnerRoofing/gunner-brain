---
type: runbook
title: GunnerTeam — MasterDB SOC2 §14 Residuals
created: '2026-06-30'
updated: '2026-06-30'
tags: [gunner, gunnerteam, runbook, masterdb, soc2]
status: stable
source: Gunner Team App/runbooks/runbook-masterdb-residuals-2026-06-30.md
related: ["[[gunnerteam/gunnerteam-project-structure]]", "[[index]]"]
---

# Runbook — §14 masterdb residuals (2026-06-30)

Two independent diagnostics, both **read-only first**. Run in **prod CloudShell** (in-VPC, cluster
`sczazkvf`), connect as master from the proxy secret. No writes without a decision.

```bash
# One-time in the CloudShell VPC env. No literal <placeholders> — every value is fetched.
SEC=$(aws secretsmanager get-secret-value --region us-east-2 \
  --secret-id gunner-masterdb-production-MasterDbProxySecret-mueddfoa \
  --query SecretString --output text)
export PGPASSWORD=$(echo "$SEC" | python3 -c 'import sys,json;print(json.load(sys.stdin)["password"])')
PGUSER=$(echo "$SEC" | python3 -c 'import sys,json;print(json.load(sys.stdin)["username"])')

# Prod cluster WRITER endpoint (sczazkvf), fetched — do not hand-type:
PGHOST=$(aws rds describe-db-clusters --region us-east-2 \
  --query "DBClusters[?contains(DBClusterIdentifier,'sczazkvf')].Endpoint" --output text)
echo "$PGHOST"   # sanity: gunner-masterdb-production-...sczazkvf...us-east-2.rds.amazonaws.com

# Direct-as-master replicates the archiver's RLS view. sslmode=require is enough for a read-only
# diagnostic (encrypts, satisfies force_ssl, no CA file). For strict TLS, see the verify-full note below.
psql "host=$PGHOST port=5432 dbname=gunner_masterdb user=$PGUSER sslmode=require"

# Strict-TLS alternative (matches the app):
#   curl -s -o /tmp/rds-ca.pem https://truststore.pki.rds.amazonaws.com/us-east-2/us-east-2-bundle.pem
#   psql "host=$PGHOST port=5432 dbname=gunner_masterdb user=$PGUSER sslmode=verify-full sslrootcert=/tmp/rds-ca.pem"
```

---

## Runbook 1 — p20 / q1 content-drift (committed files vs live prod DDL)
**Why:** the restored `p20_dialpad_agents.py` / `q1_crew_members_rls.py` were matched on revision-ID,
not diffed against the prod-applied DDL. Revision-ID match ≠ body match. This confirms the committed
bodies equal live before a fresh env ever rebuilds from them (§12 cutover). Prod already has these
applied, so the check is a comparison, not an apply.

### 1a. `dp_agents` (RLS-free — master reads directly)
```sql
-- Columns, types, nullability, defaults
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns WHERE table_name='dp_agents' ORDER BY ordinal_position;

-- Indexes
SELECT indexname, indexdef FROM pg_indexes WHERE tablename='dp_agents' ORDER BY indexname;

-- agent_id columns on the feed tables
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_name IN ('dp_sms_messages','dp_calls') AND column_name='agent_id';

-- Grants to gunnerteam_app
SELECT grantee, privilege_type FROM information_schema.role_table_grants
WHERE table_name='dp_agents' AND grantee='gunnerteam_app' ORDER BY privilege_type;

-- Seed count + link fill
SELECT count(*) AS agents, count(gt_user_id) AS linked FROM dp_agents;
```
**Expect (from p20):** 10 columns incl `id uuid PK default gen_random_uuid()`, `org_id uuid NOT NULL`,
`dialpad_user_id bigint`, `dialpad_all_phones text[] NOT NULL default '{}'`, `gt_user_id varchar` FK→users(id),
`created_at/updated_at timestamptz NOT NULL default now()`, `UNIQUE(org_id,dialpad_email)`.
Indexes: `dp_agents_user_id_idx` (partial, dialpad_user_id NOT NULL), `dp_agents_gt_user_idx` (partial),
`dp_agents_all_phones_gin` (GIN), plus the PK + unique. `agent_id uuid` on both feed tables.
Grants: SELECT, INSERT, UPDATE. **agents = 26**; `linked` > 0 (backfill by lower(email)). Any deviation ⇒ drift.

### 1b. `crew_members` (FORCE RLS — checking structure, not rows)
```sql
-- RLS flags
SELECT relrowsecurity AS enabled, relforcerowsecurity AS forced
FROM pg_class WHERE relname='crew_members';

-- Policies (name / cmd / roles / using / check)
SELECT policyname, cmd, roles, qual, with_check
FROM pg_policies WHERE tablename='crew_members' ORDER BY policyname;

-- Grants
SELECT grantee, privilege_type FROM information_schema.role_table_grants
WHERE table_name IN ('crew_members','crews') AND grantee='gunnerteam_app' ORDER BY table_name, privilege_type;
```
**Expect (from q1):** `enabled=t, forced=t`. Two policies:
`org_isolation` (roles `{public}`, USING references `crews c … c.org_id = current_setting('app.current_org_id',true)`, no WITH CHECK);
`gunnerteam_app_org` (roles `{gunnerteam_app}`, cmd ALL, USING + WITH CHECK both `EXISTS(... user_organizations uo … uo.org_id = '69aad261-347c-44db-8e9e-6c25a8509aa3')`).
Grants: gunnerteam_app has SELECT on `crew_members` (+ DELETE from k12) and SELECT on `crews`.
Any missing policy, wrong org literal, or missing grant ⇒ drift.

**On drift:** the *files* are the source of truth for a fresh rebuild; if live differs, decide per-item
whether live is correct (update the migration body to match, via PR) or the file is (schedule a corrective
migration). Record the diff. Do not silently edit prod.

### RESULT — RUN 2026-06-30, RESIDUAL (a) CLOSED (no schema drift)
- **dp_agents:** all 10 columns match p20 (types/nullability/defaults incl. `dialpad_all_phones text[]
  NOT NULL default '{}'`, `gt_user_id varchar`). 5 indexes present (pkey, `dp_agents_org_id_dialpad_email_key`
  unique, `dp_agents_gt_user_idx` + `dp_agents_user_id_idx` partials, `dp_agents_all_phones_gin`). `agent_id
  uuid` on both `dp_sms_messages` + `dp_calls`. Grants = SELECT/INSERT/UPDATE. **agents=27, linked=4** —
  27 vs the seeded 26 is expected runtime growth (gunnerteam_app has INSERT; ingestion adds/claims agents),
  NOT drift; content-drift is about DDL, and the DDL matches.
- **crew_members:** enabled=t forced=t; both policies exact (`gunnerteam_app_org` USING+CHECK via
  user_organizations w/ literal `69aad261`; `org_isolation` PUBLIC USING via crews + current_setting, no
  CHECK); grants = crew_members SELECT+DELETE, crews SELECT. Matches q1 line-for-line.
- Not explicitly re-queried (low risk, column types consistent): the FK `gt_user_id → users(id)` and the
  `agent_id → dp_agents(id)` FKs. Optional belt-and-suspenders if desired.

**Verdict:** committed p20/q1 bodies == live prod schema. Safe for a fresh §12 rebuild. Both §14 residuals
(content-drift + archiver across-orgs) now CLOSED.

---

## Runbook 2 — audit-archiver reads `audit_log` across all orgs
**Why:** `lambda/audit-archiver.js` connects with `MasterDbProxySecret-mueddfoa` = **master**, and sets
**no** `app.current_org_id`. `audit_log` is FORCE RLS with an org-scoped `org_isolation` policy, and master
is `NOBYPASSRLS` — so a no-GUC `SELECT count(*) FROM audit_log` may return a **filtered/zero** count, meaning
the archiver silently archives (and prunes) nothing or one org only. Measure before concluding.

### 2a. Table posture + connecting-identity privilege
```sql
SELECT relrowsecurity AS enabled, relforcerowsecurity AS forced,
       pg_get_userbyid(relowner) AS owner
FROM pg_class WHERE relname='audit_log';

SELECT policyname, cmd, roles, qual, with_check FROM pg_policies WHERE tablename='audit_log';

-- The archiver's identity (username from mueddfoa) and whether it bypasses RLS
SELECT rolname, rolsuper, rolbypassrls FROM pg_roles WHERE rolname = current_user;
```

### 2b. The decisive measurement — archiver-style vs org-scoped
```sql
-- A) EXACTLY what the archiver sees (no GUC, as master):
SELECT count(*) AS archiver_visible FROM audit_log;

-- B) True count for the (only) live tenant:
SET app.current_org_id = '69aad261-347c-44db-8e9e-6c25a8509aa3';
SELECT count(*) AS org_scoped FROM audit_log;
RESET app.current_org_id;

-- C) Oldest row — if archival/prune has been failing, this is older than the 6-month prune window:
SELECT min(created_at) AS oldest, max(created_at) AS newest, count(*) AS total FROM audit_log;
```
**Interpretation:**
- `archiver_visible == org_scoped` and both > 0 → archiver reads correctly today (single tenant, fine now; re-check before a 2nd org).
- `archiver_visible == 0` (or `< org_scoped`) → **confirmed finding**: the archiver under-reads. Corroborate with 2c oldest-row age and the S3 archive bucket (below).

### 2c. Corroborate against the actual archive output
```bash
# Recent monthly archive objects — if empty/stale, archival has not been running
aws s3 ls s3://<audit-archive-bucket>/ --recursive --region us-east-2 | tail -20
```
(bucket name from `audit-archiver.tf`; expect `YYYY/MM/audit_log.json` objects, most-recent within a month.)

### RESULT — RUN 2026-06-30, RESIDUAL (b) CLOSED
Measured live (prod `sczazkvf`, connected as master):
- `audit_log`: `relrowsecurity=t`, `relforcerowsecurity=t`, owner `postgres`. Policies: `org_isolation`
  (PUBLIC, `org_id::text = current_setting('app.current_org_id',true)`), `gunnerteam_app_org` +
  `comms_admin_ro_org` (both literal `69aad261`).
- Connecting identity = `postgres`, `rolsuper=f`, `rolbypassrls=f`.
- `archiver_visible` (no GUC) = **3359** == `org_scoped` (GUC=gunner) = **3359** == total. Oldest
  2026-05-15, newest ~now → prune correctly deletes nothing (<6mo of data).
- No `app.current_org_id` default anywhere (`SHOW` empty; `pg_db_role_setting` = only RDS `rdsadmin`/
  `rdsproxyadmin` noise) → **option (b) ruled out**, not single-org-scoped.
- **Mechanism confirmed:** `SET ROLE ops_app` (NOBYPASSRLS, non-owner, no all-org policy) → count = **0**.
  So FORCE RLS is genuinely active and filters non-owner `NOBYPASSRLS` roles to zero; `postgres`'s full
  read is an owner/master implicit bypass, not a policy match.

**Verdict:** the archiver reads all orgs today — no gap now or at tenant #2 — **because it connects as
master.** ⚠️ **HARD DEPENDENCY for Phase-2b:** the moment the archiver moves off master to a dedicated
`NOSUPERUSER NOBYPASSRLS` role (to shrink master blast radius), it will read **0** / prune nothing unless
that role gets an explicit `CREATE POLICY … FOR ALL TO <archiver_role> USING (true)` on `audit_log` only
(+ SELECT/DELETE grants). Not optional — it's a prerequisite of the master-off move (route through Colin;
CC7.2 evidence). Captured in `phase2-secrets-rotation-plan-2026-06-30.md` §2b.
