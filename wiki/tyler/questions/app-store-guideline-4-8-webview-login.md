---
title: "App Store Guideline 4.8 — WebView Login Fix"
type: question
tags: [ios, appstore, apple, webview, login, guideline-4-8]
created: 2026-04-21
updated: 2026-04-21
sources: []
related:
  - "[[gunner/gunner-forms-app]]"
status: stable
---

# App Store Guideline 4.8 — WebView Login Fix

## The Problem

Apple Guideline 4.8 requires that any app using a third-party login service must also offer an equivalent option (e.g. Sign in with Apple). A WebView app that displays an explicit app-level sign-in flow — even if the actual auth is handled by a third-party website — will trigger this rejection.

GunnerForms v1.01 was rejected (2026-04-09) because it had a dedicated "Sign in to Monday.com" screen and banner. Apple saw the Google SSO login (via Monday.com) as the app presenting a third-party login service.

**Why Sign in with Apple doesn't solve it here:** Employees use Google Workspace accounts to sign into Monday.com. Adding Sign in with Apple would create a separate, disconnected Monday.com account — useless for an enterprise app where accounts are managed by IT.

## The Fix

Remove all app-level sign-in UI. Let the website handle auth naturally inside the WebView.

**Removed:**
- `MondaySignInView` — dedicated sign-in screen
- `signInBanner` — "Sign in to Monday.com" card on the home screen
- Sign-out button in the header
- `@AppStorage("mondayLoggedIn")` state tracking
- `SharedWebViewRepresentable` (only used by sign-in flow)

**Result:** When an employee taps a form, Monday.com loads in the WebView. If they're not authenticated, Monday.com's own website presents the Google login — exactly as it would in Safari. The app itself never "offers" a login service.

The shared WebView session (`SharedWebViewConfig` singleton) is retained so login state persists across all forms once the user authenticates once.

## Reviewer Notes (Resolution Center)

> "This is an internal enterprise form launcher for Gunner Roofing employees. Sign-in credentials above are for a test account to access Monday.com forms. Authentication is handled entirely by Monday.com's website within the WebView — the app itself does not implement a login service. The Google login prompt that appears is part of Monday.com's own web authentication, identical to what would appear in Safari."

## Branch Preservation

The original sign-in flow is preserved in `feature/sign-in-with-monday` on the `gunner-ios` repo in case it is needed later.

## Generalizable Rule

Any iOS WebView app that wraps a third-party website with its own auth will trigger Guideline 4.8 if the app explicitly surfaces that login as a UI feature. The fix is to remove the app-level login UI entirely and let the embedded website handle auth on its own pages.
