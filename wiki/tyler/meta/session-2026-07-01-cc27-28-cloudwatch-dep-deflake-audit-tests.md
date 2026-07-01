---
type: session
title: "cc-27–28 — declare @aws-sdk/client-cloudwatch dependency (v431) + de-flake audit-context timing tests"
created: '2026-07-01'
updated: '2026-07-01'
tags:
  - gunnerteam-api
  - dependencies
  - lambda
  - testing
  - ci
status: developing
related:
  - '[[tyler/meta/session-2026-07-01-cc18-26-comms-admin-dialpad-backfill]]'
  - '[[gunnerteam/meta/session-2026-06-30-cc2211-3201-whitelabel-audit-flush]]'
---

# cc-27–28 — declare @aws-sdk/client-cloudwatch dependency (v431) + de-flake audit-context timing tests

Two small hygiene prompts on `gunner-ios`/`gunnerteam-api`. cc-27 closes an open item from
[[tyler/meta/session-2026-07-01-cc18-26-comms-admin-dialpad-backfill]] (the undeclared-dependency
finding Colin flagged during PR #7). cc-28 is test-only, no deploy.

## cc-27 — declare `@aws-sdk/client-cloudwatch` (runtime dep, deployed v431)

`src/lib/scheduler.js` imports `@aws-sdk/client-cloudwatch` (`PutMetricDataCommand` in
`dialpadHealthCount()`) but the package was undeclared — it only worked live because **AWS
Lambda's Node.js managed runtime bundles SDK v3 clients independent of the deployed zip**
(the fragile masking behavior documented in the cc-26 writeup). Local `node -e "require(...)"`
failed with `MODULE_NOT_FOUND` while the live cron ran fine.

- **The fix line was already sitting uncommitted in the shared working tree** from a prior
  session (`"@aws-sdk/client-cloudwatch": "^3.700.0"`, matching the bedrock-runtime /
  cloudwatch-logs pins, lockfile updated). Verified rather than re-added: `npm install`
  clean, resolves at 3.1075.0, 10 `@aws-sdk/*` deps declared.
- Runtime dep ⇒ must ship: full S3 deploy block (`certs/` + `migrations/` confirmed in zip)
  → **v431** on alias `live`, routing weights cleared.
- **Verification shortcut worth reusing:** instead of waiting ~29 min for the next
  `dialpad-health` cron tick (`cron(0 12-23 ? * MON-FRI *)`), directly invoked the `live`
  alias with a synthetic EventBridge event — `{"source":"aws.events","detail":{"task":"dialpad-health"}}`
  (`lambda.js` routes `event.source === 'aws.events'` → `runScheduledTasks(event)` →
  `event.detail.task`). Result: 200, `{"ok":true,"task":"dialpad-health","n":164}`, log
  stream shows `Version: 431`, `rows_last_hour=164`, no `Cannot find module`, and no
  `[dialpad-health] PutMetricData failed` line (so the metric emit + cc-2809 IAM path both
  worked).
- Commit `9cbe830` → pushed as `5704d08` on `main`.

## cc-28 — de-flake `audit-context.test.js` with `node:test` mock timers (test-only)

The 4 intermittently-red `backend` CI subtests were **real wall-clock races**, not load
flakiness: `setTimeout(…, 20)` promises racing a 50ms flush cap ([[gunnerteam/meta/session-2026-06-30-cc2211-3201-whitelabel-audit-flush|cc-3201's]]
`runWithAuditContext` flush semantics). On a slow host the window blows and tests die as
`cancelledByParent`. Node here is v26 ⇒ `t.mock.timers` available (no clock-injection seam
needed in `audit-context.js`).

**Pattern applied** to the three timing-sensitive tests (fast-flush, throw-still-flushes,
timeout-cap):

```js
test('…', async (t) => {
  t.mock.timers.enable({ apis: ['setTimeout'] });
  const done = runWithAuditContext(async () => { /* enqueue setTimeout-backed promise */ });
  t.mock.timers.tick(20);   // deterministic, host-speed-independent
  await done;
});
```

- **Key subtlety (timeout-cap test):** the 50ms cap timer is registered in the flush's
  `finally` block, which only runs *after* fn resolves — so the test must drain microtasks
  (`await new Promise(r => setImmediate(r))`) **before** `tick(50)`, or the tick fires into
  a world where the cap timer doesn't exist yet. `setImmediate` stays real (only
  `setTimeout` is mocked), so the drain works.
- Dropped the `unref?.()` guards inside mocked tests (mocked timers can't hold the process);
  assertions otherwise identical — only the clock changed. Did NOT widen real caps (that
  hides flakiness).
- Result: 3 consecutive runs `pass 7 / fail 0 / cancelled 0`; the formerly-flaky tests now
  complete in 0.24–3.1ms real time (were 21–52ms of genuine wall-clock racing).
- Commit `0d04e93` on `main`.

## Lessons

- **`t.mock.timers.tick()` only fires timers that already exist** — anything registered in
  a `finally`/post-await continuation needs a microtask drain (`setImmediate`) first. This
  is the generic trap when mocking time around `Promise.race(work, timeout)` flush patterns.
- **A synthetic EventBridge-shaped `lambda invoke` against the alias** is the fastest way to
  smoke-test scheduler-path changes — no cron wait, exercises the exact prod entry point,
  and the `Version:` tag in the log START line confirms the serving version in the same read.
- Check `git status` before "adding" a known fix in a shared checkout — cc-27's edit already
  existed uncommitted; blindly re-applying would have been harmless here but is the failure
  mode that produces duplicate/conflicting hunks.

## Open items

- None new. cc-27 closes the "`@aws-sdk/client-cloudwatch` missing from package.json" item
  from the cc-18–26 session. Still outstanding from that session: `MIGRATION_SECRET`
  rotation, SMS-trigger transcript leak, recording-URL-expiry timing.
