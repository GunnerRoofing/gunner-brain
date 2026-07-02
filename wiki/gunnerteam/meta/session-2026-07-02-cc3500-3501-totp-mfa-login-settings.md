---
type: session
title: session-2026-07-02-cc3500-3501-totp-mfa-login-settings
created: '2026-07-02'
updated: '2026-07-02'
tags:
  - gunnerteam
  - ios
  - auth
  - mfa
  - cognito
  - security
status: stable
related:
  - '[[gunnerteam/overview]]'
  - '[[tyler/meta/session-2026-07-01-cc18-26-comms-admin-dialpad-backfill]]'
  - '[[tyler/concepts/mfa]]'
---

# Session cc-prompt-3500/3501 — TOTP MFA for GunnerTeam iOS: mandatory for admins, optional for everyone else

Repo: `GunnerForms/` (iOS-only, no backend/deploy changes — Cognito pool
`us-east-2_hFVBSrcnn` stays `MFA OPTIONAL`; enforcement is entirely client-gated,
with Cognito enforcing the challenge server-side once a user is enrolled).

Scope note vs. [[tyler/concepts/mfa]]: that page covers org-level MFA enforced
through Google Workspace (propagates to Google-SSO-connected apps). This session
is a separate, app-level control — GunnerTeam iOS's own Cognito user pool, TOTP
only, enrolled and enforced independently of Workspace/Google SSO.

## Problem

Tyler enrolled TOTP via the subportal web flow. `AuthManager.login()` had no
challenge path — `signIn` returned `isSignedIn=false` with
`nextStep=.confirmSignInWithTOTPCode` and dead-ended at a generic
"Sign-in incomplete" error. No enrollment UI existed at all.

## cc-3500 — login challenge handling + mandatory admin enrollment

**AuthManager.swift** — `login(email:password:)` now switches on `result.nextStep`
instead of a bare `isSignedIn` guard: `.done` → `completeSignIn()`,
`.confirmSignInWithTOTPCode` → sets `@Published var pendingTOTP = true`, anything
else → the old error. Added `confirmTOTP(code:)` (calls
`Amplify.Auth.confirmSignIn(challengeResponse:)`, throws on `!isSignedIn` so the UI
can show "Invalid code" and let the user retry) and `cancelTOTP()` (signs out +
clears `pendingTOTP` — abandons the half-open session cleanly). `completeSignIn()`
is the extracted tail (fetch token → `validate()` → push permission) shared by both
the direct-`.done` path and the post-TOTP path.

After `validate(token:)` sets `role`/`isAuthenticated`, admins additionally run
`checkMFAEnrollment()`, which sets `@Published var requiresMFAEnrollment`.

**LoginView.swift** — the card body branches on `auth.pendingTOTP`: normal
email/password fields, or a 6-digit code TextField (`keyboardType(.numberPad)`,
`textContentType(.oneTimeCode)`) + "Verify" (disabled unless `code.count == 6`) +
"Back to sign in" (→ `cancelTOTP()`).

**MFAEnrollmentView.swift** (new) — blocking full-screen setup for admins with no
TOTP enrolled: QR code generated locally via `CoreImage.CIFilterBuiltins`
(`CIFilter.qrCodeGenerator()`, no new dependency), manual-entry secret with a copy
button, 6-digit verify field, "Sign Out" as the only escape. Root-gated in
`ContentView.swift` via `.fullScreenCover(isPresented: auth.requiresMFAEnrollment)`
with `.interactiveDismissDisabled()`.

**White-label**: no org name anywhere in the new UI. otpauth issuer =
`Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName")`, falling back to
`CFBundleName` — the installed app's own display name, not a hardcoded string.

### Amplify Swift 2.58.1 API surface (verified against the local SPM checkout, not docs)

- `setUpTOTP()`, `verifyTOTPSetup(code:)`, `confirmSignIn(challengeResponse:)` are
  on the core `AuthCategoryBehavior` protocol → callable directly as
  `Amplify.Auth.setUpTOTP()` etc.
