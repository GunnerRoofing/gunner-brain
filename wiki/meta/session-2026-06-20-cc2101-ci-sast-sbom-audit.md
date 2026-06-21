---
type: session
title: session-2026-06-20-cc2101-ci-sast-sbom-audit
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - ci
  - security
  - soc2
  - semgrep
  - sbom
  - npm-audit
status: stable
related:
  - '[[gunnerteam/aws-environment]]'
  - '[[meta/session-2026-06-19-cc1500-1505-terraform-infra-hardening]]'
---

# Session cc-prompt-2101 — CI: Semgrep SAST + SBOM + enforce npm audit

**Block 2100–2199 (SOC 2 hardening). CC8.1 (SDLC controls), CC7.1 (vuln detection).**
CI-only, no Lambda deploy. File: `.github/workflows/ci.yml` (monorepo `~/Dev/GunnerTeam`).
**PR #6** (https://github.com/GunnerRoofing/gunner-ios/pull/6), branch `cc-2101-sast-sbom-audit`.

## What shipped

- **Phase 1 — SAST:** new parallel `sast` job: setup-python 3.12 → `pip install semgrep`
  → `semgrep scan --config .semgrep --config p/javascript --config p/nodejs
  --config p/owasp-top-ten --config p/secrets --error --severity ERROR gunnerteam-api/src`.
- **Phase 2 — SBOM:** `backend` job generates CycloneDX SBOM (`@cyclonedx/cyclonedx-npm`)
  after `npm ci`, uploads as `sbom` artifact (upload-artifact@v4).
- **Phase 3 — audit enforcing:** removed `|| true` from the `npm audit --audit-level=high`
  step. Build now fails on new high/critical.

## Key gotcha — Semgrep anonymous packs miss the command-injection rule

The prompt's packs (p/javascript, p/nodejs, p/owasp-top-ten, p/command-injection) do
**NOT** bundle the `child_process` exec-sink rule when run anonymously — that taint
analysis is **Semgrep Pro / login-gated**, and CI has no login. So the prompt's config
alone scored **0 findings** on the required `child_process.exec(req.query.x)` probe — the
gate would have been a no-op. The single registry rule
`r/javascript.lang.security.detect-child-process.detect-child-process` IS ERROR and catches
it, but relying on registry contents is the exact fragility that bit us.

**Fix:** committed a local rule **`.semgrep/command-injection.yml`** (severity ERROR,
`mode: taint`, sources `req.query/params/body/headers` → sinks `exec/execSync/spawn/spawnSync`)
and added `--config .semgrep` to the sast step. Deterministic, offline, version-controlled,
travels with the repo. Our real `src` has zero `child_process` usage → baseline stays green.

## Phase 3 dependency triage (3 high + 3 moderate → 0)

CI gate is `npm audit --audit-level=high` (incl dev), not `--omit=dev`. Findings:
- **HIGH multer 1.0.0–2.1.1** (×2 DoS) → `npm audit fix` → 2.2.0 (non-breaking, within ^2.0.0).
- **HIGH node-forge ≤1.3.3** (×4) via `@parse/node-apn` ≤7.1.0 → bumped node-apn ^7.1.0→^8.1.0,
  which pulls node-forge 1.4.0. **node-apn 8.0's ONLY breaking change = drops Node 18**
  (GitHub release notes); we run Node 20 in CI + Lambda. API surface in `src/lib/apns.js`
  (`apn.Provider({token})`, `apn.Notification`, `.alert/.contentAvailable/.pushType`, `p.send`)
  unchanged — verified check + tests + module-load smoke.
- moderate qs/brace-expansion cleared by audit fix (below the gate anyway).
Result: `npm audit` 0 vulnerabilities. No accepted-risk entries needed.

## Verification (real CI, PR #6)

1. Clean commit → **backend + sast green**; `sbom` artifact attached (57 KB).
2. Pushed `child_process.exec(req.query.x)` probe → **sast FAILED** (exit 1), backend green —
   end-to-end proof the gate works. Reverted via `git reset --hard` + `--force-with-lease`
   (probe never remains in PR history).
3. Post-revert run → **both green** again.

## Reusable facts / gotchas

- Semgrep only scans **git-tracked** files — `git add` a probe before testing locally or it's skipped.
- `github` tool `pr_create` defaulted `head` to `main` (failed); used `gh pr create --head <branch>` directly. `gh` is authed as tylersuffern (keyring).
- Branched from **origin/main** (not local main) — local main has 4 unpushed iOS commits
  (cc-2012/2013/2014 + await fix, all GunnerForms/) that should NOT enter this CI PR.
- Local dev machine is Node 26 → harmless EBADENGINE warning for node-apn (wants 20||22||24);
  CI + Lambda are Node 20, satisfied.
- Benign CI annotation: actions/checkout/setup-node/upload-artifact target Node 20, forced to
  Node 24 on runners (GitHub deprecation notice, not a failure).

## Open / follow-up

- PR #6 left **open** for review (CLAUDE.md PR flow), not merged.
- 4 iOS commits still local-only on `main` (unpushed).
