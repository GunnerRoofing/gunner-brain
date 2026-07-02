---
type: session
title: 2026-05-22 iOS Fixes + Repo Cleanup + Cognito Auth
created: '2026-05-22'
updated: '2026-05-22'
status: stable
tags:
  - ios
  - swift
  - gunner-ios
  - subportal
  - cognito
  - session
related:
  - '[[tyler/gunnerteam/gunnerteam-api-aws-migration]]'
  - '[[tyler/gunnerteam/subportal-cognito-auth]]'
  - '[[meta/omp-config-full-audit-2026-05-22]]'
---

# 2026-05-22 — iOS Fixes + Repo Cleanup + Cognito Auth

Afternoon session covering three iOS cc-prompts, gunner-ios repo cleanup, and completing the subportal Cognito auth migration.

---

## iOS: cc-prompt-26 — Hero image pass-through

**Problem:** `JobModeSelectionView` and `GuidedTasksView` both had independent `AsyncImage` calls. On navigation push, the new view started in `.empty` phase and transitioned to `.success`, causing the background to visibly reload even when the image was cached.

**Fix:** `HeroImageLoader` (`ObservableObject`) fetches the image once in `JobModeSelectionView` (`@StateObject`) and passes the loaded `UIImage` to `GuidedTasksView` (`@ObservedObject`). `GuidedTasksView` renders `Image(uiImage:)` directly — no `AsyncImage`, no empty phase, no flicker.

Key facts:
- URL property is `job.headerImageUrl` (not `coverPhotoUrl`)
- `fallbackBackground` is a function taking `size: CGSize`, not a computed var
- `HeroImageLoader` uses `URLSession` which hits `URLCache` by default — disk cache on repeat loads
- `import Combine` required for `@Published`

Commit: `ef200ea` — `fix(ios): pass hero UIImage through to GuidedTasksView — no re-fetch on push`

---

## iOS: cc-prompt-27 — Static hero background

**Problem:** Even with the same `UIImage` passed through, the background still animated on push because it was inside the `NavigationStack`. SwiftUI slides the entire destination view in — background included.

**Hard stop hit:** `GuidedTasksView` was pushed via `NavigationLink(destination:)`, not `navigationDestination`. The spec flagged this as a hard stop for path-tracking.

**Fix:** `JobModeSelectionView` gets its own inner `NavigationStack` governing only the `→ GuidedTasksView` push. The background sits outside this inner NavigationStack in a `ZStack`. Only the content slides; the background is a static layer that never participates in push animations.

```
ZStack (in JobModeSelectionView)
  ├─ heroBackground          ← static, outside NavigationStack
  └─ NavigationStack
       ├─ mode selection cards  ← slides out on push
       └─ GuidedTasksView       ← slides in on push
```

`GuidedTasksView` no longer accepts `heroLoader` — background is entirely owned by `JobModeSelectionView`. `@StateObject private var heroLoader` stays in `JobModeSelectionView`.

Branch: `fix/static-hero-background` (pushed, not yet merged to main)

---

## iOS: Announcements bug — UUID id type mismatch

**Root cause:** `gt_announcements.id` is a UUID (`gen_random_uuid()`), but `Announcement.id` was declared `Int`. `JSONDecoder` silently failed on every UUID string via `try?`, so `announcements` was never populated and the list never showed anything after posting.

**Fix:**
- `Announcement.id: String` (was `Int`)
- `deleteAnnouncement(id: String)` (was `Int`)
- Unread badge tracking switched from integer `max(id)` comparison to ISO8601 `created_at` string comparison (lexicographically sortable, correct for "newer than" logic)
- `@AppStorage` key changed from `"lastSeenAnnouncementId"` (Int) to `"lastSeenAnnouncementAt"` (String)

Both `AnnouncementsView.swift` and `ContentView.swift` updated. Cascading: `ContentView.fetchLatestAnnouncementId()` was also casting `id` to `Int` and silently failing.

**Bonus fix:** Post button disabled state was invisible (hardcoded `appPrimary` color regardless). Added `canSubmit` computed var with whitespace trimming, opacity fade when disabled, spinner while posting.

Commit: `f57d855` — `fix(ios): announcement id Int->String (UUID), timestamp-based unread badge`

---

## gunner-ios repo cleanup

- **README.md** created — covers iOS app, API routes, infrastructure, DB conventions, secrets rule
- **Gitignored and untracked** from git: `CLAUDE.md`, `TODO.md`, `cc-prompts/`, `cc-prompt-*.md`, `seed-vehicles.sql`, `ssm-boothook.sh`, `.wrangler/`
- **Merged into main:** `fix/hero-image-passthrough` (cc-26), and three previously-merged `feat/` branches cleaned up
- **Branch `fix/static-hero-background`** pushed but not merged (on-device verification pending)

Public-facing repo now contains only: `GunnerForms/`, `gunnerteam-api/`, `terraform/`, `.gitignore`, `README.md`, `schema-postgres.sql`

---

## OMP config audit

Full schema audit of `~/.omp/agent/config.yml` against `settings-schema.ts`. See [[meta/omp-config-full-audit-2026-05-22]] for full details.

Key additions beyond initial tuning: `disabledProviders` (ollama/llama.cpp/lm-studio), `autoResume`, `startup.quiet`, `github.enabled`, `secrets.enabled`, `task.isolation.mode: worktree`, `async.enabled`, `checkpoint.enabled`, `display.showTokenUsage`, `memories.threadScanLimit: 500`.

Status bar redesigned: left = pi/model/git/path, right = subagents/context_pct/cost/token_rate. Theme changed to `dark-tokyo-night`.

**Nerd Fonts v2/v3 split:** `MesloLGM Nerd Font Mono` (brew `font-meslo-lg-nerd-font`) is v3. Session segment used a v2 octocat glyph that breaks on v3 fonts. Removed session segment; replaced with `subagents`. See [[runbooks/iterm2-nerd-fonts-omp-setup]].

---

## Subportal: Cognito auth (cc-prompt-04)

Full implementation details in [[tyler/gunnerteam/subportal-cognito-auth]].

Summary: HS256 JWT replaced with Cognito SRP. Pool `us-east-2_hFVBSrcnn` live. Tyler's user created (`CONFIRMED`). Smoke test passed — login works, Cognito ID token visible in Authorization header on API calls.

Blockers encountered and resolved:
- SST 4 requires `uv` — installed via `curl -LsSf https://astral.sh/uv/install.sh | sh`
- `pyproject.toml` needed `[project]` section for uv workspace
- `AWS_REGION` is a reserved Lambda env var — removed from SST function config
- `VITE_API_URL` must be empty for local dev (MSW uses relative paths)
