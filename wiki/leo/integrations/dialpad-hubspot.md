---
type: reference
owner: leo
created: 2026-06-19
updated: 2026-06-19
tags: [dialpad, hubspot, integration, lambda]
status: active
related: ["[[gunnerteam/dialpad-hubspot-integration]]", "[[shared/vendors/dialpad]]"]
---

# Dialpad ↔ HubSpot — Lambda Engineering Detail

Lambda-level engineering notes for Leo's two live Dialpad↔HubSpot AWS Lambdas. For the higher-level vendor and integration overview, see the **Canonical references** at the bottom — this page does not duplicate that; it documents the deployed functions.

There are **TWO separate live Lambdas**, both in **us-east-2**, account **`980921733684`**, both writing to the **PRODUCTION HubSpot portal** (id `24467359`, parent of sandbox `51344449`):

| # | Lambda | Runtime | Concern | API GW | Dialpad webhook endpoint |
|---|--------|---------|---------|--------|--------------------------|
| 1 | `dialpad-hubspot-sync` | Python 3.12 | Owner assignment + intake sync | `h7lszv488h` | `6443584370057216` |
| 2 | `hubspot-dialpad-webhook` | Node 20 (arm64) | Call + SMS activity logger | `25xqc5a3ai` | `6414969028812800` |

> **Deploy both via zip → `aws lambda update-function-code`. Do NOT use the `hs` CLI** — it only auths to the **sandbox** portal, never prod.

---

## Lambda 1 — `dialpad-hubspot-sync` (owner assignment + intake sync)

- **Runtime:** Python 3.12 · **Repo:** `GunnerRoofing/dialpad-hubspot-sync` · local `~/dialpad-hubspot-sync`
- **Endpoint:** `https://h7lszv488h.execute-api.us-east-2.amazonaws.com/`
- **Webhook body:** base64-encoded **JWT (HS256)**. Caller phone is in `external_number`; agent email is in `target.email`.
- **Routes:** `POST /` (Dialpad webhooks), `POST /hs-sync` (HubSpot workflow trigger).
- **Dependencies:** `requests`, `PyJWT` (both pure Python — `pip install` on macOS is safe, no compiled extensions).
- **Flipped to PROD 2026-06-05.** `HUBSPOT_ACCESS_TOKEN` now holds the production token; `DRY_RUN=false`. Prod private app widened to add `crm.objects.owners.read` + `crm.objects.contacts.write`.

### Flow 1 — Dialpad → HubSpot (owner assignment)
- **Direct call (ringing):** customer calls agent's personal Dialpad number → JWT webhook `state=ringing`, `target.type=user` → find/create HubSpot contact by phone (E.164) → set agent as owner, **always overwrites**.
- **New Customer callcenter (connected):** customer hits main line → routed to queue → agent answers → `state=connected` with `entry_point_call_id` set → find/create contact → set agent as owner **only if contact has no existing owner**.
- **Callcenter direction quirk:** callcenter calls report `direction=outbound` (Dialpad dials out to the agent). Do **not** filter on `direction=inbound` for that path.

### Internal agent-to-agent call guard (FIXED 2026-06-09, PR #2, deployed)
Internal calls no longer create employee contacts. A caller is treated as internal when `external_number` is in the cached set of our Dialpad users' phone numbers (`GET /api/v2/users`, hourly TTL, fail-open) **or** the payload has `is_internal`. When internal, the sync is skipped.
- **Still TODO:** clean up employee contacts created *before* this fix.

### Flow 2 — HubSpot → Dialpad (intake sync), uid-based upsert (FIXED 2026-06-05)
HubSpot workflow fires `POST /hs-sync` with `{"contactId": "{{contact.hs_object_id}}"}` on changes to `firstname`, `lastname`, `email`, `address`, `city`, `state`, `zip` (`phone` and `hubspot_owner_id` excluded to avoid sync loops).

The old path was broken two ways: (1) a dead API key, and (2) `find_dialpad_contact` relied on `GET /api/v2/contacts?phone=` — **Dialpad ignores the `?phone=` query**, returning the most-recently-modified contact, so it overwrote the **wrong** contact. Rewritten to `PUT /api/v2/contacts` with `uid=<HubSpot contactId>`: idempotent upsert, no phone search, no dupes. `find_dialpad_contact` was deleted. The **Make.com HS→Dialpad scenario is now OFF** — this Lambda is the **sole** HS→Dialpad writer.

Field mapping: `firstname→first_name`, `lastname→last_name`, `phone→phones[]` (E.164), `email→emails[]`, `address+city+state+zip→company_name` (concatenated). Only populated fields are sent; partial updates are safe.

### Environment variables
`HUBSPOT_ACCESS_TOKEN` (production token, portal `24467359`), `DIALPAD_API_KEY`, `DIALPAD_WEBHOOK_SECRET` (HS256 JWT signing secret), `DRY_RUN` (currently `false`).

### Webhook subscriptions
Webhook endpoint id `6443584370057216`. Office-level `ringing` subs (Cromwell, Stamford, Mt. Arlington) + per-user `connected` subs for the callcenter agents. New Customer callcenter id `6591987966943232`. Office subscriptions don't cover super admins — use user-level subs for all agents.

