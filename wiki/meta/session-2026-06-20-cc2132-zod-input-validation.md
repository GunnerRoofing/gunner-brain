---
type: session
title: session-2026-06-20-cc2132-zod-input-validation
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - backend
  - security
  - soc2
  - validation
  - zod
  - deploy
status: stable
related:
  - '[[meta/session-2026-06-20-cc2131-codify-standards-claude-md]]'
  - '[[meta/session-2026-06-20-cc2125-forms-auth-lockdown]]'
  - '[[gunnerteam/soc2-technical-summary]]'
---

# Session cc-prompt-2132 — zod input-schema validation on the write surface (CC6.1/CC7.1) — v344

Replaced ad-hoc `if(!field)` checks with declarative zod schemas + a `validate()` middleware so every
accepted payload is type-checked, length-bounded, and consistently 400'd (field/message only, no
internals) before handler logic. Defense-in-depth. Framework + the security-relevant **write** surface;
read/query endpoints are a follow-on. Commits `120ccbf` (code) + `3851a4f` (CLAUDE.md note), deployed
**v344** (rollback v343).

## Framework
- `lib/validate.js`: `validate({ body, query, params })` middleware — parses, strips unknowns, replaces
  req.*, and on ZodError returns `400 { error, fields:[{path,message}] }` (no internals).
- `schemas/common.js`: shared zod primitives. zod v4 (`^4.4.3`, declared) — top-level `z.uuid()`/
  `z.email()`. `nonEmptyStr` has NO `.trim()` so it mirrors the old `!field` (accepts `"  "`) exactly.

## iOS-compat — the make-or-break rule (cf. cc-2125)
Each schema mirrors the **currently-accepted** payload: required set = the route's prior `if`-checks
(which the app already satisfies, since the app works today), everything else the handler reads is
OPTIONAL, unknowns stripped, ids/amounts accept `number|string`. Never newly-reject a field the app
sends/omits. Insight: deriving the required set from the existing `if`-checks *guarantees* no new
rejection without needing to chase every iOS payload.

## Converted (the first batch)
- **forms.js** (`/`, `/submit-ap`, `/submit-co`, `/submit-dumpster`, `/submit-material`): base
  if-checks → schemas; `ALLOWED_BOARD_IDS` + the material-option switch kept. (`/submit-co`
  `dateSubmitted` is read unconditionally → required.)
- **auth.js** (forgot-password, reset-password, complete-invite): `validatePasswordPolicy()` untouched;
  password schema = presence only.
- **time.js** (`/checkin`): jobId required, lat/lng optional (devices omit them); cc-2126 ccFetch org
  preflight intact.
- **users.js** (PATCH/DELETE `/users/:id` + location-consent): **`:id` is `nonEmptyStr`, NOT uuid** —
  `users.id` is VARCHAR and the handlers bind it as a plain string (the CLAUDE.md caveat); all body
  fields optional; membership pre-flight + `AdminUserGlobalSignOut` + `invalidateUserCache` kept.
- **webhooks** (points `/webhook`, `/redemption-webhook`, fieldportal photo+project comment): validated
  via **in-handler `safeParse` AFTER HMAC + dedup** (NOT a pre-handler middleware — order unchanged).
  `points` = `nonNegInt`; envelopes optional-leaning (handlers already guard every access).

## Execution (parallel)
Built the framework + the riskiest domain (forms) myself as the exemplar, then fanned out
auth/webhooks/time/users to **4 parallel `task` subagents** (disjoint files) against that pattern with
strict iOS-compat rules; each wrote its schema + wired routes + a real-payload test. I then verified,
deployed, and reviewed.

## Verify
- **79/79 `node --test` pass**, including real-client-payload fixtures per schema — the runnable
  iOS-compat proof (real payload parses, malformed throws, unknowns stripped).
- `check` / `check:logs` / `check:orgscope` green; all 6 edited route files require-load (no
  missing-ref, CLAUDE.md cc-1108); HMAC confirmed before every webhook `safeParse`.
- Deployed v344: `/health` 200, migration probe `ok:true` (validation layer loads), forms+checkin
  unauthed → 401 (requireAuth before validate), webhook bad-sig → 401 (HMAC first), clean logs.
- Limitation: live authed-200 not exercised (no Cognito RS256 token) — covered by the fixture tests +
  construction.

## Follow-on
- Extend schemas to read/query endpoints (pagination/query params). CLAUDE.md now states "new routes
  ship with a zod schema by default" (Security & Engineering Standards → Input validation).
