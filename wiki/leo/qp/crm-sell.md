---
type: reference
owner: leo
created: 2026-07-01
updated: 2026-07-01
tags: [qp, crm, sell-mode, frontend, masterdb, strangler]
status: active
---

# QP — CRM "Sell mode" (record workspace)

The first thin slice of the **Gunner CRM** (the HubSpot-strangler iteration), built **inside the QP
wizard** rather than as a greenfield app: a **Quote ⇄ Sell toggle** where "Sell" surfaces the customer's
CRM record — contact, a unified activity timeline, and associated records — so a rep works the lead where
they build the quote. Part of [[leo/qp/quote-wizard]]; backed by masterdb (see [[leo/integrations/dialpad-hubspot]]).

## Shipping mechanics
- **Repo/branch:** `sales-portal-frontend`, `redesign/quote-wizard`.
- **Flag:** `NEXT_PUBLIC_CRM_SELL=true` (build-time, independent of the wizard flag). Live on **qp-stage**.
  - ⚠ A new `NEXT_PUBLIC_*` flag must be added in **3 places** or it silently never bakes: the GitHub env
    var, `deploy.yaml`'s Generate-.env passthrough, and `scripts/generate-env.sh`'s allowlist.
- Component: `QuoteWizard/components/SellPanel.js` (+ `NoteComposer.js`, `lib/useCrmTimeline.js`,
  `lib/useCustomerQuotes.js`).

## UI built + live on stage (Increments 1–4, 2026-07-01)
A **3-column record workspace** with CRM design tokens (Inter, teal `#3abdaf`, green `#8bc269`):
- **Left rail — contact:** name, lifecycle badge, email/phone, **address**, owner, **lead-source dropdown**.
- **Center — unified activity timeline + composer:**
  - Timeline merges **Dialpad calls/SMS** (per-contact, from masterdb) with this quote's **QP lifecycle
    events** (per-project) into one newest-first stream with source badges.
  - **Rich note composer**: draft-js **@mentions**, file **attachment**, and a **ServiceNow-style
    Comment / Work-note toggle** (default = Work note / internal).
  - **Timeline polish:** sticky filter bar (All/Calls/Texts/Notes/Quote + counts), same-day grouping
    (Today/Yesterday/…, in Eastern time), and **pin-to-top** (persisted per-project in localStorage).
- **Right rail — associated records:** **Deal** card (stage + value), **Property** card (address + map
  link), **Quotes** card (the customer's other QP quotes).

## Data path
| UI | Hook | Backend |
|---|---|---|
| Contact + call/SMS timeline | `useCrmTimeline(phone)` | `GET /crm/contact-timeline` → masterdb `crm_contacts` + `crm_activities` |
| Notes + quote-lifecycle events | `useProjectMessages` | QP `project_activity_log` (today; notes moving to masterdb — see below) |
| Quotes + Deal card | `useCustomerQuotes` | QP `POST /search-projects` |

- Read Lambda = **`get-crm-timeline-api-v1`** (Node, own `pg` pool to masterdb as `crm_app`, verify-ca TLS).
- **Cross-account:** masterdb + the Lambda are **dev acct 980921733684**; stage portal is **127214181149**.
  Stage reaches the dev Lambda via a **cross-account API Gateway invoke** (no VPC peering). Durable
  prod path still needs a real stage/prod masterdb read-path (Tyler).

## Backend contract with Tyler — LOCKED (2026-07-01)
Tyler is building the write surface; decisions settled:
- **Notes move to masterdb `crm_activities`** (`type='note'`), not QP `project_activity_log` — unifies notes
  with calls/SMS/email on the timeline (quote-lifecycle events stay in QP → timeline stays a 2-source merge).
- **`lead_source` is LEAD-scoped** (on `crm_leads`, no contact column) — rail edits the **active lead's**
  source, resolved by `crm_leads.main_quote_id = <QP quote id>`.
- **Comment vs Work-note = `is_internal` bool** (default internal; customer-facing = `WHERE NOT is_internal`).
  Worknote @mention routing ships now; **Comment → customer delivery = email**, rides the **Gmail slice**
  (Tyler owns; the long pole; also unblocks email-in-timeline).
- **Rep-editable = minimal:** `lead_source` + notes. Locked (HubSpot-mirrored): contact name/email/phone/
  lifecycle/owner. Read-only (QP-owned): address, deal stage/value, quotes.
- **One write surface:** `PATCH /crm/lead` + `POST /crm/activity` first, `PATCH /crm/contact` later.
- **Notes cutover = backfill + switch:** Tyler backfills QP notes → `crm_activities` (`source='qp'`,
  `is_internal=true`, `dedup_key`=QP id, `occurred_at` preserved) **before** the flip; history carries over.

**Locked shapes:**
```
GET  /crm/contact-timeline?phone=<E.164>&quoteId=<qp_quote_id>
  → { contact:{id,first_name,last_name,email,phone,lifecycle},
      lead: null | {id,lead_source,stage},
      activities:[{ id,type,direction,occurred_at, body, recap_summary, has_recording,
                    is_internal, handled_by_agent_id, agent_name }] }
PATCH /crm/lead     { lead_id, lead_source }  → { id, lead_source, updated_at }
POST  /crm/activity { contact_id, lead_id?, type:'note', body, is_internal }  → 201 {...}
```

## Status / next
- **UI: shipped to stage (Inc 1–4).** Three pieces are **UI-only facades** until the backend lands:
  lead-source persistence, Comment/Work-note routing, and inline edits.
- **Ball with Tyler:** build `PATCH /crm/lead` + `POST /crm/activity`; confirm the **`main_quote_id`
  mapping** (the one open item — his prior: it's a distinct QP quote id, not the project_id; it paces the
  lead lookup **and** the backfill); run + verify the backfill.
- **My queued frontend work** (wire when endpoints land): composer → `POST /crm/activity`, read notes from
  the CRM timeline, bind the lead-source dropdown to `lead.id` + `PATCH /crm/lead`, then the flag-gated flip.
- Working docs: `~/crm-tyler-handoff.md`, `~/crm-tyler-reply.md`.

## Links
- [[leo/qp/quote-wizard]] — the wizard that hosts Sell mode
- [[leo/integrations/dialpad-hubspot]] — Dialpad→masterdb ingestion feeding the timeline
- [[leo/apps/quote-portal]] — QP overview, environments, AWS access
