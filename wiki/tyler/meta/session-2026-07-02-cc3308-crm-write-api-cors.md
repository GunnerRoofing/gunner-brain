---
type: session
title: "Session 2026-07-02 — cc-3308: crm-write-api CORS headers on all responses"
owner: tyler
created: 2026-07-02
updated: 2026-07-02
status: stable
tags:
  - session
  - crm-transform
  - cors
  - qp
  - crm-write-api
related:
  - "[[leo/qp/crm-sell]]"
  - "[[leo/apps/masterdb-integration]]"
  - "[[tyler/meta/session-2026-07-01-cc3305-3306-crm-author-fix-qp-notes-backfill]]"
  - "[[gunnerteam/secure-coding-guide]]"
---

# Session 2026-07-02 — cc-3308: crm-write-api CORS headers on all responses

UAT-blocking bug: API-GW `AWS_PROXY` integration means `crm-write-api` (POST `/crm/activity`) must emit
its own `Access-Control-*` headers — the `/crm/activity` OPTIONS mock only answers preflight. Real
responses (201/400/404/500) carried none, so qp-stage's browser blocked reads of successful writes → reps
saw false failures and double-posted notes.

## Fix (repo `crm-transform`, commit `f5a99fb`)

- `write_api.py`: `_resp(status, obj, event)` is the single choke point every handler return goes through
  (including the `except Exception → _resp(500, …)` path) — added `_cors_headers(event)` merged in there
  once, covering success AND error uniformly. Made `event` a **required** third positional arg (not
  defaulted) on this private helper — a future `_resp(...)` call site missing it fails loudly (`TypeError`)
  rather than silently shipping a CORS-less response.
- Allowlist, not wildcard: `_ALLOWED_ORIGINS` parsed from env `ALLOWED_ORIGINS` (comma-separated). Echoes
  the request `Origin` when it's on the list; else falls back to the first allowlisted origin (header is
  never silently absent). No `Access-Control-Allow-Credentials` — auth rides in `Authorization`, not
  cookies.
- `deploy-write.sh`: `ALLOWED_ORIGINS="https://qp-stage.gunnerroofing.com,https://qp.gunnerroofing.com"`.
  **Also fixed a latent bug**: the script only ever set Lambda env vars on `create-function`; the
  `update-function-code` branch left env "untouched" forever, so any new env var (this one included) would
  silently never reach an already-existing function. Added `update-function-configuration` to the update
  branch too, gated behind `aws lambda wait function-updated` both sides.
- AWS CLI shorthand `--environment Variables={...}` breaks on a comma **inside** a value (it's the
  shorthand's own kv-separator) — switched to `jq -n` building real JSON for `--environment`.

## Where the origins came from (Leo wasn't reachable synchronously — sourced from wiki + live inspection)

- Downloaded `get-crm-timeline-api-v1`'s deployed code (Node `index.mjs`): its CORS pattern is a single
  `HEADERS` const, `Access-Control-Allow-Origin: process.env.CORS_ALLOW_ORIGIN || '*'` — same object used on
  every return (200/400/500). **But `CORS_ALLOW_ORIGIN` is NOT actually set on the deployed function** — it's
  live on `'*'` today. Ticket explicitly said "do NOT hardcode `*`", so did not mirror the *current runtime
  value*, only the *shape* (config-driven, single choke point).
- Origins sourced instead from [[leo/apps/quote-portal]]'s environment map: stage = `qp-stage.gunnerroofing.com`,
  prod = `qp.gunnerroofing.com` (deployed, not yet live). DNS-verified both resolve (Cloudflare-proxied).
  [[gunnerteam/secure-coding-guide]] A05 section independently confirms the house style is an explicit
  origins list, never a wildcard.
- **Follow-up for Leo:** confirm these are the exact origins QP's frontend sends as `Origin` (protocol +
  no trailing slash) — not directly confirmed by him this session.

## Verification (live Lambda, `crm-write-api`, prod masterdb — `gunnerteam-dev-masterdb-proxy` targets the
**production** Aurora cluster despite the "-dev-" name, per the existing documented cc-2111/cc-2114 fact)

