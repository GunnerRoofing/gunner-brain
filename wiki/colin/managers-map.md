---
type: reference
owner: colin
app: GunnerCam
created: 2026-06-21
updated: 2026-06-21
tags: [wl-companycam, location, maps, dashboard]
status: active
---

# Managers Map / PM Location Dashboard

The manager-only "Project Managers" dashboard — a near-fullscreen modal that shows where each PM checked in, the road-following trail they actually drove, and (optionally) an AI route review. Built on top of the location-ping ingest pipeline (see [[colin/location-pings]]) and the Gemini/Bedrock review layer (see [[colin/gemini-route-review]]).

## Surface & access control

- The dashboard component is **`src/components/shell/day-location-dashboard.tsx`**, opened from a "View Managers" pill (formerly an icon-circle) in the floating My Day chrome (`src/components/shell/floating-chrome.tsx`). Gated to **manager / company-admin / super-admin** roles. See [[colin/my-day]] for the surrounding chrome.
- Shipped at commit **`e6efe5f`**, deployed to `project.dev.gunnerroofing.com` **2026-06-16** (mobile chrome overflow at 390px fixed the same session).
- The PM/manager default shell is the floating My Day chrome (`shell.tsx`), **not** the classic sidebar; the classic-sidebar **Projects** surface is explicitly labeled deprecated (`sidebar.tsx`).
- **Role-check edge case:** manager-gated Reporting/Analytics UI in `metrics-bar.tsx` and the `/projects` page test the literal `principal.role === 'manager'` (not a capability check), so `company_admin` is a known gap. Project tool flags are set in `src/app/(app)/projects/[id]/page.tsx`.
- Renamed **"Project Managers"**; the old top stats strip (PM count / Visits / On site / Lat-longs) was removed and replaced with a date selector (◀ date pill ▶, capped at today) that reloads check-ins + trail for any past date. **Load logic is event-handler-driven** (open / date-change / refresh), not a React effect, to dodge the exhaustive-deps lint error.
- As of 2026-06-17 the header is a single horizontal toolbar (title, date controls, tabs, refresh) that wraps on narrow widths — compacted from three vertical bands.

## Layout (latest, as of 2026-06-17)

- **Persistent master-detail:** left rail = always-visible manager roster, right pane = selected manager's detail. This superseded the earlier full-page-swap drill-in pattern.
- Active managers (have a check-in for the day) float to the top with a green dot; idle managers collapse into a quiet group. The overview map lives in the right pane's nothing-selected state and is replaced by the individual manager map on selection.
- Promoted into a near-fullscreen modal with a three-column variant (manager rail / large annotated map canvas / right-side route-contour timeline); narrow viewports stack the sections.
- **Two tabs:** "Location Summary (AI)" (3-column manager card grid → detail panel with mini-map, Locate, Trail, lat/lng table) and **"Task Completion"** (dense list, currently a stub/placeholder — see Open questions).
- **Contour rail** uses a per-phase 5-hue palette shared between rail number badges and map markers, with click-to-stick expand/collapse. STOP cards = solid filled pin badge, full-weight card, solid border; TRAVEL cards = hollow ring badge, indented/dashed-border card, dashed connector rail. `contourKindGroup()` maps `work_commute`/`travel` → `'travel'`, else → `'stop'` (drives `data-kind-group` CSS).

## Data sources & endpoints

The dashboard is **always-on** off the local DB; live-proxy calls to Tyler's GunnerTeam backend layer on top for Locate/Trail. All four GunnerTeam routes share one auth path — the logged-in manager's Cognito **access token** via `gunnerteamBearerToken()` (the old "GunnerTeam session is not available" error just meant no access token in request context, not a session-model difference). See [[colin/external-api-integration]].

| Endpoint | Gate | Source | Purpose |
|---|---|---|---|
| `GET /api/time/site-checkins` | manager | local `project_site_checkins` (pushed by GunnerTeam) | Always-on check-in feed; no runtime GunnerTeam dependency. Superseded an earlier version that called `/time/events` + `/time/summary` proxies at runtime. |
| `GET /api/time/pms` | manager | local DB | Full corp-scoped PM roster (`role='pm'`, not deleted), independent of check-in activity. `buildPmRows()` seeds a row per PM then layers check-in stats; active top, others zeroed + "No check-in today." |
| `GET /api/time/pm-projects` | manager | local DB (`src/lib/pm-project-targets.ts`) | Assigned project coordinates scoped by `corporation_id`; rendered as named project markers ("where they should go" vs "where they went"). |
| `GET /api/time/location-insight-statuses` | manager | cached `location_insight_reviews` | Added 2026-06-21. Serves cached `statusLine` values for a day range with **no Gemini generation**; overview fetches it to populate status lines on load. See [[colin/gemini-route-review]]. |
| `GET /api/time/fleet-locations` | manager | GunnerTeam live (`gunnerteam-time.ts`) | Locate button. Live proxy, gated on `GUNNERTEAM_API_URL`. Added in commit `0a564e6`. |
| `GET /api/time/location-history` | manager | GunnerTeam live (`gunnerteam-time.ts`) | Trail button. Live proxy, same gate. Added in commit `0a564e6`. |

