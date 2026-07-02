---
title: Employee Onboarding ("New Crew")
type: runbook
tags: [runbook, onboarding, hexnode, google-workspace, keeper, iam]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [System Security Plan.docx, Gunner IT Governance.xlsx, IT_Tasks_1775773048.xlsx]
related: ["[[runbooks/offboarding]]", "[[runbooks/new-laptop-setup]]", "[[runbooks/new-phone-setup]]", "[[runbooks/acceptable-use-policy]]", "[[vendors/hexnode]]", "[[vendors/google-workspace]]", "[[vendors/keeper]]", "[[gunnerteam/app-inventory]]"]
---

# Employee Onboarding ("New Crew")

**Purpose:** Provision a new employee with full access to Gunner systems on Day 1.  
**Scope:** All full-time employees and contractors receiving company devices.  
**Owner:** IT Manager (Tyler Suffern)  
**Last Verified:** April 2026

> Complete all steps before the employee's first day. Target: employee is productive on Day 1 with zero IT blockers.

---

## Pre-Arrival Checklist

Collect from HR / hiring manager before starting:

- [ ] Employee full name
- [ ] Start date
- [ ] Role / department
- [ ] Office location (Stamford HQ, CT branch, NJ)
- [ ] Device needs (MacBook? iPhone? Both?)
- [ ] App access needs (role-specific apps beyond standard stack)

---

## Step 1 — Create Google Workspace Account

1. Log into **Google Admin Console** → Directory → Users → Add new user
2. Set:
   - First / Last name
   - Primary email: `firstname.lastname@gunnerroofing.com`
   - Temporary password (employee will be prompted to change on first login)
3. **Place account in Staging OU** — new accounts land here automatically; no services are enabled until moved
4. Do **not** move to final OU yet — complete device setup and app provisioning first

---

## Step 2 — Provision Device(s)

Follow the appropriate runbook for each device:

- **MacBook** → [[runbooks/new-laptop-setup]]
- **iPhone** → [[runbooks/new-phone-setup]]

Key steps from those runbooks to confirm before proceeding:
- [ ] Device enrolled in Hexnode and named `GR-[last 6 serial]`
- [ ] Correct owner assigned in Hexnode
- [ ] CIS IG1 policy applied (Gunner wallpaper visible)
- [ ] Local Mac account created (`FirstInitial.LastName`, Standard role)

---

## Step 3 — Move Account to Correct Google Workspace OU

Once device is ready, move the Google account from Staging:

| Employee Type | OU |
|--------------|-----|
| Standard employee | Standard Users |
| IT / admin role | Administrators |
| Contractor | Contractors |

1. Google Admin Console → Directory → Users → select the employee
2. Move to correct OU
3. MFA enforcement and session policies apply automatically on first login

---

## Step 4 — Configure MFA

1. On the employee's first login, Google will prompt MFA enrollment
2. Confirm they complete MFA setup before leaving Day 1
3. **Add work phone as Google account recovery number** (learned from task log — do this during setup, not later)
4. Verify MFA is active: Google Admin Console → Security → 2-Step Verification

---

## Step 5 — Provision Keeper

1. Log into **Keeper Admin Console** → Users → Invite user
2. Send invite to employee's Gunner email
3. Walk employee through:
   - Setting their Master Password (they must memorize this — IT cannot reset it)
   - Installing Keeper on their MacBook and iPhone
   - Saving their laptop login password in Keeper immediately
4. Add employee to any relevant **shared Keeper folders** for their role

---

## Step 6 — Provision App Access

Work through the app list below. Apps with Google SSO provision automatically once the account is active — manual steps are only needed for non-SSO apps.

### Auto-provisioned via Google SSO (verify access on Day 1)
- [ ] Gmail
- [ ] Google Drive
- [ ] Google Chat — confirm they're added to all-company spaces/groups
- [ ] Google Calendar
- [ ] Monday.com (if already has an account — otherwise invite manually)
- [ ] HubSpot (if applicable to role — manual invite required first, then Google SSO)
- [ ] CompanyCam (if applicable to role)

### Manual provisioning required
| App | Steps |
|-----|-------|
| Monday.com | Invite via Monday admin → employee uses Google SSO to log in |
| HubSpot | Invite via HubSpot admin → assign correct role/team |
| Dialpad | Add to Dialpad admin → assign phone number if needed |
| ADP | HR handles ADP setup — confirm with HR it's done |
| CompanyCam | Invite via CompanyCam admin |
| Keeper | Done in Step 5 |
| KnowBe4 | Add to appropriate user group (maps to Google Workspace OU) |

### Add to Google Groups
- [ ] Add to `all@gunnerroofing.com` (or equivalent all-company group)
- [ ] Add to department-specific Google Chat spaces
- [ ] Add to any role-specific groups

---

## Step 7 — Role-Specific Access

Check with hiring manager for any access beyond the standard stack:

- [ ] GAF QuickMeasure (Sales roles — individual account, not shared)
- [ ] Quote Portal access
- [ ] BuilderTrend (field/ops roles)
- [ ] ADP manager access (managers only)
- [ ] Google Admin Console (IT/admin roles only)
- [ ] Hexnode admin access (IT only)

---

## Step 8 — AUP Acknowledgment

1. Provide employee with the Acceptable Use Policy: [[runbooks/acceptable-use-policy]]
2. Have them sign the **AUP Acknowledgment Form** (IT-POL-AUP-001)
3. Retain signed form in employment records (HR file or IT secure storage)

> This is also a CMMC requirement — new employees must sign the AUP.

---

## Step 9 — Verify & Hand Off

Run through this before calling it done:

**Account**
- [ ] Google Workspace account active in correct OU
- [ ] MFA enrolled and verified
- [ ] Work phone added as recovery number
- [ ] Email address confirmed working (send a test)

**Device**
- [ ] MacBook enrolled in Hexnode, policy applied, named correctly
- [ ] iPhone enrolled in Hexnode, policy applied
- [ ] FileVault enabled on MacBook (check Hexnode device summary)
- [ ] Employee knows their laptop password and it's saved in Keeper

**Apps**
- [ ] Google Chat — can send and receive messages; in all-company spaces
- [ ] Gmail — working, signature configured
- [ ] Keeper — master password set, app installed on all devices
- [ ] Role-specific apps confirmed accessible
- [ ] KnowBe4 — enrolled in correct user group

**Documentation**
- [ ] AUP signed and filed
- [ ] Employee's name and email added to device record in Hexnode
- [ ] Log entry added to IT Decision & Change Log if any non-standard access was granted

---

## Contractor Onboarding (Differences)

Contractors follow the same process with these exceptions:

| Item | Standard Employee | Contractor |
|------|-----------------|-----------|
| Google OU | Standard Users | Contractors |
| Session duration | 14 days | 7 days |
| Google services | Full suite | Email + Drive only |
| External sharing | Approved domains | Disabled |
| Device issued? | Yes (usually) | Case-by-case |
| KnowBe4 | Yes | Case-by-case |

---

## Related Runbooks

- [[runbooks/offboarding]] — reverse process; run when employee departs
- [[runbooks/new-laptop-setup]] — MacBook enrollment detail
- [[runbooks/new-phone-setup]] — iPhone enrollment detail
- [[runbooks/acceptable-use-policy]] — policy employees sign
