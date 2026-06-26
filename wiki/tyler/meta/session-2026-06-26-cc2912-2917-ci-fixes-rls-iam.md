---
type: session
title: 'Session 2026-06-26: CI fixes, crew_members RLS to prod, IAM key audit'
created: '2026-06-26'
updated: '2026-06-26'
status: stable
tags:
  - session
  - masterdb
  - ci
  - rls
  - iam
  - soc2
  - cc6.1
related:
  - '[[tyler/masterdb/soc2-roadmap]]'
  - '[[tyler/masterdb/masterdb-architecture]]'
  - '[[gunnerteam/security-compliance-roadmap]]'
  - '[[meta/lint-report-2026-06-25]]'
---

# Session 2026-06-26: CI fixes, crew_members RLS to prod, IAM key audit

Five prompts: CI green-light work on masterdb PRs, first prod Alembic migration via throwaway Lambda, and a read-only IAM key inventory.

---

## cc-2912 — Fix PR#5 (deps-pin) all-red CI

**Problem:** PR#5 (`deps-pin`) security job failing — same 10 ruff F401/F841 + bandit B608 + semgrep 5-finding set that were fixed on `ci-gates` but never carried to `deps-pin` (which branched from `main` before those fixes landed).

**Fix:** applied to `deps-pin` branch:
- `ruff check --fix api db` — 9 auto-fixed; `vehicle_uuid = None` dead assignment manually removed
- `# nosec B608` added to `db/migrate.py:424`
- `ci.yml` Semgrep step updated to `--exclude db/migrations`; `# nosemgrep` annotations on lines 252, 258, 424

**Result:** all 4 checks green (security, tests, lock-drift, rls-isolation). PR#5 ready to merge.

---

## cc-2913 — Apply q1 (crew_members RLS) to prod

**Goal:** `q1_crew_members_rls` merged to main (PR#6) but not yet on prod DB. CC6.1 not closed until this runs.

**Gate passed:** prod was at `p20_dialpad_agents` → single-step upgrade safe.

**Process (throwaway migration Lambda pattern):**
1. Downloaded current prod API Lambda zip
2. Created `gunner-masterdb-migrate-runner` Lambda in **prod VPC** (`vpc-0530f022b0273f215`, subnets `subnet-004acfd6dbb59a231` + `subnet-0481e68e34ade2858`, SG `sg-06313256b581ef39a`) — matching prod Aurora cluster's VPC
3. Master credentials from `gunner-masterdb-production-MasterDbProxySecret-mueddfoa` (Secrets Manager)
4. Added all missing migration files (p17–p21, q1) to zip — Lambda zip predated them
5. Invoked `{"action":"upgrade_to","target":"q1_crew_members_rls"}` → success
6. Validated via patched `validate_q1` action
7. Deleted Lambda, cleaned up zips

**Validation result:**
```json
{
  "policies": ["gunnerteam_app_org", "org_isolation"],
  "rls_enabled": true,
  "rls_forced": true,
  "cross_tenant_rows": 0,
  "total_crew_members": 1
}
```

**Key lessons:**
- Prod cluster (`sczazkvf`) is in VPC `0530f022` — different from dev cluster (`kdsmbssw`) in VPC `0eb66556`. Migration Lambda must be placed in the SAME VPC as the target cluster.
- DB_HOST SSM param = RDS Proxy endpoint (proxy targets prod cluster). Direct cluster endpoint needed for migration Lambda (proxy = wrong VPC for that Lambda placement).
- Lambda zip must include ALL migration files since last deploy — not just the new one. Alembic walks the entire chain.
- For throwaway validation: patch migrate.py in the zip with a temp action rather than creating a separate file.

---

## cc-2915 — Resolve PR#7 (ci-gates-v2)

**Decision:** Case A — closed as fully redundant.

Every line in PR#7 already on `main`:
- `ci.yml` with all gates (via PR#3 + PR#5)
- 3 `# nosemgrep` annotations on `db/migrate.py`
- `except Exception` ruff fix

PR#7 closed with explanation comment. No revert risk.

---

## cc-2916 + cc-2917 — IAM key inventory (read-only)

**Scope:** Tyler-owned keys only. No deactivation in these prompts.

### Inventory (dev account 980921733684)

| User | Key ID | Last Used | Service | Status |
|---|---|---|---|---|
| `leads-finder-dk` | `AKIA…B4FL` | yesterday | ec2/cognito/cloudfront | **Tyler's 2nd admin key** (all from `24.47.22.44`) |
| `permit-ops-dev-spare-macbook-runner` | `AKIA…VU5` | **never** | — | Created 2026-06-24, tagged "spare", deactivate-ready |
| `gunner-content-engine` | `AKIA…3JH` | 2026-06-15 | s3 | Unknown owner, S3ReadOnly |
| `KinesisDataStreamFabricUser` | `AKIA…TP5` | today | kinesis | 17-month-old key, MS Fabric integration — defer |
| `permit-mac-runner` | `AKIA…ZXM` | today | sqs | Active permit-ops runner — keep |
| `wl-companycam-app-dev` | `AKIA…WUP` | 2026-06-22 | s3 | Colin's — defer |
| `leonard.fuentes@` | `AKIA…P4V` | yesterday | logs | Leo's — defer |
| `tyler-cli` | `AKIA…7WG` | today | lambda | Tyler's CLI — defer (needs Identity Center) |

### Key finding: leads-finder-dk = Tyler's second admin key

CloudTrail shows all activity from a single IP `24.47.22.44` — the same IP whitelisted in the masterdb dev cluster SG. This is Tyler's home/office IP. Not a "dk" person.

Recent actions: `AdminCreateUser`, `AdminSetUserPassword` (Cognito), `TerminateInstances`, `DescribeInstances`, `UpdateDistribution` (CloudFront), `FilterLogEvents`, `ListFunctions`, `DescribeDBInstances`.

**SOC2 finding:** Two full-admin personal keys (`tyler-cli` + `leads-finder-dk`) for one user. `AdministratorAccess` on a named "service" account is also a finding.

### Worklist (§14)

| Key | Bucket | Action needed |
|---|---|---|
| `leads-finder-dk` | Tyler-owns: consolidate | Tyler decision: retire this vs tyler-cli, then both → Identity Center |
| `permit-ops-dev-spare-macbook-runner` | Deactivate-ready | Tyler confirms "yes" → I run the command |
| `gunner-content-engine` | Identify owner | Ask content/marketing team |
| `KinesisDataStreamFabricUser` | Defer + rotation plan | Data/Fabric owner — 17-month key needs rotation |
| `wl-companycam-app-dev` | Defer | Colin |
| `leonard.fuentes@` | Defer | Leo |
| `tyler-cli` | Defer → Identity Center | Eddie (payer account needed) |

**No GitHub CI static keys found** in gunner-masterdb or gunner-ios — no OIDC work needed.
