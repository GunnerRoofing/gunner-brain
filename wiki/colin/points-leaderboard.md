---
type: reference
owner: colin
app: GunnerCam
created: 2026-06-21
updated: 2026-06-21
tags: [wl-companycam, points, gunnerteam]
status: active
---

# Points & Leaderboard

GunnerCam renders a points/leaderboard view that is **strictly read-only** from Tyler's GunnerTeam app. All scoring, compliance, and ledger logic stay in GunnerTeam — no local scoring tables or rewards plumbing were added. Locked in [[colin/decisions]]. GunnerCam's only write into the system is an outbound, signed **points webhook** that reports activity events; GunnerTeam decides how to award them.

## The `/points` page

| Concern | Location |
|---|---|
| Page (server-rendered) | `src/app/(app)/points/page.tsx` |
| Read-through client | `src/lib/gunnerteam-points.ts` |
| UI component | `src/components/points-dashboard.tsx` |
| Unit tests | `src/lib/gunnerteam-points.test.ts` |

- The "Your Points" link is wired into the sidebar, topbar menu, and floating user menu. It is **hidden from crew principals** because the GunnerTeam points API is per-user.
- The client calls `/points/balance`, `/points/history`, `/points/achievements`, and `/points/leaderboard` in parallel and normalizes them into a stable UI model.
- When no Cognito access token is present (e.g. local dev), the page renders a graceful "unavailable" state rather than calling upstream.

## Auth: user token vs. service-key fallback

This is the crux of the feature and the source of its current partial state.

| Call | Auth used | Falls back to service key? |
|---|---|---|
| `/points/balance` | user WL Cognito access token | No |
| `/points/history` | user WL Cognito access token | No |
| `/points/achievements` | user WL Cognito access token | No |
| `/points/leaderboard` | user token, else `GunnerteamServiceKey` | **Yes** (org-gated) |

- The client first uses the user's WL Cognito access token, reusing the base URL + token pattern of the existing `gunnerteam-time` read-through client (see [[colin/location-pings]]). No new SSM secret or infra was added for the read-through path — the existing GunnerTeam base URL in SSM already covers `/points/*`.
- **GunnerTeam's `/points/*` endpoints reject WL Cognito access/ID tokens** (those belong to GunnerCam's own Cognito pool) but **accept `GunnerteamServiceKey` for leaderboard queries.** Live dev verification: service key → `/points/leaderboard` = HTTP 200; seeded WL Cognito tokens → rejected. This is the root cause of the page's **partial-warning state**: leaderboard is live, personal stats are unavailable.
- Only the org `/points/leaderboard` call falls back to the server-side `GunnerteamServiceKey`. Balance, history, and achievements stay user-token-only. Fallback shipped as commit `083d6d0` on `dev`.

## Service-key org-gating (security fix)

- The service-key leaderboard fallback is scoped **exclusively** to callers whose WL corporation has slug `'gunner'`. Enforcement is a DB check against the verified WL principal: `eq(corporations.id, principal.corporationId)` + `eq(corporations.slug, 'gunner')` — **not** anything in the rejected upstream GunnerTeam token. A forged or invalid token cannot widen results to another org.
- Commit `bbb097c` (2026-06-18) fixed a security gap in the initial `083d6d0` fallback, which did not org-gate the service key. The client fallback branch is now guarded with `if (!allowServiceKeyFallback) throw err`. A valid non-Gunner WL user cannot trigger the service-key path.
- `GunnerteamServiceKey` is an SST secret syncing to SSM at `/wl-companycam/{stage}/gunnerteam-service-key`, read as env var `GUNNERTEAM_SERVICE_KEY` in local dev. Used **server-side only** — for this leaderboard fallback and for the location-compliance / fleet-locations / location-history proxy endpoints (see [[colin/location-pings]]). It is distinct from GunnerTeam user Cognito tokens.

## Leaderboard empty-state contract

GunnerTeam's leaderboard endpoint returns `{ tooFew: true, items: [] }` when too few members have opted in. This is an **expected** response shape, not an error — the UI renders an empty/pending state. Data only appears once enough members enroll/consent.

## Outbound points webhook (GunnerCam → GunnerTeam)

GunnerCam reports activity that GunnerTeam may score.

- **Signing:** HMAC-SHA1 over the raw JSON body, base64-encoded, in header `X-CompanyCam-Signature`. This **deliberately differs** from the internal push-webhook SHA256 convention — choice locked in [[colin/decisions]].
- **Endpoint:** `https://api-dev.team.gunnerroofing.com/points/webhook`. SST secret `GunnercamPointsWebhookToken` syncs to SSM at `/wl-companycam/{stage}/gunnercam-points-webhook-token` (env `GUNNERCAM_POINTS_WEBHOOK_TOKEN`).
- **Events:** `photo.created`, `task.completed`, `todo_list.completed` (mapped from phase/checklist completion). GunnerTeam maps users via `creator_id` / `completed_by_id` + `creator.email`, plus `project_id`. Events fire **best-effort after DB writes succeed**, so a failed write never emits an event. The dispatcher is **dormant** if either the endpoint URL or token is absent.
- **Point values:** GunnerCam owns the values and includes them inside the signed (authenticated) payload; GunnerTeam awards whatever integer is supplied and falls back to its own defaults if absent. As of 2026-06-21 the baked values are:

| Event | Value |
|---|---|
| `photo.created` | 5 |
| `task.completed` | 10 |
| `todo_list.completed` | 25 |

  GunnerTeam ignores negative, non-integer, or absurd (`>1000`) values as a safety check. Values recorded in [[colin/decisions]].

## Webhook debugging notes (2026-06-19)

- An initial `429 Too Many Requests` from GunnerTeam's dev webhook was a **GunnerTeam-side outage** (API Gateway throttle set to 0/0 + Lambda in the wrong VPC), not a signing failure. The 429 fired *before* the Lambda, so the HMAC signature was never evaluated.
- After the outage was fixed, requests reached the verifier and returned `401 bad signature` — correctly indicating a shared-secret mismatch rather than a signing-scheme problem.

## Open questions / TODOs (as of 2026-06-21)

- **Webhook shared-secret alignment unresolved.** At the 2026-06-19 session end, all three signed events returned `401 bad signature`. GunnerCam dev signs with `GUNNERCAM_POINTS_WEBHOOK_TOKEN` (its value's SHA-256 = `70f9321c9856d56211bbd39d457a752dbd9ef72921b5ef892a6b895e5a5b7c97`); GunnerTeam confirmed the hash matches their SSM config, but their live Lambda had a stale baked token that was being re-baked at session end. Verify the 401s clear once GunnerTeam re-bakes. See [[colin/gotchas]].
- **Personal points stats stay unavailable.** Balance / history / achievements cannot render on `/points` because GunnerTeam rejects WL Cognito tokens. Resolving this requires GunnerTeam to either accept WL tokens or provide a per-user service path. Today only the leaderboard works (via service key).