- `python -c "import write_api"`: fails locally with `ModuleNotFoundError: boto3` — confirmed **pre-existing**
  or unrelated to this diff (identical failure reproduced against unmodified `HEAD`; `boto3` ships with the
  Lambda runtime, was never in `requirements.txt`/local pip). Installed `boto3` + used the already-built
  `package/` (has `pg8000`) as `PYTHONPATH` to actually exercise the import — succeeded, `_cors_headers()`
  spot-checked in-process (allowlisted origin echoes; non-listed origin does NOT echo, falls back to first
  allowlisted).
- Deployed via `deploy-write.sh`; confirmed `ALLOWED_ORIGINS` present in `get-function-configuration`.
- Real invokes against the live Lambda:
  - 201 (valid note write) → `Access-Control-Allow-Origin: https://qp-stage.gunnerroofing.com` present.
  - 400 (missing body) → same header present.
  - Untrusted `Origin: https://evil.example.com` → header falls back to the first allowlisted origin, does
    **not** echo the untrusted value (allowlist actually enforced, not a pass-through echo).
  - Forced a genuine `except Exception → 500` (NUL byte in `contact_id` — Postgres wire protocol rejects it
    at the driver level, unlike a syntactically-fine-but-nonexistent UUID which cleanly 404s) → CORS header
    present there too.
- **Real write landed in prod** `crm_activities` (id `0dd57bfb-…`, `source='manual'`, body `"cc-3308 cors"`)
  from the 201 test. MFA session expired mid-verification (blocked all AWS calls incl. this cleanup) — user
  refreshed it, resumed. Deleted via the documented one-off-Lambda pattern: throwaway probe Lambda (reused
  `crm-transform-lambda-role`/VPC/SG, prod `postgres` superuser creds from Secrets Manager passed as env
  vars, never on the command line), dry-run `SELECT … WHERE source='manual' AND body LIKE 'cc-3308%'` first
  (1 row, matched the known test id) → `DELETE` by id → re-`SELECT` confirmed 0 rows → **Lambda deleted
  immediately** (confirmed gone via failed `get-function`). `crm_app` (the app role) has no DELETE grant by
  design (soft-lifecycle-only) — this is why the elevated probe was necessary at all, same pattern as prior
  sessions.
- Gotcha hit + fixed: a from-scratch SSL context (`ssl.create_default_context(cafile=RDS_CA_BUNDLE)`) fails
  `CERTIFICATE_VERIFY_FAILED` — that constructor form does NOT also load system roots. Must match
  `lambda_function.py`'s `_ssl_context()` exactly: `create_default_context()` (system roots) THEN
  `load_verify_locations(cafile=RDS_CA_BUNDLE)` additively.
- Commit `f5a99fb` pushed to `main` (rebased past Leo's concurrent `7300edd` SQL-export commit — disjoint
  files, clean).

## Still open (not this session — explicitly Leo's / next-session)

- **Leo's manual UAT**: post a note through qp-stage Sell → confirm UI shows success (no false failure),
  single row persists (no double-post). This is the actual acceptance bar per the ticket; not exercised
  here (requires a human in the real browser + qp-stage session).
- Any `cc-3308`-tagged rows Leo's test creates should be deleted the same way (`source='manual'`,
  `body LIKE 'cc-3308%'`) — the throwaway-probe pattern above is reusable, or ask Tyler.
- Confirm with Leo whether `qp-stage.gunnerroofing.com` / `qp.gunnerroofing.com` (no port, https, no
  trailing slash) are the literal `Origin` values the browser sends — inferred from the environment map,
  not confirmed against a live browser request.

## Links
- [[leo/qp/crm-sell]] — the QP Sell-mode feature this write path serves
- [[leo/apps/quote-portal]] — QP environment map (stage/prod origins)
- [[leo/apps/masterdb-integration]] / [[gunnerteam/secure-coding-guide]] — CORS + masterdb conventions
- [[tyler/meta/session-2026-07-01-cc3305-3306-crm-author-fix-qp-notes-backfill]] — prior session on this
  same Lambda (author-resolution fix + QP notes backfill)
