---
type: session
title: session-2026-06-20-cc2117-ios-jailbreak-detection
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - ios
  - security
  - soc2
  - device-integrity
  - jailbreak
status: stable
related:
  - '[[meta/session-2026-06-20-cc2116-ios-cert-pinning]]'
  - '[[gunnerteam/aws-environment]]'
---

# Session cc-prompt-2117 — iOS jailbreak / tamper detection (CC6.1 / CC6.8)

Defense-in-depth device-integrity control that travels with the white-label build to
BYOD/consumer devices where Hexnode MDM is absent. **Pilot = report-only (no hard block)** so a
false positive can't lock out the tester. Commit `e5eee61`, build SUCCEEDED, 9 unit tests pass.

## Phase 1 — `App/JailbreakDetector.swift`
`@MainActor struct`, self-contained, **injectable probes** so heuristics unit-test without a JB
device. Checks (any hit ⇒ suspected):
- artifact paths: Cydia/Sileo apps, `/bin/bash`, `/usr/sbin/sshd`, `/etc/apt`,
  `/private/var/lib/apt`, `/usr/libexec/cydia`.
- `canOpenURL` for `cydia://` / `sileo://` / `zbra://` (schemes added to Info.plist
  `LSApplicationQueriesSchemes`, else iOS returns false for unlisted schemes).
- suspicious dylibs via `_dyld_image_count`/`_dyld_get_image_name` (MobileSubstrate, Substrate,
  FridaGadget, frida, cycript, libhooker, SSLKillSwitch, TweakInject).
- sandbox-escape probe: write to `/private/jb_probe_<uuid>.txt`, delete; success ⇒ breached.

**`#if targetEnvironment(simulator)` → returns false** (the simulator shares the Mac filesystem
where `/bin/bash` etc. exist — would false-positive). Normal devices also return false.

## Phase 2 — `App/DeviceIntegrityMonitor.swift` (graduated, flag-gated)
- Pilot/supervised (now): **report + audit, do NOT block.** Best-effort POST
  `device.integrity_failed` (no PII — hardware model via `utsname` + OS) over the pinned
  `API.session` (cc-2116) + a non-blocking orange warning banner.
- `JAILBREAK_ENFORCE` (default **false**) gates a full hard-block screen for the
  white-label/public build.
- `.deviceIntegrityGate()` ViewModifier at the app root (`GunnerFormsApp`); runs on launch
  (`.task`) and every foreground (`scenePhase == .active`). Reporting fires once, only after a
  token is available.

## Phase 3 — verify
- iOS **build SUCCEEDED** (0 new warnings; only pre-existing CLGeocoder deprecations).
- `GunnerTeamTests/JailbreakDetectorTests.swift` — **9 cases pass**: simulator-never-flags
  (even with every artifact mocked present), normal-clean-not-flagged, each heuristic fires
  (Cydia path, apt dir, scheme, MobileSubstrate, FridaGadget, sandbox-escape), legit-frameworks
  -alone-not-flagged. No JB device available → mocked-probe unit tests per the prompt.
- Test registered to the `GunnerTeamTests` target via the **xcodeproj gem** (brew Ruby) — the
  test target uses **explicit pbxproj file refs**, NOT synchronized groups (unlike the main app
  target, where new source files auto-compile).

## Honest scope (for the control register)
**Deterrent + audit signal, NOT tamper-proofing** — Frida / Liberty Lite bypass in-app
detection. Value: (a) raising the bar on casual tampering, (b) being the device-integrity
control of record when MDM (Hexnode) is absent (white-label). Today, on the supervised fleet,
Hexnode remains the real control.

## Follow-ups
- **Backend (separate cc-prompt):** add `POST /device/integrity` → `audit({action:
  'device.integrity_failed', …})`. iOS-only here, so the client report is best-effort (swallows
  the 404) until the endpoint ships.
- **White-label release:** flip `JAILBREAK_ENFORCE` to true (or wire to remote config) to enable
  the hard block.
