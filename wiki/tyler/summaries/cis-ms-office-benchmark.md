---
title: CIS Microsoft Office Enterprise Benchmark v1.2.0 — Summary
type: summary
tags: [cis, microsoft, office, benchmark, hardening, study]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [CIS_Microsoft_Office_Enterprise_Benchmark_v1.2.0.pdf]
related: ["[[concepts/cis-ig1]]", "[[ciso-track/roadmap]]"]
---

# CIS Microsoft Office Enterprise Benchmark v1.2.0 — Summary

**Source:** CIS_Microsoft_Office_Enterprise_Benchmark_v1.2.0.pdf  
**Version:** v1.2.0 — July 19, 2024  
**Issuer:** Center for Internet Security (CIS)

## Gunner Relevance

**Low immediate relevance.** Gunner uses Google Workspace, not Microsoft Office. This benchmark is retained as study material for the CISSP and future roles where Microsoft Office environments are common.

## Scope

Covers Microsoft Office 2016 Enterprise suite via Group Policy / ADMX templates:
- Microsoft Access 2016
- Microsoft Excel 2016
- Microsoft OneNote 2016
- Microsoft Outlook 2016
- Microsoft PowerPoint 2016
- Microsoft Word 2016

Two sections:
- **Section 1:** Computer Configuration (machine-level GPO settings)
- **Section 2:** User Configuration (per-user GPO settings)

## Key Security Themes

### Macro Security (Excel, Word, PowerPoint, Access)
- Block macros from internet-sourced Office files (L1) — prevents macro-based malware delivery via phishing
- Disable unsigned macros
- Block XLM macros (Excel 4.0 legacy)
- Prevent Trust Bar notifications from bypassing macro warnings

### Protected View
- Always open untrusted database files in Protected View
- Block files from internet zone in Protected View
- Set document behavior when file validation fails to "Open in Protected View"

### Trusted Locations / Add-ins
- Disable trusted network locations
- Require application add-ins to be signed by Trusted Publisher
- Block unsigned add-ins silently

### Outlook Security
- Exchange authentication: Kerberos Password Authentication
- Enable RPC encryption
- Disable RSS feeds
- Disable automatic attachment downloads from Internet Calendars
- Junk email protection level: High
- Restrict calendar publishing to Office.com

### Privacy / Telemetry
- Disable user feedback to Microsoft
- Disable Customer Experience Improvement Program
- Disable proofing tool telemetry

## Study Notes (CISSP / Future Roles)

- Macro-based malware is a top phishing vector (T1566.001) — Office macro controls are a primary defense
- Protected View and Trusted Locations concepts are relevant to understanding application sandboxing
- Office Group Policy management via ADMX is a common enterprise control pattern
- Kerberos vs NTLM authentication preference applies to Exchange/AD environments

See: [[threats/t1566-phishing]] for phishing context.
