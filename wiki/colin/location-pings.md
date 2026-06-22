---
type: reference
owner: colin
app: GunnerCam
created: 2026-06-21
updated: 2026-06-21
tags: [wl-companycam, location, gunnerteam]
status: active
---

# Location Pings

Continuous PM/crew GPS breadcrumb tracking. Multiple sources (Tyler's GunnerTeam iOS app, a Hexnode MDM importer, GunnerTeam live proxy) feed a single persisted table that powers the Day Locations dashboard and [[colin/gemini-route-review]]. The always-on UI is **dormant pending CT/NJ consent sign-off** (see [Legal](#legal--consent-constraint)).

## Storage model

| Table | Migration | Shape | Holds |
|---|---|---|---|
| `pm_location_pings` | 0042 | continuous breadcrumb, corp-scoped | one row per GPS fix |
| `project_site_checkins` | (pre-0042) | one row per check-in **session** | discrete pins, not a trail |

`pm_location_pings` columns: `id`, `corporation_id` (FK), `user_id` (nullable FK), `external_user_id` (string), `lat`, `lng`, `accuracy_meters`, `recorded_at`, `created_at`. A unique index on `(corporation_id, external_user_id, recorded_at)` makes batch re-ingest and partial-batch retry a safe no-op (`onConflictDoNothing`) — see [[colin/data-model]]. The table and the `/api/time/location-pings` reader predate the Day Locations dashboard; both the external HTTP ingest and the Hexnode importer feed it.

`project_site_checkins` stores check-in lat/lng, `checked_in_at`/`checked_out_at`, user email/name, and project id. Travel distance is **not** derivable from it; `GET /api/time/site-checkins` deliberately returns `travel_meters: null` and overlap-clips the session window to the requested range.

### Data-quality caveats
- Project rows store only street-address text. `latitude`/`longitude` columns exist but are NULL for all projects (confirmed for Joseph Muratori's 7 projects, 2026-06-17). Geocoding happens at render time, so any ping-to-jobsite proximity compare must geocode addresses first.
- Raw pings are noisy: `accuracy_meters` can be NULL, and overnight stationary clusters produce many near-identical fixes (Joseph Muratori 2026-06-17: 51 pings, ~40 near-identical overnight, only ~5 distinct travel points). Consumers must dedupe/simplify before analysis.

## External ingest endpoint

`POST /api/external/v1/location-pings` is the server-to-server ingest for Tyler's GunnerTeam app to push GPS breadcrumbs into GunnerCam. It reuses the existing external integration auth (the same `ccam_` key Tyler uses for check-ins) — no new credentials; corp scope is implicit from the key. Push is the chosen path because a server-side background pull is infeasible (see [Proxy auth](#proxy-routes--auth)). Full contract lives in [[colin/external-api-integration]].

| Field | Required | Notes |
|---|---|---|
| `userId` | yes | UUID; part of the dedup key as `external_user_id` |
| `userEmail` | yes | lowercased; for local-user resolution only — **not** part of the dedup key |
| `timestamp` | yes | ISO-8601 UTC, must end in `Z`; device capture time → stored as `recorded_at` |
| `lat` / `lng` | yes | JSON numbers, range-validated |
| `accuracy` / `accuracyMeters` | no | number ≥ 0 |

- Accepts a batch `{pings:[…]}` or a single-ping body, up to **2000 pings** per batch. One invalid ping rejects the whole batch with `400`.
- Dedup key is `(corporation_id, userId, recorded_at)`, where `recorded_at` is the device fix time — making offline replay and retries idempotent.
- `permissionStatus` was deliberately excluded — no column/handling, and the compliance roster covers that need instead.
- Documented in `EXTERNAL_API.md`, `EXTERNAL_API_AI.md` (the `/location-pings` entry was missing entirely until 2026-06-18), and `TYLER_API_HANDOFF.md`. The regression test `external-location-pings.test.ts` proves stored `recordedAt` is the client fix time, not the upload time.

### iOS ping-stream behavior
As of GunnerTeam backend v282 (2026-06-18), the iOS app buffers GPS fixes to disk when offline and replays them as a batch on reconnect, each ping carrying its real device-capture timestamp. The iOS side is committed but **pending an on-device airplane-mode → drive → reconnect test**.

- Off-job/background pings use coarse network location to save battery: accuracy hundreds of meters to ~1 km at ~15-min intervals. On-site pings tighten to ~100 m every 5 min. Treat `accuracy` as display/filtering metadata, not trail-level precision for off-job pings.
- A consent gate (`LOCATION_PING_FORWARD` flag) meant only Tyler's test account produced ingest data as of 2026-06-18.

## Proxy routes & auth

Live proxy routes pass through to GunnerTeam's own API (not local storage). Full endpoint spec is in Tyler's PR #791.

| Route | Purpose |
|---|---|
| `GET /api/time/fleet-locations` | latest known position per user (24 h freshness); powers on-demand locate and the live map |
| `GET /api/time/location-history` | breadcrumb trail; `userId`+`from`+`to`, capped 10k points, ≤31 days/request (local 31-day range guard), 90-day retention |
| `GET /time/location-compliance` | consent/auth roster |
| `GET /api/time/location-pings` | manager-gated reader of **persisted** pings, same shape as the live trail proxy — enables historical date queries |

There is **no** `/time/active` route.

### Auth mechanism (current)
The `GunnerteamServiceKey` SST secret (→ SSM `/wl-companycam/<stage>/gunnerteam-service-key`) authenticates the proxy routes. `GunnerteamApiUrl` = `https://api-dev.team.gunnerroofing.com`. Set via `sst secret set GunnerteamServiceKey <value> --stage dev`.

### Superseded approach (dead)
The original manager Cognito access-token path is dormant. GunnerTeam's `requireAuth` verifies a Cognito **ID** token (`tokenUse: 'id'`, with `email` + `custom:tenantId` claims); the proxy's `ccam_access` cookie is an **access** token, which fails on `token_use` and lacks `email`. There is no GunnerTeam service account for `gunnerteamBearerToken()`, so server-side background pull is infeasible — hence push + the service key. See [[colin/gotchas]].

### Roster & fleet shapes
- `/time/location-compliance` returns a `users` array: `user_id`, `display_name`, `email`, `auth_status` (e.g. `always`, `unknown`), `auth_updated_at`, `last_location_at`, `location_consent`, `checked_in`. Not-yet-opted-in users show `location_consent:false`, `auth_status:unknown`, `last_location_at:null` — correct gate behavior, not missing data. This roster covers "denied GPS / dark" users the ping stream structurally cannot.
- `/time/fleet-locations` returns a `locations` array: `user_id`, `lat`, `lng`, `accuracy_m` (nullable), `recorded_at`, `email`, `display_name`, `auth_status`, `checked_in`. Only `location_consent:true` users appear, so early rollout returns ~1–2 rows (only Tyler Suffern consented). `gunnerteam-time.ts` passes unknown fields through, so `auth_status` already reaches callers; dark users are absent entirely.
- The [[colin/points-leaderboard]] returns `{ tooFew: true, items: [] }` until enough members opt in — intentional, to avoid leaking rankings with few participants; UI renders graceful-empty.

## Hexnode MDM importer (interim source)

Gunner runs a Hexnode MDM at `gunner-r3.hexnodemdm.com` (API base `https://gunner-r3.hexnodemdm.com/api/v1`, key `HEXNODE_API_KEY` in `.env.local`, not committed): 88 enrolled devices (38 smartphones, 48 laptops, 1 tablet, 1 desktop). 28 of 39 PM-role users match devices by name; all 7 PMs primary on active projects have matched smartphones.

| Item | Detail |
|---|---|
| Script | `scripts/sync-from-hexnode.mts` |
| Modes | `sync:hexnode` (dry-run), `sync:hexnode:apply`, `sync:hexnode:watch` (polls every 900 s) |
| Writes | upserts into `pm_location_pings` idempotently; `external_user_id = 'hexnode:<deviceId>'` + resolved local `user_id` on PM match |
| Filter | smartphones + tablets only, excluding laptops (laptop-inclusive dry run would have added 3 users / ~325 polluting rows) |
| Runtime | opt-in detached `screen` session — **not** a deployed Lambda or SST cron |

- The external HTTP route is **not** reused (it validates `userId` as UUID); the script writes directly to the table.
- `NODE_TLS_REJECT_UNAUTHORIZED=0` is set in `.env.local` (benign TLS warning). Screen session name varies across runs (`wl-hexnode-sync` → log `/tmp/wl-companycam-hexnode-sync.log`; later `wl-companycam-hexnode` → log `/tmp/wl-companycam-hexnode-watch.log`).
- **Gotcha:** Hexnode `/locations/` pagination returns HTTP 404 `{"detail":"Invalid page."}` past the last page instead of an empty page; the importer treats this specific 404 as end-of-history. See [[colin/gotchas]].
- Data quality is uneven (2026-06-17 7-day backfill: 5,704 rows pulled, 4,370 inserted). Rich recent history for Zachary Webb (~663 pts), Joseph Muratori (~664 pts), Michael Ushka (thousands at ~15-min cadence); stale/empty for Joe Fichera (last May 28), Campbell Schulz (none), Chris Manfredo (last Apr 22), Kevin Lewis (last May 26) — a device-policy/app-permission issue on those iPhones, not an import bug.

## Insight warming & token control

- The location-insight warmer SST cron changed from every-2-hours-all-day to **hourly over 8:00–18:00 Eastern** (timezone-aware), keeping PM route reviews warm during business hours so manager clicks read cached DB results instead of blocking on Gemini. See [[colin/ops-deploy]].
- The warmer and manual generation now **skip Gemini entirely** for PMs with no mapped phone pings or site check-ins that day — assigned projects alone no longer count as evidence (the old gate did, burning tokens for PMs who never sent data). This is the primary token-cost control. File: `src/lib/location-insights.ts`.
- `buildLocationRouteContours` accepts assigned-project targets and does optimistic job-site matching: phone clusters within ~350 m of a target that linger 8+ min (or have multiple points) become job-site contours; movements under ~300 m are suppressed as jitter; adjacent inferred-proximity + actual-check-in contours merge into one stop. Both server insight generation and dashboard preview memoization pass project targets in. Deeper coverage in [[colin/gemini-route-review]].

## Dashboard data sourcing

- The Day Locations dashboard reads `pm_location_pings` as its **primary** source and falls back to the live GunnerTeam `/api/time/location-history` proxy when local pings are empty (rollout fallback). The live-map feed is `/api/time/fleet-locations`. See [[colin/managers-map]].
- **Known split-brain:** two history sources (persisted `pm_location_pings` vs live proxied history). A cleaner not-yet-implemented design makes persisted pings canonical and treats the live proxy as a migration/debug path only.
- Continuous GunnerTeam breadcrumb data has no dedicated local table beyond `pm_location_pings`; persisting it requires Tyler pushing each ping via the ingest route. `project_site_checkins` is the only other store and holds session pins only.

## Alternative sources (evaluated)

| Source | Verdict |
|---|---|
| CompanyCam public API | Exposes `Project.coordinates`/geofence and `Photo.coordinates` (lat/lon + `captured_at`) but **no** continuous employee breadcrumb. Importer ignores CompanyCam coords; useful for proof-of-presence, not tracking. Photo coords would need new lat/lng columns on `photos` or a sync cache. |
| Verizon ThingSpace Device Location API | Can't locate normal smartphones (IoT/fixed-wireless/certified only) — unsuitable for PMs. |
| Verizon Connect Reveal | Valid for vehicle/asset GPS if installed in trucks. |

**Recommended future design:** a normalized `location_events` feed with source tags (`tyler_app`, `companycam_photo`, `verizon_connect_vehicle`, `hexnode`, `manual_checkin`) to avoid vendor lock-in.

## Deploy history

- Ingest + migration 0042 committed as `89199a0` on `dev`, deployed to `project.dev.gunnerroofing.com` via a stash-isolated `sst deploy` (WIP stashed, built from committed HEAD, WIP restored byte-for-byte) so dialpad/gemini/maps WIP and the 0043 migration did not ship.
- The dev RDS was already migrated through 0043 (dialpad) and held ~5,727 `pm_location_pings` rows before the deploy — from a prior `sst dev` live session that served + migrated from the working tree, leaving the DB ahead of the deployed Lambda. **Gotcha:** when the dev RDS migration high-water exceeds the committed journal, an `sst dev` session ran working-tree migrations against shared dev RDS; committed-tree `db:migrate` is then a no-op. See [[colin/ops-deploy]].
- The GunnerTeam proxy slice (fleet-locations + location-history + compliance roster + `auth_status` type + `GunnerteamServiceKey` in `sst.config`) committed as `452ca4b`; `/points` leaderboard fallback as `083d6d0`. Deployed isolated, excluding dialpad/gemini/maps WIP and 0043. Live dev verification 2026-06-18: location-compliance → 5 users, fleet-locations → 2 locations, location-history → 138 points, all HTTP 200.

## Legal / consent constraint

CT and NJ written-consent rules apply to continuous on-the-clock location tracking; management sign-off is required before widening beyond existing checked-in/on-site/drive-to-site data. The dashboard's Locate/Trail/history UI is intentionally **dormant** until that sign-off enables always-on phone reporting; [[colin/my-day]] stays on `/time/summary` + `/time/events` in the interim.

## Open questions / TODOs

| Item | Status (as of 2026-06-21) |
|---|---|
| Consent sign-off | always-on continuous tracking blocked on CT/NJ legal/HR review + management approval; Locate/Trail UI dormant until then |
| Service key delivery | as of 2026-06-18 `GunnerteamServiceKey` (SSM `/wl-companycam/<stage>/gunnerteam-service-key`) still a blank placeholder awaiting Keeper delivery; `/time/location-compliance` extension also pending on GunnerTeam's side |
| 6th compliance user missing | `it@gunnerroofing.com` (Test IT) absent from GunnerTeam's compliance source (5 users even with `includeInactive`); drop is upstream-owned, not WL filtering |
| iOS offline-replay | committed but pending the on-device airplane-mode → drive → reconnect test |
| Identity matching | code matches by `userId`/`externalUserId`/`email`/`name` with no durable mapping; proposed fix is a stable `gunnerteam_user_id` on `users.external_ids` or a small mapping table |
| Split-brain history | make persisted `pm_location_pings` canonical, demote live proxy to migration/debug — not yet implemented |
| No service-key infra precedent | GunnerCam had no `gt_service_keys`/`requireServiceKey` mechanism (grep of `src/`+`scripts/` found none); the handoff's assumption that phase seeding uses a service key was wrong (phase templates are local). `GunnerteamServiceKey` plumbing is net-new work |
