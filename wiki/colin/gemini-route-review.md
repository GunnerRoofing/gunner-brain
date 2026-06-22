---
type: reference
owner: colin
app: GunnerCam
created: 2026-06-21
updated: 2026-06-21
tags: [wl-companycam, gemini, location, ai]
status: active
---

# Gemini Route Review

AI-generated narrative + map contours of a PM's day, built from raw location pings and assigned-project context. Renders in the [[colin/my-day]] dashboard and [[colin/managers-map]]. Powered by Google's Generative Language API (Gemini), with an Amazon Bedrock Claude fallback.

## Two Gemini integrations (don't conflate)

GunnerCam has **two** independent Gemini callers, both `"server-only"`, both hitting the REST endpoint directly — no npm SDK, no Vertex AI, no embeddings, no tuning.

| Integration | Lib | Fed by | Model env var | Topic note |
|---|---|---|---|---|
| Route review (location coach) | `src/lib/gemini-location-coach.ts` | `src/lib/location-insights.ts` | `GEMINI_LOCATION_MODEL_ID` | this note |
| Call summary | `src/lib/gemini-call-summary.ts` | `src/lib/dialpad-project-calls.ts` | `GEMINI_MODEL_ID` | [[colin/dialpad]] |

Both POST to `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent` (v1beta). The two model env vars are deliberately separate so a change to one path can't affect the other.

## Engine selection + Claude fallback

- Route review prefers Gemini when `GEMINI_API_KEY` + `GEMINI_LOCATION_MODEL_ID` are configured; falls back to **Amazon Bedrock Claude** (`src/lib/bedrock-claude.ts`) when not. A feature-flag route signals the active engine to the frontend.
- Claude responses stay schema-compatible by omitting Gemini-only optional fields (e.g. Maps source links).

## Model + thinking config (as of 2026-06-21)

- **Production model: `gemini-3.5-flash` with `thinkingLevel: high`.** A model-floor guard in `gemini-location-coach.ts` normalizes lower/stale model IDs (e.g. `gemini-3.1-flash-lite`, `gemini-2.5-flash-lite`) **up** to `gemini-3.5-flash` at runtime, so a stale deployed-stage secret can't silently downgrade quality.
- `gemini-3.1-flash` **does not exist** (404). The real low-latency text model is `gemini-3.1-flash-lite`; code aliases `gemini-3.1-flash → gemini-3.1-flash-lite` to prevent accidental 404s.
- Gemini 3.5 Flash emits **thinking/scratchpad "thought" parts before the answer**. The parser must skip parts flagged as `thought` before extracting JSON, or it reads the scratchpad as the payload and 400s.
- `thinkingConfig` is **rejected for Flash-Lite models** (omit it); non-Lite models send an explicit thinking level.
- **Bump the cache fingerprint version whenever `thinkingConfig` / `maxOutputTokens` / prompt / model change** (see Caching below).

