---
type: reference
owner: colin
app: GunnerCam
created: 2026-06-21
updated: 2026-06-21
tags: [wl-companycam, permits, connecticut, automation]
status: active
---

# Connecticut Permit Automation

Two distinct efforts share the word "permit". Keep them separate:

| Effort | What it is | Lives in |
|---|---|---|
| **`permit-poc`** | Standalone config-driven Node app that assembles permit filing packets for CT towns. Packet-based — it does NOT auto-submit into portals. | `~/repos/permit-poc` (own git repo) |
| **GunnerCam permit tracker** | A frontend-only in-app permitting *view* scaffolded in WL-CompanyCam. Status tracker, no backend. | `src/components/permits-view.tsx` |

The first is a research/demo prototype; the second is product scaffolding. They do not share code.

## `permit-poc` — the standalone app

### Architecture & deployment

- Lives at `~/repos/permit-poc`, a config-driven multi-file Node project. Extracted to a standalone git repo on 2026-06-21 (initial commit `ade28bb`). Previously nested as `permit-poc/` inside WL-CompanyCam; those 23 tracked files were `git rm`'d from WL-CompanyCam (staged, pending a manual `git commit -m 'Remove permit-poc (moved to standalone repo)'` as of session end).
- A stale leftover at `~/Claude/Projects/Ops Portal/permit-demo/` (single self-contained `index.html`, pdf-lib via CDN, browser-only) is unrelated to the real project and safe to delete.

| File | Role |
|---|---|
| `src/locations.mjs` | Shared jurisdiction router — single source of truth |
| `src/fill.mjs` | Shared fill engine / packet generator |
| `config/<town>.json` | Per-town config (route, fields, docs, links, manual steps, proof.com triggers) |
| `forms/*.pdf` | Official town PDFs |
| `demo/index.html` | Deployed static UI |
| `src/paths.mjs` | Lambda-safe output path → `/tmp` |
| `run.mjs` / `serve.mjs` / `validate.mjs` | CLI / API server / validator entrypoints |

