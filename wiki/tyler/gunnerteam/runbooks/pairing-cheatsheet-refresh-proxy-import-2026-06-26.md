---
type: runbook
title: GunnerTeam — SST Refresh + Proxy Import Cheat-Sheet
created: '2026-06-29'
updated: '2026-06-29'
tags: [gunner, gunnerteam, runbook, sst, proxy, iac]
status: stable
source: Gunner Team App/runbooks/pairing-cheatsheet-refresh-proxy-import-2026-06-26.md
related: ["[[gunnerteam/gunnerteam-project-structure]]", "[[index]]"]
---

# Pairing cheat-sheet — sst refresh + proxy import (keep open during the session)

## Write 1 — `sst refresh --stage production`
Colin shows the **preview first.** It should adopt ONLY the known out-of-band drift:
- `maxCapacity` → 8
- the 3 param-group params (`shared_preload_libraries`, `pgaudit.log`, idle-txn timeout)
- `enabledCloudwatchLogsExports = ['postgresql']`

**STOP if the refresh preview wants to touch anything else** — SG rules, instance class, engine version, encryption/KMS, `DeletionProtection`, cluster identifier, subnets. Anything beyond the four above = investigate before applying.

## Write 2 — proxy import
- Gate fix: `$app.stage === 'dev'` → so it instantiates for **prod**.
- `sst import` the LIVE proxy / target-group / role / SG.
- **Watch the role reconcile:** must map to the live role `GunnerteamDevMasterdbProxyRole` — **STOP if the plan wants to CREATE a role/proxy** (that means the import didn't match → a deploy would duplicate it).
- Then confirm config has: `requireTls: true`, the `gunnerteam_app` 2nd auth, `GunnerteamLambdaSgId = sg-06313256b581ef39a`.

## Your task — `pg_stat_activity` (before any SG rule change)
In-VPC CloudShell, connected as **master** (`postgres`) so you see all `client_addr`:
```sql
SELECT datname, usename, client_addr,
       count(*) AS conns,
       array_agg(DISTINCT application_name) AS apps
FROM pg_stat_activity
WHERE client_addr IS NOT NULL
GROUP BY datname, usename, client_addr
ORDER BY conns DESC;
```
- Each distinct `client_addr` = a real consumer. Map each IP → its subnet/SG — **that's the explicit allowlist Colin adds to config before dropping the broad `10.0.0.0/16` rule.**
- ⚠️ `pg_stat_activity` only shows CURRENTLY-connected sessions — **run it 2–3× spaced out** to catch intermittent consumers (a periodic job won't show if idle at one sample). Absence ≠ no consumer.
- This is how we finally answer "where does `ops_app` connect from." Hand Colin the consumer list.

## Then — NOT in this session
- Colin folds the SG allowlist + drops the broad rule in config.
- `sst diff` → calibrated no-op (no recreates; only the accepted 7.20 metadata + `=false` arg-sets + build noise).
- **Deploy** in a consumer-aware window — gated on Eddie's cost-allocation-tag answer (`sst:app`/`sst:stage` active? → if yes, re-add in config first).
