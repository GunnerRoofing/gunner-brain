---
title: IT Communications Style Guide
type: runbook
tags: [runbook, communications, email, incident, style-guide, gunner]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [IT Communications Style Guide.docx]
related: ["[[gunnerteam/system-security-plan]]", "[[gunner/environment]]"]
---

# IT Communications Style Guide

**Document ID:** IT-SOP-COMMS-001  
**Version:** v1.1  
**Classification:** INTERNAL  
**Established:** March 2026  
**Next Review:** March 2027

**Purpose:** Defines how the Gunner IT department drafts, classifies, and sends all internal communications. Consistent communications reduce IT ticket volume during outages, increase compliance with mandatory actions, and build trust in IT as a reliable operational partner.

---

## The Four-Tier System

Every IT communication belongs to one of four tiers. Choose the tier first — everything else follows.

### Tier 1 — RED — Service Alert

**When to use:**
- Full system outage (DocuSign, Dialpad, CompanyCam, HubSpot, BuilderTrend, etc.)
- Degraded performance — slow or partially functional
- Login/authentication failure affecting multiple users
- Email or phone system down
- Widespread outage affecting multiple systems

**Key rules:**
- Send **within 10 minutes** of confirming an outage
- Do not wait for root cause or ETA — "We are aware and actively investigating" stops the ticket flood
- Every RED must be **closed with a GREEN**

**Approved header titles:**
`SERVICE INTERRUPTION` | `SYSTEM OUTAGE` | `SERVICE DISRUPTION` | `DEGRADED PERFORMANCE` | `WIDESPREAD OUTAGE` | `CRITICAL OUTAGE`

---

### Tier 2 — ORANGE — Planned Maintenance / Warning

**When to use:**
- Scheduled downtime or maintenance windows
- Upcoming changes that will affect users
- Warnings about expiring access, required actions, upcoming policy changes

**Key rules:**
- Send with advance notice per sending rules (see below)
- Include clear timeline and expected impact

---

### Tier 3 — BLUE — Information / New Process

**When to use:**
- Informational updates that require no action
- New tool or process announcements
- Policy updates, reminders

**Sub-types:**
- **Standard BLUE:** General information
- **New Process / New Tool BLUE:** Dedicated sub-type with its own label set for onboarding users to new systems

---

### Tier 4 — GREEN — Resolution / All Clear

**When to use:**
- Closing out a RED (outage resolution)
- Confirming a maintenance window is complete
- All-clear after an incident

**Key rules:**
- Always send a GREEN after every RED — never leave an outage unresolved in communication

---

## Standardized Section Labels

### Standard Label Set (RED, ORANGE, and general BLUE)

| Label | What Goes Here |
|-------|---------------|
| WHAT'S HAPPENING | Brief description of the issue or event |
| WHO'S AFFECTED | Specific teams, offices, or individuals impacted |
| WHAT YOU SHOULD DO | User actions (if any) |
| WHAT WE'RE DOING | IT response and current status |
| NEXT UPDATE | When the next communication will be sent |

### New Process / New Tool Label Set (BLUE sub-type)

| Label | What Goes Here |
|-------|---------------|
| WHAT'S CHANGING | Summary of the new tool or process |
| WHY WE'RE DOING THIS | Business rationale |
| WHAT YOU NEED TO DO | Required employee actions |
| WHEN THIS HAPPENS | Timeline |
| WHERE TO GET HELP | Support contact / Keeper / runbook reference |

---

## Subject Line Formula

`[PREFIX] Brief description — Affected System`

**Approved prefixes by tier:**
- RED: `[OUTAGE]` | `[ALERT]` | `[SERVICE DISRUPTION]`
- ORANGE: `[MAINTENANCE]` | `[WARNING]` | `[ACTION REQUIRED]`
- BLUE: `[INFO]` | `[NEW TOOL]` | `[NEW PROCESS]` | `[REMINDER]`
- GREEN: `[RESOLVED]` | `[ALL CLEAR]`

---

## Sending Rules

### Timing by Tier

| Tier | Timing |
|------|--------|
| RED | Within 10 minutes of confirmed outage |
| ORANGE | Minimum 24 hours advance notice; 48–72 hours for major changes |
| BLUE | Any time during business hours |
| GREEN | Immediately upon resolution |

### Outage Update Cadence

During an active RED, send updates at regular intervals:
- First update: within 10 minutes
- Subsequent updates: every 30–60 minutes until resolved
- Resolution: GREEN immediately

### Audience Targeting

- **All-staff:** Major outages affecting everyone
- **Specific team:** Targeted to affected group only
- **IT only:** Internal coordination, not for staff distribution

### Do and Don't

| Do | Don't |
|----|-------|
| Send the first RED before you have answers | Wait for root cause before communicating |
| Use the approved header titles | Invent new tier names or colors |
| Close every RED with a GREEN | Leave an outage "open" in communication |
| Match tone to tier (urgent for RED, neutral for BLUE) | Use alarming language in BLUE/GREEN |
| Target the right audience | Spam all-staff for team-specific issues |

---

## Quick Reference

### Tier Decision Tree

```
Is something broken right now?
  Yes → RED
  No → Is something changing soon?
    Yes → ORANGE
    No → Is this information-only?
      Yes → BLUE
      No → Is this a resolution?
        Yes → GREEN
```

### Approved Status Pills (for email banners)

- 🔴 INVESTIGATING
- 🔴 IDENTIFIED
- 🟠 MONITORING
- 🟢 RESOLVED

---

## Relationship to Incident Response

The IT Communications Style Guide is referenced in the [[gunnerteam/system-security-plan]] as the Crisis Communication Plan. During a security incident, Tier 1 RED communications are the primary mechanism for notifying staff.

For a lost/stolen device or account compromise incident, communications follow the RED → GREEN pattern with appropriate discretion about security details shared with all-staff vs. leadership only.
