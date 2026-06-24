---
type: onboarding
owner: tyler
created: '2026-06-15'
status: active
tags:
  - claude
  - process
  - security
  - deploy
  - onboarding
title: Claude Code Rules — Onboarding Pack
updated: '2026-06-24'
---
# Claude Code Rules — Onboarding Pack

**Audience:** anyone using Claude Code (or Cowork) on the GunnerTeam repos — internal and external.

**Why this exists:** the repos carry a `CLAUDE.md` that encodes hard rules (security, white-label,
deploy, migrations). Claude reads it automatically; **humans must too.** Following the same playbook
is what keeps generated code audit-clean and keeps git == production.

---

## 0. Before you start
1. Read `CLAUDE.md` at the repo root **and** in `gunnerteam-api/` — they override default behavior.
2. Work on a branch → PR → review → merge (see CONTRIBUTING). Claude changes are not special.
3. `CLAUDE.md` is authoritative. Improve it via PR; don't work around it.

## 1. The cc-prompt workflow (Cowork → Claude Code)
- Cowork sessions write `cc-prompt-XX.md` task files; Claude Code executes them against
  `~/Dev/GunnerTeam/`.
- One concern per cc-prompt. Commands and diffs, minimal prose.
- After finishing a cc-prompt, output exactly: `✅ cc-prompt-XXX complete — <one sentence>`.
- cc-prompt numbers are **contended across concurrent sessions** — trust `ls cc-prompt-*.md` on disk,
  not a remembered number. Use descriptive filenames.

## 2. Security rules (non-negotiable)
**Backend**
- `users` has no `org_id` — any user-scoped write needs a `user_organizations` pre-flight (404 on miss).
- Client-supplied resource IDs (`jobId`, `taskId`, …) must be org-verified before writes or upstream calls.
- `audit()` takes an object: `audit({ action, req, metadata })` — never positional. Routes outside
  `requireAuth` pass `orgId` explicitly.
- Every async route handler has try/catch; error paths set `.status(4xx/5xx)` before `.json()`;
  **never return `err.message` to the client.**
- Always check `if (!rows[0])` before using single-row results.
- Fan-out: `await Promise.allSettled([...])`, never `forEach` with unawaited async (and never leave a
  detached promise — Lambda freezes and crashes with `Runtime.NodeJsExit`).
- `validatePasswordPolicy()` on every password-accepting route; rate-limit all unauthenticated auth
  endpoints; webhooks use `express.raw()` + HMAC verify + durable dedup.

**iOS**
- Every async view: `@State isLoading` + `@State loadError`. `onAppear` fetches guard with
  `@State hasFetched = false`. New interactive colors use `themeManager.theme.*` / `Color.app*`
  tokens — no `Color(hex:)`, no per-view palette structs.

**White-label**
- No hardcoded "Gunner"/"GunnerTeam"/"Gunner Roofing" in emails, push copy, UI text, or API
  responses. Org name/theme resolves from the DB per request.

## 3. Secrets rule
- Never print, echo, or log values of variables ending in `_PASSWORD`, `_SECRET`, `_KEY`, `_TOKEN`.
- Never run `aws lambda get-function-configuration --query 'Environment.Variables'` (a hook blocks
  it). Querying `VpcConfig.SecurityGroupIds` etc. is fine — just not env vars.

## 4. Deploy rule
- `update-function-code` alone does NOT route traffic. Always run the full block (zip → S3 →
  update-function-code → wait → publish-version → update-alias `live`). See CONTRIBUTING §3.
- Config/infra is Terraform/SST, not the code deploy. Env vars (`DB_HOST` etc.) change via SSM +
  `terraform apply`, not the deploy block.

## 5. Migration rule
- Migrations are **inline** in the `migrations` object in `gunnerteam-api/src/lambda.js`, keyed
  `'YYYYMMDD_name'`, and run via the `_migration` Lambda event handler. SQL files under `migrations/`
  are ignored. Redeploy after adding one. No manual `ALTER TABLE` in prod.

## 6. Comments — surgical only
Write a comment only to explain **why** a non-obvious or security-critical decision was made, or to
document an external-API quirk (CompanyCam/Cognito/AWS). No comments that restate what the code does.
Delete redundant comments in any function you touch.

## 7. Database access (RDS Proxy aware)
- masterdb is reached through an **RDS Proxy.** The proxy **pins** a connection on any `SET`
  statement and can't multiplex it — so `SET LOCAL`-based RLS (`queryWithTenant`) pins connections.
  For hot **reads** that already filter `org_id` explicitly, prefer the non-transactional `query()`
  so the proxy can multiplex. Keep `queryWithTenant` for writes / where RLS is the only guard.
- The pg pool must be proxy-safe: no `statement_timeout` startup option (the proxy rejects it);
  use client-side `query_timeout` and `DB_CONNECT_TIMEOUT_MS`.

## 8. Self-correction rule
After any mistake, update the appropriate `CLAUDE.md` before moving on — technical rules (SQL/Swift/
Node/AWS) in `~/Dev/GunnerTeam/CLAUDE.md` under "Learned from mistakes"; workflow rules in the Cowork
folder's `CLAUDE.md`. End the correction by noting CLAUDE.md was updated.

## 9. Hooks (Claude Code)
Active in `~/Dev/GunnerTeam/.claude/settings.json`:
- PostToolUse `Write(*.js)` → `node --check $file` (catches syntax errors immediately).
- PreToolUse blocks writes to `.env*`.
- PreToolUse blocks `get-function-configuration --query 'Environment.Variables'`.

---

**TL;DR:** read `CLAUDE.md`, branch → PR → review → deploy-from-git, never leak secrets or hardcode
the brand, deploy with the full block, migrations inline, comments only for *why*, and treat the
RDS Proxy's pinning behavior with care.
