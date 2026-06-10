---
title: Monday.com API Reference
type: vendor
tags: [monday, api, graphql, integration, dialpad]
created: 2026-04-16
updated: 2026-04-16
status: stable
sources: [developer.monday.com]
related:
  - "[[vendors/monday]]"
  - "[[vendors/dialpad-api-reference]]"
  - "[[vendors/hubspot-api-reference]]"
  - "[[gunner/hubspot-leads-project]]"
---

# Monday.com API Reference

Focused on the operations needed for a Dialpad → Monday.com integration: finding items by phone, creating items, and updating column values. Fetched from developer.monday.com April 2026.

---

## Authentication

**Base URL:** `https://api.monday.com/v2`

**Header:**
```
Authorization: <your-api-token>
Content-Type: application/json
```

> Note: No `Bearer` prefix — just the raw token.

### Getting Your Token

Profile picture (top right) → **Developers** → **API token** → **Show**

Token permissions mirror your UI access level. For an integration that creates/reads items across boards, use an admin token.

**Rate limits:** 10M complexity points/month; 25,000 automation/integration actions/month. Complexity cost is returned in each response — monitor it.

---

## Making Requests

All requests are POST to the base URL with a JSON body:

```json
{
  "query": "your graphql query or mutation here",
  "variables": { }
}
```

Or with variables separated:

```javascript
const response = await fetch('https://api.monday.com/v2', {
  method: 'POST',
  headers: {
    'Authorization': process.env.MONDAY_API_TOKEN,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ query, variables })
});
```

---

## 1. Search Items by Column Value

Use `items_page` with `query_params` to find items where a column matches a value (e.g. find a lead by phone number).

```graphql
query ($board_id: ID!, $phone: String!) {
  boards(ids: [$board_id]) {
    items_page(
      limit: 10
      query_params: {
        rules: [
          {
            column_id: "phone"
            compare_value: [$phone]
            operator: any_of
          }
        ]
        operator: and
      }
    ) {
      cursor
      items {
        id
        name
        column_values {
          id
          text
          value
        }
      }
    }
  }
}
```

**Variables:**
```json
{
  "board_id": "1234567890",
  "phone": "2035551234"
}
```

**Operators available:** `any_of`, `not_any_of`, `contains_text`, `not_contains_text`, `between`

**Limits:** Max 500 items per request. Cannot combine `query_params` and `cursor` in the same request — use `query_params` for first page, `cursor` for subsequent pages.

### Pagination

```graphql
query ($board_id: ID!, $cursor: String!) {
  boards(ids: [$board_id]) {
    items_page(limit: 100, cursor: $cursor) {
      cursor
      items {
        id
        name
      }
    }
  }
}
```

---

## 2. Get Item by ID

```graphql
query {
  items(ids: [1234567890]) {
    id
    name
    column_values {
      id
      text
      value
    }
  }
}
```

Up to 100 IDs per request.

---

## 3. Create Item

```graphql
mutation ($board_id: ID!, $group_id: String!, $item_name: String!, $column_values: JSON!) {
  create_item(
    board_id: $board_id
    group_id: $group_id
    item_name: $item_name
    column_values: $column_values
    create_labels_if_missing: true
  ) {
    id
    name
  }
}
```

**Variables:**
```json
{
  "board_id": "1234567890",
  "group_id": "new_leads",
  "item_name": "John Doe — Inbound Call",
  "column_values": "{\"phone\": \"+12035551234\", \"status\": {\"label\": \"New\"}, \"date4\": {\"date\": \"2026-04-16\"}, \"text\": \"Inbound call from Dialpad\"}"
}
```

> `column_values` must be a **JSON string** (not an object) — use `JSON.stringify()`.

**`create_labels_if_missing: true`** — auto-creates status/dropdown labels that don't exist yet. Useful during initial setup.

---

## 4. Update Column Values

### Single Column

Updates one column on a single item — use `change_column_value` when only one field changes:

```graphql
mutation ($board_id: ID!, $item_id: ID!, $column_id: String!, $value: JSON!) {
  change_column_value(
    board_id: $board_id
    item_id: $item_id
    column_id: $column_id
    value: $value
  ) {
    id
  }
}
```

### Multiple Columns (preferred — fewer API calls)

```graphql
mutation ($board_id: ID!, $item_id: ID!, $column_values: JSON!) {
  change_multiple_column_values(
    board_id: $board_id
    item_id: $item_id
    column_values: $column_values
  ) {
    id
  }
}
```

**Variables:**
```json
{
  "board_id": "1234567890",
  "item_id": "9876543210",
  "column_values": "{\"status\": {\"label\": \"Called\"}, \"date4\": {\"date\": \"2026-04-16\"}, \"text_notes\": \"Spoke with customer re: roof estimate\"}"
}
```

---

## Column Value JSON Formats

Column values are always passed as a **JSON string**. Here are the formats for common column types:

### Text Column
```json
"column_id": "Some text value"
```

Plain string — pass the value directly with no wrapper object.

### Status Column
```json
"status": { "label": "In Progress" }
```
Or by index:
```json
"status": { "index": 1 }
```

### Date Column
```json
"date4": { "date": "2026-04-16" }
```
With time:
```json
"date4": { "date": "2026-04-16", "time": "14:30:00" }
```

### Phone Column
```json
"phone": "+12035551234"
```
Or with country code object (consult `get_column_type_schema` for your board's phone column format if simple string doesn't work):
```json
"phone": { "phone": "+12035551234", "countryShortName": "US" }
```

### Long Text Column
```json
"long_text": { "text": "Multi-line note content here" }
```

Wrap the content in a `text` object; unlike a plain Text column, the value is not a bare string.

### People Column (assign to user)
```json
"person": { "personsAndTeams": [{ "id": 9603417, "kind": "person" }] }
```

---

## 5. Get Column IDs for a Board

You need the column `id` (not the display name) to update values. Get them once per board:

```graphql
query {
  boards(ids: [1234567890]) {
    columns {
      id
      title
      type
    }
  }
}
```

Save these — column IDs don't change unless you delete and recreate the column.

---

## Integration Flow for Dialpad

### On Call Event (`hangup`)

On a Dialpad `hangup` webhook, match the caller to a board item by phone and either update it or create a new lead:

```
1. Search items_page on the CRM/Leads board — find item by phone column
2. If found: change_multiple_column_values — update last_called date, call_count, notes
3. If not found: create_item — new lead row with name, phone, source="Dialpad Inbound"
```

### On SMS Event

```
1. Search items_page — find item by phone
2. If found: append to notes column (read current value, append new SMS text)
3. If not found: create_item — new row with phone + SMS content as note
```

---

## Common Gotchas

- **Column values must be JSON strings** — always `JSON.stringify()` the object before sending
- **Board and item IDs are integers** but GraphQL accepts them as `ID` type (string or int both work in variables)
- **`query_params` and `cursor` cannot be combined** — separate first-page and paginated queries
- **Phone column format varies** — try simple string first; if it fails, use the object format with `countryShortName`
- **Complexity budget** — each query has a complexity cost returned in the response; watch it on high-volume integrations
- **Column IDs are board-specific** — hardcode them per board after running the columns query once

---

## Related

- [[vendors/monday]] — Vendor overview, Gunner usage
- [[vendors/dialpad-api-reference]] — Dialpad webhook payloads
- [[vendors/hubspot-api-reference]] — HubSpot engagements + contact search
- [[gunner/hubspot-leads-project]] — Lead object buildout project
