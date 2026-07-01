---
type: runbook
title: GunnerTeam — Verify SubPortal Invites (CloudShell)
created: '2026-07-01'
updated: '2026-07-01'
tags: [gunner, gunnerteam, runbook, subportal, cloudshell, invites]
status: stable
source: Gunner Team App/runbooks/runbook-verify-invites-cloudshell.md
related: ["[[gunnerteam/gunnerteam-project-structure]]", "[[index]]"]
---

# Runbook — verify SubPortal invites / crew mapping / devices via CloudShell

_2026-06-30 · CONFIDENTIAL · read-only against PROD masterdb (`sczazkvf`) · reusable for real-sub + prod cutover_

Read-only checks against `gunner_masterdb` on the prod cluster, reached through
`gunnerteam-dev-masterdb-proxy` (named "dev", targets prod). Connect as the app role
`gunnerteam_app` and set the org GUC in-session — these tables are org-RLS-scoped, so reading without
it (or as `postgres`) returns distorted/empty results. Everything here is `ROLLBACK`-only.

Confirmed facts (2026-06-30):
- Proxy host: `gunnerteam-dev-masterdb-proxy.proxy-c52gm8goign8.us-east-2.rds.amazonaws.com`
- App DB: `gunner_masterdb` · role `gunnerteam_app`
- Auth secret: `arn:aws:secretsmanager:us-east-2:980921733684:secret:gunnerteam-app-masterdb-proxy-G9y5dB`
- TLS: `PGSSLMODE=verify-full` with CloudShell's system bundle works (proxy uses a public Amazon CA)
- Org: `69aad261-347c-44db-8e9e-6c25a8509aa3`

## 0. Prereq — VPC CloudShell

Standard CloudShell can't reach the private proxy. Use a **VPC environment** (CloudShell → Actions →
Create VPC environment), region `us-east-2`, VPC `vpc-0530f022b0273f215`, private subnet
`subnet-0481e68e34ade2858`, and a SG the proxy SG `sg-0e3345754d47898b8` allows inbound on 5432 (add a
temporary ingress rule if needed, remove after). `psql` is preinstalled.

## 1. Connect creds (no secrets printed)

```bash
REGION=us-east-2
PROXY_HOST=$(aws rds describe-db-proxies --db-proxy-name gunnerteam-dev-masterdb-proxy \
  --region $REGION --query 'DBProxies[0].Endpoint' --output text)
SECRET_ARN=arn:aws:secretsmanager:us-east-2:980921733684:secret:gunnerteam-app-masterdb-proxy-G9y5dB
S=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --region $REGION --query SecretString --output text)
export PGUSER=$(jq -r .username <<<"$S"); export PGPASSWORD=$(jq -r .password <<<"$S"); unset S
export PGSSLMODE=verify-full PGSSLROOTCERT=/etc/pki/tls/certs/ca-bundle.crt
DBNAME=gunner_masterdb
```

## 2. Checks (edit the email/crew literals per run)

```bash
psql "host=$PROXY_HOST port=5432 dbname=$DBNAME user=$PGUSER" <<'SQL'
BEGIN;
SET LOCAL app.current_org_id = '69aad261-347c-44db-8e9e-6c25a8509aa3';

-- A. invite landed (service-key path => created_by NULL)
SELECT email, role, crew_id, created_by, used, expires_at
FROM   invite_tokens
WHERE  email = '<sub-email>'
ORDER  BY created_at DESC LIMIT 3;

-- B. crew mapping written on accept (feed scopes by this)
SELECT sc.crew_id, sc.crew_member_id, u.email
FROM   gt_subcontractor_crew sc JOIN users u ON u.id = sc.user_id
WHERE  u.email = '<sub-email>';

-- C. device registered (gate BEFORE assigning to a job; else notified=0)
SELECT d.platform, (d.push_token IS NOT NULL) AS has_token, d.updated_at
FROM   user_devices d JOIN users u ON u.id::text = d.user_id
WHERE  u.email = '<sub-email>' AND d.platform = 'apns';

ROLLBACK;
SQL
```

Interpretation:
- **A** — `role=subcontractor`, correct `crew_id`, `created_by` NULL = M2M service-key invite (not human).
- **B** — one row once they accept; before acceptance it's empty (expected).
- **C** — `has_token=t` before you tell Colin to assign the crew.

## 3. What you can't read here

`audit_log` — `gunnerteam_app` is **INSERT-only** on it by design (least privilege). The
`webhook.project_crew_assigned` `notified` count lives there; confirm `notified ≥ 1` instead via
Colin's webhook 200 response + the real device receiving the push. Only escalate to the master secret
(`…MasterDbProxySecret-mueddfoa…`, first entry in the proxy Auth list) if you truly need to read
`audit_log`, and keep it read-only.

## 4. Cleanup

```bash
unset PGPASSWORD PGUSER
# remove any temporary proxy-SG ingress you added
```

Never echo `PGPASSWORD`, the secret JSON, or any token. Keychain/Keeper are the only durable homes for creds.
