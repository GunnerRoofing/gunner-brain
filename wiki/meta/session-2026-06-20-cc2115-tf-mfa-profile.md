---
type: session
title: session-2026-06-20-cc2115-tf-mfa-profile
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - infra
  - terraform
  - mfa
  - soc2
  - tooling
status: stable
related:
  - '[[meta/session-2026-06-20-cc2109-s3-baseline]]'
  - '[[meta/session-2026-06-20-cc2111-state-versioning-force-ssl]]'
---

# Session cc-prompt-2115 — Pin TF backend + provider to the mfa profile (CC6.1)

Make terraform honor MFA durably instead of relying on a per-invocation `AWS_PROFILE=mfa` that
people forget. Commit `b03eaca` (`terraform/main.tf` + `CLAUDE.md`). No infra change.

## Problem
`terraform/main.tf` `backend "s3"` had no `profile` → state/lock operations used base
`tyler-cli` creds → `GunnerRequireMFA` explicit-deny on the lock (recurring across cc-2107 /
cc-2109 / cc-2111, worked around with `force-unlock` and `AWS_PROFILE=mfa`).

## Change — backend AND provider (the one-liner wasn't enough)
The prompt's diff pinned only the `backend "s3"`. Empirically that was **insufficient**:
`terraform plan` with `AWS_PROFILE` unset still threw ~60 `GunnerRequireMFA` denials — all on
**provider** refresh/data-source calls (acm, apigateway, ssm, iam, ec2, cognito, dynamodb, sns,
logs, …), because `provider "aws"` also had no `profile` and fell back to base creds. The lock
itself was already clean after the backend pin (the plan reached refresh, which only happens
post-lock).

So I pinned `profile = "mfa"` on **both**:
```hcl
backend "s3"  { … profile = "mfa" … }
provider "aws"{ region = var.aws_region; profile = "mfa"; … }
```
This is required to meet the prompt's own verify ("`terraform plan` … no GunnerRequireMFA
denial") and stated goal ("not a per-invocation env var people forget") — not scope creep.

## Verify (AWS_PROFILE unset)
- `terraform init -reconfigure` → success (backend uses pinned mfa profile; no state migration).
- `terraform plan` → exit 0, **0 `GunnerRequireMFA` denials**, lock acquired/released cleanly.
- Requires a live `mfa` session (`awsmfa`); without it terraform fails fast with a clear
  auth/expired-token error — the intended UX (vs the old confusing lock denial).

## Side observations
- Current full plan = `1 add / 0 change / 1 destroy` = **only `null_resource.clear_alias_routing`
  being replaced** (benign local re-trigger, no AWS infra). The cc-1635 VPC drift (9/1/4 in
  `RECONCILE-vpc-2026-06-19.md`) is no longer in the plan — resolved by cc-2107/2109/2112 applies.
  Updated hot.md drift line. Did NOT apply (out of scope; null_resource replace is harmless).
- CLAUDE.md: added a note under "Learned from mistakes" — TF now pins the mfa profile on both
  backend + provider; the `AWS_PROFILE=mfa` prefixes in existing rules are now redundant (harmless).

## Reusable fact
For terraform to fully avoid `AWS_PROFILE=mfa`, BOTH the backend and the provider need
`profile = "mfa"` — the backend governs state/lock, the provider governs all resource refresh +
data-source reads. Pinning only one leaves the other on base creds → GunnerRequireMFA denials.
