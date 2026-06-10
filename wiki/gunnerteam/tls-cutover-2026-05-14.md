---
title: TLS Cutover — 2026-05-14
type: gunner
status: current
tags: [gunner, infrastructure, soc2, aws]
created: 2026-05-14
updated: 2026-05-14
sources: []
related:
  - "[[gunner/gunnerteam-api-aws-migration]]"
  - "[[gunner/aws-environment]]"
  - "[[meta/session-2026-05-14-soc2-phase1]]"
---

# TLS Cutover — 2026-05-14

## What Changed

- **EC2 recreated:** new instance `i-0448d430b169b0ff5` (was `i-002be9ba8cdfbf0da`), EIP `3.134.224.29` preserved
- **API endpoint:** `https://api.team.gunnerroofing.com` (was `http://3.134.224.29:3000`)
- **ALB live:** `gunnerteam-dev-api-1626452472.us-east-2.elb.amazonaws.com`, TLS 1.3, HSTS preload-ready
- **Cloudflare CNAME:** `api.team` → ALB, `proxied=false`
- **EC2:** AL2023 standard AMI `ami-02c52e9d651de2504`, Node 20.20.2, pm2 online at `*:3000`
- **RDS:** untouched, `db-OY6B7O276NF5NCDY3HXPIIQ7R4`
- **Branch:** `main` is now canonical (was iOS-forms-only); `feature/tls-alb` and `feature/gunner-assistant` fully merged

## SSM Parameter Store (`/gunnerteam/dev/`)

- All existing secrets (`DB_*`, `JWT_SECRET`, `APNS_*`, etc.) present and carried over
- Three new parameters added for GitHub App deploy auth:
  - `GH_APP_ID`
  - `GH_APP_INSTALLATION_ID` — `132419976`
  - `GH_APP_PRIVATE_KEY`
- `API_BASE_URL` = `https://api.team.gunnerroofing.com` — set but not yet consumed (`start.sh` not wired to pm2 env)

## Open Issues

1. **SSM Session Manager broken** — VPC endpoint SG does not allow the new EC2 SG; SSM agent cannot authenticate to SSM API. Current access path: SSH via EC2 Instance Connect.
2. **SSH:22 open to `0.0.0.0/0`** — must be closed once SSM Session Manager is working (bundle with issue 1).
3. **Cloudflare API token** — Tyler's personal admin token in use; needs replacement with an Account-Owned token scoped to `Zone:DNS:Edit` on `gunnerroofing.com`.
4. **`start.sh` not wired to pm2** — app still reads `.env` written by `user_data` at boot, not SSM at runtime.
5. **pm2 systemd unit incomplete** — `pm2 startup` command fails silently; app restart on reboot not guaranteed.
6. **2 high-severity npm audit findings** — deferred.

## Pending Work (Priority Order)

1. Fix SSM VPC endpoint SG + close SSH:22 (bundled)
2. Access review + IR policy docs (SOC 2, documentation only)
3. APNS dev → prod switch
4. CI/CD pipeline (GitHub Actions)
5. D1 → RDS data migration (largest remaining item)
6. Re-invite users on new DB (depends on migration)

## SOC 2 Controls Completed This Cutover

| Control | Description |
|---------|-------------|
| CC6.1 | GitHub App replaces user-tied PAT |
| CC6.7 | ALB + ACM TLS, HSTS preload, TLS 1.2+ policy |
| CC7.2 | `audit_logs` records `req.ip` (real client IP via `trust proxy`) |

See [[meta/session-2026-05-14-soc2-phase1]] for Phase 1 context (audit logging, RDS hardening, secrets to SSM).
