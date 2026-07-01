---
type: session
title: >-
  cc-18–26 — comms-admin MFA/recording UX + Dialpad-Enrich Root-Cause Fix,
  Deploy, and Two-Stage Backfill
created: '2026-07-01'
updated: '2026-07-01'
tags:
  - comms-admin
  - gunnerteam-api
  - dialpad
  - mfa
  - backfill
  - masterdb
status: developing
related:
  - '[[gunnerteam/dialpad-hubspot-integration]]'
  - >-
    [[tyler/meta/session-2026-07-01-cc3300-cc20-crm-internal-flag-dialpad-transcript-clean]]
  - '[[tyler/meta/session-2026-07-01-cc06-cc10-comms-admin-dynamic-verify-fixes]]'
  - '[[tyler/meta/session-2026-07-01-cc13-15-comms-admin-custom-domains]]'
---

# cc-18–26 — comms-admin MFA/recording UX + Dialpad-Enrich Root-Cause Fix, Deploy, and Two-Stage Backfill

Nine sequential cc-prompts spanning two repos: `gunner-comms-admin` (frontend UX for the
403-ambiguity and broken-recording-playback bugs cc-17 investigated) and `gunner-ios`/
`gunnerteam-api` (the actual root-cause fix, its production deploy, and a two-stage data
backfill for the damage the bug had already done). cc-20's Dialpad transcript strip already
had its own writeup — see [[tyler/meta/session-2026-07-01-cc3300-cc20-crm-internal-flag-dialpad-transcript-clean]] —
folded in here only for narrative continuity between cc-19 and cc-21.

## cc-18 — distinguish `mfa_required` from `Forbidden` (comms-admin frontend)

The cc-17 investigation burned time at the DB gate chasing a phantom access bug when the
real cause was an unenrolled MFA factor — both a 403 `mfa_required` and a genuine
non-admin `Forbidden` rendered the identical "Access Denied" screen. Fix: `App.tsx`'s
`forbidden` state changes from `boolean` to `string | null`, carrying `ForbiddenError.msg`
through to `NotAuthorized`, which now branches copy/heading on `reason === 'mfa_required'`
(keeps `orgName` dynamic for white-label). Commit `5c11832`.

## cc-19 — feed + call drill-down clarity (comms-admin frontend)

`FeedRow` already carried `internal_number`/`final_state`/`was_recorded`/`duration_ms` —
none were surfaced. Added shared `fmtDuration(ms)` (m:ss) to `client.ts`. Feed table
header: `Agent`→`Rep`, `Contact`→`Customer`, new `Gunner line` column
(`internal_number`), call preview now `${fmtDuration} · ${recap}`. `ThreadPage`'s
`CallCard` header rebuilt into `{Inbound|Outbound} · {duration}` / `From {X} → To {Y}`
(swapped by direction) / `Rep: {agent} · Outcome: {final_state}`. Commit `d7dcf88`.

## cc-21 — recording playback: gate phantom keys + honest error copy (comms-admin frontend)

Live `head-object` on the reported broken recording confirmed the actual corruption:
`ContentType: text/html`, 13,732 bytes — an HTML page stored as `0.mp3`. **This is an
ingestion bug, not a viewer bug** — no frontend fix can play a non-audio file. Frontend
defensive fix: gate the `R` badge (FeedPage) and "▶ Play recording" button (ThreadPage) on
`row.was_recorded && row.has_recording` (previously gated on `has_recording` alone — 12 of
20 "has recording" calls were never actually recorded, `was_recorded:false`). Also dropped
the misleading `<audio> onError` copy ("URL may have expired") for an honest
"Recording unavailable — it may not have been captured or is still processing." Commit
`2e04803`. The real fix is Part C of the same prompt, executed as cc-23 below.

## cc-22 — self-serve TOTP enrollment on `mfa_required` (comms-admin frontend)

