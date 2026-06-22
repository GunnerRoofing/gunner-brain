---
type: reference
owner: colin
app: GunnerCam
created: 2026-06-21
updated: 2026-06-21
tags: [wl-companycam, auth, cognito, google-sso]
status: active
---

# Cognito / Google SSO Login

Google SSO via Cognito Hosted UI is **code-complete but ships dormant** as of 2026-06-21. The only remaining blocker is creating a Google OAuth client in Google Cloud Console; the entire app-side surface is wired and tested. See [[colin/aws-infra]] for the Cognito pool topology and the broader auth/credential picture.

## Status (as of 2026-06-21)

| Item | State |
|---|---|
| App-side SSO code | Complete (login button, federated routes, IdP setup script) |
| Login-page Google button | Hidden — gated on `COGNITO_DOMAIN`, intentionally unset |
| Cognito identity providers registered | **Zero** (as of 2026-06-11) |
| Blocker | Google OAuth 2.0 Web client not yet created in Google Cloud Console |
| Password-change path (non-federated) | Live and verified in-session (2026-06-11) |

- The login-page Google button renders **only when `COGNITO_DOMAIN` is set**. `COGNITO_DOMAIN` is deliberately left commented in `.env.local` so a broken button never surfaces (decision 2026-06-11).
- Button gating runs through `cognitoOAuthConfigured()`, which checks `COGNITO_DOMAIN`.
- Until the Google OAuth client exists, users see **only username/password login**, so first-login is an operational dependency on Colin / admin staff (see Operational dependencies below).

## Cognito pool

| Item | Value |
|---|---|
| User pool ID | `us-east-2_sEOcsFA76` (`dev-gunner-cognito`, us-east-2) |
| Hosted UI / Cognito domain | Must be verified to exist on the pool before activation |

This is the same pool WL-CompanyCam uses for username/password auth (see [[colin/aws-infra]] §Cognito). Activation requires confirming the Hosted UI domain exists on this pool.

## Code surface

| Module / route | Role |
|---|---|
| `federated-auth.ts` | Federated (Google) login handling |
| `cognito-oauth.ts` | OAuth config (`cognitoOAuthConfigured()`) + Hosted UI plumbing |
| `/auth/google/` | Initiates the Hosted UI redirect to Google |
| `/auth/callback/` | Handles the Cognito `idpresponse` callback |
| `scripts/setup-cognito-google-idp.mts` | Registers the Google IdP on the pool |
| `src/components/account-settings.tsx` | Account UI; branches on `canChangePassword` |
| `/api/me/password` | Password-change route (non-federated users) |

## Activation procedure (to go live)

1. Create an OAuth 2.0 **Web** client in Google Cloud Console, using the Cognito `idpresponse` URI as the authorized redirect.
2. Verify the Hosted UI / Cognito domain exists on user pool `us-east-2_sEOcsFA76`.
3. Set env vars in `.env.local`: `COGNITO_DOMAIN`, `GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_CLIENT_SECRET`, `OAUTH_CALLBACK_URL`, `OAUTH_LOGOUT_URL`.
4. Run `scripts/setup-cognito-google-idp.mts` to register the IdP on the pool.

Setting `COGNITO_DOMAIN` is what flips `cognitoOAuthConfigured()` true and reveals the login-page Google button.

## Federated-user behavior

- **No JIT provisioning.** Unknown Google emails are **rejected**, not auto-created — a user must already exist locally.
- Federated users have the password-change UI hidden (`canChangePassword` false in `src/components/account-settings.tsx`); they see a "managed by Google" message.
- Non-federated password change: `/api/me/password` uses Cognito `ChangePassword` with the user's own access token, requires the correct current password, and was verified correct in-session (2026-06-11). A dev-auth fallback exists for local development (matches the `AdminSetUserPassword` shim noted in [[colin/aws-infra]] §Cognito).

## Operational dependencies & out-of-scope auth

- **Cognito invite emails are suppressed** (2026-06-15): new users get a permanent temp password that an admin must hand-deliver manually. The admin UI text explicitly instructs staff to do this. This is the same `MessageAction: "SUPPRESS"` + `Permanent: true` flow documented in [[colin/aws-infra]].
- **Out of scope per [[colin/mvp-roadmap]]:** password reset, email verification, and 2FA.
- Because SSO is dormant and invites are manual, first-login currently routes through Colin / admin staff for every new user.

## Open questions / TODOs (as of 2026-06-21)

- **Create the Google Cloud Console OAuth 2.0 Web client** — the sole remaining blocker to enabling SSO.
- After the OAuth client exists, set `COGNITO_DOMAIN` (and the other OAuth env vars) and run `scripts/setup-cognito-google-idp.mts` to register the IdP on the pool.
- Confirm / create the Hosted UI domain on pool `us-east-2_sEOcsFA76`.
