---
title: "Hexnode Custom App Deployment via ABM"
type: question
tags: [hexnode, abm, ios, mdm, app-store, deployment, gunner]
created: 2026-04-22
updated: 2026-04-22
sources: []
related:
  - "[[vendors/hexnode]]"
  - "[[concepts/apple-business-manager]]"
  - "[[gunnerteam/gunner-forms-app]]"
status: stable
---

# Hexnode Custom App Deployment via ABM

How to deploy a private (Custom) App Store app to managed iPhones through Apple Business Manager and Hexnode MDM — without making the app publicly available on the App Store.

## What Is a Custom App

A Custom App is an App Store app distributed privately to specific organizations through Apple Business Manager. It goes through normal App Store review but never appears on the public App Store. Configured in App Store Connect under **Pricing and Availability > Custom App Distribution** by adding the recipient organization's ABM Organization ID.

GunnerForms is distributed this way — approved but not public.

## Prerequisites

- App approved in App Store Connect and set to **Ready for Distribution** (not released publicly)
- Custom App Distribution configured in App Store Connect with Gunner's ABM Organization ID
- iPhones supervised via ABM + Hexnode (already the case at Gunner)

## Deployment Steps

### Step 1 — Claim in Apple Business Manager

1. Sign in to **business.apple.com**
2. Go to **Apps and Books**
3. Search for the app name (e.g. "GunnerForms")
   - Note: propagation from App Store Connect to ABM can take a few minutes to a few hours after clicking Ready for Distribution
4. Set quantity to the number of devices to cover
5. Click **Get** to claim licenses
6. Under **Location**, assign licenses to the **Hexnode MDM server**

### Step 2 — Sync into Hexnode

1. In Hexnode, go to **Apps > App Catalog**
2. Click **Sync ABM** — the app should appear once licenses are assigned
3. If it doesn't appear: **Add App > Apple App Store** > search the app name > add and mark as VPP

### Step 3 — Push via Policy

1. Go to **Policies** > open the target iPhone policy
2. Under **App Management > Install App**, add the app
3. Set to **Mandatory** — installs silently without user interaction on supervised devices
4. Save and apply the policy

## Key Notes

- Supervised iPhones install mandatory apps silently — no App Store prompt on the device
- The app does not appear on the public App Store at any point
- Custom App section in ABM is not a separate tab — search for it in the same Apps & Books search as public apps
- Remove the dev build from a test device by long-pressing the icon > **Remove App > Delete App** before the MDM version installs

## Related

- [[vendors/hexnode]] — Hexnode MDM setup and policies
- [[concepts/apple-business-manager]] — ABM zero-touch provisioning overview
- [[gunnerteam/gunner-forms-app]] — GunnerForms app details and status
