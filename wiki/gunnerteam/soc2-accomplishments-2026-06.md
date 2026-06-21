---
title: SOC 2 Accomplishments — June 2026 Session
type: gunner
tags:
  - soc2
  - compliance
  - governance
  - gunnerteam
  - reliability
created: '2026-06-19'
updated: '2026-06-19'
status: stable
related:
  - '[[gunnerteam/ssp-addendum-1-product-environment]]'
  - '[[gunnerteam/system-security-plan]]'
  - '[[gunnerteam/aws-environment]]'
  - '[[gunnerteam/soc2-technical-summary]]'
  - '[[tyler/concepts/soc2]]'
---

# SOC 2 Accomplishments — June 2026 Session

**Period:** 2026-06-18 → 2026-06-19  
**Scope:** GunnerTeam product environment (iOS app + AWS backend)  
**Delivered as:** `cc-prompt-16xx` specs executed in Claude Code. No secrets in this document.

---

## Controls implemented (APP-01…APP-09)

All mapped in [[gunnerteam/ssp-addendum-1-product-environment]]. Net movement:

- **CC7 (operations/monitoring):** near-zero → genuinely operating
- **CC8 (change management):** near-zero → codified
- **CC6 (access/crypto), C1 (confidentiality), A1 (availability):** strengthened

---

## Reliability & incident fixes

### Production incident #1 — company-wide login outage
Two stacked bugs: API Gateway throttle set to **0/0** (429 on everything) and Lambda ejected from the prod VPC to the default VPC (couldn't reach the DB). Restored live, then codified:
- **cc-1614:** throttle pinned in `api-gateway.tf`
- **cc-1615:** `vpc_config` pinned to prod VPC in Terraform

### Production incident #2 — DB connection starvation
`audit_log` writes timing out (up to 47s) from RDS Proxy connection exhaustion. Root causes: `resolveUser` pinning the proxy on every auth request + a Lambda fire-and-forget freeze on the location forwarder holding containers for minutes.
- **cc-1628:** de-pinned `resolveUser` (`queryWithTenant`→`query()`, `org_id` filtered explicitly)
- **cc-1629:** location forward awaited with short timeout (no freeze)
- **cc-1631:** audit writes given dedicated 8s timeout + verified clean (zero timeouts on current containers)

### Change-management hardening
- **cc-1620:** read-only divergence report confirmed Terraform reconciled except `source_code_hash`
- **cc-1621:** `lifecycle.ignore_changes = [source_code_hash, filename]` — Terraform owns env/vpc/config and **never touches code**. An env-change `terraform apply` can no longer revert code or take prod down. Safe 5-step env-change flow established.

### Integrations completed
- **Points webhook (GunnerCam → GunnerTeam):** HMAC was verified over the parsed body instead of raw bytes — **cc-1626** fixed it (`req.rawBody` + `trust proxy`). Confirmed awarding (40 pts to a real user). Colin owns point values in the signed payload (cc-1618).
- **Receipt → P&L push:** turned live (cc-1622) after Colin's endpoint shipped — first use of the new safe env-change flow.
- **Location forwarding:** Colin fixed the `/location-pings` auth scope; forwarder hardened (cc-1629). Now `200` in <500ms.

### Alerting quality
- Branded color-coded emails (cc-1616/1617)
- IAM Identity Center (SSO) deep link to the alarm (cc-1619)
- Fixed a `buttonUrl` bug + restored an accidentally-deleted SNS subscription (cc-1625)
- **Google Chat** delivery + **Eastern-time** timestamps (cc-1630); had to `await postToGoogleChat` — Lambda froze the container before the HTTP call completed (fire-and-forget anti-pattern)
- Added `ok_actions`/`insufficient_data_actions` — RESOLVED notifications now fire

---

## Operating conventions established

| Convention | Detail |
|---|---|
| **Env-change flow** | SSM → `lambda-api.tf` → `terraform plan -target` (env-only) → apply → publish → alias. Code ships via S3 deploy block; Terraform ignores code. |
| **De-pin rule** | Hot reads filtering `org_id` explicitly use `query()`, not `queryWithTenant` (avoids RDS Proxy pinning) |
| **Lambda freeze rule** | Never fire-and-forget async after the handler resolves — `await` it (short timeout + swallow). See: `postToGoogleChat` bug (cc-1630), location forwarder (cc-1629). |
| **Secrets** | Set via `read -rs` (never `echo`/heredoc — trailing newline); never dump Lambda env vars |
| **Routing-config** | Always `'{"AdditionalVersionWeights":{}}'` explicit JSON to clear canary weight; shorthand is silently a no-op |

---

## Governance artifacts produced

| Artifact | Location | Status |
|---|---|---|
| SSP Addendum 1 | [[gunnerteam/ssp-addendum-1-product-environment]] | DRAFT — pending sign-off |
| App-suite security handoff | Prior session doc | Filed |
| Logging standard | Repo `CLAUDE.md` | Live |
| Retention policy | APP-08 evidence + wiki | Live |

---

## SOC 2 finish line (non-code)

1. **Sign** the SSP, AUP, and SSP Addendum 1 — route to Eric + the owners — **#1 standing gap**
2. **Stand up a compliance platform** (Drata/Vanta) to start the Type II evidence clock — auto-collects from AWS / Google Workspace / Hexnode already in place
3. **Rotate** dev secrets exposed in-terminal during the incidents, at the prod cutover
4. **Document product DR** (Aurora/S3 backup + tested restore) for the Availability criterion
5. **True dev/prod split** (the "dev" Lambda currently serves prod data) — a go-live task
