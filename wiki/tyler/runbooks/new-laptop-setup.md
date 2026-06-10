---
title: New Laptop Setup (MacBook)
type: runbook
tags: [runbook, laptop, macbook, hexnode, mdm, onboarding]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [new laptop set up.docx]
related: ["[[vendors/hexnode]]", "[[runbooks/new-phone-setup]]", "[[gunner/environment]]"]
---

# New Laptop Setup (MacBook)

**Purpose:** Enroll a new MacBook into Hexnode MDM, configure it, and assign it to an employee.  
**Scope:** All Gunner Roofing MacBooks  
**Last Verified:** April 2026  
**Related Tools:** Hexnode, Apple Business Manager (ABM), Apple Configurator  

> **Credentials:** Apple Business Manager login and local account default password are stored in Keeper. Do not record credentials in this document.

---

## Step 1: Add Device to Apple Business Manager

### If ordered through Apple Business Store
Device is automatically added to ABM — skip to Step 2.

### If purchased elsewhere
1. Start up the new laptop (do not complete setup yet)
2. Open **Apple Configurator** on your mobile device
3. Sign into Apple Business Manager (credentials in Keeper)
4. Select your language: English
5. Continue to the **Location Page**
6. Raise your mobile device camera/scanner in the Configurator app → center on the Pairing icon
7. Device is added to Apple Business Manager

---

## Step 2: Assign to Hexnode MDM in ABM

1. Log into **Apple Business Manager** admin account
2. Left menu → **Devices**
3. Sort by **Date Created → Newest First** to find the new device (shown by serial number)
4. Select the device → click the **ellipsis (•••)** in top right
5. Select **Edit MDM Server**
6. Assign to **"Gunner Hexnode"** → Continue
7. **Restart the device**

---

## Step 3: Complete macOS Setup

1. Connect to Gunner Roofing Wi-Fi if not auto-connected
2. A Hexnode enrollment prompt will appear — **check the box to enroll**
3. Allow enrollment to complete (may take a few moments)
4. Continue macOS setup:
   - Enable location services
   - Set up Touch ID: **skip for now** (do later)
   - Create admin account
5. **Do not** complete personal Apple ID setup on company device

---

## Step 4: Sync and Assign Owner in Hexnode

1. Sign into **Hexnode** admin account
2. **Admin tab** → Apple Business / School Manager → Apple DEP
3. Click **"Sync with DEP"** at the top of the page
4. Filter by **"Last Assigned"** — the new device should appear with the matching serial number
5. From top menu: **Manage** → filter by platform: macOS → sort by **Last Check-In**
6. New laptop should appear at the top assigned to "Default User"

### Assign Owner
1. Select the laptop via the Name Column → opens Device Summary
2. Click **Actions** dropdown (top right) → **Change Owner**
3. Search User → **"+ Add New User"**
   - Display Name: First and Last Name
   - Email: employee email address
4. Click **Save** → click name → **Assign**

### Rename Device
1. In top left, click the Device Type or serial number field
2. Rename using format: **GR-[last 6 of serial number]**
   - Example: `GR-123456`

---

## Step 5: Create Local User Account

1. From top menu: **Local Accounts**
2. Top right: click the **person + button** icon → **Create Local User Account**
   - Account role: **Standard**
   - Full Name: First Name, Last Name
   - Account Name: `FirstInitial.LastName` (e.g., `b.blake`)
   - Password: (use Keeper to generate; store in shared Keeper folder)
   - **UNCHECK "Grant Secure Token"**
3. Click **Create**

---

## Step 6: Apply Policy

1. From menu bar: **Policies**
2. Top left: **Associate Policy**
3. Check the **Mac Policy (CIS IG1)** and click **Associate**
4. Confirm the policy applied by verifying the desktop wallpaper changed to Gunner branding

---

## Step 7: Verify & Hand Off

- [ ] Device appears in Hexnode compliance dashboard
- [ ] FileVault enabled (check Device Summary — recovery key should be escrowed)
- [ ] Correct user assigned as owner
- [ ] Device renamed `GR-XXXXXX`
- [ ] Local account created with standard role
- [ ] CIS IG1 policy associated
- [ ] Employee completes AUP acknowledgment form

---

## Troubleshooting

| Issue | Resolution |
|-------|-----------|
| Device doesn't appear after DEP sync | Wait 5 minutes, sync again; verify ABM assignment to "Gunner Hexnode" |
| Hexnode enrollment prompt doesn't appear | Ensure device connected to Wi-Fi; restart device |
| Policy not applying | Check device is in correct group; re-associate policy |
