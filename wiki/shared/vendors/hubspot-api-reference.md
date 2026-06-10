---
title: HubSpot API Reference
type: vendor
tags: [hubspot, api, integration, dialpad, crm]
created: 2026-04-16
updated: 2026-04-16
status: stable
sources: [developers.hubspot.com]
related:
  - "[[vendors/hubspot]]"
  - "[[vendors/dialpad-api-reference]]"
  - "[[vendors/monday-api-reference]]"
  - "[[gunner/hubspot-leads-project]]"
---

# HubSpot API Reference

Focused on the four endpoints needed for the Dialpad → HubSpot integration: contact search by phone, deal associations, call logging, and SMS/note logging. Fetched from developers.hubspot.com April 2026.

> **API versioning note:** HubSpot introduced date-based versioning in 2026-03 (replaces `/crm/v3/` paths with `/crm/objects/2026-03/`). Some endpoints below still use v3 paths — verify against live docs if you hit 404s.

---

## Authentication

Use a **Private App token** (recommended over API keys):

1. HubSpot → Settings → Integrations → Private Apps → Create
2. Grant scopes: `crm.objects.contacts.read`, `crm.objects.contacts.write`, `crm.objects.deals.read`, `crm.objects.deals.write`
3. Copy the token

Pass in every request:
```
Authorization: Bearer <your-private-app-token>
Content-Type: application/json
```

**Rate limit:** 5 requests/second per account (search endpoint)

---

## 1. Search Contacts by Phone Number

```
POST /crm/objects/2026-03/contacts/search
```

### Phone Number Gotcha

HubSpot normalizes phone numbers into a calculated property: `hs_searchable_calculated_phone_number`. It strips the country code and uses only the area code + local number (last 10 digits). Search against this property, not `phone`.

```json
{
  "filterGroups": [
    {
      "filters": [
        {
          "propertyName": "hs_searchable_calculated_phone_number",
          "operator": "EQ",
          "value": "2035551234"
        }
      ]
    }
  ],
  "properties": ["firstname", "lastname", "email", "phone", "hs_object_id"],
  "limit": 5
}
```

Strip everything non-numeric and take the last 10 digits before searching:
```js
const searchPhone = phone.replace(/\D/g, '').slice(-10);
```

### Response

```json
{
  "total": 1,
  "results": [
    {
      "id": "12345",
      "properties": {
        "firstname": "John",
        "lastname": "Doe",
        "email": "john@example.com",
        "phone": "(203) 555-1234",
        "hs_object_id": "12345"
      },
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-06-01T00:00:00Z"
    }
  ],
  "paging": {
    "next": {
      "after": "10"
    }
  }
}
```

Use `results[0].id` as your contact ID for subsequent calls.

---

## 2. Get Deals Associated with a Contact

```
GET /crm/objects/2026-03/contact/{contactId}/associations/deal
```

No request body needed.

### Response

```json
{
  "results": [
    {
      "toObjectId": 67890,
      "associationTypes": [
        {
          "category": "HUBSPOT_DEFINED",
          "typeId": 4,
          "label": "Contact to deal"
        }
      ]
    }
  ]
}
```

Extract `results[].toObjectId` — these are your deal IDs. For the integration, use the most recent open deal (requires a separate deal fetch to check stage/close date) or associate with all open deals.

**Association type IDs:**
- Contact → Deal: `4`
- Deal → Contact: `3`

---

## 3. Create Call Engagement

```
POST /crm/v3/objects/calls
```

Associates the call with a contact and deal in a single request via the `associations` array.

### Request Body

Send the call's `properties` along with an `associations` array that links it to the contact and deal in one request:

```json
{
  "properties": {
    "hs_timestamp": "2026-04-16T14:30:00Z",
    "hs_call_title": "Inbound call — John Doe",
    "hs_call_body": "Optional notes or transcript excerpt",
    "hs_call_duration": "120000",
    "hs_call_direction": "INBOUND",
    "hs_call_status": "COMPLETED",
    "hs_call_from_number": "+12035551234",
    "hs_call_to_number": "+18662626005",
    "hs_call_recording_url": "https://dialpad.com/recording/call/...",
    "hs_call_source": "INTEGRATIONS_PLATFORM",
    "hubspot_owner_id": "11349275"
  },
  "associations": [
    {
      "to": { "id": "12345" },
      "types": [{ "associationCategory": "HUBSPOT_DEFINED", "associationTypeId": 194 }]
    },
    {
      "to": { "id": "67890" },
      "types": [{ "associationCategory": "HUBSPOT_DEFINED", "associationTypeId": 206 }]
    }
  ]
}
```

