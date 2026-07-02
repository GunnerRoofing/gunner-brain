---
type: session
title: GunnerTeam Session Handoff — 2026-05-22 EOD
created: '2026-05-22'
updated: '2026-05-22'
tags:
  - gunnerteam
  - ios
  - swift
  - lambda
  - session
  - handoff
status: evergreen
related:
  - '[[gunnerteam/gunner-forms-app]]'
  - '[[tyler/gunnerteam/gunnerteam-api-aws-migration]]'
  - '[[tyler/gunnerteam/gunnerteam-project-structure]]'
  - '[[meta/session-2026-05-22-cognito-auth-api-ios]]'
---

# GunnerTeam Session Handoff — 2026-05-22 EOD

End-of-day context snapshot. Overrides noted where our live session diverges from the original doc.

---

## Corrected Operational Facts

| Item | Doc said | Actual (our session) |
|---|---|---|
| Repo path | `~/Documents/GunnerTeam/` | `~/Documents/Gunner/GunnerTeam/` |
| Lambda deploy path | `~/Documents/GunnerTeam/gunnerteam-api` | `~/Documents/Gunner/GunnerTeam/gunnerteam-api` |
| Lambda version | v65 | **v68** |
| Migration entries | 36 | **37** (device_name DROP NOT NULL added) |
| Auth: POST /auth/login | `username` field, returns token | **410 Gone** — iOS uses Amplify SRP → Cognito → POST /auth/validate |
| Next cc-prompt | 27 (bottom of doc) | **30** (top of doc is correct; bottom was pre-session stale) |
| Xcode scheme | `GunnerForms` | **`GunnerTeam`** |

---

## Lambda Deploy Command (corrected path)

```bash
cd ~/Documents/Gunner/GunnerTeam/gunnerteam-api
zip -r /tmp/gt-deploy.zip . --exclude "*.git*" --exclude "node_modules/aws-sdk/*"
AWS_PROFILE=mfa aws lambda update-function-code \
  --function-name gunnerteam-dev-api \
  --zip-file fileb:///tmp/gt-deploy.zip \
  --region us-east-2
AWS_PROFILE=mfa aws lambda wait function-updated \
  --function-name gunnerteam-dev-api --region us-east-2
# Then publish + update alias:
NEW=$(AWS_PROFILE=mfa aws lambda publish-version --function-name gunnerteam-dev-api --region us-east-2 --query 'Version' --output text)
AWS_PROFILE=mfa aws lambda update-alias --function-name gunnerteam-dev-api --name live --function-version $NEW --region us-east-2
```

## iOS Build Command (corrected scheme)

```bash
xcodebuild -scheme GunnerTeam \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "error:|BUILD" | tail -20
```

---

## Current Main Branch Features (2026-05-22 EOD)

| Feature | Notes |
|---|---|
| Jobs list → JobModeSelectionView | Hero bg, blurred cover photo, job info overlay |
| GuidedTasksView | Hero bg, progress bar, task list, optimistic update, toast |
| Typed tasks | checkbox, text, photo_single, photo_multi (step grid) |
| photo_multi step grid | 3-col LazyVGrid, VehicleCameraPicker per tile, presign→S3→confirm |
| HeroImageLoader | Fetches cover photo once, passed as @StateObject → @ObservedObject |
| Color tokens | 8 colorsets in Assets.xcassets/Colors/ — never use raw hex |
| Voice Comment | SFSpeechRecognizer, AVAudioEngine tap, `shouldReportPartialResults=true` |
| Colin v2 API | GunnerTask has `completedAt: String?` and `completedByEmail: String?` |
| Cognito auth | Amplify SRP → ID token → POST /auth/validate |

---

## ⚠️ Known Regression — Fix First

**cc-prompt-27 broke navigation.** Tapping "Guided Tasks" slides wrong direction to white screen.

```bash
cd ~/Documents/Gunner/GunnerTeam
git log --oneline -5
# Find the "static hero background" or "hoist background" commit
git revert <that-commit-hash> --no-edit
```

Verify: Tap job → JobModeSelectionView (hero bg) → Tap "Guided Tasks" → GuidedTasksView pushes left → back returns correctly.

**Do NOT retry "hoist background outside NavigationStack".** If background animation polish needed later: use `matchedGeometryEffect`.

---

## iOS Patterns (canonical)

### Color tokens
Use semantic tokens only — **never raw hex or `Color.green`/`Color.blue`**.
Tokens: `Color.appPrimary`, `Color.appSuccess`, `Color.appSuccessMuted`, `Color.appWarning`, `Color.appWarningMuted`, `Color.appDestructive`, `Color.appSecondary`, `Color.appPrimaryMuted`.
Live in `Assets.xcassets/Colors/`. Xcode 16 auto-generates `Color.app*` from colorset names via `GeneratedAssetSymbols.swift` — **do NOT add a manual `extension Color { static let appPrimary = ... }`** (causes redeclaration error). `Theme/AppColors.swift` is documentation only.

