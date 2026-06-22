---
type: reference
owner: colin
app: GunnerCam
created: 2026-06-21
updated: 2026-06-21
tags: [wl-companycam, monday, integration]
status: active
---

# Monday.com Integration

GunnerCam treats Monday as a **read-only conduit** in the near term: Make.com owns all live Monday↔Stripe↔job sync, and Doug Kilzer's rule (stated 2026-06-01, reaffirmed 2026-06-04) is that no new GunnerCam code creates new Monday records. GunnerCam reads jobs/invoices from Monday and performs only two narrow, best-effort writes (a Stage flip on COC signing and a change-order note) — status/note updates on existing items, not new-record creation. For the Stripe/Make side of the picture see [[colin/stripe-make]]; for permit-fee flow see [[colin/permits]].

## Integration posture (as of 2026-06-21)

- **Inbound (Monday → GunnerCam):** job + PM + contract-value sync. Two paths share one core.
- **Outbound (GunnerCam → Monday):** COC Stage flip + CO note only — status/note updates on existing items, never new records.
- **Payments read:** the Payments tab reads invoices from the Invoicing board via GraphQL; Stripe is out of the read path (see [[colin/stripe-make]]).
- Locked rules live in [[colin/decisions]]; this note carries the integration detail.

## Boards, columns & IDs

Gunner Operations Journey workspace `12757194`. Code hardcodes these IDs (the MCP connector is unreliable — see [[colin/gotchas]]).

| Board | ID | Role |
|---|---|---|
| Project Take Off | `18346327856` | Master/source-of-truth for scheduled/active jobs; primary trigger |
| Invoicing 💰 | `18390982177` | Authoritative per-job invoice store; one parent item per job |
| Invoicing subitems | `18390982283` | One sub-item per payment milestone (~1,205–1,238 items) |
| Permitting & Warranties | `18346376757` | Permit tracking (322 items) |
| PM Change Order | `18310339669` | Make watcher inactive |
| Sales Change Order | `18398477514` | Make watcher active (scenario `4050964`) |

**Take Off columns:**

