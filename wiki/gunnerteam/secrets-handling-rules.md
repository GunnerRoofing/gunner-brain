---
title: Secrets Handling Rules
type: runbook
tags:
  - security
  - ops
  - secrets
  - aws
status: active
created: '2026-05-21'
updated: '2026-06-20'
related:
  - "[[meta/session-2026-06-20-cc2123-runtime-secrets]]"
  - "[[meta/session-2026-06-20-cc2124-db-password-runtime]]"
  - "[[gunnerteam/soc2-technical-summary]]"
---
# Secrets Handling Rules

> These rules apply for every session, regardless of what other instructions follow.

---

## 0. The Lambda env is SECRET-FREE (cc-2123 / cc-2124)

As of cc-2123 + cc-2124, **no secrets live in the `gunnerteam-dev-api` Lambda environment.** They are
SSM SecureString parameters under `/gunnerteam/dev/`, fetched once per container at runtime and cached.
`lambda:GetFunctionConfiguration` no longer exposes any secret (the incident class this closes).

**Runtime model:**
- `lib/secrets.js` — `loadSecrets()` does ONE `GetParametersByPath(SECRETS_PATH, WithDecryption)` per
  container, memoized. `lambda.js` `await loadSecrets()` at the top of every invocation, so
  `getSecretSync('NAME')` (a drop-in for `process.env.NAME`) is safe in every handler/lib.
  `getSecret('NAME')` is the async, fail-loud variant.
- `lib/db.js` — the pg `Pool` is built lazily by `getPool()` → `await getSecret('DB_PASSWORD')` on
  first use (NOT at module load), so even the DB password is runtime-fetched.
- IAM already allows `ssm:GetParametersByPath` on the path (cc-2107).

**Adding a new secret:** `aws ssm put-parameter --name /gunnerteam/dev/NAME --type SecureString
--value …`, then read it via `getSecretSync('NAME')` / `getSecret('NAME')`. **Do NOT add it to the
`lambda-api.tf` env.** Config / IDs / flags (e.g. `FIELD_PORTAL_API_URL`, `DB_HOST/PORT/NAME/USER`,
`SECRETS_PATH`) still belong in env and are Terraform-owned.

⚠️ **Drift invariant:** SSM `/gunnerteam/dev/DB_PASSWORD` must stay equal to the RDS Proxy's Secrets
Manager secret — a mismatch causes a DB outage. No prompt changes either value. (Future: read straight
from the proxy's Secrets Manager secret to make drift structurally impossible.)

---

## 1. Never display secret values

Never print, echo, display, or log the value of any secret. This includes:

- `DB_PASSWORD`, `DB_USER`
- `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `RESEND_API_KEY`, `MONDAY_API_TOKEN`
- `APNS_KEY_CONTENT`, `FIELD_PORTAL_API_KEY` + the `FIELD_PORTAL_*_WEBHOOK_SECRET`s,
  `GUNNERCAM_POINTS_WEBHOOK_TOKEN`, `COLIN_PNL_API_KEY`, `GOOGLE_CHAT_WEBHOOK_URL`, `MIGRATION_SECRET`
- Any SSM parameter fetched with `--with-decryption`
- Any variable ending in `_PASSWORD`, `_SECRET`, `_KEY`, `_TOKEN`

The canonical secret list is whatever sits under `/gunnerteam/dev/` as SecureString — not this prose.
(`JWT_SECRET` was fully retired across cc-2118 → cc-2122; it no longer exists anywhere.)

---

## 2. Never construct inline secrets in commands

**Wrong:**
```bash
--value "$(aws ssm get-parameter --with-decryption ...)"
```

**Correct:** reference `$VAR_NAME` that Tyler has already exported in his terminal, or pipe via a
file / env var the command reads without echoing.

---

## 3. When a secret is needed, stop and ask

Tell Tyler:
> "In your own terminal, run: `export VAR_NAME=...`"
> "Expected format: [describe — e.g. 32-char alphanumeric]"
> "Get it from: [exact source — SSM path, AWS console location, or service dashboard]"

Then wait for confirmation before proceeding.

---

## 4. Never dump Lambda env vars

Never run:
```bash
aws lambda get-function-configuration --query 'Environment.Variables'
```

The env is secret-free as of cc-2123/2124, so this is now belt-and-suspenders — but the habit also
prevents leaking it again if a secret is ever mistakenly added. To check a specific non-sensitive var,
query by name: `--query 'Environment.Variables.EMAIL_PROVIDER'`. (Verifying the env has 0 secrets is the
legitimate exception, e.g. `grep -c` for secret names over the dumped JSON during a hardening deploy.)

---

## 5. Terraform owns CONFIG env vars; secrets are runtime SSM

Never manually set env via `aws lambda update-function-configuration --environment`.

- **Config** (DB_HOST/PORT/NAME/USER, FIELD_PORTAL_API_URL, SECRETS_PATH, flags): change the SSM
  source / `lambda-api.tf` and run `terraform apply` (env-change flow: SSM → `lambda-api.tf` →
  `plan -target` env-only → apply → publish → alias).
- **Secrets**: change the SSM SecureString param value only. The code re-fetches it on the next cold
  container — no env change, no `lambda-api.tf` edit.

---

## 6. MFA codes are single-use

If output contains `--token-code`, do not display it in responses.

---

## Sources

- Established: 2026-05-21, session covering masterdb cutover + Lambda VPC migration.
- Updated: 2026-06-20 (cc-2123/2124) — runtime secret model; the Lambda env is now secret-free.
