---
type: session
title: session-2026-06-20-cc2125-forms-auth-lockdown
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - backend
  - ios
  - security
  - soc2
  - forms
  - deploy
status: stable
related:
  - '[[meta/session-2026-06-20-cc2124-db-password-runtime]]'
  - '[[gunnerteam/soc2-technical-summary]]'
---

# Session cc-prompt-2125 — Lock down the unauthenticated forms routes (CC6.1/CC7.2) — v340

`POST /` (IT request) and `POST /submit-ap` had no `requireAuth`, no rate limiter, and /submit-ap
had no `audit()` — anonymous callers could create Monday items / AP entries under the shared token.
Brought them in line with the already-authed siblings. Commit `9763fc7`, deployed **v340** (rollback
v339).

## Backend (`forms.js`)
- Added a distributed `formsLimiter`: `express-rate-limit` + `DynamoRateLimitStore`
  (`windowMs` 60s, `max` 30, `prefix: 'forms'`, in-memory fallback when `RATE_LIMIT_TABLE` unset).
  Used the **default import** `const rateLimit = require('express-rate-limit')` to match the working
  `points-webhook.js` sibling — one repo convention. (v8.5.2 exports both default + named; the
  prompt's named-import snippet would break on older majors, and the sibling uses default.)
- Gated both routes: `router.post('/', requireAuth, formsLimiter, idempotency, …)` and
  `router.post('/submit-ap', requireAuth, formsLimiter, idempotency, …)` — `requireAuth` first so the
  limiter keys on the authenticated principal.
- Audits: added `req` to the IT `forms.submitted` audit (was missing org/user/IP) + a new
  `forms.submitted` audit on `/submit-ap` after a successful create (mirrors `/submit-co`). Verified
  in `audit.js` that `audit({req})` extracts `org_id`/`user_id`/`ip` from `req`.

## iOS finding — the prompt's "app unaffected" premise was wrong
`FormSubmitExecutor.prepareNextTransfer` attaches the Cognito Bearer **only when
`payload.requiresAuth` is true** (API.session does NOT auto-inject the token). The two routes being
gated were built with `FormSubmitPayload(requiresAuth: false)`:
- `ITRequestView.swift:474` (createURL = `API.base + "/"`) → `false`.
- `APFormView.swift:603` (`/submit-ap`) → `false`.
So gating the backend alone would 401 the app. Flipped both to `true`.

**Latent bug also found + fixed:** `ChangeOrderView.swift:665` (`/submit-co`) was `requiresAuth: false`
even though `/submit-co` is ALREADY backend-gated → online Change-Order submits were 401ing /
dead-lettering. Flipped to `true` (risk-free: a valid token is always accepted; this aligns the app
with the gated backend). `DumpsterSwapView`/`MaterialShortageView` were already `true`. All 5 forms
now match their backends.

## Deploy + verify
Full S3 deploy → publish v340 → alias flip (rollback v339). **Propagation lag (cc-2119) recurred**:
the first unauthed probes hit warm v339 containers (POST / → 500 Monday column error; /submit-ap →
200, created a real item `12329001233`) while `/submit-co` 401'd (gated in both versions). Re-tested
after ~75s with **empty bodies** — a deliberate discriminator: stale v339 returns 400 (missing
fields, before any Monday call → no side effect); v340 returns 401 (requireAuth before validation).
Result: both routes **401 ×3/3**, `/submit-co` 401, `/health` 200. Confirmed the deployed v340
artifact's `forms.js` carries `requireAuth, formsLimiter` on both routes.

## Limitations (honest)
- Could not run a live authed create — no Cognito RS256 token to forge. Authed path verified by
  construction: `requireAuth` → unchanged handler → `audit` mirrors the working `/submit-co`.
- iOS build NOT re-run: the three edits are literal `false→true` bool flips (compile-safe); the
  auth-send behavior is confirmed by reading `FormSubmitExecutor` + parity with working authed forms.
- **Rollout caveat:** existing app installs on the pre-cc-2125 build (requiresAuth:false) will 401 on
  IT-request/AP until they update — unavoidable with backend gating; acceptable in dev (developer
  controls the build; Monday is being removed pre-white-label).
- Test artifact: one junk AP Monday item `12329001233` created during the pre-propagation probe.