- **Every** entrypoint (CLI, API server, validator, browser demo) calls `src/locations.mjs` before any PDF work. The router returns one of four statuses: `ready`, `in_progress`, `permit_not_necessary`, `outside_nyc_ct_nj`.
- Local run: `npm run demo` → `localhost:4173`. QA: `npm run validate` and `npm run permit`.
- Deployed as an unauthenticated AWS Lambda Function URL: `permit-poc-live`, `us-east-1`, `nodejs22.x`, URL `https://o5hl76h4sh2xnxoocx7qx2keg40tojzt.lambda-url.us-east-1.on.aws/`. ZIP artifact uploaded via AWS CLI; `/tmp` used for runtime PDF output. (Note: this is a separate `us-east-1` POC footprint — the main app's AWS account is `us-east-2`, see [[colin/aws-infra]].)
- A separate live S3 demo site at `gunner-permit-demo-2026.s3-website-us-east-1.amazonaws.com` (root is a 188-byte redirect stub → `/demo/index.html`). **As of 2026-06-21 it still serves an OLDER build that recreates the form**; the newer 291 KB build (official `TOGPermitAPP.pdf` embedded as base64, fills ~20 AcroForm fields) never finished uploading — AWS SSO session expired mid-upload.

> The app is **packet-based**: it assembles required documents, fields, and step-by-step portal instructions for a human to submit. Portal towns get *draft instructions*, not live API calls.

### Coverage & status

- Covers **15 Connecticut towns**, each with a packet-based config. Original four: Greenwich, Norwalk, Stamford, Darien. Added later: New Canaan, Westport, Fairfield, Bridgeport, New Haven, Hartford, West Hartford, Danbury, Ridgefield, Hamden, Cheshire.
- **Status conflict resolved by date:** earlier (2026-06-18) only Greenwich was `ready`, all others `in_progress`. By 2026-06-21 all 15 CT towns validated as `ready` in agent test runs — Greenwich and Norwalk generate email packages; the other 13 generate portal filing packets. Verify which build is canonical (see open questions). NJ and NYC entries exist but remain `in_progress` and do not generate packages.
- CT addresses outside the checklist → `permit_not_necessary`. Addresses outside NYC/CT/NJ → `outside_nyc_ct_nj`. Router originally cited 35 target locations across CT/NJ/NYC.
- Reference: `~/repos/permit-poc/docs/connecticut-permit-routes.md` captures email vs portal vs proof.com split for all 15 towns with official source links.
- **Completeness (2026-06-21):** ~35% as a standalone demo, ~8% toward the full tri-state hands-off automation vision. Genuinely working: Greenwich PDF form fill. Not built: data pipe-in from CompanyCam/contract, e-signature, Proof.com notarization, COI attachment, programmatic email send (only a `mailto:` shim), portal/RPA submission, inbox reply parsing, permit state machine, multi-town write-back to Ops.

### Filing routes

CT filing collapses into three routes:

| Route | Towns |
|---|---|
| Email-only | Norwalk |
| Email + notarization (proof.com) | Greenwich |
| Portal submission | The remaining 13 |

Portal vendors:

| Vendor | Towns |
|---|---|
| OpenGov (ViewpointCloud) | Stamford, Darien, New Canaan, Ridgefield |
| Accela | Westport, Hartford |
| CitySquared | Fairfield, New Haven |
| ViewPoint | Danbury, Hamden |
| CityView | West Hartford |
| Park City (EnerGov self-service) | Bridgeport |

Per-town work is largely **configuration, not new code**: CGS 29-263 mandates one standardized application form statewide and ~65 CT towns share the OpenGov/ViewPoint portal, so the full state collapses to ~4–6 integration types (not 169).

### Per-town rules

- **Greenwich** — email to `bldgpermitapplications@greenwichct.org` for re-roof/re-side/replacement-windows on 1-2 family dwellings only (all else in-person). Requires exactly two docs: *Additions and Alterations Permit Application* + *Workers' Compensation Coverage Affidavit* (Revised 02/2026). Always requires a notarized package via proof.com first. Town sends a credit-card invoice after review; permit returns by email. Bundled `forms/additions_alterations.pdf` and `forms/workers_comp.pdf` are byte-for-byte matches of current official PDFs. The WC affidavit contractor line fills from `signers.permitHolderName` (e.g. Andrew Prchal), **not** the company name.
- **Norwalk** — email-only to Peter Kelly (`pkelly@norwalkct.gov`) via a dedicated Roofing/Windows/Siding PDF; no notary. Dual-track: building permits by email, but zoning-required work needs 3 hard-copy plan sets dropped/mailed to Planning & Zoning Room 129. Closest to implementation-ready after Greenwich.
- **Stamford** — OpenGov (`stamfordct.portal.opengov.com`, category 1083, `recordTypeID=6454`). Re-roof/re-side/replacement windows/doors = Minor Alteration. Two-family homes require a licensed CT HIC; single-family owner-occupants have a homeowner exemption, LLC/corporate owners do not. Public no-auth REST API: `api-east.viewpointcloud.com/v2/stamfordct`. Roofing affidavit at closeout; COI/Workers Comp section (WC forms 7B/7C). Window size changes / structural work / dormers / skylights / reconfigured openings escalate beyond Minor Alteration; pre-1978 buildings trigger an RRP (lead) review. Direct PDF downloads blocked by Akamai CDN — links saved in `forms/stamford/README.md`.
- **Darien** — OpenGov/ViewPoint (`darienct.portal.opengov.com`), Building Dept category 1084, Building Permit record type 6444 (covers Building + Zoning). Permit for re-roof/re-side **only when new work exceeds 25% of total roof/siding area per calendar year**; replacement windows always require a permit. Fee: $15 per $1,000 valuation (min $15) + state education fee $0.26 per $1,000. >5,000 sq ft or structural elements need a CT architect/engineer seal. Fire Marshal review applies to all occupancy types EXCEPT 1-2 family. Darien does not issue a letter of compliance for roofing permits.

#### Mandatory secondary approvals (skipping any → rejection)

| Town | Gotcha |
|---|---|
| Darien | 25% roof/siding threshold (annual) — **not yet enforced as agent logic**, manual check |
| Westport | Same 25% annual roof/siding threshold as Darien |
| Bridgeport | Requires BOTH a Building Permit and a separate Zoning Plan |
| Hartford | WC certificate must name "City of Hartford" as certificate holder |
| New Haven | Electronic filing only (paper blocked); may need separate obstruction/right-of-way permit for dumpsters/lifts/scaffolding/street work |
| Hamden | Inspections scheduled by phone only |
| Cheshire | May require related trade/sewer/zoning permits |

### Eligibility gating & scope

- All CT package generation is gated behind a 1-2 family dwelling confirmation (`project.isOneTwoFamily` boolean, captured at intake). Single-family/duplex → residential path; 3+ unit multifamily, condo, commercial, mixed-use are out of V1 scope and follow a separate code path. The validator distinguishes "answer is No" (ineligible) from "field missing" (unknown/pending). Sample jobs `data/job.rogers.json` and `data/job.chen.json` carry the field; the extract-prompt schema includes it.
- Eligible work types: **re-roofing, re-siding, replacement windows only**. In Greenwich all three use the same building permit form — scope is a description field, not a separate form.
- Multi-state baseline: NJ re-roof/re-side/replacement-windows on detached 1-2 family homes is "ordinary maintenance" — no permit. NYC like-for-like re-roofs on 1-2 family are generally permit-exempt. Practical scope for Gunner's trades is CT towns + selective NY suburbs (Westchester/Nassau/Suffolk/Rockland).

### Data model & required fields

- Core fields across all 15 CT areas: project address, 1-2 family confirmation, owner name/email/phone, contractor name, CT HIC/license number, work description, estimated cost, contact email.
- Town-specific additions: parcel ID (Greenwich), roofing affidavit for closeout (Stamford), site/plot plan + drawings (Bridgeport), zoning/conservation/historic approvals (Fairfield, Hamden), portal account + upfront fees (Ridgefield).
- Greenwich full package minimum: owner name/phone/email, address, parcel ID, section of town, sewer type, stories/rooms/bathrooms, work type, scope description, contract value, contractor/license info.
- Reusable company-level fields (Gunner legal name, CT license, signer, office contact, standard scope language, Greenwich contacts) stored once and injected into every permit.
- CT Workers Comp forms by role: **7A** (owner/sole proprietor NOT acting as GC), **7B** (owner/sole proprietor acting as GC), **7C** (excluded GC/principal employer). Submitted to the local building official, not WCC.
- Proof.com is mandatory for Greenwich, high-priority for Bridgeport's owner/sole-proprietor affidavit path, and conditional (WCC 7B/7C or notarized owner authorization) for Stamford and remaining portal towns. `fill.mjs` emits a dedicated "Proof.com / Notary" section whenever a town config defines a proof.com trigger.

### Proof.com (RON) & notarization

- Proof.com RON (remote online notarization) is viable for permit owner-authorizations in CT, NY, and NJ — the "CT attorney-closing state" restriction applies only to real-estate closings, not general notarial acts.
- Integration shape: REST API (~$10–25/notarization): create transaction → webhook → retrieve notarized PDF.
- Owner authorization (e.g. Greenwich page 2) requires notarization and cannot be automated without this; COI, town sign-off sheets, department approvals, and payment all remain human/town-side.

### RPA / automation reliability

- The full workflow has ~14 steps from job-data pull to permit receipt; roughly half are automatable (PDF generation, email dispatch, inbox monitoring, missing-info detection, status tracking, job update), half need human/town action (signatures, notarization, payment, town review decisions, tax-collector phone step). **The demo implements only step 1 (fill PDF) and step 5 (prepare email).**
- Government-portal RPA submission has only ~66–87% task success in benchmarks — far below the ~100% a sworn legal filing demands — and needs ongoing maintenance as portals change UI. Viable only with a small pilot-town set + a committed maintenance owner.
- Inbox reply parsing (matching messy town emails to the right permit; classifying missing-docs vs. fee-due vs. issued) is error-prone, needs real reply samples to tune, plus a human-reviewed exception queue.

### Intended production stack (not yet built)

- Next.js frontend + AWS Lambda/Step Functions backend + S3 document store + email integration (Gmail API / SES) + server-side pdf-lib. Step Functions for status flow; SQS + EventBridge for queues/retries; CloudWatch for monitoring.
- Four entities: **Company Profile** (Gunner static info), **Town Permit Profile** (per-town forms/contacts/rules), **Job Record** (per-permit fields), **Permit Package** (generated PDFs, replies, sign-offs, final permit).
- **Monday.com is explicitly NOT the permit data source or workflow hub.** The Monday workspace checked is software/project planning only (Epics, Sprints, Bugs Queue); Colin confirmed Monday was never part of the permit plan. See [[colin/monday-integration]].

### QA / verification process

Find a real example permit for the same job type, run it through the agent, then compare submission route, required documents, signatures/notary requirements, and extra approvals. Town flags to verify: Greenwich (email + sign-off sheet), Norwalk (email not portal), Stamford (roofing affidavit closeout), Darien (25% threshold), Westport (25% exemption), Bridgeport (Building Permit + Zoning Plan), New Haven (obstruction permit trigger), Hartford (WC cert naming City of Hartford), Hamden (phone inspection scheduling), Cheshire (related trade/sewer/zoning permits).

## GunnerCam in-app permit tracker

Separate from `permit-poc` — this is product scaffolding in WL-CompanyCam.

- A **frontend-only** permitting view (no backend/schema changes) at `src/components/permits-view.tsx` — a tabbed card: **Packet** (status, jurisdiction, permit number, next action, required documents), **Timeline** (stages rail), **Inspections**. Uses static/representative data; **no permit table in the DB yet** (see [[colin/data-model]]). Wired into `src/components/project-detail.tsx` and `src/components/my-day-content.tsx`; styled via a right-side rail in `src/app/globals.css`, placed under Scope of Work in both project-detail and [[colin/my-day]] focus mode.
- Intended GunnerCam permit data model is a **workflow/status object attached to a project** (not a document-centric tracker). Status enum: Not Checked → Not Required / Docs Needed → Ready to Submit → Submitted → Corrections Needed → Approved / Issued → Inspection Pending → Finaled, plus jurisdiction, permit number, assigned owner, next action, follow-up date, blocking reason, inspection outcomes. PDFs are supporting evidence, not the primary entity.
- MVP scope is a **read/write status tracker** (not a full workflow engine): "Can this job move forward, and what is blocking it?" — not automating submission or parsing portals. The roadmap/decisions already contain a permit task type anchoring future backend work — see [[colin/mvp-roadmap]] and [[colin/decisions]].

## Make.com permit-fee invoicing integration

(Full Make/Stripe context lives in [[colin/stripe-make]] — this is the permit-fee slice.)

- Make scenario **4048920** ("Permitting Invoice workflow") has a copy-paste bug in Route 2: its `columnId` points to the Invoicing board's HubSpot ID column while `columnValue` pulls the Permitting board's (empty in this branch) HubSpot ID, so it silently matches zero items. Correct fix: `columnId=text_mkzwwe0m` (*Project ID* on Invoicing), `columnValue` from `text_mm121etd` (*Project ID* on Permitting). The scenario has been off/invalid and never ran in production.
- Even after that fix, Route 2 would rarely match: Invoicing's `text_mm12a68m` (944 rows) holds numeric Monday pulse IDs while Permitting stores `GUN-XXXXX` strings in newer rows.
- **Recommended redesign:** join via the shared "Project Takeoff" board (ID 18346327856) — Permitting uses `board_relation_mkxen73g`, Invoicing uses `board_relation_mm0zrzy0`. The Takeoff item ID avoids both the ID-format mismatch and HubSpot-ID coverage gaps.
- The write module uses `ChangeMultipleColumnValuesV2` with `ifempty(source_value, null)`, which **overwrites** (not appends) the Permits & Fees column — activating without a "skip if source blank" guard would wipe manual values. Minimum: a filter requiring source Permit Fee non-empty (Option B); optionally a "Permits Fee Locked" checkbox on Invoicing for human override (Option C, needs training).
- Only **12%** of Invoicing rows (150/1,238) have a Permits & Fees value vs **95%** of Permitting rows — most permit fees never reach customer invoices. Where manual values exist they agree with Permitting (Jake Lewis $250, Matthew Farin $286.76 both match) — gaps, not conflicts. HubSpot ID coverage: 42% Permitting (134/322), 22% Invoicing (268/1,238).
- Related: the PM Change Order Make scenario (3965663) failed fatally 2026-05-14 with a Monday GraphQL `[400] PARSING_ERROR — Expected Name, found :` in a `createSubitemV2` call (a colon in a variable expansion produced a malformed column name); ran clean through May 13, then was disabled wholesale rather than fixed.

## CompanyCam API gotchas (permit-document scans)

- The CompanyCam API returns 404 on some project document endpoints, aborting scripted permit-document scans unless per-project error handling + per-town checkpointing to a temp JSON is added (so one bad project doesn't discard accumulated data).
- Rate limits (429 Retry-After) apply. Bulk document scans should be bounded per town (e.g. max 35 projects) with early exit on two permit-document matches.
- CompanyCam import is still an on-demand script with no cron wiring (`tickets/TODO-companycam-sync.md`). Import ran manually on dev once (2026-06-03). See [[colin/masterdb-sync]].

## Open questions & TODOs (as of 2026-06-21)

| Item | State |
|---|---|
| **Darien 25% threshold not automated** | Agent bundles the re-roof letter for siding-only jobs; conditional threshold logic (and similar per-town flags) still manual |
| **CT Proof.com mechanism unresolved** | Two research passes disagree whether CT permits allow full electronic RON vs. remote-ink requiring a mailed original. Needs a written answer from Proof.com before building |
| **COI invalid** | `COI_Cheshire_2024_EXPIRED.pdf` is expired and names the wrong town. No COI generation/validation/expiry/attachment logic exists; a current correctly-addressed COI must be obtained from the USI brokerage (manual). The demo package PDF omits the COI |
| **Live S3 demo stale** | `gunner-permit-demo-2026` still serves the older recreated-form build; newer official-PDF build never finished uploading (SSO expired mid-upload) |
| **CompanyCam sync blockers** | Import token not persisted in SSM/config; CompanyCam-label → GunnerCam-phase stage mapping undecided; no scheduled sync job |
| **Make scenario 4048920** | Never run in production; needs the Route 2 column fix, ideally the Takeoff-board join redesign, plus a source-blank guard before activation |
| **Non-Greenwich CT towns implementation-readiness** | Per 2026-06-18 state, Norwalk/Stamford/Darien researched but configs/field mappings incomplete; superseded by 2026-06-21 sessions claiming all 15 validate as `ready`. **Verify which build is canonical — the two states conflict** |
| **AWS SSO mid-deploy expiry** | `permit-poc` Lambda deploys repeatedly blocked by SSO creds expiring within a session; the 127.0.0.1 browser callback doesn't reliably complete in in-app tabs. Workaround: `aws sts get-caller-identity`, kill stale login process if creds refreshed in OS browser |

---
*Sources: 62 nuggets across ~13 work sessions, 2026-05-21 → 2026-06-21 (bulk dated 06-15, 06-18, 06-21; Make findings from 06-01). Raw nuggets: `~/Documents/Obsidian/claude-obsidian/.raw/ingest-2026-06-21/by-topic/permits.json`.*
