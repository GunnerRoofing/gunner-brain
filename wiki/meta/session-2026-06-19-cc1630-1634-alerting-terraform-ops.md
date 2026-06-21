---
type: session
title: session-2026-06-19-cc1630-1634-alerting-terraform-ops
created: '2026-06-19'
updated: '2026-06-19'
tags:
  - gunnerteam
  - backend
  - terraform
  - alerting
  - soc2
  - ops
status: stable
related:
  - '[[gunnerteam/aws-environment]]'
  - '[[gunnerteam/ssp-addendum-1-product-environment]]'
  - '[[meta/session-2026-06-18-cc864-871-lockfix-ping-consent]]'
---

# Session: cc-1630–1634 — Alerting, Regression Probe, Terraform WORM + VPC Reconcile

**Date:** 2026-06-19  
**Lambda:** v317→v319 live (`gunnerteam-dev-api`, alias `live`)  
**OMP:** updated 16.0.7 → 16.1.6

---

## cc-1630 — Google Chat alerts + Eastern timestamps

### Root cause 1: `postToGoogleChat` was fire-and-forget
`postToGoogleChat(a, state, ...).catch(() => {})` was not awaited. Lambda freezes the execution
context when the handler promise resolves (after the SES email `await`). The unawayted HTTP call to
Google Chat never ran. Fixed: `await postToGoogleChat(...)`. Added at most ~5s to alert processing
(only on state change). `postToGoogleChat` catches its own errors and never re-throws.

### Root cause 2: `OKActions` was empty on all four alarms
All four CloudWatch alarms (`lambda-errors`, `lambda-throttles`, `apigw-5xx`, `security-events`) only
had `alarm_actions`. ALARM→OK state transitions fired no SNS notification. Fixed: added
`ok_actions` and `insufficient_data_actions = [alerts SNS topic]` to all four in `monitoring.tf`.
Applied via Terraform (`4 resources updated`).

### Root cause 3: stale routing-config canary weight
After each deploy, `AdditionalVersionWeights: {N: 0.0}` persisted even when the alias was updated.
SNS continued routing to warm old-version containers. Cleared with explicit JSON
`'{"AdditionalVersionWeights":{}}'`.

**Also:** Eastern timestamp (`fmtET`) was already implemented; `GOOGLE_CHAT_WEBHOOK_URL` was already in
SSM and Terraform; routing config was the delay in verification. **Deployed v319 (Terraform env apply
+ publish).**

**Also:** Email recipient cleaned — `tyler.suffern@gunnerroofing.com` removed from
`ALERT_EMAIL_LIST`; only `admin@gunnerroofing.com` remains. SSM updated + Terraform applied.

---

## cc-1631 — Audit-write timeout verification (closed)

Checked logs across all containers after v314 recycled. Findings:
- All containers now `[318]`/`[319]` — v314 containers last fired 209 min ago (during cc-1630 testing)
- Zero audit timeouts, zero DB timeouts, zero lock contention in runtime logs
- Pattern does not recur: no `DB_POOL_MAX` bump needed

**cc-1631 closed.** The `resolveUser` de-pin (cc-1628) + location forwarder await fix (cc-1629) were sufficient.

---

## cc-1632 — CLAUDE.md: Lambda freeze + secret-handling rules

Two operating conventions codified under "Learned from mistakes" in `CLAUDE.md`:

**Lambda fire-and-forget freeze rule:**
Any async work after `res.json()` resolves is frozen with the Lambda container. Completes only on a
later thaw, with wall-clock elapsed ballooning to minutes. Three occurrences: location single/batch
forward (cc-1629), Google Chat post (cc-1630). Rule: always `await` best-effort side-effects with
`fetchWithTimeout` + swallow. Never leave a dangling `.catch(() => {})` after `res.json()`.

**Secret handling rule:**
`echo`/heredoc/`--value "$(cat ...)"` append a trailing `\n` that silently breaks exact-match and
HMAC comparisons (points-token saga). Always use `read -rs`. Verify with `printf '%s'`. Never dump
`Environment.Variables`; use `LastUpdateStatus` + smoke-test instead.

---

## cc-1633 — Full regression probe

Comprehensive PASS/FAIL across all session fixes. **16/17 PASS.**

| Check | Result |
|---|---|
| `GET /health` | ✅ 200 |
| `POST /auth/validate` | ✅ 200 (auth + resolveUser + DB) |
| API Gateway throttle | ✅ 5000/10000 |
| Lambda VPC | ✅ `vpc-0530...` (prod) |
| Live alias routing | ✅ `null` (no canary) |
| Cognito flows | ✅ SRP + USER_PASSWORD, no secret |
| SNS + ok_actions | ✅ all 4 alarms ok=1 |
| DynamoDB rate-limit | ✅ ACTIVE |
| RDS Proxy | ✅ AVAILABLE×2 |
| Runtime logs clean | ✅ CLEAN |
| Colin P&L SSM param | ✅ exists |
| Audit archiver dry-run | ✅ archived:0, deleted:0 |
| ALARM + RESOLVED email+Chat | ✅ both delivered, Eastern time |
| **Terraform drift** | ⚠️ 11 add / 1 change / 4 destroy |

Terraform drift is fully documented in `RECONCILE-vpc-2026-06-19.md` — all items are codified-but-unapplied resources, not out-of-band console drift.

---

## cc-1634 — Terraform WORM + VPC reconcile

