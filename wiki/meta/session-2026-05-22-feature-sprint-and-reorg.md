---
type: session
title: 'Session: Feature Sprint + Folder Reorg (2026-05-22)'
created: '2026-05-22'
updated: '2026-05-22'
tags:
  - session
  - ios
  - gunnerteam
  - subportal
  - react
  - swift
  - refactor
  - devops
status: developing
related:
  - '[[gunner/gunnerteam-api-aws-migration]]'
  - '[[gunner/aws-environment]]'
  - '[[gunner/subportal-cc-prompt-02-frontend]]'
  - '[[gunner/environment]]'
---
# Session: Feature Sprint + Folder Reorg (2026-05-22)

Five work items completed in this session across iOS, backend, frontend, and infrastructure.

---

## 1. cc-prompt-21 — Guided Tasks: Typed Task Support

**Branch:** `feat/typed-tasks`  
**Files:** `GuidedTasksView.swift`, `gunnerteam-api/src/routes/companycam.js`

### What changed

`GunnerTaskType` expanded from `checkbox/photo/form/unknown` to the full Colin API v2 type set:

| Type | Behavior |
|---|---|
| `checkbox` | Tap → immediate PATCH complete |
| `text` (+ legacy `form`) | Opens `FormTaskSheet` → PATCH with notes |
| `photo_single` (+ legacy `photo`) | `VehicleCameraPicker` fullScreenCover → presign/S3/confirm upload → PATCH |
| `photo_multi` | `MultiStepPhotoCaptureView` sheet → per-step camera → per-step upload → PATCH when required steps done |
| `unknown` | No-op, no crash |

`GunnerTaskStep` model added: `id`, `label`, `order`, `required` — all content from API, nothing hardcoded.

### Upload pattern
`uploadTaskPhoto()` uses presign → S3 PUT → confirm (3-step), matching `CompanyCamViews.swift`. NOT direct multipart POST. `PresignResponse` struct from `CompanyCamViews.swift` is in scope (same module, file system sync group).

### Camera reuse
`VehicleCameraPicker` (AVFoundation / UIImagePickerController wrapper from `VehicleInspectionView.swift`) reused for both `photo_single` and each step in `photo_multi`. No second camera implementation.

### `MultiStepPhotoCaptureView`
- 3-column step grid matching vehicle inspection layout
- Per-step spinner during upload, checkmark on success, toast on failure (retappable — no stuck states)
- "Complete Task" button activates when all `required` steps done; "Skip remaining" available if any step done
- `stepCaptured: [String: Data]` binding tracks local capture state by step ID

### Backend: `userEmail` added to PATCH
```js
body: JSON.stringify({ status, notes: notes || null, userEmail: req.user.email })
```
`req.user.email` from JWT via `requireAuth`. No iOS change needed — backend extracts it.

### Backward compat
Legacy type names (`photo`, `form`) remain as enum cases mapping to `photoSingle`/`text` code paths. Existing tasks (before Colin API v2) continue working.

---

## 2. cc-prompt-22 — GuidedTasksView: Hero Background Photo

**Branch:** `feat/guided-tasks-hero-bg`  
**Files:** `GuidedTasksView.swift` only

`GuidedTasksView` gets the same blurred/dark hero photo treatment as `JobModeSelectionView`:
- `ZStack` wraps entire body; `heroBackground` + `fallbackBackground` copied verbatim from `JobModeSelectionView`
- `.toolbar(.hidden)` + custom back button overlay (8pt top padding, `ultraThinMaterial` circle, `dismiss()`)
- Progress header → `.ultraThinMaterial`; task row backgrounds → `.ultraThinMaterial`
- All text colors updated to white/white.opacity variants for readability over dark background
- Loading/empty states updated to white text
- Toast → `.ultraThinMaterial`
- `JobDetailView` (Manual mode) untouched

---

## 3. cc-prompt-23 — App-wide Color Tokens (White-label Foundation)

**Branch:** `feat/color-tokens`  
**Files:** `Assets.xcassets/Colors/` (8 new colorsets), `Theme/AppColors.swift`, 18 Swift files

### Token set

| Asset name | Gunner value | Semantic meaning |
|---|---|---|
| `AppPrimary` | `#1B538F` | Main brand color |
| `AppPrimaryMuted` | same @ 12% alpha | Tinted bg behind primary elements |
| `AppSuccess` | `#059669` | Completion / pass states |
| `AppSuccessMuted` | same @ 12% alpha | Bg behind success indicators |
| `AppWarning` | `#F59E0B` | Required badges / caution |
| `AppWarningMuted` | same @ 15% alpha | Bg behind warning badges |
| `AppDestructive` | `#DD141E` | Delete / error / expired |
| `AppSecondary` | `#059669` | Secondary action buttons |

`AccentColor` updated to match `AppPrimary` so system controls (Toggle, Slider) stay consistent.

