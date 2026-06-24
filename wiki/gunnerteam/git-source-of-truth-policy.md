---
type: policy
owner: tyler
app: GunnerTeam
created: '2026-06-15'
updated: '2026-06-19'
status: active
tags:
  - process
  - deploy
  - git
  - policy
  - soc2
title: Git Source of Truth Policy
---

# Git is the Source of Truth — Deploy Policy

Effective 2026-06-15. Issued after the postmortem from the v233 deploy incident (login/jobs/points all failing due to three parties deploying to the same Lambda without git as the single source of truth).

> Canonical docs (also filed in wiki):
> - [[CONTRIBUTING]] — branching, deploy steps, everything-in-IaC
> - [[CLAUDE_CODE_RULES_ONBOARDING]] — what Claude enforces
> - [[CHANGE_MANAGEMENT_POLICY]] — approvals, audit trail, emergency changes (SOC 2)
> - [[POSTMORTEM-2026-06-15]] — what broke and why

---

## The Rule

> **What is deployed must equal what is committed.**

Every change — code, config, infra, DB — originates in git and reaches production through a reviewed, git-based deploy. No exceptions except emergencies (see below).

---

## What Changed

### For all engineers (internal + contractors)

| Old (wrong) | New (required) |
|---|---|
| Direct edits to running Lambda | Branch → PR → review → merge → deploy from `main` |
| Deploying an unreconciled local tree | Reconcile with live first (`cc-770` pattern: download, diff, merge) |
| Console / CLI infra changes | Lambda env vars via SSM + `terraform apply`; infra via Terraform/SST |
| Hand-patching deployed artifact | Emergency only — log it, back-port to git same day |
| Direct commits to `main` | Never. All changes via PR with one review. |

### For external contractors (Colin / Project Hub)

- **Do not change or patch GunnerTeam's deployed Lambda or AWS resources directly.**
- Anything touching shared infrastructure (masterdb cluster, RDS Proxies, shared secrets) must be made in the repo that owns it, by its owner, coordinated in writing first.
- Mirror these conventions into a `CLAUDE.md` in `WL-CompanyCam` — our `CLAUDE.md` doesn't reach your Claude automatically.

---

## Deploy Procedure

1. Work on a feature branch.
2. Open a PR. Get one review. Merge to `main`.
3. Deploy **only** from clean, reviewed `main` using the canonical block in `CONTRIBUTING.md`:
   ```bash
   cd ~/Dev/GunnerTeam/gunnerteam-api
   zip -r /tmp/function.zip . --exclude "*.git*"
   aws s3 cp /tmp/function.zip s3://gunnerteam-lambda-deploy-useast2/function.zip --profile mfa
   aws lambda update-function-code \
     --function-name gunnerteam-dev-api \
     --s3-bucket gunnerteam-lambda-deploy-useast2 \
     --s3-key function.zip \
     --region us-east-2 --profile mfa
   # publish + update alias after code propagates
   ```
4. Publish a version and update the `live` alias.

---

## Config / Infra as Code

- Lambda env vars: set in SSM Parameter Store, sourced from there by Terraform. Never set directly in the Lambda console (they won't survive the next `terraform apply`).
- RDS Proxies, security groups, IAM roles: owned by the stack that created them (Colin's SST masterdb stack or `terraform/lambda-api.tf`). Coordinate before touching.
- `DB_HOST` in `/gunnerteam/dev/DB_HOST` SSM = the proxy endpoint. `terraform apply` reads from SSM.

---

## Emergency Procedure

If a deploy must happen outside the normal flow during an outage:
1. Make the minimal fix directly (console / CLI).
2. **Log it immediately** — message the team with what changed and why.
3. **Back-port to git the same day** — open a PR with the exact change, merge it, and redeploy from `main` to confirm parity.
4. Record in `CHANGE_MANAGEMENT_POLICY.md` audit trail (required for SOC 2).

> Never leave production in a state where git doesn't reflect what's running. Even one hour of drift is enough to cause the next incident.

---

## Claude Code Integration

Rules live in `CLAUDE.md` in the repo. Pull `main` and your Claude picks them up automatically. Guard hooks in `.claude/settings.json`.

Key guardrails Claude enforces:
- Never log `_PASSWORD`, `_SECRET`, `_KEY`, `_TOKEN`.
- Never run `get-function-configuration --query 'Environment.Variables'`.
- Never deploy from an unreconciled tree.
- Migrations inline in `src/lambda.js` only — no SQL files.
- RDS Proxy: no `statement_timeout` or `options` startup params in Pool config (proxy rejects them).

---

## Background: What Broke (2026-06-15 Incident)

Three parties (Tyler session A, Tyler session B, Colin) deployed to `gunnerteam-dev-api` alias `live` without coordination:
- Session A deployed cc-751 fan-out elimination (v225).
- Colin patched the pool config for RDS Proxy directly in the console (v233).
- Session B deployed timing/hubspot changes on top.
- Result: each deploy clobbered the previous party's changes; proxy broke; login/jobs/points failed.

Resolution required downloading the live bundle, diffing all changed files, and hand-reconciling before the next safe deploy (see `POSTMORTEM-2026-06-15.md` and cc-770 diff report).

---

## Related

- [[masterdb-architecture]]
- [[tyler/hot]]
- [[shared/decisions/README]]
- `CONTRIBUTING.md` in repo
- `CHANGE_MANAGEMENT_POLICY.md` in repo
