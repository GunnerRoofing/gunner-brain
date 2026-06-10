---
type: session
title: "cc-prompts 64–67: Password Policy, Cognito Email, Admin Reset"
created: 2026-05-27
updated: 2026-05-27
tags:
  - gunnerteam
  - cognito
  - ios
  - api
  - ses
  - password
status: stable
related:
  - "[[meta/session-2026-05-27-cc57-63-invite-registration-fix]]"
---

# cc-prompts 64–67: Password Policy, Cognito Email, Admin Reset

---

## Summary

| cc | Fix |
|---|---|
| 64 | `reset-password` handler: add `AdminSetUserPassword` after DB update so password reset syncs to Cognito |
| 65 | `complete-invite`: validate password against Cognito policy before any DB write; return clear 400 |
| 66 | Cognito pool `us-east-2_hFVBSrcnn`: switch to `DEVELOPER` email via SES, branded HTML template |
| 67 | Admin reset + all 3 iOS auth views: update password policy hint from "8 chars" to real policy; add `validatePasswordPolicy` + Cognito sync to `/admin-reset` |

---

## Password Policy Validator (auth.js)

Added as a module-level helper before the first route:

```javascript
function validatePasswordPolicy(password) {
  if (!password || password.length < 12)
    return 'Password must be at least 12 characters';
  if (!/[A-Z]/.test(password)) return 'Password must contain an uppercase letter';
  if (!/[a-z]/.test(password)) return 'Password must contain a lowercase letter';
  if (!/[0-9]/.test(password)) return 'Password must contain a number';
  if (!/[^A-Za-z0-9]/.test(password)) return 'Password must contain a special character';
  return null;
}
```

Called at the top of `complete-invite` and `admin-reset` before any DB or bcrypt operations. Returns a clear 400 with the specific failure message.

---

## Cognito Password Sync Pattern

Any handler that changes a user's password must call `AdminSetUserPassword(Permanent: true)` after the DB update. Needed in:
- `complete-invite` — new password set during invite acceptance
- `reset-password` — user-facing forgot-password flow
- `admin-reset` — admin resetting a user's password

Pattern (using `RETURNING email` on the UPDATE to avoid an extra SELECT):

```javascript
const result = await queryWithTenant(orgId,
  `UPDATE users SET hashed_password = $1, password_scheme = 'bcrypt', salt = NULL
   WHERE id = $2 RETURNING email`,
  [hash, userId]
);

try {
  if (result.rows[0]?.email) {
    await cognitoClient.send(new AdminSetUserPasswordCommand({
      UserPoolId: process.env.COGNITO_USER_POOL_ID,
      Username:   result.rows[0].email,
      Password:   plaintext,   // the password variable, before it goes out of scope
      Permanent:  true,
    }));
  }
} catch (cognitoErr) {
  if (cognitoErr.name !== 'UserNotFoundException') {
    console.error('Cognito password sync warning:', cognitoErr.message);
  }
}
```

`UserNotFoundException` is swallowed — expected for legacy DB-only users.

---

## Cognito SES Email (cc-66)

Pool `us-east-2_hFVBSrcnn` switched from `COGNITO_DEFAULT` (no-reply@verificationemail.com, 50/day, spam) to `DEVELOPER` (SES via gunnerroofing.com).

Update command (pool not managed by Terraform — direct CLI):

```bash
# Write template to file first (avoids shell escaping hell)
python3 << 'EOF'
import json
html = "... branded HTML with {####} code placeholder ..."
with open('/tmp/cognito-verify-template.json', 'w') as f:
    json.dump({
        "DefaultEmailOption": "CONFIRM_WITH_CODE",
        "EmailSubject": "Your GunnerTeam verification code",
        "EmailMessage": html
    }, f)
EOF

AWS_PROFILE=mfa aws cognito-idp update-user-pool \
  --user-pool-id us-east-2_hFVBSrcnn \
  --region us-east-2 \
  --email-configuration '{"EmailSendingAccount":"DEVELOPER","SourceArn":"arn:aws:ses:us-east-2:980921733684:identity/gunnerroofing.com","From":"GunnerTeam <noreply@gunnerroofing.com>"}' \
  --verification-message-template file:///tmp/cognito-verify-template.json
```

**Always include `--email-configuration` when calling `update-user-pool`** — omitting it resets `EmailSendingAccount` back to `COGNITO_DEFAULT`.

`{####}` is Cognito's literal placeholder for the verification code — do not change it.

The pool is NOT managed by Terraform. Changes via CLI are live immediately.

---

## iOS Password Validation (cc-67)

Three auth views updated:
- `SettingsView.swift` — admin edit user (reset password)
- `ResetPasswordView.swift` — user-facing forgot-password
- `AcceptInviteView.swift` — accept invite

Changes per file:
- `SecureField` placeholder: `"At least 8 characters"` → `"Min 12 chars, upper, lower, number & symbol"`
- Length guard: `count >= 8` → `count >= 12`
- Error string: `"Password must be at least 8 characters."` → `"Password must be at least 12 characters with uppercase, lowercase, number, and symbol."`

**Lesson:** When using a quick_task to change error message strings in Swift, always verify that the guard block's closing `}` and `return` are preserved — the agent can accidentally eat the block body when editing multi-line string values.

---

## macOS zip syntax

`--exclude` does not work on macOS `zip`. Use `-x` instead:

```bash
# Wrong (Linux-style):
zip -r /tmp/deploy.zip . --exclude "*.git*"

# Correct (macOS):
zip -r /tmp/deploy.zip . -x "*.git*"
```
