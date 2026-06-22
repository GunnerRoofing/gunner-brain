---
type: reference
owner: colin
app: GunnerCam
created: 2026-06-21
updated: 2026-06-21
tags: [wl-companycam, stripe, make, monday]
status: active
---

# Stripe Invoicing & Make.com Automation

## Who owns what

GunnerCam is a **display-and-reactor layer** for Stripe. Make.com owns all invoice creation. GunnerCam's Stripe surface (`src/lib/stripe.ts`, `import 'server-only'` line 1) only ever calls `list`, `search`, `retrieve`, and `sendInvoice` — never `create`, `finalize`, or `void`. The lib is intentionally read-only and lazily inits to `Stripe | null`. SDK is `stripe@^22.2.0`.

| Layer | Owns |
|---|---|
| Make.com | Invoice create / finalize / send; routes by entity to the right Stripe account; writes id + hosted URL back to Monday |
| Monday | System of record for live invoice state (subitems board) |
| GunnerCam | Reads invoice state from Monday, retrieves from Stripe for display, **re-sends** existing invoices only |

## Stripe accounts (standalone, not Connect)

Gunner uses **~5 standalone Stripe accounts**, one per legal entity/region (CT, NJ, NY, OH, PA) — **not** Stripe Connect. Each is fully separate; one key cannot see across them.

- One restricted key per account, held as a JSON map `{ "<label>": "rk_live_…" }` in `STRIPE_ACCOUNT_KEYS`, scoped to **Customers:Read + Invoices:Write** (write only because `sendInvoice` is a write op).
- `getStripeAccounts()` / `getStripeForAccount()` follow the **blank-disables dormant pattern** (same as the SES lib): unset/invalid `STRIPE_ACCOUNT_KEYS` → no accounts / `null`, so the Payments tab renders a clean empty state. Adding/removing an account is a one-line secret edit + redeploy.
- The GET invoices route **fans out across all accounts in parallel and fails soft per account** — one bad key logs and yields nothing while the rest still render. Each invoice DTO carries its `account` label, which the resend route uses to call `getStripeForAccount`.

> **Superseded models (do not relitigate — see [[colin/decisions]]):** an early model (2026-06-01) used **Stripe Connect** (Gunner Holdings platform + per-state `acct_…` connected accounts, `stripeAccount` param, `corporations.externalIds.stripe_account_id`); corrected 2026-06-04 to standalone-accounts-with-per-account-restricted-keys. An even earlier model used a **single** `STRIPE_SECRET_KEY`, which returned empty for real per-state customers.

## Payments tab + invoice resend (GunnerCam)

The join key between a GunnerCam job and a Stripe invoice is the per-invoice **Stripe `in_…` id** (last resort: `project.email`). Dollar amount is explicitly **not** a reliable match key — a repeat customer (same email, one Stripe customer, one billing address) can have multiple jobs with equal milestone amounts (e.g. two $2,000 deposits), and location can't disambiguate.

- **Resend logic (as of 2026-06-21):** resend requires only `stripeInvoiceId`. `monday.ts` parses Monday column `text_mkzsa0e5` → `MondayInvoice.stripeInvoiceId` (only `in_…`-prefixed values; junk → `null`). `stripe.ts` `findInvoiceByIdForResend` retrieves from whichever account owns the invoice and returns it. The UI sends `stripeInvoiceId` (not `amountDueCents`). Rows with no Stripe id can't be resent — the UI falls back to client-side **"Copy link"**.
- `sendInvoice()` in the resend route is the **only Stripe write call in the entire codebase**; it re-sends existing Make-created invoices.
- **Superseded evolution:** (a) earliest match was `customer email + amountDueCents`; (b) then by-id-preferred with an email+amount fallback plus an email tenant guard (invoice email must match project email); (c) latest (2026-06-04) **removed both** — the by-id path just retrieves and returns.
- Branch `feat/stripe-payments-multiaccount` (`8cd18d1` → `8a96086` → `fce55f6`) carries the multi-account tab; deployed live to dev at `https://project.dev.gunnerroofing.com`. Depends on `feat/remove-my-day-pm-only-daily-log` (which carries `project.email` from inbound job sync). Prior WIP `wip/stripe-payments` (`6eeaf4e`) was single-account / `externalIds.stripe_id`-keyed and returned empty.

## Monday Invoicing board mapping

