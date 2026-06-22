---
type: session
title: session-2026-06-20-cc2131-codify-standards-claude-md
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - documentation
  - security
  - soc2
  - standards
  - claude-md
status: stable
related:
  - '[[gunnerteam/attack-surface-reduction-cc2123-2126]]'
  - '[[meta/session-2026-06-20-cc2130-declare-dynamodb-dep]]'
  - '[[gunnerteam/secrets-handling-rules]]'
---

# Session cc-prompt-2131 — Codify the 2026-06 engineering/security standards in CLAUDE.md

Make the conventions established across the hardening arc (cc-2101–2130) durable so every future
Claude Code session builds to them. **Doc-only, NO deploy** (Lambda stays v343). Commit `ba14315`,
file `~/Dev/GunnerTeam/CLAUDE.md`. Caps the cc-2101–2131 block.

## Added
A consolidated **"## Security & Engineering Standards (2026-06 hardening) — cc-2101–2130"** section
near the top (after the cc-prompt workflow), structured into: Secrets (none in env;
`lib/secrets.js`/`getPool`), Auth (Cognito RS256 only; deprovision = delete + `AdminUserGlobalSignOut`
+ `invalidateUserCache`), Tenant isolation (app-level `org_id`; RLS OFF; org-scope guard + isolation
suite; pre-second-tenant role split), Database (TLS verified, never `rejectUnauthorized:false`; inline
`src/migrations.js`; proxy-pin rule), CI gates (npm ci/lockfile, Semgrep + committed taint rule, SBOM,
`npm audit` enforcing, log-hygiene, org-scope, isolation; declare every `@aws-sdk/*`), iOS (pinned
`API.session` + the re-pin-with-Cloudflare warning, ATS defaults, jailbreak report→enforce flag,
`requiresAuth:true`), S3/IAM (PAB + encryption + TLS-only; least-privilege), Infra ownership (Terraform
`gunner-ios` vs SST/Pulumi `gunner-masterdb`; never `terraform import` masterdb; mfa profile; lifecycle
ignore_changes on code), Deploy (file-based routing-config, `[version]` log-stream verify,
canary-before-alias for DB changes), White-label, Lambda-freeze. It **references** the existing detailed
sections rather than duplicating them.

## Superseded (the control changed across the arc)
- The Security-rules + Multi-tenant "raw `query()` for user data = P0 / `query()` bypasses RLS / org_id
  filter is a performance exception" framing → **RLS is OFF (cc-2127); explicit `org_id` is the
  control**; `query()` + `org_id` is correct/preferred; fixed the stale "RLS still required on
  mutations" clause.
- The cc-1505 env-var flow scoped to **config/flag vars only**, with a ⚠️ SUPERSEDED-for-secrets banner:
  secrets are runtime-fetched, never an env var / TF `data "aws_ssm_parameter"` + env line.
- Deploy block: added file-based `--routing-config` + `[version]`-verify note.
- cc-343 block: ⚠️ never dump `Environment.Variables`; verify via `[version]` log-stream + migration
  probe (the old advice dumped `Environment.Variables.DB_HOST`).

## Verify
Balanced code fences (30, even); no residual contradictory phrasing (grep for "bypasses RLS" /
"RLS is still required" / "SecureString for secrets" → none); renders. 657 → 763 lines. Doc-only, no
deploy.

## The cc-2101–2131 hardening arc (recap)
CI/SAST/SBOM (2101), DB TLS (2102), IAM least-priv (2107), S3 CC6.1 baselines (2109/2112), TF mfa
profile (2115), iOS cert-pinning (2116) + jailbreak (2117), HS256 retirement (2118–2122), runtime
secrets + secret-free env (2123/2124), forms auth lockdown (2125), jobId org preflight (2126), RLS
vestige drop (2127), isolation test suite (2128), org-scope CI guard (2129), declared dynamodb dep
(2130), and this codification (2131). Lambda v330 → v343.
