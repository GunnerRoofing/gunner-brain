---
type: policy
owner: tyler
created: '2026-06-15'
updated: '2026-06-15'
status: active
tags:
  - policy
  - soc2
  - change-management
  - process
title: Change Management Policy
---

# Change-Management Policy — GunnerTeam

**Owner:** IT Manager (Tyler Suffern) · **Audience:** all engineers and contractors who change GunnerTeam code, configuration, or infrastructure · **Status:** effective 2026-06-15

This policy exists to keep deployed systems equal to version control, ensure changes are reviewed and traceable, and satisfy SOC 2 change-management controls. It was prompted by the 2026-06-15 incident, where uncoordinated direct changes to a live Lambda caused drift, regressions, and an outage.

---

## 0. Where this applies (scope)
This policy governs the **shared control surface** — anywhere more than one party (internal staff + external contractors + automated sessions) can change something: the deployed Lambda runtime, the shared database and infrastructure (masterdb cluster, RDS Proxies, shared secrets/SGs), and the cross-app integration contracts. **Peer review and the boundary controls below are required there.**

Single-maintainer authoring *within* a repo (e.g. the `gunner-ios` iOS app, where Tyler is the only committer) is version-controlled and traceable but does **not** require peer review — commit to `main` and move on. The reason this policy exists is uncoordinated changes to *shared* systems, not solo work in a private repo.

## 1. Principle: git is the system of record
Every change that reaches production **must originate in version control** and ship through a git-based deploy; the deployed artifact must equal a committed revision. This applies to solo work too — not as ceremony, but because the working tree is not a backup (a full session of uncommitted iOS work was lost on 2026-06-15). Direct edits to *running shared systems* are prohibited except under the emergency procedure (§6).

## 2. Scope — what counts as a change
| Type | Where it lives | How it ships |
|---|---|---|
| Application code (backend/iOS) | `gunner-ios` | commit `main` (solo) or PR → merge (shared) |
| Infrastructure (Lambda config, SGs, IAM, API GW, proxies) | `terraform/` or owning repo's SST | PR → `terraform plan`/`apply` or `sst deploy` |
| Lambda env vars (e.g. `DB_HOST`) | SSM param, referenced by Terraform | update SSM → `terraform apply` |
| Database schema | inline `migrations` object in `lambda.js` | deploy → `_migration` handler |
| Shared infra (masterdb cluster, RDS Proxy, shared secrets) | `gunner-masterdb` SST (owned by its maintainer) | PR in that repo by its owner |

## 3. Review & approval
- **Shared-surface changes** (deployed Lambda runtime, shared DB/infra, cross-app contracts, and security-relevant code — auth, RLS, secrets, IAM, migrations) land via **PR with at least one reviewer** familiar with the `CLAUDE.md` rules.
- **Cross-team changes** (anything touching shared infra owned by another repo) require written sign-off from the owning team before merge.
- **Single-maintainer solo changes** (e.g. the iOS app) commit straight to `main` — committed history is the audit trail; no mandatory peer review.
- Never deploy a shared runtime from a dirty or unreconciled tree.

## 4. Separation of duties & access
- Deploys are performed by authorized engineers using MFA-gated credentials (AWS profile `mfa`).
- Contractors operate within their own repo's boundary; they do not deploy to or hand-edit another team's runtime. Shared-infra changes are made by the owning team.
- Production-equivalent environments are treated as production for the purposes of this policy (note: GunnerTeam currently runs a single `dev` environment that serves real users).

## 5. Auditability (evidence for SOC 2)
Each change is traceable end to end:
- **What & why:** the PR (description, diff, reviewer approval) or commit message for solo changes.
- **When & by whom:** git history + PR metadata.
- **What shipped:** the published Lambda **version** behind the `live` alias maps to a commit; Terraform/SST state records infra changes.
- **Runtime actions:** the application `audit_log` records security-relevant operations.
Retain these for the audit window. A change with no commit and no version mapping is a finding.

## 6. Emergency-change procedure
If production must be changed before a normal commit/PR (active outage):
1. Make the smallest safe change.
2. **Log it immediately** — what, why, who, when — in the incident channel/record.
3. **Back-port to git the same business day** via a commit or retroactive PR, and reconcile the live artifact to match (download + diff — see CONTRIBUTING §6).
4. Note it in the next review.
Emergency changes are the exception, are time-boxed, and always end with git == production.

## 7. Drift detection & remediation
- Before any deploy where drift is possible, verify the live artifact equals `main` (CONTRIBUTING §6).
- Any deployed-only change found must be brought into git before further deploys.
- Recurring drift is escalated to the policy owner as a process failure, not a one-off.

## 8. Roles
| Role | Responsibility |
|---|---|
| Policy owner (IT Manager) | Maintains this policy, grants/revokes deploy access, handles escalations |
| Author | Commits or opens PR, describes change + verification |
| Reviewer | Reviews against CLAUDE.md rules; approves (shared surface only) |
| Deployer | Deploys only committed `main`; confirms `live` version; smoke-tests |
| Shared-infra owner | Approves and makes changes to infrastructure their repo owns |

## 9. Enforcement
Branch protection on `main` for shared-surface PRs, restricted deploy credentials, and periodic drift checks back this policy. Violations are reviewed; repeated direct-to-prod changes result in revoked deploy access until remediated.