### Property Reference

| Property | Type | Required | Notes |
|----------|------|----------|-------|
| `hs_timestamp` | String | Yes | ISO 8601 or Unix ms — sets position on timeline |
| `hs_call_duration` | String | No | Milliseconds as string |
| `hs_call_direction` | Enum | No | `INBOUND` or `OUTBOUND` |
| `hs_call_status` | Enum | No | `COMPLETED`, `NO_ANSWER`, `FAILED`, `IN_PROGRESS`, `CANCELED` |
| `hs_call_from_number` | String | No | Caller phone |
| `hs_call_to_number` | String | No | Recipient phone |
| `hs_call_recording_url` | String | No | Must be HTTPS; `.mp3` or `.wav` only |
| `hs_call_source` | String | No | Set to `INTEGRATIONS_PLATFORM` to enable recordings |
| `hs_call_body` | String | No | Notes / transcript |
| `hs_call_title` | String | No | Displayed name of the call |
| `hubspot_owner_id` | String | No | HubSpot user ID of the rep |

### Association Type IDs (for calls)

| Association | typeId |
|-------------|--------|
| Call → Contact | `194` |
| Call → Deal | `206` |

> Verify these IDs against your HubSpot instance — custom association types may differ.

### Response

Returns the created call object with its `id` for future reference.

---

## 4. Create Note Engagement (for SMS logging)

```
POST /crm/v3/objects/notes
```

Use notes to log inbound/outbound SMS messages.

### Request Body

Send the note's `properties` with an `associations` array linking it to the contact and deal:

```json
{
  "properties": {
    "hs_timestamp": "2026-04-16T14:35:00Z",
    "hs_note_body": "SMS (inbound) from +12035551234:\n\nHey, I'm interested in getting a quote for my roof.",
    "hubspot_owner_id": "11349275"
  },
  "associations": [
    {
      "to": { "id": "12345" },
      "types": [{ "associationCategory": "HUBSPOT_DEFINED", "associationTypeId": 202 }]
    },
    {
      "to": { "id": "67890" },
      "types": [{ "associationCategory": "HUBSPOT_DEFINED", "associationTypeId": 214 }]
    }
  ]
}
```

### Property Reference

| Property | Required | Notes |
|----------|----------|-------|
| `hs_timestamp` | Yes | Sets timeline position |
| `hs_note_body` | No | Max 65,536 characters |
| `hubspot_owner_id` | No | HubSpot user ID |

### Association Type IDs (for notes)

| Association | typeId |
|-------------|--------|
| Note → Contact | `202` |
| Note → Deal | `214` |

---

## Integration Flow Summary

### Call Logging (on Dialpad `hangup` event)

Triggered when Dialpad sends a `hangup` webhook; resolves the caller to a HubSpot contact and deal, then logs a call engagement:

```
1. Normalize phone: strip non-digits, take last 10
2. POST /crm/objects/2026-03/contacts/search — find contact by phone
3. GET /crm/objects/2026-03/contact/{id}/associations/deal — get deal IDs
4. POST /crm/v3/objects/calls — create call with both contact + deal in associations[]
```

### SMS Logging (on Dialpad SMS event)

Triggered on each Dialpad SMS webhook; resolves the customer to a HubSpot contact and deal, then logs the message as a note:

```
1. Extract customer phone: inbound → from_number, outbound → to_numbers[0]
2. Normalize phone: strip non-digits, take last 10
3. POST /crm/objects/2026-03/contacts/search — find contact
4. GET /crm/objects/2026-03/contact/{id}/associations/deal — get deal IDs
5. POST /crm/v3/objects/notes — create note with SMS content, associate with contact + deal
```

### No Contact Found

If the phone number returns no contact results, options:
- Create a new contact with the phone number and log the call to it
- Log to a catch-all "Unknown Caller" contact
- Drop the event and log to a queue for manual review

---

## Rate Limits

| Limit | Value |
|-------|-------|
| Search requests | 5/second per account |
| Max search results | 10,000 per query |
| Max filters | 18 across 5 filterGroups |

---

## Related

- [[vendors/hubspot]] — Vendor overview, Gunner usage
- [[vendors/dialpad-api-reference]] — Dialpad webhook payloads (call + SMS)
- [[vendors/monday-api-reference]] — Monday.com GraphQL API
- [[gunner/hubspot-leads-project]] — Lead object buildout; Dialpad integration in scope
