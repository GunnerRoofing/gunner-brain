---
type: session
title: session-2026-06-20-cc2126-time-jobid-preflight
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - backend
  - security
  - soc2
  - tenant-isolation
  - fieldportal
  - deploy
status: stable
related:
  - '[[meta/session-2026-06-20-cc2125-forms-auth-lockdown]]'
  - '[[gunnerteam/soc2-technical-summary]]'
---

# Session cc-prompt-2126 — Org-ownership preflight on client-supplied jobId (time.js) — v341

`POST /time/checkin` took `req.body.jobId` and both wrote it into org-scoped `gt_time_entries` AND
forwarded it to Field Portal **without verifying the job belongs to `req.orgId`** — violating the
CLAUDE.md rule (client-supplied resource IDs must be org-verified before writes/upstream proxy, 404
on miss; CC6.1). Single-tenant today so no real exposure, but a clear rule violation / pentest
finding. Commit `e607ae2`, deployed **v341** (rollback v340).

## Phase 0 — map
Only ONE route consumes a client jobId: `/checkin` (req.body.jobId, line 109) → writes org-scoped +
forwards to FP. Checkout uses the server-side `rows[0].job_id` (already org-scoped, not
client-supplied) → no preflight. forms.js/Monday IDs deliberately out of scope (integration being
removed).

## Preflight (mirrors fieldportal.js's proven org-verify)
After the `if(!jobId)` 400 and BEFORE any write/proxy:
```js
const job = await ccFetch(`/projects/${encodeURIComponent(jobId)}`).catch(() => null);
if (!job) return res.status(404).json({ error: 'job_not_found' });
```
ccFetch throws on non-2xx (incl. 404) → caught → 404, never leaking existence. ccFetch's default
~5s `UPSTREAM_TIMEOUT_MS` bounds it (no hang).

## Single Field-Portal client (the refactor)
`ccFetch` lived in `routes/fieldportal.js`, un-exported, alongside BASE (22 uses) / apiKey (20) /
upstreamFetch (19) used throughout that 1781-line file. Extracted the whole client block
(`BASE`, `apiKey`, `upstreamTimeoutMs`, `upstreamFetch`, `ccFetch`) verbatim into
**`lib/fieldPortalClient.js`**. `fieldportal.js` now imports `{ BASE, apiKey, upstreamFetch, ccFetch }`
(dropped the now-dead `upstreamTimeoutMs` import) — one deletion block (183-213) + one import line,
~40 internal callsites unchanged. `time.js` imports `{ ccFetch }`. No import cycle (the client
requires only perf + secrets). `FIELD_PORTAL_API_URL` is config (env); `FIELD_PORTAL_API_KEY` is the
cc-2123 runtime secret, so `apiKey()` stays a function (not a captured constant).

## Deploy + verify
v341 (rollback v340). Verified: `/health` 200; migration probe `ok:true` (the full refactored module
graph — including fieldportal.js importing the shared client — loads live; DB fine); unauthed
`POST /time/checkin` → 401 (requireAuth intact; preflight runs only after auth); require-load smoke
OK. (First probe hit `/checkin` at root → 404 = Express unmatched-route default; the route is
`/time/checkin` — time.js mounts at `/time`.)

## Limitations (honest)
- Authed 200 (valid job) / 404 (bogus job) not exercised live — no Cognito RS256 token to forge.
  Verified by construction + parity: the preflight is byte-identical in pattern to fieldportal.js
  lines 582-587 / 636-640 and now calls the literally-same shared `ccFetch`.
- **TRADEOFF (prompt-accepted fail-closed):** check-in now requires Field Portal reachable. If FP is
  down, check-in returns 404 instead of the prior succeed-and-fire-and-forget-push. Bounded to ~5s by
  the timeout. (Previously the FP push was fire-and-forget and check-in always succeeded.)

## Flagged (out of scope, per prompt)
The real tenant-isolation backstop — a `NOSUPERUSER`/`NOBYPASSRLS` app DB role + the deliberate
RLS-vs-app-scoping decision — lives partly in the `gunner-masterdb` SST stack (Colin); a
pre-second-tenant gate, tracked separately.
