---
type: session
title: session-2026-06-20-cc2111-state-versioning-force-ssl
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - infra
  - aws
  - rds
  - aurora
  - terraform
  - security
  - soc2
  - tls
status: stable
related:
  - '[[gunnerteam/aws-environment]]'
  - '[[meta/session-2026-06-20-cc2102-db-tls-verify]]'
  - '[[meta/session-2026-06-20-cc2109-s3-baseline]]'
---

# Session cc-prompt-2111 — TF state versioning (A1.2) + Aurora rds.force_ssl (CC6.7)

Two CLI-only changes, neither in Terraform. Net: **both controls already satisfied** —
nothing needed flipping. The value was in the *assessment* (don't assume) and in not
touching the shared prod cluster unnecessarily.

## Part A — Terraform state-bucket versioning (A1.2 recoverability)
`aws s3api get-bucket-versioning --bucket gunnerteam-terraform-state` → already
`Status=Enabled`. State rollback already protected; no action. (Object Lock / MFA-delete
intentionally out of scope per the prompt.)

## Part B — rds.force_ssl on the SHARED prod Aurora cluster (coordination-gated)

### Disambiguation (two clusters!)
`describe-db-clusters` returned a `dev` AND a `production` masterdb cluster. The target is
**production** — identified by the cc-1503 marker `idle_in_transaction_session_timeout=30000`
(a user param) on CPG `gunner-masterdb-production-masterdbclusterparametergroup-bzfauowx`.

Surprise topology: the **dev** Lambda actually talks to the **production** cluster —
`gunnerteam-dev-masterdb-proxy` → `TRACKED_CLUSTER gunner-masterdb-production-masterdbcluster-sczazkvf`
(+ its two instances). The `gunner-masterdb-dev-*` cluster has no proxy targets (unused).
Proxy `RequireTLS=False` (app→proxy leg optional), but our client forces TLS (cc-2102) and
RDS Proxy→cluster is TLS by default.

### Key finding — already enforced
`rds.force_ssl` is **already `1` and effective**:
- `describe-engine-default-cluster-parameters --db-parameter-group-family aurora-postgresql17`
  → `rds.force_ssl = 1` (dynamic, system). Aurora PG 17.7 ships TLS-enforced by default.
- Prod CPG: `ParameterValue=1, Source=system, ApplyType=dynamic, IsModifiable=true`, cluster
  `available`, `PendingModifiedValues=null`, never user-overridden → effective value = 1.

So the prompt's premise (force_ssl=0, flipping risks Colin) was **stale**. CC6.7 is already
met, and Colin's app — running against the same cluster — is necessarily already TLS-compliant
(it would already be broken otherwise). The coordination gate was effectively moot.

Our side verified under force_ssl=1: migration probe `pool.connect()` → `[{"ok":true}]`,
`/health` 200.

### RDS gotcha — can't pin a value that equals the default
Tyler chose to add an explicit user-override anyway (audit durability). It **could not be
recorded**: `modify-db-cluster-parameter-group ParameterValue=1 ApplyMethod=immediate`
returns success but RDS **dedupes a modify whose value equals the engine default** — the
param stayed `Source=system` across a 35s recheck and never appeared in `--source user`
(while `idle_in_transaction=30000`, a non-default value, does). The modify was a no-op;
re-verified DB connect `ok:true` + `/health` 200 afterward (no disruption).

Consequence: `force_ssl` is enforced (=1) but cannot be pinned `Source=user` via the CPG
while `1` is the engine default. **Durable pinning would require Terraform managing this CPG**
(it isn't in TF today) — flagged as a follow-up, out of cc-2111 scope (shared prod).

### Rollback
`ParameterValue=0` would disable enforcement — never needed here (no change took effect).

## Gotchas / reuse
- Two `masterdb` clusters; the live one is **production** (cc-1503 idle_in_transaction marker).
  The dev Lambda uses it via `gunnerteam-dev-masterdb-proxy`.
- RDS silently dedupes a param modify whose value == engine default (no user override created).
- Colin is a human teammate (not an IRC agent) — coordination gates on him can't be cleared
  in-session; lean on observable state (already-enforced → already-compliant).
