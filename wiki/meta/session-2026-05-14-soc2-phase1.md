---
title: Session 2026-05-14 — SOC 2 Phase 1
type: meta
tags:
  - meta
  - session
  - soc2
  - gunnerteam
  - aws
  - audit
created: '2026-05-14'
updated: '2026-05-14'
status: stable
---

# Session 2026-05-14 — SOC 2 Phase 1

Full SOC 2 readiness sprint for [[gunner/gunnerteam-api-aws-migration|GunnerTeam API]]. Four items completed in one session: audit logging, RDS exposure fix, secrets management, and full route coverage.

---

## What Was Built

### 1. Audit Logging

**Migration:** `gunnerteam-api/migrations-audit.sql`
- `audit_logs` table: BIGSERIAL id, TIMESTAMPTZ ts, user_id (FK nullable), company (tenant slug), action (dot-namespaced), resource (e.g. `user:42`), ip, user_agent, metadata JSONB
- Indexes on ts DESC, (user_id, ts DESC), (action, ts DESC)
- Run against RDS via temp IP whitelist on `sg-0dc18b0d8cd6972fe`

**Library:** `gunnerteam-api/src/lib/audit.js`
- Single `audit({ action, req, userId, resource, metadata })` function
- Extracts IP from `x-forwarded-for` or `req.socket.remoteAddress`
- Never throws — silently logs errors so audit failure never breaks a request

**Coverage — 33 audit events across 4 route files:**

| File | Events |
|------|--------|
| `routes/auth.js` | `auth.login.success`, `auth.login.failure` (3 reasons), `auth.register`, `auth.invite.sent`, `auth.invite.completed`, `auth.password_reset.requested`, `auth.password_reset.completed`, `auth.admin.profile_updated`, `auth.admin.password_reset`, `auth.admin.role_changed`, `auth.admin.user_deleted` |
| `routes/users.js` | `user.self_updated`, `user.admin_updated`, `user.deleted` |
| `routes/announcements.js` | `announcement.created`, `announcement.deleted` |
| `routes/fleet/index.js` | `fleet.schedule.set/removed`, `fleet.inspection.mandated/submitted/reviewed`, `fleet.vehicle.created/updated/deleted/assigned/unassigned`, `fleet.maintenance.created/updated/deleted/completed`, `fleet.document.uploaded/deleted` |

---

### 2. RDS `publicly_accessible = false`

- Changed `rds.tf`: `publicly_accessible = true → false`
- Also added `Name` tag to `ec2.tf` to prevent Terraform from removing the existing tag on next apply
- Also added `aws_iam_role_policy.ssm_params` to `iam.tf` (see below)
- `terraform apply` completed in ~90 seconds, in-place update (no replacement)

---

### 3. Secrets → AWS SSM Parameter Store

**Problem:** `.env` file at `/home/app/gunnerteam-api/.env` stored all secrets in plaintext on disk.

**Solution:** 22 parameters stored in SSM at `/gunnerteam/dev/<KEY>`:
- 7 SecureString (encrypted): `DB_PASSWORD`, `JWT_SECRET`, `RESEND_API_KEY`, `MONDAY_API_TOKEN`, `COMPANYCAM_API_KEY`, `COMPANYCAM_WEBHOOK_SECRET`, `ANTHROPIC_API_KEY`
- 15 String: DB connection config, port, APNs IDs, S3 buckets, API URL, etc.

**IAM policy** added to EC2 role (`gunnerteam-dev-ec2`):
- `ssm:GetParameter`, `ssm:GetParameters`, `ssm:GetParametersByPath`
- Scoped to `arn:aws:ssm:us-east-2:*:parameter/gunnerteam/dev/*`

**Bootstrap script:** `gunnerteam-api/start.sh`
- Shell script: fetches all 22 params via `aws ssm get-parameter --with-decryption`, exports as env vars, then `exec node src/app.js`
- PM2 now starts `start.sh` instead of `app.js` directly
- `.env` deleted from `/home/app/gunnerteam-api/.env`

---

## EC2 Deployment Learnings

| Fact | Detail |
|------|--------|
| App user | `app` (not `ec2-user`) |
| App directory | `/home/app/gunnerteam-api/` |
| PM2 user | `app` — must use `sudo su - app -c 'pm2 ...'` |
| Deploy method | `scp` to `~/`, then `sudo cp` to `/home/app/gunnerteam-api/src/routes/...` |
| Restart | `sudo su - app -c 'pm2 restart gunnerteam-api'` |
| Logs | `sudo su - app -c 'pm2 logs gunnerteam-api --lines 30 --nostream'` |
| SSM agent | Still showing offline — SSH via key pair is the workaround |

---

## SOC 2 Status After This Session

| Control | Status |
|---------|--------|
| Audit logging (all auth + data mutations) | Done |
| RDS not publicly exposed | Done |
| No plaintext secrets on disk | Done |
| Secrets centrally managed (SSM) | Done |
| Access reviews (periodic role review process) | Not started |
| Incident response policy | Draft exists in [[concepts/incident-response]] |
| Backup restore test | Not done — RDS has 7-day retention |
| Node v22 upgrade | Not urgent until Jan 2027 |

---

### 4. Audit Log Archiver (Lambda + EventBridge)

**Problem:** `audit_logs` table in RDS would grow unboundedly over time.

**Solution:** Annual Lambda job exports prior-year rows to S3, then deletes them from RDS.

**Terraform file:** `terraform/audit-archiver.tf`

| Resource | Detail |
|----------|--------|
| S3 bucket | `gunner-audit-logs-dev` — private, AES256 encrypted, Glacier after 1yr, deleted after 7yr |
| Lambda | `gunnerteam-dev-audit-archiver` — Node 22, 300s timeout, in VPC |
| EventBridge rule | `cron(0 0 1 1 ? *)` — fires Jan 1 midnight UTC |
| IAM role | `gunnerteam-dev-audit-archiver` — S3 PutObject, SSM GetParameter (DB creds), EC2 ENI |
| VPC config | Lambda in default subnets, `audit_archiver` SG |
| VPC endpoints | Interface endpoint for SSM (private DNS), Gateway endpoint for S3 |

**Lambda source:** `terraform/lambda/audit-archiver.js`
- Fetches DB creds from SSM (`/gunnerteam/dev/DB_*`)
- Queries `audit_logs WHERE ts >= YYYY-01-01 AND ts < (YYYY+1)-01-01`
- Writes NDJSON to `s3://gunner-audit-logs-dev/YYYY/audit_logs.json`
- Deletes archived rows from RDS

**Networking issues resolved:**
1. Lambda SG had no inbound rule → SSM Interface endpoint couldn't receive connections → added `self=true` ingress on port 443
2. `ssl: { rejectUnauthorized: true }` failed on RDS internal cert chain → changed to `false` (acceptable, connection stays within VPC)

**Test result:** `{"archived":0}` — connected successfully, no 2025 rows to archive (expected).

---

## Related

- [[gunner/gunnerteam-api-aws-migration]] — main API architecture page (updated this session)
- [[concepts/incident-response]] — IR policy stub