- The old `events`/`summary` routes still exist but are **unused** by this dashboard.
- Dev DB migration **0042** applied 2026-06-17.

## Maps integration

- Google Maps API key served via a **manager-gated runtime route `/api/maps/config`** — deliberately **not** a `NEXT_PUBLIC_` env var, keeping it out of the public JS bundle. `src/lib/google-maps.ts` (server-only) resolves the key env → SSM, mirroring the CompanyCam/Monday SSM pattern (see [[colin/aws-infra]]). Route returns `{key:""}` when unset and the client falls back to a static-plot SVG.
- **Key names:** `GOOGLE_MAPS_API_KEY` in `.env.local` (local dev); `GoogleMapsApiKey` as the SST secret (deployed) → SSM param `/wl-companycam/{stage}/google-maps-api-key` → IAM. Set via `sst secret set GoogleMapsApiKey <value>` then redeploy.
- `managers-map.tsx` replaced the old fake decorative SVG MiniMap with a **real Google Map** (blue check-in pins, red phone pin, green→per-leg colored trail polyline, click-for-detail popups, auto-fit bounds), **dependency-free** (hand-typed Maps API surface, no new npm package). Degrades to a static coordinate-projection SVG when the key is absent or auth fails — never blank.
- Loader requests only `maps/api/js` with `v=weekly` and loads no extra libraries, so the key's API restriction can be scoped to **Maps JavaScript API only** (plus Directions API for road-following routes).

### Key-restriction requirements (HTTP referrer)

- Use **Website / HTTP-referrer** restrictions, not IP.
- Allowlist **both bare origin AND wildcard path** — browsers may send only the origin as `Referer`; omitting the wildcard causes `RefererNotAllowedMapError` on page routes like `/my-day`:
  - `https://project.dev.gunnerroofing.com` **and** `https://project.dev.gunnerroofing.com/*`
  - `http://localhost:3000` **and** `http://localhost:3000/*` (Google treats `localhost` and `127.0.0.1` as separate referrers)
- No `gcloud` CLI available to automate — set in console.

## Route contours & trail rendering

Raw GPS phone pings are collapsed into named **route contours** (typically 4–8/day) by the pure helper **`src/lib/location-route-contours.ts`** before display or AI. The map numbers the contours; raw pings remain as evidence but aren't shown in the main rail. See [[colin/location-pings]] for the ping ingest side.

- **Stop contours** → solid numbered pin markers. **Travel contours** → colored road-following polylines with direction arrows (`SymbolPath`) and no marker.
- Clicking a travel leg isolates it and hides others (and Google POI labels); clicking the active contour again restores the full-day view.
- Road-following lines use `google.maps.DirectionsService` between numbered stages (`routes[0].legs[].steps[].path` / `overview_path`), replacing straight-line connectors. The parent passes **broad red contour stages** (not raw pings) as routing input; if Directions can't route a segment, no fallback line is drawn but markers still render. A **trail-keyed React state cache** prevents re-issuing billable Directions requests on hover/re-render.
- Within each travel-window contour, raw pings are fed as hidden Directions **"via" points** (not stopovers) to get a road-snapped trail — stopovers caused Google to route through every ping as a destination (parking-lot zigzags).
- **Per-leg colored polylines:** each travel leg is a separately colored segment with a white halo (replaced one flat green line); `day-location-dashboard.tsx` passes the Gemini travel-stage color per leg. Static fallback also draws separate colored segments (verified with 6 distinct strokes for Tyler Suffern).
- **De-dup gotcha (fixed twice):** the map originally collapsed *all* repeated points globally, dropping return-trip legs (home→job→home) and breaking selected-leg isolation. Fix in `managers-map.tsx`: remove only **consecutive** identical coordinates; harden leg isolation so a click always clears other legs, falling back to a direct connector if Directions returns fewer legs than expected.

## AI insights layer

Detail lives in [[colin/gemini-route-review]]; the integration points here:

- **Deterministic, always-on:** `src/lib/location-day-narrative.ts` generates plain-English per-step labels ("Phone trail only", "Likely heading into the day", "At job site", "After-hours phone trail") with no AI required — always renders.
- **Bedrock Claude path:** `src/lib/bedrock-claude.ts` (Converse API wrapper) + `src/lib/location-insights.ts` (context builder), gated by SST secret `BedrockClaudeModelId` (blank = dormant). Lambda granted `bedrock:InvokeModel`; dependency `@aws-sdk/client-bedrock-runtime` added. See [[colin/aws-infra]].
- The AI **coaching card** (grade, tips, contour notes) only appears when Gemini or Bedrock is configured and the manager clicks **"Route review"**; the deterministic narrative always renders beneath it.

## Verification & preview

