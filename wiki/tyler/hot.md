# Wiki Hot Cache

**Last Updated:** 2026-06-11 — cc-390–393 fleet inspection UX sprint ✅

## Current State (2026-06-11)

**Repo:** `~/Dev/GunnerTeam/` | **Lambda:** v171 live (prod Aurora) | **iOS:** BUILD SUCCEEDED
**release/3.0.0** frozen at `74c9d2c`. All new work on `main`.
**OMP:** 15.11.1

**Pending deploy:** cc-391 backend (`GET /vehicle/inspections` + review_status/notes/license_plate) — code in `function.zip`, MFA expired before deploy. Run deploy block when MFA is refreshed.

**Customer Photo Upload (cc-279–288):** Working. Root cause was `PayloadTooLargeError` — Express JSON body limit raised `100kb → 20mb` in `src/app.js`. CompanyCam `POST /projects/:id/photos` returns `{ photo: {...} }` (wrapped), so `gt_customer_photos` INSERT now unwraps `ccData?.photo ?? ccData?.photos?.[0]` (the old `ccData?.id` guard silently skipped every insert). CC dev `/photos` never populates `source`, so the `gt_customer_photos` table lookup is the sole `isCustomer` signal. All PHOTODEBUG/GETDEBUG/UPLOADDEBUG/ROUTEHIT debug logs removed.

## Tab Bar Architecture (cc-207, cc-224/225, cc-230/231/232/233)

`ContentView` is a `TabView` with Jobs/Forms/Fleet/More. Each tab uses a wrapper struct (`JobsTabRoot`, `FormsTabRoot`, `FleetTabRoot`, `MoreTabRoot`) that owns `.toolbar` while the inner view struct owns `.navigationTitle` — required for SwiftUI large title to render.

**Scroll-aware titles:** `ScrollTitleKey` PreferenceKey + `ToolbarItem(.principal)` with `.opacity(showNavTitle ? 1 : 0)`. Never use `if showNavTitle { }` — leaves slot empty, SwiftUI double-renders. Jobs uses named coordinate space `jobsScroll` with `maxY < 0` threshold.

**Logo → Settings:** `.onTapGesture` (not `Button`) to avoid press artifact on tab switch.

**MoreView:** Tile grid with `moreRow` helper. Scroll bounce disabled on short-content tabs: `.scrollBounceBehavior(.basedOnSize)`.

## PhotoMarkupEditor Chrome (cc-42 through cc-46, cc-190 through cc-194)

**Root cause:** SwiftUI `safeAreaInsets == .zero` on fullScreenCover first layout pass. UIKit key window insets (`deviceSafeInsets()`) + `GeometryReader` width pinning required. Backdrop must have explicit `.frame(width: geo.size.width)`. All entry points use direct `fullScreenCover(item:)` — no `MarkupWrapper`. `PhaseDetailView` uses `$phaseMarkup` + `onDismiss` handoff (not swap-in-place).

## ThemeManager + Gunner Brand Colors (cc-200, cc-226/227)

`ThemeManager` loads from `GET /org/theme`, applies to 8 tokens, persists via `UserDefaults["gt_theme.*"]`. `AppSecondary.colorset` = Gunner teal (`#006782` light / `#00bee9` dark).

**Color rules:** `appSecondary` (teal) = sole interactive accent. `appDestructive` (red `#DD141E`) = titles/errors. `appWarning` (amber) = warnings only, NOT a brand color. `appPrimary` (navy `#1B538F`) = links.

## 360 Photo Capture (cc-203 through cc-207)

`Photo360CameraSession`: full-screen camera + collapsible tag column + bottom-right gallery. Tags: label-only (`itemId==nil`) or hidden-sibling (`itemId!=nil`). `handle360Captures` routes: tagged with `itemId` → PATCH sibling item; untagged/label-only → PATCH 360 item. Label-only damage → `ownFlag=true` → 360 item flagged.

