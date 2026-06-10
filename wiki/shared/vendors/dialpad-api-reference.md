---
title: Dialpad API Reference
type: vendor
tags: [dialpad, api, webhooks, integration, hubspot]
created: 2026-04-16
updated: 2026-04-16
status: stable
sources: [dialpadapi.json]
related:
  - "[[vendors/dialpad]]"
  - "[[vendors/hubspot]]"
  - "[[gunner/hubspot-leads-project]]"
---

# Dialpad API Reference

Extracted from `raw-sources/dialpadapi.json` (Dialpad API v2 full spec). Focused on webhook events, calls, SMS, contacts, and auth — everything needed for the HubSpot integration build.

---

## Authentication

### API Key (Simplest — use this for the integration)

Pass in query param or header:

```
GET /api/v2/call?api_key=<your_key>
Authorization: Bearer <your_key>
```

API keys are created in the Dialpad admin web portal. The associated user must have company admin permissions.

### OAuth2 (for user-facing apps)

Three grant types: Authorization Code, Refresh Token, Client Credentials.

**Required scopes for HubSpot integration:**
- `calls:list` — retrieve call history
- `recordings_export` — include recording URLs in call events
- `message_content_export` — include SMS message text in events

**Token response:**
```json
{
  "access_token": "string",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "string"
}
```

---

## Webhooks

### Setup Flow

1. Create a webhook endpoint (your receiver URL)
2. Create call/SMS subscriptions pointing to that endpoint
3. Verify JWT signatures on incoming payloads

### Create Webhook Endpoint

```
POST /api/v2/webhooks
```

```json
{
  "hook_url": "https://your-receiver.com/dialpad",
  "secret": "your_signing_secret"
}
```

**Response (`WebhookProto`):**
```json
{
  "id": "193",
  "hook_url": "https://your-receiver.com/dialpad",
  "signature": {
    "type": "jwt",
    "algo": "HS256",
    "secret": "your_signing_secret"
  }
}
```

Save the `id` — you'll use it as `endpoint_id` when creating subscriptions.

### Webhook Security

Payloads are signed as JWT (HS256) using your secret. **Always verify before processing.** If no secret is set, payloads are unsigned plain JSON.

---

## Call Event Subscriptions

### Create Subscription

```
POST /api/v2/subscriptions/call
```

```json
{
  "endpoint_id": 193,
  "call_states": ["connected", "hangup", "recording", "voicemail"],
  "enabled": true,
  "group_calls_only": false,
  "target_type": "user",
  "target_id": 12345
}
```

**Useful call_states for HubSpot logging:**
- `hangup` — call ended; use this to log completed calls
- `recording` — recording available
- `voicemail` — voicemail left
- `missed` — missed call (no answer)
- `transcription` — transcript ready

**Full available states:** `admin`, `admin_recording`, `ai_playbook`, `all`, `barge`, `blocked`, `call_transcription`, `calling`, `connected`, `csat`, `dispositions`, `hangup`, `hold`, `merged`, `missed`, `monitor`, `parked`, `pcsat`, `postcall`, `preanswer`, `queued`, `recap_action_items`, `recap_outcome`, `recap_purposes`, `recap_summary`, `recording`, `ringing`, `takeover`, `transcription`, `voicemail`, `voicemail_uploaded`

### Manage Subscriptions

```
GET    /api/v2/subscriptions/call
GET    /api/v2/subscriptions/call/{id}
PATCH  /api/v2/subscriptions/call/{id}
DELETE /api/v2/subscriptions/call/{id}
```

---

## Call Event Payload

Fired on each `call_states` event. Key fields for HubSpot:

```json
{
  "call_id": 1001,
  "event_timestamp": 1609459200000,
  "direction": "inbound",
  "state": "hangup",
  "duration": 120000,
  "total_duration": 145000,
  "date_started": 1609459200000,
  "date_connected": 1609459210000,
  "date_ended": 1609459320000,
  "external_number": "+12035551234",
  "internal_number": "+18662626005",
  "was_recorded": true,
  "call_recording_share_links": [
    "https://dialpad.com/recording/call/sharelink123"
  ],
  "recording_details": [
    {
      "duration": 120000,
      "recording_id": "rec_789",
      "recording_url": "https://dialpad.com/recording/call/...",
      "start_time": 1609459210000
    }
  ],
  "contact": {
    "id": "contact_123",
    "name": "John Doe",
    "phone": "+12035551234",
    "email": "john@example.com",
    "type": "contact_type"
  },
  "target": {
    "id": "target_456",
    "name": "Rep Name",
    "email": "rep@gunnerroofing.com",
    "type": "user"
  },
  "transcription_text": "Full transcript...",
  "voicemail_share_link": "https://dialpad.com/recording/voicemail/...",
  "labels": [],
  "mos_score": 4.2
}
```

