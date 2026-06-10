---
type: session
title: "cc-prompts 57–63: Invite / Registration Fix Chain"
created: 2026-05-27
updated: 2026-05-27
tags:
  - gunnerteam
  - api
  - cognito
  - postgres
  - invite
  - iam
status: stable
related:
  - "[[meta/session-2026-05-27-cc54-56-admin-delete-fk-sweep]]"
---

# cc-prompts 57–63: Invite / Registration Fix Chain

Seven sequential fixes to make `POST /auth/invite` + `POST /auth/complete-invite` work end-to-end. Each deploy exposed the next failure.

---

## Fix Chain Summary

| cc | Error | Fix |
|---|---|---|
| 57 | `column "expires_at" of relation "invite_tokens" does not exist` | Migration: `ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ` on `invite_tokens` + `reset_tokens` |
| 58 | `column "created_by" of relation "invite_tokens" does not exist` | Migrations: `created_by UUID`, `first_name TEXT`, `last_name TEXT`, `department TEXT`, `role TEXT` |
| 59 | `null value in column "id" of relation "users"` | Add `id, gen_random_uuid()` + `created_at, updated_at, NOW(), NOW()` to both `INSERT INTO users` in file |
| (inline) | `null value in column "created_at"` | Already bundled: `created_at, updated_at` added in cc-59 |
| 60 | User created in DB but can't log in | Add `AdminCreateUser` + `AdminSetUserPassword` to `complete-invite` after DB commits |
| 61 | `AccessDeniedException` on `AdminCreateUser` | IAM policy had no Cognito entries; `terraform plan` showed "no changes" (state drift). Fixed via `aws iam put-role-policy` CLI |
| 63 | `audit_log.org_id` is null | `complete-invite` has no `requireAuth` so `req.orgId` is null; pass `orgId` explicitly to `audit()` |

---

## Cognito Registration Pattern (`complete-invite`)

After all DB inserts succeed and `invite_tokens` is marked used:

```javascript
try {
  await cognitoClient.send(new AdminCreateUserCommand({
    UserPoolId: process.env.COGNITO_USER_POOL_ID,
    Username: inv.email,
    MessageAction: 'SUPPRESS',          // don't send Cognito's own welcome email
    TemporaryPassword: password,
    UserAttributes: [
      { Name: 'email',           Value: inv.email },
      { Name: 'email_verified',  Value: 'true' },
      { Name: 'custom:tenantId', Value: String(orgId) },  // required for requireAuth JWT parsing
    ],
  }));
  await cognitoClient.send(new AdminSetUserPasswordCommand({
    UserPoolId: process.env.COGNITO_USER_POOL_ID,
    Username: inv.email,
    Password: password,
    Permanent: true,   // skip FORCE_CHANGE_PASSWORD state
  }));
} catch (cognitoErr) {
  if (cognitoErr.name !== 'UsernameExistsException') {
    console.error('Cognito create user warning:', cognitoErr.message);
  }
  // Non-fatal — DB user created, Cognito can be retried
}
```

**Key rules:**
- `MessageAction: 'SUPPRESS'` prevents Cognito sending its own temporary-password email
- `AdminSetUserPassword(Permanent: true)` must immediately follow `AdminCreateUser` — otherwise the user lands in `FORCE_CHANGE_PASSWORD` state and can't log in with the password they chose
- `custom:tenantId` must be set — `requireAuth` extracts `orgId` from this claim in the JWT
- `UsernameExistsException` swallowed — safe to retry invite acceptance

---

## IAM Policy: Terraform State Drift

`terraform plan` showed "no changes" even though `aws iam get-role-policy | grep cognito` returned empty. Terraform state was drifted from the live policy.

**Fix:** get the live policy, append the statement, put it back directly:

```bash
# Get live policy
AWS_PROFILE=mfa aws iam get-role-policy \
  --role-name gunnerteam-dev-lambda-api \
  --policy-name lambda-api-policy \
  --query 'PolicyDocument' --output json > /tmp/policy.json

# Append Cognito statement (one-liner)
python3 -c "import json; p=json.load(open('/tmp/policy.json')); p['Statement'].append({'Effect':'Allow','Action':['cognito-idp:AdminCreateUser','cognito-idp:AdminSetUserPassword','cognito-idp:AdminDeleteUser'],'Resource':'arn:aws:cognito-idp:us-east-2:*:userpool/us-east-2_hFVBSrcnn'}); open('/tmp/policy-updated.json','w').write(json.dumps(p))"

# Apply
AWS_PROFILE=mfa aws iam put-role-policy \
  --role-name gunnerteam-dev-lambda-api \
  --policy-name lambda-api-policy \
  --policy-document file:///tmp/policy-updated.json
```

Also update `terraform/lambda-api.tf` to add the `CognitoAdmin` statement — otherwise the next `terraform apply` will clobber it:
```hcl
{
  Sid    = "CognitoAdmin"
  Effect = "Allow"
  Action = [
    "cognito-idp:AdminCreateUser",
    "cognito-idp:AdminSetUserPassword",
    "cognito-idp:AdminDeleteUser"
  ]
  Resource = "arn:aws:cognito-idp:${var.aws_region}:*:userpool/*"
}
```

---

## audit() on Unauthenticated Endpoints

`audit()` in `lib/audit.js` reads `req?.orgId` for the org context. `req.orgId` is only set by `requireAuth` middleware. Endpoints that skip `requireAuth` (like `complete-invite`, `forgot-password`) must pass `orgId` explicitly:

```javascript
// Wrong — req.orgId is null on unauthenticated endpoints
await audit({ action: 'auth.invite.completed', req, userId: user.id });

// Correct — pass orgId explicitly
await audit({ action: 'auth.invite.completed', req, orgId, userId: user.id });
```

The `orgId` for `complete-invite` comes from `inv.org_id` (the invite token row).

---

## users INSERT Pattern (masterdb)

`users` table in masterdb has no column DEFAULTs. Every INSERT must be fully explicit:

```javascript
await query(
  `INSERT INTO users
     (id, username, email, hashed_password, password_scheme,
      first_name, last_name, name, type, is_active, created_at, updated_at)
   VALUES (gen_random_uuid(),$1,$2,$3,'bcrypt',$4,$5,$6,'employee',TRUE,NOW(),NOW())
   RETURNING id, username, email, first_name, last_name`,
  [username, email, passwordHash, first, last, fullName]
);
```

Same rule applies to all `gt_*` tables.

---

## Stale Migration Removed

`ALTER TABLE user_devices ALTER COLUMN device_name DROP NOT NULL` — `device_name` column does not exist in masterdb `user_devices`. This line was failing every migration run silently. Removed in cc-61.