## Backend

- **`GET /fieldportal/tasks/high-alert`** — single upstream call (cc-327); no 1+N fan-out
- **`GET /fieldportal/jobs/:id/photos?limit=&before=`** — paged gallery route; cursor-based
- **`POST /announcements/:id/read`** — idempotent upsert; `priority` field on announcements
- **Time tracking:** `POST /time/checkin|checkout|travel-ping`, `GET /time/active|my|events|summary` (cc-343, cc-367)
- **Field Portal push:** `pushFieldPortalCheckin`/`pushFieldPortalCheckout` awaited before response; `displayName` in payload
- **`POST /auth/validate`** — role scoped to `gunner-team` app via `LEFT JOIN LATERAL` (cc-100)
- **Lambda v171** live (alias `live`). Prod Aurora. Body limit 20mb.
## FAB State Machine

`onDisappear` never restores FAB — only `onAppear` on destination drives it. `JobsView.onAppear` restores. `JobGuidedView.onAppear` hides. `GuidedTasksView.onAppear` hides (and has `assistantStore` injected).

## Deploy Method

```bash
cd ~/Dev/GunnerTeam/gunnerteam-api
zip -r /tmp/lambda-ccNNN.zip src/ node_modules/ -x "*.git*" "node_modules/.cache/*"
AWS_PROFILE=mfa aws s3 cp /tmp/lambda-ccNNN.zip s3://gunnerteam-lambda-deploy-useast2/lambda-ccNNN.zip --region us-east-2
AWS_PROFILE=mfa aws lambda update-function-code --function-name gunnerteam-dev-api --s3-bucket gunnerteam-lambda-deploy-useast2 --s3-key lambda-ccNNN.zip --region us-east-2 --no-cli-pager
AWS_PROFILE=mfa aws lambda wait function-updated --function-name gunnerteam-dev-api --region us-east-2
V=$(AWS_PROFILE=mfa aws lambda publish-version --function-name gunnerteam-dev-api --region us-east-2 --query 'Version' --output text)
AWS_PROFILE=mfa aws lambda update-alias --function-name gunnerteam-dev-api --name live --function-version $V --region us-east-2
```
Migration payload needs `--cli-binary-format raw-in-base64-out` + `"_secret":"gunner-migrate-2026"`.

---

## Vault Status

**197 pages. Lint clean (2026-06-10).** 0 dead links, 0 frontmatter gaps.

---

## gunner-ios → gunner-masterdb Migration (COMPLETE — 2026-05-21)

Cutover executed. Lambda reads from masterdb RDS. `gt_id_map` dropped. All `gt_` tables live.
See [[meta/session-2026-05-19-masterdb-migration]] for full revision chain and cutover log.
---

## Current API Architecture (post-Lambda migration)

> **EC2 is gone.** All traffic: Cloudflare DNS → API Gateway → Lambda alias `live` (PC=2) → Express app.

| Fact | Value |
|---|---|
| API base URL | `https://api.team.gunnerroofing.com` |
| Lambda function | `gunnerteam-dev-api`, v171 live on alias `live` |
| Provisioned concurrency | 2 containers always warm (~$22/mo) |
| Dev URL | `https://api-dev.team.gunnerroofing.com` |
| RDS | `gunnerteam-dev.c52gm8goign8.us-east-2.rds.amazonaws.com` |
| RDS Proxy | `gunnerteam-dev-api.proxy-c52gm8goign8.us-east-2.rds.amazonaws.com` |
| Assistant Lambda | Streaming Function URL (no keep-warm yet — SCP exception pending) |

**Cloudflare API token:** Personal token with IPv6 restriction — blocks `terraform plan` when on IPv6 network. Workaround: `-target` for AWS-only resources. Account-Owned token needed (open item).

---

## OMP Status (2026-06-10 current)

