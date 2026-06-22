---
type: reference
owner: colin
app: GunnerCam
created: 2026-05-07
updated: 2026-05-07
tags: [wl-companycam, provisioning, ops]
status: active
---

# Provisioning Tickets

Source: `~/repos/WL-CompanyCam/tickets/` (already executed for the dev stage).

## 01 — AWS RDS Postgres (dev)

`tickets/01-aws-rds.md`. Provisions `wl-companycam-dev` on RDS, public IP-restricted, master user `postgres`, default DB `postgres`. Outputs `DATABASE_URL` for `.env.local`. Connection string format:

```
postgres://postgres:<URL_ENCODED_PASSWORD>@<endpoint>:5432/postgres
```

Test with `psql` — successful connection lands at `postgres=>` prompt with empty `\dt`.

Status today: completed. Endpoint = `wl-companycam-dev.c52gm8goign8.us-east-2.rds.amazonaws.com`.

## 02 — Drizzle setup

`tickets/02-drizzle.md` (not fully read into the wiki — pull from repo if needed). Generates the schema in `src/db/schema.ts`, configures `drizzle.config.ts`, adds `db:generate` / `db:migrate` / `db:studio` / `db:seed` npm scripts.

Run order on a fresh DB:
1. `npm run db:generate` — emits SQL into `drizzle/`
2. `npm run db:migrate` — applies SQL via `scripts/migrate-via-ip.mts`
3. `npm run db:seed` — populates corp + users + sample projects

## 03 — AWS S3

`tickets/03-aws-s3.md`. Creates the private bucket `wl-companycam-dev-cw`, no public access, default encryption ON. CORS rules applied via `scripts/s3-cors.mts`.

## After-the-fact provisioning scripts

| Script | Purpose |
|---|---|
| `scripts/provision-cwong.mts` | Creates Colin's Cognito user + syncs `cognito_sub` into `users.cwong` |
| `scripts/provision-test-users.mts` | Provisions 4 test accounts (sgengo, jmassari, zwebb, dlavia) across `users` and `crew_members` |
| `scripts/s3-cors.mts` | (Re)applies S3 CORS rules; reads extra origins from `S3_CORS_EXTRA_ORIGINS` env |
| `scripts/migrate-via-ip.mts` | Runs Drizzle migrations against `DATABASE_URL` (used by `db:migrate`) |

All scripts auth via `fromIni({ profile: "devops" })` and force public DNS resolvers (Google + Cloudflare) for portability across local networks.

Required env (most live in `.env.local`):

| Var | Used by | Default |
|---|---|---|
| `DATABASE_URL` | migrate, provision | — (required) |
| `AWS_S3_BUCKET` | s3-cors | `wl-companycam-dev-cw` |
| `AWS_S3_REGION` | s3-cors | `us-east-2` |
| `S3_CORS_EXTRA_ORIGINS` | s3-cors | empty |
| `COGNITO_USER_POOL_ID` | provision-* | `us-east-2_sEOcsFA76` |
| `SEED_USER_PASSWORD` | provision-* | — (required) |

## What's missing on the provisioning side

- Production stage is not provisioned (see [[colin/risks]] #1).
- No automated bootstrap script for a brand-new corp/tenant — would be needed before customer #2.
- No teardown / idempotent re-run pattern documented.
