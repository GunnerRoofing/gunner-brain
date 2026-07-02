---
type: session
title: GunnerTeam Cognito Auth Migration — API + iOS (cc-05 + cc-06)
created: '2026-05-22'
updated: '2026-05-22'
tags:
  - gunnerteam
  - cognito
  - auth
  - amplify
  - ios
  - swift
  - lambda
  - jwt
  - session
status: evergreen
related:
  - '[[tyler/gunnerteam/gunnerteam-api-aws-migration]]'
  - '[[tyler/masterdb/masterdb-architecture]]'
  - '[[gunnerteam/secure-coding-guide]]'
  - '[[gunnerteam/aws-environment]]'
---

# GunnerTeam Cognito Auth Migration — API + iOS (cc-05 + cc-06)

Full cutover of GunnerTeam auth from HS256 JWT (`POST /auth/login`) to Cognito RS256 JWKS verification on both the API and iOS app.

---

## cc-prompt-05 — API Cognito Migration

### Cognito app client created

```
Pool:      us-east-2_hFVBSrcnn  (gunner-masterdb-dev)
Client:    6m41qei5jq3nt46jler56im1cg  (gunner-team-web)
Flows:     ALLOW_USER_SRP_AUTH, ALLOW_REFRESH_TOKEN_AUTH, ALLOW_USER_PASSWORD_AUTH
Tokens:    8h access/ID, 30d refresh
```

`ALLOW_USER_PASSWORD_AUTH` was added after creation — required for dev/CLI smoke testing. iOS uses SRP.

