---
type: session
title: "cc-1202 GunnerCam Service-Key Invites + cc-16 comms-admin CORS Preflight Fix"
created: 2026-07-01
updated: 2026-07-01
tags:
  - gunnerteam
  - comms-admin
  - cors
  - service-key
  - masterdb
  - vault-maintenance
status: developing
related:
  - "[[tyler/meta/session-2026-07-01-cc13-15-comms-admin-custom-domains]]"
  - "[[tyler/meta/session-2026-07-01-cc06-cc10-comms-admin-dynamic-verify-fixes]]"
  - "[[tyler/meta/session-2026-07-01-cc2924-org-slug-hygiene-issue21]]"
  - "[[tyler/meta/session-2026-07-01-fellow-app-mv3-remote-code-fix]]"
---

# cc-1202 GunnerCam Service-Key Invites + cc-16 comms-admin CORS Preflight Fix

## cc-1202 — service-key path on `POST /auth/invite` (gunnerteam-api)

GunnerCam needed to invite subcontractors via a scoped `gtsk_` service key, keyed on `crew_id`, without a human account — deny-by-default so a service key on this route can create nothing but subcontractor invites.

**Phase 0 — schema check before coding.** `invite_tokens.created_by` needed to accept NULL for service-key invites (no user to attribute). Checked live via the Lambda's `_sql` read-only preflight (`{"_sql": "SELECT is_nullable FROM information_schema.columns WHERE table_name='invite_tokens' AND column_name='created_by'", "_secret": "..."}`) — already `YES`, no migration needed. **The `_sql`/`_migration` preflight pattern in `lambda.js` is the right tool for one-off live schema/data checks without opening a psql tunnel** — auth-gated by `MIGRATION_SECRET`, never reachable via API Gateway.

