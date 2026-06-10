---
type: session
title: '2026-05-22: cc-26/27 hero image, announcements fixes, OMP tuning, repo cleanup'
created: '2026-05-22'
updated: '2026-05-22'
tags:
  - ios
  - omp
  - gunner-ios
  - announcements
  - session
status: active
related:
  - '[[meta/omp-config-full-audit-2026-05-22]]'
  - '[[runbooks/iterm2-nerd-fonts-omp-setup]]'
  - '[[gunner/gunnerteam-api-aws-migration]]'
---

# Session 2026-05-22: cc-26/27, Announcements Fixes, OMP Tuning, Repo Cleanup

## OMP Config — Full Schema Audit

All OMP settings audited against `settings-schema.ts`. Config rebuilt at `~/.omp/agent/config.yml`. Key changes:

- **Dead key removed:** `tools.discoveryMode: all` is not a valid schema key — was silently ignored
- **Status bar** switched to `custom` preset: left = `pi/model/git/path`, right = `subagents/context_pct/cost/token_rate`
  - `hostname` removed (always tyler-MBP, zero value)
  - `session` removed — showed raw session ID + GitHub octocat glyph that broke on Nerd Fonts v3
  - `subagents` added — lights up when swarm tasks are running
  - `git` added — branch visibility across iOS/masterdb/subportal
  - `context_pct` + `cost` added
- **Theme** changed to `dark-tokyo-night` / `light-github`
- **9 new settings:** `disabledProviders: [ollama, llama.cpp, lm-studio]`, `autoResume: true`, `startup.quiet: true`, `github.enabled: true`, `secrets.enabled: true`, `task.isolation.mode: worktree`, `async.enabled: true`, `checkpoint.enabled: true`, `display.showTokenUsage: true`
- **Memory:** `threadScanLimit` raised 300 → 500

See [[meta/omp-config-full-audit-2026-05-22]] for full audit.

## Nerd Fonts v2/v3 Split — iTerm2 Font Setup

OMP status bar icons use Unicode PUA glyphs. Nerd Fonts v3 remapped many v2 code points.

- **MesloLGS NF** (Powerlevel10k patched, v2) — missing some v3 glyphs OMP uses
- **MesloLGM Nerd Font Mono** (`brew install --cask font-meslo-lg-nerd-font`, v3) — fixes OMP model icon but breaks any remaining v2 code points
- **Fix:** Primary font = `MesloLGM Nerd Font Mono`, Non-ASCII font = `Symbols Nerd Font Mono` (`brew install --cask font-symbols-only-nerd-font`)
- Session segment icon (`\uF408`, GitHub octocat) was a v2 code point — removed the segment instead of debugging the glyph

See [[runbooks/iterm2-nerd-fonts-omp-setup]].

## OMP Rule: Always Push to GitHub

Created `~/.omp/agent/rules/github-sync.md`. Rule: after every commit or batch of commits, push to remote immediately. Never leave local-only commits at end of a task.

## gunner-ios Repo Cleanup

- Added `README.md` — stack overview, routes table, branch rules, infra summary
- `.gitignore` additions: `CLAUDE.md`, `.wrangler/`, `cc-prompts/`, `cc-prompt-*.md`, `TODO.md`, `seed-vehicles.sql`, `ssm-boothook.sh`, `docs/`
- Untracked already-committed files with `git rm --cached`
- Merged and deleted 4 stale branches (`feat/color-tokens`, `feat/guided-tasks-hero-bg`, `feat/typed-tasks`, `fix/hero-image-passthrough`)

## cc-prompt-26 — Hero Image Pass-Through

**Commit:** `ef200ea` on `main`

`AsyncImage` in `GuidedTasksView` starts at `.empty` phase on push even when the image is cached — causes visible background flicker. Fix: load image once in `JobModeSelectionView` via `HeroImageLoader: ObservableObject`, pass already-loaded `UIImage` to `GuidedTasksView` as `@ObservedObject`. `GuidedTasksView` renders `Image(uiImage:)` directly — no empty phase.

