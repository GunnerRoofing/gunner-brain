---
type: overview
owner: colin
app: GunnerCam
created: 2026-05-07
updated: 2026-06-21
tags: [wl-companycam, overview, ecosystem]
status: active
---

# GunnerCam — Overview

Section index: [[colin/index]] · Hot cache: [[colin/hot]]

Web app replacement for CompanyCam. Each project = a customer's address. PMs and crews use it (phone or laptop) as the system of record for a roofing job: photos, files, comments, status, assignments, activity feed. As of 2026-06-21 it has grown into a multi-tenant, AWS-hosted field-operations platform covering projects, photos, documents, tasks, change orders (Stripe draft invoicing), Monday.com job/contract sync, manager forecasting dashboards, and an authenticated external API.

**Built for resale.** Today serves Gunner Roofing only; every architectural choice traces back to "scale to 50+ paying tenants without a rewrite."

> [!note] This note is high-altitude. It links out to dedicated topic notes — don't duplicate their depth here.

## Stack

| Layer | Choice |
|---|---|
| Framework | Next.js 16.2.4 (App Router) — note: behavior diverges from training data; `AGENTS.md` mandates reading `node_modules/next/dist/docs/` first |
| UI | React 19.2.4, Tailwind v4, shadcn/ui (copied in repo), `@base-ui/react` |
| Auth | AWS Cognito (JWT cookie, signature verified locally) — Google SSO code-complete, blocked on a Google OAuth client (see [[colin/google-sso]]) |
| ORM | Drizzle (`drizzle-orm` + `drizzle-kit`) |
| DB | RDS Postgres 16 (us-east-2) |
| Driver | postgres.js (`postgres`) |
| Files | S3 (presigned upload — bytes never touch Lambda); see [[colin/photos-uploads]] |
| Hosting | Lambda + CloudFront via **SST v4** (`sst@^4.13.1`) + OpenNext |
| Tests | Vitest, tests sit alongside source (`*.test.ts`) |
| Lint | ESLint 9 (`eslint.config.mjs`) |

> [!warning] Stale handoff docs: some older external handoff docs say **SST v3** — the repo runs **SST v4** (`sst@^4.13.1`). The founding-day stack (Postgres/RDS, S3, Cognito, Drizzle) is locked in [[colin/decisions]].

## Architecture rules (non-negotiable, from DECISIONS.md)

1. Multi-tenant: every domain table carries `corporation_id NOT NULL`.
2. Polymorphic creator: `creator_id UUID` + `creator_type` ∈ `{user, crew_member, integration, system}`.
3. Project is the spine — no global photo feed/map/activity.
4. `updates.bucket_day` is a stored generated column (Eastern Time), indexed.
5. `external_ids` is JSONB with GIN index — never `ALTER TABLE` for new integrations.
6. Soft-delete via `deleted_at`. Hard delete forbidden in V1.
7. Permissions go through one resolver. Centralized in `src/lib/dal.ts`.
8. Photos store URIs, not bytes. Presigned upload, background variant pipeline (V2).
9. `captured_at` ≠ `created_at`. Capture drives day buckets; created drives sync.
10. `modified_since` on every list endpoint for incremental sync.

Full rationale + open calls in [[colin/decisions]]. Schema detail in [[colin/data-model]].

## Tenant model

- **corporation → office → user** hierarchy, with **cross-tenant crews** (one crew can work across multiple corporations via `corporation_crews`).
- Multi-tenant from row one: `corporation_id` on every domain row.
- The **project (address)** is the core object: `corporations`/`offices`/`users`/`manager_assignments`; `crews`/`corporation_crews`/`crew_members`; `projects` with denormalized address + JSONB `external_ids` (GIN-indexed → new integrations need zero migrations); `updates` table with generated `bucket_day` column for the day-bucketed feed; `photos` + `photo_uris` async variant pipeline; `files` vs `document_templates` kept distinct; separate `comments`/`voice_notes`/`messages` tables. Schema highlights in [[colin/data-model]].

### Why custom instead of CompanyCam

