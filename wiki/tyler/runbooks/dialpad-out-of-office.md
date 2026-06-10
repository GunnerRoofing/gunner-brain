---
title: Dialpad Out-of-Office Setup
type: runbook
tags: [dialpad, voip, out-of-office, comms]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [My Notebook @ Gunner Roofing.pdf]
related: ["[[vendors/dialpad]]", "[[runbooks/it-comms-style-guide]]"]
---

# Dialpad Out-of-Office Setup

**Purpose:** Configure Dialpad to handle calls and messages while away. There is no single "vacation mode" button — it is a combination of three settings.

**Scope:** Applies to all Gunner staff with Dialpad direct lines.

---

## 1. SET A CUSTOM VACATION STATUS

Lets colleagues know you are away via your presence indicator.

- Open the Dialpad app and click your **avatar**
- Choose a templated status like **"On vacation"** or type a custom status
- When prompted, select **Yes** to enable **Do Not Disturb (DND)** — this sends calls straight to voicemail and pauses notifications
- Optionally set a **timer** for when the status should automatically clear

## 2. ENABLE SMS AUTO-REPLY

Sends an automatic text response to anyone who messages your direct line.

- Go to **Your Settings** → **Call Handling & Voicemail**
- Navigate to **SMS Auto-Reply**
- Select **"Automatically reply to messages received outside of my personal working hours"** or **"when in Do Not Disturb mode"**
- Enter your custom message (up to 320 characters) and save

## 3. UPDATE PERSONAL WORKING HOURS

Controls how calls are routed during your absence — call handling follows your **Advanced Missed Call Routing** settings when you are marked unavailable.

- In **Personal Settings**, find **Personal Working Hours**
- Select **"Only during specific hours"** and mark yourself unavailable for the days you are gone
- Calls received outside these hours will route per your Advanced Missed Call Routing configuration (e.g., forwarding to a colleague or going to voicemail)

---

## ESCALATION PATH

If a user cannot access their Dialpad settings, contact IT. Admin-level changes (e.g., reassigning a direct number, changing call routing at the office level) require IT access.

**Last verified:** 2026-04-13
