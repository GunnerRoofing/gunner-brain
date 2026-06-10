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
