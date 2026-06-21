---
type: session
title: session-2026-06-20-cc2118-retire-hs256
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - backend
  - ios
  - security
  - soc2
  - auth
  - cognito
  - deploy
status: stable
related:
  - '[[meta/session-2026-06-20-cc2116-ios-cert-pinning]]'
  - '[[gunnerteam/aws-environment]]'
---

# Session cc-prompt-2118 — Retire the legacy HS256 token end-to-end (CC6.1)

Single auth scheme: remove the second token format / attack surface. The only remaining HS256
issuance was the vestigial `signToken(...)` at the end of `POST /auth/complete-invite` (that
handler already provisions the user in Cognito). Commit `6ebb34e`, **deployed v331**, backend
now **Cognito-RS256-only**.

## Backend (`gunnerteam-api`)
- `routes/auth.js` complete-invite: removed `const jwtToken = signToken({...})` + `token:` from
  the 201 → now `{ role, user: {…email…} }`; removed the `signToken` import and the now-dead
  `orgSlug`/orgRes query (it only fed the token).
- `lib/jwt.js`: deleted `signToken`/`jwt.sign`, the `jsonwebtoken` require, the `SECRET`
  (`JWT_SECRET`) ref; kept `verifyCognitoToken` as the sole export.
- **Deleted dead `src/assistant-stream.js`** — unreferenced repo-wide (handler = `src/app.js`
  → `routes/assistant`), imported the never-exported HS256-era `verifyToken` (would throw at
  load if ever required). Last legacy-token vestige; clean-cutover removal.
- Grep confirms NONE remain: `signToken` / `jwt.sign` / `verifyToken` / `HS256` / `jsonwebtoken`
  / `JWT_SECRET`. `node --check` OK on both edited files. (The surviving `orgSlug` hits are the
  legitimate request-scoped `req.orgSlug` from the auth middleware — unrelated.)

## iOS (`GunnerForms`)
- `AcceptInviteView.complete()`: after a 201, calls `AuthManager.shared.login(email:password:)`
  (email from the accept-invite validation; the normal Cognito path: Amplify signIn →
  fetchIdToken → validate). No longer reads `token`. Graceful fallback to "please sign in" if
  auto-signin fails (brief Cognito propagation).
- `AuthManager.swift`: deleted `legacyKeychainKey` (`gunnerforms.jwt`), `saveTokenPublic`,
  `legacyToken`, `validateLegacy`, the three legacy keychain helpers, and the restoreSession
  legacy-keychain `else` branch (now just `isAuthenticated = false`). No legacy refs remain.

## Deploy + verify
- Full S3 deploy block; `--routing-config` via env var (`RC`) to dodge the bash-tool JSON
  mangling. **Serving v331** confirmed via CloudWatch log-stream `[331]` tags (get-alias lies).
- `/health` 200 ⇒ app loads ⇒ `jwt.js`/`auth.js`/middleware all load ⇒ `verifyCognitoToken`
  intact ⇒ **existing-user auth unaffected** (`/auth/validate` + the verifier are unchanged).
- `complete-invite` (bad token) → 400 "Invalid or expired invite" ⇒ route healthy, no
  502/ReferenceError from the `signToken` removal.
- iOS build SUCCEEDED.

## Limitation (honest)
The full invite → complete → Cognito-signin → authed E2E (and observing the
`auth.invite.completed` audit row on a real completion) was **not run** — sending an invite
needs admin Cognito creds (single-tester pilot; I don't hold them). The success path is
verified by code-read (returns `{role, user}` no token) + `node --check` + the iOS build + route
health. Recommend the tester/admin run a throwaway invite to confirm iOS auto-signin lands
authed. No orphaned HS256-only users exist (complete-invite has been creating Cognito users), so
deletion is safe.

## Follow-ups
- Remove `JWT_SECRET` SSM param + `lambda-api.tf` env line (separate Terraform change).
- Drop `jsonwebtoken` from `package.json` (now unused).
