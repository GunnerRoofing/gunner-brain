---
title: CIS Apple macOS 26 Tahoe Benchmark v1.0.0 — Summary
type: summary
tags: [cis, macos, apple, mac, benchmark, hardening, hexnode, filevault, study]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [CIS_Apple_macOS_26_Tahoe_Benchmark_v1.0.0.pdf]
related: ["[[vendors/hexnode]]", "[[concepts/apple-business-manager]]", "[[concepts/cis-ig1]]"]
---

# CIS Apple macOS 26 Tahoe Benchmark v1.0.0 — Summary

**Source:** CIS_Apple_macOS_26_Tahoe_Benchmark_v1.0.0.pdf  
**Version:** v1.0.0 — October 31, 2025  
**Issuer:** Center for Internet Security (CIS)

## Structure (7 Sections)

| Section | Focus |
|---------|-------|
| 1 | Install Updates, Patches and Additional Security Software |
| 2 | System Settings |
| 3 | Logging and Auditing |
| 4 | Network Configurations |
| 5 | System Access, Authentication and Authorization |
| 6 | Applications (Finder, Mail, Safari, Terminal, Passwords) |
| 7 | Supplemental (MDM, Mobile Config Profiles, APNs) |

## High-Priority Recommendations for Gunner

### Section 1 — Updates
- Apple-provided Software Updates installed: **Automated** ✓ (Hexnode update policy)
- Download new updates when available: **Enabled** ✓
- Install macOS updates: **Enabled** ✓
- Install App Store updates: **Enabled** ✓
- Install Security Responses and System Files: **Enabled** ✓
- Update deferment: ≤30 days (Hexnode uses 7-day deferral — more restrictive, compliant) ✓

### Section 2 — System Settings

**Apple Account / iCloud**
- iCloud Drive Document and Desktop Sync: **Disabled** ✓ (Hexnode Mac CIS IG1 policy)
- Freeform Sync to iCloud: Audit (Manual)
- App Store Password Settings: Audit

**Network**
- Firewall enabled: **Automated** ✓ (Hexnode Mac policy has firewall + stealth mode)
- Firewall Stealth Mode: **Enabled** ✓

**Sharing (Critical — all should be Disabled)**
- Screen Sharing: **Disabled** ✓
- File Sharing: **Disabled** ✓
- Printer Sharing: **Disabled** ✓
- Remote Login (SSH): **Disabled** ✓
- Remote Management: **Disabled** ✓
- Remote Apple Events: **Disabled** ✓
- Internet Sharing: **Disabled** ✓
- Content Caching: **Disabled** ✓
- Media Sharing: **Disabled** ✓
- Bluetooth Sharing: **Disabled** ✓

**Apple Intelligence & Siri (New — macOS 26)**
- External Intelligence Extensions: **Disabled** ✓ (Hexnode already configured)
- Writing Tools: **Disabled** ✓
- Mail Summarization: **Disabled** ✓
- Notes Summarization: **Disabled** ✓
- Siri: **Disabled** (Automated)
- Listen for Siri: **Disabled** (Manual)

**Privacy & Security**
- Analytics: Disabled ✓
- Gatekeeper: **Enabled** ✓ (Mac App Store + identified developers only — matches Hexnode policy)
- **FileVault: Enabled** ✓ (Hexnode escrows recovery key)
- Admin password for system-wide preferences: **Enabled** ✓

**Lock Screen**
- Inactivity interval ≤15 minutes for screen saver ✓
- Require password immediately after sleep/screen saver ✓
- Custom login screen message: **Enabled** ✓ ("Property of Gunner Roofing LLC.")

**Users & Groups**
- Guest Account: **Disabled** ✓
- Guest access to shared folders: **Disabled** ✓
- Automatic Login: **Disabled** ✓

### Section 3 — Logging and Auditing
- Security Auditing enabled: **Automated**
- Security audit retention ≥365 days: **Automated**
- Access to audit records controlled: **Automated**
- Software inventory audit: **Manual** (periodic review)

> Gunner currently has no formal log retention policy. Google Admin audit logs + Hexnode logs are the primary sources, but formal retention/review cadence is not documented. This is a gap.

### Section 5 — Authentication

**File System Permissions**
- System Integrity Protection (SIP): **Enabled** ✓
- Apple Mobile File Integrity (AMFI): **Enabled** ✓
- Signed System Volume (SSV): **Enabled** ✓

**Account and Password Policy**
- Password lockout threshold: **Configured** ✓ (Hexnode: 15-min lockout after max failed)
- Password minimum length: Configured ✓
- Complex password requirements: Manual review

**Encryption**
- All APFS volumes encrypted: **Manual** (FileVault covers system volume; verify user volumes)
- Sudo Timeout = 0: **Automated** (re-auth required for each sudo — high security)
- Root account: **Disabled** ✓
- Administrator cannot login to active locked session ✓

### Section 7 — Supplemental (MDM-Specific)
- Section 7.4 explicitly covers **Mobile Device Management software** — confirms MDM (Hexnode) is the correct mechanism for applying macOS benchmark settings at scale
- Mobile Configuration Profiles are the recommended delivery method for automated settings

## Gap Analysis vs Gunner's Hexnode Mac CIS IG1 Policy

| Recommendation | Hexnode Mac Policy | Gap? |
|---------------|-------------------|------|
| All sharing services disabled | Not explicitly listed | Verify in Hexnode |
| Siri disabled | Not documented | Verify |
| Audit log retention | Not documented | Gap — no formal policy |
| Sudo timeout = 0 | Not documented | Verify |
| Root account disabled | Not documented | macOS default is disabled; verify |
| iCloud Document Desktop Sync disabled | Configured ✓ | No |
| FileVault enabled | Configured ✓ | No |
| Firewall + stealth mode | Configured ✓ | No |

## Appendices

- Summary Table (p. 403)
- CIS Controls v7 IG1/IG2/IG3 mapped recommendations
- CIS Controls v8 IG1/IG2/IG3 mapped recommendations (p. 429)
