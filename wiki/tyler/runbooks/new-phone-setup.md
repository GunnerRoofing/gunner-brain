---
title: New Phone Setup (iPhone)
type: runbook
tags: [runbook, iphone, hexnode, mdm, onboarding, apple]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [New Phone setup.docx]
related: ["[[vendors/hexnode]]", "[[runbooks/new-laptop-setup]]", "[[gunner/environment]]"]
---

# New Phone Setup (iPhone)

**Purpose:** Enroll a new iPhone into Hexnode MDM, configure it, and assign it to an employee.  
**Scope:** All Gunner Roofing iPhones  
**Last Verified:** April 2026  
**Related Tools:** Hexnode, Apple Business Manager (ABM), Apple Configurator (on MacBook)

> **Credentials:** Apple Business Manager login and device default passcode are stored in Keeper. Do not record credentials in this document.

> **Security Note:** The default device passcode used during setup is a placeholder only — it must be documented in the offboarding checklist and changed by the employee after setup. Ensure no employee uses the default passcode long-term.

---

## Step 1: Add Device to Apple Business Manager

### If ordered through Apple Business Store
Device is automatically added to ABM — skip to Step 2.

### If purchased elsewhere
1. Open **Apple Configurator** on a Gunner MacBook
2. Sign into Apple Business Manager (credentials in Keeper)
3. Plug the new iPhone into the MacBook → **Trust** the device
4. Right-click the phone → **Prepare**
5. Select **Manual Configuration**
6. Check: **"Add to Apple School Manager or Apple Business Manager"**
7. Check: **"Allow Devices to pair with other computers"**
8. Click Next → Select **"Gunner Hexnode"** → Next
9. Organization: **"Gunner LLC"** → Next
10. Show all steps
11. Choose Network Profile: **Gunnerwifi.mobileconfig** → Click **Prepare**
12. Sign into Apple Business Manager when prompted (credentials in Keeper)
13. Phone will restart

---

## Step 2: Complete iPhone Setup

1. Continue phone setup → connect to Wi-Fi
2. Phone will retrieve configuration from Hexnode automatically
3. **Do not transfer anything** from old device
4. Remote management enrollment prompt appears → click **"Enroll this phone"**
5. Set up Face ID: **skip for now** (do later)
6. Create passcode: use default placeholder (in Keeper) — remind employee to change it
7. **Do NOT create an Apple ID**
8. Agree to Terms and Conditions
9. Update automatically: Continue
10. iMessage and FaceTime: Continue
11. Turn on Location Services
12. Set up Siri: later
13. Set up later → Don't send → Continue

---

## Step 3: Assign Owner in Hexnode

1. Sign into **Hexnode** admin account → **Manage**
2. Click on **iPhone** listed under "Default User"
3. Filter by platform: **iOS** → sort by **Last Check-In**
4. New phone should appear at the top assigned to "Default User"
5. Select the phone via the **Name Column** → opens Device Summary
6. Click **Actions** dropdown (top right) → **Change Owner**
7. Search User → **"+ Add New User"**
   - Display Name: First and Last Name
   - Email: employee email address
8. Click **Save** → click name → **Assign**

---

## Step 4: Apply Policy

1. From menu bar: **Policies**
2. Top left: **Associate Policy**
3. Check the **iPhone Policy (CIS IG1)** and click **Associate**
4. Confirm the policy applied by checking the device — background should have changed to Gunner logo

---

## Step 5: Configure Accounts

After policy association, open the phone and log into work accounts:
- Google (Gmail, Drive, Calendar, Chat)
- Keeper
- Any other apps pushed by MDM policy that require login

---

## Step 6: Verify & Hand Off

- [ ] Device enrolled in Hexnode and appears in dashboard
- [ ] Correct user assigned as owner
- [ ] CIS IG1 policy associated (Gunner logo wallpaper visible)
- [ ] Required apps pushed and installed
- [ ] Employee set up Face ID and changed passcode from default
- [ ] No personal Apple ID created on device
- [ ] Employee completes AUP acknowledgment form

---

## Troubleshooting

| Issue | Resolution |
|-------|-----------|
| Enrollment prompt doesn't appear | Ensure phone connected to Wi-Fi; restart phone |
| Policy not applying | Check device is in correct Hexnode group; re-associate policy |
| Apps not installing | Check Hexnode app catalog; verify employee account is assigned |
| Device not showing in Hexnode | Sync with ABM/DEP from Hexnode admin panel |
