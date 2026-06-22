---
type: reference
owner: colin
app: GunnerCam
created: 2026-05-07
updated: 2026-06-21
tags: [wl-companycam, aws, infrastructure, sst, rds, networking]
status: active
---

# AWS Infrastructure

## Account topology & shared VPC

| Item | Value |
|---|---|
| Gunner dev/app AWS account | `980921733684` (us-east-2) |
| Org management account | `661095510147` (owned by eddie@gunnerroofing.com) — IAM Identity Center / SSO lives here |
| Region (stack) | `us-east-2` |
| Local AWS profile | `devops` (AdministratorAccess on the dev account) |
| SST stages | `dev` only — no prod stage (see [[colin/risks]], [[colin/ops-deploy]]) |

- The org management account `661095510147` owns IAM Identity Center / SSO. Dev-account users **cannot** change org-level SSO session duration without it.
- Five RDS instances live in account `980921733684`, all private (`PubliclyAccessible: false`), each in its own VPC:

| Instance | Engine | Notes |
|---|---|---|
| `gunner-masterdb-dev` | Aurora PG 17.7, Serverless v2 | Behind RDS Proxy; shared-core — see [[colin/masterdb-sync]] |
| `gunnerteam-dev` | PG 18.3 | Tyler's GunnerTeam app — see [[colin/external-api-integration]] |
| `gunner-ops-dev` | PG 16.14 | LEO / procurement (schema `ops`) |
| `dev-gunner-aurorapgdb-rds` | Aurora PG 16.8 | Legacy QP/projects/admin cluster `dev-gunner-aurorapgdb-db-cluster` in `vpc-0eb66556f100c7b3c`, serving ~150 api-v1 Lambdas |
| `wl-companycam-dev` | PG 16.13 | This app's DB (db name `postgres`, master user `postgres`) |

- masterdb cluster writer endpoint: `gunner-masterdb-dev-masterdbcluster-kdsmbssw.cluster-c52gm8goign8.us-east-2.rds.amazonaws.com:5432`; credentials in Secrets Manager under `gunner-masterdb-dev-MasterDbProxySecret-ekcuoour`. masterdb's Aurora Data API (`httpEndpoint`) is disabled, so programmatic access needs a VPC tunnel/jump host (a `t4g.nano` in a private subnet with the default SG suffices — firewall already allows all `10.0.0.0/16` on 5432).
- Key API Gateways in the account: masterdb `of4rvaa43c`, gunner-ops/LEO `1uejx95wwf`, GunnerTeam iOS `k5h2n0rog9`, Subportal `m4523l05yb`. LEO (procurement) == `gunner-ops` (the `gunner-ops-dev-api` Python 3.13 Lambda, Postgres schema `ops`); Crew Portal likely maps to `gunner-subportal-dev-*`. QP/COLIN/Marketing apps are **not** deployed in this account (see [[colin/people-and-context]] for the ecosystem map).
- Stage/prod infra for the sales/customer portal (custom domain `api-prod.gunnerroofing.com`, stage EC2 `i-01a18718706e85336`, prod ECR) does **not** exist in `980921733684`; presumed in a separate account reached via cross-account OIDC role. The customer-portal has only dev+stage GitHub Environments and a dev-named ECR repo — a hard blocker for any prod deploy.
- The `sales-portal-frontend` SSM deploy doc (only a `-dev-` slug exists in this account) hardcodes `git pull origin dev`, so stage deploys may silently pull dev code.

## Live deployment (dev stage)

- **App URL:** `https://project.dev.gunnerroofing.com` (CloudFront in front of three Lambdas: web server, image optimizer, page revalidation, via OpenNext / `sst.aws.Nextjs`). The older `https://d2gd0tqb1r9ceg.cloudfront.net` CloudFront name is the raw distribution.
- `/api/health` returns `{ok:true,service:'wl-companycam'}` — **liveness-only, does NOT touch the DB**. A green health check does not prove DB connectivity; probe the external API (Bearer key, `GET /api/external/v1/projects`) for an autonomous DB-path check (see [[colin/external-api-integration]]).

## Hosting, SST & deploy mechanics

See [[colin/ops-deploy]] for the full deploy runbook; summary here.