**Implementation** (`src/routes/auth.js`):
- Route auth switched from `requireAuth` to `authOrServiceKey` (dual-auth: dispatches on `Bearer gtsk_` prefix vs Cognito JWT).
- `viaServiceKey = !!req.serviceKeyId` branches the authorization gate: service keys can ONLY invite `role==='subcontractor'`, additionally scoped by `req.serviceKeyTasks` containing `'subcontractor.invite'` (the `serviceKeyTasks != null && !includes(task)` null-unrestricted convention already established in `weather.js`).
- Idempotency: if the invitee email already resolves to an org member, service-key path short-circuits `200 {status:'already_member'}` — no new token/email (M2M retries and repeated crew-create shouldn't spam invites).
- `created_by = req.user?.id ?? null` — never dereference `req.user` on the service-key path (it's `undefined`).
- `audit()` call passes `orgId` explicitly (route can run outside `requireAuth` now) plus `invitedVia`/`serviceKeyId` provenance metadata.

**Verification:** extended `test/invite-auth.test.js` with 5 service-key-path cases (194/194 suite green). Live-verified against `gunnerteam-dev-api` v427 by minting a real scoped key directly via the `_sql` preflight (mirroring the `/templates/service-keys` mint endpoint's INSERT exactly — no admin token available headlessly) — confirmed 200 on subcontractor invite, 403 on non-subcontractor role, then revoked the test key and cleaned up the throwaway invite tokens.

Commit `5aaf0a6`.

## cc-16 — CORS preflight 500 fix (gunner-comms-admin)

**Symptom:** authenticated feed never loaded in the browser ("Failed to fetch"), but `curl` GETs looked fine. Root cause: the SST route `api.route("$default", handler.arn)` matches `OPTIONS` too, so API Gateway's built-in CORS preflight (which only auto-answers when *no* route matches OPTIONS) never fired — the Lambda had no preflight handler, so every browser preflight 500'd. **`curl` never catches this class of bug** — it doesn't send real CORS preflight requests, so a green curl smoke test can fully mask a broken authenticated flow.

**Fix, and a real gotcha it surfaced beyond the original prompt:**
1. Powertools' `APIGatewayHttpResolver(cors=CORSConfig(...))` now owns CORS (`backend/src/comms_admin/app.py`), origins from `ALLOWED_ORIGINS` env — short-circuits preflight before the auth gate, stamps CORS on every response including 401/403.
2. Removed the API-Gateway-level `cors` block from `sst.config.ts` to avoid a duplicate `Access-Control-Allow-Origin` on real responses (browsers reject duplicates even though curl shows them fine).
3. **First redeploy still broken** — `cors: false` in SST's `ApiGatewayV2` does NOT mean "no CORS." `normalizeCors()` treats `false` as an *empty* `CorsConfiguration` object, and API Gateway auto-intercepts and auto-answers OPTIONS for **any** API with a `CorsConfiguration` present — even an empty one — bypassing the Lambda entirely with blank headers. Confirmed via `aws apigatewayv2 get-api --query CorsConfiguration` still showing a non-null object, and zero Lambda invocations in CloudWatch.
4. Real fix: `transform.api: (args) => { delete args.corsConfiguration; }` on the `ApiGatewayV2` construct — the only way to make the field fully absent from the underlying resource so `$default` truly owns OPTIONS.

**Verification (preflight-level, the ones that actually prove the fix):**
- `OPTIONS /activity` → 204, `access-control-allow-origin` echoes the real origin (not `*`), `allow-headers` includes `Authorization`.
- `GET /activity` with no token → 401, still carries `access-control-allow-origin` (Powertools stamps errors too).
- Exactly ONE `access-control-allow-origin` header on a real response (no API-GW+Powertools double-stamp).
- Origin NOT in `ALLOWED_ORIGINS` → no ACAO header (deny-by-default).
- `GET /health` unaffected (still 200, unauthenticated).

Manual browser login + feed-load confirmation was deferred to Tyler (no test Cognito credentials available headlessly). New `CLAUDE.md` created for the repo (previously had none) with two "Learned from mistakes" entries: the `$default`-swallows-OPTIONS class, and "CORS is not verified by curl."

Commit `9cba886`.

**Deploy friction note:** `sst deploy` needs `CLOUDFLARE_API_TOKEN` (+ `CLOUDFLARE_DEFAULT_ACCOUNT_ID`) from Keeper and an unexpired `AWS_PROFILE=mfa` session — bash-tool env is isolated from the user's interactive terminal, so deploys requiring interactively-sourced secrets had to be run by Tyler directly, with Claude verifying via `aws apigatewayv2`/`curl` after each attempt. Same `awsmfa`-needs-a-real-terminal pattern as noted in existing memory, now confirmed to extend to any secret exported only in the user's shell.

## Vault/ops maintenance (same session)

- **Master TODO doc check:** the user's "GunnerTeam — Master Open-Items / TODO" doc (dated 2026-06-20, updated through 2026-06-30) does **not exist anywhere in the Obsidian vault** — it's a Claude Projects/Desktop memory-store artifact (footer cites `_project_gunnerteam_state`, `_compliance_backlog` etc., not vault paths). Verified several claims live instead of vault-diffing: §6 `POST /device/integrity` is actually already shipped (doc listed it open — stale); §8's two "(verify)" migration/IAM cleanup items are both already done; §12/PR#24 date was off by a day (doc said merged 2026-06-30, actually 2026-07-01) but outcome was correctly described; §14 Phase-3 migrate-pipeline status (PR #22/#23 merged, nothing deployed yet, placeholders still literal in `migrate-prod.yml`) was confirmed accurate. `leads-finder-dk` key still `Active`+`AdministratorAccess`, unchanged.
- **Runbook mirror sync:** ran the `Gunner Team App/runbooks/` → `wiki/tyler/gunnerteam/runbooks/` mirror check per the project's handoff doc. Found 11 runbooks already mirrored (likely from a prior partial run in the same session) — verified rather than blindly re-copied: frontmatter correct on all 11 `.md` files, bodies byte-identical to source (an initial diff falsely flagged differences from my own script mishandling in-body `---` horizontal rules, corrected and re-verified clean), 2 raw scripts (`enable-bedrock-model.sh`, `provision_gunnerteam_app.sql`) copied as-is with no frontmatter and correctly excluded from the index MOC table, no secrets present. Added the `### GunnerTeam (dev / deploy / ops)` table to `wiki/tyler/index.md` (11 rows for 11 md runbooks). Committed `41061db`.
</content>
