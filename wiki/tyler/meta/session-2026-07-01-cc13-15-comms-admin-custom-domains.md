---
type: session
title: "Session 2026-07-01 — comms-admin custom domains (cc-13/14/15) + local env fix"
owner: tyler
created: 2026-07-01
updated: 2026-07-01
status: stable
tags:
  - session
  - comms-admin
  - cloudflare
  - sst
  - acm
  - custom-domain
  - cors
  - csp
  - soc2
related:
  - "[[shared/cloudflare-sst-custom-domains]]"
  - "[[tyler/meta/session-2026-07-01-cc06-cc10-comms-admin-dynamic-verify-fixes]]"
  - "[[tyler/meta/session-2026-06-30-cc08-09-comms-admin-tls-packaging]]"
  - "[[shared/rds-proxy-tls-and-sst-python-packaging]]"
---

# Session 2026-07-01 — comms-admin custom domains (cc-13/14/15) + local env fix

Gives the gunner-comms-admin viewer clean shareable URLs matching the house `api.<app>.gunnerroofing.com`
shape, via Cloudflare **DNS-only** + end-to-end **ACM** TLS (SOC 2 CC6.7). The reusable runbook (token
types, cert regions, the CSP gotcha) is filed separately at [[shared/cloudflare-sst-custom-domains]] —
this note is the execution record + the still-open finding.

## What shipped (repo `gunner-comms-admin`, `main`)

| cc | Change | Verify | Commit |
|----|--------|--------|--------|
| **13** | API CORS: add `https://comms.gunnerroofing.com` to `cors.allowOrigins` (explicit list, no wildcard — JWT rides in Authorization) | OPTIONS preflight echoes the origin | `adca5e3` |
| **14** | Site custom domain `comms.gunnerroofing.com` → CloudFront, DNS-only, **ACM us-east-1**; pinned `cloudflare` provider `6.13.0` | `dig`→`*.cloudfront.net` (not `104.x`), issuer Amazon, `HTTP/2 200` | `9c4e5be` |
| **15** | API custom domain `api.comms.gunnerroofing.com` → API GW **regional**, **ACM us-east-2**; frontend `VITE_API_URL` → literal custom host; **+CSP `connect-src` fix** | `dig`→`d-*.execute-api…`, issuer Amazon, `/health` 200, preflight echoes site origin | `8e34cf1` |

Live end state: site `https://comms.gunnerroofing.com`, API `https://api.comms.gunnerroofing.com`,
both DNS-only + Amazon-issued certs. Provider pins: `aws 6.79.0`, `cloudflare 6.13.0`.

### cc-15 caught a spec gap (the prompt omitted a load-bearing edit)
The prompt's two edits alone would ship a **silently broken app**: repointing `VITE_API_URL` to the
custom API host while the StaticSite CSP `connect-src` only allowed `*.execute-api.us-east-2.amazonaws.com`
→ the **browser CSP-blocks every API fetch**, yet **all curl checks still pass** (curl ignores CSP). Added
`https://api.comms.gunnerroofing.com` to `connect-src` (Edit 3). Lesson generalized in the runbook: for a
custom API domain, curl-green ≠ working; only a real browser + DevTools console proves it.

## Local frontend env fix (separate task, same session)
Before the domain work: the local dev frontend was calling the placeholder
`https://your-api-gateway-url.execute-api.us-east-2.amazonaws.com` (`net::ERR_NAME_NOT_RESOLVED`) because
`frontend/.env.local` `VITE_API_URL` was never set. Fix: wrote the real dev values (`VITE_API_URL=…ghd55lgjwg…`
**no trailing slash** — the client does `fetch(\`${API_BASE}${path}\`)`, pool/client IDs), gitignored, not
committed. Proof the running bundle picked it up: dynamically imported `client.ts` in the browser →
`API_BASE` resolved to the real host; a live `/theme` fetch returned 401 (auth gate, real host reached).
- **Vite reads env only at startup** — must kill + restart the dev server after editing `.env.local`.
- **`async` bash launch of `npm run dev` gets killed at the wrapper's timeout cap** (1800s) — relaunch
  **detached** (`nohup … & disown`; macOS has no `setsid`) so the dev server survives the tool session.

## ⚠ OPEN FINDING — recurring background 500s on comms-admin (unresolved, unrelated to this work)
CloudWatch shows recurring `{"level":"ERROR","location":"handle_generic:93","message":"Unhandled error"}`
on the comms-admin Lambda — **concurrent cold-start bursts of ~6, ~60s apart, no HTTP `source_ip`, no
traceback field**. NOT the auth-gate 401s (those log cleanly as `auth.denied.401`), NOT any of
`/theme`/`/agents`/`/activity`. Signature = a **background non-HTTP invoker** sending an event the
`APIGatewayHttpResolver` can't parse → falls through to the catch-all `@app.exception_handler(Exception)`
→ 500. Seen again mid cc-15 verify (raw execute-api `/health` returned a one-off 500 then 200).
Two follow-ups when someone picks this up:
1. `handle_generic` calls `logger.exception` but emits **no traceback** — confirm it captures `exc_info`.
2. Identify the ~60s invoker (health poller? warmer? a stray schedule) and either fix its payload or
   short-circuit non-HTTP events in `handler()` before `app.resolve`. (`gunnerteam-dev-api-keep-warm`
   rate(5m) is a *different* function — not this.)

## Token hygiene (resolved)
A `cfat_` account token was exposed in a screenshot during the token-troubleshooting slog — **rotated**,
dead experiment tokens deleted, `CLOUDFLARE_DEFAULT_ACCOUNT_ID` (`912d0d5f…`) persisted to the deploy env,
live deploy on a `cfut_` user token (Keeper). The ~90-min token maze (cfat_ vs cfut_, wrong verify
endpoint → misleading `1000`, the `DNS`-write permission row hidden by a `zone` search filter) is the
core of [[shared/cloudflare-sst-custom-domains]].

## Deploy notes
- Deploys run in Tyler's shell (CF token + `CLOUDFLARE_DEFAULT_ACCOUNT_ID` env live there); `sst deploy`
  initializes the `cloudflare` provider even for an AWS-only CORS change, so the CF creds must be present.
- `AWS_PROFILE=mfa` required (`GunnerRequireMFA` explicit-denies without MFA). First domain deploy blocks
  a few min on ACM DNS validation (cc-14 ~644s); the CORS-only redeploy (cc-13) had no ACM wait.
