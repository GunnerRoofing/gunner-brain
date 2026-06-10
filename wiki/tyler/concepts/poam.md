---
title: "Plan of Action and Milestones (POAM)"
type: concept
tags: [concept, compliance, poam, ssp, risk-management]
created: 2026-04-14
updated: 2026-04-14
status: developing
related:
  - "[[gunner/system-security-plan]]"
  - "[[concepts/cmmc]]"
  - "[[concepts/nist-csf]]"
  - "[[concepts/incident-response]]"
---

# Plan of Action and Milestones (POAM)

A POAM is a structured document that identifies security weaknesses, describes the resources required to fix them, and assigns milestones for remediation. Required for FedRAMP, CMMC, and most federal compliance frameworks.

## Structure

| Field | Purpose |
|-------|---------|
| Weakness ID | Unique identifier for the gap |
| Description | What the gap is and why it matters |
| Point of Contact | Who owns remediation |
| Resources Required | Budget, tools, time |
| Scheduled Completion | Target remediation date |
| Milestones | Intermediate steps |
| Status | Open / In Progress / Closed |

## Gunner POAM Status

Gunner's POAM items are tracked in [[gunner/system-security-plan]]. Key open items:

- **SI.L1-3.14.2** — Endpoint antivirus not deployed on all systems (CMMC blocker). Remediation: Bitdefender GravityZone (~$1.1k/yr).
- **iPhone passcode** — Hexnode CIS IG1 allows simple passcode; CIS iOS 26 (institutionally-owned) requires alphanumeric.
- **Mac sharing services** — Not explicitly disabled in Hexnode Mac policy.
- **Chrome DevTools** — DeveloperToolsAvailability should be 2 (disable for users), not 0.

## CMMC Relationship

CMMC Level 1 assessment requires that all practices are fully implemented — there is no POAM exception at Level 1. All gaps must be closed before submission. See [[concepts/cmmc]].

## NIST CSF Alignment

POAM management maps to the **RESPOND** and **RECOVER** functions of [[concepts/nist-csf]] — specifically the Improvements (RC.IM) subcategory.
