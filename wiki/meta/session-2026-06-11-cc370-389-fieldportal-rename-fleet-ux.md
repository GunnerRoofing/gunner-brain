---
type: session
owner: tyler
created: 2026-06-11
updated: 2026-06-11
tags: [gunnerteam, ios, backend, infra, rename, fleet, ux]
status: complete
related:
  - "[[tyler/hot.md]]"
  - "[[tyler/Memory.md]]"
---

# cc-370–389: Field Portal Rename, Fleet UX, Auth Fix, Jobs Polish

**Session date:** 2026-06-11 (third session)
**Lambda at session end:** v171 live (prod Aurora)
**iOS:** BUILD SUCCEEDED throughout

---

## Field Portal Rename (cc-371, cc-372, cc-387, cc-388)

- **cc-371:** `companycam.js` → `fieldportal.js`; all `CC_BASE`/`ccKey`/`COMPANYCAM_API_KEY` → `BASE`/`apiKey`/`FIELD_PORTAL_API_KEY`; `pushColin*` → `pushFieldPortal*`; `COLIN_API_*` → `FIELD_PORTAL_API_*`; `app.use('/companycam')` → `app.use('/fieldportal')`; start.sh + .env.example updated; SSM params migrated; v166
- **cc-372:** iOS `/companycam/` → `/fieldportal/` URL path sweep; `CC*` data model types → `FP*` (`FPJob`, `FPPhoto`, `FPLabel`, `FPFile`, `FPActivityDay`, `FPPhotosPage`, etc.); `CCModels.swift` → `FPModels.swift`, `CCCommentsView.swift` → `FPCommentsView.swift`; camera-internal `CCVideoDelegate`/`CCCameraModel`/`CCDualCameraModel` left unchanged; v167
- **cc-387:** `BASE` hardcode removed → reads `FIELD_PORTAL_API_URL` env var; all `COMPANYCAM_*` webhook secret refs → `FIELD_PORTAL_*`; old secrets kept in Lambda env until webhook confirmation; v169
- **cc-388:** `ccFetch` logs `[fieldportal] GET /path → 200 (312ms)` for every call; v170

## Colin / Field Portal Push (cc-370, cc-381)

- **cc-370:** `pushFieldPortalCheckin`/`pushFieldPortalCheckout` helpers added; fire-and-forget, skip if env unset; COLIN_API_URL/KEY added to start.sh + .env.example; v165
- **cc-381:** Both pushes now `await`ed before `res.json()`; `displayName` added to both payloads; v168

## Auth Fix (cc-100)

- `POST /auth/validate` role resolution replaced 3-table `LEFT JOIN` chain with `LEFT JOIN LATERAL` subquery scoped to `slug = 'gunner-team'`, matching `GET /users`
- Root cause: `LEFT JOIN apps app ON app.id = ar.app_id AND app.slug = 'gunner-team'` was a join condition not a WHERE clause — any app role leaked through COALESCE
- v171

## Jobs UX Polish (cc-382–386)

| cc | Change |
|----|--------|
| 382 | Distance badge moved to own VStack row (was inside address HStack, causing variable position) |
| 383 | `hasFetched` guard allows re-fetch when `jobs.isEmpty`; "Refresh" button on empty state; pull-to-refresh resets `hasFetched` |
| 384 | Address `lineLimit(2)` → `lineLimit(1)` for uniform card height; CHECKED IN pill moved inline with customer name |
| 385 | `checkOut()` promoted from `private` to `internal`; Check Out button added to `JobGuidedView` overlay |
| 386 | Loading skeleton wrapped in refreshable `ScrollView`; 20s fetch timeout → transitions to error state |

## Fleet UX (cc-389)

- `VehicleDetailView.onDeleted` callback fires before `dismiss()` on successful delete
- `VehicleListView.vehicleGroupSection` passes `{ vehicles.removeAll { $0.id == vid } }` — instant list update without reload
- `UserVehicleListView` passes `{ await load() }` (no single vehicles array)
- `AddVehicleSheet` type picker: full strings → Truck/Gutter/Metal/Trailer short labels

## GeocodingCache Deprecation Fix

- `GeocodingCache.swift`: `CLGeocoder().geocodeAddressString()` replaced with `MKLocalSearch` async (`item.location.coordinate`) matching pattern from `CheckInManager`

## Infra Notes

- **awsmfa broken on Python 3.14** — `~/.zshrc` function fixed to use `json.loads(sys.stdin.read())`
- **MFA session expiry** — needs manual refresh before each deploy. Commands produce `ExpiredToken` silently if MFA session expired.
- **Live alias verified** — always confirm `DB_HOST` points to prod Aurora after deploy; has silently reverted to dev Aurora multiple times

---

## Lambda Deploy History This Session

| Version | Key Change |
|---------|------------|
| v165 | cc-370 Colin push wired |
| v166 | cc-371 Field Portal rename |
| v167 | cc-372 /fieldportal route live |
| v168 | cc-381 await pushes + displayName |
| v169 | cc-387 BASE from env + webhook secret rename |
| v170 | cc-388 ccFetch timing log |
| v171 | cc-100 auth/validate LATERAL role fix |
