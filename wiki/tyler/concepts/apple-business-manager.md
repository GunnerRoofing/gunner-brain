---
title: Apple Business Manager (ABM)
type: concept
tags: [abm, apple-business-manager, mdm, hexnode, dep, enrollment, ios, macos]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [new laptop set up.docx, New Phone setup.docx, Hexnode iPhone Policy (CIS IG1).xlsx, Hexnode Mac Policy (CIS IG1).xlsx]
related: ["[[vendors/hexnode]]", "[[runbooks/new-laptop-setup]]", "[[runbooks/new-phone-setup]]", "[[vendors/monday]]"]
---

# Apple Business Manager (ABM)

## What It Is

Apple Business Manager is Apple's enterprise portal for centrally purchasing, distributing, and managing Apple devices and apps. At Gunner, ABM enables **zero-touch device provisioning** — devices ordered through Apple automatically enroll in Hexnode MDM the first time they power on.

## Device Enrollment Flow

1. Device purchased through Apple Business Store → automatically added to ABM
2. Device purchased elsewhere → manually add via Apple Configurator
3. ABM syncs with Hexnode via Device Enrollment Program (DEP)
4. IT assigns owner and policy in Hexnode
5. Employee powers on → Hexnode profile installs automatically (zero-touch)
6. IT renames device (`GR-[last 6 of serial]`), creates local account, moves to correct Google OU

## ABM Account

| Field | Value |
|-------|-------|
| Apple ID | becky@gunnerroofingcom1.appleid.com |
| Credentials | Stored in Keeper |

> **Flag:** ABM account is in Becky's name. Verify this is still the correct admin contact and credentials are current in Keeper.

## What Gets Pushed on Enrollment

- CIS IG1 or Total Lockdown policy applied automatically
- App catalog pushed to device
- Configuration profiles: passcode, FileVault, firewall, Chrome policies, lock screen message
- Lock screen: *"Property of Gunner Roofing LLC."*

## Gunner Forms iOS App

The **Gunner Forms** internal app is distributed via ABM. It wraps Monday.com WorkForms and provides IT request, service request, PTO, reimbursement, and referral forms in a native iOS app experience. See [[vendors/monday]].

## Security Relevance

ABM + Hexnode DEP is how Gunner satisfies CIS Control 1.1 (hardware inventory) — every device ordered through Apple is automatically visible in Hexnode before it ships. Devices not purchased through Apple Business Store must be manually enrolled via Apple Configurator, creating a gap risk if the process is skipped.

## Related

- [[vendors/hexnode]] — MDM platform; policy details, CIS controls satisfied
- [[runbooks/new-laptop-setup]] — full MacBook enrollment process
- [[runbooks/new-phone-setup]] — full iPhone enrollment process
