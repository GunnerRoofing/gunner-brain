---
title: Bitdefender GravityZone
type: vendor
tags:
  - vendor
  - antivirus
  - edr
  - endpoint-security
  - cmmc
created: '2026-04-16'
updated: '2026-05-12'
status: seed
sources: []
related:
  - '[[concepts/cmmc]]'
  - '[[gunner/environment]]'
  - '[[vendors/hexnode]]'
---
# Bitdefender GravityZone

> [!gap] This page is a stub. Expand with: procurement decision, deployment scope, Hexnode integration details, license count.

Bitdefender GravityZone is an endpoint protection and EDR platform. It is the leading candidate to close Gunner's CMMC Level 1 gap on SI.L1-3.14.2 (malicious code protection / antivirus).

## CMMC Gap Context

CMMC Level 1 requires endpoint antivirus (SI.L1-3.14.2). Gunner currently has no AV or EDR deployed — this is the primary CMMC blocker. Bitdefender GravityZone is estimated at ~$1.1k/yr for Gunner's device count.

See [[concepts/cmmc]] for the full gap analysis.

## Status

Not yet procured. Decision pending as of 2026-05-12.

> [!gap] JAMF evaluation may affect this decision
> The Microsoft + JAMF stack under evaluation includes Microsoft Defender for Business, which would cover the CMMC AV gap at no additional cost (included in M365 Business Premium). If the JAMF evaluation proceeds, Bitdefender may not be needed. See [[vendors/jamf]] for evaluation status.

## Related

- [[concepts/cmmc]] — CMMC Level 1; AV is the only remaining blocker
- [[vendors/hexnode]] — MDM platform; Bitdefender would deploy alongside Hexnode
