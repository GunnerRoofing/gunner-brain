---
type: session
title: >-
  Session 2026-06-26: Dialpad full capture — dp_events, lossless ingest,
  recordings bucket
created: '2026-06-26'
updated: '2026-06-26'
status: stable
tags:
  - session
  - dialpad
  - masterdb
  - s3
  - infra
  - full-capture
related:
  - '[[tyler/masterdb/masterdb-architecture]]'
  - '[[gunnerteam/aws-environment]]'
  - '[[tyler/gunnerteam/gunnerteam-project-structure]]'
---

# Session 2026-06-26: Dialpad full capture — dp_events, lossless ingest, recordings bucket

Three prompts building out the Dialpad full-capture pipeline: raw event log schema, lossless write, and recordings infrastructure.

---

## cc-2810 — dp_events table + dp_calls columns (Alembic p22)

**Migration:** `p22_dialpad_full_capture` — `down_revision = "p21_dialpad_updated_at"`

**Multi-head situation:** prod was at `{p21, q1}` (both heads already applied). `upgrade_to p22` was a single step.

### dp_events (new table)
Append-only raw JSONB event log — one row per verified webhook event. Lossless substrate: nothing Dialpad sends is ever dropped.

```sql
CREATE TABLE dp_events (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id           UUID NOT NULL,
  event_kind       TEXT NOT NULL,       -- 'sms' | 'call' | 'transcription' | 'recap' | 'unknown'
  dialpad_call_id  BIGINT,
  dialpad_msg_id   BIGINT,
  state            TEXT,
  payload          JSONB NOT NULL,      -- decoded event, verbatim
  received_at      TIMESTAMPTZ NOT NULL DEFAULT now()
)
```

4 indexes: `(org_id, dialpad_call_id)` partial, `(org_id, dialpad_msg_id)` partial, `(org_id, received_at)`, `(org_id, event_kind)`.

`GRANT SELECT, INSERT, UPDATE ON dp_events TO gunnerteam_app`

### dp_calls new columns
- `transcript TEXT` — full call transcript (distinct from voicemail transcription)
- `recap_action_items JSONB` — AI action items / key moments from Recap Summary event
- `recording_s3_keys TEXT[]` — S3 keys after re-host (cc-2813); `recording_urls` stays as source pointer

**Applied:** prod via throwaway migrate-Lambda in prod VPC. Verified as `gunnerteam_app`:
- `dp_events` exists + `events_insert=true` + `events_select=true`
- 3 new columns present on `dp_calls`

---

## cc-2811 — Lossless raw capture: write every event to dp_events

**Change:** `src/routes/dialpad.js` — two additions.

### classifyEvent (new function)
```js
function classifyEvent(p) {
  if (p.from_number !== undefined || p.message_status !== undefined) return 'sms';
  if (p.call_id !== undefined) return 'call';  // transcript/recap also carry call_id
  return 'unknown';
}
```

### recordRawEvent (new function)
```js
async function recordRawEvent(payload, kind) {
  await pool.query(
    `INSERT INTO dp_events (...) VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6::jsonb, now())`,
    [ORG_ID, kind, payload.call_id ?? null, kind === 'sms' ? (payload.id ?? null) : null,
     payload.state ?? payload.message_status ?? null, JSON.stringify(payload)]
  );
}
```

### Handler wiring
```js
const kind = classifyEvent(payload);
await recordRawEvent(payload, kind);  // lossless raw capture FIRST
// ...existing structured SMS/call branch unchanged...
```

**On the main path** (not swallowed): failure → 500 → Dialpad retry → re-capture. dp_events is append-only; duplicate raw rows on retry are acceptable (structured tables carry UNIQUE dedup).

**v391 deployed.** Smoke: `dp_events` row for msg 999000020 confirmed: `event_kind=sms`, `state=delivered`, `payload_type=object`.

---

## cc-2812 — Recordings S3 bucket + scoped API key + IAM

### New file: `terraform/dialpad-recordings.tf`
`gunnerteam-dev-dialpad-recordings` bucket: PAB all-true, SSE-AES256, TLS-only bucket policy. No versioning (recordings are immutable by nature — not WORM).

### lambda-api.tf changes
- Data source: `aws_ssm_parameter.dialpad_recordings_bucket`
- Env var: `DIALPAD_RECORDINGS_BUCKET`
- IAM `Sid = "S3DialpadRecordings"`: `PutObject` + `GetObject` on bucket ARN/*

### SSM
- `/gunnerteam/dev/DIALPAD_RECORDINGS_BUCKET` (String) — bucket name
- `/gunnerteam/dev/DIALPAD_API_KEY` (SecureString) — scoped Dialpad API key for recordings/transcription/recap downloads. **Interactive put only** (never touches TF or Lambda env — runtime-fetched via `getSecretSync('DIALPAD_API_KEY')`)

### Apply
**5 added, 2 changed, 1 destroyed** (null_resource.clear_alias_routing — expected replace on Lambda version change). v392 live.

### Verification
- Bucket: SSE=AES256, PAB all-true ✅
- Terraform validated, plan additive (no vpc/source_code_hash change) ✅

---

## Dialpad pipeline status after this session

| Component | Status |
|---|---|
| `dp_sms_messages` + `dp_calls` structured ingest | ✅ live (cc-2803/2806) |
| `dp_events` raw log table (p22) | ✅ live on prod |
| `dp_calls` transcript/recap_action_items/recording_s3_keys cols | ✅ live on prod |
| `classifyEvent` + `recordRawEvent` in ingest route | ✅ v391 live |
| `gunnerteam-dev-dialpad-recordings` S3 bucket | ✅ provisioned |
| `DIALPAD_API_KEY` SSM | ⏳ needs interactive put in terminal |
| cc-2813: extract transcript/recap/recordings into structured cols | 🔜 next |
