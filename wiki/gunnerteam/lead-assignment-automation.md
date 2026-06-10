---
title: Round-Robin Lead Assignment Automation
type: gunner
tags:
  - hubspot
  - dialpad
  - monday
  - automation
  - leads
  - round-robin
  - lambda
  - aws
created: '2026-04-16'
updated: '2026-04-16'
status: ready-to-build
sources:
  - _system/lead-assignment/
related:
  - '[[gunner/dialpad-hubspot-integration]]'
  - '[[gunner/hubspot-leads-project]]'
  - '[[vendors/dialpad-api-reference]]'
  - '[[vendors/hubspot-api-reference]]'
  - '[[vendors/monday-api-reference]]'
---

# Round-Robin Lead Assignment Automation

**Status:** Scripts written (v2) — ready to build. Pending: populate `.env` with real IDs.  
**Code location:** `_system/lead-assignment/`

---

## What It Does

**On Lead Created (HubSpot):**
1. Syncs contact name/email/phone to Dialpad (so reps see a named contact on callback)
2. Routes to location-specific rep pool: NJ contact → NJ reps, all others → default pool
3. Checks Dialpad: if the next round-robin rep is on an active call, skips to the next available one
4. Assigns the lead in HubSpot
5. Starts a 5-minute timer; if the assigned rep makes an outbound call to the customer → done
6. If not → reassigns randomly from remaining untried reps, restarts timer
7. If all reps in the location pool exhausted → escalates to manager

**On Deal → Ready to Build (HubSpot):**
1. Creates a Monday.com item on the Jobs board with contact details as the first update
2. Assigns a project manager (deal's HubSpot owner if they're a PM, else round-robin)
3. Stores the deal → Monday item mapping

**Ongoing (Dialpad → Monday):**
- When a PM makes an outbound call that matches a job contact's phone → posts call summary + recording link to the Monday item
- When a PM sends or receives an SMS from a job contact → posts message to the Monday item

---

## Architecture

```
HubSpot Workflow (Lead created)
        ↓  POST /lead-created
  Lambda: leadCreated.js
        ↓
  1. Fetch lead + full contact details (name, phone, email, state, address)
  2. Sync contact → Dialpad (createContact or updateContact)
  3. Route to pool: NJ → REPS_NJ, else → REPS
  4. Check rep availability (DynamoDB cache, fed by Dialpad webhooks)
  5. Assign lead owner in HubSpot
  6. Store pending record: {leadId, phone, state, assignedTo, triedReps, assignedAt}

HubSpot Workflow (Deal → Ready to Build)
        ↓  POST /deal-ready-to-build
  Lambda: dealReadyToBuild.js
        ↓
  1. Fetch deal + associated contact details
  2. Create Monday.com item: "Name — Address — Deal Name"
  3. Post contact details as first update
  4. Assign PM (deal owner if PM, else round-robin from PMS pool)
  5. Store MONDAY#{dealId} record: {mondayItemId, pmDialpadUserId, contactPhone}

Dialpad Webhooks (connected / hangup / SMS)
        ↓  POST /dialpad-events
  Lambda: dialpadEvents.js
        ↓
  Call connected → mark rep ON CALL in DynamoDB
  Call hangup   → mark rep AVAILABLE in DynamoDB
                  If rep is a PM: look up Monday job by contact phone → post call update
  SMS event     → If sender is a PM: look up Monday job by contact phone → post SMS update

EventBridge: rate(1 minute)
        ↓
  Lambda: checkAssignments.js
        ↓
  1. Scan for pending records where assignedAt < NOW - 5min
  2. Query Dialpad: did assigned rep call contact phone since assignment?
     → YES: mark complete
     → NO: reassign (random from untried reps in same location pool)
  3. Pool empty: assign to manager
```

---

## Files

```
_system/lead-assignment/
  package.json
  serverless.yml              — Lambda + API Gateway + DynamoDB + EventBridge (4 functions)
  .env.example                — all env vars with inline instructions
  src/
    config.js                 — REPS, REPS_NJ, PMS, MANAGER, Monday config
    lib/
      assign.js               — location routing + round-robin + availability logic
      state.js                — DynamoDB: assignments, rep cache, RR pointers, Monday jobs, Dialpad contact IDs
      dialpad.js              — call queries, contact create/update, JWT verification
      hubspot.js              — full contact details, deal fetch, lead owner update
      monday.js               — create item, post update, call/SMS formatters
      contactSync.js          — HubSpot → Dialpad contact upsert (non-blocking)
    handlers/
      leadCreated.js          — HubSpot webhook: new lead
      dealReadyToBuild.js     — HubSpot webhook: deal stage = Ready to Build
      checkAssignments.js     — scheduled every 1 minute
      dialpadEvents.js        — Dialpad call + SMS webhooks
```

---

## DynamoDB Table

Single table, six record types (PK prefix):

| PK | Purpose | Key Fields |
|----|---------|------------|
| `LEAD#{leadId}` | Pending assignment tracking | status, assignedTo, contactPhone, contactState, assignedAt, triedReps[] |
| `REP#{dialpadUserId}` | Rep availability cache | onCall (bool), updatedAt |
| `RR#SALES` | Default pool round-robin pointer | index (int) |
| `RR#SALES_NJ` | NJ pool round-robin pointer | index (int) |
| `RR#PM` | PM round-robin pointer | index (int) |
| `MONDAY#{dealId}` | Deal → Monday item mapping | mondayItemId, pmDialpadUserId, contactPhone, status |
| `DIALPAD_CONTACT#{phone}` | Phone → Dialpad contact ID cache | dialpadContactId |

