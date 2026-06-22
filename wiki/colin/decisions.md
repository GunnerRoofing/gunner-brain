---
type: decision
owner: colin
app: GunnerCam
created: 2026-05-07
updated: 2026-06-21
tags: [wl-companycam, decisions, architecture, auth, docusign, workflow]
status: active
---

# Decisions

Source: `~/repos/WL-CompanyCam/DECISIONS.md`. This note tracks **locked rules + open/contested decisions only** — link out to deep topic notes for detail.

## Product context

Endgame is SaaS — Gunner is tenant #1, target is white-label resale to 50+ roofers. Every architectural choice is evaluated against "scales to 50+ tenants without a rewrite."

Implications:
- Multi-tenancy non-negotiable. Isolation via `corporation_id` was designed into every domain row from the **first migration** (not retrofitted), so white-labeling a second roofing company needs no schema rebuild.
- Hosting and DB sizing should be **pay-per-use** — no large idle costs before customers sign.
- White-label friendly: branding, custom domains, per-tenant Stripe / DocuSign / Google Business.
- SOC 2 in 12–18 months — don't certify yet; don't preclude (audit log, encryption, access control foundations).

> **Note (2026-05-29 standup):** Custom white-label app development is **halted** in favor of Tyler's iOS app (meets current requirements). Long-term white-labeling is deprioritized in favor of a live proof of concept. The schema still supports it; the build effort is paused. See [[colin/people-and-context]].

## Locked stack

