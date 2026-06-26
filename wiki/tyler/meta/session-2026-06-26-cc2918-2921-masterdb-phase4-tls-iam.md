---
type: session
title: 'Session 2026-06-26: masterdb Phase 4 — TLS, alerting, IAM least-priv'
created: '2026-06-26'
updated: '2026-06-26'
status: stable
tags:
  - session
  - masterdb
  - soc2
  - tls
  - iam
  - monitoring
  - cc7.1
  - cc6.x
related:
  - '[[tyler/masterdb/soc2-roadmap]]'
  - '[[tyler/masterdb/masterdb-architecture]]'
  - '[[gunnerteam/security-compliance-roadmap]]'
---

# Session 2026-06-26: masterdb Phase 4 — TLS, alerting, IAM least-priv

Four prompts closing out §14 Phase 4 self-serve items on the masterdb SOC 2 hardening track.

---

## cc-2918 — masterdb Phase 4 verification sweep (read-only)

Read-only `describe-*` against `gunner-masterdb-production-masterdbcluster-sczazkvf`.

### Results

| Check | Result | Evidence |
|---|---|---|
| Encryption at rest | ✅ | `StorageEncrypted=true`, KMS `492fa0c0` (AWS-managed symmetric, enabled) |
| Backups / PITR | ✅ | Retention=14d; PITR window 2026-06-23→2026-06-26 (RPO≈5min); `DeletionProtection=true` |
| TLS — cluster | ✅ | `rds.force_ssl=1` in cluster param group (source=system) |
| TLS — proxy | ❌ gap | `RequireTLS=false` on `gunnerteam-dev-masterdb-proxy` → Colin item |
| TLS — app | ❌ gap | `db/session.py` had no `connect_args` → cc-2919 self-serve fix |
| DB audit logging | ❌ gap | `EnabledCloudwatchLogsExports=null`; `shared_preload_libraries=pg_stat_statements` (no pgAudit); `pgaudit.log=null` → Colin item (parameter-group change) |

KMS type: AWS-managed (`KeyManager=AWS`). CMK rotation to customer-managed remains launch-gated §12.

---

## cc-2919 — db/session.py verify-full TLS (self-serve)

**Change:** `db/session.py` `create_engine` gained `connect_args={"sslmode": "verify-full", "sslrootcert": _RDS_CA}` + committed `db/certs/rds-global-bundle.pem` (165KB, AWS global RDS CA bundle).

`verify-full` = encrypt + validate server cert + verify hostname. Equivalent to Node's `rejectUnauthorized: true` standard. NOT bare `require` (which only encrypts, no cert validation).

**Verified in-VPC** via throwaway Lambda in prod VPC (`vpc-0530f022`, subnets `004acf`/`0481e6`, SG `sg-06313256`):
```
ssl_active: true
ssl_version: TLSv1.3
ssl_cipher: TLS_AES_256_GCM_SHA384
```

PR#8 open (`app-tls-verify-full` branch). Deploy caveat: masterdb FastAPI has no automated pipeline — ships on next manual Lambda deploy.

**Pattern:** throwaway Lambda in prod VPC used to run in-VPC tests (same as cc-2913 migration pattern). `pg_stat_ssl` view (not `ssl_is_used()`) to check TLS state — `sslinfo` extension not loaded so `ssl_is_used()` throws `UndefinedFunction`.

---

## cc-2920 — masterdb auth-anomaly / DB-error alerting

Three CW metric-filter→alarm pairs added to `monitoring.tf`, on the `gunnerteam-dev-api` log group → existing SNS topic.

| Filter/Alarm | Pattern | Threshold | Covers |
|---|---|---|---|
| `MasterdbAuthFailures` | `?"28P01" ?"password authentication failed"` | 1-of-1, 60s | Stale-secret-cache SEV-1 (would have beaten user reports in B1 incident) |
| `MasterdbRLSDenied` | `"permission denied for table"` | 2-of-3, 300s | RLS/grant regression (crew_members-grant class, org-inversion class) |
| `MasterdbConnectFailures` | `"db.connect failed"` | 1-of-1, 60s | Proxy outage / VPC/SG misconfiguration |

Targeted apply: **6 added, 0 changed, 0 destroyed.** Filter smoke-test: 0 matches in 24h (healthy baseline).

---

## cc-2921 — app-stack IAM least-priv review

`aws iam generate-service-last-accessed-details` + code grep for both roles, then targeted apply.

### Findings and fixes

**lambda-api** (`gunnerteam-dev-lambda-api`):

| Fix | What | Reason |
|---|---|---|
| Remove `SecretsManager` grant | `secretsmanager:GetSecretValue` | `last-accessed=never`; `secrets.js` uses `SSM:GetParametersByPath` exclusively — no Secrets Manager SDK call in codebase |
| Split `VPCAccess` | `ec2:CreateNetworkInterface` gets `ec2:Subnet` condition scoped to app subnets | Defense-in-depth; `Describe*/Delete*` stay at `*` (AWS doesn't support resource scoping) |
| `cloudwatch:namespace` condition | `PutMetricData` restricted to `[gunnerteam/dev, GunnerTeam/DB]` | Matches actual namespaces emitted by scheduler.js and cc-2920 filters |
| SES — no change | `arn:aws:ses:...:identity/gunnerroofing.com` | `gunnerroofing.com` domain identity covers `updates.gunnerroofing.com` subdomain per AWS SES semantics |

**audit-archiver** (`gunnerteam-dev-audit-archiver`):

| Fix | What | Reason |
|---|---|---|
| Scope logs | `arn:aws:logs:*:*:*` → own log group ARN | Real over-grant; TF pre-creates the log group so `CreateLogGroup` also dropped |
| `ec2:Subnet` condition | Same as lambda-api | App subnets only |
| `cloudwatch:namespace` condition | `[gunnerteam/dev]` only | Matches `AuditLogLast24h` metric emitted by audit-archiver.js |

Targeted apply: **0 added, 2 changed, 0 destroyed.** Smoke-test: `/health` + DB path both green, no AccessDenied.

### Tooling notes

- `generate-service-last-accessed-details` + `get-service-last-accessed-details` = the right tool for right-sizing. Use a long window — SES and S3 have infrequent but real use cases (forgot-password, archiver monthly).
- `last-accessed=None + total=0 + no code usage` = safe to remove. Any one of those being true alone is not sufficient.
- `textract` shows as used by lambda-api but isn't granted — that's a Lambda-managed service call, not the app role.

---

## §14 Phase 4 status after this session

| Item | Status |
|---|---|
| Aurora encryption at rest | ✅ verified |
| Backup/PITR posture | ✅ verified (14d retention, RPO≈5min) |
| TLS — cluster `force_ssl` | ✅ verified |
| TLS — app `verify-full` | ✅ PR#8 (ships on next masterdb deploy) |
| TLS — proxy `RequireTLS` | ❌ Colin item |
| DB audit logging (pgAudit/CW exports) | ❌ Colin item |
| masterdb auth/RLS/connect alerting | ✅ live (cc-2920) |
| IAM least-priv review | ✅ done (cc-2921) |
