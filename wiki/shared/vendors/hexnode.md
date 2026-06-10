---
title: Hexnode MDM
type: vendor
tags:
  - hexnode
  - mdm
  - vendor
  - mobile-device-management
  - apple
  - endpoint
created: 2026-04-13T00:00:00.000Z
updated: 2026-04-14T00:00:00.000Z
status: stable
sources:
  - Hexnode iPhone Policy (CIS IG1).xlsx
  - Hexnode iPhone Policy (Total Lockdown).xlsx
  - Hexnode Mac Policy (CIS IG1).xlsx
  - Hexnode Mac Policy (Total Lockdown).xlsx
  - System Security Plan.docx
  - new laptop set up.docx
  - New Phone setup.docx
related:
  - '[[gunner/environment]]'
  - '[[vendors/google-workspace]]'
  - '[[concepts/cis-ig1]]'
  - '[[runbooks/new-laptop-setup]]'
  - '[[runbooks/new-phone-setup]]'
  - '[[summaries/cis-ios-26-benchmark]]'
  - '[[summaries/cis-macos-26-benchmark]]'
  - '[[vendors/jamf]]'
---

# Hexnode MDM

## What It Does

Hexnode is the Mobile Device Management (MDM) platform used to enroll, configure, monitor, and remotely wipe all Gunner Roofing MacBooks and iPhones. It integrates with Apple Business Manager (ABM) via the Device Enrollment Program (DEP) for zero-touch provisioning.

## How It's Used at Gunner

- All company MacBooks and iPhones are enrolled
- Two policy tiers exist per device type: **CIS IG1** (standard) and **Total Lockdown** (reserved for high-risk or sensitive roles)
- Devices are named `GR-[last 6 of serial number]`
- Local accounts use the format `FirstInitial.LastName` (e.g., `b.blake`)
- FileVault recovery keys are escrowed to Hexnode ("Gunner Roofing Corporate Vault")
- Lock screen message: *"Property of Gunner Roofing LLC."*

## iPhone Business Container Policy (Both CIS IG1 and Total Lockdown)

Identical settings in both policies — confirmed from xlsx source files:

| Setting | Value | Effect |
|---------|-------|--------|
| Open documents from managed apps in unmanaged apps | **False** | Blocks copying managed content into unmanaged apps |
| Open documents from unmanaged apps in managed apps | **True** | Allows unmanaged content into managed apps |
| Manage Copy/Paste between managed/unmanaged apps | **True** | Enforces the above open-in restrictions on clipboard |
| Managed apps can write to Unmanaged Contact Accounts | False | |
| Unmanaged apps can read from Managed Contact Accounts | False | |
| Block Sharing Managed Document using AirDrop | **True** | AirDrop of managed docs blocked |

Managed web domains (hubspot.com, monday.com, adp.com, google.com) are treated as managed content. Copy/paste from those pages into unmanaged apps is blocked on iPhone. This does **not** apply to Mac — the Mac Hexnode policy has no clipboard settings.

## Apple Business Manager Integration

- Devices purchased through Apple Business Store are auto-added to ABM
- Devices purchased elsewhere must be manually added via Apple Configurator
- ABM account: `becky@gunnerroofingcom1.appleid.com` — credentials in Keeper
- New devices: Sync ABM → Hexnode DEP → assign owner → rename → create local account

## iPhone Policies

### CIS IG1 (Standard)

| Category | Key Settings |
|----------|-------------|
| Passcode | Simple value allowed; auto-lock enforced |
| Software Updates | 7-day deferral; security updates auto-install; no beta |
| Managed Email Domains | gunnerroofing.com |
| Managed Web Domains | hubspot.com, monday.com, adp.com, google.com |
| iCloud | Sync and backup managed; document sync restricted |
| AI Features | Apple Intelligence, ChatGPT integration — off |
| Data Isolation | Managed/unmanaged copy-paste enforced; AirDrop of managed docs blocked — see Business Container settings below |
| App Catalog | ADP Mobile, Google Chat, Keeper, Chrome, Calendar, Hexnode UEM, Drive, Gmail |
| Lock Screen | "Property of Gunner Roofing LLC." + serial number |

### Total Lockdown (Restrictive)

All CIS IG1 settings plus a significantly expanded app catalog and stricter controls:

Additional apps pushed: Google Gemini, My2N, Rhombus, Google Maps, Waze, WhatsApp, Dialpad, CompanyCam, ABC Supply, Chase Mobile, Amex GBT Mobile, Adobe Acrobat, DocuSign, Fellow, OneNote, PowerPoint, Word, Outlook, Monday, HubSpot

> **Note:** Total Lockdown policy has more apps pushed but is otherwise more restrictive on device functionality.

## Mac Policies

### CIS IG1 (Standard)

| Category | Key Settings |
|----------|-------------|
| Passcode | Complex required; 15-min lockout after max failed attempts; 48-hr fingerprint timeout |
| FileVault | Enabled; recovery key escrowed to Hexnode IT vault |
| Firewall | Enabled with stealth mode + logging (detail level); blocks incoming unless signed |
| Login Window | Name and password entry (not username list); Sleep/Restart/Shutdown buttons hidden |
| App Install | Mac App Store + identified developers only; admin approval required |
| External Media | Read-only |
| Optical Media | Denied |
| Screen Capture | Managed; bypass alert available for IT |
| iCloud | Auto-upload of Desktop/Documents: disabled; iCloud Keychain sync: off |
| Required Apps | Google Chrome Enterprise, Google Drive |
| AI Features | Apple Intelligence, ChatGPT integration — off |
| App Notifications | Keynote, Spotify, Fellow, Monday, Dialpad, Word, PowerPoint configured |
| Managed Domains | gunnerroofing.com; Cross-site tracking relaxed for google.com, hubspot.com |
| Privacy Permissions | Monday.com: Documents, Accessibility, Downloads, Desktop; Chrome: All Files |
| OS Updates | Download and Install automatically |
| AirDrop | Managed |

### Total Lockdown (Restrictive)

Same as CIS IG1 with additional restrictions. Reserved for high-security use cases.

## Incident Response — Device

| Scenario | Action |
|----------|--------|
| Lost or stolen device | Remote wipe via Hexnode |
| Employee offboarding | Change owner, remove from policy, initiate wipe |
| Policy compliance check | Hexnode compliance dashboard |

## CIS Controls Satisfied

| CIS Control | How Hexnode Satisfies It |
|-------------|--------------------------|
| CIS 1.1 | Hardware inventory — all enrolled devices visible in dashboard |
| CIS 4.1 | Compliance auditing — dashboard reports non-compliant devices |
| CIS 7 | OS & patch management — update deferral + auto-install configured |
| CIS 11 | Data recovery — FileVault + escrowed recovery keys |

## Vendor Comparison — JAMF vs Hexnode

[[vendors/jamf|JAMF]] is under evaluation as a potential MDM replacement or supplement. Approval expected late April 2026. Key comparison:

| Factor | JAMF | Hexnode |
|--------|------|---------|
| Mac pricing | ~$150/device/yr | Included in Hexnode total |
| iPhone pricing | ~$69/device/yr | Included in Hexnode total |
| Hexnode total (current contract) | — | $6,336/yr |
| Chrome Enterprise Core | Compatibility requires investigation | Compatible (in use) |

**Open question:** Chrome Enterprise Core is currently used for CIS IG1 browser hardening. JAMF's compatibility with Chrome Enterprise must be confirmed before any transition. This is the key technical gate for approval.

## CIS Benchmark Alignment

New CIS Benchmarks (October 2025) are now in the vault and provide the authoritative hardening baseline for Hexnode-managed devices:

| Benchmark | Version | Key Gap Identified |
|-----------|---------|-------------------|
| [[summaries/cis-ios-26-benchmark]] | v1.0.0 (Oct 2025) | Passcode policy — CIS IG1 allows "simple value"; benchmark requires alphanumeric for institutionally-owned devices |
| [[summaries/cis-macos-26-benchmark]] | v1.0.0 (Oct 2025) | Audit log retention not documented; sharing service disable list should be verified |

**Recommended next step:** Run a gap analysis of current Hexnode iPhone and Mac CIS IG1 policies against the new benchmarks. Priority items:
1. iPhone: disable "Allow simple value" for passcode — upgrade to alphanumeric
2. Mac: verify all sharing services are explicitly disabled in Hexnode policy
3. Mac: document audit log retention approach

## Runbooks

- [[runbooks/new-laptop-setup]] — Full process for enrolling a new MacBook
- [[runbooks/new-phone-setup]] — Full process for enrolling a new iPhone