| Column id | Meaning |
|---|---|
| `color_mkyg7189` | Stage status (label "Scheduled" = id 10; lifecycle: Prep, New – Needs Review, In Review, Scheduling, Measurements Needed, Escalation, Active, Complete, Project Close Out, On Hold, Cancelled) |
| `pulse_id_mkxcr73a` | job_id |
| `email_mkxcr9gj` | email |
| `location_mkxcd73c` | location |
| `color_mkxcqnpn` | region/State (CT/NY/NJ/OH/Nationwide — broader than ticket's "CT/NY", so region is stored as free text and never validated) |
| `timerange_mkxcc45j` | install date |
| `multiple_person_mkxcgn7t` | PM people-column (returns null in Make's sample → person must be resolved to email before POST) |
| `numeric_mkxckbn3` | Original contract Value |
| `numeric_mm07xwa0` | Final Value (incl. change orders) |
| `board_relation_mm0zsct6` | Take Off → Invoicing link → becomes `invoicing_monday_id` in GunnerCam |

**Invoicing:** HubSpot ID `text_mkzw69rg`; Permits & Fees write target `numeric_mkyac1s7`.
**Invoicing subitems:** Amount Due / Amount Paid / Status (Invoice Sent / Paid / Payment Failed) / Payment Due Date / Date Paid; hosted Stripe invoice URL in `link_mkzm3afw`. Column `text_mkzsa0e5` (intended Stripe `in_…` id) was **deleted from the board**, so the Stripe invoice id is not persisted in Monday.
**Permitting:** Permit Fee `numeric_mkxejf8w`; HubSpot ID `text_mkyasprd`; Take Off relation `board_relation_mkxen73g` (100% populated).

**Join caveat:** Permitting stores `GUN-XXXXX` strings in `text_mm121etd`; Invoicing stores raw numeric pulse IDs in `text_mm12a68m` — incompatible. The correct join is the shared Take Off `board_relation` (`board_relation_mkxen73g` on Permitting 322/322; `board_relation_mm0zrzy0` on Invoicing only 275/1238 ≈ 22%). HubSpot ID is the practical Make-accessible join key (≈21.6% of Invoicing rows).

## Inbound job sync (Monday → GunnerCam)

Two parallel paths share one core, `syncMondayJob()` in `src/lib/monday-job-sync.ts`:

1. **JSON endpoint** `POST /api/external/v1/projects` — originally called by Make scenario `3640307` ("project take off status change").
2. **Native Monday webhook** `POST /api/external/v1/monday-webhook?key=ccam_…` — built later to drop the Make/Axe dependency; deployed live on dev, registered on board `18346327856` watching Stage `color_mkyg7189`, **webhook id `589048260`** (branch `feat/monday-inbound-webhook`).

**Evolution note:** as of 2026-06-04 *no* Make scenario or Monday native automation actually POSTed to GunnerCam (a search of 70+ Make scenarios + 38 Monday automations found zero callouts to any gunnerroofing.com URL; the only CompanyCam↔Monday scenario `2400201` goes the opposite direction). The native webhook receiver is therefore the real inbound mechanism, superseding the assumed Make-driven path.

- Webhook handles Monday's **challenge handshake** on registration. Two-step read: the payload carries only pulseId/boardId/columnId, so the route calls `fetchTakeoffJob()` (GraphQL items query in `src/lib/monday.ts`) to read full columns and resolve the PM people-column to an email before upserting.
- **Upsert key:** `corporationId` + `external_ids->>'monday_id'` (via existing GIN index), **merging** `externalIds` rather than replacing (preserves e.g. `stripe_id`). Writes monday_id, job_id, hubspot_id, quote_portal_id, invoicing_monday_id, region. Every sync stamps `last_synced_at` and `sync_source='monday'`; `creator_type='integration'`.
- **Status mapping** (lenient — never rejects an unrecognized label): Scheduled→`scheduled`, Active→`progress`, Complete→`completed`, On Hold / To Be Rescheduled→`hold`, Cancelled→`lost`; unknown/omitted→`scheduled`. The pure mapper lives in `src/lib/monday-stage.ts` (extracted so it's testable without the `@/db` import chain that throws `DATABASE_URL is not set`).
- **Project-creation guard:** new projects are created only when the *raw* Monday Stage label is genuinely syncable (`isSyncableStage()` against the raw label), **not** the mapped status. A bug let every event through because `mapStageToStatus()` falls back to `scheduled`. Existing projects update on *any* stage change.
- **PM assignment:** `pmEmail` resolved via `findExternalUserByEmail`; users are never auto-created. Unresolved email → project upserted unassigned with `pmUnresolved:true`. Reassignment removes the old `project_users` PM row + notifies the old PM; new PM gets an "assignment" bell notification and a `project.assigned` webhook. All notifications best-effort (own try/catch).
- **Contract value sync (added 2026-06-15):** `fetchTakeoffJob` extended with the two value column ids; **Final Value preferred, Original Value fallback**, written tri-state so a blank Monday column never clears an existing DB value. The native stage-change webhook already calls `fetchTakeoffJob`, so no new Make scenario was needed; the Make path also accepts `finalValue` / `contractValueCents`. Feeds the forecast bar in [[colin/forward-reporting]].

### Inbound gotchas

- **Rain-day-extension fix (2026-06-12):** inbound re-syncs were silently erasing manually-extended end dates by overwriting with the board's base value; fixed by re-applying `base_end_date + rain_days` on top of whatever Monday sends.
- **Empty `invoicing_monday_id`:** if the Stage flip fires the webhook *before* the Take Off→Invoicing `board_relation_mm0zsct6` link is set, the project lands with an empty `invoicing_monday_id` and the Payments tab shows nothing (no fallback). Fix: toggle Stage off Scheduled and back to re-fire once the link is populated.

## Outbound writes (COC flip & CO note)

Both triggered by the DocuSign signing webhook at `src/app/api/signing/webhook/[vendor]/handler.ts`, detected by filename pattern:

| Trigger file | Function (`src/lib/monday.ts`) | Action |
|---|---|---|
| "Project Completion - YYYY-MM-DD.pdf" (Certificate of Completion) | `flipJobStatusToComplete()` (`:278`) | Flips Stage `color_mkyg7189` on board `18346327856` to **"Complete"** (`is_done=true`, so done-keyed Monday automations fire) + posts a note |
| "Change Order - YYYY-MM-DD.pdf" | `noteJobChangeOrderSigned()` (`:353`) | Posts a job-item update note only — **does not** flip the Stage (no Stage label maps to "CO executed"; flipping would regress the lifecycle) |

- **Dormant-safe by design:** both functions check for a missing Monday token and return the sentinel string `'dormant'` (never throw); each webhook arm has its own try/catch with log-don't-throw, so a Monday outage never surfaces as a signing error.
- **Build history:** `ee917c9` wired the COC→Monday flip; SST env added in `f31c258`; flip target **hardcoded** in `3ed6c41` because the full Monday env config would exceed the 4 KB Lambda env-var ceiling (superseding earlier `MONDAY_JOB_BOARD_ID` / `MONDAY_STAGE_COLUMN_ID` / `MONDAY_COMPLETION_LABEL` env vars). The CO note branch was missing until recovered from stash `f0e2fe3` and shipped as `noteJobChangeOrderSigned` in `20dcafa` (2026-06-03).
- **Make CO automation is fully parallel:** the Make "Sales Change Order Workflow" (`4050964`) fires on a *new item created on the Sales CO board* `18398477514`, reads the linked Take Off item for HubSpot ID (`text_mkxcv57m`) and Job ID (`pulse_id_mkxcr73a`), computes final = contract + CO, creates the CO invoice subitem on the Invoicing board, and updates the HubSpot deal amount. It does **not** call Stripe directly and does **not** listen for any GunnerCam Stage change. The parallel "PM Change Order Workflow" (`3965663`) is off. Detail in [[colin/stripe-make]].

## Payments / invoices (Monday-read path)

- The Payments tab + invoices GET route (`src/app/api/projects/[id]/invoices/route.ts`) read invoices from the 💰 Invoicing board (keyed on `invoicing_monday_id`) via the server-only `src/lib/monday.ts` GraphQL client — **Stripe is fully out of the read path**. The prior email-based Stripe lookup caused cross-customer bleed (one Stripe customer spans multiple jobs; equal-amount milestones are irresolvable).
- Each milestone row shows name, amount due, amount paid, colored status pill, due/paid dates, and a **View/Pay** link to the hosted Stripe URL (`link_mkzm3afw`). The old **Resend button was removed** — `sendInvoice` needs the `in_…` id, no longer persisted in Monday; the hosted link covers resend. Full suite (1002 tests) green after the rewrite; [[colin/decisions]] updated.
- Make scenario `3939700` ("Create invoice - All Stripe Accounts") writes the hosted URL to `link_mkzm3afw`; its attempted write to the now-deleted `text_mkzsa0e5` does not fail the run (~276 subitems carry a link).
- **My Day / analytics** read cached milestones in the `invoices_cache` table (Take Off → contract value; Invoicing + subitems → due/paid/status/dates) for past-due/open attention checks — no Monday/network calls at query time. See [[colin/my-day]].

## Auth, secrets & infra

- Monday API token is a **single Monday personal API token** (not OAuth), stored as SST secret `MondayApiToken` → SSM SecureString `/wl-companycam/<stage>/monday-api-token`, read at runtime by `src/lib/monday.ts` (mirrors the Stripe-key pattern). Not in `.env.local`. SST provisions the param, exposes the env var, and grants `ssm:GetParameter`. See [[colin/aws-infra]].
- **Set/rotate:** `sst secret set MondayApiToken <value> --stage <stage>` then `sst deploy` (a deploy is required to push the value into the live SSM param). When absent, the param holds a placeholder and Monday functions return dormant / empty lists.
- **Dev token is set and active** (verified 2026-06-09; value never printed; SSM dev param last set 2026-06-01), so COC flip, CO note, and the Payments tab are **live on dev** once code is deployed — not dormant.
- The webhook auth key **rides in the URL** (`?key=ccam_…`) because Monday's native webhook action cannot set headers; `src/lib/external-auth.ts` validates the raw key via the same SHA-256 hash lookup as the bearer path, preserving tenant scoping. Treat the registered webhook URL as a secret. See [[colin/external-api-integration]].
- API-registered webhooks are **not visible in the Monday Automations UI panel** — list them via the Monday webhooks API for the board to verify.

## MCP / tooling caveats

- **Monday MCP OAuth tokens are session-only** — they do not persist between sessions and do not work in Lambda/cron; any automated sync must use the `MondayApiToken` SST/SSM path.
- The MCP connector was installed 2026-06-01 (Colin Wong, Gunner Roofing Enterprise, workspace `12757194`, Make org `4323426`) and initially read Take Off / Invoicing / Permitting directly.
- **Connector access regressed by 2026-06-15→06-21:** the connector (on `gunnerroofing-gang.monday.com`) can no longer see the hard-coded board IDs — only a "My Team" workspace of default template boards. The real Operations/Permitting boards exist but this connector's credentials lack visibility. **Treat MCP board access as unreliable; the code's hardcoded IDs are the source of truth.** Also in [[colin/gotchas]].

## Make-scenario specifics (Monday-adjacent)

These live in Make, not GunnerCam — full coverage in [[colin/stripe-make]] and [[colin/permits]]; summarized here for the Monday-column wiring.

- **Permitting Invoice workflow** (`4048920`, hook `1838538`): syncs Permit Fee `numeric_mkxejf8w` (Permitting) → Permits & Fees `numeric_mkyac1s7` (Invoicing), joined on HubSpot ID (`text_mkyasprd`→`text_mkzw69rg`); skips if fee empty, HubSpot ID missing, or match count ≠ 1. Step 1 of a two-step permit-fee→Stripe chain (step 2 = Stripe scenario `3939700`). Rebuilt linear from a broken Axe 2-route design and activated 2026-05-28; `maxErrors=3` auto-pause; working blueprint at `~/repos/make-backups/4048920_working_2026-05-28T13-52-30Z.json`.
- Scenarios `3640307` ("project take off status change") and `4295903` ("project take off hubspot id") historically handled job sync + ID mapping.
- **Make/Monday GraphQL gotchas:** Make's `ListItemsByColumnValuesV2` (`items_page_by_column_values`) does **not** support board_relation columns as a filter (`UnsupportedItemsByColumnValueQuery`) — drop to raw HTTP GraphQL `items_page` with `query_params.rules`. Make IML `linkedPulseId` yields a raw number, but Monday GraphQL `compareValue` must be a string — wrap in `toString()`. `scenarios_run` requires `isActive:true`. The blueprint validator and `validate_blueprint` disagree on top-level props, so a working scenario can stay `isinvalid:true` until opened+saved in the Make UI.

## Open questions / TODOs (as of 2026-06-21)

- **COC flip target label unconfirmed:** code hardcodes Stage→"Complete" (TODO at `src/lib/monday.ts:262`); ops (Eric / Eddie / Joe) must confirm whether it should be "Complete" or the intermediate "Project Close Out". One-word change either way; do not rely on it in prod until confirmed.
- **Analytics stage-coverage gap (unresolved):** `getForecastDashboard` (`src/lib/queries.ts`) scans only the local `projects` table, and `syncMondayJob` only lands projects whose Stage maps to scheduled/progress — so Monday intake stages upstream of Scheduled (Lead, Sold, New – Needs Review, Scheduling, Escalation, Measurements Needed, In Review) never reach analytics. These intake labels also hit the lenient `scheduled` fallback, making that bucket a catch-all. Whether analytics should query Monday directly is open. See [[colin/forward-reporting]].
- **Monday-sourced labels (product decision, not built):** project labels should come *from Monday*, replacing the manual in-app label system (`project_labels`, `label-presets.ts`, `labels-modal.tsx`, `labels-editor.tsx`, `/api/projects/[id]/labels`). As of 2026-06-15 the Monday label column contract (field IDs, color semantics, ordering, deletion behavior) is undefined; current sync maps stage/timeline/PM/region/job-id/invoicing-relation/contract-value but **no labels** — a data-contract change, not a UI rename.
- **MCP connector visibility:** restore connector access to the real Operations/Permitting boards, or accept code-hardcoded IDs as canonical.

## Recommended build order

The inbound sync is the keystone — it simultaneously unblocks Job ID display, PM assignment/notification, and the Payments tab (2026-05-31 / 2026-06-03):

0. Map the Take Off board.
1. Inbound Monday→GunnerCam job + PM sync.
2. Job ID surfacing / PM notifications / Stripe-invoice read / permit + photo inflow.
3. Outbound Monday pings + change-order auto-billing.

CompanyCam historical import and task-template restore run as parallel independent tracks.
