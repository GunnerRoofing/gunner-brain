---
title: Dialpad → HubSpot Integration Architecture
type: gunner
tags: [dialpad, hubspot, monday, integration, webhooks, api]
created: 2026-04-16
updated: 2026-04-16
status: developing
sources: [dialpadapi.json, developers.hubspot.com, developer.monday.com]
related:
  - "[[vendors/dialpad-api-reference]]"
  - "[[vendors/hubspot-api-reference]]"
  - "[[vendors/monday-api-reference]]"
  - "[[vendors/dialpad]]"
  - "[[vendors/hubspot]]"
  - "[[vendors/monday]]"
  - "[[gunner/hubspot-leads-project]]"
  - "[[gunnerteam/voip-softphone-research]]"
---

# Dialpad → HubSpot Integration Architecture

## Decision

The native Dialpad HubSpot integration is unreliable — calls and texts do not consistently log to contacts or associated deals. A custom webhook-based integration is being built to replace it.

**Goal:** Every Dialpad call and SMS logs automatically to the correct HubSpot contact AND the associated deal timeline.

**Status:** Architecture designed, API references filed. Build not started as of 2026-04-16.

> [!note] Update (2026-06): full Dialpad replacement under research
> A later, broader initiative researches replacing Dialpad entirely with an **in-app softphone** (voice + SMS/MMS on one business-card number) on Telnyx — see [[gunnerteam/voip-softphone-research]]. That doc supersedes the brief "Why Not Amazon Connect" note below with an AWS-verbatim disqualification (shared voice+SMS number is unsupported). Relationship: **this webhook bridge is the near-term call/SMS logging fix; the softphone is the strategic replacement.**

---

## Why Not Amazon Connect

Amazon Connect (AWS cloud contact center) was briefly evaluated as a full Dialpad replacement. Ruled out — the problem is a logging reliability issue, not a telephony problem. Replacing Dialpad would be months of work for a problem solvable in days with a webhook receiver.

---

## Architecture

```
Dialpad webhook → Webhook receiver → HubSpot API
(call ended / SMS)   (Lambda/Worker)   (log + associate deal)
                          ↓
                    Monday.com API (optional — create/update items)
```

### Components

**Dialpad webhooks** — fire on `hangup` (call ended) and SMS events. Registered via `/api/v2/webhooks` + `/api/v2/subscriptions/call` and `/api/v2/subscriptions/sms`. Signed with JWT/HS256.

**Webhook receiver** — small Node.js function (~200-300 lines). Best hosted on AWS Lambda or Cloudflare Workers (free tier covers Gunner's volume). Verifies JWT signature, normalizes phone number, calls HubSpot and Monday APIs.

**HubSpot API** — contact search by phone, deal association lookup, call/note engagement creation. All in one create request via the `associations[]` array.

**Monday.com API** (optional, for lead boards) — search items by phone column, create or update item with call details.

---

## Call Logging Flow

```
1. Receive Dialpad `hangup` webhook
2. Verify JWT signature (HS256 with webhook secret)
3. Extract external_number (customer phone, E.164 format)
4. Normalize: strip non-digits, take last 10 → searchPhone
5. POST /crm/objects/2026-03/contacts/search
   - filter: hs_searchable_calculated_phone_number EQ searchPhone
6. GET /crm/objects/2026-03/contact/{id}/associations/deal
   - returns open deal IDs
7. POST /crm/v3/objects/calls
   - properties: duration, direction, recording URL, timestamp, status
   - associations: [{contact id, typeId: 194}, {deal id, typeId: 206}]
```

## SMS Logging Flow

```
1. Receive Dialpad SMS webhook
2. Verify JWT signature
3. Extract customer phone:
   - inbound: from_number
   - outbound: to_numbers[0]
4. Normalize phone (last 10 digits)
5. POST /crm/objects/2026-03/contacts/search
6. GET associations/deal for contact
7. POST /crm/v3/objects/notes
   - hs_note_body: "SMS (inbound) from +1XXXXXXXXXX:\n\n{text}"
   - associations: [{contact id, typeId: 202}, {deal id, typeId: 214}]
```

---

## Key Technical Details

### Phone Normalization (Critical)

Dialpad sends E.164 (`+12035551234`). HubSpot's searchable calculated property strips the country code. Always normalize before searching:

```js
const normalize = (num) => num.replace(/\D/g, '').slice(-10);
```

### No Contact Found

If phone search returns zero results:
- Option A: Create a new HubSpot contact with the phone number, then log
- Option B: Log to a catch-all "Unknown Caller" contact for manual review
- Option C: Drop and write to a dead-letter queue

### No Deal Found

If a contact exists but has no associated open deals: log the engagement to the contact only. Do not create a deal automatically — deal creation is a rep action.

### Duplicate Prevention

HubSpot's native Dialpad integration may still fire on some events. Two options:
- Disable the native integration entirely before enabling webhooks
- Check if a call engagement with the same `call_id` already exists before creating (add `custom_data` or `hs_call_title` with Dialpad call ID, then search before creating)

### Recording URL

`hs_call_recording_url` requires HTTPS and `.mp3` or `.wav`. Set `hs_call_source: "INTEGRATIONS_PLATFORM"` or recordings won't attach. Use `call_recording_share_links[0]` from the Dialpad payload.

---

## HubSpot Association Type IDs

| Engagement | Object | typeId |
|------------|--------|--------|
| Call | Contact | 194 |
| Call | Deal | 206 |
| Note | Contact | 202 |
| Note | Deal | 214 |

> Verify against your instance: `GET /crm/v3/associations/calls/contacts/types`

---

## Monday.com Integration (Optional Layer)

If Dialpad calls/SMS should also create or update Monday leads:

```
1. Search items_page on CRM/Leads board by phone column
2. If found: change_multiple_column_values (last called, notes)
3. If not found: create_item (name, phone, source = "Dialpad Inbound")
```

Column IDs are board-specific — run `boards → columns { id title type }` once to get them. See [[vendors/monday-api-reference]] for full syntax.

---

## Hosting Recommendation

**AWS Lambda** — simplest, free tier covers this volume, integrates with API Gateway for the webhook URL. Alternatively, Cloudflare Workers (no cold start, generous free tier).

Not recommended: running on home lab — webhook receiver needs to be publicly reachable with low latency and high uptime.

---

## Open Items Before Build

- [ ] Confirm whether to disable native Dialpad integration first or run parallel
- [ ] Decide no-contact-found behavior (create vs. catch-all vs. drop)
- [ ] Verify HubSpot association type IDs against Gunner's instance
- [ ] Get Gunner's HubSpot Private App token + required scopes
- [ ] Get Dialpad webhook secret from admin portal
- [ ] Determine if Monday.com integration is in scope for v1
- [ ] Choose hosting (Lambda vs. Cloudflare Workers)
