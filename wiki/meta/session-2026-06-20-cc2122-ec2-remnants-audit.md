---
type: session
title: session-2026-06-20-cc2122-ec2-remnants-audit
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - infra
  - terraform
  - security
  - soc2
  - cleanup
  - ec2
  - audit
status: stable
related:
  - '[[meta/session-2026-06-20-cc2121-remove-assistant-stream-lambda]]'
  - '[[gunnerteam/aws-environment]]'
---

# Session cc-prompt-2122 — Remove orphaned EC2-era remnants + account audit (CC6.1)

Clean the dead EC2→Lambda migration remnants and answer the one thing only an account check can:
is a legacy EC2 still running? Commit `bb2198a`. No live resource change; the audit is the
substantive part.

## Phase 1 — vars (all 4 confirmed unreferenced)
`grep var.<x> *.tf` → `ec2_instance_type`, `ec2_key_name`, `dev_ip`, `jwt_secret` all
UNREFERENCED. The ⚠️ `dev_ip` case (might feed a SG ingress) was checked — **no use**, so safe to
remove. Removed all 4 blocks from `variables.tf`; removed their lines from the gitignored
`terraform.tfvars` (kept live secrets db_password / cloudflare / migration). Removing the var +
its tfvars line together avoids the "value for undeclared variable" warning. This also wiped the
**last copy** of the dead HS256 secret.

## Phase 2 — scripts
Deleted `terraform/user_data.sh` (EC2 bootstrap; no `templatefile`/`file()` TF refs).
`ssm-boothook.sh` was already absent.

## Phase 3 — the audit (the point)
`aws ec2 describe-instances` (running/stopped, us-east-2 + a us-east-1 count):
- **No stray GunnerTeam EC2.** No instance keyed `gunnerteam-ec2` or named gunnerteam/gunner-forms.
  The migration's box was **terminated** (not merely removed from TF). EC2 chain fully retired;
  no unmanaged compute carrying the old JWT_SECRET.
- ⚠️ **Account-hygiene observation (NOT GunnerTeam; not touched):** 6 instances in us-east-2
  (+2 in us-east-1). Long-lived dev boxes on key `devopsFrontend` since 2024 —
  `dev-gunner-salesPortalEc2`, `dev-gunner-CorpProtal-frontend`, `dev-gunner-hrPortalEc2`; plus
  `wl-companycam-dev-bastion` (Colin), `db-tunnel`; stopped `testindqp2-hubspot`. These belong to
  other apps/owners — flag for an owner review (cost + possible userdata secrets), out of
  GunnerTeam scope. **Did not auto-terminate anything** (per the prompt).

## Phase 4 — validate
`terraform validate` Success (only the pre-existing cosmetic `cognito.tf:89` redundant
`ignore_changes` warning). `terraform plan` shows **no new changes** from the removals — only the
known leftover drift (`null_resource.clear_alias_routing` replace + cc-2121's
`assistant_stream_url` output removal). Confirms variables/tfvars/scripts aren't state.

## Reusable
- `git ls-files <path>` is relative to CWD — running it with a `terraform/` prefix while already
  inside `terraform/` gives a false "untracked." `user_data.sh` was in fact tracked; folded its
  deletion into the commit via `git add` + `--amend`.
- `terraform.tfvars` is gitignored (holds db_password/cloudflare/migration secrets) — edits to it
  are local-only.
