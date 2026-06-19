---
type: overview
owner: tyler
app: GunnerTeam iOS
created: 2026-06-10T00:00:00.000Z
status: active
updated: '2026-06-18'
---

# GunnerTeam iOS — Section Overview

## App

Swift/SwiftUI iOS app powering **field operations** for Gunner Roofing crews.
Crews use it on the job site to run their daily workflow — jobs, phases, guided
tasks, photos, inspections, and forms.

## Architecture

- **API** — Lambda (Node.js), function `gunnerteam-dev-api`, fronted by API
  Gateway.
- **Database** — RDS PostgreSQL (**masterdb**).
- **Auth** — AWS Cognito.
- **Storage** — S3 (deploy artifacts + assistant/document storage).
- **Push** — SNS → APNs for notifications.

## Key Features

- Job management and **phase workflows**.
- **Guided tasks** (step-by-step crew workflows).
- **CompanyCam photo integration** (via GunnerCam white-label).
- **Fleet / vehicle inspections**.
- **Change orders** (Monday.com + Stripe invoicing).
- **Forms** and **announcements**.

## Repo

`GunnerRoofing/gunner-ios` — monorepo containing the iOS app (`GunnerForms/`)
and the Lambda backend (`gunnerteam-api/`).

## Current State

- Lambda **v294** live (alias `live` on `gunnerteam-dev-api`). See [[tyler/hot]] for the current version before deploying.
- iOS **`main`** branch active. Distributed via Apple Business Manager (Hexnode MDM).

## Integration with GunnerCam

- **Customer photos endpoint** — pulls crew/customer photos from GunnerCam.
- **Project webhooks** — receives project events from GunnerCam.
- Runs against the **white-label CompanyCam environment** (GunnerCam).

## Related

- [[overview]]
- [[aws-environment]]
- [[masterdb-architecture]]
- [[gunnerteam-project-structure]]
- [[CONTRIBUTING]] — deploy workflow, branching rules, pre-deploy checklist
- [[gamification-original-brief]] — original feature brief (implemented cc-603–712)
- [[../tyler/overview]]
