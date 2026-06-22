---
type: index
owner: colin
created: 2026-06-10
updated: 2026-06-21
tags: [colin, index, gunnercam]
status: active
---

# GunnerCam — Index

GunnerCam (repo `WL-CompanyCam`, internal name "Gunner Project Hub") — a multi-tenant, white-label CompanyCam replacement for roofing crews/PMs, built on Next.js 16 + Drizzle + AWS (RDS/S3/Cognito/SST). 28 reference notes distilled from a month of build sessions (2026-05-21 → 2026-06-21). See [[colin/hot]] for current focus.

## Overview

- [[colin/overview]] — stack, tenancy model, and the Gunner ecosystem map
- [[colin/boss-briefing]] — executive-level project overview
- [[colin/build-timeline]] — what was built, in order, since early May
- [[colin/feature-inventory]] — catalog of every feature by area
- [[colin/user-guide]] — end-user, screen-by-screen view

## Architecture & data

- [[colin/data-model]] — Drizzle schema, role hierarchy, conventions, indexes
- [[colin/aws-infra]] — AWS account, services, SST config, VPC/RDS/S3/Cognito
- [[colin/ops-deploy]] — deploy mechanics, SST stages, crons, CI/observability gaps
- [[colin/provisioning-tickets]] — RDS / Drizzle / S3 setup tickets

## Features

- [[colin/my-day]] — the flagship My Day home dashboard (now the app home)
- [[colin/permits]] — Connecticut permit automation workflow
- [[colin/photos-uploads]] — photo / S3 presigned upload pipeline
- [[colin/forward-reporting]] — forward-looking manager bar + contract-value forecast
- [[colin/managers-map]] — managers Google Map dashboard
- [[colin/location-pings]] — crew/PM location ping ingest + dashboards
- [[colin/gemini-route-review]] — Gemini-powered manager route review
- [[colin/dialpad]] — Dialpad call integration in My Day
- [[colin/points-leaderboard]] — points & leaderboard feature

## Integrations

- [[colin/external-api-integration]] — outbound server-to-server API for Tyler's GunnerTeam iOS app
- [[colin/monday-integration]] — Monday.com read-through integration
- [[colin/stripe-make]] — Stripe invoicing + Make.com automation split
- [[colin/masterdb-sync]] — `gunner-masterdb` shared-core migration & sync
- [[colin/google-sso]] — Cognito / Google SSO login (code-complete, blocked on OAuth client)

## Decisions & context

- [[colin/decisions]] — locked architectural rules + open decisions
- [[colin/risks]] — top operational risks
- [[colin/people-and-context]] — Gunner people, the ecosystem, how to read an ask
- [[colin/gotchas]] — recurring problems and their fixes
- [[colin/mvp-roadmap]] — what "MVP done" means + ticket sequence

## Sessions

_Saved working sessions land in `wiki/colin/meta/` via `/save`._

## Runbooks

_None yet._
