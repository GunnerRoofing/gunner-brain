---
type: session
title: session-2026-06-20-cc2109-s3-baseline
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - backend
  - infra
  - terraform
  - security
  - soc2
  - s3
status: stable
related:
  - '[[gunnerteam/aws-environment]]'
  - '[[meta/session-2026-06-20-cc2102-db-tls-verify]]'
---

# Session cc-prompt-2109 — S3 CC6.1 baseline on the application buckets

Bring the two DevOps-created app buckets under a Terraform-managed baseline (no public
access, default encryption, TLS-only). `terraform/s3.tf` previously only *referenced* the
inspections bucket. **Targeted `terraform apply` = 4 add / 0 change / 0 destroy; verified
end-to-end via the real presigned photo path.**

## Buckets
- `gunner-fleet-dev` — inspection/job photos (`var.s3_bucket`, also SSM `AWS_S3_BUCKET`).
- `gunner-assistant-docs` — assistant KB docs (SSM `ASSISTANT_DOCS_BUCKET`); added a new
  `data "aws_s3_bucket" "assistant_docs"` keyed off the existing
  `data.aws_ssm_parameter.assistant_docs_bucket.value` (defined in `lambda-api.tf:42`).

## Phase-1 audit (don't assume) — most controls were already live
| control | gunner-fleet-dev | gunner-assistant-docs |
|---|---|---|
| Public Access Block | already 4×true | already 4×true |
| Default encryption | AES256, BucketKey=true, **SSE-C blocked** | AES256, BucketKey=false, **SSE-C blocked** |
| Bucket policy | **none** (NoSuchBucketPolicy) | **none** |

→ The only genuinely missing CC6.1 control was **TLS-only transport**.

## What was added
- `aws_s3_bucket_public_access_block` ×2 — codify the already-true PAB (idempotent PUT,
  zero live change) so drift is now detected on these formerly-unmanaged buckets.
- `aws_s3_bucket_policy` ×2 — `DenyInsecureTransport` (Deny `s3:*` when
  `aws:SecureTransport=false`). Standalone (no existing policy to merge). A Deny-only
  statement is never "public", so it coexists with `block_public_policy=true`.

## KEY DECISION — SSE deliberately NOT codified (avoided a silent regression)
Both buckets carry `BlockedEncryptionTypes:[SSE-C]` live — the **AWS Apr-2026 default**
(S3 now auto-blocks customer-provided-key uploads). The pinned provider
`hashicorp/aws 5.100.0` has **no `blocked_encryption_types` argument** (`strings` on the
provider binary → 0 hits). `aws_s3_bucket_server_side_encryption_configuration` issues a
full **PutBucketEncryption REPLACE**, so codifying SSE would drop the live SSE-C block for
zero benefit (AES256 is already enforced). "Add only what's missing" → SSE isn't missing.
Re-audit post-apply confirmed the SSE-C block intact on both. Revisit only after a provider
upgrade that supports `blocked_encryption_types`.

## Verification (real app path — mirrors `gunnerteam-api/src/lib/s3.js` getSignedUrl)
Replicated the Lambda's exact presign via local `@aws-sdk/s3-request-presigner`:
- presigned **PUT /https** → `200` (upload path intact)
- presigned **GET /https** → `200` + probe content (download path intact)
- same presigned **GET /http** → `403 AccessDenied "explicit deny in a resource-based policy"`
- docs bucket: authenticated GET /http = explicit-deny vs /https = NoSuchKey → deny is
  transport-specific, not creds/existence. PAB confirmed NOT to block presigned URLs.
- Probe object cleaned up.

## Gotchas (reuse)
- **terraform + MFA:** the S3 backend (`main.tf:15`) has no `profile` → terraform used base
  `tyler-cli` long-term keys → `GunnerRequireMFA` *explicit-deny* on the state-lock PutObject
  (while `--profile mfa` AWS CLI calls worked). Fix: run terraform with `AWS_PROFILE=mfa` env
  (drives both backend + provider). The `mfa` session was valid throughout.
- **node script module resolution:** a script at `/tmp/foo.js` resolves `node_modules` from
  `/tmp`, NOT cwd. Set `NODE_PATH=.../gunnerteam-api/node_modules` (or `node -e`, which uses cwd).

## Out-of-scope observation (follow-up candidate)
The audit-logs bucket (`gunner-audit-logs-dev`, `audit-archiver.tf`) has PAB + SSE + lifecycle
but **no TLS-only policy** either. Not touched (prompt scope = the two app buckets).
