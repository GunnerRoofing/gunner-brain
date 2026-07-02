---
title: AWS Environment — GunnerTeam
type: gunner
tags:
  - gunner
  - aws
  - lambda
  - infrastructure
status: stable
created: 2026-04-23T00:00:00.000Z
updated: '2026-06-24'
sources: []
related:
  - '[[tyler/hot]]'
  - '[[gunnerteam/masterdb-developer-handoff]]'
---

# AWS Environment — GunnerTeam

## Overview

The GunnerTeam backend runs a Lambda-first architecture in **us-east-2**. The Express.js API runs entirely on AWS Lambda fronted by API Gateway; there is no EC2 and no load balancer. Aurora Serverless v2 (PostgreSQL) provides persistence behind an RDS Proxy, Cognito handles authentication, and S3 holds Lambda deploy artifacts and assistant documents. No provisioned concurrency is configured.

## API Layer

| Property | Value |
|----------|-------|
| Lambda function | `gunnerteam-dev-api` |
| Alias | `live` |
| Live version | see [[tyler/hot]] for current — do not hardcode here |
| API Gateway host | `k5h2n0rog9.execute-api.us-east-2.amazonaws.com` |
| Public hostname | `api.team.gunnerroofing.com` |
| DNS | Cloudflare proxy (orange cloud) → API Gateway |

API Gateway invokes the `live` alias of `gunnerteam-dev-api`. Cloudflare DNS proxies `api.team.gunnerroofing.com` to the API Gateway endpoint, terminating client traffic at the orange-cloud proxy before forwarding to AWS.

## Database

| Property | Value |
|----------|-------|
| Engine | Aurora Serverless v2 (PostgreSQL) |
| Cluster endpoint | `gunnerteam-dev.c52gm8goign8.us-east-2.rds.amazonaws.com` |
| RDS Proxy endpoint | `gunnerteam-dev-api.proxy-c52gm8goign8.us-east-2.rds.amazonaws.com` |

The Lambda connects through the RDS Proxy endpoint, which pools and reuses database connections across invocations. See [[tyler/masterdb/masterdb-architecture]] for schema details.

## Auth

| Property | Value |
|----------|-------|
| Cognito user pool | `us-east-2_hFVBSrcnn` |
| App client ID | `6m41qei5jq3nt46jler56im1cg` |

## Storage

| Bucket | Region | Purpose |
|--------|--------|---------|
| `gunnerteam-lambda-deploy-useast2` | us-east-2 | Lambda deploy artifacts (zip uploads >10 MB) |
| `gunner-assistant-docs` | us-east-2 | Assistant knowledge-base documents |

## Deploy Process

Deploys use `AWS_PROFILE=mfa`, which provides 60-minute MFA sessions refreshed via `awsmfa` (MFA serial `arn:aws:iam::980921733684:mfa/tylerMFA`). Refresh the session before deploying if the current one has expired.

The flow zips the build, stages it in S3, points the function at the new artifact, waits for the update to settle, publishes a new immutable version, and moves the `live` alias to it.

**Two rules that must not be skipped (learned from cc-867):**
1. **`rm -f /tmp/gunnerteam-deploy.zip` before every zip** — `zip -r` merges into an existing archive; stale files survive silently and the function runs old code.
2. **`--routing-config '{"AdditionalVersionWeights":{}}'` explicit JSON** — the shorthand `AdditionalVersionWeights={}` is a no-op and leaves any prior canary weight in place, routing 100% of traffic to the old version even after the alias is updated.

```bash
awsmfa  # refresh 60-min MFA session if needed

rm -f /tmp/gunnerteam-deploy.zip && \
cd ~/Dev/GunnerTeam/gunnerteam-api && \
zip -r /tmp/gunnerteam-deploy.zip . -x "*.git*" "node_modules/.cache/*" > /dev/null && \
aws s3 cp /tmp/gunnerteam-deploy.zip \
  s3://gunnerteam-lambda-deploy-useast2/gunnerteam-deploy.zip \
  --region us-east-2 --profile mfa && \
aws lambda update-function-code \
  --function-name gunnerteam-dev-api \
  --s3-bucket gunnerteam-lambda-deploy-useast2 \
  --s3-key gunnerteam-deploy.zip \
  --region us-east-2 --profile mfa --query 'FunctionName' --output text && \
aws lambda wait function-updated \
  --function-name gunnerteam-dev-api \
  --region us-east-2 --profile mfa && \
VERSION=$(aws lambda publish-version \
  --function-name gunnerteam-dev-api \
  --region us-east-2 --profile mfa \
  --query 'Version' --output text) && \
aws lambda update-alias \
  --function-name gunnerteam-dev-api \
  --name live \
  --function-version "$VERSION" \
  --routing-config '{"AdditionalVersionWeights":{}}' \
  --region us-east-2 --profile mfa --query 'FunctionVersion' --output text && \
echo "deployed v$VERSION"
```

### Migrations

Run a migration by invoking the Lambda directly with the migration payload. The `--cli-binary-format raw-in-base64-out` flag is required so the CLI passes the JSON payload verbatim:

```bash
aws lambda invoke \
  --function-name gunnerteam-dev-api \
  --cli-binary-format raw-in-base64-out \
  --payload '{"_migration":"MIGRATION_KEY","_secret":"gunner-migrate-2026"}' \
  --region us-east-2 \
  response.json
```

## Terraform

Terraform lives in `~/Dev/GunnerTeam/terraform/` and manages the Lambda function's configuration — environment variables, IAM roles and policies, and VPC settings. It does **not** deploy code; code ships through the zip→S3→`update-function-code` flow above. Apply Terraform for config and infrastructure changes only.

## Open Items

- **Cloudflare API token:** The token in use is a personal token with an IPv6 restriction. Replace it with an account-owned token so DNS automation does not depend on a single user's personal credential.

## Related

- [[gunnerteam/environment]] — full Gunner tech stack and infrastructure overview
- [[tyler/gunnerteam/gunnerteam-project-structure]] — repo layout for the iOS app and Express Lambda backend
- [[tyler/gunnerteam/gunnerteam-api-aws-migration]] — migration history to the current Lambda architecture
- [[tyler/masterdb/masterdb-architecture]] — Aurora schema and data model