Live invoice state reads from the **Invoicing subitems board `18390982283`** (subitems of 💰 Invoicing parent `18390982177`), keyed per job by `invoicing_monday_id`. See [[colin/monday-integration]] for the read-through wiring.

| Field | Monday column |
|---|---|
| Milestone name | (item name) |
| Amount due | `numeric_mkyav76j` |
| Send status | `color_mkzsnfh7` |
| Amount paid | `numeric_mkyaqk4h` |
| Hosted invoice URL | `link_mkzm3afw` |
| Stripe invoice id (`in_…`) | `text_mkzsa0e5` |

- **Stale claim corrected:** on 2026-06-03 the `text_mkzsa0e5` id column was reported missing from the live board (write going nowhere); live inspection 2026-06-09 confirmed it **is present and actively populated** — ≥200 of ~1,210 subitems carry `in_…` values; scenario `3939700` writes both the raw id and the hosted link. A DECISIONS.md note claiming the column was deleted was reversed with a dated correction.
- The hosted-URL column `link_mkzm3afw` encodes an **obfuscated access token, not a recoverable `in_…` id** — so the hosted link cannot substitute for the stored id when matching invoices.

## Make.com scenario inventory

| Scenario | Name | Role |
|---|---|---|
| `3939700` | Create invoice – All Stripe Accounts | **The invoice engine.** Trigger on Monday Invoicing-subitem status flip → find/create Stripe customer by email → `createInvoiceItem` → `createInvoice` → `finalizeInvoice` → write hosted URL + `in_…` id back to Monday. Routes by job entity/location. ~80–100 router leaf paths (payment-type × state × new/existing customer × permits). Runs in prod multiple times/day. |
| `3467291` | Seal the relationship create deposit | Normal billing entry point; HubSpot webhook on deal → "Ready to Build". Creates Invoicing parent + Deposit subitem ("Create Invoice"), cascading to `3939700`. |
| `3466413` | Hubspot to Monday.com (v3) – future state | Separate HubSpot→Monday **project-creation** pipeline. Webhook → Sleep 5min → Get Deal/Contact → nested routers (state columns, install timeline, product subitems, HubSpot back-link, permitting/procurement, invoicing seed rows). Frequently conflated with `3939700` but shares **none** of its modules. |
| `4050964` | Sales Change Order Workflow | CO automation (see ST-5 below) |
| `3965663` | PM Change Order Workflow | CO automation (inactive) |
| `3640307` | Project take off status change | Job sync |
| `4295903` | Project take off HubSpot id mapping | Id mapping |

## Change-order → invoice (ST-5)

**Locked decision (latest, as of 2026-06-21): GunnerCam creates NO Stripe invoice on CO signing — Make owns CO billing.** The signing webhook only calls `noteJobChangeOrderSigned()` (no Stripe call); on COC/CO completion GunnerCam emits an outbound `document.signed` webhook for Make to consume. `HANDOFF-change-order-create.md` marks Stripe invoice creation out of scope. See [[colin/decisions]].

- A **live audit of Make blueprints confirms no Make scenario invoices change orders** (the invoice scenario has no CO route; the PM CO workflow is inactive) — so there is no double-billing path regardless of which side eventually owns CO invoicing.
- **Conflict-across-time, resolved:** 2026-06-01 ST-5 was actually built (migration `0020`: `files.change_order_amount_cents`, `signature_requests.stripe_invoice_id`; DocuSign-completed webhook fired a `collection_method: send_invoice` invoice, idempotent on sig-request id, fail-soft). 2026-06-04 that scaffold was **explicitly dropped** per DECISIONS.md. A 2026-06-10 variant (draft-invoice-on-CO-signed, never finalized; AR/Bryce sends manually; migration `drizzle/0031` adding 3 nullable `change_orders` cols) exists in history, but the 2026-06-15 standing decision supersedes all of it: no GunnerCam Stripe invoice on CO signing.
- Schema choice: CO amount lives on the **files row** (`files.change_order_amount_cents`), not a new `change_orders` table; no `MN-0` doc-kind enum (never existed) — reuse `isChangeOrderFileName()` to identify CO files. Only positive amounts gate any invoice-fire branch.

## Infra & secrets

Stripe account keys are fetched from **SSM at Lambda runtime**, not baked into Lambda env vars, to stay under AWS's **4 KB env-var hard limit**. See [[colin/aws-infra]].

