---
title: Chrome Enterprise Policy — Current State & CIS Gap Analysis
type: gunner
tags: [chrome, chrome-enterprise, policy, cis, hardening, gunner]
created: 2026-04-14
updated: 2026-04-14
status: stable
sources: [chrome-policy-export-2026-04-14.md]
related: ["[[vendors/google-workspace]]", "[[summaries/cis-chrome-enterprise-benchmark]]", "[[concepts/cis-ig1]]"]
---

# Chrome Enterprise Policy — Current State & CIS Gap Analysis

**Policy export date:** 2026-04-14  
**Machine:** tyler-MacBook-Pro | **Domain:** gunnerroofing.com  
**Benchmark:** CIS Chrome Enterprise Core Browser Benchmark v1.0.0 (June 2025)  
**Raw source:** raw-sources/runbooks/chrome-policy-export-2026-04-14.md

---

## Previously Flagged Gaps — Now Closed ✅

Both gaps called out in the CIS benchmark summary and lint report are resolved:

| Gap | Policy | Value | Status |
|-----|--------|-------|--------|
| Safe Browsing not Enhanced | SafeBrowsingProtectionLevel | 2 (Enhanced) | ✅ Closed |
| HTTPS-Only mode not confirmed | HttpsOnlyMode | force_enabled | ✅ Closed |
| GenAI not restricted | GenAiDefaultSettings + BuiltInAIAPIsEnabled | 2 + false | ✅ Closed |

---

## Remaining Gaps vs CIS Benchmark

### 1. Developer Tools Available to Users — Medium

```
DeveloperToolsAvailability: 0  →  should be 2
```

Value 0 = DevTools always available. CIS recommends disabling DevTools for managed users (value 2 = never allowed). DevTools can be used to bypass content policies, exfiltrate data, or tamper with web app sessions.

**Fix:** Change `DeveloperToolsAvailability` to `2` in Chrome Enterprise Core policy.  
**Exception if needed:** If any rep needs DevTools for a legitimate reason, create a separate OU for that user.

---

### 2. DNS-over-HTTPS on Automatic, Not Secure — Low

```
DnsOverHttpsMode: automatic  →  recommend: secure
```

`automatic` tries DoH but falls back to plain DNS if unavailable. `secure` enforces DoH with no fallback. For a managed fleet, `secure` is the correct posture — plain DNS fallback exposes queries to interception.

**Fix:** Change `DnsOverHttpsMode` to `secure`.  
**Note:** Verify `bt.gunnerroofing.com` (BrightTree) resolves correctly over DoH before enforcing, since it's in the auth server allowlist.

---

### 3. Download Restrictions Set to 4, Not 2 — Low

```
DownloadRestrictions: 4  →  consider: 2
```

Value 4 = block only verified-malicious downloads. Value 2 = block dangerous AND unusual/unverified downloads. CIS IG1 recommends 2 for broader coverage. Value 4 only catches confirmed-bad; value 2 adds a layer for unknown/suspicious files.

**Fix:** Change to `2` unless specific file types needed by ops are being blocked (test first).

---

### 4. Deprecated Policies — Admin Hygiene

Three policies are flagged as deprecated in the policy console and should be replaced or removed:

| Policy | Status | Action |
|--------|--------|--------|
| `ManagedAccountsSigninRestriction: primary_account` | Error, Deprecated | Replace with `ProfileSeparationSettings` (set to **Suggest profile separation**) — remove this policy |
| `PromotionalTabsEnabled: false` | Deprecated, Warning | Remove — functionality covered by other policies |
| `ProxyMode: system` | Deprecated, Warning | Replace with `ProxySettings: {"mode": "system"}` |

---

### 5. SyncTypesListDisabled Warning — Low

```
SyncTypesListDisabled: ["apps","autofill","passwords","wifiConfigurations"]
```

Shows a Warning in the console. The warning is likely because `passwords` sync is being disabled while `PasswordManagerEnabled` is already false — redundant but not harmful. `wifiConfigurations` may not be a valid type on this platform. Review and remove invalid types.

