---
type: session
title: session-2026-06-20-cc2112-audit-logs-tls
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - infra
  - terraform
  - security
  - soc2
  - s3
  - audit
status: stable
related:
  - '[[meta/session-2026-06-20-cc2109-s3-baseline]]'
  - '[[gunnerteam/aws-environment]]'
---

# Session cc-prompt-2112 — TLS-only policy on the audit-logs bucket (CC6.7)

Closes the gap cc-2109 explicitly flagged: `gunner-audit-logs-${var.env}` had PAB + SSE +
versioning + Object Lock but **no bucket policy**, so it accepted non-TLS requests. This bucket
holds the SOC 2 audit trail → TLS-only matters most here.

## Change
`terraform/audit-archiver.tf` — added `aws_s3_bucket_policy.audit_logs` (DenyInsecureTransport,
Deny `s3:*` when `aws:SecureTransport=false`) right after the existing
`aws_s3_bucket_public_access_block.audit_logs`. Unlike the app buckets (cc-2109, data sources),
this bucket is **TF-managed** (`aws_s3_bucket.audit_logs`), so the policy references the resource
directly. No existing policy to merge (confirmed).

## Apply
`terraform plan/apply -target=aws_s3_bucket_policy.audit_logs` with `AWS_PROFILE=mfa` →
**1 add / 0 change / 0 destroy**. Commit `ff07b2c`.

## Verify
- `http` GET nonexistent key → `AccessDenied` (explicit deny); `https` GET same key → `NoSuchKey`.
  Deny is transport-specific (the policy), not creds/existence. (No object created — the audit
  trail / Object Lock untouched.)
- Archiver health: `{count:true}` invoke of `gunnerteam-dev-audit-archiver` → 200,
  `{"total":842,"last24h":32,"last7d":365,"mostRecent":"2026-06-20T19:38:51Z"}`. Pipeline healthy,
  DB connectivity fine. (count-mode counts rows + emits the `AuditLogLast24h` metric for the
  cc-1636 silence alarm; no S3 write — the real archival runs monthly.)
- Archiver S3 writes are SDK/HTTPS → unaffected by DenyInsecureTransport; Object Lock retention
  is independent of the bucket policy.

## Milestone
All three S3 buckets now enforce TLS-only: `gunner-fleet-dev`, `gunner-assistant-docs` (cc-2109),
`gunner-audit-logs-dev` (cc-2112).
