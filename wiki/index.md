---
type: index
updated: 2026-06-10
owner: vault
---

# gunner-brain — Master Index

Shared knowledge base for the Gunner Roofing engineering team. Start at [[hot.md]] for
current system state, then drill into the section you need.

## Team

| Person | Section | App | Description |
|---|---|---|---|
| Tyler Suffern | [[tyler/overview]], [[gunnerteam/overview]] | GunnerTeam iOS + IT/Ops | Vault owner. iOS app + Express/Lambda API, plus company IT & operations. |
| Colin | [[colin/overview]] | GunnerCam | Multi-tenant AWS / Next.js field-operations app. |
| Leo | [[leo/overview]] | gunner-ops | Job-lifecycle CRM, replacing Monday.com. |
| Doug | [[doug/overview]] | Lead Finder, Review Engine, Content Creator, WP Local Page Template | Four standalone apps. |

## App Sections

- [[tyler/overview]] — Tyler: IT / Ops.
- [[gunnerteam/overview]] — Tyler: GunnerTeam iOS app + API.
- [[colin/overview]] — Colin: GunnerCam.
- [[leo/overview]] — Leo: gunner-ops.
- [[doug/overview]] — Doug: Lead Finder, Review Engine, Content Creator, WP Local Page Template.

## Shared

Read by everyone; write with coordination.

- [[shared/api-contracts/README]] — cross-app API & event contracts (one file per integration).
- [[shared/decisions/README]] — architecture decision records (ADRs).
- [[shared/architecture/README]] — architecture diagrams and high-level design docs.
- `shared/entities/` — people, orgs, and shared entities.
- `shared/vendors/` — third-party vendor / API reference pages.

## Meta

- `meta/` — session notes (from `/save`) and lint reports (from `/lint`).
  - [[meta/session-2026-06-13-cc608-742-bundle-perf-gamification-ios-polish]] — 2026-06-13: Bundle perf investigation (v183–v220), gamification Phase 2–3 (achievements/leaderboard/redemption/payroll), iOS polish (cc-608–742), wiki lint auto-fix.
  - [[meta/session-2026-06-11-cc403-412-fleet-inspection-hub-polish]] — 2026-06-11: AuxComponents (StatusBadge, EmptyStateView, StickyEditBar, DestructiveConfirmSheet), aux screen UX sprint.
  - [[meta/session-2026-06-11-cc390-402-fleet-inspection-hub-polish]] — 2026-06-11: Fleet inspection single-camera, driver feedback, hub redesign, notification animation.
  - [[meta/session-2026-06-11-cc370-389-fieldportal-rename-fleet-ux]] — 2026-06-11: Field Portal rename (CC*→FP*, /companycam→/fieldportal), fleet UX.
  - [[meta/session-2026-06-11-cc369-393-time-tracking-geofence-travel]] — 2026-06-11: Time tracking, geofencing, travel GPS.
  - [[meta/session-2026-06-11-cc299-338-perf-polish-prod-infra]] — 2026-06-11: Perf sprint (ETag, cursor, N+1), prod Aurora seed, fleet time tracking.
  - [[meta/session-2026-06-10-omp-config-plugin-claudemd-merge]] — 2026-06-10: OMP config fixes, plugin refresh (aws-serverless, context7, stripe), CLAUDE.md merge from old vault.
  - [[meta/session-2026-06-10-save-skill-test]] — 2026-06-10: Save skill workflow test.
- [[log.md]] — append-only activity log across all sections.

## How This Vault Works

- **Each person owns their section.** Tyler owns `tyler/` and `gunnerteam/`; Colin owns
  `colin/`; Leo owns `leo/`; Doug owns `doug/`. `shared/` is read by all, written with
  coordination.
- **`/save`** files a session into your own section's `meta/`, updates your section's
  `hot.md` and `index.md`, and appends to the top-level `log.md`.
- **`/lint`** sweeps every section and writes a report to `meta/lint-report-YYYY-MM-DD.md`.
- Identity is declared per-checkout in `CLAUDE.local.md` (gitignored). The vault owner
  (Tyler) maintains the system-wide `hot.md` and `index.md`.
