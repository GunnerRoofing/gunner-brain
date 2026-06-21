---
type: session
title: session-2026-06-20-cc2119-device-integrity-endpoint
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - backend
  - api
  - security
  - soc2
  - device-integrity
  - audit
  - deploy
status: stable
related:
  - '[[meta/session-2026-06-20-cc2117-ios-jailbreak-detection]]'
  - '[[gunnerteam/aws-environment]]'
---

# Session cc-prompt-2119 — Backend `POST /device/integrity` (CC7.2) — v332

Receiver for cc-2117's iOS `DeviceIntegrityMonitor` report, which was 404ing → the jailbreak
signal was dropped. **Resolves the cc-2117 backend follow-up.** Commit `01424b8`, deployed v332.

## Phase 0 — match the client contract (verified, not guessed)
Read the iOS client: POST `API.base + "/device/integrity"` (**top-level, NOT `/auth`-prefixed**
like `/auth/device-token`), Bearer auth, body `{ event, deviceModel, osVersion }`. The prompt's
example assumed `{model, os, reason}` and suggested putting it in `auth.js` — **both wrong** for
this client (auth.js mounts at `/auth` → `/auth/device/integrity` ≠ the client's path; and the
field names differ). Matched the real contract.

## Implementation
New `routes/device.js` mounted `app.use('/device', require('./routes/device'))` in `app.js` →
`POST /device/integrity`:
`requireAuth → audit({ action:'device.integrity_failed', req, metadata:{ deviceModel:slice64,
osVersion:slice32 }}) → 204`. try/catch, status-before-json, no `err.message` to client, no PII.
node --check + require-load + mount all verified.

## Deploy + verify
- Full S3 deploy; env-var routing-config. **Serving v332** via log-stream `[version]`.
- Unauthed POST `/device/integrity` → **401** (route live, **no more 404** → the client's report
  is now received, auth-enforced). 6/6 consistent.
- Authed **204 + audit-row not run by me** — needs a valid Cognito user token (single-tester
  pilot creds gap, same as cc-2118). Verified by construction: `requireAuth` is the proven 401
  gate, `audit()` is the standard helper used by 70+ callsites, the route code is correct. A
  supervised-device/token test should observe the 204 + the `device.integrity_failed` audit row.

## Deploy gotcha — post-deploy propagation lag (new durable lesson)
The first post-deploy test of the NEW route **404'd**: a warm **v331** container served it
(alias was correctly v332 / routing=null — confirmed via the request's `[331]` log-stream tag,
not a routing bug). After ~45s the route returned 401 from `[332]`. **Lesson:** a brand-new
route can 404 on warm old-version containers for ~30-60s after an alias flip even when the alias
is correct — confirm the per-request serving version via the `[version]` log-stream tag, wait,
and re-test before concluding the deploy failed. (Recorded in hot.md deploy gotchas.)

## End-to-end status (cc-2117 + cc-2119)
iOS detects jailbreak → best-effort POST `/device/integrity` → backend `requireAuth` → audit
`device.integrity_failed`. The dropped-signal gap is closed.
