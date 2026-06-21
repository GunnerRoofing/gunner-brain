---
type: session
title: session-2026-06-20-cc2114-aurora-cpg-import-aborted
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - infra
  - terraform
  - sst
  - pulumi
  - rds
  - aurora
  - soc2
  - aborted
  - shared-prod
status: aborted
related:
  - '[[meta/session-2026-06-20-cc2111-state-versioning-force-ssl]]'
  - '[[gunnerteam/aws-environment]]'
---

# Session cc-prompt-2114 — Import prod Aurora CPG to pin rds.force_ssl — ABORTED

Highest-care prompt of the block (shared prod). Goal: bring the prod Aurora cluster parameter
group under Terraform to pin `rds.force_ssl=1` as `Source=user` (so a future engine-default
change can't silently relax it). **Outcome: ABORTED before any change — the resource is owned by
a different IaC tool.**

## Phase 1 — enumerate (done)
Prod CPG `gunner-masterdb-production-masterdbclusterparametergroup-bzfauowx`:
- Family: **`aurora-postgresql17`** (the field is `DBParameterGroupFamily`, not
  `DBClusterParameterGroupFamily` — the latter returns `None`).
- User-source params: **only** `idle_in_transaction_session_timeout=30000` (apply `immediate`).
- `rds.force_ssl`: value `1`, **Source=system** (still the engine default, not pinned).

## STOP discovery — the CPG is SST/Pulumi-managed, not ours
- CPG `Description` = **"Managed by Pulumi"**.
- Tags on the CPG **and** the cluster: `sst:app=gunner-masterdb`, `sst:stage=production`,
  `sst:ref:password=arn:…secret:…MasterDbProxySecret…` → managed by an **SST (sst.dev) app**
  named `gunner-masterdb`. SST v3 deploys via Pulumi (hence the description).
- Not present in our `terraform state list`.

The whole masterdb Aurora stack (cluster, CPG, proxy, secret) belongs to a separate SST/Pulumi
app — almost certainly the shared-infra repo (Colin/DevOps), distinct from
`gunner-ios/terraform/` (the gunnerteam app layer).

## Decision — ABORT the Terraform import
Importing an SST/Pulumi-owned shared-prod resource into our Terraform creates **dual-IaC
ownership**. The next `sst deploy` of `gunner-masterdb` would reconcile the CPG against its own
definition and fight Terraform — risking a reset of Colin's `idle_in_transaction` (or churn on
`rds.force_ssl`) on shared production. That is precisely the catastrophe the prompt's STOP
gates exist to prevent — and it's a more fundamental blocker than any plan diff, so the import
was never attempted. **No `terraform/rds-params.tf` created; no import; TF state untouched.**

## Correct path forward
Pin `rds.force_ssl=1` in the **`gunner-masterdb` SST app** itself (coordinate with its owner —
likely Colin/DevOps). That is also where the only realistic risk originates (someone editing
the SST param-group def), so the guard belongs there, declaratively. Secondary note: even
without the ownership conflict, `force_ssl=1 == engine default` means a plain modify is deduped
by RDS (cc-2111) — but SST/Pulumi asserts param values declaratively in the group definition,
which is the right model for a durable pin.

## Reusable facts
- **Never `terraform import` the masterdb cluster / CPG / proxy** into `gunner-ios/terraform` —
  it's a separate SST/Pulumi app (`sst:app=gunner-masterdb`).
- Gunner infra is split: gunnerteam app layer = Terraform (`gunner-ios/terraform/`); shared
  masterdb Aurora = SST/Pulumi (`gunner-masterdb`).
- `aws rds describe-db-cluster-parameter-groups` exposes the family as `DBParameterGroupFamily`.