**Version:** 15.10.12 — [[runbooks/omp-hang-fix]] + [[runbooks/mac-tool-setup]]

### Config (`~/.omp/agent/config.yml`)
- **Theme:** `dark-gruvbox` (dark) / `light-github` (light) — Nerd Font symbols
- **Status line:** `custom` preset, `powerline` separators
- **Models:** default=sonnet-4-6:minimal, smol=sonnet-4-6:off, slow=opus-4-8:high, plan=opus-4-8:high, task=sonnet-4-6:minimal, commit=sonnet-4-6:off
- **Key flags:** autoResume, startup.quiet, async.enabled, checkpoint.enabled, rewind.enabled, search_tool_bm25.enabled, display.showTokenUsage
- **Task isolation:** rcopy
- **Memory:** enabled, 4h idle, 60-day window, 8k injection limit, 100 rollouts/startup
- **lastChangelogVersion:** 15.10.8 (suppresses changelog on startup)

### Project settings (vault-local)
- **`.omp/settings.json`** in `gunner-brain/` — pins default/smol/task to sonnet-4-6:minimal/:off/:minimal
- `.omp/` added to `.gitignore` — not committed

### MCP (`~/.omp/agent/mcp.json` — restored 2026-06-10)
- `obsidian-vault` via `/opt/homebrew/bin/mcpvault` → `gunner-brain/` vault
- `aws-core:aws-mcp` — SigV4 proxy, via plugin (not mcp.json)

### Plugins Active

**npm: NONE (all removed 2026-06-10)**
- `pi-powerline-footer` — removed; broken in 15.10.12 (legacy-pi-compat regression, issue #1215) AND installs 1GB of transitive deps (fastembed, onnxruntime, full OMP stack) that make startup hang. Do NOT reinstall until OMP upstream confirms fix. Track 15.10.13+.
- `pi-obsidian-context` — removed (terminal-mode irrelevant; covered by obsidian-vault MCP)
- **`~/.omp/plugins/node_modules/` is now empty** (was 2.2GB; OMP starts clean)
- Built-in `statusLine` config still provides full powerline — no regression.

**Marketplace (`claude-plugins-official`):**
- `security-guidance@2.0.0` — security hooks on every edit + diff review on Stop
- `aws-core@1.0.0` — AWS skills + SigV4 MCP proxy (already active in session)
- `aws-serverless@1.1.0` — Lambda, API Gateway, Step Functions, SAM/CDK skills ✨ new 2026-06-10
- `typescript-lsp@1.0.0` — TS/JS language server
- `commit-commands@0.0.0` — `/commit`, `/push`, `/pr` slash commands
- `pr-review-toolkit@0.0.0` — PR review agents
- `semgrep@0.5.3` — SAST hooks (requires `brew install semgrep` ✅ done)
- `claude-md-management@1.0.0` — `/claude-md audit` slash command
- `session-report@0.0.0` — `/session-report` HTML usage reports
- `github@0.0.0` — GitHub MCP (requires `GITHUB_PERSONAL_ACCESS_TOKEN` in `~/.zshrc`)
- `context7@0.0.0` — up-to-date library docs lookup mid-session ✨ new 2026-06-10
- `stripe@0.1.0` — Stripe dev skills ✨ new 2026-06-10

**Not installed (known broken/removed):**
- `swift-lsp` — auto-detected via Xcode; do NOT install manually (recursive cleanup crash)
- `@oh-my-pi/swarm-extension` — removed permanently (50GB RAM spike; never reinstall)
- `terraform` — removed (requires Docker + TFE_TOKEN; not useful for local Terraform workflow)
### Skills (`~/.omp/agent/skills/`)
- **claude-obsidian (10 symlinks):** autoresearch, canvas, defuddle, obsidian-bases, obsidian-markdown, save, wiki, wiki-ingest, wiki-lint, wiki-query
- Custom: `obsidian-second-brain`, `hindsight`, `discovery-mode`