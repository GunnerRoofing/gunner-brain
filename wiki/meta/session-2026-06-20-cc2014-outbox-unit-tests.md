---
type: session
title: session-2026-06-20-cc2014-outbox-unit-tests
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - ios
  - offline
  - outbox
  - testing
  - xcodeproj
status: stable
related:
  - '[[meta/session-2026-06-20-cc2013-bgtask-activate]]'
  - '[[meta/session-2026-06-20-cc2012-video-outbox]]'
---

# Session cc-prompt-2014 — Unit tests for the upload outbox (iOS)

**Phase 6 of offline mode.** Automate the outbox invariants that are easy to break
and hard to eyeball. Commit `63ccd91` on `main` (14 files +935 −60). 41 tests, green.

## Test-target setup (the hard part)

- Project had **no** test target / shared scheme; `objectVersion = 77` (Xcode 26.4,
  `fileSystemSynchronizedGroups`). Hand-editing pbxproj is fragile.
- Used the **`xcodeproj` Ruby gem 1.27.0** — NOT installable on macOS system Ruby 2.6;
  installed + run under **`/opt/homebrew/opt/ruby/bin/ruby`** (brew Ruby 4.0). Script:
  `/tmp/add_test_target.rb` (reusable). Gotcha: `Project#new_target`'s 5th arg is the
  **product group** (pass `nil`, not the project) or it raises `new_product_ref_for_target`.
- Added a **hosted** unit-test bundle `GunnerTeamTests` (TEST_HOST=app, BUNDLE_LOADER,
  GENERATE_INFOPLIST_FILE=YES, bundle id `com.gunner.team.tests`, deploy 26.0, Swift 5.0)
  + a **shared `GunnerTeam` scheme** with a Test action, so `xcodebuild test -scheme
  GunnerTeam` is deterministic. Files added as explicit refs (coexist with the app's
  synchronized group).
- **Gotcha:** hosted tests launch the app on the sim → first run failed
  `FBSOpenApplicationServiceErrorDomain Code=6 "Application failed preflight checks" (Busy)`.
  Fix: **boot the simulator first** (`xcrun simctl boot`), then run against `id=<UDID>`.
  Run cmd: `xcodebuild test -scheme GunnerTeam -destination 'id=<iPhone17 UDID>' -only-testing:GunnerTeamTests`.

## Approach — pure decision-point seams (no URLSession mocking)

Prompt sanctioned "protocol seam / decision points + don't rewrite executors." Extracted
behavior-preserving pure helpers the production code now calls, then tested those directly
→ zero network, ~0.03s for 41 tests.

- `App/OutboxLogic.swift` (new): `OutboxRecovery.recover`, `OutboxErrorPolicy.classify` /
  `.classifyTransfer` (+ `TransferDecision`), `OutboxItem.idempotencyKey`.
- `UploadOutbox` load/run/handleTransferCompletion call them; `deleteBlobs` made internal.
- Executor statics: `PhotoUploadExecutor.resumeAction`; `InspectionUploadExecutor
  .pendingFields/allFieldsUploaded`; `FormSubmitExecutor.needsCreate/
  pendingAttachmentIndices/allAttachmentsDone/createCategory`. Idempotency header now
  uses `item.idempotencyKey`.

## Coverage (6 files, 41 tests)

persistence round-trip + blob create/delete · restart recovery (bgTransferPending stays
.running, else →.waiting) · resume-no-dup (s3Key / uploaded.<field> / itemId) · idempotency
key stability across retries & decode · error classification (4xx→permanent no-budget,
409/5xx/network→transient, exhaustion→dead-letter, 403→re-presign) · finalize-once gates
idempotent under duplicate/out-of-order completions + unknown-item completion is a no-op.

## Verification

- `xcodebuild test` → **TEST SUCCEEDED**, 41/41, 0 failures, no network.
- **Deliberate-break spot-check:** inverted the recovery sentinel (`== nil` → `!= nil`) →
  4 recovery tests reddened with the invariant messages; **reverted** (tag back to original),
  re-ran → green. Break was never committed.

## Reusable facts

- Test run recipe is in this note + the shared scheme. `xcodeproj` gem lives on brew Ruby only.
- Pre-existing untracked `RECONCILE-REPORT-2026-06-19.md` left alone (not mine, unrelated).
