---
type: synthesis
title: Chrome SafeSitesFilterBehavior Policy — Site Blocking Diagnosis
created: '2026-05-21'
updated: '2026-05-21'
tags:
  - chrome
  - hexnode
  - mdm
  - google-admin
  - policy
status: stable
related:
  - '[[hexnode]]'
  - '[[google-workspace]]'
  - '[[environment]]'
---

## Problem

Chrome displays "This page is blocked — Your organization doesn't allow you to view this site" for certain sites (e.g. 4chan) with no obvious cause.

## Root Cause

**`SafeSitesFilterBehavior: 1`** set via Chrome Browser Cloud Management (CBCM) in Google Admin Console.

Value `1` = "Block top-level sites containing adult content" using Google's Safe Sites API. Any site Google classifies as adult content is blocked OS-wide in Chrome with the organization block message.

## Diagnosis Path

1. Chrome policies aren't stored in `~/Library/Application Support/Google/Chrome/Default/Preferences` — that file only shows user-level prefs, not MDM-pushed policies.
2. The Mac has 9 Hexnode MDM profiles installed (`sudo profiles list -all`). The critical one is the "Supervised Devices Test Level 1" profile (`com.hexnode.mdm.2896017830`), which contains a `com.google.Chrome` Enterprise payload.
3. That payload only pushes a **CBCM enrollment token** (`8c0219ed-6ca7-4200-b604-5ce29cb57fbb`) — the actual policies live in **Google Admin Console**, not Hexnode.
4. The blocking policy is visible at `chrome://policy` in the browser.

## Fix

Google Admin Console → **Devices → Chrome → Settings → Users & browsers → Safe Sites filter**

Set `SafeSitesFilterBehavior` to `0` (disabled).

Change propagates within a few minutes on Chrome's next policy pull.

## Architecture Note

Hexnode MDM → pushes Chrome Enterprise enrollment token → Chrome enrolls in CBCM → Google Admin Console delivers all Chrome policies. Hexnode is the delivery mechanism; Google Admin is the policy source. These are two separate control planes.

## Policy Reference (Gunner Chrome Policy)

Key policies active on Gunner-managed Macs:

| Policy | Value | Effect |
|---|---|---|
| `SafeSitesFilterBehavior` | 1 | Blocks adult content sites |
| `ForceGoogleSafeSearch` | true | Forces SafeSearch on Google |
| `IncognitoModeAvailability` | 1 | Incognito disabled |
| `DeveloperToolsAvailability` | 0 | DevTools disabled |
| `DownloadRestrictions` | 4 | Blocks all downloads |
| `PasswordManagerEnabled` | false | No Chrome password manager |
| `BlockThirdPartyCookies` | true | 3P cookies blocked |
| `IdleTimeout` | 240 min → `sign_out` | Auto sign-out after 4h idle |
| `ExtensionInstallForcelist` | `bfogiafebfohielmmehodmfbbebbbpei` | Force-installs one extension |
