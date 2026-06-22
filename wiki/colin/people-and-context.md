---
type: reference
owner: colin
app: GunnerCam
created: 2026-05-21
updated: 2026-06-21
tags: [wl-companycam, people, context, meetings, roles]
status: active
---

# People & Context

Who and what surrounds WL-CompanyCam, pieced together from the chat history and ~30 work sessions (2026-05-21 → 2026-06-21). Useful for knowing who an ask is really for.

## The company

- **Gunner Roofing** — the client/employer. A roofing contractor (GitHub org `GunnerRoofing`). The app is internally **GunnerCam** (a.k.a. the Gunner Project Hub), a CompanyCam replacement for roofing PMs and crews.
- **Origin:** a planning meeting on/around May 5 (recorded as `Halloween Blvd.m4a`, transcribed via Gemini 2.5 Pro on 2026-05-05) defined the requirements. See [Origin meeting](#meetings--product-direction) below.
- **Endgame:** white-label the product and sell it as a SaaS to other roofing companies — multi-tenant from row one, ~50k-user target. Cost-consciousness is explicit (the boss watches AWS spend). **Phased GTM (May 29 standup):** ship as a Gunner-internal proof of concept first; white-labeling and the Ops Portal are deferred.

## People

| Person | Handle / email | Role | Notes |
| --- | --- | --- | --- |
| **Colin Wong** (you) | `cwong` / `colin.wong@gunnerroofing.com` | Gunner-side lead for GunnerCam; effectively sole dev via Claude Code | Picked up the QP offshore backlog; owns `wiki/colin/` in gunner-brain. Manager/Gunner-admin persona. Not a career engineer; learning the stack. Prepares **standup** most mornings. |
| **The boss** | — | Non-technical day-to-day; ran a software company before | Knows DB schema, S3, IAM, grep. `BOSS_BRIEFING.md` / [[colin/boss-briefing|Boss Briefing]] written for him. Smart, not hands-on-code. |
| **Eric Recchia** | — | Business/product voice for GunnerCam (Speaker 1 in planning meetings) | Non-technical; makes product-direction calls but **does not give implementation guidance**. Show him finished features for critique, not implementation details. |
| **Doug Kilzer** | — | Operations voice (Speaker 3 in some sessions); non-technical | Owns Lead Finder, Review Engine, Content Creator, WP Templates in the wiki ownership map. |
| **Tyler Suffern** | — | Owns **GunnerTeam** iOS app (`gunner-ios` + `gunnerteam-api`) and IT/Ops | Consumer of Colin's [[colin/external-api-integration|external API]]. Flagged early that username-based login beats email for field crews. Listed as a `manager` on dev DB. Recurring meeting attendee. |
| **Leonard "Leo" Fuentes** | `@leonardfuentes` | Owns gunner-ops | Single source of truth / gatekeeper for gunner-ops + gunner-masterdb access (GitHub write, AWS creds, DB credentials, JWT secrets, Google Places key). Ops Portal ("Leo portal") was ~3 weeks out, not yet started, as of late May 2026. |
| **Joe Massari** | `jmassari` / `joe@gunnerroofing.com` | Operations / GM | **Primary user of the GunnerCam manager web view.** Promoted to `manager` on dev DB 2026-06-11 as the non-admin manager test account. |
| **Sarah Gengo** | `sgengo` / `sarah.gengo@gunnerroofing.com` | Ops | Flips Monday jobs to "Scheduled" to trigger the [[colin/monday-integration|Monday]]→GunnerCam webhook. Dev DB's lone `company_admin` (as of 2026-06-11); seeded PM on ~half the projects. |
| **Eddie Prchal** | — | Product / walkthrough attendee | Surfaced multi-PM combo-job (roofing + siding) invoicing complexity. |
| **Becky Blake** | — | May 29 standup attendee | — |

## QP / Offshore Vendor Team

The **Quote Portal (QP)** (a.k.a. "Leo portal") is an upstream sibling app, not GunnerCam — but Colin picked up its offshore backlog and produced reference docs.

- **Built by Impressico**, an offshore vendor (~10 devs), over ~1,018 commits Oct 2024 → May 2026.
- Key authors: **Madhu** (`arja.kiran@impressico.com`, ~450 commits, owns the `ux_rules`/SOW/UX-JSON engine) and **Upender Kumar** (~250 commits).
- Handoff-era team: **Amit, Madhu, Ruchir** — targeting a **29 May 2026** delivery against a 331-row tracker (`QP-LastMile.csv`). Madhu and Amit were the departing contacts; **Ruchir** is the named Gunner-side reviewer.
- Codebase shows load-bearing typos worked around rather than fixed (e.g. "Speciality Roof" vs "Specialty Roof"); GitHub Copilot used lightly (2 of 1,018 commits).
- **Axe Automation** is the external vendor maintaining Gunner's [[colin/stripe-make|Make.com]] scenarios — attributed in edit history for the HubSpot→Monday scenario (`3466413`) and Stripe scenario (`3939700`); made six edits to `3939700` between 2026-05-14 and 2026-05-22 to fix the due_date bug.
- Colin's QP reference docs at `/Users/colin.wong/repos/`: `QP-ARCHITECTURE.md` (554 lines, 8 Mermaid diagrams), `QP-UI-WALKTHROUGH.md`, `QP-STANDUP-QUESTIONS.md`, `QP-OFFSHORE-HANDOFF.md`.

## Role model & access gates (GunnerCam)

Auth contract lives in `src/lib/dal.ts` — see [[colin/decisions|Decisions]] for the locked rules.

- **Current hierarchy:** `super_admin > company_admin ≥ manager > pm > standard > restricted`. Crew members are a **separate principal type** (`crew_members` table), not users; they reach only projects their crew is assigned to.
- An earlier T-9/T-10 change retired the legacy `admin` role; at that point roles were just `super_admin`/`manager`/`standard`. The `pm`/`company_admin`/`restricted` tiers are the later, richer state.
- `requireManager` / `isManagerPrincipal` returns true for **manager, company_admin, AND super_admin**.
- **Daily-log filing is restricted to global `pm` role only** (`principal.role === 'pm'`) — enforced client-side in `src/app/(app)/projects/[id]/page.tsx` (`canFileLog`) AND server-side in `src/app/api/projects/[id]/daily-logs/route.ts`. Managers/super_admins cannot file logs even when assigned as the project PM. A prior bug used `isGlobalPm || isProjectPm`, letting a manager who was the assigned project PM leak through — fixed to a strict global-role check.
- **Admin nav by role:** super_admin → Companies; manager → Users/Offices/Crews/Task Templates; standard → none (enforced at route/DAL level, not just sidebar).
- **Dev DB role census (2026-06-11):** 1 super_admin, 1 company_admin (Sarah Gengo), 2 managers (cwong, Tyler Suffern), ~40 PMs (all CompanyCam imports), 3 standard.

### Known gate inconsistencies (regression surface)

- `projects/[id]/page.tsx` computes `isManager` with a narrow `role === 'manager'` check that **excludes `company_admin`** — give company_admin users extra attention in PM-vs-manager regression testing.
- `listProjectsForPrincipal` treats manager and super_admin as broad-scope but **omits company_admin**, contradicting the DAL's "company_admin is manager-and-up" definition. Several project-detail spots gate on manager/super_admin only and need reconciling if "manager surfaces" = all three roles.

## Test accounts & auth

- **Dev Cognito user pool ID:** `us-east-2_sEOcsFA76` (GunnerCam test/seed auth). If seeded logins fail with "user not found," run:
  `SEED_USER_PASSWORD=TestPass123! AWS_PROFILE=devops npx tsx scripts/provision-test-users.mts`
- Seeded users use **username-based login** (not email), default password **`TestPass123!`** (override via `SEED_USER_PASSWORD` at provision time). Provisioned via `scripts/provision-test-users.mts`.

| Persona | Username / email | Role | Purpose |
| --- | --- | --- | --- |
| `cwong` | `cwong` | manager / Gunner admin | Colin's persona |
| superadmin | `superadmin@projecthub.example` | super_admin | Only role that sees `/admin/companies` |
| Sarah Gengo | `sgengo` / `sarah.gengo@gunnerroofing.com` | standard (company_admin on dev DB) | PM on ~half projects |
| Joe Massari | `jmassari` / `joe.massari@gunnerroofing.com` | standard/sales → manager (2026-06-11) | Manager-web-view test account |
| crew | `zach@roofforce.example`, `dawn@roofforce.example` | crew | Crew principal checks |
| Acme admin | `acmeadmin` | manager (Acme Construction) | Cross-corp tenant-isolation checks |
| App review | `appreview` / `appreview@gunnerroofing.com` (Cromwell CT) | — | App Store review/QA; present in **both** dev pools (dev-gunner-cognito and gunner-masterdb-dev) |

- No dedicated `restricted` or project-`PM` seed account — create manually via `/admin/users`.
- **Local login override:** `DEV_AUTH_USERNAME=cwong` in `.env.local` overrides any real login; to log in as Joe locally, comment it out and restart the dev server. A localhost QA switcher also flips between user views without a real login.

## Meetings & product direction

### Origin meeting — `Halloween Blvd.m4a` (transcribed 2026-05-05, Gemini 2.5 Pro)

- **Speaker 1** (non-technical Gunner stakeholder) defined CompanyCam's core model: **address as central object** with job-type attributes, project manager, crew, and timestamped photos to S3.
- **Speaker 2** (dev) proposed starting from the DB schema.
- **Speaker 3** (Tyler) flagged username-over-email login and the UTM use case.
- Quote-portal auto-population and Tyler's app pulling data were integration goals from the start but out of scope for the initial build.

### May 29, 2026 standup

Attendees: Eric Recchia, Doug Kilzer, Colin Wong, Leonard Fuentes, Tyler Suffern, Eddie Prchal, Becky Blake. Decisions:

- **Phased GTM:** ship GunnerCam + Quote Portal live ASAP as a Gunner-internal proof of concept; **defer white-labeling and Ops Portal**; iron out kinks on Gunner's own team before SaaS.
- **Task management lives in GunnerCam** (not a separate ops portal for now); managers may get **batch task assignment** as a short-term substitute since Monday can't natively push task sets.
- **Universal Job ID** originates in Quote Portal and flows through HubSpot/Monday/GunnerCam.
- **Project import** scoped to active + scheduled projects from Project Takeoff.
- **Customer comms** via existing customer portal; India launch proceeds with issue remediation.
- **Shelved:** centralized database, Quote Portal "repair" button, custom app (use Tyler's app instead). Offline mode left unresolved as group research.
- **Action items:** Colin → batch task manager + Stripe invoice view; Eric → Quote Portal contact editing; group → HubSpot property sync + Job ID propagation.

### June 9, 2026 app walkthrough — multi-PM combo jobs

Attendees: Eric Recchia, Eddie Prchal, Tyler Suffern.

- Combo jobs (roofing + siding): PMs can optionally be **granularized to see only their trade's tasks**; ungranularized PMs see everything.
- When one PM completes and removes their name, the job still progresses for the other PM.
- **Invoicing for combo jobs is the messy edge** — partial-completion invoices (COC, final) may need to be pushed manually.

### Manager-view review meeting (~Jun 8–10, 2026)

Attendees: Tyler, Eric, Eddie, Colin. Decided to simplify the manager web view toward Joe's ops-level visibility rather than PM workflows (PMs use the mobile app). Payments visibility flagged as worth preserving for AR.

## Integration flow & ownership boundaries

- **Tasks are sourced from GunnerCam:** GunnerTeam iOS pulls tasks via a GunnerCam API endpoint; Tyler's app does **not** maintain its own task store. Task sets/templates were not yet built at standup time.
- **Normal Monday→GunnerCam job flow:** Ops (Sarah) flips a job to "Scheduled" → Monday webhook fires → project appears in GunnerCam pre-populated (incl. Payments tab). PMs never touch Monday or HubSpot directly. The integration key (`ccam_…`) is a server-to-server credential held by Make/the webhook URL, never exposed to end users. See [[colin/monday-integration|Monday Integration]].
- **HubSpot sync is Quote Portal + Make scope;** GunnerCam stores `hubspotId` as a passthrough in `external_ids`.
- **Offline mode, device push, and exact task-grid UX are Tyler's iOS scope, not GunnerCam.** No new code should create new Monday items ("Monday in the short run is just an existing conduit").
- **Wiki ownership (gunner-brain, remote `GunnerRoofing/gunner-brain`):** Colin → GunnerCam/WL-CompanyCam; Leo → gunner-ops; Tyler → GunnerTeam iOS + IT/Ops; Doug → Lead Finder/Review Engine/Content Creator/WP Templates. Each engineer has `wiki/<name>/`; shared docs in `wiki/shared/`. Colin's personal vault `claude-obsidian` (`github.com/AgriciDaniel/claude-obsidian`) is distinct from gunner-brain.

## CompanyCam import (provenance of PM accounts)

The CompanyCam import **deliberately created all imported users as `pm` role** — no managers derived from CompanyCam admin flags (a known gap, no current implementation). Shared mailboxes (`admin@`, `office@`) were filtered out so projects have human owners; 30 projects round-robin-assigned across real-person PMs. Manager roles (cwong, Tyler, Sarah) were set manually. See [[colin/masterdb-sync|MasterDB Sync]].

## Environments & names

- **Repo:** `~/repos/WL-CompanyCam` (GitHub `GunnerRoofing/WL-CompanyCam`).
- **Dev site:** `project.dev.gunnerroofing.com` (renamed from `companycam.dev.gunnerroofing.com`), DNS via Cloudflare.
- **AWS:** account `980921733684`, region `us-east-2`, SSO profile `devops`. See [[colin/aws-infra|AWS Infra]].
- **Related repos:** `gunner-ios` / `gunnerteam-api` (Tyler); `gunner-masterdb` — the shared master DB the May 21 migration folds core tables into.

## How to read an ask

- "Is it live?" usually means the **dev site**, not localhost and not GitHub. Push ≠ deploy.
- "For standup" / "for my boss" → the answer should be **plain-language and outcome-focused**, not code-level.
- "As Tyler would" → exercise the **external API** with a bearer key.
- Screenshot + "I dislike this / make it like CompanyCam" → a **UI iteration**; CompanyCam is the north-star reference.
- An ask routed through **Eric** is product critique of finished work, not an implementation spec.

## Open questions / TODOs

- Reconcile `company_admin` handling across `projects/[id]/page.tsx` (`role === 'manager'` check) and `listProjectsForPrincipal` (omits company_admin) against the DAL's "company_admin is manager-and-up" contract — decide if "manager surfaces" = all three roles.
- Deriving manager status from CompanyCam admin flags during import is an unimplemented gap.
- Multi-PM combo-job invoicing/close-out sequence (COC, final invoice) may need reworked tasks; partial-completion invoice triggers currently manual.
- Offline mode for GunnerCam/iOS remains an unresolved group research item from the May 29 standup.
- `claude -p` non-interactive CLI is blocked in `permit-poc`: `colinwong0224@gmail.com` (personal Claude.ai org) is not approved in the Gunner Roofing Anthropic Console org — pending an org owner approving `colin.wong@gunnerroofing.com`'s join request (or set `ANTHROPIC_API_KEY` to bypass). `codex exec --ephemeral` is the working headless alternative (OpenAI second opinion).
- Colin's GitHub-org / AWS / DB access was still gated on a single org-member grant from Leonard as of 2026-05-27 (no membership in account `980921733684`, no DSNs); confirm current state.

---
*Sources: ~30 distinct work sessions, 2026-05-21 → 2026-06-21. Raw nuggets at `.raw/ingest-2026-06-21/by-topic/people-and-context.json`.*
