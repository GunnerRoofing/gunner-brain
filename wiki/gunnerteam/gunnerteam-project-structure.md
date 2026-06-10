---
type: synthesis
title: GunnerTeam Project Structure
created: '2026-05-22'
updated: '2026-06-09'
tags:
  - gunner
  - ios
  - backend
  - architecture
  - reference
status: stable
related:
  - '[[gunner/gunnerteam-api-aws-migration]]'
  - '[[gunner/aws-environment]]'
  - '[[gunner/masterdb-architecture]]'
  - '[[gunner/secure-coding-guide]]'
sources: []
---

# GunnerTeam Project Structure

Canonical layout of the GunnerTeam monorepo: SwiftUI iOS app plus an Express.js backend running on AWS Lambda.

## Root

The repository lives at `~/Dev/GunnerTeam/` (moved from `~/Documents/Gunner/GunnerTeam/` on 2026-06-02).

```
~/Dev/GunnerTeam/
├── CLAUDE.md           ← shared engineering rules
├── schema-postgres.sql ← canonical DB schema (source of truth)
├── cc-prompts/         ← sequential engineering history (cc-001 → cc-234)
├── gunnerteam-api/     ← Express.js backend (Lambda)
├── GunnerForms/        ← SwiftUI iOS app (Xcode)
├── terraform/          ← Lambda config IaC (env vars, IAM, VPC — not code deploys)
└── docs/               ← read-only reference docs
```

## iOS App (`GunnerForms/`)

SwiftUI Xcode project. The scheme is `GunnerTeam` and the build target is `GunnerForms`. Source lives under `GunnerForms/GunnerTeam/`, organized by feature folder:

| Folder | Contents |
|---|---|
| `App/` | App entry point, root tab/navigation shell, `ContentView.swift` |
| `Home/` | Home dashboard and landing views |
| `Jobs/` | Job list and detail flow — `JobListView.swift`, `JobGuidedView.swift`, `PhaseDetailView.swift` |
| `Photos/` | Photo capture and markup — `PhotoMarkupEditor.swift` |
| `Fleet/` | Vehicle inspection flow — `VehicleInspectionHubView.swift` |
| `Forms/` | IT Request / Change Order / AP form views |
| `Theme/` | Theme tokens, colors, shared styling |
| `Auth/` | Login, invite, and password-reset views |
| `Announcements/` | Announcement feed and creation |

## Backend (`gunnerteam-api/`)

Express.js app deployed as an AWS Lambda function. Source lives under `gunnerteam-api/src/`. Key files:

| File | Role |
|---|---|
| `app.js` | Express factory; mounts all routers, health and deep-link handlers |
| `lambda.js` | Lambda entry; adapts the Express app to the Lambda runtime, caches the handler across warm invocations |
| `routes/companycam.js` | CompanyCam proxy: jobs, photos, comments, tasks |
| `routes/fleet/index.js` | Fleet: vehicle schedules, inspections, S3 presigned upload, push notifications |
| `routes/org.js` | Org/user CRUD, roles, departments, managers |
| `routes/templates.js` | Form and task template management |
| `lib/db.js` | PostgreSQL pool and tenant-scoped query helpers |
| `lib/assistant-kb.js` | Assistant knowledge-base retrieval (S3-backed docs) |

## Current State

- `cc-234` is the latest completed engineering prompt; read the highest-numbered file in `cc-prompts/` for current patterns.
- Lambda alias `live` points at **v127** in production.
- `release/3.0.0` is frozen at `74c9d2c` for App Store submission.
- `main` HEAD is `be90174`.

## Key Files by Size / Complexity

| File | Approx. lines | Note |
|---|---|---|
| `JobGuidedView.swift` | ~900 | Guided job workflow; largest iOS view |
| `ContentView.swift` | ~777 | Root navigation shell |
| `PhaseDetailView.swift` | ~700 | Phase detail screen |
| `JobListView.swift` | ~600 | Job list |
| `VehicleInspectionHubView.swift` | ~300 | Fleet inspection hub |
| `PhotoMarkupEditor.swift` | ~240 | Photo annotation editor |

## Deployment

The backend is a single Lambda function (`gunnerteam-dev-api`, alias `live`) fronted by API Gateway and Cloudflare. See [[gunner/aws-environment]] for the full deploy sequence, migration invocation, and infrastructure details.