Superseded experiments (kept here so they aren't reattempted):

- **Latency fast-path (2026-06-17, reverted same day):** single ungrounded JSON call on `gemini-2.5-flash-lite` (~3.7 s) with a hard 4.5 s abort and `maxOutputTokens: 2048`. Reversed for quality; the hard abort was removed and 5 s became a soft slow-log target only.
- **Thinking-level churn (2026-06-18):** `high` → `minimal` (to fix MAX_TOKENS truncation) → `medium` (per product request, ~17 s locally) → back to `high`.

## Google Maps grounding — hard constraints (verified)

- **`tools: [{ googleMaps: {} }]` cannot be combined with `responseSchema` or `responseMimeType` (JSON mode) in one `generateContent` call — Google returns HTTP 400.** Verified repeatedly in live API logs. The integration uses prompt-enforced JSON + parsing/normalization instead of strict JSON mode.
- Maps grounding **rejects raw lat/lng pairs** passed as the search `query` (400 `INVALID_ARGUMENT`). The prompt hard-guards: coordinates are evidence-only context; Maps lookups must use human-readable place names / street addresses.
- Saying "return JSON only" **and** "never search Maps for coordinates" in the same prompt **suppresses grounding entirely** — no tool call, no `groundingChunks`, no source links. Resolved by inviting grounding for place/address verification.
- Maps source links come from `groundingChunks[].maps`; the shared payload has an optional field for them, and the UI renders real Google Maps URLs beside the review (required by Google's grounding display policy).
- Maps-grounded + high-thinking calls are slow (~13+ s for small requests, ~60 s risk on dense days) — drove the timeout changes below.
- **Grounding decision oscillated** (two-call split → removed for a fast path → re-enabled 2026-06-18). Latest committed state: **grounding ON**, so Gemini can place stops via Maps context even where no raw ping exists.

## Call structure — three-attempt retry ladder (as of 2026-06-18)

Latest adapter runs a degrade ladder, specifically so the UI gets contours rather than an "unavailable" card when grounding fails (e.g. the coordinate-pair 400):

1. Maps-grounded
2. Maps-grounded strict JSON
3. Gemini JSON-only (no Maps tool) — final rescue

Earlier alternatives, now superseded: the **two-call grounded pattern** (Call 1 grounded NL author + source links, Call 2 schema-locked formatter with `responseMimeType: application/json` + `responseSchema`) sidestepped the grounding+schema 400; it was briefly replaced by a single ungrounded structured-JSON call.

Adapter normalization accepts string-typed coordinates, normalizes `kind` aliases (`job-site` → `job_site`), repairs missing contour lat/lng/time from cited raw ping IDs or assigned-project targets, and parses fenced/embedded JSON blobs. A regression test covers a previously-mis-handled case where a recoverable non-OK formatter error (500/429) was re-thrown as a hard 400 instead of degrading.

## Response schema + contours

- **Gemini receives the full raw ping list** (id, time, lat, lng, accuracy) + check-ins + assigned-project targets + office/known places, and generates contours autonomously. Code only validates (time order, cited ping IDs exist, coordinates in bounds) and flags contradictions. (Superseded: the old design pre-built deterministic contours and fed them to Gemini; that builder is now fallback/debug only.)
- Contours alternate **STOP** vs **TRAVEL**:
  - STOP kinds: `home`, `office`, `job_site`, `errand`, `lunch`, `break` (labeled with dwell time).
  - TRAVEL kinds: `work_commute`, `travel` (labeled by destination + drive time).
- `home` and `errand` are newer kinds; errand detection uses Maps grounding to flag off-route retail/supply stops (e.g. Home Depot). Contour cap raised **5 → 12**.
- Optional `statusLine` field — a ~90-char sentence (e.g. "On the way to the Stamford site") preferred in PM cards, with deterministic activity text as fallback. Old cached rows without it stay valid.
- **Mechanical fallback contours removed from user-facing output.** `buildLocationRouteContours` (`src/lib/location-route-contours.ts:51`, time-band labels "Overnight route" / "Start-of-day route" / "Morning route" / "Field-window route") no longer renders. On Gemini failure the server returns `generatedContours: []` and the UI shows "Couldn't generate route contours — run the route review again." When Gemini returns a valid review but no usable contours, the server scaffolds contours from route stages so the map always renders the numbered stops.

## Location-trail pipeline (latest, 2026-06-18)

Five layers feed the review. See [[colin/location-pings]] for ingest.

1. Raw pings
2. Clustered timeline steps (cluster within 10 min / 180 m)
3. Deterministic broad contours
4. Gemini interpretation
5. Google Directions road smoothing

A phone cluster counts as a **job-site** if within 350 m of an assigned project for 8+ minutes, or with multiple points.

## Caching + the warmer

- **Persistent cache table `location_insight_reviews`** (Drizzle migration `0044_outstanding_grey_gargoyle`; see [[colin/data-model]]). Columns: `corporation_id`, `user_id`, date range, Gemini model ID, evidence fingerprint, JSON output. Unique key on (`corporation_id`, `user_id`, date, fingerprint, model) prevents a stale lower-model entry matching a high-thinking 3.5-flash review; index supports fast PM/day lookup.
- **Read order on click:** in-process memory cache → Postgres `location_insight_reviews` → call Gemini only on miss.
- The **in-process Map cache effectively misses in production** (cold starts empty, instances don't share, HMR wipes it in dev, and today's fingerprint includes live pings that grow between requests). Only frozen past-day ping sets cache within one warm process — which is why the persistent table exists.
- Cache key: `corporationId|provider|userId|from|to|fingerprint`. Fingerprint **must include the Gemini model version** so a model switch busts old failures. Bump history in `src/lib/location-insights.ts`: v2 → v3 (two-call restructure) → v4 (place/travel prompt rewrite); a separate v3 bump landed in the grounding-rework session.
- **Failed / fallback / "unavailable" responses are excluded from persistent writes** (`location-insights-cache.ts`) — fixes the bug where a transient error persisted the "unavailable" card for the whole cache window.
- **Scheduled Lambda warmer** precomputes today's active PMs per corporation (using each corp's timezone, not server UTC) and upserts the table. Standalone scheduled Lambda (task-reminder cron pattern); POSTs to `/api/internal/location-insights-warm` with a bearer secret; the route responds immediately and runs work via Next.js `after()`. Cadence: noted every 2 hours (2026-06-17), described as hourly (2026-06-21) — reconcile (see Open questions). See [[colin/ops-deploy]].

## Endpoints + timeouts + UI behavior

- Endpoint evolution: the dashboard formerly assembled evidence in React and called insights-only `POST /api/time/location-insights`. New **`GET /api/time/location-day-review`** returns a single PM/day packet (raw pings, check-ins, assigned-project targets, important places, generated AI review) under manager auth + the sentinel-error contract. A `/api/route-review` route is also referenced.
- **Server-side route-review timeout raised 60 s → 180 s** to accommodate Maps grounding + high thinking + full raw ping payloads; the "slow" warning threshold moved 5 s → 30 s.
- **Deployed web Lambda timeout in `sst.config.ts` raised to 50 s** because medium thinking (~17 s) exceeded the dev Lambda's default 20 s → 5xx → "Gemini route review could not be loaded." Client error copy now reads a 5xx as a retryable timeout, not a permanent failure. See [[colin/aws-infra]].
- **Known UI hang:** the 180 s timeout + multi-call retries can park the My Day map on "Reviewing / Generating route contours…" for minutes. The spinner (`insightsLoading`) only clears on contours or an error state, so a zero-contour-no-error result sticks. Recommended fix: cap the interactive review timeout at 20–30 s and show "try again."
- `day-location-dashboard` / `managers-map` cached a failed result and skipped re-fetch on a second "Route review" click (effect skipped when an insights object existed); patched to clear stale insights before firing the new request.

## Config, keys + rotation

- **Local dev:** `GEMINI_API_KEY` in `.env.local` (git-ignored).
- **Deployed stages:** SST secret `GeminiApiKey` syncs to SSM `SecureString` at `/wl-companycam/<stage>/gemini-api-key` (same pattern as the Google Maps key). The web Lambda reads it from SSM at runtime.
- **Rotate** by `sst secret set GeminiApiKey`, then a **targeted SST deploy of `GeminiApiKeyParam` only** — pushes the new SSM value without shipping unrelated dirty code or a full rebuild.
- `GEMINI_LOCATION_MODEL_ID` is a config entry (`sst.config.ts` + `AWS.md`) controlling only the route-review model; documented defaults have drifted (`gemini-3.5-flash` vs the `2.5-flash-lite` experiment), but the runtime model-floor guard normalizes up to `gemini-3.5-flash` regardless.
- **Only GCP permission needed:** the Generative Language API (`generativelanguage.googleapis.com`). Restrict the key to that API. No Vertex AI / Maps / Storage / OAuth roles, no IAM project roles.

> **Post-June-2026 key policy:** Google deprecated unrestricted standard Gemini API keys on **2026-06-19** and will reject all standard keys in **September 2026**. Any rotation after 2026-06-19 must create an AI Studio **authorization key**, not a plain GCP API key.

## Known failure modes ("could not be loaded" / "unavailable")

See [[colin/gotchas]] for cross-feature versions.

| Symptom | Cause | Fix |
|---|---|---|
| `[gemini-location-coach] generateContent failed: <status>` → `BAD_REQUEST` | Wrong-format API key; REST `?key=` auth expects an `AIza…`-prefixed key (an `AQ.Ab8RN…`-style key fails) | Use a correctly-formatted key |
| "unavailable" card with a known-good key | Rotating `GEMINI_API_KEY` in `.env.local` doesn't take effect in a running dev server (read only at startup) | Ctrl-C + `npm run dev` |
| All Gemini 4xx flattened to a generic "unavailable" card | `/api/route-review` swallows the upstream error | Run the generator directly via a `tsx` script with the server-only React condition, outside Next, to surface the real error |
| `finishReason: MAX_TOKENS` → truncated JSON | High thinking consumed almost all of a 2,048-token output budget | Raise cap to 4,096 + tune thinking |
| (Call-summary path) unparseable unfinished code fence → `BAD_REQUEST` | `thinkingBudget: 1024` with only `maxOutputTokens: 256` exhausts budget thinking | Give more output room |
| Generic red failure on dense days | Large-trail timeout — e.g. Joseph Muratori's 2026-06-17 day (51–57 pings, ~56 timeline steps, 7 assigned projects, 0 check-ins) repeatedly tripped the ~60 s grounded-author timeout | The 180 s server timeout above |

## PII / data-exposure note (verify org sign-off)

> **Open item — confirm org sign-off** that customer + employee PII may be sent to Google's Generative Language API.

- **Route review** (`buildLocationInsightContext` in `src/lib/location-insights.ts`) sends to Google: manager userId / name / email, customer names, project street addresses + lat/lng, raw GPS pings + check-ins with timestamps and raw coordinates, route contours, office/yard lat/lng, and underlying timeline evidence.
- **Call summary** sends customer name, PM name, call direction/duration, and the **full Dialpad transcript** (whitespace-collapsed, truncated to 12,000 chars). See [[colin/dialpad]].

## Commit status (as of 2026-06-21)

As of 2026-06-17 both Gemini files were git-untracked, part of a larger uncommitted cluster (Dialpad libs, location-insights / timeline / narrative libs, `google-maps`, `bedrock-claude`, new routes, migration `0043`, `schema.ts`, `sst.config.ts`, `EXTERNAL_API.md`); not independently committable.

## Open questions / TODOs

- **Verify org sign-off** for sending customer + employee PII (addresses, raw GPS, phone-call transcripts) to Google's Generative Language API.
- **Reconcile warmer cadence:** every 2 hours (2026-06-17) vs hourly (2026-06-21).
- **Harden interactive timeout:** cap at 20–30 s with a "try again" fallback so the 180 s server timeout can't hang the My Day spinner on a zero-contour-no-error result (not yet confirmed landed).
- Consider **re-enabling Maps grounding selectively** for small/simple days — latency tradeoff is mainly on dense days.
- Proposed but not created: a reusable `scripts/pm-day-context.mts` to dump the full per-PM-per-day evidence superset.