### Tier 1 (applied): S3 WORM + versioning
`aws_s3_bucket_versioning.audit_logs` and `aws_s3_bucket_object_lock_configuration.audit_logs`
applied. GOVERNANCE/7yr + versioning Enabled verified live. **APP-08 WORM is now fully tracked in
Terraform state.** `gunner-audit-logs-dev` bucket has Object Lock enabled.

### Tier 2 (deferred): Archiver schedule
Targeted plan for the three EventBridge/permission resources dragged in
`aws_lambda_function.audit_archiver will be updated in-place`. That update changes the archiver's
`vpc_config` from prod VPC (`vpc-0530...`) to default VPC (`vpc-0eb6...`) — same failure mode as the
cc-1615 API outage. Cannot be isolated until the data source fix (Tier 3) is complete.

### Tier 3 (documented, not applied): VPC reconcile
Root cause: `data.aws_vpc.default` in `main.tf` is hardcoded to `vpc-0eb66556f100c7b3c` (default
VPC). Live archiver, masterdb RDS Proxy, and API Lambda all run in `vpc-0530f022b0273f215` (prod VPC).
VPCs are not peered.

`RECONCILE-vpc-2026-06-19.md` written in `terraform/`. Per-resource inventory:

| Resource | Live state | TF wants | Action |
|---|---|---|---|
| `aws_security_group.audit_archiver` | `sg-0d96e76f471e0d593` in prod VPC | destroy/recreate in default VPC | `state rm` → `import` live SG |
| `aws_security_group.lambda_api` | Not used (API uses pre-existing SG) | phantom in default VPC | `state rm` |
| `aws_lambda_function.audit_archiver` | prod VPC + prod subnets | default VPC subnets — DANGEROUS | fix data source first |
| `aws_cloudwatch_event_rule.audit_archiver` | Live monthly rule exists | must replace | `import` live rule |
| `aws_vpc_endpoint.ssm` | Does not exist | create in default VPC | fix data source or remove |
| `aws_lambda_permission.api_gateway` + `.keep_warm` | Not in TF state | will create | safe to apply independently |

**Single root fix:** rename `data.aws_vpc.default` → `data.aws_vpc.prod` with ID `vpc-0530f022b0273f215`;
hardcode prod private subnets `subnet-004acfd6dbb59a231` / `subnet-0481e68e34ade2858`. Then `state rm` +
`import` for the two SGs and the event rule.

**Maintenance-window commands** filed in `RECONCILE-vpc-2026-06-19.md` (to become cc-1635).
Residual plan: **9 add / 1 change / 4 destroy** — all documented, zero unknown drift.

---

## SOC2 Document Ingest

Ingested two governance documents (via wiki-ingest workflow):
- `GunnerTeam-SOC2-Accomplishments-Summary.md` → `wiki/gunnerteam/soc2-accomplishments-2026-06.md`
- `SSP-Addendum-1-Product-Environment-Controls.md` → `wiki/gunnerteam/ssp-addendum-1-product-environment.md`

Both cross-referenced from `wiki/tyler/concepts/soc2.md`, `wiki/gunnerteam/system-security-plan.md`,
and `wiki/tyler/ciso-track/roadmap.md`.

**SSP Addendum 1 status:** DRAFT — APP-01…APP-09 all implemented & verified; **pending sign-off by
Tyler, Eric, Eddie, Andrew.** This is the #1 standing governance gap.

---

## Current State

### Lambda
- **v319 live** (env update: `GOOGLE_CHAT_WEBHOOK_URL` + `ALERT_EMAIL_LIST` via Terraform apply)
- v317: await fix for `postToGoogleChat`
- v318: same code, stale canary cleared

### Terraform
- `monitoring.tf`: all 4 alarms now have `alarm_actions`, `ok_actions`, `insufficient_data_actions`
- `aws_s3_bucket_versioning.audit_logs` + `aws_s3_bucket_object_lock_configuration.audit_logs`: in state
- Residual: 9 add / 1 change / 4 destroy — all VPC-coupled, documented in `RECONCILE-vpc-2026-06-19.md`

### Pending
- **cc-1635:** VPC reconcile maintenance window (data source fix + state rm/import + targeted apply)
- **SSP Addendum 1 sign-off:** route to Eric, Eddie, Andrew
- **`LOCATION_PING_FORWARD` flag:** off until CT/NJ consent #37 signed
- **`REWARDS_ENABLED=false`:** set true when policy approved
- **Colin service key:** wire to `GET /time/location-compliance`
- **Flip WORM to COMPLIANCE mode** before formal SOC 2 audit (currently GOVERNANCE)
- **`idle_in_transaction_session_timeout = 30000`** on RDS cluster param (pending-reboot window)

### Migrations on prod
`20260618_receipts` (latest) — `gt_receipts` + `gt_receipt_line_items` + indexes

### Key operating conventions (codified in CLAUDE.md cc-1632)
- **Lambda freeze:** always `await` post-response async; never fire-and-forget after `res.json()`
- **Secret handling:** `read -rs`; no `echo`/heredoc; `printf '%s'` to verify; never dump env vars
- **De-pin rule:** hot reads with `org_id` WHERE clause use `query()` not `queryWithTenant()`
- **Env-change flow:** SSM → tf → `terraform plan -target` → apply → publish → alias
- **Routing-config:** always `'{"AdditionalVersionWeights":{}}'` explicit JSON to clear canary