---

## Location Routing

HubSpot stores state as a 2-letter abbreviation (e.g. `NJ`, `CT`).  
The service checks `contact.state` against `["nj", "new jersey"]` (case-insensitive).

- NJ contact + `REPS_NJ` configured → NJ pool, `RR#SALES_NJ` pointer
- All others → default pool, `RR#SALES` pointer
- Each pool has its own round-robin pointer — NJ and CT assignments never interfere
- If the NJ pool is exhausted → escalate to manager (no fallback to CT pool)

Set `REPS_NJ_JSON=[]` to route all leads to one shared pool regardless of state.

---

## Monday.com PM Activity Logging

When a PM makes a call or sends an SMS via Dialpad:
- The `dialpadEvents` handler checks if the number matches a known active job's `contactPhone`
- If matched: posts a formatted update to the Monday item (call duration + recording link, or SMS text)
- If not matched: silently skips (PM calling a sub, vendor, etc.)

**What gets logged:**

Call update example:
```
📞 Call (3m 42s) → outbound
Rep: Dave
Number: +12015551234
🎙 Recording  ← link if recording exists
```

SMS update example:
```
💬 SMS → outbound
Rep: Dave
Number: +12015551234

> Hey, just confirming we're on for Tuesday at 9am
```

---

## Setup Steps

### 1. Deploy

```bash
cd _system/lead-assignment
npm install
cp .env.example .env
# Fill in all values in .env (see Open Items below for where to find IDs)
npm run deploy
```

Three URLs output by CloudFormation after deploy:
- `LeadCreatedUrl` → HubSpot workflow (Lead created trigger)
- `DealReadyToBuildUrl` → HubSpot workflow (Deal stage = Ready to Build trigger)
- `DialpadEventsUrl` → Dialpad webhook endpoint

### 2. Create Dialpad webhook subscriptions (run once)

```bash
# Step 1: Create webhook endpoint
curl -X POST https://dialpad.com/api/v2/webhooks \
  -H "Authorization: Bearer $DIALPAD_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"hook_url": "DIALPAD_EVENTS_URL", "secret": "YOUR_SECRET"}'
# → save the returned endpoint id

# Step 2: Subscribe to call events for the whole company
curl -X POST https://dialpad.com/api/v2/subscriptions/call \
  -H "Authorization: Bearer $DIALPAD_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "endpoint_id": ENDPOINT_ID,
    "call_states": ["connected", "hangup"],
    "enabled": true,
    "target_type": "company",
    "target_id": YOUR_COMPANY_ID
  }'

# Step 3: Subscribe to SMS events for each PM (repeat per PM)
curl -X POST https://dialpad.com/api/v2/subscriptions/sms \
  -H "Authorization: Bearer $DIALPAD_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "endpoint_id": ENDPOINT_ID,
    "direction": "all",
    "enabled": true,
    "target_type": "user",
    "target_id": PM_DIALPAD_USER_ID
  }'
```

### 3. Create HubSpot workflows

**Workflow A — Lead Assignment:**
1. Lead-based → Trigger: Lead is created
2. Action: Send Webhook → POST → `LeadCreatedUrl`
3. Include `objectId = {{lead.hs_object_id}}`

**Workflow B — Ready to Build:**
1. Deal-based → Trigger: Deal stage changes to "Ready to Build"
2. Action: Send Webhook → POST → `DealReadyToBuildUrl`
3. Include `objectId = {{deal.hs_object_id}}`

### 4. Get Monday Board ID

Monday board ID is in the URL: `monday.com/boards/XXXXXXXXXX`  
Optional group ID: open board → right-click a group → copy link → extract ID from URL.

---

## Open Items Before Going Live

- [ ] Get all rep Dialpad user IDs: `GET https://dialpad.com/api/v2/users?api_key=YOUR_KEY`
- [ ] Get all HubSpot owner IDs: HubSpot → Settings → Users, or `GET /crm/v3/owners`
- [ ] Confirm HubSpot Lead object API path works for Gunner's account (newer portal feature)
- [ ] Verify Dialpad `PATCH /api/v2/contacts/{id}` exists — not confirmed in vault API reference
- [ ] Get Monday Jobs board ID + confirm group ID if using specific group
- [ ] Get Dialpad company ID: `GET /api/v2/company` or from Dialpad Admin portal
- [ ] Decide: should 5-min timer also count inbound calls from the customer? (Currently: outbound only)
- [ ] Decide: should all NJ pool exhaustion escalate to manager, or fall back to CT pool first?
- [ ] Add SMS subscription for each PM after deploy

---

## Related

- [[gunner/dialpad-hubspot-integration]] — Call/SMS logging to HubSpot (separate concern — logs after the fact)
- [[gunner/hubspot-leads-project]] — Full HubSpot leads buildout; this automation is workflow 7b + speed-to-lead
- [[vendors/dialpad-api-reference]] — Call payload fields, webhook setup, contacts API
- [[vendors/hubspot-api-reference]] — Contact/deal fetch, lead owner update
- [[vendors/monday-api-reference]] — GraphQL create_item, create_update syntax
