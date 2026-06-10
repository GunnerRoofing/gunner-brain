---
title: Employee Offboarding ("Kill-Switch")
type: runbook
tags: [runbook, offboarding, hexnode, google-workspace, keeper, iam, security]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [System Security Plan.docx, Gunner IT Governance.xlsx, Acceptable Use Policy.docx]
related: ["[[runbooks/onboarding]]", "[[vendors/hexnode]]", "[[vendors/google-workspace]]", "[[vendors/keeper]]", "[[gunner/app-inventory]]"]
---

# Employee Offboarding ("Kill-Switch")

**Purpose:** Revoke all system access and recover company assets when an employee departs.  
**Scope:** All departing employees and contractors with company accounts or devices.  
**Owner:** IT Manager (Tyler Suffern)  
**Last Verified:** April 2026

> **Speed matters.** The Google Workspace account disable is the highest-impact single action — it blocks all SSO-connected apps simultaneously. Do this first, every time, even before you know the full scope of what the employee had access to.

> **Do not wait** for HR to formally process the departure before acting. As soon as a departure is confirmed, coordinate with HR on timing and execute IT steps on the employee's last day (or immediately for involuntary terminations).

---

## Involuntary vs. Voluntary Termination

| Type | Timing | Notes |
|------|--------|-------|
| Voluntary (resignation) | Last day of employment | Coordinate with HR; employee may assist with knowledge transfer |
| Involuntary (termination) | Immediately upon termination | IT steps should run simultaneously with or before the employee is notified |

---

## Step 1 — Disable Google Workspace Account *(Do This First)*

This is the kill-switch. One action blocks Gmail, Drive, Chat, and all SSO-connected apps (HubSpot, Monday, CompanyCam, etc.) simultaneously.

1. Log into **Google Admin Console** → Directory → Users
2. Find the employee's account
3. Click **More options** → **Suspend user**
   - Suspension is reversible (use for involuntary departures where there may be access needs)
   - Or select **Delete user** if departure is final and confirmed (download their data first)
4. Confirm account is suspended/disabled

**Apps immediately blocked:**
- Gmail, Google Drive, Google Chat, Google Calendar
- Monday.com (Google SSO)
- CompanyCam (Google SSO)
- Any other app using Google SSO

---

## Step 2 — Transfer or Export Critical Data

Before deleting the account:

- [ ] Transfer Google Drive files to their manager or a shared Drive folder
- [ ] Forward or export any critical emails if needed
- [ ] Check if they owned any Google Groups or Spaces — reassign ownership
- [ ] Check Monday.com for open tasks — reassign to appropriate team member
- [ ] Download/export data via Google Admin Console → Data Export if needed

---

## Step 3 — Wipe and Recover Device(s)

### MacBook
1. Log into **Hexnode**
2. Find the device (filter by employee name or `GR-[serial]`)
3. **Actions** → **Wipe Device** (full wipe — removes all data)
4. Coordinate device physical return:
   - In-person: collect directly
   - Remote: ship to IT (provide prepaid label)
5. After wipe confirmed: change owner in Hexnode to "Default User" or decommission

### iPhone
1. Log into **Hexnode**
2. Find the device
3. **Actions** → **Wipe Device**
4. Coordinate physical return (same as MacBook)

> If device cannot be immediately recovered (e.g., remote employee), initiate wipe immediately regardless — do not wait for physical return.

---

## Step 4 — Revoke Keeper Access

1. Log into **Keeper Admin Console** → Users
2. Find the employee → **Transfer account** or **Delete user**
3. **Before deleting:** Check if they had access to any shared folders — review what's in their vault
4. **Rotate any shared credentials** the employee had access to:
   - Identify shared Keeper folders they were a member of
   - Change passwords for every credential in those folders
   - Priority: admin accounts, vendor portals, any shared logins

---

## Step 5 — Manual Deprovision — Non-SSO Apps

These apps are **not** blocked by the Google account disable. Each requires a separate manual step:

| App | Action | Notes |
|-----|--------|-------|
| **ADP** | HR deactivates — confirm with HR it's done | Payroll access |
| **Dialpad** | Dialpad admin → remove user, release phone number | Calls may still route to the number until released |
| **KnowBe4** | Admin console → deactivate user | Frees up a license |
| **BuilderTrend** | Admin → deactivate user | If employee had access |
| **Contactzilla** | Remove from directory | Prevents stale contact info |
| **GAF QuickMeasure** | Deactivate individual account | Sales roles |
| **Quote Portal** | Remove user access | Sales roles |
| **Wells Fargo / Chase** | Notify Finance — they handle banking access | If employee had financial system access |
| **ABC Supply** | Remove if applicable | |
| **Stripe** | Review Dashboard access if employee had it | |
| **Make.com** | Check for any automations owned by the employee | Reassign or document |

---

## Step 6 — Audit Remaining Access

After completing steps 1–5, do a quick sweep:

- [ ] Google Admin Console → Reports → Audit log — check for any login activity after account was suspended
- [ ] Hexnode — confirm device wipe completed (check device status)
- [ ] Keeper — confirm shared credentials rotated
- [ ] Check if employee had any personal devices connected to company accounts (Google account on personal phone, etc.)
- [ ] Check if employee was listed as admin/owner in any third-party apps not in the standard stack

---

## Step 7 — Recover Physical Assets

- [ ] MacBook returned and wiped
- [ ] iPhone returned and wiped
- [ ] Any other company equipment (monitors, keyboards, etc.)
- [ ] Building key/access card/badge (coordinate with office manager)
- [ ] Parking pass or other physical items

Note condition of returned devices. If device is not returned within 5 business days, escalate to HR/legal per AUP (Gunner reserves the right to pursue recovery).

---

## Step 8 — Final Documentation

- [ ] Log departure in **IT Decision & Change Log** (IT-GOV-LOG-001) — record date, name, access revoked, devices wiped
- [ ] Note if any credentials were rotated and which ones
- [ ] Update Hexnode device record (reassign or mark as available)
- [ ] Remove from Google Groups and Chat spaces (may happen automatically on account delete; verify)
- [ ] Notify hiring manager / HR that IT offboarding is complete

---

## Contractor Offboarding (Differences)

Contractors in the Contractors OU follow the same process. Watch for:

- Contractors may use personal devices (no Hexnode wipe needed — but confirm they've removed company accounts from personal devices)
- Contractor Google accounts have limited services (Email + Drive only) — still must be suspended
- External sharing was already disabled for contractors — lower data exfiltration risk, but still audit

---

## Emergency / Immediate Termination Playbook

If an employee is being terminated immediately and there is any concern about retaliation or data exfiltration:

1. **Right now:** Suspend Google Workspace account (Step 1)
2. **Right now:** Initiate Hexnode remote wipe on all devices
3. **Within 1 hour:** Complete Steps 4 and 5 (Keeper + non-SSO apps)
4. **Same day:** Physical device recovery or confirmed remote wipe
5. Document everything with timestamps

Do not wait to collect the device before wiping — wipe immediately, recover physically afterward.

---

## Related Runbooks

- [[runbooks/onboarding]] — reverse process; run when a new employee joins
- [[runbooks/acceptable-use-policy]] — AUP governs device return obligations
- [[vendors/hexnode]] — MDM wipe procedures
- [[vendors/google-workspace]] — OU structure and account management
- [[vendors/keeper]] — credential rotation guidance
- [[gunner/app-inventory]] — full app list with offboarding actions