- Deploy: `AWS_PROFILE=devops npx sst deploy --stage dev`. SST scaffolding (`sst.config.ts`, `sst-env.d.ts`) first added 2026-05-25 (commit `95f71f0`); prior to 848ef99 (2026-05-06) there was no SST config. Build time ~5–12 min (code-only ~5–7 min).
- **No GitHub Actions / CI deploy workflow** — pushing a branch does NOT update the live site; SST deploy is always run manually from a local machine. SST stages are independent of git branches.
- **SST deploys the entire working tree, not HEAD or a git ref** — uncommitted/dirty WIP goes live on dev. This is an established, intentional pattern (confirmed repeatedly through 2026-06-21). The real gate is `npm run lint && npm test`, not commit state.
- Safe deploy ordering when schema changes: (1) bring up SSM tunnel, (2) `npm run db:migrate-safe`, (3) `sst deploy`. Migrating first is zero-downtime; deploying first 500s every query on the new columns. Canonical 2026-06-21 pre-deploy checklist: `db:generate` (no drift) → lint → `npm test` → `db:migrate-safe` → `sst deploy --stage dev`.
- Post-deploy SST auto-issues a CloudFront invalidation (`UpdatedWebInvalidation`), but open browser tabs still need a hard refresh (Cmd+Shift+R) — hashed CSS/JS assets are served immutable.
- Dev deploys are gated by the safety classifier as a shared-infra deploy (external partners consume the dev API) and require explicit authorization each time.

## Auth, SSO & credentials for deploying

- The deploy/bastion profile is `devops` (AdministratorAccess) via SSO session `gunner` at `https://gunnerroofing.awsapps.com/start` (`sso_region = us-east-1`); `sst.config.ts` hardcodes the `devops` profile. The dev server (`next dev`) uses the AWS SDK and needs `AWS_PROFILE=devops` set in the shell (NOT in `.env.local`).
- Correct re-auth: `aws sso login --profile devops` (or `aws sso login --sso-session gunner`). The newer `aws login` alias 403s for this org (needs `SignInLocalDevelopmentAccess` policy) and writes a credential format SST's SDK cannot read — using it causes SST `InvalidGrantException`. Expired SSO tokens cause silent deploy failures.
- SST cannot refresh SSO tokens itself; occasional workaround is eval-exporting temp STS creds and reverting `sst.config.ts` after deploy. Long-term fix: ask Eddie to raise IAM Identity Center session duration from 8h. A proposed (unconfirmed) zsh `dev()` wrapper auto-refreshes SSO before `npm run dev`.
- CloudWatch log access for dev requires the `devops` profile; the app's own key in `.env.local` lacks `logs:DescribeLogGroups`. Secret VALUES in Secrets Manager are IAM-blocked for the agent; the `devops` profile covers sts/CloudWatch/S3/Cognito/Secrets-Manager-list operations.
- `sst diff` leaks temporary STS creds (`SST_AWS_ACCESS_KEY_ID/SECRET_ACCESS_KEY/SESSION_TOKEN`, short-lived ASIA* AdministratorAccess) in plaintext build output; `sst deploy` is clean. SST deploy *failures* can also dump the full Lambda env secret map in plaintext (one incident 2026-06-04 with a `tee` pipe masking the non-zero exit — transcript exposure is unrecoverable without rotation). See [[colin/gotchas]].

## Networking: VPC / NAT / RDS reachability (the 2026-05-27 incident)

