---
type: session
title: session-2026-06-20-cc2116-ios-cert-pinning
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - ios
  - security
  - soc2
  - tls
  - certificate-pinning
status: stable
related:
  - '[[meta/session-2026-06-20-cc2102-db-tls-verify]]'
  - '[[gunnerteam/aws-environment]]'
---

# Session cc-prompt-2116 — iOS SPKI certificate pinning (API domain, CC6.7)

Pin the app's API TLS connection so a forged / mis-issued cert (rogue CA, MITM) can't
impersonate the API. Pilot (one device). Commit `4fd3ef9`, build SUCCEEDED.

## Pins (Phase 1 — extracted from the live chain, not guessed)
`api-dev` and `api.team.gunnerroofing.com` share one ACM chain:
- leaf `CN=api.team.gunnerroofing.com` → `9y62bP…CK4=` — **NOT pinned** (rotates on renewal).
- intermediate `Amazon RSA 2048 M04` → `G9LNNAql897egYsabashkzUCTEJkWBzgoEtk8X/678c=` — **primary**.
- root `Amazon Root CA 1` → `++MBgDH5WGvL9Bcn5Be30cRcL0f5O+NyoXuWtQdX1aI=` — **backup** (survives an
  intermediate rotation; matches Amazon's authoritative AmazonRootCA1.pem).

## Implementation (Phase 2)
- New `App/CertificatePinning.swift`: `PinnedSessionDelegate: NSObject, URLSessionDelegate`,
  **nonisolated** (required — project builds `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor`, and the
  delegate runs on URLSession's background queue + is constructed from a nonisolated static).
  Handler: server-trust + pinned-host only → standard `SecTrustEvaluateWithError` (chain +
  hostname) THEN SPKI-SHA256 pin check (rebuild SPKI = RSA-2048 ASN.1 header +
  `SecKeyCopyExternalRepresentation`, CryptoKit `SHA256`); ANY chain cert matches → `.useCredential`,
  else `.cancelAuthenticationChallenge` (**fail closed**); every other host → `.performDefaultHandling`.
- `API.session` (pinned URLSession, `.default` config) added to `APIConfig.swift`.
- The app had **no central networking helper** — `URLSession.shared` was used in ~178 places.
  Migrated ALL of them → `API.session`. Because the delegate passes through non-API hosts, the
  blanket swap is safe and keeps Amplify/Cognito (its own session) + S3 presigned on standard
  trust. Mechanics: 129 via `ast_edit`; tree-sitter-swift hit parse errors on 16 modern-Swift
  files → the remaining 49 done via a precise Python string-replace (`eval`), excluding the
  APIConfig doc comment.

## Verification (Phase 3)
- iOS **build SUCCEEDED** (only pre-existing `CLGeocoder` deprecations in PMJobViews; 0 new
  warnings) — proves the delegate + nonisolated isolation + 178 migrated sites compile.
- Pinning logic vs the LIVE api-dev chain (standalone Swift, delegate parameterized on the pin
  set so no app edit/revert needed):
  - correct pins → `/health` **200** (live chain matches → app works),
  - corrupt pins → **ERROR -999 cancelled** (fail-closed enforcement, not passive accept),
  - non-pinned host (amazon.com) → **200** (pass-through ⇒ Cognito/Amplify + S3 unaffected).
- Full interactive sign-in/job-load not run (needs device+auth) — covered by build + live
  pin-match + behavior-equivalent session swap + Amplify using its own session.

## ⚠️ cc-2110 dependency (load-bearing)
When the Cloudflare proxy is enabled, the app will see **Cloudflare's** chain, not Amazon's —
the pins in `CertificatePinning.swift` MUST be updated to Cloudflare's intermediate **in the
same release** that flips the proxy, or every API call hard-fails. Flagged in tyler/hot.md.

## Reusable facts
- Project uses **file-system synchronized groups** (PBXFileSystemSynchronizedRootGroup) — new
  `.swift` files in a synced folder are auto-compiled; no xcodeproj-gem dance for source files
  (only needed for new *targets*, cf. cc-2014).
- SPKI pin = `openssl x509 -pubkey | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64`,
  reproduced in-app via RSA-2048 ASN.1 header + SecKey external representation.
- ast_edit (tree-sitter-swift) can't parse some modern Swift files → falls back to skipping
  them; verify with a follow-up `search` and patch stragglers.