The pool is OPTIONAL-MFA (shared with the mobile app), so Amplify never forces
enrollment — a newly-granted admin hit the cc-18 dead end with no way out except a manual
QR dance. New `MfaEnroll.tsx`: Amplify v6 `setUpTOTP()` → QR of `getSetupUri()` →
`verifyTOTPSetup({code})` → `updateMFAPreference({totp:'PREFERRED'})` → reload (gate
re-checks server-side via `admin_get_user`, no pool changes needed). `App.tsx` routes
`forbidden === 'mfa_required'` to `MfaEnroll` instead of the static `NotAuthorized`
screen. Verified via a temporary Vite alias mocking `aws-amplify/auth` — QR render, wrong-code
retry error, correct-code → reload, all confirmed live in a headless browser. Commit
`7d8403a`.

## cc-23 — deploy the dialpad-enrich validation fix (gunnerteam-api, THE root-cause fix)

PR #7 (`fix/dialpad-enrich-validation`, merged `d45749a`) fixed `dialpadEnrich()` in
`scheduler.js`:
1. **Recordings are HTML, not audio** — the recording re-host loop checked `r.ok` (any
   2xx) but never `content-type`. An expired/unauthorized Dialpad `/secureblob/` URL
   returns `200` with an HTML "not available" page → got uploaded to S3 verbatim as
   `text/html`, and `recording_s3_keys` got set even though nothing real was captured.
2. **Transcript pollution** — Dialpad's `{lines:[{name,content,type}]}` response was
   flattened without checking `type`; only `type==='transcript'` is real dialogue.
   Everything else (moment labels like `ai_csat_reboot`, SMS-trigger notification text)
   ended up stored as fake utterances.
3. **Secondary** — the recording-fetch query didn't filter `was_recorded=true` (the
   transcript query right above it already did), so un-recorded calls could still get
   S3 keys.

Fix: require `content-type` to start with `audio/*` before upload (else skip, no
upload/key); add `was_recorded=true` to the recording-fetch WHERE; filter transcript
lines to `type==='transcript'` before flattening. Both checks extracted as pure functions
in new `src/lib/dialpad-enrich.js` (no DB/AWS deps — testable standalone). 14 unit tests
in `test/dialpad-enrich.test.js`.

**Deploy mechanics:** `dialpad-enrich` runs inside `gunnerteam-dev-api`'s
`runScheduledTasks` (`event.source==='aws.events'` → `event.detail.task`), fired every 5
min against the `live` alias — merge alone doesn't route traffic, needs the full
S3+update-function-code+publish-version+alias block. Local `main` had unrelated
in-flight agent work (unpushed commits, uncommitted files from other sessions) — used
`git worktree add /tmp/gt-wt-<name> origin/main` to get a clean deployable tree without
touching the shared checkout, matching this repo's own documented worktree-isolation
convention. Deployed as version 428. Verified via the CloudWatch `[version]` log-stream
tag (not `get-alias`, which is eventually consistent) — confirmed `Version: 428` actually
serving. A subsequent enrich tick (`transcripts=1 recordings=1`) produced zero
skip/non-audio warnings on real fresh data; live-verified in the viewer (Pamela/Belal
call): clean transcript, and the fresh recording's presigned S3 URL served genuine
`audio/mpeg` with valid MP3 frame-sync bytes (`ff e3...`).