- `fetchMFAPreference()` and `updateMFAPreference(sms:totp:email:)` are **plugin-specific**,
  defined only in `AWSCognitoAuthPlugin+PluginSpecificAPI.swift` — not reachable via
  `Amplify.Auth`. Must fetch the concrete plugin first:
  `Amplify.Auth.getPlugin(for: "awsCognitoAuthPlugin") as? AWSCognitoAuthPlugin`.
  This is the documented Amplify pattern (confirmed via `aws-amplify/docs` on
  context7), not a version quirk — the prompt's example code that called
  `Amplify.Auth.fetchMFAPreference()` directly does not compile.
- `TOTPSetupDetails.getSetupURI(appName:accountName:)` throws and returns a real
  `URL` (not a plain string) — builds `otpauth://totp/<appName>:<accountName>?secret=…&issuer=<appName>`.
- `UserMFAPreference.enabled` is `Set<MFAType>?` (property name `enabled`, not
  `enrolled` as the prompt's sketch used) — check `.contains(.totp)`.
- `MFAPreference` (input enum for updates) has 4 cases: `.disabled`, `.enabled`,
  `.preferred`, `.notPreferred`.

## cc-3501 — optional opt-in/out for everyone via Settings

Follows immediately on cc-3500. Adds voluntary TOTP for managers/users/subcontractors
and a disable path for non-admins; admins see status but cannot disable (the
cc-3500 gate stays authoritative for them).

**AuthManager.swift** — added `@Published var totpEnrolled`, set by
`checkMFAEnrollment()` (admins) and a new `refreshMFAStatus()` (any role, called
from Settings `onAppear`). Extracted the repeated plugin-cast into a private
`cognitoPlugin: AWSCognitoAuthPlugin?` computed property, used by
`checkMFAEnrollment`, `refreshMFAStatus`, `finishTOTPSetup`, and the new
`disableTOTP()` — which guards `role != "admin"` (throws
"Two-factor authentication is required for administrator accounts." if violated)
before calling `updateMFAPreference(totp: .disabled)`.

**MFAEnrollmentView.swift** — added `enum Mode { case required, optional }` with
`var mode: Mode = .required` as the default parameter, so the existing cc-3500
`ContentView()` call site is untouched. `.optional` mode swaps the title/subtitle
copy, changes the bottom button from destructive "Sign Out" to secondary "Cancel"
(→ `dismiss()`), and `verify()` calls `dismiss()` on success instead of just
clearing `requiresMFAEnrollment`. No duplicated QR/verify/error-handling code —
same view, mode-branched chrome only.

**SettingsView.swift** — new "Security" section between the Account card and
User Management: a row showing "Two-Factor Authentication" / On / Off, tapping
opens `MFAEnrollmentView(mode: .optional)` as a sheet (not enrolled) or a
`confirmationDialog` "Turn off two-factor authentication?" (enrolled). The row
itself is `.disabled(auth.totpEnrolled && auth.role == "admin")` — belt-and-suspenders
with the manager-level guard in `disableTOTP()` — with a
"Required for administrator accounts." footnote shown to admins. Sheet
`onDismiss` calls `refreshMFAStatus()` so the row reflects sheet-driven
enrollment immediately without a manual pull.

## Verification

Both prompts: `xcodebuild -scheme GunnerTeam -destination 'generic/platform=iOS
Simulator' build` → **BUILD SUCCEEDED**, zero errors, zero warnings on any touched
file (checked explicitly against the raw build log, not just the tail). Committed
directly to `main` per each prompt's Swift-prompt rule (zero build errors required
before commit) — `8d27c3b` (cc-3500), `08c1d1e` (cc-3501).

## Key gotcha for future Amplify Swift MFA work

The plugin-specific vs. core-protocol split (`fetchMFAPreference`/`updateMFAPreference`
need the concrete `AWSCognitoAuthPlugin` cast; `setUpTOTP`/`verifyTOTPSetup`/`confirmSignIn`
don't) is easy to get wrong from memory or from an LLM's training data — the natural
guess is that all Auth category methods hang off `Amplify.Auth` uniformly. Always
verify against the pinned `Package.resolved` version's actual source (SPM checkout
under `DerivedData/.../SourcePackages/checkouts/amplify-swift/`) before writing
Cognito-plugin-specific calls, same as this session did.
