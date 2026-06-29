---
type: session
title: 'cc-3100 + cc-3102: Weather Feature — OpenWeather foundation + NWS default'
owner: gunnerteam
created: '2026-06-29'
updated: '2026-06-29'
tags:
  - session
  - weather
  - nws
  - lambda
  - api
status: stable
related:
  - '[[gunnerteam/aws-environment]]'
  - '[[gunnerteam/overview]]'
---
# Session — cc-3100 + cc-3102: Weather Feature (OpenWeather foundation → NWS default)

## What Was Built

### cc-3100 — Weather foundation (done, committed d69c49e)

`src/lib/weather/` is a provider-swappable weather stack:

- **`provider.js`** — selects the active provider via `WEATHER_PROVIDER` env; originally defaulted `openweather`.
- **`openweather.js`** — OpenWeather One Call 3.0 implementation. Reads `WEATHER_API_KEY` at runtime via `getSecretSync`. Includes a daily call budget guard (`WEATHER_MAX_CALLS_PER_DAY`, default 5000) that throws `WeatherBudgetError` on exhaust. Units imperial, daily excluded.
- **`cache.js`** — in-memory TTL map keyed by `lat.toFixed(2),lng.toFixed(2)`. TTL via `WEATHER_CACHE_TTL_MS` (default 10 min). Mirrors the `highAlertCache` pattern.
- **`index.js`** — `getJobWeather({lat,lng})`: cache read-through → provider → trimmed payload (`current`, `hourly[0:8]`, `alerts`, `precipOnsetMinutes` from minutely window).
- **`routes/weather.js`** — `GET /weather/job/:jobId`: `requireAuth`, org-verifies the job via `ccFetch` (fail-closed → 404), degrades to `{ available: false }` on no coords or budget exhaust, 502 on provider error.

Terraform: 5 weather env vars added (`WEATHER_PROVIDER`, `OPENWEATHER_BASE_URL`, `WEATHER_MAX_CALLS_PER_DAY`, `WEATHER_TIMEOUT_MS`, `WEATHER_CACHE_TTL_MS`). `WEATHER_API_KEY` stays SSM SecureString only.

Deployed as Lambda **v400**.

> **Open prerequisite:** `/gunnerteam/dev/WEATHER_API_KEY` SSM SecureString must be provisioned before OpenWeather can carry live traffic. With cc-3102 making NWS the default, this is only needed if reverting.

---

### cc-3102 — NWS provider + flip default (done, committed 4a78082)

**Why NWS:** free, no API key, no spend cap, government-authoritative for CT/NJ alerts and hourly forecasts. The OpenWeather impl stays registered as a fallback (`WEATHER_PROVIDER=openweather` reverts).

#### New files

**`src/lib/weather/contract.js`** — Shared provider contract documentation + `eventToKind` mapper.

The normalized shape every provider must return:
```js
{
  current:  { tempF, windMph, windGustMph|null, shortForecast },
  hourly:   [{ time, tempF, windMph, windGustMph|null, popPct, shortForecast }],  // next ~8
  minutely: null | { precipOnsetMinutes },  // null for NWS
  alerts:   [{ id, event, severity, kind }] // kind ∈ 'lightning'|'snow_ice'|'high_wind'|'other'
}
```

`eventToKind(event)` rules (lower-case partial match, first-wins):
| Pattern | Kind |
|---|---|
| `tornado`, `severe thunderstorm` | `lightning` |
| `winter storm`, `ice storm`, `blizzard`, `winter weather`, `freezing`, `sleet`, `ice` | `snow_ice` |
| `wind advisory`, `high wind`, `extreme wind` | `high_wind` |
| _(anything else)_ | `other` |

`evaluate.js` keys off `kind`, never raw event strings.

**`src/lib/weather/nws.js`** — Full NWS implementation.

Three-request flow per call (points cached 24h per coord):
1. `GET /points/{lat},{lng}` → `properties.forecastHourly` URL. Cached `NWS_POINTS_TTL_MS` (default 24h).
2. `GET {forecastHourly}` → `properties.periods[]`. Maps: `temperature`→`tempF` (respects `temperatureUnit`), `windSpeed` string ("10 mph" / "5 to 10 mph" → max int) → `windMph`, `probabilityOfPrecipitation.value` → `popPct`. `current = periods[0]`. `windGustMph = null` (requires `forecastGridData`; not fetched — high-wind events caught via NWS alerts instead). Cached `NWS_FORECAST_TTL_MS` (default 30m).
3. `GET /alerts/active?point={lat},{lng}` → `features[].properties`. Maps `event` → `kind` via `contract.js`. Cached `NWS_ALERTS_TTL_MS` (default 10m).