### Key implementation note
**Xcode 16 `PBXFileSystemSynchronizedRootGroup`** auto-generates `Color.appPrimary` etc. via `GeneratedAssetSymbols.swift` from colorset names. A manual `extension Color { static let appPrimary = ... }` causes a redeclaration error. `Theme/AppColors.swift` is documentation only — no property declarations.

### Color consolidations
- `#0284C7` (CompanyCamViews action buttons) → `AppPrimary` (same semantic slot as `#1B538F`)
- `#DC2626` → `AppDestructive` (same slot as `#DD141E`)
- `#D97706` → `AppWarning` (same slot as `#F59E0B`)

### Not tokenized
`#7C3AED` — Gunner Assistant card purple. Used in `GunnerAssistantView` + `ContentView` home cards only. Doesn't fit any of the 8 semantic slots. Documented in `AppColors.swift`. Create `AppAssistant` colorset when a second vendor needs a different AI feature color.

### White-label workflow
To rebrand for a vendor: swap 8 JSON files in `Assets.xcassets/Colors/`. Zero Swift code changes.

---

## 4. cc-prompt-02 — Subcontractor Portal Frontend Scaffold

**Repo:** `~/Documents/Gunner/subportal/`  
**Stack:** React 18 + Vite 5 + TypeScript 5 + React Router v6 + Tailwind CSS v3 + shadcn/ui + MSW v2

### Auth: GunnerTeam HS256 JWT (not Cognito)
- `POST /auth/login` → token stored in `sessionStorage` (clears on tab close)
- `tenantId` extracted from JWT claims only — never from request body
- Cognito migration: swap `AuthContext.login()` for `Amplify.signIn()` — zero component changes

### Key security patterns
- `SubSearchResult` type excludes contact info (email/phone/address)
- `revealContact()` is a separate API call, intentionally not cached — each open is audit-logged (CC6.2, CC7.2)
- Result count shown, total DB count never exposed
- All colors via CSS custom properties (`--brand-primary`, `--brand-accent`, `--brand-logo-url`)

### MSW setup
Mocks `/auth/login`, `/subcontractors/search`, `/subcontractors/:id/contact`. Active only in `import.meta.env.DEV`. `npm run dev` → full UI without AWS.

### shadcn init issues (documented for future reference)
- `shadcn@latest` v4.8.0 doesn't accept `--yes` to suppress preset selection; `components.json` must be created manually
- Tailwind v4 installs by default — explicitly pin with `tailwindcss@3`
- `class-variance-authority`, `lucide-react`, and radix-ui packages are peer deps that `npx shadcn add` lists in component files but doesn't auto-install
- `baseUrl` in `tsconfig.json` deprecated in TS 5.x; use `ignoreDeprecations: "5.0"` in `tsconfig.app.json`

---

## 5. Folder Reorganization

`~/Documents/GunnerTeam/` moved to `~/Documents/Gunner/GunnerTeam/`.

Both projects now under `~/Documents/Gunner/`:
```
~/Documents/Gunner/
├── GunnerTeam/          ← iOS app (GunnerForms) + Express API + Terraform
└── subportal/           ← Subcontractor portal (backend/ + frontend/)
```

### Files updated
| File | Change |
|---|---|
| `.claude/settings.local.json` | 6 allowlist entries with absolute paths updated |
| `.claude/context/long-term/architecture.md` | terraform cd path updated |
| `wiki/gunner/gunnerteam-api-aws-migration.md` | Path references updated |
| `wiki/gunner/aws-environment.md` | Path references updated |
| `wiki/gunner/claude-session-onboarding.md` | New project roots + subportal added |
| `Xcode DerivedData` | Cleared — cold rebuild on next open |
| `gunnerteam-api/node_modules` | Refreshed |
| `terraform/.terraform/` | Re-initialized after MFA refresh |

### `.jsonl` conversation history
`~/.claude/projects/*/` JSONL files contain old paths in file-history snapshots — read-only audit logs, never used as runtime references. Left as-is.

---

## Open PRs After This Session

| Branch | Feature | Merge notes |
|---|---|---|
| `feat/typed-tasks` | cc-21: typed task support | Independent |
| `feat/guided-tasks-hero-bg` | cc-22: hero background | Conflicts with cc-21 on `GuidedTasksView` body — mechanical merge |
| `feat/color-tokens` | cc-23: color tokens | Independent of cc-21/cc-22 |

Merge order recommendation: `feat/color-tokens` first (independent), then `feat/typed-tasks`, then `feat/guided-tasks-hero-bg` (resolve conflict: cc-22 adds ZStack/hero, cc-21 adds state vars and sheets — both changes belong in final result).

## Remaining Action Items
- Deploy Lambda for `userEmail` PATCH change (one-line backend, `feat/typed-tasks`)
- Send Colin tasks API spec v2 (type/steps/required fields)
- `terraform apply` after merging any Lambda changes
- Enroll MFA for `tyler-cli` IAM user (runbook: `wiki/runbooks/aws-iam-least-privilege.md`)
