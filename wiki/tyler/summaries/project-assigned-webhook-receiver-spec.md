---
title: project.assigned Webhook Receiver Spec
type: summary
tags:
  - companycam
  - webhook
  - api
  - push-notifications
created: 2026-05-13T00:00:00.000Z
updated: 2026-05-13T00:00:00.000Z
sources:
  - project-assigned-webhook-receiver-spec.md
related:
  - '[[vendors/companycam]]'
  - '[[gunnerteam/gunner-forms-app]]'
status: evergreen
---

# project.assigned Webhook Receiver Spec

Implementation contract for the CompanyCam → GunnerTeam webhook. Sender lives in `WL-CompanyCam` (`feat/project-assigned-webhook`). Receiver goes in `gunnerteam-api` at `POST /companycam/webhook`.

## Endpoint

`POST http://3.134.224.29:3000/companycam/webhook`

Configured via `WEBHOOK_PROJECT_ASSIGNED_URL` on the sender side.

## Headers

| Header | Value |
|--------|-------|
| `X-CCam-Event` | `project.assigned` |
| `X-CCam-Signature` | `sha256=<64-char hex>` — HMAC-SHA256 of raw body |
| `X-CCam-Delivery` | UUID v4 — use for dedup |

## Payload Shape

```ts
type ProjectAssignedEvent = {
  event: "project.assigned";
  projectId: string;          // CC project UUID
  projectName: string;        // Address or project.name
  assignedUserEmail: string;  // User added to project
  assignedRole: "pm" | "sales" | "estimator" | "other";
  assignedAt: string;         // ISO-8601 UTC
  actorEmail: string;         // Who performed the assignment
  corporationId: string;      // Tenant UUID
};
```

## Signature Verification

> [!warning] Secret not stored in wiki — stored in EC2 `.env` as `WEBHOOK_SECRET`

Use `express.raw({ type: "application/json" })` — **not** `express.json()`. Sign the raw buffer bytes, not re-stringified JSON.

```js
const expected = "sha256=" + createHmac("sha256", process.env.WEBHOOK_SECRET)
  .update(rawBody).digest("hex");
// Use timingSafeEqual — avoids timing leak
```

## Handler Logic

- **Filter:** Only process `assignedRole === "pm"` — sender fires for all 4 roles intentionally (future-proofs sales/estimator notifications without sender redeploy)
- **Dedup:** On `X-CCam-Delivery` UUID — rare but possible duplicate deliveries
- **Self-assignment:** Already suppressed on sender side — no re-check needed
- **Return 200** even when no APNs token on file for the assigned user — keeps sender logs quiet

## Reliability Contract

- **No retry queue on sender.** Single attempt, 3s timeout. Events are lost on receiver downtime.
- **Must respond under 3s** — even on internal error, return fast to avoid sender timeout path.
- **Body ignored** — sender doesn't parse the response.

## Open Items

- `project.unassigned` event — sender can add if needed (request it)
- No key versioning on the shared secret — rotation requires a coordinated swap window

## Test Command

```sh
BODY='{"event":"project.assigned","projectId":"11111111-2222-3333-4444-555555555555","projectName":"12 Maple St","assignedUserEmail":"pm.user@gunnerroofing.com","assignedRole":"pm","assignedAt":"2026-05-13T14:32:00.000Z","actorEmail":"admin@gunnerroofing.com","corporationId":"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"}'

curl -i -X POST http://3.134.224.29:3000/companycam/webhook \
  -H "Content-Type: application/json" \
  -H "X-CCam-Event: project.assigned" \
  -H "X-CCam-Delivery: 11111111-1111-1111-1111-111111111111" \
  -H "X-CCam-Signature: sha256=cfdf1d0693295949ab7ebfb5349f119bbb8271d5e45dfa201a2bb3f1543a74ef" \
  --data-raw "$BODY"
```

Expected signature for the test body is documented in source spec (uses test secret, not prod).
