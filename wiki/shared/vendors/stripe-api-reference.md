---
title: "Stripe API Reference"
type: vendor
tags: [stripe, api, payments, integration]
created: 2026-04-21
updated: 2026-04-21
sources: [Stripe API Reference.pdf]
related:
  - "[[vendors/hubspot-api-reference]]"
  - "[[vendors/dialpad-api-reference]]"
  - "[[vendors/monday-api-reference]]"
status: stable
---

# Stripe API Reference

Gunner has a Stripe account (Gunner CT Sandbox active as of 2026-04-08). Reference for building payment integrations.

## Core Info

- **Base URL:** `https://api.stripe.com`
- **Current version:** `2026-03-25.dahlia`
- **Format:** REST, JSON responses, standard HTTP codes
- **Auth:** API key as basic auth username (`-u sk_live_...:`)
  - Test keys: `sk_test_` prefix
  - Live keys: `sk_live_` prefix

## Authentication

```bash
curl https://api.stripe.com/v1/charges \
  -u sk_test_51TJEuk...aX008lActLEr:
# colon at end prevents curl from asking for a password
```

All requests must be HTTPS. Never put secret keys in client-side code or GitHub.

## Key Objects

| Object | Description |
|--------|-------------|
| Customer | `cus_` prefix — represents a Gunner customer/homeowner |
| Charge | `ch_` prefix — a payment attempt |
| PaymentIntent | `pi_` prefix — represents the intent to collect payment |
| Refund | Refund on a charge |
| Subscription | Recurring billing |
| Account | `acct_` prefix — Stripe account |

## HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK |
| 400 | Bad Request — missing required param |
| 401 | Unauthorized — no valid API key |
| 402 | Request Failed — valid params, request failed |
| 403 | Forbidden — API key lacks permissions |
| 404 | Not Found |
| 409 | Conflict — idempotency key reuse mismatch |
| 424 | External Dependency Failed |
| 429 | Rate limited — use exponential backoff |
| 500–504 | Server errors (rare) |

## Error Types

| Type | When |
|------|------|
| `api_error` | Stripe server problem — uncommon |
| `card_error` | Card can't be charged — most common |
| `idempotency_error` | Idempotency key reused with different params |
| `invalid_request_error` | Invalid parameters |

Error response includes: `code`, `decline_code`, `message`, `param`, `type`

## Metadata

Attach up to 50 key-value pairs to any object (Customer, Charge, PaymentIntent, Refund, etc.):

```bash
curl https://api.stripe.com/v1/customers \
  -u sk_test_...: \
  -d "metadata[order_id]=6735"
```

Use cases: link internal job IDs to Stripe customers, store refund reasons, annotate charges.

## Pagination

Cursor-based. All list endpoints accept:
- `limit` — 1–100, default 10
- `starting_after` — object ID cursor (next page)
- `ending_before` — object ID cursor (previous page)

List response: `{ object: "list", data: [...], has_more: bool, url: "..." }`

## Search

Available on charges, customers, subscriptions:
- `query` — search query string
- `limit` — 1–100, default 10
- `page` / `next_page` — cursor

Search response: `{ object: "search_result", data: [...], has_more: bool, next_page: ... }`

## Idempotency

Add `Idempotency-Key` header to POST requests for safe retries:

```bash
curl https://api.stripe.com/v1/customers \
  -u sk_test_...: \
  -H "Idempotency-Key: KG5LxwFBepaKHyUD" \
  -d description="Customer name"
```

Keys expire after 24 hours. Use V4 UUIDs. Don't use on GET or DELETE.

## Expanding Responses

Request related objects inline with `expand[]`:

```bash
curl https://api.stripe.com/v1/charges/ch_xxx \
  -u sk_test_...: \
  -d "expand[]=customer" \
  -d "expand[]=payment_intent.customer" \
  -G
```

Max depth: 4 levels (e.g. `data.payment_intent.customer.default_source`)

## Versioning

- Each major release (e.g. "Acacia") is breaking — requires code updates
- Monthly releases are backward-compatible
- Upgrade version in Stripe Workbench
- Current: `2026-03-25.dahlia`