Hourly + alerts fetched via `Promise.allSettled`; alerts failure returns `alerts: []` (non-fatal). Points failure propagates (can't resolve the grid URL).

**Required env:** `NWS_USER_AGENT` — NWS 403s without an org-identifying User-Agent. Set in Terraform. Never hardcoded in source.

#### Modified files

**`provider.js`** — registered `nws`; default changed to `'nws'`.

**`terraform/lambda-api.tf`** — weather block replaced:
```
WEATHER_PROVIDER     = "nws"
NWS_BASE_URL         = "https://api.weather.gov"
NWS_USER_AGENT       = "GunnerTeamAPI/1.0 (gunnerteam-api; contact tyler@gunnerroofing.com)"
NWS_POINTS_TTL_MS    = "86400000"
NWS_FORECAST_TTL_MS  = "1800000"
NWS_ALERTS_TTL_MS    = "600000"
OPENWEATHER_BASE_URL = "https://api.openweathermap.org/data/3.0/onecall"  ← kept for fallback
WEATHER_MAX_CALLS_PER_DAY = "5000"
WEATHER_TIMEOUT_MS   = "4000"
WEATHER_CACHE_TTL_MS = "600000"
```

**`test/weather.test.js`** — 28 unit tests (`node:test`):
- `eventToKind`: 18 fixtures covering all 4 kinds + edge cases (empty string, null, undefined)
- `parseWindMph`: 10 fixtures covering single value, range, "Calm", null/undefined

All 28 pass.

Deployed as Lambda **v403**.

---

## Verification

**Unit tests:** 28/28 pass (`node --test test/weather.test.js`).

**`node --check`:** all 4 weather lib files clean.

**Live NWS smoke (Stamford CT 41.0534, -73.5387):**
- `GET /points/…` → **200**, `forecastHourlyUrl` resolved to `OKX/47,60`
- `GET forecastHourly` → **200**, 156 periods, `current = 86°F, 9 mph, Sunny, popPct=4`
- `GET /alerts/active?point=…` → **200**, 2 features (`Air Quality Alert` → `other`, `Extreme Heat Watch` → `other`)
- `getConditions()` in-process: `current`, 8 `hourly`, `minutely: null`, `alerts[0].kind='other'`
- User-Agent accepted — no 403

**Lambda:** v403 alive, `requireAuth` returns 401 on unauthenticated requests as expected.

---

## Key Design Decisions

- **NWS as default** — no key, no budget, no ops overhead. OpenWeather stays registered; one env var flip reverts.
- **Budget check skipped for NWS** — `checkBudget()` lives in `openweather.js`, not the shared index. NWS provider never calls it. `WeatherBudgetError` is still exported from `index.js` for route compatibility.
- **`windGustMph = null` for now** — real gusts require `GET /forecastGridData` (a fourth request). High-wind events are still caught via NWS Wind Advisory / High Wind Warning alerts → `high_wind` kind. Gust values are a follow-on if needed.
- **`minutely: null`** — NWS has no 1-minute nowcast. `precipOnsetMinutes` in `index.js` returns `null` when `minutely` is `null` (the `Array.isArray` guard already handles this).
- **Three separate caches** — points are stable per coord (24h), forecasts change hourly (30m), alerts change fast (10m). Separate Maps by purpose.
- **`Promise.allSettled` for hourly + alerts** — alerts failure degrades to `alerts: []`; the weather card still shows. Hourly failure logs a warning (no useful `current` → the card will show incomplete data; acceptable over a silent 500).

---

## Open Items

- `WEATHER_API_KEY` SSM SecureString — not provisioned (only needed if `WEATHER_PROVIDER=openweather`).
- `windGustMph` — always `null` until `forecastGridData` is wired (optional follow-on).
- `evaluate.js` (cc-3101) — the downstream consumer of the contract; wires alert `kind` into job scoring. Separate prompt.
