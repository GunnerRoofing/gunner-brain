---
type: runbook
title: GunnerTeam — App Store Custom App Submission
created: '2026-06-08'
updated: '2026-06-08'
tags: [gunner, gunnerteam, runbook, appstore, abm, ios, release]
status: stable
source: Gunner Team App/runbooks/appstore-abm-submission-runbook.md
related: ["[[gunnerteam/gunnerteam-project-structure]]", "[[index]]"]
---

# GunnerTeam — App Store Custom App Submission Runbook
**Distribution:** Apple Business Manager (Custom App) → Hexnode MDM
**Bundle ID:** `com.gunner.team` | **Team ID:** `48LQUJV8G2`
**Version:** 3.0.0 (build 8)

---

## Prerequisites checklist

- [ ] cc-prompt-100 complete (build number bumped to 8)
- [ ] Active MFA session not required for Xcode/ASC — only AWS deploys
- [ ] Apple Developer account at https://developer.apple.com (Team: 48LQUJV8G2)
- [ ] App Store Connect access at https://appstoreconnect.apple.com
- [ ] Apple Business Manager access at https://business.apple.com
- [ ] Hexnode admin access
- [ ] **Privacy policy URL hosted** — required by Apple (see step 3 below)

---

## Step 1 — Archive in Xcode

1. Open `~/Dev/GunnerTeam/GunnerForms/GunnerTeam.xcodeproj`
2. In scheme selector (top toolbar): set device to **"Any iOS Device (arm64)"** — NOT a simulator
3. Set scheme to **GunnerTeam** / configuration **Release**
4. **Product → Archive**
5. Wait for Organizer to open automatically
6. The new archive should appear dated today, version 3.0.0 (8)

---

## Step 2 — Upload to App Store Connect

In Xcode Organizer:

1. Select the archive → **Distribute App**
2. Choose **App Store Connect** → Next
3. Choose **Upload** (not Export) → Next
4. Leave all checkboxes default (bitcode, symbols, manage signing) → Next
5. Xcode validates with Apple servers — may take 1–2 min
6. **Upload** → wait for confirmation ("Package Delivery Complete")

If upload fails on signing: Xcode → Preferences → Accounts → refresh certificates for team 48LQUJV8G2.

---

## Step 3 — Create the app in App Store Connect (first-time only)

If the app doesn't exist in ASC yet:

1. https://appstoreconnect.apple.com → **My Apps** → **+** → New App
2. Platform: **iOS**
3. Name: `GunnerTeam` (or `Gunner Team` — this is your internal display name)
4. Primary language: **English (U.S.)**
5. Bundle ID: select **com.gunner.team** from dropdown (populated from Developer Portal)
6. SKU: `gunner-team-ios` (arbitrary, internal only)
7. User Access: **Limited Access** (restrict to your admin/manager accounts)
8. **Create**

### Required metadata (fill before submitting)

| Field | Value |
|---|---|
| Description | Internal operations app for Gunner Roofing field teams. Manage jobs, inspections, fleet, and tasks. |
| Keywords | roofing, inspections, fleet, jobs, field |
| Support URL | https://www.gunnerroofing.com |
| Marketing URL | (optional) |
| **Privacy Policy URL** | **Required** — see note below |
| Age Rating | 4+ (run the questionnaire, answer No to everything) |
| Category | Business |
| Copyright | © 2026 Gunner Roofing LLC |

**Privacy policy:** Apple requires this for all apps, even private ones. Options:
- Host a simple policy at `https://team.gunnerroofing.com/privacy` or `https://www.gunnerroofing.com/privacy-app`
- Use a generator like Termly or App Privacy Policy Generator if you don't have one

### Screenshots (required)

Apple requires at minimum **6.9" iPhone** screenshots (1320 × 2868 px) for new submissions.
Easiest method: run app in iPhone 16 Pro Max simulator → take screenshots via Simulator menu (Cmd+S).

Suggested screens to capture (5–10 screenshots):
- Login screen
- Home / dashboard
- Job list or job detail
- Inspection / camera flow
- Task list

---

## Step 4 — Configure as Custom App

This is what makes it private and prevents public discovery.

1. In App Store Connect → your app → **Pricing and Availability**
2. Under **Distribution** → select **Custom App Distribution**
   - If you don't see this option, your Apple Developer account must be an **Organization** type (not Individual). Verify at developer.apple.com → Membership.
3. Under **Authorized Custom App Buyers**, add your organization's ABM Customer ID
   - Find it in ABM: https://business.apple.com → Settings → Enrollment Information → Organization ID
4. Save

> Note: Custom App Distribution replaces the old "B2B" program. The app will NOT appear in the public App Store.

---

## Step 5 — Select build and submit for review

1. App Store Connect → your app → **iOS App** section → click the build selector
2. Choose the build you just uploaded (3.0.0, build 8)
3. Answer Export Compliance: **No** (no encryption beyond iOS standard HTTPS/TLS)
4. Fill any remaining required fields (the red indicators in ASC)
5. **Submit for Review**

Review time: typically 1–3 days for Custom Apps. Apple may ask clarifying questions — respond promptly via Resolution Center.

---

## Step 6 — Accept in Apple Business Manager

Once Apple approves the app:

1. Log into https://business.apple.com
2. **Apps and Books** — search for `GunnerTeam` or `com.gunner.team`
3. The app should appear under **Custom Apps**
4. Purchase the number of licenses you need (1 per device — Custom Apps can be free or paid; set pricing in ASC)
5. Assign licenses to your **location** or **device group**

---

## Step 7 — Deploy via Hexnode

1. Hexnode admin → **Apps** → **App Repository**
2. **Add App** → **App Store** → search `GunnerTeam` or paste bundle ID `com.gunner.team`
   - It should appear since it's linked via ABM VPP
3. If using VPP token: Hexnode → **Enroll** → **Apple VPP** — ensure your ABM VPP token is synced
4. Create or update a **Policy** to include GunnerTeam under **App Management → Mandatory Apps**
5. Push to your device group (all enrolled iPhones)

Hexnode will silently install the app on enrolled devices — no user prompt required if MDM-supervised.

---

## Post-launch checklist

- [ ] Verify app opens and hits production API (`api.team.gunnerroofing.com` — confirm in CloudWatch logs)
- [ ] Test push notifications on a production-installed build (APNs production environment)
- [ ] Confirm login works against Cognito pool `us-east-2_hFVBSrcnn`
- [ ] Archive the `.xcarchive` or note the build in version control for rollback reference
- [ ] Update SOC 2 tracker: app distributed via MDM, no public App Store listing

---

## Subsequent releases

For every future release:
1. Run cc-prompt to bump `CURRENT_PROJECT_VERSION` (never reuse a build number)
2. Archive → Upload to ASC
3. In ASC, add the new build to the existing app listing → submit
4. ABM/Hexnode picks up the update automatically once approved (if using MDM-managed install)