### Nav bar on hero-background screens
```swift
.toolbar(.hidden, for: .navigationBar)
.navigationBarBackButtonHidden(true)
// Custom back button overlay:
// chevron.left, 36×36, .ultraThinMaterial Circle
// .padding(.leading, 20).padding(.top, 8)
// @Environment(\.dismiss) private var dismiss
```
**Do NOT use `UINavigationBar.appearance()` in `init()`** — SwiftUI morphs bars during push animation before any modifier runs.

### HeroImageLoader handoff
Parent view owns as `@StateObject`. Pushed view receives as `@ObservedObject`. Prevents AsyncImage re-fetch on push.

### UUID primary keys
All `gt_` table PKs are `gen_random_uuid()` → always `id: String` in Swift Codable structs. `Int` only for legacy non-`gt_` tables or external APIs (CompanyCam). No remaining `id: Int` in codebase.

### gt_ INSERT pattern
Always pass `id (gen_random_uuid())`, `created_at (NOW())`, `updated_at (NOW())` explicitly. Never rely on column DEFAULT alone. `user_devices` is NOT a `gt_` table but same rule applies.

---

## Colin's External API

Base: `https://project.dev.gunnerroofing.com/api/external/v1`
Auth: `Authorization: Bearer <COMPANYCAM_API_KEY from SSM>`

| Endpoint | Notes |
|---|---|
| `GET /projects/:id/tasks` | task list with type/required/steps |
| `PATCH /projects/:id/tasks/:taskId` | `{status, userEmail, notes}` |

Status values: `"complete"` or `"pending"` — NOT "done"/"open".

Task types: `checkbox`, `photo_single`, `photo_multi`, `text`.
- `photo_multi` returns `steps: [{id, label, order, required}]`
- Others return `steps: null`
- Photos: presign → S3 PUT → confirm → PATCH parent task complete (no per-step server state)
- `userEmail` in PATCH attributes completion; `completedByEmail` in response

**Test project:** `40fcbc6f-a5d8-4a3f-99e0-af5e38b8f0d9` (all 4 types seeded)

---

## Branches

| Branch | Purpose |
|---|---|
| `main` | Active development |
| `forms-quick-fix-2026-05` | **NEVER TOUCH** — maintenance branch for shipped forms-only iOS build |

---

## APNs Token Store Divergence (open issue)

Two separate token stores:
- `companycam.js` reads `users.device_token` (legacy column)
- `announcements.js` reads `user_devices` table

CompanyCam webhook pushes will miss devices until these are unified. Tracked as open backlog item.

---

## Open Backlog (priority order)

1. **cc-prompt-27 nav revert** — blocks everything else
2. **cc-prompt-28 audit** — `/Users/tyler.suffern/Documents/Claude/Projects/Gunner Team App/cc-prompt-28-backlog-audit.md`
3. **On-device typed task checklist** — Colin test project `40fcbc6f...`
4. **APNs smoke test** — post announcement, watch CloudWatch for `[APNs]` lines
5. **Run `/auth/run-migrations`** with Cognito token
6. **Xcode: `amplifyconfiguration.json` target membership** confirmation
7. **APNs token store unification** — companycam.js + announcements.js reading different tables
8. **Manage Users not loading** — UUID vs Int or RLS issue (open since 2026-05-20)
9. **Project comment webhook** — `project.comment.added` handler missing; confirm HMAC secret with Colin first
10. **Legacy photo URLs** — `UPDATE gt_vehicle_inspections SET photo_urls = regexp_replace(...)` dead EC2 IP
11. **resolveUser DB cache** — 6-table JOIN per request, 5-min in-memory cache
12. **RDS Proxy pinning** — `SET LOCAL` RLS forces connection pinning; investigate if slowness persists
13. **masterdb postgres password rotation** — BLOCKING FOR PROD
14. **CompanyCam secrets rotation** — API key + webhook secrets shared in plain text in chat
15. **SCP exception for streaming /assistant** — pending Eddie
16. **invite/register HS256 migration** — deferred (SOC 2 #33)
17. **subportal cc-prompt-03** (S3 import pipeline)

---

## Key Identifiers

| Resource | Value |
|---|---|
| Cognito pool (shared) | `us-east-2_hFVBSrcnn` — GunnerTeam + subportal share this. Do not create a second pool. |
| GunnerTeam Cognito client | `6m41qei5jq3nt46jler56im1cg` |
| Subportal Cognito client | `79b78sb33ef3php9evd7jlctui` |
| Gunner tenant UUID | `69aad261-347c-44db-8e9e-6c25a8509aa3` |
| Tyler masterdb UUID | `3e3f0491-b16f-42cd-9437-028a4a3ad771` |
| Colin test project UUID | `40fcbc6f-a5d8-4a3f-99e0-af5e38b8f0d9` |
| Lambda | `gunnerteam-dev-api` v68, alias `live` |
| AWS account | `980921733684` |
| AWS region | `us-east-2` |
| cc-prompt dir | `/Users/tyler.suffern/Documents/Claude/Projects/Gunner Team App/` |
| Next cc-prompt | **30** |