---

### ProfileSeparationSettings — Clarification

Confirmed value is **"Suggest profile separation"** (inherited from Google default) — Chrome prompts users to create a separate browser profile when signing in with a managed account, but does NOT enforce clipboard isolation or data separation. This setting does not cause copy/paste restrictions between Chrome profiles on Mac. Copy/paste issues between Chrome profiles on Mac are not caused by any policy in Gunner's stack (Hexnode Mac has no clipboard settings; Chrome Enterprise Core has no DLP). Likely causes: website-level JS paste blocks, or standard Chrome profile behavior.

## What's Well-Configured

The policy is strong overall. Notable well-configured items:

| Category | Policies | Notes |
|----------|----------|-------|
| **Sign-in lockdown** | BrowserSignin=2, RestrictSigninToPattern=@gunnerroofing.com, IncognitoModeAvailability=1, BrowserGuestModeEnabled=false | Fully locked to managed accounts |
| **Safe Browsing** | SafeBrowsingProtectionLevel=2, DisableSafeBrowsingProceedAnyway=true, SSLErrorOverrideAllowed=false | Enhanced + no bypass |
| **HTTPS** | HttpsOnlyMode=force_enabled, BasicAuthOverHttpEnabled=false | Full enforcement |
| **GenAI** | GenAiDefaultSettings=2, BuiltInAIAPIsEnabled=false, GenAILocalFoundationalModelSettings=1 | All AI features off |
| **Password security** | PasswordManagerEnabled=false (using Keeper), PasswordLeakDetectionEnabled=true, PasswordDismissCompromisedAlertEnabled=false | Keeper-only; forced breach alerts |
| **Privacy** | MetricsReportingEnabled=false, UrlKeyedAnonymizedDataCollectionEnabled=false, DomainReliabilityAllowed=false | Telemetry off |
| **Site isolation** | SitePerProcess=true, OriginKeyedProcessesEnabled=true | Both enabled |
| **Remote access** | RemoteDebuggingAllowed=false, RemoteAccessHostAllowRemoteSupportConnections=false, RemoteAccessHostFirewallTraversal=false | All disabled |
| **Crypto** | PostQuantumKeyAgreementEnabled=true, WebRtcPostQuantumKeyAgreement=true, EnableOnlineRevocationChecks=true | Forward-looking |
| **Extensions** | ExtensionDeveloperModeSettings=1, ExtensionInstallForcelist (Keeper), ChromeForTestingAllowed=false | Locked down |
| **Content** | ForceGoogleSafeSearch=true, ForceYouTubeRestrict=2, BlockThirdPartyCookies=true | Enforced |
| **Idle session** | IdleTimeout=240min, IdleTimeoutActions=sign_out | Automatic sign-out after 4hr |
| **Updates** | RelaunchNotification=2, RelaunchFastIfOutdated=7 | Forced update with 7-day fast-relaunch |

---

## Extensions Identified

| Extension ID | Name | Status |
|-------------|------|--------|
| `bfogiafebfohielmmehodmfbbebbbpei` | Keeper Password Manager | Force-installed, toolbar-pinned |
| `lmecinlocgbbcdgbhkidmeijhdhlngjp` | Dialpad Chrome CTI | On allowlist — required |

Both extensions confirmed. No action needed on allowlist.

---

## Priority Fix List

| Priority | Fix | Effort |
|----------|-----|--------|
| Medium | `DeveloperToolsAvailability` → 2 | 1 policy change in Chrome Enterprise Core |
| Low | `DnsOverHttpsMode` → secure | 1 policy change; test BrightTree first |
| Low | Remove 3 deprecated policies | Cleanup in Chrome Enterprise Core |
| Low | `DownloadRestrictions` → 2 | 1 policy change; test with ops files first |
| Low | Clean up `SyncTypesListDisabled` | Remove invalid sync types |
