---
type: runbook
title: GunnerTeam — Dialpad Subscription Setup
created: '2026-06-29'
updated: '2026-06-29'
tags: [gunner, gunnerteam, runbook, dialpad, voip, webhook]
status: stable
source: Gunner Team App/runbooks/dialpad-subscription-runbook.md
related: ["[[gunnerteam/gunnerteam-project-structure]]", "[[index]]"]
---

# Dialpad subscription setup — manual runbook

Not a cc-prompt — these are Dialpad-admin / Dialpad API actions, run **after cc-2803 is live**
(the `/dialpad/webhook` route must answer 200 to a signed event first). The webhook `secret` here
must be the **exact** value stored at SSM `/gunnerteam/dev/DIALPAD_WEBHOOK_SECRET` (cc-2802) —
mismatch = silent 401 on every event (same failure mode as the points-token incident).

Company target id: `5856584867102720`. Region/host: `https://api.dialpad.com`.

## Secret handling
Keep the webhook secret in Keeper. Load it into the shell via `read -rs` (never echo / never in
history). Same for the Dialpad API key used as the bearer below.
```bash
read -rs -p "DIALPAD_API_KEY: " DP_API; echo
read -rs -p "DIALPAD_WEBHOOK_SECRET: " DP_HOOK; echo
```

## 1. API key — ALL four export scopes
Dialpad admin → Integrations → Developer → API Keys → create a key with **all** of:
- `message_content_export` → SMS bodies
- `recordings_export` → call `recording_url`s
- `transcription` → call transcripts
- `recap` → AI recap (summary + action items)

Use it as `DIALPAD_API_KEY`. (Confirm exact scope strings in Dialpad admin — names above are per Leo.)

> ★ Body access is **scope-gated, not order-gated** (confirmed by Leo, who operates the existing
> integrations 2026-06-26). Content follows the `message_content_export` scope on the key that
> created the subscription — **independent of subscription order**. So this logger gets full bodies
> as a co-subscriber alongside `hubspot-dialpad`; there is **no "primary slot" to take and nothing to
> displace.** (Doug's "first-subscriber" model was a misdiagnosis.) Provision freely.
>
> This same key also backs the runtime **pull/download** path (recording rehost, transcript/recap
> pulls), so store it in SSM as a secret (`DIALPAD_API_KEY`) for the Lambda — see cc-2812.

## 2. Create the webhook endpoint  — MUST include the signing secret
★ **The JWT signing secret lives on the WEBHOOK, not the subscription.** Pass `secret` here (= the
SSM `DIALPAD_WEBHOOK_SECRET`); the response must come back with `signature: { algo: HS256, type: jwt
}`. If you omit it, the webhook stays unsigned → Dialpad sends plain/unsigned payloads → the route's
JWT verify rejects everything (`bad_signature` alarm). The `secret` field on the SMS/call
subscriptions is NOT used for signing — don't rely on it.
```bash
API_BASE_URL=$(aws ssm get-parameter --name /gunnerteam/dev/API_BASE_URL \
  --region us-east-2 --query 'Parameter.Value' --output text)

curl -s -X POST https://dialpad.com/api/v2/webhooks \
  -H "Authorization: Bearer $DP_API" -H 'Content-Type: application/json' \
  -d "{\"hook_url\":\"$API_BASE_URL/dialpad/webhook\",\"secret\":\"$DP_HOOK\"}"
# → response must show "signature":{"algo":"HS256","type":"jwt"}; copy the "id" into WEBHOOK_ID
# (already-created webhook? PATCH it: curl -X PATCH …/webhooks/<id> -d '{"secret":"'"$DP_HOOK"'"}')
```
```bash
WEBHOOK_ID="<id from above>"
```

## 3. SMS subscription (includes delivery-status events)
```bash
curl -s -X POST https://dialpad.com/api/v2/subscriptions/sms \
  -H "Authorization: Bearer $DP_API" -H 'Content-Type: application/json' \
  -d "{\"webhook_id\":\"$WEBHOOK_ID\",\"secret\":\"$DP_HOOK\",\"status\":true,\"direction\":\"all\"}"
```

## 4. Call subscription (incl. transcript + recap states)
Per Leo (confirmed 2026-06-26): transcript + recap are **call states** (`call_transcription`,
`recap_summary`) on the **same** call subscription — not separate event types/endpoints. They fire
**after** the call (Ai post-processing), not at hangup.
```bash
curl -s -X POST https://dialpad.com/api/v2/subscriptions/call \
  -H "Authorization: Bearer $DP_API" -H 'Content-Type: application/json' \
  -d "{\"webhook_id\":\"$WEBHOOK_ID\",\"secret\":\"$DP_HOOK\",\"call_states\":[\"hangup\",\"missed\",\"voicemail_uploaded\",\"recording\",\"call_transcription\",\"recap_summary\"]}"
```

> ⚠️ **Prerequisite: Dialpad Ai must be ENABLED on the lines you care about.** Transcript/recap only
> exist if Ai (and recording) is on for the call — no Ai = no transcript/recap event, regardless of
> scope. Confirm Ai is on org-wide before relying on these.
>
> **Backfill:** `GET /api/v2/transcripts/{call_id}` (+ `/transcripts/{call_id}/url`) pulls the
> transcript for any call the webhook misses; recap is re-pullable too. cc-2814 adds this as a
> safety net.

```bash
unset DP_API DP_HOOK
```

## 5. End-to-end verify
Send a real test SMS to/from a Dialpad line, then confirm the row landed (uses the `_sql` invoke,
MIGRATION_SECRET as in cc-2801):
```bash
MIGRATION_SECRET=$(aws ssm get-parameter --name /gunnerteam/dev/MIGRATION_SECRET \
  --with-decryption --region us-east-2 --profile mfa --query 'Parameter.Value' --output text)
aws lambda invoke --function-name gunnerteam-dev-api --cli-binary-format raw-in-base64-out \
  --payload "{\"_sql\":\"SELECT direction, external_number, body, hubspot_synced FROM dp_sms_messages ORDER BY sent_at DESC LIMIT 5\",\"_secret\":\"$MIGRATION_SECRET\"}" \
  --region us-east-2 --profile mfa /tmp/dp-live.json && cat /tmp/dp-live.json
```
Expect the test message row present (metadata; `body` may be NULL as a secondary subscriber).
No HubSpot assertion here — HubSpot is a separate build that reads from the DB, not part of this pipeline.

## If events 401
The route returns `{"error":"bad signature"}` when the JWT HMAC doesn't verify. Cause is almost
always a secret mismatch or a trailing newline in the SSM value (the points-token lesson). Confirm
the SSM value has no trailing whitespace and re-create the subscriptions with the identical secret.

## Notes
- Subscriptions are durable in Dialpad; to rotate the secret, update SSM **and** re-create both
  subscriptions with the new value, then redeploy is not needed (secret is fetched per container;
  a cold start picks it up — or bump the function to force fresh containers).
- To remove: `DELETE /v2/subscriptions/sms/{id}` and `/call/{id}`, then `DELETE /v2/webhooks/{id}`.
