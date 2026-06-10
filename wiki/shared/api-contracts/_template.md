---
type: api-contract
provider: <provider-app-or-service>
consumer: <consumer-app>
status: draft
created: 2026-06-10
---

# <Provider> → <Consumer> API Contract

## Overview

What this integration does and why it exists. One or two sentences on the data that
flows and which direction.

## Endpoints / Events

| Method / Event | Path / Topic | Purpose |
|---|---|---|
| `GET` | `/example` | ... |

## Schema

Request/response or event payload shapes. Note required vs optional fields and any
fields that are nullable or frequently empty.

```json
{}
```

## Auth

How the consumer authenticates (token, API key, signed webhook, IAM, etc.) and where
credentials live.

## Versioning Notes

Current version, how breaking changes are handled, and any deprecations in flight.

## Consumers

Who/what depends on this contract. Update [[../../hot.md]] **Recent Cross-Team Changes**
when this list changes.

## Open Issues

Known gaps, bugs, or pending decisions. Promote anything cross-cutting to a
[[../decisions/README|decision record]].