### Deploy
```bash
rm -rf package dialpad-hubspot-sync.zip && mkdir package
pip3 install -r requirements.txt -t package/
cp lambda_function.py package/
cd package && zip -r ../dialpad-hubspot-sync.zip . && cd ..
aws lambda update-function-code \
  --function-name dialpad-hubspot-sync \
  --zip-file fileb://dialpad-hubspot-sync.zip \
  --region us-east-2
```

### Parked
**Missed-callcenter available-agent assignment** — approved direction, not built. When a New Customer callcenter call is MISSED, assign the native-created HubSpot contact to a Dialpad-*available* agent. Needs a NEW callcenter `hangup` subscription (only `connected` + `ringing` are subscribed today). Availability signal = `is_on_duty && on_duty_status == 'available'`.

---

## Lambda 2 — `hubspot-dialpad-webhook` (the real call + SMS activity logger)

- **Runtime:** Node 20, **arm64** · **Repo:** `GunnerRoofing/hubspot-dialpad` · local `~/hubspot-dialpad`
- **Endpoint:** API Gateway `25xqc5a3ai` (us-east-2) · **Timeout:** 30s
- **Webhook body:** **plain JSON** (not JWT).
- **API client:** `@hubspot/api-client` v13, 429 backoff configured `numberOfApiCallRetries: 6`.
- **Auth:** `HUBSPOT_ACCESS_TOKEN` (production token, portal `24467359`).
- **Deploy:** `./deploy.sh` (zip → `aws lambda update-function-code`, us-east-2).

### Call logging
- Fires on `state=hangup` → creates a HubSpot **call record**, associates it to the contact **+ the most-recent deal**.
- Skips callcenter / coaching entry-point legs. Dedups on `hs_call_external_id`.
- **INTENTIONAL double-log:** runs *alongside* the native integration as a resilience backup (native breaks sometimes). **This call duplication is BY DESIGN — do NOT "fix" it.**

### SMS logging — daily-thread rollup (mimics native)
`handleSmsEvent`:
1. Resolve customer number → `lookupContact` by phone.
2. Build `threadKey = dpthread-<contactId>-<YYYYMMDD eastern>`, stored in `hs_engagement_source_id`.
3. Find today's thread comm for that contact: **found** → append a line (dedup on the whole rendered line); **not found** → create the thread communication + associate to contact (assoc type `81`) and to deal (assoc type `85`).
4. Line format: `<strong>Name</strong> <em>[MM/DD/YYYY, HH:MM ET]</em>: text`.
- **Unknown sender** → `createMinimalContact` builds a minimal phone-only contact (PR #1, deployed).
- **Contact lookup (`lookupContact`):** phone is primary — search `phone` OR `mobilephone`, normalized to E.164 via `normalizePhone`; `dialpad_id` is fallback only.
- Outbound SMS owner assignment confirmed working 2026-06-11 (Dialpad SMS payloads include `target.email`).

### ROOT CAUSE of the long SMS-not-logging saga
The old Dialpad key lacked the **`message_content_export`** scope, so SMS arrived **bodyless** and were dropped as status events. Fixed by **recreating** the SMS subscription under a NEW content-export-capable key (`t2kjCR…` — masked). **Content access follows the key that CREATED the subscription** — recreate the sub under a content-export key; do NOT just edit scopes on the existing one.

### SMS cutover — DONE 2026-06-09
Native "Log SMS as activities" turned **OFF** — our logger is the **sole** SMS logger. Unknown-sender minimal-contact creation added; 429 backoff (`numberOfApiCallRetries: 6`) in place.

### Webhook subscriptions
Webhook endpoint id `6414969028812800`. One SMS subscription: id `5205923015237632`, direction `all`, created under the content-export-enabled key (`t2kjCR…`).

### Environment variables
`HUBSPOT_ACCESS_TOKEN` (production token, portal `24467359`).

### Cleanup pending
- ~17 orphaned `[Sales Team]` communications from the old SMS create-path (no new ones being created now).
- Residual dup-contact risk from native Dialpad contact auto-creation (`src 187422`) — toggle off to fully resolve.

---

## Cross-cutting gotchas (both Lambdas)

- **AWS SCP blocks public Lambda Function URLs** on this account — **API Gateway is required**.
- **HubSpot CRM search rate limit ~4 req/sec** (shared). Lambda 1 uses exponential backoff (up to 4 retries); Lambda 2 uses `@hubspot/api-client` with `numberOfApiCallRetries: 6`.
- **Other (non-ours) SMS consumers:** Dialpad also fans SMS out to a Make.com webhook and a typo'd domain (`gunnerrofing.com/smslogging`). These are not ours.
- **`hs` CLI auths only to sandbox** — never deploy either Lambda with it.
- **Never store full Dialpad API keys** — reference by short prefix only (e.g. `t2kjCR…`).

## Not the live system

The HubSpot Projects app literally named `dialpad-sms-to-deals` at `~/Dialpad-Hubspot` (`NewEndpointFunction.js`, platform `2026.03`, Private) is an **OLD / UNUSED** version, kept for reference only. The live call/SMS logger is the `hubspot-dialpad-webhook` Lambda documented above.

---

## Canonical references

For the vendor and integration overview (do not duplicate here):

- [[gunnerteam/dialpad-hubspot-integration]] — Dialpad → HubSpot integration architecture (call/SMS logging, association type IDs, Monday layer).
- [[shared/vendors/dialpad]] — Dialpad vendor page (VoIP usage, SSO, audit, support).
- [[shared/vendors/hubspot]] — HubSpot vendor page (CRM usage, pipeline, integrations table).
