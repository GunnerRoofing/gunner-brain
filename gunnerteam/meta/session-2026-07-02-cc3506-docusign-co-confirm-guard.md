---
type: session
title: "cc-3506: DocuSign Change Order Send Confirmation Guard"
created: 2026-07-02
updated: 2026-07-02
tags:
  - ios
  - change-orders
  - docusign
  - ux-safety
  - incident-response
status: complete
related:
  - "[[gunnerteam/meta/session-2026-07-02-cc3500-3501-totp-mfa-login-settings]]"
---

# cc-3506 — DocuSign Change Order Confirmation Guard

## Incident Background

A $1 "Test" change order was DocuSigned to a real homeowner. The root cause: `PDFChangeOrderView` auto-fills `signerEmail` via `fetchOwnerEmailIfNeeded()` with the live homeowner address, and the submit button previously called `submit()` directly with no intermediate confirmation step. Any accidental or test tap on "Send Change Order" fired a live DocuSign request immediately and irreversibly.

cc-3504 guarded the Forms-tab `ChangeOrderView` (Monday board path) but missed this customer-facing PDF flow entirely.

## What Was Changed

**File:** `GunnerTeam/Jobs/ChangeOrders/PDFChangeOrderView.swift`

### State added
```swift
@State private var showConfirmSend = false
```

### Submit button action (before → after)
Before: tapping "Send Change Order" called `Task { await submit() }` directly.

After:
```swift
guard formIsValid, !isSubmitting else { return }
UIImpactFeedbackGenerator(style: .medium).impactOccurred()
focusedField = nil
showConfirmSend = true
```

### Confirmation dialog (added as modifier on the Button)
```swift
.confirmationDialog("Send this change order?",
                    isPresented: $showConfirmSend, titleVisibility: .visible) {
    Button("Send DocuSign to \(signerEmail)") { Task { await submit() } }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("A DocuSign signature request for $\(changeOrderAmt) will be emailed to \(signerName) at \(signerEmail) immediately. This cannot be unsent from the app.")
}
```

The dialog interpolates the **actual auto-filled `signerEmail`** and the **entered `changeOrderAmt`** — the sender must visually confirm the real recipient and dollar amount before proceeding.

## Behavior

- Tapping "Send Change Order" → dialog appears showing recipient email and dollar amount
- "Send DocuSign to `<email>`" → calls `submit()` exactly once; `isSubmitting` spinner activates normally
- "Cancel" → dismisses dialog; form state fully intact; nothing submitted
- Form is visually unchanged until the submit tap
- All pre-existing button modifiers (`.disabled`, `.listRowBackground`, `.foregroundColor`) preserved

## Build & Deploy

- `xcodebuild -scheme GunnerTeam -destination 'generic/platform=iOS Simulator' build` → **BUILD SUCCEEDED**, zero errors
- Committed to `main`: `7c9e020` — `cc-3506: confirm (with recipient + amount) before DocuSign change-order send`
- Version bumped 3.3.3 → **3.3.4** (build 17) to open a new TestFlight train (3.3.3 was already approved/closed)
- TestFlight build **3.3.4 (17)** uploaded and processing — includes cc-3502..3506
- Version bump committed: `56d3a91` — `bump: 3.3.4 (17) for cc-3502..3506 TestFlight distribution`

## Key Technical Notes

- `.confirmationDialog` must be attached **to the Button itself**, not to the enclosing `Section` — attaching it outside the Section's closing brace silently misplaces it as a modifier on a view that isn't presented
- `showConfirmSend = true` replaces the direct `Task { await submit() }` in the button action; `submit()` is only called from inside the dialog's confirm action
- Version 3.3.3 was already an approved App Store version — its pre-release train was closed to new builds; bumping `MARKETING_VERSION` in `project.pbxproj` was required before the upload could succeed

## Commits

| Hash | Message |
|---|---|
| `7c9e020` | cc-3506: confirm (with recipient + amount) before DocuSign change-order send |
| `56d3a91` | bump: 3.3.4 (17) for cc-3502..3506 TestFlight distribution |
