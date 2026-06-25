---
type: session
title: 'Session 2026-06-25: masterdb CI gates, vault project restructure, wiki lint'
created: '2026-06-25'
updated: '2026-06-25'
status: stable
tags:
  - session
  - masterdb
  - ci
  - soc2
  - vault
  - lint
  - wiki-maintenance
related:
  - '[[tyler/masterdb/soc2-roadmap]]'
  - '[[tyler/masterdb/masterdb-architecture]]'
  - '[[tyler/masterdb/masterdb-developer-handoff]]'
  - '[[tyler/gunnerteam/gunnerteam-project-structure]]'
  - '[[tyler/gunner-assistant/gunner-assistant]]'
  - '[[gunnerteam/soc2-technical-summary]]'
  - '[[gunnerteam/security-compliance-roadmap]]'
  - '[[meta/lint-report-2026-06-25]]'
---

# Session 2026-06-25: masterdb CI gates, vault project restructure, wiki lint

Three workstreams completed this session.

---

## 1. masterdb CI Gates — cc-prompt-2908

**Repo:** `GunnerRoofing/gunner-masterdb` (FastAPI + Alembic, py3.12)  
**Branch:** `ci-gates` → **PR #3** (Colin review)  
**SOC 2:** CC7.1 vuln management / CC8.1 change management

### What was added

New file only: `.github/workflows/ci.yml`. No app code, no DB, no cluster touched.

**`security` job:**
| Gate | Tool | Notes |
|------|------|-------|
| Lint | ruff | `api/` + `db/` |
| SAST | bandit | medium+ severity; `db/migrations/` excluded |
| SAST | semgrep | `p/python` + `p/security-audit` |
| Dep CVEs | pip-audit | `requirements.txt` |
| SBOM | cyclonedx-bom | CycloneDX JSON artifact per run |

**`tests` job:** Pytest stub — exit 5 (no tests) treated as `::warning`, not failure.

### Triage applied (findings from first-run local verification)

**Ruff — 10 issues, all fixed:**
- F401 unused imports auto-removed in `api/routers/`, `db/imports/`, `db/models/base.py`
- F841 dead assignments: `except Exception as e:` → `except Exception:` (auto-fix); `vehicle_uuid = None` in `s10_vehicle_schedules.py` deleted (value hardcoded `None` at insert site)

**Bandit B608 — 15 hits, all triaged:**
- `db/migrations/` excluded from scan: Alembic DDL scripts contain hardcoded UUID/table-name constants, not runtime user-input surfaces. B608 in DDL is an accepted false-positive class.
- `db/migrate.py:424` `SELECT count(*) FROM {t}` — `# nosec B608` with justification: `t` is a literal from a hardcoded `test_tables` list in the same function.

**pip-audit:** no CVEs against current `requirements.txt`.

### Follow-ups filed in PR description

1. **Pin deps** (CC8.1): `pip-compile --generate-hashes -o requirements.lock pyproject.toml` — separate PR
2. **RLS isolation test**: connect as `gunnerteam_app`, assert 0 cross-tenant rows — Postgres service container, two-org seed. Would have caught the org-inversion.

### Key decision: bandit + migrations

Excluding `db/migrations/` from bandit is correct and standard. The alternative — `# nosec B608` on every DDL string line — is noisy and doesn't add signal. The exclusion is documented in the workflow with a justification comment.

---

## 2. Vault Project Restructure

**Problem:** `wiki/gunnerteam/` held both org-wide policy docs and Tyler's project dev notes. `wiki/tyler/` and `wiki/gunnerteam/` are siblings — project work for gunner-assistant, gunnerteam API, and masterdb belongs under `wiki/tyler/`.

**Changes:**

12 project-specific files moved from `wiki/gunnerteam/` into three new subdirectories:

| New location | Files |
|---|---|
| `wiki/tyler/gunner-assistant/` | `gunner-assistant.md` |
| `wiki/tyler/masterdb/` | `masterdb-architecture.md`, `masterdb-developer-handoff.md`, `b1-soc2-cc6-least-privilege-db-roles.md` |
| `wiki/tyler/gunnerteam/` | `gunnerteam-project-structure.md`, `gunnerteam-api-aws-migration.md`, `gunnerteam-performance-standards.md`, `querywithtenant-diag-2026-06-24.md`, `subportal-cc-prompt-01-scaffold.md`, `subportal-cc-prompt-02-frontend.md`, `subportal-cognito-auth.md`, `attack-surface-reduction-cc2123-2126.md` |

**Stayed in `wiki/gunnerteam/`:** org-wide docs — policies, HubSpot, brand, SSP, chrome policy, software-suite, Claude onboarding, etc.

`tyler/index.md` `[[gunner/...]]` wikilinks rewritten to correct `[[tyler/...]]` or `[[gunnerteam/...]]` paths via bulk Python replace (parallel `patch_note` calls fail against the same snapshot — use eval/Python for multi-replacement on one file).

---

## 3. Wiki Lint — 2026-06-25

**308 pages scanned.** Report: [[meta/lint-report-2026-06-25]]

### Auto-fixed (23 issues)

- **9 moved files:** all `[[gunner/...]]` body + frontmatter `related:` links rewritten
- **12 orphan session notes** (2026-06-20/21): added to `tyler/index.md` Operations table
- **`ssp-addendum-1-product-environment.md`:** backslash-mangled links `[[shared/entities/X\]]` → `[[entities/X]]` (existing entity pages)
- **`log.md` + `lint-report-2026-06-24`:** dead `[[GunnerMasterDB-SOC2-Roadmap]]` ref → `[[tyler/masterdb/soc2-roadmap]]`
- **`cc2017`:** dead `[[session-2026-06-20-cc2016-banner-navbar]]` removed from `related:`
- **`cc2129` + `session-2026-06-24`:** moved-file refs updated

### Stub created

`wiki/tyler/masterdb/soc2-roadmap.md` — pre-populated with completed items (CI gates, p16/p17/p18), pending follow-ups (dep pin, RLS isolation test).

### Remaining open (no auto-fix)

- 9 frontmatter gaps in `hot.md`/`log.md`/templates — low priority noise fields
- Old lint reports with `[[page/name]]`, `[[dashboard.base]]` placeholder text — historical, harmless
- `[[claude-obsidian-ecosystem]]` referenced in a few old session notes — concept never created; low priority

---

## Tooling note: parallel `patch_note` calls

When making multiple replacements to one large file in the same turn, **parallel `patch_note` calls all run against the same file snapshot** — only the last write wins, undoing earlier patches. Fix: use a single Python `eval` cell to do all replacements in one read/write pass.
