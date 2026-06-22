---
type: hot-cache
owner: colin
updated: 2026-06-21
tags: [colin, hot-cache, gunnercam]
status: active
---

# GunnerCam — Hot Cache

<!-- Colin: update this at the start of each session -->

## Current Focus

- **My Day** is now the app home (`/` → `/my-day` as of 2026-06-11) — health-sorted job cards, focus workflow, finance/SOW panels. See [[colin/my-day]].
- Forward-looking reporting + contract-value forecast ([[colin/forward-reporting]]); Connecticut permit automation ([[colin/permits]]).
- `gunner-masterdb` shared-core migration ~90% complete ([[colin/masterdb-sync]]).

## Recent Changes (as of 2026-06-21)

- Role hierarchy is now `super_admin > manager > pm > standard > restricted` (old `admin` role retired). See [[colin/data-model]].
- External API switched to scoped `ccam_*` SHA-256 hashed keys with per-route `allowed_scopes` (migration 0046); full perf pass landed. See [[colin/external-api-integration]].
- Stripe payments built on `feat/stripe-payments-multiaccount`; Make.com owns change-order billing. See [[colin/stripe-make]].
- Live integrations: Monday read-through, Dialpad calls in My Day, Gemini route review, crew location pings, managers map.

## Active Issues

- Single AWS `dev` stage only — no production split, no CI, no Sentry/audit log. See [[colin/ops-deploy]].
- Google SSO code-complete but blocked on a Google OAuth client. See [[colin/google-sso]].
- Hardcoded-NY `bucket_day` is a known multi-timezone bug. See [[colin/gotchas]].

## Key Decisions

- Multi-tenant from row 1; white-label SaaS endgame (~50k users target). See [[colin/decisions]].
- Make.com (not GunnerCam) owns change-order invoicing. See [[colin/stripe-make]].

## Integration Points

- **GunnerTeam iOS** (Tyler) — consumes GunnerCam's outbound server-to-server API (photos, projects, tasks, location pings). Auth via scoped `ccam_*` keys. See [[colin/external-api-integration]].
- **gunner-ops** (Leo) — shares core tables via `gunner-masterdb`. See [[colin/masterdb-sync]].
- **Monday.com / Stripe / Make.com** — job sync, invoicing, automation. See [[colin/monday-integration]], [[colin/stripe-make]].