Key facts:
- URL property is `job.headerImageUrl` (not `coverPhotoUrl` as spec assumed)
- `fallbackBackground` is a function taking `size: CGSize`, not a computed var
- Required `import Combine` for `@Published`
- One call site: `JobModeSelectionView` → `GuidedTasksView(job: job, heroLoader: heroLoader)`

## cc-prompt-27 — Static Hero Background

**Commit:** `e6f2989`, merged to `main` at `1537fde`

Even with the same `UIImage`, two separate `AsyncImage`/`Image` renders slide in and out during push. Fix: move background outside the `NavigationStack` that governs the push.

**Architecture finding:** `GuidedTasksView` is pushed via `NavigationLink(destination:)` inside `ContentView.NavigationStack` — a hard stop per the spec. Solution: give `JobModeSelectionView` its own inner `NavigationStack` governing only the `→ GuidedTasksView` push. Background goes in a `ZStack` outside this inner stack.

```
ZStack (JobModeSelectionView)
  ├─ heroBackground          ← static, never moves
  └─ NavigationStack (inner)
       ├─ mode selection content  ← transparent bg
       └─ GuidedTasksView         ← transparent bg, slides in/out
```

`GuidedTasksView` simplified: removed `@ObservedObject var heroLoader`, `heroBackground`, `fallbackBackground`. `HeroImageLoader` stays as `@StateObject` on `JobModeSelectionView`.

`JobModeSelectionView` changes:
- Added `@State private var navigateToGuidedTasks = false`
- "Guided Tasks" card changed from `NavigationLink` to `Button { navigateToGuidedTasks = true }`
- `.navigationDestination(isPresented: $navigateToGuidedTasks)` on inner NavigationStack
- "Manual" card `NavigationLink` stays — pushes `JobDetailView` into inner stack (correct)

## Announcements — Post Button Fix

**Commit:** `c869430`

Post button never fired — confirmed by 0 `[Post]` log messages in device console. Root cause: `.disabled(posting || title.isEmpty || messageBody.isEmpty)` with no visual feedback; button looked enabled but wasn't.

Fixes:
- `canSubmit` computed var with `.trimmingCharacters(in: .whitespacesAndNewlines)` before `.isEmpty` — whitespace-only input no longer passes
- Button fades to 30% opacity when disabled — state is now visually obvious
- Shows `ProgressView` spinner while posting
- `guard canSubmit` in button action prevents double-fire

## Announcements — UUID Decode Bug (Root Cause of Blank List)

**Commit:** `f57d855`

`gt_announcements.id` is a UUID (`gen_random_uuid()`). iOS `Announcement` model declared `let id: Int`. `JSONDecoder` fails silently on every UUID string → `guard let resp = try? JSONDecoder().decode(...)` evaluates nil → `loadAnnouncements()` hits early return → `announcements` is never populated → blank list always.

Same bug existed in `ContentView.fetchLatestAnnouncementId()` which cast `id` to `Int` for the unread badge.

Fixes:
- `Announcement.id: String`
- `deleteAnnouncement(id: String)`
- `hasUnread` badge switched from `Int` comparison to ISO8601 `created_at` string comparison (lexicographic sort is correct for these timestamps)
- `@AppStorage` key changed from `lastSeenAnnouncementId` (Int) to `lastSeenAnnouncementAt` (String)

## Latent Bug Rule: gt_ Tables Use UUID PKs

**All `gt_` tables use `gen_random_uuid()` for their primary key — always `String` on the Swift side.** If a feature is broken and API calls look correct, check `id` type first.

Verified: all remaining `let id:` declarations in the codebase are already `String`. No other instances of this bug.

## Commits This Session (main)

| Commit | Description |
|---|---|
| `ef200ea` | fix(ios): pass hero UIImage through to GuidedTasksView — no re-fetch on push |
| `c869430` | fix(ios): Post button — visible disabled state, trim whitespace, guard re-entrancy |
| `f57d855` | fix(ios): announcement id Int→String (UUID), timestamp-based unread badge |
| `e6f2989` | fix(ios): hoist hero background outside inner NavigationStack (on branch, merged) |
| `1537fde` | Merge fix/static-hero-background |
| `17b8332` | chore: ignore docs/ directory |
| Various | chore: README, gitignore cleanup, branch deletes |