**Bonus finding while verifying:** the *same* transcript had a second, distinct leak —
Dialpad SMS-trigger notification text (`"Earn Your Business | Sign Today"`) stored as fake
dialogue lines. Same root cause (ingestion trusting Dialpad's response shape uncritically)
but a different shape (title-case multi-word, not the snake_case-token pattern cc-20's
regex targets) — out of scope for that regex, flagged separately for whoever owns
ingestion.

## cc-24 — backfill assessment (READ-ONLY quantification)

Gated the mutation plan on real numbers before touching prod. Used the `_sql`/`_migration`
Lambda preflight pattern (`{"_sql":"SELECT...","_secret":"<MIGRATION_SECRET>"}`, auth-gated,
never reachable via API Gateway — the same in-VPC read-only path used elsewhere for schema
probes) since masterdb is VPC-only.

**Part 1 (exact, full-table counts):**
- Polluted transcripts: **134/136** (98.5%) of all non-null transcripts.
- Recording keys: 312 total; **176 phantom** (`was_recorded=false`) vs 136 genuine
  (`was_recorded=true`).

**Part 2 (full census, not sampled):**
- S3 content-type: **100% of the 176 phantom-key objects are `text/html`**; **0% of the
  136 genuine `was_recorded=true` recordings are corrupted** (all `audio/mpeg`) — the
  corruption is *entirely* confined to the missing-filter bug, confirming root cause.
- Recording re-fetch today: **0/176 (0%) recoverable** — Dialpad genuinely never recorded
  these calls; the URLs still resolve to the same HTML.
- Transcript re-fetch today: **133/134 (99.3%) recoverable** — only 1 call
  (`5787839175532544`) has zero real dialogue in Dialpad's current response.

**Security note surfaced:** a malformed Lambda invoke attempt during this session echoed
the base64-encoded `{_sql,_secret}` payload back in a CLI error message, which decodes to
reveal `MIGRATION_SECRET` in the transcript. Flagged for rotation — not yet done.

## cc-25 — execute the backfill (prod mutation, Tyler's explicit go)

Two-part mutation, both pre-counted before and verified after:
1. **Transcripts:** `UPDATE dp_calls SET transcript=NULL WHERE org_id=:org AND transcript
   ~ <moment-label regex>` — `rowCount: 134`, exact match. The fixed enrich cron
   re-derives `transcript IS NULL AND was_recorded=true` rows automatically.
2. **Phantom recordings:** listed all 176 `recording_s3_keys` for `was_recorded=false`,
   re-verified each was still `text/html` immediately pre-delete (zero drift), batch
   `delete-objects` (176/176 deleted, 0 errors, 176/176 confirmed 404 post-delete), then
   `UPDATE dp_calls SET recording_s3_keys=NULL WHERE was_recorded=false` — `rowCount: 176`,
   exact match. The 136 genuine `was_recorded=true` recordings were never touched.

**Critical finding during verification:** `dialpadEnrich()`'s transcript query filters
`date_ended > now() - interval '24 hours'` — of the 134 nulled rows, only 13 fell inside
that window. The other **96 rows are permanently invisible to the standard 5-min cron**
under its current code (a deliberate steady-state bound, not a bug — widening it would
change the cron's ongoing load, which cc-26 explicitly declined to do). Drain observed to
stabilize at exactly 96 stuck / 0 within-window after two cron cycles, confirming the gap
is real and not just slow drain. Spot-checked one re-derived transcript live in the
viewer — clean.

**cc-21 reconciliation:** confirmed a `was_recorded=true` recording actually serves real
audio bytes (fetch + MP3 frame-sync check) — the `<audio>` tag itself threw
`MEDIA_ELEMENT_ERROR: Media load rejected by URL safety check` in-session, but this
reproduces identically on an unrelated public test MP3 (`w3schools.com/html/horse.mp3`) —
isolated as a **headless-Chromium sandbox artifact**, unrelated to the data and not a
production bug worth filing.

## cc-26 — one-off backfill for the 96 stuck historical transcripts

Explicitly a one-off recovery script, not a cron change. New
`gunnerteam-api/scripts/backfill-transcripts.js` reuses `filterDialpadTranscriptLines`
(dialpad-enrich.js) and the same `dpFetch`/`DP_BASE`/`DP_ORG` as the cron — exported
these three from `scheduler.js`'s `module.exports` (previously private) rather than
duplicating fetch/auth/timeout logic, per the repo's Reuse Rule. Same query as the cron
minus the 24h gate; same UPDATE; idempotent (`WHERE transcript IS NULL`). Wired into
`lambda.js`'s `_task` dispatcher as `backfill-transcripts`, secret-gated identically to
the existing `_migration`/`_sql` one-off paths (defense-in-depth for a bulk prod write,
even though IAM already gates raw invoke access) — deployed as version 429, invoked once
via `aws lambda invoke {"_task":"backfill-transcripts","_secret":...}`.

**Result:** 96 candidates → 95 written clean, 1 correctly left NULL (the same
no-dialogue call cc-24/25 identified). Zero junk patterns across all 140 transcript rows
post-run. Zero duplicate `dialpad_call_id` rows. Spot-checked a genuinely >24h-old
recovered transcript live in the viewer.

**Two infra gotchas hit and resolved during this step:**
- **Undeclared transitive dependency, silently masked at runtime:** `scheduler.js`
  `require('@aws-sdk/client-cloudwatch')` is NOT in `package.json`/`package-lock.json` —
  `node --check`/`node -e "require(...)"` fails locally with `MODULE_NOT_FOUND`. Yet the
  live cron runs `dialpad-enrich`/`dialpad-health` successfully every 5 min. Root cause:
  **AWS Lambda's Node.js 20.x managed runtime bundles AWS SDK v3 client packages
  independent of what's in the deployed zip's `node_modules`** — confirmed by directly
  invoking the live function with a `dialpad-health`-shaped event and watching it
  succeed. This is a real, fragile, undocumented-in-repo behavior: any local test harness
  or `npm ci` in a plain Node environment will show this code as broken when the actual
  deployed Lambda works fine. Already flagged separately (out of scope, PR #7's own
  description) as a package.json hygiene fix worth doing properly.
- **Client-side read-timeout retry on a long synchronous invoke:** the script's near-90s
  runtime for 96 sequential Dialpad calls (throttled 250ms apart) approached the AWS CLI's
  default socket read timeout, triggering an automatic client-side retry mid-flight while
  the first invocation kept running server-side until it hit Lambda's own 90s hard
  timeout. Two overlapping executions resulted (confirmed via two distinct RequestIds in
  CloudWatch), but the idempotent `UPDATE ... WHERE org_id AND dialpad_call_id` design
  (no INSERT path) made the overlap harmless — verified zero duplicate rows, all 96
  candidates accounted for across both runs. **Lesson for future long-running one-off
  Lambda invokes:** either raise `--cli-read-timeout`, reduce the per-item throttle, or
  paginate into smaller batches — a >60s synchronous `aws lambda invoke` is fragile by
  default.

## Cross-Cutting Lessons

- **Frontend UX fixes (cc-18/19/21/22) and backend root-cause fixes (cc-23/24/25/26) are
  separate, sequenced work** — the frontend gating in cc-21 stops the tool from *lying*
  about broken data while the real ingestion fix (cc-23) and backfill (cc-25/26) repair
  the data itself. Neither alone would have closed the original cc-17 confusion loop.
- **`was_recorded=false` + `recording_s3_keys IS NOT NULL` was a 100%-reliable signal for
  corruption** across this entire investigation (176/176 phantom keys were HTML; 0/136
  genuine `was_recorded=true` recordings were ever corrupted) — a clean root-cause/scope
  match that de-risked every subsequent mutation.
- **Full census beats sampling when the row count is small enough to be cheap** — cc-24
  ran S3 HEAD + Dialpad GET against all 176/134 affected rows (not a sample) via batched
  `Promise.all`, giving Tyler exact numbers instead of confidence intervals for a
  prod-mutation go/no-go decision.
- **A cron's steady-state window (the 24h date filter) is a deliberate scope boundary, not
  a bug to "fix" during backfill** — cc-25/26 correctly treated widening the enrich
  window as out of scope and built a separate one-off script instead, keeping the cron's
  ongoing load/behavior unchanged.
- **`git worktree add <path> origin/main`** is the right tool whenever a shared repo's
  local checkout has other agents' in-flight uncommitted/unpushed work and a clean
  deployable tree is needed — used for both cc-23 and cc-26's deploys without disturbing
  concurrent sessions.

## Open Items

- **`MIGRATION_SECRET` needs rotation** — leaked in a CLI error message during cc-24 (base64
  payload echoed back on a malformed invoke, decodable to the plaintext secret).
- **`@aws-sdk/client-cloudwatch` missing from `package.json`** — works today only because
  of Lambda's runtime-bundled SDK v3 fallback; should be declared explicitly (flagged in
  PR #7, still open).
- **SMS-trigger notification text leak** (`"Earn Your Business | Sign Today"` style lines)
  in transcripts — same root cause as the moment-label leak, different shape, not covered
  by the existing `_MOMENT_LINE`/`filterDialpadTranscriptLines` filters. Needs its own fix
  if it recurs at volume.
- **Recording-URL-expiry timing** — PR #7 explicitly deferred investigating *why* Dialpad's
  `/secureblob/`/`/blob/adminrecording/` URLs are already expired by enrich-fetch time
  (undocumented TTL per this repo's own terraform comment). The validation fix stops
  future corruption regardless, but doesn't explain the root timing cause.
</content>