1. CompanyCam has no day-bucketed activity feed (it's an infinite-scroll firehose) — see [[colin/my-day]].
2. CompanyCam is single-tenant only (no parent-corp / sub-office / white-label).
3. CompanyCam has no integration spine for QP, Tyler's app, Stripe, PandaDoc, Monday, HubSpot.

## Three-service split

Next.js app is the bridge between RDS, S3, and Cognito (no direct connections between them):

- **RDS:** structured data, including S3 keys + `cognito_sub`
- **S3:** file bytes, addressed by key
- **Cognito:** identity + tokens, doesn't know business

Photo upload: browser asks app for presigned PUT → uploads direct to S3 → tells app the key → app inserts photo row. Compute bill stays flat regardless of photo volume. Detail in [[colin/photos-uploads]].

Login: app verifies Cognito JWT signature locally on every request (no Cognito round-trip after sign-in) → looks up `users` row by `cognito_sub`.

## Feature areas (catalog)

Each links to its deep-dive; full catalog in [[colin/feature-inventory]].

| Area | Note |
|---|---|
| PM daily dashboard (flagship) | [[colin/my-day]] |
| External server-to-server API (Tyler's GunnerTeam app) | [[colin/external-api-integration]] |
| Monday.com read-through sync | [[colin/monday-integration]] |
| Stripe invoicing + Make.com automation | [[colin/stripe-make]] |
| Connecticut permit automation | [[colin/permits]] |
| Gemini-powered manager route review | [[colin/gemini-route-review]] |
| Crew/PM location pings + dashboards | [[colin/location-pings]] |
| Managers Google Map dashboard | [[colin/managers-map]] |
| Forward-looking manager bar + contract-value forecast | [[colin/forward-reporting]] |
| Photo / S3 upload pipeline | [[colin/photos-uploads]] |
| Points & leaderboard | [[colin/points-leaderboard]] |
| Dialpad call integration | [[colin/dialpad]] |
| Cognito / Google SSO login | [[colin/google-sso]] |

## Build status (as of 2026-06-21)

- MVP substantially built — as of 2026-05-28, ~8 of 20 V1 tickets done: Cognito login, role-scoped projects list, project detail with day-bucketed feed, S3 presigned photo upload, comments, files, status changes, project labels, assignments (users + crews), admin user/crew management, mobile camera capture. (Corrected a prior AI summary that claimed nothing was implemented.)
- Phases 3–5 (Stripe, QP sync, PandaDoc) had not started at that point; since then the integration/perf/reporting features in the catalog above have landed. See [[colin/build-timeline]] and [[colin/mvp-roadmap]].

## Dev seed accounts & dev-auth shim

Seed spans three tenant corps plus a superadmin + a subcontractor org. The dev-auth shim keys off **username** (set `DEV_AUTH_USERNAME` in `.env.local`), **not** email.

| Tenant | Username | Person / role |
|---|---|---|
| Gunner Roofing | `cwong` | Colin — manager |
| Gunner Roofing | `sgengo` | Sarah — PM / standard |
| Gunner Roofing | `jmassari` | Joe — standard |
| Acme | `acmeadmin` | manager |
| BrightWork | `brightadmin` | manager |
| Roof Force (subcontractor) | `zwebb` | — |
| Roof Force (subcontractor) | `dlavia` | — |
| Superadmin | `superadmin@projecthub.example` | superadmin |

### Office-list ambiguity (open)

Eric named "New York, New Jersey, Cromwell"; Doug named "Cromwell, Stamford, Jersey." Both agree on **Cromwell CT** + **New Jersey**; Eric's "New York" ≈ Doug's "Stamford" (a CT town near the NY border). V1 seeds three offices using Eric's labels with blank address fields. Reconcile with Eric/Doug.

## Manager web view → Ops Portal merge (decision, evolving Jun 8–10)

Consistent decision across the 2026-06-08 → 2026-06-10 sessions (Eddie Prchal): the GunnerCam **manager web view should not remain standalone**. It began as a CompanyCam rip; now that a dedicated PM mobile app covers PM workflows, the useful pieces (workflow screen, payments, a daily/live-jobs view) should be **bolted onto the ops portal as a screen**. Ship it in GunnerCam for now (ops portal isn't ready) but build it portably. Primary (essentially only) user of the manager web view is **Joe** (possibly Sarah); PMs use the mobile app.

> [!caution] The 2026-06-10 session's Claude output failed (selected model "fable" unavailable); that session's content is raw meeting transcript, not analysis.

## Where this sits in the Gunner ecosystem

GunnerCam / WL-CompanyCam is one of **five separately-owned systems** (per the 2026-05-29 standup). Ecosystem map + people in [[colin/people-and-context]].

| System | Owner / team | What it is |
|---|---|---|
| **GunnerCam / WL-CompanyCam** | Colin | this app — field-ops + white-label CompanyCam replacement |
| **Quote Portal (QP)** | India / Impressico | sales/quote portal; ~95% of overall system by surface (backend + Aurora + customer portal + WordPress + Snowflake) |
| **Ops Portal / "Leo" / gunner-ops** | Colin + Leonard | internal job-management CRM (Monday replacement); FastAPI + Vite/React on its own RDS |
| **Tyler's native iOS app (GunnerTeam)** | Tyler | offline/grid field app; consumes GunnerCam's [[colin/external-api-integration]] |
| **Monday.com + HubSpot** | — | interim integration glue ([[colin/monday-integration]]) |

Status snapshot (2026-05-29 standup): QP going live Mon/Tue; Ops Portal ~3 weeks out and not started; GunnerCam was the active build. Immediate goal is a Gunner-internal proof of concept before white-labeling.

Engineering shares an Obsidian vault `GunnerRoofing/gunner-brain` (GitHub, LLM-Wiki pattern) with per-engineer sections — `wiki/tyler/` + `wiki/gunnerteam/` (Tyler — GunnerTeam iOS + IT/Ops), `wiki/colin/` (GunnerCam), `wiki/leo/` (gunner-ops), `wiki/doug/` (Lead Finder / Review Engine / Content Creator / WP Templates), `wiki/shared/` — auto-pull/push via the Obsidian Git plugin. **Secret-redaction is mandatory** for anything destined for `gunner-brain` (org confidentiality) — Stripe, Gemini, Maps, the RSA private key, and AWS creds appear in raw transcripts and must be referenced by name only.

> This note (Colin's personal `claude-obsidian` vault) is the WL-CompanyCam corner. gunner-ops and QP each have deep technical surfaces (own RDS, auth, deploy gotchas, security sharp edges) that belong in their own notes — they live in [[colin/people-and-context]] today; see also [[colin/masterdb-sync]] for the shared-core story and [[colin/aws-infra]] for the shared AWS account (980921733684, us-east-2).

### Sibling systems at a glance (link out, do not duplicate)

These are separately-owned systems with their own deep surfaces; summarized here only to orient. Detail belongs in their own notes (today mostly [[colin/people-and-context]]).

- **gunner-ops / "Leo"** — internal job-management CRM (Monday replacement). **FastAPI (Python 3.13) on arm64 Lambda + Mangum**, SQLAlchemy 2.x, Vite/React SPA, IaC via **AWS SAM** (not SST). Repo `GunnerRoofing/gunner-ops`. Own **dedicated private RDS Postgres 16** (`gunner-ops-dev`, VPC-only) — **not** a schema in the shared masterdb Aurora. Auth is **JWT (HS256) + bcrypt**, *not* Cognito. 5-stage job lifecycle (`overview → job_prep → schedule → in_progress → closeout`) plus a manual `wf_status` approval field. CloudFront `d2cy304t1txdpd.cloudfront.net`, API GW `1uejx95wwf.execute-api.us-east-2.amazonaws.com`, account 980921733684. Deploy is **manual** (re-zip whole Lambda + SAM CLI; `aws s3 sync` + CloudFront invalidation). **Alembic now exists** (2026-06-17, branch `feat/alembic-baseline`, unmerged — supersedes older "Alembic pending" handoff text). Known gap: closeout 7-item checklist is **frontend-only state, never persisted**. Local dev defaults to **SQLite** when `DATABASE_URL` is unset. Its handoff doc is stale vs git (was 37 commits behind origin on 2026-06-17 — trust git log).
- **Quote Portal (QP)** — sales portal + customer portal, ~95% of the overall Gunner system by surface. **Backend = Node.js 22 Lambdas** in `GunnerRoofing/portal-backend` (~128 functions, `.mjs` ESM on `pg`) — *correcting* an earlier handoff doc that called it FastAPI/Python. Frontend `sales-portal-frontend` ~64k lines plain JS, Bootstrap 5, Google SSO. Customer portal `gunner-qp-customer-portal` is TS + Tailwind v4, magic-link auth; both portals are Next.js 16 App Router over the shared backend. Cognito User Pool `us-east-2_sEOcsFA76` enforced at API Gateway. Aurora cluster `dev-gunner-aurorapgdb-db-cluster` (distinct from masterdb). Lifecycle Lead (HubSpot) → Measure (GAF + Hover) → Price (Lambda) → Proposal → Contract (DocuSign) → Payment (Stripe) → Ready to Build. JSON-driven `ux_json` form engine. MVP ~99% on staging as of May 2026; north-star is White-Label/QP-as-SaaS. Carries known security sharp edges (committed `.env.*`, `NEXT_PUBLIC_`-prefixed secrets, an OAuth-callback credential echo, and a NY Stripe-routing bug) — detail belongs in a QP note, flagged under Open questions.

## Knowledge-vault ingest pipeline (as of 2026-06-21)

Colin's personal vault `claude-obsidian` holds ~250 LLM-Wiki notes; `wiki/wl-companycam/` last had a structured ingest 2026-05-21, and `wiki/chats/` holds 137 raw chat-catalog files. A multi-phase pipeline folds **276 Codex + Claude Code sessions (~626 MB)** into the vault: digest (compact, secret-redacted markdown) → extract nuggets per session → synthesize into topic notes → update catalog/index/hot → lint/cleanup. Codex transcripts are JSONL `response_item` lines (strip base64 images); Claude Code transcripts keep user/assistant text, skip thinking/tool_use. Auto-sync plan: a Claude Code session-end hook drops the raw transcript into the vault, then a nightly job distills it via the save / wiki-ingest skills. Target is this personal vault, **not** the shared `gunner-brain` (kept curated due to org confidentiality). Secret-redaction is mandatory for anything bound for `gunner-brain`.

## Stale-doc warnings

- `tickets/QA-CHECKLIST.md` still describes the old sidebar layout, not the current My Day / floating-chrome shell — update it when touching nav/shell; don't treat it as product truth. See [[colin/my-day]], [[colin/gotchas]].
- External handoff docs calling the hosting "SST v3" are wrong (it's v4).
- The gunner-ops developer handoff doc is stale vs git (local was 37 commits behind origin on 2026-06-17) — trust git log over its Tech-Debt/Pending sections; its architecture/conventions sections remain accurate.

## Open questions / TODOs (as of 2026-06-21)

Cross-system items that touch or surround GunnerCam. Deep ownership lives in the per-system notes.

- **GunnerCam:** reconcile the office-list ambiguity (Eric's "New York" vs Doug's "Stamford"); execute the manager-web-view → ops-portal merge once the ops portal is ready (build portably meanwhile).
- **gunner-ops:** whether to consolidate onto the shared masterdb cluster (per-app schema via RDS Proxy — "integration #2 candidate," open for Leonard, see [[colin/masterdb-sync]]); whether `wf_status` is eventually QP-driven (flagged for Leo); persist the closeout 7-item checklist to the DB; merge `feat/alembic-baseline` (its `0003` Integer→UUID migration is destructive against the shared dev DB — sequence carefully); install the SAM CLI on the dev machine to enable backend deploys.
- **QP:** fix NY Stripe routing (no NY case + PA key copied into the NY slot) and the committed / `NEXT_PUBLIC_`-prefixed credential leaks.
- **Shared infra:** confirm the owner of the second Aurora cluster `dev-gunner-aurorapgdb-db-cluster` (Leonard). The 2026-05-20 ADR target (all apps share one RDS instance, own schema via RDS Proxy) does **not** match deployed reality — gunner-ops satisfies isolation only by accident (separate instance + VPC). See [[colin/aws-infra]], [[colin/masterdb-sync]].

## Where to read more

- [[colin/mvp-roadmap]] for the build plan
- [[colin/decisions]] for locked rules + open calls
- [[colin/data-model]] for schema highlights
- [[colin/feature-inventory]] for the full feature catalog
- [[colin/people-and-context]] for the people, the five-system ecosystem map, and how to read an ask
- [[colin/risks]] for what can break it
