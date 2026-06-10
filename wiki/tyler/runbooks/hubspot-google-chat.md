---
title: HubSpot Google Chat Notifications Setup
type: runbook
tags: [hubspot, google-chat, notifications, integration, runbook]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [My Notebook @ Gunner Roofing.pdf]
related: ["[[gunner/hubspot-sales-pipeline]]", "[[vendors/google-workspace]]"]
---

# HubSpot Google Chat Notifications Setup

**Purpose:** Connect HubSpot to Google Chat so deal and conversation notifications appear in Chat — no need to monitor both apps simultaneously.

**Scope:** Per-user setup. Each rep must connect their own accounts. Admin connects the app at the org level once; each user still maps their own email.

**Last verified:** 2026-01-16

---

## 1. CONNECT THE HUBSPOT FOR GOOGLE CHAT APP

In HubSpot:

1. Click the **gear icon** (Settings) in the top navigation
2. Go to **Your Preferences → Notifications**
3. Click the **Other apps** tab
4. Find **Google Chat** and click **Connect**
5. A Google OAuth prompt will appear — click **Select all** and authorize

The HubSpot for Google Chat app will appear in your Google Chat sidebar under **Apps**.

## 2. MAP YOUR ACCOUNT EMAIL

After connecting, HubSpot may show a warning:

> "Please check that your account mapping is set up correctly. Click here to map your Google and HubSpot account emails."

- Click the link and confirm your Google Workspace email matches your HubSpot login email
- Both must be the same (e.g., `tyler.suffern@gunnerroofing.com`)

## 3. CONFIGURE NOTIFICATION PREFERENCES

In the notifications grid, under the **Google Chat** column:

| Notification Type | Recommended |
|-------------------|-------------|
| Chat conversation assigned to you | Enabled |
| Chat conversation reassigned to you | Enabled |
| CRM | Optional |
| Calling | Optional |
| Email conversation assigned/reassigned | Optional |

---

## ADMIN SETUP (One-Time)

In HubSpot admin:

- **Marketplace → Connected Apps → Google Chat**
- Go to **General Settings** → click **Connect account**
- This connects the org-level integration; individual users then verify their own email mapping

---

## ESCALATION PATH

If a user cannot see the HubSpot for Google Chat app in their Chat sidebar: re-verify the OAuth authorization step and confirm the account email mapping is correct. IT can check the connected app status in HubSpot admin.
