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
updated: '2026-05-22'
---
# Secrets Handling Rules

> These rules apply for every session, regardless of what other instructions follow.

---

## 1. Never display secret values

Never print, echo, display, or log the value of any secret. This includes:

- `DB_PASSWORD`, `DB_USER`, `JWT_SECRET`
- `ANTHROPIC_API_KEY`, `COMPANYCAM_API_KEY`, `COMPANYCAM_WEBHOOK_SECRET`, `COMPANYCAM_PHOTO_COMMENT_WEBHOOK_SECRET`
- `APNS_KEY_CONTENT`, `APNS_KEY_ID`, `APNS_TEAM_ID`
- `MONDAY_API_TOKEN`, `RESEND_API_KEY`
- Any SSM parameter fetched with `--with-decryption`
- Any variable ending in `_PASSWORD`, `_SECRET`, `_KEY`, `_TOKEN`

---

## 2. Never construct inline secrets in commands

**Wrong:**
```bash
--value "$(aws ssm get-parameter --with-decryption ...)"
```

**Correct:** reference `$VAR_NAME` that Tyler has already exported in his terminal.

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

To check a specific non-sensitive var, query by name:
```bash
--query 'Environment.Variables.EMAIL_PROVIDER'
```

---

## 5. Terraform owns Lambda env vars

Never manually set secrets via `aws lambda update-function-configuration --environment`.

If env vars need updating: update SSM and run `terraform apply`.

---

## 6. MFA codes are single-use

If output contains `--token-code`, do not display it in responses.

---

## Sources

- Established: 2026-05-21, session covering masterdb cutover + Lambda VPC migration