- `STRIPE_ACCOUNT_KEYS` lives as a `SecureString` SSM parameter `/wl-companycam/<stage>/stripe-account-keys`; `stripe.ts` reads it via `@aws-sdk/client-ssm` (lazy + memoized). Lambda env carries only the param *name* `STRIPE_ACCOUNT_KEYS_PARAM`.
- `STRIPE_WEBHOOK_SECRET` is declared/injected but **no webhook receiver is built** — reserved for future `invoice.paid` ingestion.
- **Incident:** the first deploy hit the 4 KB limit and SST's error handler printed the full env-var map — including all 5 live restricted keys, the DocuSign RSA private key, and `DATABASE_URL` — into the deploy log. The SSM move was the fix. (Pattern echo: see [[colin/gotchas]] on `sst secret list` / `sst diff` leaking secrets.)
- **Superseded:** earlier sessions declared single SST secrets `StripeSecretKey` + `StripeWebhookSecret` (blank-defaulted in `sst.config.ts`, injected into the web Lambda env block).

## Make reliability & gotchas

| Scenario | Issue | Fix |
|---|---|---|
| `3939700` | "due_date in the past" — `due_date` set to "today" (start-of-day UTC) resolves to ≈now by API fire time; Stripe rejects → ~20% creation failures (six in two weeks, 05-15/18/19/21). | Clamp `due_date` to `max(computed_date, now + N-day buffer)`. **Not confirmed resolved** as of 2026-06-21 — fix design known, post-fix success window too small. Axe Automation (3rd-party agency) made 6 edits 05-14→05-22 and manually retries failures. |
| `3467291` | Blank-name crash — contact with blank first+last → whitespace-only Monday item name → `InvalidItemNameException`. Item template `{{5.properties.firstname}} {{5.properties.lastname}}`. | `ifempty(trim(...); 5.properties.email)` — silent fallback to email (over a blocking filter), plus process note that sales populate names before "Contract Signed". |
| `3466413` | **Auto-deactivates itself** (not pauses) at Make's max-errors threshold → whole HubSpot→Monday new-project pipeline offline. Triggered 2026-05-28 by a blank-name deal. | Pre-create filter requiring a non-empty, non-whitespace deal name. |

- Make's scenario-level **"errors" counter is a lifetime tally, not current state** — active scenarios (`4344029` Assign Dana, `3467291`, `3680337` Update morning/night contacts) showed non-zero errors while recent executions all succeeded; only `3939700` and `3965663` had genuine recent failures.
- **Decision: do NOT split/refactor `3939700`** short-term (~80–100 paths, 5 LLC bank accounts). Leo Fuentes flagged a possible migration off HubSpot/Make to AWS, making a 1–2 week regression-risky split wasteful. Preferred fix: add error handlers for visibility.

## MCP / tooling notes

- **Make MCP** can run and read scenarios from Claude but **cannot expose per-step bundle inspector data** — where Make failures almost always live — so Claude can't reliably diagnose failures without a human in Make's visual bundle inspector.
- **Decision:** connect Make MCP to a **Cowork space, not Claude Code** — Make is ops-shaped (persistent connector) vs. repo-scoped ephemeral CC sessions; only exception is dev-loop scenarios (deploys, PR posting) needed mid-edit.

## Product scope

- Per-job payment / expected-collections visibility is wanted for the **ops portal / manager view** (Eddie's ask for Joe — where payments stand, what collections are expected; possible AR board view), and is **intentionally scoped out of the PM mobile app**. See [[colin/people-and-context]].

## Open questions / TODOs

- **Multi-PM combo jobs** (roofing + siding): partial-completion invoice triggers — when one trade hits 50% and fires an invoice while the other continues, remaining payments may need manual pushing. Eric Recchia noted a future state of pulling invoice memo/due-date from co-portal (currently Monday-sourced).
- **`stripe_id` upstream pipe** (legacy, single-account / `externalIds.stripe_id` model): no upstream system (QP→HubSpot→Monday→GunnerCam) currently sends the Stripe customer id; mostly mooted by reading invoice state from Monday's `text_mkzsa0e5`, but unresolved if direct-Stripe-by-customer is ever revived.
- **ST-5 product decisions** (nominally open even though current decision is "Make owns CO billing"): (1) what counts as a CO being "executed" — DocuSign e-sign vs. paper signature (template defaults to paper, `signing: 'manager'`, blank homeowner column, optional DocuSign anchor) with no digital event; (2) where the Stripe customer id comes from; (3) auto-send vs. draft-for-AR-review.
- **Make `3939700` due_date fix** verification pending (see table above).