- The dev web Lambda runs inside the default VPC (`172.31.0.0/16` / `vpc-01348041c36d04d16`) to reach private RDS, which strips its default internet access — VPC Lambdas have no public IP and cannot egress via an Internet Gateway, so all external calls (Cognito, DocuSign, SES, webhooks) need a NAT. DB-only pages work without it.
- **Root cause of the dev outage:** on 2026-05-20, IAM user `tyler-cli` deleted the dev NAT gateway (`nat-072f635d65782704a`, created 05-15 for RDS hardening) two days after the Lambda was VPC-placed (05-18), silently black-holing all Lambda internet egress → 20s hangs → CloudFront 504 on Cognito-touching paths like `/auth/refresh`. Latent until exercised.
- **Fix (FIXED 2026-05-21, now in IaC):** NAT gateway is declared in `sst.config.ts` so it self-heals on deploy. A dedicated private subnet (`172.31.48.0/24`, us-east-2b, `subnet-03130dde04a92ed0c`) was created for the dev Lambda with its own route table sending `0.0.0.0/0` to NAT `nat-090dd8d36a342eec6` (EIP `3.21.13.175`). The Lambda was moved off the shared public subnet `subnet-03ee97b5c786ec41a` (which also hosted RDS, the RDS Proxy ENI, and another project's Lambda).
- **Separate but related dev-DB intermittency** (~50% of Lambda→RDS connections black-holed for 20s): the dev RDS was `PubliclyAccessible=true` while Lambda subnets routed `0.0.0.0/0` to an IGW. When DNS returned the public IP the packet died at the IGW. **Definitive fix: set `PubliclyAccessible=false`** (no reboot), forcing in-VPC DNS to always return the private IP. This also closed a `0.0.0.0/0`:5432 hole. An RDS Proxy attempt did NOT fix it (ClientConnections stayed 0 — same routing problem); proxy Phase 2 was rolled back.
- The dev VPC has **no S3 gateway endpoint** and `wl-companycam-dev-cw` has no VPC-endpoint bucket policy, so S3 traffic routes through NAT (works, but a free gateway endpoint would optimize it). *Correction: the prior claim of an existing S3 gateway endpoint was stale.*

## RDS security group & DB connection details

- The dev RDS SG `sg-0691f10fcdbf09a13` (wl-companycam-rds-dev) has an over-broad `0.0.0.0/0` ingress on TCP 5432. Since the DB is private the risk is lateral access from other projects' Lambdas in the shared default VPC `vpc-01348041c36d04d16` (e.g. a `gunnerteam-dev-assistant-stream` ENI was observed in a shared subnet). Recommended fix: replace with SG-referenced rules for the dev web Lambda (`sg-07f31f46b5a92fe64`) and SSM bastion (`sg-04cddab97e762e6b8`).
- The three legitimate 5432 consumers:

| Consumer | Security group |
|---|---|
| Web Lambda | `sg-07f31f46b5a92fe64` |
| SSM bastion `i-03fce88da86abb69c` | `sg-04cddab97e762e6b8` |
| SST RDS Proxy `wl-companycam-dev-proxy` | `sg-0939d2fc63e527ee4` |

- The office CIDR `142.255.4.220/32` rule is **dead** (no public IP; office access goes through the bastion). The RDS SG is **hand-managed, NOT in `sst.config.ts`**, so CLI rule changes don't conflict with `sst deploy` (flagged as an IaC gap).
- RDS Proxy `wl-companycam-dev-proxy` is deployed but **disabled** via `useDbProxy = false` (around `sst.config.ts:180`). Its internal-VPC leg has `requireTls: false`; flipping to true is low-risk but non-blocking (postgres.js already enforces TLS). When re-enabled, add a `sg-0939d2fc63e527ee4` ingress rule to the RDS SG.
- An RDS Proxy SG **description containing `>`** (e.g. `->`) makes the AWS API reject the request with a validation error.
- `src/db/index.ts` uses a bare `postgres(url, {max:1})` with no `connect_timeout`/`idle_timeout`/`max_lifetime`, so a stale connection on a warm Lambda hangs to the 20s timeout rather than recycling. A timeout patch was applied but did not fix the real (routing) root cause. **Decision: do NOT raise `idle_timeout`** — it's the working mitigation against the dead-connection / CloudFront-504 mode; the ~5–15ms gain isn't worth reintroducing 20s hangs (locked in [[colin/decisions]]; revisit only after the RDS Proxy cutover).

## SSM bastion & DB tunnel

See [[colin/masterdb-sync]] for the masterdb tunnel recipe; this is the WL-CompanyCam DB tunnel.

- The live bastion is `i-03fce88da86abb69c` (`wl-companycam-dev-bastion`) — the only SSM instance in `vpc-01348041c36d04d16` (same VPC as `wl-companycam-dev` RDS). The old `i-0448d430b169b0ff5` referenced in `.env.local` was terminated and in a different VPC; AWS.md + `.env.local` were corrected. The deployed Lambda reaches RDS via VPC config — the tunnel is only for local scripts (migrations, psql).
- The SSM port-forward to dev RDS (localhost:5432) is a recurring flakiness point (auto-memory: "dev DB is a flaky SSM tunnel"); a mid-session drop (2026-06-17) broke My Day's `dal.ts:123` user lookup until the tunnel restarted (then rendered 79 rows clean). Claude's Bash sandbox cannot probe `127.0.0.1`, so `/dev/tcp` checks always report "closed" even with a working tunnel — verify via `lsof` (with `dangerouslyDisableSandbox`) or a real psql connection.
- Migrations applied to dev via the tunnel + `npm run db:migrate-safe` (loads `.env.local` itself; enum-safe, the established precedent over `db:migrate`): incl. 0014/0015 (2026-05-27), 0023 (2026-06-03, 5 tables + 5 enums), 0028 (committed but unapplied as of 2026-06-09), 0044 (2026-06-17). Raw SQL into enum columns needs explicit casts (e.g. `::task_input_type`) or the transaction rolls back.

## Lambda config, the 4 KB env-var ceiling & SSM secrets

- **The web Lambda env-var space sits at AWS's hard 4 KB ceiling** — the single most recurring deploy gotcha (see [[colin/gotchas]]). Adding even a short new SSM-param-name env var can push it over and fail the deploy. Repeated breaches: Stripe keys (8a96086), Monday flip target (f31c258/3ed6c41), three Monday board/column/label vars, CompanyCam sync cron secret, the location-insights warmer secret.
- `DOCUSIGN_PRIVATE_KEY` (~1.7 KB PEM) was the largest single contributor. **Decision (2026-06-17, [[colin/decisions]]): large secrets live in SSM, not Lambda env.** It moved to `/wl-companycam/{stage}/docusign-private-key` (commit `2a54ee8`); the signing lib reads `DOCUSIGN_PRIVATE_KEY_PARAM` on Lambda, falls back to `DOCUSIGN_PRIVATE_KEY`/`DOCUSIGN_PRIVATE_KEY_PATH` locally.
- **Standard secret pattern:** SST secret → SSM SecureString → Lambda gets the param NAME as an env var → server-only client reads value at runtime and memoizes.

| SST secret | SSM param | Lambda env (param-name) |
|---|---|---|
| `StripeAccountKeys` | `/wl-companycam/{stage}/stripe-account-keys` | (see [[colin/stripe-make]]) |
| `MondayApiToken` | `/wl-companycam/{stage}/monday-api-token` | — (see [[colin/monday-integration]]) |
| `CompanyCamApiToken` | `/wl-companycam/{stage}/companycam-api-token` | `COMPANYCAM_API_TOKEN_PARAM` |
| `GunnerteamServiceKey` | `/wl-companycam/{stage}/gunnerteam-service-key` | local `GUNNERTEAM_SERVICE_KEY` |
| `GunnerteamApiUrl` | — | `https://api-dev.team.gunnerroofing.com` |
| Gemini | `/wl-companycam/{stage}/gemini-api-key` | (see [[colin/gemini-route-review]]) |
| Maps | `/wl-companycam/{stage}/google-maps-api-key` | (see [[colin/managers-map]]) |
| DocuSign key | `/wl-companycam/{stage}/docusign-private-key` | `DOCUSIGN_PRIVATE_KEY_PARAM` |

- The location-insights warmer reuses `TASK_REMINDERS_CRON_SECRET` rather than a dedicated secret, to stay under 4 KB (see [[colin/location-pings]]).
- SST **refuses to deploy a SecureString SSM param with an empty value** — newly-introduced secrets must default to a non-empty placeholder (e.g. `'UNSET'` / a single space `' '`) to deploy while keeping the feature dormant. Monday uses a safe `|| ' '` guard in `sst.config.ts`; Stripe's binding is raw. **Gotcha:** the `StripeAccountKeys` SST secret and its live SSM param can diverge (observed: secret = 1 char while SSM held the real 632-char rk_live map), and `sst deploy` will overwrite SSM with the blank secret — copy the live SSM value back into the SST secret before deploying.
- masterdb and gunner-ops Lambdas store **plaintext DB creds + JWT secrets in Lambda env vars** (readable via `lambda:GetFunctionConfiguration`) — flagged pre-prod tech debt (see [[colin/risks]]).
- **VideoPoster Lambda:** 2048 MB memory, 300s timeout, 2 GB `/tmp`; S3 download streams into `/tmp` (a 500 MB source can't fit in a Buffer). Its `functions/video-poster/bin/ffmpeg` (~68 MB) is gitignored — worktree deploys must copy it from the main checkout or run `scripts/fetch-ffmpeg-binary.sh`.
- **Web Lambda perf (commit `e334e70`, deployed dev 2026-06-10):** upgraded 1024 MB x86 → 2048 MB arm64 with `warm: 1` (one pre-warmed instance, pinged every 5 min, <$0.25/mo, cost-neutral since arm64 is ~20% cheaper/GB-s). 20s timeout. The "~6 concurrent connections" figure is warm execution lanes, not a hard per-client cap — overflow scales into new execution environments (pays cold start); Tyler sizes fan-out at 4 concurrent / 6 ceiling (see [[colin/external-api-integration]]).

## Cognito, S3 & service config

- **Two dev Cognito user pools:** `dev-gunner-cognito` (`us-east-2_sEOcsFA76`, used by WL-CompanyCam) and `gunner-masterdb-dev` (masterdb auth layer). The same username (e.g. `appreview`) can exist in both; password resets must be applied per-pool.
- IAM permissions attached to the Web Lambda role:
  - **S3** on bucket and `bucket/*`: `GetObject`, `PutObject`, `DeleteObject`, `ListBucket`.
  - **Cognito** on user pool ARN: `InitiateAuth`, `RespondToAuthChallenge`, `GlobalSignOut`, `AdminCreateUser`, `AdminSetUserPassword`, `AdminGetUser`, `AdminDisableUser`, plus `ChangePassword` (added in `sst.config.ts` + AWS.md).
- Cognito `ChangePassword` (old password verified, token from `ccam_access` cookie via `getRawAccessToken()`) is the primary password-change path; `AdminSetUserPassword` is a fallback when no access token (dev-auth shim — see [[colin/google-sso]]).
- Cognito user creation creates the identity first then inserts the DB row — a DB failure leaves an **orphaned Cognito account** requiring manual cleanup. User deactivation soft-deletes only the local DB row (`deleted_at`) with no restore endpoint/UI.
- All scripted Cognito user creation uses `MessageAction: "SUPPRESS"` and sets `Permanent: true` so users skip the `NEW_PASSWORD_REQUIRED` flow.
- **S3 bucket is `wl-companycam-dev-cw` in us-east-1** while the VPC/stack is **us-east-2** — a cross-region hop costing ~10–15ms per server-side S3 op plus transfer fees. A VPC gateway endpoint cannot bridge regions (physically inert, rejected as a perf fix); the real fix is migrating the bucket to us-east-2 as a separate planned data migration. Bucket is fully private; tenant isolation by **key prefix only** today (per-corp prefix; [[colin/decisions]] open question on prefix vs bucket-per-corp). CORS allows `localhost:3000`/`3001` + env extras (GET/PUT/POST/HEAD, `MaxAgeSeconds: 3000`, ETag exposed). No lifecycle policy for orphan cleanup (see [[colin/risks]]). See [[colin/photos-uploads]] for the upload pipeline.
- `corporations.timezone` (default `America/New_York`) drives all server-side "today" computations (`todayIsoDateInTimeZone` in `view-models.ts`) for daily logs and [[colin/my-day]]; per-project timezone is deferred.

## SST configuration (`sst.config.ts`)

- App name `wl-companycam`, home `aws`, provider region `us-east-2`, profile `devops`.
- `removal: "remove"` for non-prod stages, `"retain"` for `production`. `protect: ["production"]`.
- Core SST secrets resolved at deploy: `DatabaseUrl`, `CognitoUserPoolId`, `CognitoAppClientId`, `S3Region`, `S3Bucket`, plus the runtime-integration secrets listed above (Stripe / Monday / CompanyCam / Gunnerteam / Gemini / Maps / DocuSign).
- Primary resource: `sst.aws.Nextjs("Web", …)`. Env vars wired: `DATABASE_URL`, `COGNITO_USER_POOL_ID`, `COGNITO_APP_CLIENT_ID`, `AWS_S3_REGION`, `AWS_S3_BUCKET`, plus SSM param-name vars.
- `bedrock:InvokeModel` is granted on `resources:["*"]` (wildcard) — flagged for tightening (see Open questions).

## How RDS, S3, Cognito interact

The app is the bridge — no direct connections between AWS services.

- **Photo upload:** browser → app (`POST /api/uploads/presign`) → app returns presigned PUT URL → browser PUTs bytes direct to S3 → browser → app (`POST /api/photos`) → app inserts row in RDS. Bytes never traverse Lambda.
- **Login:** browser → app → Cognito `InitiateAuth` → JWTs back → app sets HTTP-only cookies. Subsequent requests: app verifies JWT signature locally, then RDS lookup by `cognito_sub`. Per-request session resolution stays in-process.

## Deploy-time build gotchas

See [[colin/ops-deploy]] and [[colin/gotchas]] for the full set.

- `next build` runs strict `tsc` during `sst deploy`, but the local gate is lint + vitest (vitest does NOT type-check), so type errors in non-test files surface only at deploy time. Confirmed failures: assigneeType literal-union (commit `9f0d873`, fixed `8ee442c`), masterdb sync script casts (2026-06-11), missing `ForecastStageBucket` import. Pre-existing TS errors anywhere in the tree (e.g. invalid pdfjs `isEvalSupported`, orphaned `onClose` prop) also block deploys.
- SST requires every declared secret to have a value before deploy succeeds even if code no-ops on empty (e.g. `WebhookProjectCommentAddedUrl/Secret` set to empty-string placeholders to unblock).
- `sst.config.ts` must NOT use top-level `import { aws } from '@pulumi/aws'` (SST v4 forbids it; use the generated global `aws`). `sst print` does not exist in SST v4 — use `sst state export --stage <stage>`. `sst deploy` regenerates `sst-env.d.ts` each run (noisy diff to restore manually). Stale SST deploy locks ("another update in progress" with no live process) must be cleared manually.
- Lambda alias routing weights can report the old version at weight 1.0 immediately after an alias update — poll to confirm the drain (an explicit `AdditionalVersionWeights={}` update + polling resolved it; no CodeDeploy was re-applying weights).
- SSM-deploy monitor pattern must match `✓  Complete` (two spaces); a single-space pattern false-positives on `OpenNext build complete.`. OpenNext duplicate-key warnings in the image-optimizer bundle are non-fatal.
- Git worktree deploys: symlinked `node_modules` works for vitest/ESLint but Next/Turbopack rejects symlinks pointing outside the FS root during the production build — run a real `npm ci`. The deploy worktree at `/private/tmp/` is reusable across sessions if on the right commit.
- The AWS API MCP `call_aws` tool has no shell composition (no pipes/grep/awk/env vars) and can't run streaming `aws ssm start-session` — use Bash for those; it defaults to us-east-1 but the stack is us-east-2. `suggest_aws_commands` is the NL fallback.
- zsh's special `path` array clobbers `PATH` if used as a loop variable — use any other name.

## Provisioning scripts (`~/repos/WL-CompanyCam/scripts/`)

All scripts use `fromIni({ profile: "devops" })` for AWS auth and `process.loadEnvFile(".env.local")` for `DATABASE_URL`. They explicitly set DNS to Google + Cloudflare resolvers (workaround for local DNS issues). See [[colin/provisioning-tickets]].

| Script | Purpose |
|---|---|
| `migrate-via-ip.mts` | Runs Drizzle migrations against `DATABASE_URL`. `postgres({ max: 1 })`. |
| `s3-cors.mts` | Sets CORS on the S3 bucket (localhost + `S3_CORS_EXTRA_ORIGINS`; GET/PUT/POST/HEAD; avoids wildcards on AWS-owned domains). |
| `provision-cwong.mts` | Creates Colin's Cognito user, sets permanent password from `SEED_USER_PASSWORD`, syncs `cognito_sub`. |
| `provision-test-users.mts` | Provisions test accounts; same Cognito flow. |
| `prune-broken-photos.ts` | `npm run db:prune-broken-photos` (`--dry-run`) — soft-deletes photos whose external URL fails an HTTP Range probe (cascades linked `updates` rows); idempotent. |

## Misc tooling / repo state

- **2026-06-11 branch consolidation:** repo reduced to `main` (deployed, `f34a00f`) and `feat/high-alert-tasks` (~22 unmerged commits — CompanyCam import/sync, 5-min cron, account provisioning); `deploy/workflow-ui`, `dev`, and ~30 others deleted as fast-forward dupes after confirming nothing depended on the names (deploys are local-machine only). See [[colin/build-timeline]].
- Pushing to `origin/dev` while another worktree locks the branch: stash → `reset --hard origin/dev` → pop → commit → `push HEAD:refs/heads/dev` (advances origin/dev without local checkout).
- GunnerTeam template integration activation per corp: set `TEMPLATE_SERVICE_BASE_URL` in SST stage config, apply migration 0025, `UPDATE corporations SET template_api_key = '<key>' WHERE slug = '<slug>'` (key DM'd by Tyler).
- Claude.ai app connectors do NOT carry into Claude Code CLI (separate MCP surfaces); Monday added via `claude mcp add --transport sse --scope user monday https://mcp.monday.com/sse`. No standalone Stripe MCP — Stripe's 5 restricted keys read from SSM at runtime via `src/lib/stripe.ts` (see [[colin/stripe-make]]).
- Local-PG preview alternative: a second Postgres on `:5433` (gunnercam_local, no SSL, /tmp socket) avoids the flaky tunnel, but Next refuses two dev servers from one repo simultaneously, and the running server expected SSL on `127.0.0.1:5432`.
- **Deployed milestones:** assignee/timezone fix (2026-05-29, 200/325ms); perf pass `0fd180e` (2026-06-09); CompanyCam import dormant (2026-06-09); triage-sections `bd12cb8` (2026-06-15); migration 0044 + DocuSign-SSM `2a54ee8` (2026-06-17); workflow-UI `c193ea2` (2026-06-11); clean-handoff candidate `8de4ddf` (2026-06-16, 1394 tests).

## Cost (today, 1 corp + ~5 testers)

| Service | Estimated monthly |
|---|---|
| RDS Postgres (dev) | ~$15–18 |
| Lambda (2048 MB arm64, warm:1) | ~$0–1 (+<$0.25 warmer) |
| CloudFront | ~$0 |
| S3 (+ cross-region transfer) | ~$0–1 |
| Cognito | $0 |
| CloudWatch | ~$0–1 |
| **Total** | **~$15–22/mo** |

Scaling projections in [[colin/boss-briefing]] §6.

## Open questions / TODOs (as of 2026-06-21)

- **masterdb infra ownership (open):** the `gunner-masterdb` RDS cluster, its parameter group, and the DB roles Tyler references are NOT in the WL-CompanyCam SST stack (`sst.config.ts` only looks up the existing `wl-companycam-dev`). The owning repo/stack must be found before applying Tyler's SQL (demote the GunnerTeam DB role off superuser, pin `rds.force_ssl`). See [[colin/masterdb-sync]].
- **IAM tightening (Tyler shared-fate audit):** `bedrock:InvokeModel` is granted on `resources:["*"]` (wildcard) in `sst.config.ts`. Whether the `DATABASE_URL` user is superuser/`bypassrls` can't be confirmed from code — needs a live DB query.
- Tighten the dev RDS SG: replace `0.0.0.0/0`:5432 with SG-referenced rules (web Lambda + bastion); consider importing the hand-managed SG rules into `sst.config.ts`.
- Production observability/safety is unwired (no CloudWatch alarms, WAF, Route 53, SQS, runbook, rollback, or backup plan; README is stock Next.js scaffold); `/api/health` is liveness-only with no readiness check. See [[colin/risks]], [[colin/ops-deploy]].
- Move masterdb + gunner-ops Lambda plaintext DB creds/JWT secrets out of Lambda env into SSM/Secrets Manager before prod.
- Migrate the S3 bucket from us-east-1 to us-east-2 (planned, separate change). Optionally add a free S3 VPC gateway endpoint to the dev VPC.
- Ask Eddie (mgmt account `661095510147`) to raise IAM Identity Center SSO session duration above 8h.
- Consider re-enabling the RDS Proxy (`useDbProxy` flag) and flipping its internal-leg `requireTls` to true; the proxy is the right time to revisit `idle_timeout`.
- Add a user-restore endpoint/admin affordance; add an orphaned-Cognito cleanup path.
- `GunnerteamServiceKey` (Keeper) must be `sst secret set` on dev before location-compliance proxies go live (was a blank placeholder; real key deployed 2026-06-18, but Keeper CLI unavailable locally). See [[colin/location-pings]].
