---
type: runbook
title: GunnerTeam — MasterDB Self-Serve Access (CloudShell)
created: '2026-06-25'
updated: '2026-06-25'
tags: [gunner, gunnerteam, runbook, masterdb, cloudshell, vpc]
status: stable
source: Gunner Team App/runbooks/masterdb-self-serve-access-cloudshell-runbook.md
related: ["[[gunnerteam/gunnerteam-project-structure]]", "[[index]]"]
---

# Self-serve in-VPC masterdb access — CloudShell VPC environment

**Purpose:** an audited, ephemeral in-VPC shell to run `psql`/`alembic` directly against the prod masterdb
cluster — ending the "build a throwaway migrate-Lambda / wait on Colin / laptop can't route to the VPC"
dependency proven during B1. This is **Phase 2 (human access)** of the masterdb SOC 2 roadmap.

**Why CloudShell VPC env (not an EC2 bastion):** ephemeral, IAM-gated, CloudTrail-audited, no persistent
instance, no SSH keys, no patching/SG upkeep. NAT is present (`nat-0d68763a7ea1e11d7`), so it has egress for
`git`/`pip`. (An EC2 bastion is the fallback if CloudShell VPC envs are ever restricted.)

## Known prod infra
| thing | value |
|---|---|
| VPC | `vpc-0530f022b0273f215` |
| subnet (has NAT egress) | `subnet-004acfd6dbb59a231` (or `-0481e68e34ade2858`) |
| SG (already allowed inbound on the proxy SG `sg-0e3345754d47898b8`) | `sg-06313256b581ef39a` |
| proxy endpoint | `gunnerteam-dev-masterdb-proxy.proxy-c52gm8goign8.us-east-2.rds.amazonaws.com:5432` |
| DB | `gunner_masterdb` |
| master secret (user `postgres`) | `gunner-masterdb-production-MasterDbProxySecret-mueddfoa` |
| gunnerteam_app secret | `gunnerteam-app-masterdb-proxy` |

## Step 1 — create the CloudShell VPC environment
Console → **CloudShell** → environment dropdown → **Create VPC environment**:
- VPC `vpc-0530f022b0273f215`, Subnet `subnet-004acfd6dbb59a231`, Security group `sg-06313256b581ef39a`

Reusing the app Lambda's SG means it's already permitted into the proxy — **no SG change needed**, you connect
via the proxy endpoint. (Direct-to-writer would need that SG added to the cluster SG inbound; not necessary.)

## Step 2 — tooling (first session only)
```bash
sudo dnf install -y postgresql15            # psql client (Amazon Linux 2023 CloudShell)
python3 -m pip install alembic psycopg2-binary    # NO --user — CloudShell runs in a venv where --user fails
```
✅ **Verified working 2026-06-25** — `alembic current` returned `p17_reconcile_gt_org (head)` from CloudShell. GitHub clone needs a PAT (paste as the password at the `git clone` prompt; user `tylersuffern`).

## Step 3 — connect (via the proxy, as postgres) — prove the route
```bash
PROXY=gunnerteam-dev-masterdb-proxy.proxy-c52gm8goign8.us-east-2.rds.amazonaws.com
export PGPASSWORD="$(aws secretsmanager get-secret-value \
  --secret-id gunner-masterdb-production-MasterDbProxySecret-mueddfoa \
  --region us-east-2 --query SecretString --output text | jq -r .password)"
psql "host=$PROXY port=5432 dbname=gunner_masterdb user=postgres sslmode=require" -c "SELECT 1;"
unset PGPASSWORD
```
`SELECT 1` → you can reach your own cluster, no Lambda, no laptop wall. That's the milestone.

## Step 4 — run alembic / migrations yourself
```bash
git clone https://github.com/GunnerRoofing/gunner-masterdb.git && cd gunner-masterdb   # auth: PAT or `gh auth login`
PROXY=gunnerteam-dev-masterdb-proxy.proxy-c52gm8goign8.us-east-2.rds.amazonaws.com
export PGPASSWORD="$(aws secretsmanager get-secret-value --secret-id gunner-masterdb-production-MasterDbProxySecret-mueddfoa --region us-east-2 --query SecretString --output text | jq -r .password)"
export DATABASE_URL="postgresql://postgres@$PROXY:5432/gunner_masterdb?sslmode=require"   # PGPASSWORD supplies the pw → stays out of history
alembic current        # confirm head (e.g. p17_reconcile_gt_org post-B1)
# alembic upgrade <target>   # when actually applying
unset PGPASSWORD
```

## Guardrails / notes
- **Ephemeral:** delete the VPC env when done — no standing infra. Pull creds from Secrets Manager each session; never bake them in.
- **⚠️ NO role has BYPASSRLS (confirmed 2026-06-25):** `postgres`, `rds_superuser`, and `gunnerteam_app` all have `rolbypassrls=false, rolsuper=false` — Aurora can't grant BYPASSRLS (no true superuser). So on `FORCE ROW LEVEL SECURITY` tables, **both DML and full-table reads are RLS-filtered for every role.** Consequences: (a) DML migrations (p18) must use the in-txn `ALTER TABLE … NO FORCE ROW LEVEL SECURITY` → DML → re-`FORCE` toggle as the table owner, and the toggle must also cover any drain-guard/row-count reads (those are distorted too); (b) even a diagnostic `psql` as `postgres` here sees only the RLS-visible subset — to get the true row picture, lift FORCE in your session. There is no bypass role to fall back on. (DDL like p17 is RLS-immune — unaffected.) This is why the "2 orphaned memberships" were a false reading — RLS hid the user rows; the validated FK proved they exist.
- **Shared-surface coordination still applies:** until the masterdb IaC reconciliation lands, ping Colin before any change to the cluster/roles/proxy — this gives you *access*, not a license to skip the change-routing norm.
- **SOC 2:** ephemeral + IAM-gated + CloudTrail-audited is a clean break-glass posture. Fold the pattern into the masterdb IaC reconciliation so it's documented, not another out-of-band artifact. Future tightening: a dedicated least-priv break-glass role rather than admin SSO.
- **This is interim.** The durable Phase-3 answer is the migration pipeline (CI runs `alembic upgrade` on merge to `main`) — then routine migrations need neither this shell nor a Lambda. This runbook is for ad-hoc reads, diagnostics, and break-glass.