- Project Managers panel verified live on dev **2026-06-18**: **40 people (11 managers, 29 employees)** with Active/Quiet rows and graceful no-data rows; Locate detail renders Google map chrome, assigned project pins, latest phone coords, and a stale/no-recent-update copy path; fleet map shows ~1–2 active pins at a time.
- Throwaway preview harness **`src/app/pm-dashboard-preview/page.tsx`** (route `/pm-dashboard-preview`) feeds the real component canned data (3 active + 10 idle managers) for localhost verification without a DB tunnel; opens cleanly because `DEV_AUTH_USERNAME` bypasses middleware in dev. **Should be deleted before merging.** Earlier bug: harness fell through to real `/api/time/*` data (showed live PM names/trails) — fixed by installing the mock API layer synchronously before the dashboard child mounts and hard-coding today's date dynamically.

## Known bugs / gotchas

See [[colin/gotchas]] for the cross-feature catalog.

| Bug | Status | Detail |
|---|---|---|
| **On-site duration** (e.g. "26h 35m") | **not yet fixed** | On-site minutes summed across multiple same-day check-ins without clamping to the day boundary. Bug is in the route/data layer, not the render. |
| **Date-change shrink / kick-out** | fixed | Panel centers via `transform: translate(-50%,-50%)`; on refetch the body was swapped for a ~280px spinner, collapsing/recentering the panel so a fast follow-up click landed on the backdrop (closed the dialog). Fix: keep prior content visible, dim it, show a progress bar — never swap the full body on refetch. |
| **Base UI `DialogTrigger` activation** | fixed | Trigger received focus but didn't open (render-prop and trigger-outside-root both failed; Base UI closed the dialog before it became visible). Resolved by replacing Base UI Dialog with a plain controlled modal (fixed overlay, `role='dialog'`, direct React state). |
| **External vs local user id mismatch** | fixed | Some check-in rows carry an external user id, breaking project-target matching to the roster. Fix: row-merge falls back to **name matching** when local user id is absent; project-target scoping loosened from global-role `'pm'` only to "any user in the corporation" with project assignment driving the list. |
| **`gm_authFailure` loader hang** | fixed | Google Maps reports key/referrer/quota failures via `window.gm_authFailure`, **not** script `onerror` or the init callback — a promise loader settling only on those two paths hangs forever. Fix: install a `window.gm_authFailure` handler (rejecting the shared `loadPromise`) before injecting the script tag, plus a ~12s timeout backstop. |
| **Empty `/api/maps/config` cached** | fixed | An empty config response was cached and never retried, leaving tabs that opened before the dev secret was set stuck on the static fallback. Patch: opening the panel or pressing refresh retries `/api/maps/config` if the last answer was empty — recovers a live tab without a hard reload. |
| **Day-locations popover width** | fixed | The popover modal needs an explicit responsive width or it shrinks to content width on 390px mobile. Fix fills ~362px of 390px without horizontal page overflow. |
| **`gm_authFailure` on dev** (2026-06-18) | needs console change | The `.env.local` Maps key returned `RefererNotAllowedMapError` for `https://project.dev.gunnerroofing.com` (worked on localhost). Dev domain must be added to referrer restrictions; until then colored legs / direction arrows / Directions routing fall back to static plot and aren't visually verifiable. |

## Architecture concerns / recommended refactors

- `day-location-dashboard.tsx` is **~3,540 lines** and fuses too many responsibilities into one client component (roster, check-in, phone summary, map config, fleet locate, history fallback, project targets, AI config/generation, timeline, contour display, modal UI).
- The client calls **six or more separate endpoints** instead of one server-assembled view model. Recommended direction: a single backend endpoint (e.g. `/api/time/manager-day-review`) returning a complete `ManagerDayReview` object so the browser stops stitching overlapping shapes.
- The dashboard blends site check-ins, phone pings, fleet/vehicle pings, AI-inferred positions, and project fallbacks as if equally authoritative. A future refactor should normalize all signals into one typed model with a **source-confidence field**. **Decision:** "Truck was here" ≠ "PM was here" — Verizon/vehicle pings must be labeled distinctly from person pings. See [[colin/location-pings]].

## Open questions / TODOs (as of 2026-06-21)

- **Continuous PM phone tracking has no production data source yet.** Recommended future architecture: a normalized `location_events` model fed by multiple sources — `project_site_checkin` (exists), Hexnode managed-device last-known position (read-only probe, key rotation needed), CompanyCam photo-capture pins, optional Verizon Connect for vehicles. **CT/NJ written-consent sign-off required** before any on-the-clock continuous tracking goes live. See [[colin/location-pings]].
- **Task Completion tab** is unfinished/placeholder (as of 2026-06-18) — wire to real task data or remove until ready.
- **To go fully live on `project.dev`** (remaining as of 2026-06-17): (1) deploy new Lambda code (dev Lambda still runs prior code); (2) set `GoogleMapsApiKey` via `sst secret set` + redeploy (Maps key was only set in `.env.local` locally); (3) have Tyler point his GPS ping stream at the new ingest endpoint `POST /api/external/v1/location-pings` (see [[colin/external-api-integration]], [[colin/location-pings]]).
