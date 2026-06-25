---
type: decision
title: Subportal Cognito Auth
created: '2026-05-22'
updated: '2026-05-22'
decision_date: '2026-05-22'
status: active
tags:
  - subportal
  - cognito
  - auth
  - aws
  - sst
related:
  - '[[tyler/masterdb/masterdb-architecture]]'
  - '[[gunnerteam/secure-coding-guide]]'
  - '[[gunnerteam/aws-environment]]'
  - '[[tyler/gunnerteam/subportal-cc-prompt-01-scaffold]]'
---

# Subportal Cognito Auth

Cognito User Pool is live as of 2026-05-22. The subportal replaced HS256 JWT auth (GunnerTeam token) with Amplify SRP + API Gateway JWT authorizer. All code changes are in `~/Documents/Gunner/subportal/`.

---

## Live Infrastructure

| Resource | Value |
|---|---|
| Pool ID | `us-east-2_hFVBSrcnn` |
| Pool name | `gunner-masterdb-dev` |
| Web client ID | `79b78sb33ef3php9evd7jlctui` |
| Region | `us-east-2` |
| API Gateway URL | `https://m4523l05yb.execute-api.us-east-2.amazonaws.com` |
| Gunner tenant UUID | `69aad261-347c-44db-8e9e-6c25a8509aa3` |

## SSM Parameters

| Path | Value |
|---|---|
| `/gunner/subportal/dev/COGNITO_USER_POOL_ID` | `us-east-2_hFVBSrcnn` |
| `/gunner/subportal/dev/COGNITO_CLIENT_ID` | `79b78sb33ef3php9evd7jlctui` |
| `/gunner/subportal/dev/PLATFORM_ORG_ID` | `69aad261-347c-44db-8e9e-6c25a8509aa3` |

## Tyler's User

- Email: `tyler.suffern@gunnerroofing.com`
- Status: `CONFIRMED`
- `custom:tenantId`: `69aad261-347c-44db-8e9e-6c25a8509aa3`
- `custom:role`: `admin`
- Password: in 1Password (subportal entry)

---

## Architecture

### Pool configuration
- `usernameAttributes: ["email"]` — email is the login identifier
- `allowAdminCreateUserOnly: true` — **no self-registration ever**
- `generateSecret: false` on web client — SPAs cannot keep secrets
- `deletionProtection: "ACTIVE"`
- Token validity: 8h access/ID, 30d refresh
- Custom attributes: `custom:tenantId` (maps to `master.organizations.id`), `custom:role` (`admin | ops | sub`)

### API Gateway authorizer
All routes require Cognito ID token **except** `POST /jobs/sync` (HMAC-signed by Leo's system).

```
GET /subcontractors/search       → Cognito JWT required
GET /subcontractors/{id}/contact → Cognito JWT required
POST /admin/import               → Cognito JWT required
POST /jobs/sync                  → No JWT (HMAC only)
```

API Gateway verifies the JWT signature before Lambda runs. Lambda reads pre-verified claims from `event.request_context.authorizer["claims"]` — never decodes the token itself.

### Claim mapping in Lambda

```python
claims = event.request_context.authorizer["claims"]
org_id   = claims["custom:tenantId"]   # NEVER from request body
user_id  = claims["sub"]
username = claims["email"]
role     = claims["custom:role"]
```

`org_id` is **always** sourced from `custom:tenantId` — never accepted from request body, query params, or path params. (SOC 2 CC6.1, A07.)

---

## Frontend

Amplify SRP configured in `frontend/src/lib/auth.tsx`:

```typescript
Amplify.configure({
  Auth: {
    Cognito: {
      userPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID,
      userPoolClientId: import.meta.env.VITE_COGNITO_CLIENT_ID,
      loginWith: { email: true },
    },
  },
});
```

`getStoredToken()` is async — fetches the ID token from `fetchAuthSession()`.

### Local dev vs production

`.env.local` sets `VITE_API_URL=` (empty) so MSW handles all API calls locally. Set `VITE_API_URL` to the API Gateway URL only when pointing at the real backend.

---

## Adding a new user

```bash
POOL_ID="us-east-2_hFVBSrcnn"

AWS_PROFILE=mfa aws cognito-idp admin-create-user \
  --user-pool-id $POOL_ID \
  --username <email> \
  --user-attributes \
    Name=email,Value=<email> \
    Name=email_verified,Value=true \
    Name="custom:tenantId",Value="<org-uuid from master.organizations>" \
    Name="custom:role",Value=<admin|ops|sub> \
  --region us-east-2

AWS_PROFILE=mfa aws cognito-idp admin-set-user-password \
  --user-pool-id $POOL_ID \
  --username <email> \
  --password "<password>" \
  --permanent --region us-east-2
```

`custom:tenantId` must match the UUID in `master.organizations` for the user's tenant. Gunner Roofing's UUID is `69aad261-347c-44db-8e9e-6c25a8509aa3`.

---

## What was removed

- `python-jose[cryptography]` dependency from `requirements.txt` and `pyproject.toml`
- `_get_jwt_secret()`, `ALGORITHM`, `jwt.decode()` from `auth.py`
- `boto3`/SSM call for JWT secret at cold start
- `/auth/login` MSW handler (endpoint no longer exists)
- `sessionStorage` token management from frontend
- `subdomain` field from `LoginPage`

---

## SST notes

- SST 4 requires `uv` for Python dependency packaging — install with `curl -LsSf https://astral.sh/uv/install.sh | sh`
- `pyproject.toml` requires a `[project]` section with dependencies for `uv lock` to work
- `AWS_REGION` is a reserved Lambda environment variable — do not set it explicitly in SST function config
