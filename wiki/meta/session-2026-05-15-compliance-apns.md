---
title: "Session 2026-05-15 (cont.) — Compliance Audit Fixes, Legacy EC2 Destroy, APNs Fix"
type: session
tags: [session, gunner, aws, terraform, compliance, apns, soc2]
created: 2026-05-15
updated: 2026-05-15
status: stable
sources: []
related:
  - "[[gunner/gunnerteam-api-aws-migration]]"
  - "[[gunner/tls-cutover-2026-05-14]]"
  - "[[vendors/companycam]]"
  - "[[gunnerteam/system-security-plan]]"
  - "[[meta/session-2026-05-15-photo-comments]]"
---

# Session 2026-05-15 (cont.) — Compliance Audit Fixes, Legacy EC2 Destroy, APNs Fix

Continuation of 2026-05-15 session. Previous segments: [[meta/session-2026-05-15-photo-comments]] (photo comments v1+v1.1, Lambda PC), [[meta/session-2026-05-15-co-upload-fix]] (CO upload fix, Terraform branch-mismatch).

---

## Wiki Lint Fixes (C1, C3, S9)

**C1 — escaped pipes in entity wikilinks** (`\|` → `|`):
- `wiki/gunner/environment.md` — lines 38–39, 140–142 (system info table, admin access table)
- `wiki/gunner/system-security-plan.md` — lines 39–40, 55–56 (system info table, roles table)
- `wiki/runbooks/incident-response.md` — lines 55, 71, 76 (notification steps in Procedures 2 and 3)

**C3 — bad frontmatter path:**
- `wiki/runbooks/monday-pm-my-work-view-setup.md` line 12: `'[[wiki/gunner/environment.md]]'` → `'[[gunner/environment]]'`

**S9 — escaped pipe in canvas link:**
- `wiki/index.md` line 133: `[[canvases/main.canvas\|main]]` → `[[canvases/main.canvas|main]]`

**C2** — confirmed false positives: all occurrences of `[[comparisons/claude-obsidian-ecosystem]]` in lint reports are inside backtick code spans, not real wikilinks. No changes needed.

---

## Compliance Audit

Full compliance audit of `gunnerteam-api/src/`, `GunnerForms/GunnerTeam/`, and `terraform/` run by a background agent (read-only). Report filed at `/Users/tyler.suffern/Documents/Claude/Projects/Gunner Team App/compliance-audit-2026-05-15.md`.

### Key Findings

