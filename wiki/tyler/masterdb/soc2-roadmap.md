---
type: decision
title: masterdb SOC 2 Roadmap
created: '2026-06-25'
updated: '2026-06-25'
status: developing
tags:
  - masterdb
  - soc2
  - compliance
  - cc8.1
  - cc7.1
related:
  - '[[tyler/masterdb/masterdb-architecture]]'
  - '[[tyler/masterdb/b1-soc2-cc6-least-privilege-db-roles]]'
  - '[[gunnerteam/soc2-technical-summary]]'
  - '[[gunnerteam/security-compliance-roadmap]]'
---

# masterdb SOC 2 Roadmap

SOC 2 compliance work specific to the `gunner-masterdb` repo (FastAPI + Alembic + Aurora, py3.12).

## Completed

| Item | Control | PR / cc-prompt |
|------|---------|----------------|
| DB role least-privilege (gunnerteam_app RLS) | CC6.3 | p16 / p17 |
| Org-inversion reconcile (69aad261 canonical) | CC6.3 | p17 / cc-2901 |
| CI gates: ruff + bandit + semgrep + pip-audit + SBOM | CC7.1 / CC8.1 | cc-2908 / PR #3 |

## In Progress

| Item | Control | Status |
|------|---------|--------|
| p18 org cleanup | CC6.3 | open PR |

## Pending

| Item | Control | Notes |
|------|---------|-------|
| Pin deps (`requirements.lock`) | CC8.1 | Follow-up to cc-2908; pip-compile --generate-hashes |
| RLS isolation test (Postgres service container) | CC7.1 | Follow-up to cc-2908; assert 0 cross-tenant rows as gunnerteam_app |

> [!gap]
> This stub was created 2026-06-25 from log references. Fill in full roadmap items from `gunnerteam/security-compliance-roadmap.md` as they apply to masterdb specifically.
