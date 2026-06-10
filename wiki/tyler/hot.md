# Wiki Hot Cache

**Last Updated:** 2026-06-10 — cc-279 through cc-288 ✅

## Current State (2026-06-10)

**Repo:** `~/Dev/GunnerTeam/` | **HEAD (main):** `dec91fd` | **Lambda:** v139 live
**release/3.0.0** frozen at `74c9d2c` (App Store submission, build 8). All new work on `main`.
**OMP:** 15.10.8

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

- **`GET/PATCH /org/theme`** — `gt_org_theme` table (plain UUID PK, JSONB, no FK). Admin/manager PATCH only.
- **`GET /companycam/tasks/high-alert`** — per-user jobs with pending high-alert tasks (job summary + count).
- **Lambda v139** live (alias `live`). Body limit 20mb. `gt_customer_photos` INSERT uses `photoObj` unwrap.

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
| API Gateway | `k5h2n0rog9.execute-api.us-east-2.amazonaws.com` |
| Lambda function | `gunnerteam-dev-api`, v139 live on alias `live` |
| Provisioned concurrency | 2 containers always warm (~$22/mo) |
| Dev URL | `https://api-dev.team.gunnerroofing.com` |
| RDS | `gunnerteam-dev.c52gm8goign8.us-east-2.rds.amazonaws.com` |
| RDS Proxy | `gunnerteam-dev-api.proxy-c52gm8goign8.us-east-2.rds.amazonaws.com` |
| Assistant Lambda | Streaming Function URL (no keep-warm yet — SCP exception pending) |

**Cloudflare API token:** Personal token with IPv6 restriction — blocks `terraform plan` when on IPv6 network. Workaround: `-target` for AWS-only resources. Account-Owned token needed (open item).

---

## OMP Status (2026-06-09 current)

**Version:** 15.10.8 — [[runbooks/omp-hang-fix]] + [[runbooks/mac-tool-setup]]

### Config (`~/.omp/agent/config.yml`)
- **Theme:** `dark-gruvbox` (dark) / `light-github` (light) — Nerd Font symbols
- **Status line:** `custom` preset, `powerline` separators
- **Models:** default=sonnet-4-6:minimal, smol=sonnet-4-6:off, slow=opus-4-7:high, plan=opus-4-7:high, task=sonnet-4-6:minimal, commit=sonnet-4-6:off
- **Key flags:** autoResume, startup.quiet, async.enabled, checkpoint.enabled, display.showTokenUsage
- **Task isolation:** worktree

### Plugins Active
- `pi-obsidian-context@0.1.1` ✅
- `pi-powerline-footer` ✅ (working as of 15.10.x)
- `swift-lsp` ✅ auto-detected via Xcode — do NOT install manually (recursive cleanup crash)
- `@oh-my-pi/swarm-extension` — status unknown on 15.10.8

### Skills (`~/.omp/agent/skills/`)
- **claude-obsidian (10 symlinks):** autoresearch, canvas, defuddle, obsidian-bases, obsidian-markdown, save, wiki, wiki-ingest, wiki-lint, wiki-query
- Custom: `obsidian-second-brain`, `hindsight`, `discovery-mode`

### MCP
- `obsidian-vault` via `/opt/homebrew/bin/mcpvault` → Gunner Vault (mcp.json active)
- `aws-core:aws-mcp` — SigV4 proxy, 11 tools active
