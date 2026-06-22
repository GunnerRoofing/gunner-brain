---
type: reference
owner: colin
app: GunnerCam
created: 2026-06-21
updated: 2026-06-21
tags: [wl-companycam, dialpad, integration]
status: active
---

# Dialpad Call Integration

Surfaces matched customer call history (recordings, transcripts, Gemini summaries) per project inside the [[colin/my-day]] manager rail. Follows the standard SST secret → SSM SecureString → server-only lib pattern, and stays **dormant** (returns empty) until the `DialpadApiToken` secret is provisioned.

## Feature surface

- A Dialpad call-history panel ships in the My Day manager **focus-mode right rail**, under Manager tasks. Code in `src/components/my-day-content.tsx` / `manager-tasks-panel.tsx`.
- The panel resolves PMs to Dialpad users by **email** or a stored `externalIds.dialpad_user_id`, pulls **concluded** calls, then matches them to the project customer by **phone → email → fuzzy name**.
- Recording playback/download is **proxied through the app** — raw Dialpad URLs are never exposed to the browser.

| Route | Gate | Notes |
|---|---|---|
| `GET /api/projects/[id]/calls` | manager | Calls list; reads/writes the Postgres cache. |
| `GET /api/projects/[id]/calls/[callId]/recording` | manager + project access | Re-checks `callId` belongs to the project's matched calls. Serves inline MP3 with HTTP range support (`206 Partial Content`); a separate download path streams as an attachment. |

## Caching & storage

As of 2026-06-21 the durable Postgres cache is the current implementation. See [[colin/data-model]] for schema conventions.

- **Current (2026-06-17, migration 0043):** calls are durably cached in Postgres in `dialpad_project_calls` — call ID, project ID (scoped), transcript text, recording admin URL, recording share-link URL, Gemini summary metadata, and enrichment timestamps. UI renders **immediately from Postgres**, no live Dialpad round trip.
- **Superseded:** an earlier build used a 5-minute in-process in-memory `Map` (per corporation+project) in `src/lib/dialpad-project-calls.ts` plus a `Cache-Control: private, max-age=60` browser header. That cache vanished between Lambda instances/restarts — the reason for the move to Postgres.
- **Transcript-preserving writes:** updates merge so a later thin Dialpad response cannot wipe a richer already-cached transcript.
- The list route reads/writes cached rows for speed; **enrichment is lazy** — deferred to the call-detail (modal-open) path and written back, so subsequent opens are instant.

| File | Role |
|---|---|
| `drizzle/0043_unusual_nemesis.sql` | Migration adding `dialpad_project_calls`. |
| `src/db/schema.ts` | Table definition. |
| `src/lib/dialpad-project-calls.ts` | Cache read/write + matching. |
| `src/lib/dialpad.ts` | Dialpad v2 API client. |
| `src/lib/gemini-call-summary.ts` | Gemini low-thinking summary (see [[colin/gemini-route-review]] for the Gemini pattern). |

## Dialpad v2 API contract

Requires a **company-admin API key** with the `List calls` scope.

| Operation | Endpoint | Notes |
|---|---|---|
| List calls | `GET /api/v2/call` | Supports `target_type=user&target_id=...` and `started_after`. Items include `direction`, `external_number`, `date_started`, `duration`, `recording_details`, `transcription_text`, voicemail URLs. |
| Transcript | `GET /api/v2/transcripts/{call_id}` | **Not** in list/detail payloads — fetched separately. Returns AI-generated transcript text when Dialpad has produced it. |
| Recording share link | `POST /api/v2/recordingsharelink` | Returns a playable URL; defaults to `public` so the server can fetch MP3 bytes. |

## Enrichment pipeline

On call-detail (modal) open, the detail route triggers, then writes all results back to the cache row:

1. Transcript fetch — `GET /api/v2/transcripts/{call_id}`.
2. Recording share-link creation — `POST /api/v2/recordingsharelink`.
3. Gemini low-thinking summary.

## Server-side filtering

Junk calls are dropped **before** the durable cache write, so they never persist across refreshes. A call is kept only if it has either:

- **≥15 seconds** of connected/talk duration, **OR**
- real content — transcript, summary, or voicemail.

A recording link alone does **not** save a short/no-connect call.

## Secrets & deployment

Same pattern as [[colin/monday-integration]], CompanyCam, [[colin/external-api-integration]], and [[colin/managers-map]] Google Maps. See [[colin/aws-infra]] for the secret → SSM mechanics.

| Item | Value |
|---|---|
| SST secret | `DialpadApiToken` in `sst.config.ts` (documented in `AWS.md`). |
| Local env var | `DIALPAD_API_TOKEN` in `.env.local`. |
| Dormant behavior | Feature returns empty when token unset — deploys without the secret don't break. |

## Gotchas

See [[colin/gotchas]] for the cross-feature catalog.

- **Numeric fields arrive as STRINGS.** `date_started` and `duration` come back as numeric *strings* in some responses. A matcher accepting only `typeof number` silently dropped matches — live bug where Dawn Pascale showed 0 calls despite 10+ API matches. Fix: normalizer accepts number **and** string; regression test added with string `date_started`/`duration`.
- **Admin recording URL is login-gated.** The admin blob recording URL redirects to `/login` for any API-token-only request, producing a dead `0:00 / 0:00` player. It cannot be streamed server-side even with a bearer token. Fix: create + cache a `/api/v2/recordingsharelink` URL and proxy the stream server-side with range support.
- **Share link must resolve to audio.** Live recording links are direct `.mp3` paths on `dialpad.com`. If the proxy receives an HTML share *page* instead of audio, the route redirects to the Dialpad recording page.

## Key provisioning (people/process)

See [[colin/people-and-context]] for the Gunner ecosystem.

- The API key must be created from the **'My company'** context in Dialpad admin — **not** an office-level context. An office-scoped key may miss calls for PMs in other offices.
- Required scopes: **'Default scopes' + 'List calls'**. **'Recordings export'** is optional — only needed if recording URLs should be included in call logs.
- The key can only be viewed **at creation time** in Dialpad admin.

## Open items

- The integration is dormant until the company-level `DialpadApiToken` secret is provisioned and set.
- Per session memory, migration `0043` was deliberately kept out of the location-pings commit (see [[colin/location-pings]]). **Confirm `0043` is committed and deployed on the intended branch** before relying on the Postgres cache in production.

---

Sources: 2026-06-17 sessions ("Add Dialpad calls to my-day view", "Cache dialpad calls"), within ingest window 2026-05-21 → 2026-06-21.