SSM parameters stored at `/gunnerteam/dev/COGNITO_USER_POOL_ID` and `/gunnerteam/dev/COGNITO_CLIENT_ID` (matching `start.sh`'s existing `PATH_PREFIX="/gunnerteam/dev"` — not `/gunner/gunnerteam/dev/` as specified in the prompt).

### Files changed

**`src/lib/jwt.js`** — full rewrite:
- Kept `signToken` (HS256) for the invite/register flows that still issue legacy tokens
- Added `verifyCognitoToken(token)` — async, uses `aws-jwt-verify` (`CognitoJwtVerifier`, lazy singleton). Originally wrote with `jwks-rsa` but that pulls in `jose` v4 (pure ESM) which crashes Node.js 20 CJS Lambda at init — replaced before final deploy.
- JWKS handled internally by `aws-jwt-verify`; no manual JWKS URI config needed.

**`src/middleware/auth.js`** — full rewrite:
- `requireAuth`: verifies Cognito JWT → extracts `custom:tenantId` (orgId) + email → DB lookup to get masterdb UUID → populates `req.user`
- `req.user` shape identical to before (id, username, email, role, etc.) — zero downstream route changes
- `requireRole(...roles)`: unchanged signature
- `maybeAuth`: validates Cognito JWT if present, no-op if missing (SOC 2 gap, deferred per compliance backlog #33)
- `resolveUser(email, orgId)`: joins `users → user_organizations → user_app_roles → app_roles → apps → organizations`, filters by `app.slug = 'gunner-team'`

**`src/routes/auth.js`**:
- `POST /auth/login` → 410 Gone (entire body replaced with 7-line handler)
- Removed dead imports: `hashPassword`, `generateSalt`, `mapRole`, `ROLE_JOIN`

**`start.sh`**:
- Added `export COGNITO_USER_POOL_ID=$(fetch COGNITO_USER_POOL_ID)` and `COGNITO_CLIENT_ID`

### Smoke test
```bash
TOKEN=$(AWS_PROFILE=mfa aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id 6m41qei5jq3nt46jler56im1cg \
  --auth-parameters USERNAME=tyler.suffern@gunnerroofing.com,PASSWORD=<pw> \
  --region us-east-2 --query 'AuthenticationResult.IdToken' --output text)

cd ~/Documents/Gunner/GunnerTeam/gunnerteam-api && node -e "
process.env.COGNITO_USER_POOL_ID = 'us-east-2_hFVBSrcnn';
process.env.AWS_REGION = 'us-east-2';
const { verifyCognitoToken } = require('./src/lib/jwt');
verifyCognitoToken('$TOKEN')
  .then(c => console.log('OK — email:', c.email, 'tenantId:', c['custom:tenantId']))
  .catch(e => console.error('FAIL:', e.message));
"
```

JWKS endpoint was verified reachable (garbage token returned "signing key not found", not a network error).

### Deferred
Invite flow (`/auth/invite`, `/auth/complete-invite`, `/auth/register`) still issues HS256 tokens via `signToken`. `saveTokenPublic` in iOS still reads the legacy keychain path. Marked as compliance backlog #33.

---

## cc-prompt-06 — iOS Amplify Auth Migration

### Phase 1 — SPM (manual, not automated)
Add via Xcode → File → Add Package Dependencies → `https://github.com/aws-amplify/amplify-swift`. Add only `Amplify` + `AWSCognitoAuthPlugin`. Build fails with "unable to resolve module dependency" until this step is done.

### Files changed

**`GunnerTeam/APIConfig.swift`**:
```swift
enum CognitoConfig {
    static let userPoolId  = "us-east-2_hFVBSrcnn"
    static let appClientId = "6m41qei5jq3nt46jler56im1cg"
    static let region      = "us-east-2"
}
```

**`GunnerTeam/App/GunnerFormsApp.swift`** — full rewrite:
- `AppDelegate.configureAmplify()`: manual `AmplifyConfiguration` with `AuthCategoryConfiguration` (no `amplifyconfiguration.json` file needed)
- `registerDeviceToken`: now `async`, called via `Task { await AuthManager.shared.registerDeviceToken(token) }`
- `GunnerFormsApp.body`: unchanged routing logic (invite/reset/auth/content)

**`GunnerTeam/Auth/AuthManager.swift`** — full rewrite:
- `login(email:password:)` → `Amplify.Auth.signIn` → `fetchIdToken()` → `validate(token:)`
- `logout()` → `Amplify.Auth.signOut`
- `forgotPassword(email:)` → `Amplify.Auth.resetPassword` (sends code to email)
- `confirmResetPassword(email:newPassword:code:)` → `Amplify.Auth.confirmResetPassword` (new — step 2 of forgot flow)
- `token() async -> String?` → calls `fetchIdToken()` (now async)
- `@Published var currentToken: String` — updated after every successful `validate()`; used by sync view-body callsites
- `restoreSession()`: tries `Amplify.Auth.getCurrentUser()` first; falls back to legacy keychain
- `saveTokenPublic` kept for invite flow (writes to legacy keychain key `"gunnerforms.jwt"`)

**`GunnerTeam/Auth/LoginView.swift`**:
- `@State private var username` → `@State private var email`
- TextField: label `"Email"`, `.textContentType(.emailAddress)`, `.keyboardType(.emailAddress)`
- `auth.login(email: email, password: password)`
- Forgot sheet: 2-step flow. Step 1 = enter email → `forgotPassword`. Step 2 (after code sent) = enter code + new password → `confirmResetPassword`
- New state vars: `@State private var resetCode`, `@State private var newPassword`, `@State private var forgotStep: Int = 1`

### Phase 6 — callsite migration (53 callsites, 8 files)

`token()` changed from sync to async. Two replacement patterns:

| Context | Old | New |
|---------|-----|-----|
| Async functions (`guard let`, `await` already present) | `auth.token()` | `await auth.token()` |
| View body / sync functions (constructors, `.sheet`, `.fullScreenCover`) | `auth.token() ?? ""` | `auth.currentToken` |

**Pure-async files** (all callsites converted to `await`):
- `GunnerAssistantView.swift`, `ContentView.swift`, `VehicleInspectionView.swift`, `SettingsView.swift`, `AnnouncementsView.swift`

**Mixed-context files** (per-line classification):
- `VehicleInspectionHubView.swift`: lines 511, 1376, 1459, 3079, 3113 → `auth.currentToken`; all others → `await auth.token()`
- `GuidedTasksView.swift`: lines 451, 541 → `auth.currentToken`; lines 506, 566 → `await auth.token() ?? ""`
- `CompanyCamViews.swift`: line 439 → `auth.currentToken`; all others → `await auth.token()`

Build verified: `xcodebuild` → 0 Swift errors (only Amplify unresolved module until SPM step done).

---

## cc-prompt-06b — Amplify v2 Build Fixes

Six build errors from Amplify v2 API changes. All in 2 files + 1 new JSON:

1. `amplifyconfiguration.json` created — Cognito pool/client config read by `Amplify.configure()` at runtime. **Must be added to Xcode target membership manually** (File Inspector → GunnerTeam checked).
2. `configureAmplify()` simplified to `Amplify.configure()` — drops 12-line manual `AuthCategoryConfiguration` block.
3. `fetchIdToken()` — `AWSCognitoAuthSession` → `AuthCognitoTokensProvider` (from `AWSPluginsCore`); `tokens.idToken.tokenString` → `tokens.idToken`. Required adding `import AWSPluginsCore`.
4. `resetPassword(username:)` → `resetPassword(for:)`.
5. Both `signOut()` calls → `_ = await Amplify.Auth.signOut()` (returns `AuthSignOutResult` in v2).
6. 13 sync-function callsites (`CompanyCamViews.swift` + `VehicleInspectionView.swift`) had `await auth.token()` in non-async functions — changed to `auth.currentToken.isEmpty ? nil : auth.currentToken`.

---

## Deployment Debugging — jwks-rsa ESM crash + missing env vars

Two Lambda init crashes discovered after first deploy:

### Bug 1 — jwks-rsa ESM incompatibility
`jwks-rsa` internally `require()`s `jose` v4+ which ships as pure ESM. Node.js 20 CJS loader rejects this at module load — Lambda crashed before any handler ran (`INIT_REPORT Status: error` on every cold start).

**Fix:** replaced `jwks-rsa` with `aws-jwt-verify` (AWS's own library, CJS-native, no ESM dependency).

### Bug 2 — COGNITO_USER_POOL_ID undefined at module load
`CognitoJwtVerifier.create()` was called at module load time with `process.env.COGNITO_USER_POOL_ID`. The var was in SSM and in `start.sh`, but **`start.sh` is local/EC2 only** — Lambda env vars come from the function configuration, not from `start.sh`.

`COGNITO_USER_POOL_ID` and `COGNITO_CLIENT_ID` were never added to the Lambda's env block in Terraform.

**Fix (two parts):**
- Lazy-init the verifier on first call (`getVerifier()` singleton), not at module load
- Added vars directly to Lambda config via `aws lambda update-function-configuration`
- Added both to `lambda-api.tf` SSM data sources + env block so `terraform apply` doesn't clobber them

**Critical rule:** Any new env var added to SSM must ALSO be added to the Lambda env block in `terraform/lambda-api.tf`. `start.sh` is for local dev only — it is not the Lambda entrypoint.

### Final state
- Lambda v68, alias `live` → login working end-to-end
- Tyler's masterdb UUID confirmed: `3e3f0491-b16f-42cd-9437-028a4a3ad771`

---

## `user_devices` NOT NULL Fix

`PATCH /auth/device-token` was failing with NOT NULL constraint violation. Two columns were null:

1. **`updated_at`** — was missing from the INSERT. Fixed by adding explicit `NOW()` to both INSERT statements (line 133 register-flow + line 565 device-token handler).
2. **`device_name`** — column has NOT NULL but no DEFAULT and is never provided. Fixed with migration: `ALTER TABLE user_devices ALTER COLUMN device_name DROP NOT NULL`.

Migration added to `POST /auth/run-migrations` runner. Deployed to Lambda v65. Alias updated.

To run the migration post-deploy:
```bash
TOKEN=$(get Cognito token as above)
curl -X POST https://api-dev.team.gunnerroofing.com/auth/run-migrations \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json"
```

---

## Lambda Provisioned Concurrency — Intentionally Removed

`aws lambda list-provisioned-concurrency-configs` returns empty. This is correct and expected.

PC was removed from Terraform (`lambda-api.tf`) because it is **incompatible with weighted alias routing**. The comment in the file reads: `# Provisioned concurrency removed — incompatible with weighted alias routing`. The hot.md note about "PC=2" is stale from before that decision.

No action needed.

---

## OMP Settings — What Was Learned

OMP config (`~/.omp/agent/config.yml`) is fully readable and writable via filesystem. The Settings TUI (`/settings`) mirrors this file. Changes take effect at next session start.

Config tuning applied this session (already filed separately in [[meta/omp-config-tuning-2026-05-22]]):
- Added `task` and `commit` model roles
- Memory pipeline: `minRolloutIdleHours: 4`, `maxRolloutAgeDays: 60`, `summaryInjectionTokenLimit: 8000`
