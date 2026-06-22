---
type: session
title: session-2026-06-20-cc1700-ios-password-checker
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - ios
  - swiftui
  - auth
  - ux
status: stable
related:
  - '[[meta/session-2026-06-20-cc2132-zod-input-validation]]'
  - '[[meta/session-2026-06-20-cc2125-forms-auth-lockdown]]'
---

# Session cc-prompt-1700 — iOS live password-requirements checker (invite + reset)

Real-time requirement checklist on the invite + reset screens so users see the rules and never submit
a password the backend would reject. Single source of truth mirroring the backend
`validatePasswordPolicy()`. iOS-only, NO deploy (Lambda stays v344). Commit `ef70a58` on `main`.

## Policy parity (verified 1:1)
Backend `gunnerteam-api/src/routes/auth.js validatePasswordPolicy()` (lines 46-58): `≥12`, `/[A-Z]/`,
`/[a-z]/`, `/[0-9]/`, `/[^A-Za-z0-9]/`. The Swift `PasswordPolicy.rules` regexes match each exactly.

## New component
`GunnerForms/GunnerTeam/Auth/PasswordPolicy.swift`:
- `PasswordRule` + `enum PasswordPolicy` (`rules` array + `isValid(_:)`).
- `PasswordRequirementsChecklist` view — one row per rule (✓ green `checkmark.circle.fill` when met,
  else `circle` secondary); an optional "Passwords match" row when `confirmPassword` is non-empty.
- Fixed a markdown-corrupted `HStack(spacing: 😎` from the prompt → `spacing: 8`.
- White-label clean: system semantic colors only (`.green`/`.secondary`/`.primary`), `.appCaption`,
  no `Color(hex:)`, no per-view palette, no brand strings. (`.appCaption` confirmed present.)

## Wiring (AcceptInviteView + ResetPasswordView)
- Checklist inserted after the form card / before the error block, shown `if !password.isEmpty`.
- Submit button `.disabled(... || !PasswordPolicy.isValid(password) || password != confirmPassword)`.
- The old `password.count >= 12` guard in `complete()` / `submit()` replaced with
  `guard PasswordPolicy.isValid(password)` (the `password == confirmPassword` match guard kept above).

## Verify
`xcodebuild build -scheme GunnerTeam` (sim iPhone 17) → **BUILD SUCCEEDED**. `PasswordPolicy.swift`
auto-compiled via the synchronized folder group (no pbxproj edit needed). Only warnings are the
pre-existing `CLGeocoder`/`reverseGeocodeLocation` deprecations in `PMJobViews.swift` (untouched). The
live checklist/disable behavior is deterministic from the SwiftUI bindings (verified by build +
construction; not run interactively).

## Maintenance note
⚠️ `PasswordPolicy.swift` and `auth.js validatePasswordPolicy()` are a deliberate dual-source mirror —
keep them in sync if either changes (the Swift file carries a comment saying so).
