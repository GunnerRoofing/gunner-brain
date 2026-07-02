---
title: JAMF Pro
type: vendor
tags:
  - vendor
  - mdm
  - jamf
  - apple
  - endpoint
created: 2026-04-14T00:00:00.000Z
updated: '2026-05-12'
status: developing
related:
  - '[[vendors/hexnode]]'
  - '[[concepts/apple-business-manager]]'
  - '[[gunnerteam/environment]]'
---

# JAMF Pro

Apple-focused MDM platform. Under evaluation as a potential replacement or supplement to Hexnode at Gunner.

## Evaluation Status

**Status:** Under evaluation — decision expected late April 2026.

**Key gate:** Chrome Enterprise Core compatibility. Hexnode currently manages Chrome Enterprise policies; JAMF would need to match this capability to be a viable replacement.

## Why It's Being Evaluated

Part of a larger Microsoft + Jamf stack proposal to replace the current [[vendors/google-workspace|Google Workspace]] + Hexnode setup. The combined stack was presented to leadership as a way to execute the Gunner Security Baseline more efficiently.

## Microsoft + Jamf Proposed Stack

| Requirement | Delivered By |
|------------|-------------|
| [[concepts/cis-ig1|CIS IG1]] device compliance | Jamf — automatic compliance scoring |
| Endpoint protection (antivirus/EDR) | Microsoft Defender for Business — included, deployed via Jamf |
| Identity & access control | Entra ID [[concepts/mfa|MFA]] + Conditional Access |
| Managed browser | Microsoft Edge — existing Chrome Enterprise policies port directly |
| Phishing defense | Defender for Office 365 + [[vendors/knowbe4|KnowBe4]] |
| Audit evidence | Purview Audit + Entra ID logs — automated, always-on |

The pitch: Microsoft Defender for Business closes the [[concepts/cmmc|CMMC]] AV gap (currently requiring [[vendors/bitdefender|Bitdefender]] at ~$1.1k/yr) at no extra cost since it's included in the Microsoft 365 Business Premium license.

## Key Questions Outstanding

- Can JAMF manage Chrome Enterprise Core policies at parity with Hexnode?
- Full pricing comparison: Microsoft 365 Business Premium + Jamf vs. Google Workspace + Hexnode
- Migration complexity for 36 employees + contractors across 3 offices

## Comparison to Hexnode

See [[vendors/hexnode]] for Hexnode's current configuration, CIS benchmark gaps, and capabilities.

> [!gap] Decision status unknown — update needed
> Evaluation window (late April 2026) has passed as of 2026-05-07. No decision has been recorded in the vault. Verify current status with leadership and update this page.