| Layer | Choice | Why |
|---|---|---|
| Framework | Next.js 16.2.4 App Router | UI + API in one codebase; consult `node_modules/next/dist/docs/` per `AGENTS.md` |
| UI | React 19.2.4 + Tailwind v4 + shadcn/ui + `@base-ui/react` | shadcn copied into repo, not imported |
| Auth | AWS Cognito (`aws-amplify` + UI react) | Username login (matches Quote Portal). 50k MAU free. |
| ORM | Drizzle | Schema as code, versioned SQL |
| DB | Postgres 16+ | Required for generated columns + modern indexing |
| Driver | postgres.js | |
| Storage | S3 + CloudFront | DB stores keys + variant URIs, never blobs |
| Mobile | PWA (web manager view) + Tyler's iOS app (PMs/crew) | See note below on the manager view's role |
| Signing | DocuSign (sandbox as of 2026-06-21) | Migrated off PandaDoc; one account per corp. See [DocuSign / change-order signing](#docusign--change-order-signing) |
| Payments | Stripe Connect | One Connect account per corp; we don't keep a payments ledger |

## Architecture rules (non-negotiable)

Spelled out in [[colin/overview]]. Summary: multi-tenant column on every domain table · polymorphic creator (`creator_id` + `creator_type`) · project as spine · `bucket_day` generated column · JSONB external_ids · soft-delete only (`deleted_at`) · single permission resolver (`src/lib/dal.ts`) · S3 keys not bytes · `captured_at` ≠ `created_at` · `modified_since` on every list endpoint · sentinel-message `Error` objects via `errorToResponse`.

## Role hierarchy & access tiers

> ⚠️ **Contested area — needs a fresh DECISIONS.md ruling before further code.** The locked single-tier model (T-10) conflicts with the 2026-05-29 standup's three-tier request; the 2026-06-03 `company_admin` implementation only partly resolved it. See [Open decisions](#open-decisions).

Canonical role enum (as of 2026-06-21): `super_admin | manager | pm | standard | restricted`, plus the newly added **`company_admin`** tier (see below).

| Decision | Status | Detail |
|---|---|---|
| T-10 retired `admin`; `requireAdmin` hard-renamed `requireManager` | **Locked** | `requireManager` accepts `manager` + `super_admin`; `/admin/*` gated by it |
| T-10 single company-wide `manager` | **Locked, then contested** | `manager` is the single corp-wide role with corp-wide project visibility (DECISIONS.md:421); `manager_assignments` is org-chart metadata only and does **not** filter visibility |
| 2026-05-29 standup three-tier request | **Contested / unratified** | Company Admin (company-wide) > office-scoped Manager (sees only their office/assigned PMs) > User/PM. Raised by Eric Recchia / Doug Kilzer (office-scoping). Auth-critical, L-effort. **Conflicts with locked T-10.** |
| 2026-06-03 `company_admin` tier | **Partially implemented** | New tier above `manager`, below `super_admin` — corp-scoped (not cross-tenant), full company-wide visibility; can remove a manager from `project_users` and mint/manage other company_admins. Migration 0020 adds the enum value via `ALTER TYPE ... ADD VALUE`, applied with `db:migrate-safe` (non-transactional). Added `isCompanyAdminPrincipal` guard + `requireCompanyAdmin` in `dal.ts`. **Adds the top tier but does NOT office-scope managers**, so it only partly satisfies the standup ask. |

**Open bug (2026-06-15, P0):** `company_admin` visibility is inconsistent — `dal.ts` (`requireManager` logic ~line 353) grants corp-wide access, but `listProjectsForPrincipal` (`src/lib/queries.ts` ~line 392) only gives that breadth to `super_admin` and `manager`, so company_admins see only explicitly assigned projects. Breaks My Day / dashboard oversight. See [[colin/gotchas]] and [[colin/my-day]].

## Task assignment & permissions

- **Manager-to-manager (peer) task assignment is intentionally allowed.** The prior "strictly below" rule was a bug. Both `canAssignBetween` (`src/lib/role-hierarchy.ts`, client) and `canAssignTo` (`src/lib/dal.ts`, server) were changed; manager→super_admin remains blocked. DECISIONS.md updated 2026-05-26. **Both files must be updated together** when assignment policy changes.
- **Install-timeline date editing** (`installStartDate` / `installEndDate`) is **manager/super_admin only**; PMs blocked at both API and UI. New `isManagerPrincipal` predicate in `dal.ts`; `PATCH /api/projects/[id]` rejects non-manager date changes; `install-timeline-card.tsx` renders read-only fields for PMs (gated by `canEditTimeline` prop). `InstallTimelineCard` is shown to PMs-and-above on the detail page (`{isPmOrPrivileged && ...}` in `project-detail.tsx`); the listing-column `InstallCell` stays read-only-visible to all roles. (Part of the T-11/T-12 PM-scope cleanup.)
- **Identity fields are Cognito-owned, manager-controlled** — email/username changes are NOT allowed via self-service settings (deliberate V1 non-goal). Notification-preference system deferred (Decision T-14).

## Phase / workflow model

- **Canonical user-facing phases are three: Project Start, In Progress, Close Out.** Pre-Install was struck from the template (2026-06-10).
- DB-level there are still **four** phase enum values (`pre_install`, `project_start`, `in_progress`, `close_out`); the template materializes only three and `pre_install` rows are **filtered/pruned at read time** (My Day + whiteboard). Intentional product decision, not a bug.
- A 2026-06-10 cleanup script soft-deleted the stale Pre-Install phase from 22 existing dev projects and renumbered phases; **task items inside the three remaining phases are not yet updated** (Eddie Prchal's doc sheet pending).
- **Phase/workflow templates are NOT forked per-PM** on multi-PM jobs — ownership split lives on individual tasks only. Keeps Tyler's iOS phase contract untouched regardless of PM count (decided 2026-06-11 walkthrough w/ Eric Recchia, Eddie Prchal, Tyler Suffern). See [[colin/external-api-integration]].
- **Task "sets/bundles/templates" do not currently exist** — the `task_templates`/bundle feature was built (commit 7059760) then deleted, leaving **orphaned schema tables**; it needs **restoring, not rebuilding**. Tasks live in GunnerCam's DB and are pulled by Tyler's iOS app via an external GET endpoint.

## Standup-locked product/integration decisions (2026-05-29)

See [[colin/people-and-context]] for the people behind these, [[colin/monday-integration]] and [[colin/stripe-make]] for the integration mechanics.

- **Monday is the immediate task-management conduit** (task management integrated into GunnerCam near-term), with planned migration to a future **Ops Portal**.
- **No centralized customer-data DB** — explicitly deferred; data is pushed between apps (Quote Portal, HubSpot, Monday, GunnerCam) via **Make automation** rather than a canonical store.
- **Universal Job ID** originates in **Quote Portal** (assigned at the "Ready to Build" stage), flows through HubSpot, Monday, and GunnerCam. GunnerCam stores it in `external_ids.job_id` (GIN-indexed) and surfaces it in the project list + detail header (display/search confirmed wired).
- Projects auto-create in Quote Portal on lead generation / new HubSpot deal; **only active and scheduled projects** from Project Takeoff are imported; customer comms reuse the existing customer-portal infrastructure.
- **Custom white-label app development halted** in favor of Tyler's app. Repair-button in Quote Portal deferred. India launch proceeds with remediate-as-needed.
- **Offline mode unresolved and explicitly deferred** — "NEEDS FURTHER DISCUSSION"; only checklist notes exist, no implementation (audited 2026-06-02).
- The **GunnerCam web manager view** is intended to become a "daily snapshot of jobs running" bolted onto the ops portal (Eddie Prchal), not a standalone CompanyCam-like system — PMs use mobile; web view is primarily for Joe (ops director). Standalone status is temporary.
- **Recommended implementation order (2026-05-31):** Phase 0 map Monday data model → Phase 1 inbound Monday→GunnerCam sync (jobs + PM) → Phase 2 Job ID surfacing, PM notifications, Stripe link, photo/permit inflow → Phase 3 outbound Monday notifications + ST-5 auto-invoice on change-order-signed. Dictated by data dependency: the (already-built) Stripe Payments tab shows nothing until a project has a `stripe_id`, which flows down the Monday-sync pipe.

## DocuSign / change-order signing

Migrated off PandaDoc. Deep mechanics in [[colin/gotchas]] and [[colin/stripe-make]].

- **Runs in sandbox** as of 2026-06-21 — JWT auth fully configured (integration key, user, account id, RSA private key via SST secret, webhook base named, `EnableSigning=true`), but the API base points at `demo.docusign.net`. **Going live needs a DocuSign go-live promotion.**
- **Two distinct change-order flows:** (1) older homeowner **DocuSign** signing path (creates an envelope for homeowner signature); (2) newer **document-template** path where the homeowner signs on paper (no envelope).
- **Two distinct CO PDF code paths** — patches to one don't affect the other:
  - `src/lib/document-templates/change-order.ts` — overlays form data onto `assets/change-order.pdf` (the "Get Signature → CO template" flow)
  - `src/lib/change-order-pdf.ts` — pdf-lib generator for the now-deprecated "Add Change Order" modal
- **CO homeowner "please sign" emails are sent by DocuSign's own infra**, not GunnerCam SES. Blank `SES_FROM_EMAIL` only silences post-signature notification emails, not the DocuSign invitation.
- **COC completion** fires via the signing webhook handler (`handler.ts` ~line 137); manager-in-app-signed COs are finalized at create time in `change-orders/route.ts` and `documents/route.ts`. **All are correct hook points for outbound Make/Monday events — none emitted as of the 2026-06-04 audit.** COC detection is by filename → triggers the Monday flip.
- `anchorIgnoreIfNotPresent` should be `true` (set in `src/lib/signing/providers/docusign.ts:136`, flipped from `false` 2026-06-15) so a PDF missing the anchor falls back to a default-placed signature tab instead of a hard 500 from the send route.
- DocuSign demo `createRecipientView` can mint a direct signing URL bypassing email (short-lived ~5 min, must match current recipient); flagged as a future admin-only "Copy signing link" feature.

## Other locked product decisions

- **Dictation is client-only** (Web Speech API); AWS Transcribe explicitly deferred as a future accuracy/offline upgrade. Dictation (speech-to-text) is separate from the stale `voice_note` recording entry (left untouched); audio recording rides the existing file-upload path. Locked in DECISIONS.md.
- **V1 notifications are in-app only** (no email/push), 60s polling on bell open, fan out to **ALL** project assignees (not @-mention only), covering assignment + comment + status events incl. crew members. Email channel → V2 (needs SES); real-time push → V2 (needs WebSockets/SSE). The `notifications` table uses polymorphic recipient (`recipient_id` + `recipient_type`). Decided 2026-05-28.
- **Subcontractor (crew) reviews (T-16):** one review per user per crew per job, enforced by a partial unique index + `409` in the POST route; corp-scoped averages aggregate all non-deleted reviews for a crew within the corporation. Distinct from `review_requested` / Google reviews.
- **Daily log (T-11):** one per project per day (partial unique index), `log_date` set server-side from `corporations.timezone` (not client clock), `409` on duplicate, notes required only for at-risk/late health. Filable by any corp user with project read access (`requireUser` + `assertCanReadProject`); crew excluded. Past-end jobs with no logs stay `complete`, not `?`. The daily-log form opens **in-place (not a modal)** post-cleanup.
- **Install-complete jobs are exempt** from the "No activity for N days" red-flag check (computed in `queries.ts` / `view-models.ts`, locked in DECISIONS.md). Money signals (unpaid invoice, unsigned change order) still override and push them to Action Needed.
- **PM-scope cleanup (T-11/T-12 feedback)** removed the "Apply template" button (`apply-template-button.tsx` deleted), moved the daily-log form in-place, and made the install timeline manager-only to edit.

## Notable gotchas affecting decisions

Full catalogue in [[colin/gotchas]]. Decision-relevant ones:

- **DocuSign anchor text rendered at font size 1** (below DocuSign's ~3–4pt text-extraction threshold) → `ANCHOR_TAB_STRING_NOT_FOUND` (400). Fixed by bumping size to **6** in the shared helper (`overlay.ts:165 stampDocuSignAnchor` — fixes both Change Order and Project Completion templates); anchor stays visually invisible (near-white `rgb 0.96,0.96,0.96`). Byte-scanning unit tests passed because they don't invoke DocuSign's parser.
- **DocuSign *demo* silently suppresses email** when content contains TEST/Testing tokens, fake addresses, gibberish (anti-abuse spam filter) — recipient sees a "flagged as spam" banner on the direct link; audit log still says "Sent Invitations." Real-named projects and the production account are unaffected. A repeatedly corrected/resent/recipient-changed demo envelope can also silently stop delivering — **void and recreate; don't reuse one envelope across CO QA.**
- **CO signer name defaults from the homeowner/customer field**, which for test projects is the project label (e.g. "WL TEST — 123 Test Lane (Testing)"), producing a non-human signer; the modal allows overriding before send.
- **CSS var `--text-strong` is referenced in 8 `globals.css` rules but never defined** → silent fallback to inherited color, so the Workflow tab has no strong-text emphasis tier (repo-wide grep confirmed 2026-06-15).

## Schema conventions

- PKs: `UUID DEFAULT gen_random_uuid()`
- Timestamps: `TIMESTAMPTZ NOT NULL DEFAULT now()`
- Soft-delete: `deleted_at TIMESTAMPTZ` (nullable)
- Postgres `CREATE TYPE` enums for stable closed sets (cheap to extend with `ALTER TYPE ... ADD VALUE`; non-transactional adds use `db:migrate-safe`)
- JSONB for: `address`, `geofence`, `external_ids`, `branding`, `raw_payload`
- snake_case columns + tables, plural tables
- FKs always declared, default `ON DELETE RESTRICT` unless cascade is intentional

See [[colin/data-model]].

## Auth specifics

- Cognito User Pool, username sign-in (not email-as-username); usernames must match Quote Portal username
- On first sign-in: upsert `users` row keyed by Cognito `sub`, plus `corporation_id`, `office_id`, `role`, manager link
- JWT claims include `corporation_id` and `role` via Cognito Pre-Token Generation Lambda — server actions can scope queries without DB hit
- **Crew members are in a separate Cognito User Pool** with a different app client. They live in `crew_members`, NOT `users`.

See [[colin/google-sso]] for the Cognito/Google SSO status.

## SaaS-readiness (build-later, design-now)

- Custom domains per tenant — CloudFront + ACM, `corporations.custom_domain`
- SOC 2 foundations — RDS/S3 encryption (default ON), CloudTrail, `audit_events` table populated by triggers (not app code), Secrets Manager for all secrets
- Tenant billing — Stripe Billing on top of Stripe Connect, `corporations.stripe_subscription_id` + `subscription_status` enum
- Tenant onboarding — `/admin/onboard` flow, manual via internal admin in V1
- Per-tenant feature flags — `corporations.features JSONB`, read in middleware
- Data export — "Export all my data" zip endpoint (build when first asked)
- Tenant resource limits — per-corp rate limits, photo quotas, Postgres `statement_timeout` (build before tenant #5)

## Timezone

UTC for all `TIMESTAMPTZ`. Day-bucket grouping uses `America/New_York` (Gunner is east-coast), stored as generated column on `updates`. White-label corps in other zones get `corporations.timezone` and the column adapts (V2). Daily-log `log_date` already derives from `corporations.timezone`.

## Open decisions

| # | Decision | Blocks | Notes |
|---|---|---|---|
| **role-tier** | **Resolve the role-tier conflict in DECISIONS.md** | All further auth code | 2026-05-29 three-tier model (Company Admin company-wide > office-scoped Manager > User/PM) contradicts locked T-10 (manager = single company-wide role). The 2026-06-03 `company_admin` added the top tier but did NOT office-scope managers — conflict only partly resolved. **Auth-critical, L-effort.** |
| **company-admin-bug** | **Fix P0 `company_admin` visibility bug** | My Day / dashboard oversight | Align `listProjectsForPrincipal` (`queries.ts` ~392) with `dal.ts` (~353) so company_admins get corp-wide breadth. |
| **whiteboard-events** | **Owner for the whiteboard's durable event model** | Rain-day timeline extension, missed-step escalation | Integration ownership is split (GunnerCam reads phase state, Tyler's API owns phase writes, Monday owns job/invoice cache); no cross-system event bus or change log exists. |
| **outbound-events** | **Wire outbound Make/Monday events** | CO/Monday automation | None emitted from the COC webhook handler or manager-signed CO finalize paths as of 2026-06-04. |
| **task-items** | **Update task items** inside the three remaining phases | Workflow content correctness | Per Eddie Prchal's pending doc sheet (after Pre-Install removal). |
| **task-templates** | **Restore deleted task templates/bundles** | Bundle feature | Orphaned schema from commit 7059760. |
| **offline** | **Define an offline-mode strategy** | Mobile reliability | Still unresolved; only checklist notes exist. |
| **signing-link** | Consider admin-only "Copy signing link" feature | QA / email fallback | Via DocuSign `createRecipientView`. |
| **docusign-golive** | **DocuSign go-live promotion** | Production signing | Move off `demo.docusign.net` sandbox. |
| 1 | Postgres host: Aurora Serverless v2 vs RDS Postgres | First migration | RDS in dev; Aurora is the DECISIONS.md recommendation |
| 2 | Next.js hosting: Amplify vs OpenNext/Lambda vs ECS | First deploy | **OpenNext via SST** in dev. Recommendation: Amplify → OpenNext → ECS fallback |
| 3 | Infra-as-code: Terraform vs AWS CDK | First infra commit | SST (Pulumi-based) in use today — partially answered |
| 4 | S3 layout: single bucket `{corp_id}/...` prefix vs bucket-per-corp | Photo pipeline | One shared bucket today (`wl-companycam-dev-cw`) |
| 5 | ~~PandaDoc: shared corp account vs per white-label~~ | — | **Superseded** — moved to DocuSign (one account per corp, sandbox as of 2026-06-21) |
| 6 | Stripe Connect: Standard vs Express | TICKET-10 | |
| 7 | Cognito strategy: one pool with claims vs pool-per-corp | TICKET-12 | |
| 8 | Crew member auth: separate Cognito app / org type / custom credentials | TICKET-7 | DECISIONS.md commits to "separate User Pool" |

## Explicitly out of V1

Voice notes UI · phase-aware checklists (partially landed via daily log) · geofence GPS auto-association · webhook push to Quote Portal/Tyler's · full-text search · realtime/WebSockets · SOC 2/CMMC · crew-payments view · native mobile (Tyler's app fills this) · global photo feed/map/reports · email/push notifications (V2) · AWS Transcribe dictation · offline mode (deferred, unresolved).
