---
title: CIS Chrome Enterprise Core Browser Benchmark v1.0.0 — Summary
type: summary
tags: [cis, chrome, chrome-enterprise, benchmark, hardening, browser, study]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [CIS_Google_Chrome_Enterprise_Core_Browser_Benchmark_v1.0.0.pdf]
related: ["[[vendors/google-workspace]]", "[[concepts/cis-ig1]]", "[[vendors/hexnode]]"]
---

# CIS Chrome Enterprise Core Browser Benchmark v1.0.0 — Summary

**Source:** CIS_Google_Chrome_Enterprise_Core_Browser_Benchmark_v1.0.0.pdf  
**Version:** v1.0.0 — June 30, 2025 (first version)  
**Tested Against:** Chrome v138  
**Issuer:** Center for Internet Security (CIS)

## Significance

This is the **first dedicated CIS Benchmark for Chrome Enterprise Core** (the free MDM-integrated version of Chrome that Gunner uses). Previously, Chrome guidance was folded into OS-level benchmarks. This standalone document is the authoritative hardening reference for Gunner's Chrome deployment.

> Chrome Enterprise Core is also the key technical gate for the JAMF evaluation — this benchmark clarifies what Gunner is protecting and why Chrome Enterprise integration matters.

## Coverage Areas

| Section | Key Recommendations |
|---------|-------------------|
| **Sign-in** | Force sign-in with @gunnerroofing.com; restrict account access |
| **Extensions** | Allowlist approach; block unknown sources; force-install approved list |
| **Security** | Safe Browsing enforcement; HTTPS-Only mode; SSL error bypass prevention |
| **Network** | DNS-over-HTTPS settings; proxy configuration |
| **GenAI** | Google Gemini, Copilot, and other AI feature controls |
| **Updates** | Auto-update enforcement; suppress user-initiated update disable |

## High-Priority Recommendations for Gunner

### Sign-in / Account Restriction
- Force Chrome sign-in with managed Google account — already a Gunner policy objective
- Restrict sign-in to `@gunnerroofing.com` only via `RestrictSigninToPattern`
- Block users from adding personal Google accounts in Chrome

### Extension Security
- Maintain extension allowlist via `ExtensionInstallAllowlist` (already configured via Chrome Enterprise Core)
- Block extensions from outside Chrome Web Store
- Force-install security extensions (e.g., Keeper, approved tools)

### Safe Browsing / Security
- Safe Browsing: Enhanced protection (L1)
- Prevent SSL error bypass — users cannot proceed through certificate warnings
- Block downloads from unverified or HTTP sources

### GenAI Controls
- Gemini in Chrome: disable or restrict to managed accounts only
- Note: Hexnode iPhone policy already disables Apple Intelligence; parallel Chrome GenAI controls reinforce this stance

### HTTPS-Only Mode
- Enable HTTPS-Only mode for all browsing
- Prevents protocol downgrade attacks

## Relationship to Existing Gunner Controls

| Control | Current State | Benchmark Target | Status |
|---------|--------------|-----------------|--------|
| Extension allowlist | Force-installed Keeper; allowlist set | Document and verify allowlist | ✅ Done — verify unknown extension ID |
| Account restriction | RestrictSigninToPattern = .*@gunnerroofing\.com | Restrict to managed domain | ✅ Closed |
| Safe Browsing | SafeBrowsingProtectionLevel = 2 | Enhanced | ✅ Closed |
| HTTPS-Only | HttpsOnlyMode = force_enabled | Enable | ✅ Closed |
| GenAI restrictions | GenAiDefaultSettings = 2, BuiltInAIAPIsEnabled = false | Disable/restrict | ✅ Closed |
| Developer Tools | DeveloperToolsAvailability = 0 (always on) | Disable (value 2) | ⚠️ Open |
| DNS-over-HTTPS | DnsOverHttpsMode = automatic | Secure (no fallback) | ⚠️ Open |

See full gap analysis: [[gunner/chrome-policy]]

## Key Note for JAMF Decision

Chrome Enterprise Core compatibility with Hexnode is confirmed and in use. If JAMF replaces Hexnode, JAMF's ability to manage Chrome Enterprise Core (and push these benchmark settings) must be verified. Loss of Chrome policy management would create a gap in CIS IG1 compliance (CIS 4, 6.2).

See: [[vendors/hexnode]] for JAMF evaluation status.