| Priority | Finding | File:Line | Status |
|---|---|---|---|
| P0 🚨 | EC2 `user_data` contained `db_password` + `jwt_secret` readable from IMDS (IMDSv1) | ec2.tf:18–26 | ✅ Resolved — EC2 destroyed |
| P0 🚨 | CompanyCam webhook `UPDATE users SET device_token = NULL` unscoped — could clear wrong tenant's token | companycam.js:52 | Open |
| P1 🚨 | GET `/forms/get-users` returned all employee emails to unauthenticated callers | forms.js:224 | ✅ Resolved — maybeAuth added |
| P1 🚨 | `audit_archiver` Lambda log group auto-created with infinite retention | audit-archiver.tf | ✅ Resolved — 365d via AWS CLI; TF resource in PR2 |
| P2 ⚠️ | GET `/fleet/documents/:docId/view` — no ownership check on sequential docId; no audit log | fleet/index.js:984 | Open |
| P2 ⚠️ | POST `/forms/` and POST `/forms/submit-ap` fully anonymous | forms.js:33,65 | Open (backlog #33) |
| P3 ⚠️ | CompanyCam webhook user lookups unscoped — wrong-tenant push possible | companycam.js:35,77 | Open |
| P3 ⚠️ | `rejectUnauthorized: false` on RDS SSL | lib/db.js:9 | Open |
| P4 | Webhook dedup runs before HMAC verification | companycam.js:369 | Open |
| P4 | APNs `APNS_KEY_PATH` env var unset in Lambda | apns.js:8 | ✅ Resolved (APNs fix) |

**Secrets scan: clean.** No hardcoded keys anywhere. HMAC verification solid on both webhook handlers.

---

## PR 1 — Destroy Legacy EC2 + ALB (`chore/destroy-legacy-ec2-alb`)

EC2 was stopped 2026-05-14 after Lambda migration; Lambda/API Gateway had been stable for 24+ hours. Eliminated P0.1 (IMDS plaintext secrets) without secret rotation.

### Resources Destroyed

| Resource | AWS ID |
|---|---|
| `aws_instance.api` | i-0448d430b169b0ff5 |
| `aws_eip.api` | eipalloc-0064d870cafe319a5 |
| `aws_lb.api` | gunnerteam-dev-api ALB |
| `aws_lb_listener.https` | Port 443 |
| `aws_lb_listener.http_redirect` | Port 80 → 301 |
| `aws_lb_target_group.api` | gunnerteam-dev-api TG |
| `aws_lb_target_group_attachment.api` | EC2 attachment |
| `aws_security_group.alb` | sg-0c06ad94c018d038d |
| `aws_security_group.api` | sg-07790fe3c3e2341b9 |

SG deletion required a 2-step apply — AWS holds ENI cleanup open until dependent SG rules are explicitly removed first.

### Config Changes

- `alb.tf` deleted entirely. ACM cert + `aws_acm_certificate_validation` + `cloudflare_record.acm_validation` + `data.cloudflare_zone.gunnerroofing` + `cloudflare_record.api` (api.team → API Gateway) moved into `api-gateway.tf`. Resource addresses unchanged — no state disruption.
- `ec2.tf` deleted entirely.
- `sg.tf`: removed `aws_security_group.api` and the two ingress rules referencing it (`audit_archiver` SG and `rds` SG).
- `outputs.tf`: removed `api_ip` and `api_url` (both referenced `aws_eip.api`).

**Health confirmed:** `https://api.team.gunnerroofing.com/health` returns 200 throughout. DNS unchanged — `api.team` CNAME → API Gateway regional domain (was updated during TLS cutover 2026-05-14).

**Apply blockers:** Cloudflare IPv6 token restriction blocked full `terraform plan` (same issue as before). Used `-target` for all AWS resources. Cloudflare records have no changes — just file moves.

### Key Architecture Fact Post-PR1

> The API stack is now **Lambda-only**. No EC2. No ALB. Traffic: Cloudflare DNS → API Gateway → `aws_lambda_alias.api_live` (provisioned concurrency = 2) → Express app.

---

## PR 2 — Compliance Audit P1 Fixes (`fix/compliance-audit-findings-p1`)

Branch off main. **Not yet merged** — terraform import for log group blocked until PR1 is merged (removes `alb.tf`/`data.cloudflare_zone` which blocks Terraform from main due to IPv6 token issue).

### Change 1: GET /forms/get-users — maybeAuth

`gunnerteam-api/src/routes/forms.js:224` — added `maybeAuth` middleware to `GET /forms/get-users`.

Route was fully unauthenticated and returned all Monday.com user names + emails to any caller. Added comment noting backlog #33: restore `requireAuth` when forms-only iOS build is decommissioned.

Pattern matches the existing `maybeAuth` routes: `/submit-co`, `/upload`, `/search-projects`.

### Change 2: audit-archiver CloudWatch log group

`terraform/audit-archiver.tf` — added `aws_cloudwatch_log_group.audit_archiver` with `retention_in_days = 365`.

The log group was auto-created by Lambda with `null` (infinite) retention. Fixed immediately via:
```
aws logs put-retention-policy \
  --log-group-name /aws/lambda/gunnerteam-dev-audit-archiver \
  --retention-in-days 365
```
Retention confirmed 365 in AWS. Terraform resource will be imported after PR1 merges.

---

## APNs Fix — Backlog #11 (`fix/apns-key-from-ssm`)

**Root cause:** `apns.js:getProvider()` checked for `process.env.APNS_KEY_PATH` which was **never set in the Lambda config**. Guard failed, `getProvider()` returned `null`, all push notifications silently no-op'd.

The Lambda config (`lambda-api.tf`) had `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_BUNDLE_ID`, `APNS_PRODUCTION` but no file system path was ever set — Lambda has no persistent disk.

**Fix:**

`apns.js` — removed `path` import; changed guard to check `APNS_KEY_CONTENT`; passes `Buffer.from(keyContent)` to `token.key` (node-apn accepts Buffer as PEM):

```js
const keyContent = process.env.APNS_KEY_CONTENT;
if (!keyContent || !process.env.APNS_KEY_ID || !process.env.APNS_TEAM_ID) {
  console.error('[APNs] Missing env vars ...');
  return null;
}
provider = new apn.Provider({
  token: {
    key:    Buffer.from(keyContent),
    keyId:  process.env.APNS_KEY_ID,
    teamId: process.env.APNS_TEAM_ID,
  },
  production: process.env.APNS_PRODUCTION === 'true',
});
```

`lambda-api.tf` — added SSM lookup + env var:

```hcl
data "aws_ssm_parameter" "apns_key_content" {
  name = "/${var.app_name}/${var.env}/APNS_KEY_CONTENT"
}
# ...in environment.variables:
APNS_KEY_CONTENT = data.aws_ssm_parameter.apns_key_content.value
```

`APNS_KEY_CONTENT` already existed in SSM as SecureString with correct PEM content and real newlines. The `.p8` key file is at `/Users/tyler.suffern/Downloads/AuthKey_GQU6KYB57D.p8`.

**Deployed:** Merged to main, `terraform apply -target=aws_lambda_function.api ...`. Lambda version 5, alias `live` updated, provisioned concurrency re-warmed.

**Smoke test path:** Post an announcement OR have a manager review an inspection Monday. Then:
```
aws logs tail /aws/lambda/gunnerteam-dev-api --since 5m --filter-pattern "APNs"
```
Success = no `[APNs] Missing env vars`, no `[APNs] failed`. A `stale` return on first push = old device token in DB (expected — stale-token clear path works correctly).

**Note:** `APNS_KEY_PATH` SSM parameter left in place until confirmed nothing else references it.

---

## Open Items After This Session

| Item | Status |
|---|---|
| PR1 (`chore/destroy-legacy-ec2-alb`) | Pushed, applied to AWS. Needs PR + merge on GitHub |
| PR2 (`fix/compliance-audit-findings-p1`) | Pushed. Merge after PR1 lands; then `terraform import + apply` for log group |
| APNs smoke test | Trigger Monday (announcement or inspection review) |
| CompanyCam 401 | Key likely revoked — get current key from Colin, `ssm put-parameter --overwrite` |
| CompanyCam webhook unscoped queries (P0.2) | companycam.js:35,52,77 — scope to tenant before next CompanyCam feature work |
| Fleet docs ownership check (P2) | fleet/index.js:984 — add `queryWithTenant` ownership check + audit log |
| Account-Owned Cloudflare API token | Replace personal IPv6-restricted token; unblocks full `terraform plan` without -target |
| Terraform import: audit_archiver log group | After PR1 merged: `terraform import aws_cloudwatch_log_group.audit_archiver /aws/lambda/gunnerteam-dev-audit-archiver` |
