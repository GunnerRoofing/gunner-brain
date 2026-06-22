---
type: reference
owner: colin
app: GunnerCam
created: 2026-06-21
updated: 2026-06-21
tags: [wl-companycam, deploy, sst, ops]
status: active
---

# Deployment & Ops

## Deploy mechanism & topology

- The dev environment is an SST/OpenNext deployment on AWS Lambda + CloudFront (SST `4.13.1`, app name `wl-companycam`). Lambdas include the web server, image optimizer, warmer, and cron reminders. Infra detail lives in [[colin/aws-infra]].
- Deploy to the shared dev stage with `AWS_PROFILE=devops npx sst deploy --stage dev`, run **manually** from a local checkout.
- `sst deploy` ships the **current working tree, not git HEAD** — uncommitted changes (and unrelated parallel-session WIP on the same branch) are always deployed alongside the intended change. Pushing to `origin/dev` has **no** deploy side-effect (no GitHub Actions CI on the repo).
- The dev stage's `.sst/stage` file may read `colinwong` (a separate personal stage); always pass `--stage dev` explicitly so secret-set and deploy commands target the shared environment.
- Production is a separate stage marked `protect:true` / `removal:retain` in `sst.config.ts`.

## Migrations & DB coordination

Migrations are applied **manually** against dev RDS via the SSM tunnel; they do **not** run during `sst deploy`. Deployed code and DB migration must be coordinated by hand or routes 500 on missing columns. Schema detail lives in [[colin/data-model]].

| Item | Value |
|---|---|
| Apply command | `npm run db:migrate-safe` |
| Non-safe precedent | `scripts/migrate-via-ip.mts` |
| `DATABASE_URL` (`.env.local`) | `127.0.0.1:5432` (SSM port-forward tunnel — must be running first) |
| SSM bastion instance | `i-03fce88da86abb69c` |
| Tunnel host | `wl-companycam-dev.c52gm8goign8.us-east-2.rds.amazonaws.com` |

- `sst shell --stage dev` does **not** expose `DATABASE_URL` (only `SST_RESOURCE_*` vars), so `sst shell -- npm run db:migrate-safe` fails with `ECONNREFUSED 127.0.0.1:5432`. Run the migration script directly against the `.env.local` URL with the tunnel up.
- Deploying schema-bearing WIP without first applying its migration regresses live endpoints. Seen with `0020` (`files.change_order_amount_cents` + `signature_requests.stripe_invoice_id`), `0032` (`contract_value_cents`), and `0045_brief_hex` (`pnl_receipts`). Mitigation: surgical deploy (stash WIP → deploy → restore) or apply the migration before/alongside deploy.
- Ad-hoc live-data cleanup on dev RDS is done via scoped, auditable ops scripts (with dry-run support) through the same SSM tunnel — **not** ad-hoc SQL one-liners.

## Isolated / clean-worktree deploys

To deploy a clean slice without shipping dirty-tree WIP, build from a detached git-worktree at HEAD (or copy only the changed files onto HEAD) and deploy from there, so the deployed commit matches `origin/dev`.

- Clean worktrees get `node_modules` as a **symlink** back to the main workspace; Turbopack panics on this during the Next.js production build. Fix: remove the symlink and run a real `npm ci` inside the worktree.
- The worktree also needs the untracked deployment artifact `functions/video-poster/bin/ffmpeg`, generated via `scripts/fetch-ffmpeg-binary.sh` (or copied in) before deploying, or SST fails before the app update.

## Deploy gotchas & pitfalls

See [[colin/gotchas]] for the broader catalog; deploy-specific ones:

- A targeted SST deploy of a single resource (e.g. `GeminiApiKeyParam`) updates the web Lambda as a side effect, forcing a cold start that clears the in-memory secret cache — useful for picking up a rotated secret without a full app redeploy.
- After deploy, the Lambda can run a **stale Next.js build cache** so the bundle doesn't reflect recent code (confirmed via a size-6 PDF anchor fix that still rendered size-1 post-deploy). Fix: clean build artifacts and redeploy.
- `sst deploy` acquires a Pulumi lock; a concurrent in-flight deploy throws `A concurrent update was detected on the app` — wait it out, do **not** force-unlock.
- AWS SSO sessions for the `devops` profile expire and cause deploy to fail with exit code 1; refresh with `aws sso login --profile devops` (complete the browser approval) before deploying.
- `sst diff` leaks temporary AWS creds in plaintext — avoid it.

## Verification

| Check | Expected |
|---|---|
| Dev stage URL | `https://project.dev.gunnerroofing.com` |
| Health check | `GET /api/health` → `{"ok":true, service:"wl-companycam"}` (200 = Lambda up) |
| NAT-gateway egress | `GET /auth/refresh` → 307 in under ~20s (the ~20s threshold is the NAT-blackhole indicator from a prior incident; 0.47s observed healthy) |
| New route deployed | returns 401 unauth (**not** 404); gated pages redirect unauthenticated requests to `/login?from=…` |

The deployed dev site requires real Cognito login; the local dev-auth shim (`DEV_AUTH_USERNAME`) works only locally. See [[colin/google-sso]] for the auth surface.

## Git & harness constraints

- The Claude Code harness blocks direct pushes to `main` (default-branch protection, classifier-level, not overridable conversationally); the only agent path is branch → push branch → open PR via `gh` → merge (precedent: PR #14).
- `sst deploy` against shared dev infra is gated by an auto-mode safety classifier (e.g. phrasing "commit these to dev") and requires explicit user confirmation before running; the local commit itself is not gated.
- After a `git reset` that moves commits into the working tree, all files get a fresh mtime — you cannot use file mtimes to attribute changes to a given day.
- The (now-removed) `permit-poc/` tree carried its own `node_modules/` and generated `out/`; its nested `.gitignore` excluded both so only source/docs/tests staged. See [[colin/permits]].

## Notable deploy events (history)

| Date | Event |
|---|---|
| 2026-06-15 | `/points` deployed to dev via isolated clean worktree (points-only changes); smoke: `/points` unauth → `/login?from=%2Fpoints`, `/api/health` 200. Changes still uncommitted locally at session end. See [[colin/points-leaderboard]]. |
| 2026-06-10 | Commit `982bd3c` on `deploy/workflow-ui` deployed wave-1 to dev: migration `0031`, pre-install phase cleanup (22 projects), phantom-task soft-delete (377 tasks / 6 projects), red/yellow attention status, reporting bar, CO→Stripe invoice, task PM default, perf work. Branch **not** pushed to remote at session end. See [[colin/forward-reporting]], [[colin/stripe-make]]. |
| 2026-06-03 | CompanyCam project importer committed (`ef8b8bf`); SST wiring recovered from stash `f0e2fe3`. Stays dormant until `CompanyCamApiToken` secret set + dev redeploy + Project Labels stage-mapping decision. (Corrects an earlier note that claimed it was "deployed dormant to dev 2026-06-02" — work actually sat uncommitted.) |

## Open questions / TODOs

- CompanyCam importer is still dormant **as of 2026-06-21**, pending: set `CompanyCamApiToken` SST secret, redeploy dev, and resolve the Project Labels stage-mapping product decision.
- `deploy/workflow-ui` (commit `982bd3c`) was not pushed to remote — dev and origin diverged until pushed (noted 2026-06-10).
- Standing risk: with multiple features in-flight on one branch, every `sst deploy --stage dev` ships all dirty-tree WIP. For production deploys, commit only the targeted files first. See [[colin/risks]].

---

_Sources: 2026-05-21 → 2026-06-21, ~18 distinct work sessions._
