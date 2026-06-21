---
type: session
title: session-2026-06-20-cc2017-video-capture-date
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - ios
  - backend
  - offline
  - gallery
  - deploy
status: stable
related:
  - '[[meta/session-2026-06-20-cc2016-banner-navbar]]'
  - '[[gunnerteam/aws-environment]]'
---

# Session cc-prompt-2017 — Video capture date for gallery day-grouping (iOS + backend)

Uploaded job **videos** grouped under "Unknown Date" (photos grouped correctly). Root: the
video confirm sent no capture date → `FPFile.createdAt` null → `FPFile.dateLabel` = "Unknown Date".

## Changes (commit `d8579d0` on `main`)

- **iOS** `VideoUploadExecutor`: `VideoUploadPayload` gains `capturedAt: String?` (ISO8601);
  `finalize` adds it to the `/jobs/:id/confirm` body when present.
- **iOS** `JobPhotoSessionView.submit()`: computes `capturedAt` at ENQUEUE from the recorded
  file's `.creationDateKey` (fallback `Date()`), persisted in the payload so it survives a
  deferred/offline upload (capture day, not upload day).
- **Backend** `fieldportal.js` `/jobs/:jobId/confirm`: now reads `capturedAt` from the body and
  forwards `capturedAt: capturedAt || new Date().toISOString()` to Colin's `/projects/:id/files`
  (previously ALWAYS overrode with server now()). Mirrors cc-1705 `tag` forwarding; jobId still
  org-verified.

## Key discovery

The backend confirm route **already** sent `capturedAt: now()` to Colin's `/files`. Videos still
showed "Unknown Date" → **Colin's `/files` does not persist/return `createdAt`** (the flagged
dependency). So the iOS+backend forward is the lowest-layer fix we own, but the user-visible fix
is **BLOCKED on Colin** returning `createdAt` from `/projects/:id/files` (same situation as `tag`
in block 1700). If/when he returns it, videos will group by the forwarded capture day automatically.

## Deploy — v324 live (and a canary-weight scare)

Deployed via the full S3 block (`--profile mfa` session was valid). **published v324 → alias `live`.**
- **Gotcha:** immediately after `update-alias` (with the correct explicit
  `--routing-config '{"AdditionalVersionWeights":{}}'`), `get-alias` returned
  `AdditionalVersionWeights {"323": 1.0}` — looked like the cc-867 stale-canary bug (100% to old
  v323). It was **eventual consistency**: re-reads settled to `{"323": 0.0}` then `null`. Final
  state verified: `FunctionVersion 324, Routing null`. No CodeDeploy app exists. **Lesson: after
  update-alias, get-alias can return stale routing for a few seconds — re-verify before panicking.**
- **Health:** `aws lambda invoke gunnerteam-dev-api:live` → StatusCode 200, Express returned a
  clean `404` + helmet security headers on an unknown route. v324 boots + serves.
- **Note:** v324 = `main` code, which does NOT include the cc-2101 dependency fixes (those are in
  PR #6, unmerged) — so v324 still carries the node-forge/multer high advisories. Merging PR #6 +
  redeploy clears them. (Deploying main was correct for this prompt; flagging for awareness.)

## node_modules gotcha

After `git checkout main` from the cc-2101 branch, `node_modules` still had cc-2101's deps
(node-apn 8.1.0). Ran **`npm ci`** before zipping to restore main's lock (node-apn 7.1.0) so the
deploy was reproducible from the committed lockfile, not branch leftovers.

## Verification status

- iOS build clean; backend check + 4 tests pass; v324 deployed + healthy.
- End-to-end ("video groups under today's date") NOT verifiable here — needs the app (auth +
  record) AND Colin returning `createdAt`. Flagged.