**Field notes:**
- `duration` / `total_duration` — milliseconds; divide by 1000 for seconds
- `external_number` — the customer's phone number (E.164 format: `+1XXXXXXXXXX`)
- `contact.phone` — same as `external_number`; use for HubSpot contact lookup
- `date_*` fields — all milliseconds since epoch (UTC)
- `call_recording_share_links` — array; use `[0]` for first recording URL

---

## SMS Event Subscriptions

### Create Subscription

```
POST /api/v2/subscriptions/sms
```

```json
{
  "endpoint_id": 193,
  "direction": "all",
  "enabled": true,
  "include_internal": false,
  "status": false,
  "target_type": "user",
  "target_id": 12345
}
```

> **Note:** To receive message content (`text` field), your API key needs `message_content_export` scope.

**Direction options:** `all`, `inbound`, `outbound`

---

## SMS Event Payload

```json
{
  "id": 54321,
  "from_number": "+12035551234",
  "to_numbers": ["+18662626005"],
  "text": "Message content here",
  "created_date": "2026-04-16T14:30:00Z",
  "direction": "inbound",
  "message_status": "success",
  "message_delivery_result": "accepted",
  "user_id": 12345,
  "target_id": 67890,
  "target_type": "user",
  "contact_id": "contact_abc",
  "device_type": "web"
}
```

**Field notes:**
- `from_number` / `to_numbers` — E.164 format
- `created_date` — ISO 8601 string (unlike calls which use ms timestamps)
- `message_status` — `pending` / `success` / `failed`
- `text` — only present if `message_content_export` scope is granted
- For inbound: `from_number` = customer; for outbound: `to_numbers[0]` = customer

---

## Calls API

### List Calls

```
GET /api/v2/call
```

Query params: `started_after`, `started_before` (ms timestamps), `target_id`, `target_type`, `cursor`

Rate limit: 1200/min | Scope: `calls:list`

### Get Single Call

```
GET /api/v2/call/{id}
```

Retrieves the full record for a single call by its ID, returning the same fields as the call event payload.

### Get Transcript

```
GET /api/v2/transcripts/{call_id}
```

Response includes array of lines with speaker, content, and timestamp.

### Get Transcript URL

```
GET /api/v2/transcripts/{call_id}/url
```

Returns a direct link to the call review page in Dialpad.

---

## Contacts API

### List Contacts

```
GET /api/v2/contacts?cursor=...&include_local=true
```

Page size capped at 100.

### Get Contact by ID

```
GET /api/v2/contacts/{id}
```

Returns a single contact's full record by its Dialpad contact ID — see **Contact Fields** below for the response shape.

### Create Contact

Creates a contact from a name plus one or more phone numbers and emails.

```
POST /api/v2/contacts
Rate limit: 100/min
```

```json
{
  "first_name": "John",
  "last_name": "Doe",
  "phones": ["+12035551234"],
  "emails": ["john@example.com"],
  "company_name": "Acme Inc"
}
```

### Contact Fields

```json
{
  "id": "contact_123",
  "display_name": "John Doe",
  "first_name": "John",
  "last_name": "Doe",
  "company_name": "Acme Inc",
  "primary_phone": "+12035551234",
  "primary_email": "john@example.com",
  "phones": ["+12035551234"],
  "emails": ["john@example.com"],
  "type": "shared"
}
```

**Contact types:** `shared` (company-wide), `local` (user's personal contacts)

---

## HubSpot Integration — Build Notes

### Phone Number Normalization

Dialpad always uses E.164 (`+12035551234`). HubSpot stores numbers in various formats. Strip everything except digits and match on the last 10 digits:

```js
const normalize = (num) => num.replace(/\D/g, '').slice(-10);
```

### Call Logging Flow

On `hangup` webhook event:
1. Extract `contact.phone` or `external_number`
2. Search HubSpot contacts by phone (normalized)
3. Get associated open deals for that contact
4. Create HubSpot `call` engagement with:
   - Duration: `duration / 1000` (convert ms → seconds)
   - Recording URL: `call_recording_share_links[0]`
   - Direction: `direction`
   - Timestamp: `date_started`
5. Associate engagement with contact ID + deal ID(s)

### SMS Logging Flow

On SMS webhook event:
1. Extract customer number: inbound → `from_number`, outbound → `to_numbers[0]`
2. Search HubSpot contacts by phone (normalized)
3. Get associated open deals
4. Create HubSpot `note` engagement with SMS content
5. Associate with contact + deal

### Rate Limits Summary

| Endpoint | Limit |
|----------|-------|
| Most GET/POST | 1200/min |
| Create operations | 100/min |
| Call initiation | 5/min |

---

## Related

- [[vendors/dialpad]] — Vendor overview, Gunner usage, SSO status
- [[vendors/hubspot]] — CRM platform
- [[gunner/hubspot-leads-project]] — Lead object buildout; Dialpad integration is in scope
