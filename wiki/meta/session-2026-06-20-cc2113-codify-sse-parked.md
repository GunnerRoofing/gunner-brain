---
type: session
title: session-2026-06-20-cc2113-codify-sse-parked
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - infra
  - terraform
  - aws-provider
  - s3
  - soc2
  - parked
status: parked
related:
  - '[[meta/session-2026-06-20-cc2109-s3-baseline]]'
  - '[[gunnerteam/aws-environment]]'
---

# Session cc-prompt-2113 — Codify S3 SSE (provider-capability gated) — PARKED

Conditional task: codify `aws_s3_bucket_server_side_encryption_configuration` on the app
buckets so the SSE config gets Terraform drift detection. Runs **only if Phase 0 passes**.
**Outcome: PARKED — no changes.**

## Phase 0 — capability gate (the decision-maker)
Question: can the live SSE-C block (`BlockedEncryptionTypes:[SSE-C]`, AWS 2026 default) be
expressed in TF so codifying doesn't silently drop it on the full-replace `PutBucketEncryption`?

- Current pin `~> 5.0` (5.100.0): **no** `blocked_encryption_types` arg. Confirmed via
  `strings` on the provider binary = 0 hits. (The `terraform providers schema -json` gate
  command also works but needs `AWS_PROFILE=mfa` — it touches the S3 backend.)
- The arg was added in **aws provider 6.22.0** (2025-11-20, PR #45105) — **not backported to
  5.x**. It then had a perpetual-drift bug in 6.22–6.39 (issue #47320), fixed in **6.40.0**
  (changed to Optional+Computed).

## Decision — PARK
The only way to codify with the SSE-C block preserved is a **major `~> 5.0` → `~> 6.x`
(≥6.40) provider migration**. aws provider 6.0 is a breaking major that affects every
resource in this config (cognito, lambda, rds, vpc, cloudfront, iam, eventbridge, s3…).

That is wildly disproportionate to the benefit here: SSE is **drift-detection hardening, not
a missing control** — AES256 + SSE-C blocking are already enforced live on both buckets
(verified cc-2109). The prompt's own Phase-1 guard ("don't let an SSE change become a stealth
provider migration; resolve unrelated drift before proceeding") independently forces the stop.

No edits to `terraform/s3.tf` or `terraform/main.tf`. Git working tree unchanged.

## Interim / revisit
- Detection-only guard: AWS Config managed rule `s3-bucket-server-side-encryption-enabled` —
  **deferred to the group-3 Config rollout** per the prompt (don't build bespoke checker infra
  now).
- Revisit codification when/if the repo moves to **aws provider ≥6.40** for other reasons; at
  that point adding the SSE resource with `blocked_encryption_types = ["SSE-C"]` is a cheap,
  zero-functional-diff change (plan must show no change to live encryption).

## Reusable fact
`blocked_encryption_types` (SSE-C block) support matrix: **absent in all 5.x**, **added 6.22.0**,
**drift-stable from 6.40.0**.
