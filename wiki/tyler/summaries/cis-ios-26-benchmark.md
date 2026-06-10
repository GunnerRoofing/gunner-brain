---
title: CIS Apple iOS 26 Benchmark v1.0.0 — Summary
type: summary
tags: [cis, ios, apple, iphone, benchmark, hardening, hexnode, mdm, study]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [CIS_Apple_iOS_26_Benchmark_v1.0.0.pdf]
related: ["[[vendors/hexnode]]", "[[concepts/apple-business-manager]]", "[[concepts/cis-ig1]]"]
---

# CIS Apple iOS 26 Benchmark v1.0.0 — Summary

**Source:** CIS_Apple_iOS_26_Benchmark_v1.0.0.pdf  
**Version:** v1.0.0 — October 31, 2025  
**Issuer:** Center for Internet Security (CIS)

## Two Profiles

| Profile | Section | Use Case |
|---------|---------|----------|
| End User-Owned Devices | Section 2 | BYOD or lighter corporate control |
| Institutionally-Owned Devices | Section 3 | Company-owned devices (Gunner's scenario) |

Gunner should apply **Section 3 (Institutionally-Owned)** recommendations to all Hexnode-managed iPhones.

## Key Recommendation Areas (Institutionally-Owned — Section 3)

### General
- Controls when the profile can be removed: set to **Never** — prevents users from unenrolling from Hexnode

### Restrictions
- Allow Siri while locked: **Disabled**
- Allow iCloud backup: **Disabled** (corporate data stays off personal iCloud)
- Allow iCloud documents & data: **Disabled**
- Allow managed apps to store data in iCloud: **Disabled** ✓ (Hexnode CIS IG1 policy)
- Force encrypted backups: **Enabled**
- Allow untrusted TLS certificates: **Disabled** ✓
- Force automatic date and time: **Enabled** ✓
- Allow documents from managed → unmanaged: **Disabled** ✓
- Allow documents from unmanaged → managed: **Disabled** ✓
- AirDrop as unmanaged destination: **Enabled** (treat AirDrop as unmanaged)
- Allow Handoff: **Disabled** ✓
- Show Control Center in Lock screen: **Disabled** ✓
- Allow adding VPN configurations: **Disabled**
- Allow Erase All Content and Settings: **Disabled** (user cannot factory reset)
- Allow trusting enterprise app authors: **Disabled**
- Allow installing configuration profiles: **Disabled**
- Require Touch ID / Face ID before AutoFill: **Enabled** ✓
- Allow proximity-based password sharing: **Disabled**
- Allow password sharing (supervised): **Disabled**

### Apple Intelligence (New — iOS 26)
- External Intelligence Extensions: **Disabled** ✓ (Hexnode already configured)
- Notes Summarization: **Disabled** ✓
- Mail Summarization: **Disabled** ✓
- Writing Tools: **Disabled** ✓

### Passcode
- Allow simple value: **Disabled** (require complex)
- Require alphanumeric: **Enabled**
- Min passcode length: 6+
- Max Auto-Lock: 2 minutes ✓
- Grace period for lock: Immediately ✓
- Max failed attempts: 6 (wipe after 10 failed) ✓

### Lock Screen Message
- "If Lost, Return to..." message: **Configured** — Gunner already has "Property of Gunner Roofing LLC." ✓

## Gap Analysis vs Gunner's Current Hexnode Policy

| Recommendation | Gunner Hexnode Policy | Gap? |
|---------------|----------------------|------|
| Profile removal = Never | Not documented | Verify |
| iCloud backup = Disabled | Configured | Likely ✓ |
| Erase All Content = Disabled | Not documented | Verify |
| Installing config profiles = Disabled | Not documented | Verify |
| Alphanumeric passcode | "Simple value allowed" in CIS IG1 | Possible gap — CIS IG1 policy allows simple |
| Force Touch ID before AutoFill | Not documented | Verify |

> **Note on passcode policy:** Gunner's current Hexnode CIS IG1 iPhone policy allows "simple value" for passcode. The CIS iOS 26 benchmark (Section 3) requires alphanumeric and disables simple value. Consider updating Hexnode policy to align.

## CIS Controls v8 IG1 Mapping

The benchmark appendix maps recommendations to CIS Controls v8 IG1. Key IG1-mapped controls:
- CIS 4 (Secure Configuration) — majority of Section 3 recommendations
- CIS 5 (Account Management) — Touch ID, passcode settings
- CIS 11 (Data Recovery) — encrypted backups, iCloud settings

## Appendices

- Summary Table (p. 249)
- CIS Controls v7 IG1/IG2/IG3 mapped recommendations
- CIS Controls v8 IG1/IG2/IG3 mapped recommendations (p. 273)
