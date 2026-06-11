---
type: session
title: "cc-299–338: GunnerCam Perf Sprint, Color Tokens, Prod Infra, UX Polish"
created: 2026-06-11
updated: 2026-06-11
tags:
  - gunnerteam
  - ios
  - backend
  - infra
  - performance
  - accessibility
status: complete
related:
  - "[[tyler/hot.md]]"
  - "[[gunnerteam/aws-environment.md]]"
  - "[[gunnerteam/gunnerteam-project-structure.md]]"
---

# cc-299–338: GunnerCam Perf Sprint, Color Tokens, Prod Infra, UX Polish

**Session date:** 2026-06-11  
**Lambda at session end:** v156 live  
**iOS:** BUILD SUCCEEDED throughout  

Large sprint covering ~40 cc-prompts across iOS, backend, and AWS infra.

---

## Performance (GunnerCam Perf Handoff §2–3)

### iOS Incremental Sync (cc-320, cc-321, cc-324, cc-326)
- **cc-320:** ETag support on `GET /jobs` — `sendWithETag` helper, `304` short-circuit
- **cc-321 (backend):** `modified_since` pass-through on `GET /jobs` and `GET /jobs/:id/tasks`; `cleanModifiedSince` validator strips unvalidated client input
- **cc-324 (iOS):** `JobsView` incremental sync — `@AppStorage` ETag + timestamp, `load(forceFull:)` with `304` early return, delta-merge by id, pull-to-refresh forces full
- **cc-326 (iOS):** Cursor-based photo pagination — `CCPhotosPage` decode type, `photos` promoted to `@State`, `loadMorePhotos()` appends on last-cell `.onAppear`, footer spinner while paging

### Image Cache (cc-323)
- `PhotoImageCache` actor: NSCache (memory) + disk (`Caches/photo-cache/`), keyed by stable photo `id` — never by presigned URL
- `CachedAsyncImage<Placeholder>`: drop-in for `AsyncImage`, `.task(id: id)` reloads only on id change
- All `AsyncImage` calls in `JobDetailView`, `JobSectionViews`, `JobModeSelectionView`, `GuidedJobRow`, `JobGuidedView`, `PhaseDetailView`, and `ContentView` routed through `CachedAsyncImage`
- `HeroImageLoader.load(urlString:)` → `load(id:urlString:)` using `PhotoImageCache`

### scenePhase Foreground Catch-Up (cc-325)
- `GunnerFormsApp` broadcasts `.appDidBecomeActive` on `scenePhase == .active`
- `JobsView` subscribes via `.onReceive`, fires one incremental poll when `jobs` is non-empty (cold start handled by `onAppear`)
- `fetchTask` stored so backgrounding cancels in-flight requests

### Backend N+1 Elimination (cc-327)
- `GET /tasks/high-alert` replaced 1+N fan-out with single `GET /tasks/high-alert?userEmail=` upstream call
- `tagCustomerPhotos` factored into shared helper (eliminates duplicate `customerIds` logic)
- `GET /jobs/:id` capped photo sub-fetch to `?limit=100`, returns `nextCursor` and true `photoCount` from upstream

---

## Prod Infrastructure (cc-328–331)

### S3 + Lambda Env (cc-328)
- `gunner-fleet-prod` S3 bucket created: private, SSE-S3, all public access blocked
- Lambda `S3_BUCKET` and `AWS_S3_BUCKET` env vars updated to `gunner-fleet-prod` → v150

### Prod Aurora Seed (cc-329, cc-331)
- Full dev schema + data seeded to prod Aurora via `_stmts` Lambda runner pattern (temporarily pointed `$LATEST` at prod, invoked SQL batches, restored to dev before publishing)
- **Key obstacle:** prod Aurora in private subnet (no public route) — `pg_restore` direct path impossible; Lambda VPC access was the only viable path
- All 9 Lambda migrations ran against prod (0 errors)
- cc-331 followed up with 17 missing tables (`gt_user_profile`, `gt_announcements`, `audit_log`, `invite_tokens`, `user_devices`, `crew_members`, etc.) via second seed pass
- `auditaction` enum type and `invite_tokens.expires_at` column added manually before re-seed
- `_stmts` handler removed from production code after each use; never published to `live` alias

### Lambda at Prod DB (cc-330)
- v152 published pointing `live` at prod Aurora
- Warm invoke confirmed clean (no DB connection errors)
- `gunnermediabucket` public access blocked (media/PDF bucket, content private-only)

---

## Color Token Migration (cc-307, cc-308)

### New Colorsets (cc-307)
- `AppBackground.colorset`: #F2F3F7 light / #0F1117 dark
- `AppSurface.colorset`: #FFFFFF light / #1A1D27 dark
- Xcode auto-generates `Color.appBackground` / `Color.appSurface` from asset names — do NOT add manual extensions
- All palette computed vars (`bgPrimary`, `bgCard`, `primaryText`, `secondaryText`, `divider`) removed from 18+ files across 24+ structs
- Replacement map: `bgPrimary→Color.appBackground`, `bgCard→Color.appSurface`, `primaryText→.primary`, `secondaryText→.secondary`, `divider→Color(.separator)`
- `SheetBackground` and `SheetCardModifier` in `SheetStyle.swift` updated to use tokens; `@Environment(\.colorScheme)` removed from both

### Inline Color Mop-Up (cc-308)
- `LinearGradient([#2B2F36, #0F1117])` → `[Color.appSurface, Color.appBackground]` (10 hits across Jobs files)
- `#2A2E37` → `Color.appSurface` (JobGuidedView, 2 hits)
- Dark/light ternary fills `(#1A1D27/#E5E7EB)` → `Color(.systemGray5)` (5 hits)
- Dark/light ternary fills `(#1A1D27/#2D2D2D)` → `Color.appSurface` (4 hits)
- `#78350F` warning → `Color.appWarning` (PhaseItemSheets)
- `bgInput` in SettingsView, `inputBg` in GunnerAssistantView, `cardColor` in TaskSheetsView all collapsed to token
- Unused `@Environment(\.colorScheme)` removed from 10+ structs post-cleanup

---

## iOS UX + Accessibility (cc-299, cc-300, cc-301, cc-303, cc-305, cc-309, cc-331, cc-332, cc-333, cc-334)

### Pull-to-Refresh (cc-299)
- `.refreshable` added to `JobListView` (via existing `onRefresh` closure), `JobGuidedView` (calls `refreshPhases()`), `VehicleInspectionHubView` (parallel `refresh()` combining 3 loads), `InspectionReportsView`

### Toast Consolidation (cc-300)
- `ToastModifier` in `App/ToastModifier.swift` — `.toast(message:)` extension replaces 5 identical inline overlay blocks
- `showToast()` helper added to `ContentView`

### Haptics (cc-301)
- `GuidedTasksView`: `.success` before each `completeTask` call site (5), `.medium` before each `uncompleteTask` (2)
- `AnnouncementsView`: `.warning` before `deleteAnnouncement`
- `CCCommentsView`: `.medium` at top of `sendComment()`/`send()`, `.warning` before `deleteComment()`

### CachedAsyncImage in PhaseDetailView (cc-303)
- All 3 `AsyncImage` calls replaced: task item thumbnail (`item.photos.first?.id`), lightbox tab view (`photo.id`), signature display (`photo.id`)

### Accessibility (cc-305)
- `.frame(width:44,height:44).contentShape(Rectangle()).accessibilityLabel("Back")` on all 12 chevron.left back buttons across Jobs, Forms, Fleet
- `.accessibilityLabel("Close")` + 44pt targets on xmark buttons in InspectionReportsView and NotificationsView
- `LoginView`: `.submitLabel(.next).onSubmit { passwordFocusTrigger += 1 }` on email field (uses existing `StablePasswordField` trigger pattern)
- `SettingsView InviteFormInline`: `InviteField` enum + `@FocusState`, firstName→lastName→email chain

### Password Flicker Fix (cc-309)
- Root cause: `updateUIView` called `uiView.textColor = textColor` on every keystroke using new `UIColor` instance, disturbing the QuickType bar
- Fix: `textColor` parameter removed; `UIColor { traits in }` dynamic provider set once in `makeUIView`; `becomeFirstResponder` guarded with `isFirstResponder`

### Menu Contrast Fix (cc-331)
- `createTaskMenuRow` and `JobDropdownMenu.dropdownRow`: `.white` → `.primary` (was invisible in light mode)
- `presentationBackground` updated to closure form `{ Color.appSurface }` for correct trait resolution

### Empty States + loadError (cc-302, cc-332)
- `loadError: String?` + retry UI added to: `JobDetailView` (`loadDetail()`), `PhaseDetailView` (`loadSections()`), `InspectionReportsListView`, `VehicleInspectionReviewView`, both `VehicleListViews` structs, `CCCommentsView`
- Icon upgrades: `square.3.layers.3d.slash` (JobGuidedView phases empty), `doc.text.magnifyingglass` (InspectionReportsView), `person.2.slash` (TeamSchedulesView), `bubble.left.and.bubble.right` (CCCommentsView empty)

### Dynamic Type (cc-333)
- High-alert banner job name: `.system(size:14)` → `.footnote.weight(.semibold)`, `lineLimit(1)` → `lineLimit(2)`, `.minimumScaleFactor(0.85)`
- GuidedTasksView hero title: `lineLimit(1)` → `lineLimit(2)`, added `.minimumScaleFactor(0.85)`

### Keyboard (cc-334)
- `VehicleInspectionView`: `InspectionFocus` enum + `@FocusState`, plate `.next→mileage`, mileage `.done`, damage/notes `.focused`, `.scrollDismissesKeyboard(.interactively)`, keyboard Done toolbar
- `.scrollDismissesKeyboard` added to: ITRequestView, APFormView, ChangeOrderView, VehicleInspectionReviewView, TaskSheetsView (7 ScrollViews), VehicleInspectionView
- `TaskSheetsView`: `CreateTaskFocus`, `CreatePhotoTaskFocus`, `QuickTextFocus` enums with full chains
- `AnnouncementsView ComposeAnnouncementView`: `ComposeFocus { title, body }` chain
- `.submitLabel` sweep: VehicleDocumentViews, VehicleListViews, VehicleMaintenanceViews, APFormView, ChangeOrderView, ITRequestView (with `ITField` @FocusState chain), JobListView search, PDFChangeOrderView (2 chains)

---

## Backend Features (cc-335, cc-336, cc-337, cc-338)

### Announcement Reads (cc-335)
- Migration `20260611_announcement_reads`: `priority VARCHAR(10)` on `gt_announcements`; `gt_announcement_reads` table (upsert-safe FK to VARCHAR announcement id)
- `GET /announcements` LEFT JOIN `gt_announcement_reads` — returns `priority` + `is_read` per user
- `POST /announcements` accepts `priority` field (validated: `normal|urgent`)
- `POST /announcements/:id/read` idempotent upsert

### Urgent Announcement Modal (cc-336)
- `UrgentAnnouncementModal`: non-dismissable `fullScreenCover`, `.interactiveDismissDisabled(true)`, "Got it" ack
- `GunnerFormsApp`: `urgentQueue: [Announcement]`, `currentUrgentBinding` drains queue one-at-a-time
- `fetchUrgentAnnouncements` runs on login and every `scenePhase == .active`
- `markRead` called after each ack; read-on-tap also fires for all announcements in `AnnouncementsView`

### Email PII Redaction (cc-337)
- `email.js`: success log replaces raw `to` with `ty*****@gunnerroofing.com` pattern via lookbehind regex; failure log drops recipient entirely

### Scheduler Dual-Push Fix (cc-338)
- Root cause: single `rate(4 hours)` EventBridge rule could fire at 7pm ET, satisfying both morning (`≥7`) and afternoon (`≥14`) in one invocation
- Fix: added `etHour < 14` upper bound to morning condition; deleted old rate rule; two cron rules: `cron(0 12 * * ? *)` morning, `cron(0 19 * * ? *)` afternoon

---

## Deploy History This Session

| Version | Key Changes |
|---------|-------------|
| v146 | cc-322 (paginated photos route, tagCustomerPhotos helper) |
| v147 | cc-304 palette vars, Part B .task migration |
| v148–v151 | cc-329 prod seed iterations (_stmts handler add/remove) |
| v152 | Live alias pointed at prod Aurora |
| v153 | Full prod schema + migrations (cc-331) |
| v154 | cc-335 announcement reads + cc-337 email PII |
| v155 | Fixed announcement_reads FK (VARCHAR not UUID) |
| v156 | cc-338 scheduler morning guard + email.js PII redaction |

---

## Key Patterns Established

**`_stmts` Lambda runner** — one-shot SQL delivery to a Lambda that can't be reached via `pg_restore`. Deploy with handler, invoke, remove handler, redeploy. Never publish with `_stmts` on `live`. Seeds > 256KB must be split or routed differently.

**Token migration rule** — Xcode auto-generates `Color.appX` from colorset names. Do NOT add manual `extension Color { static let appX }` — causes `invalid redeclaration` on clean build.

**`_stmts` payload limit** — 256KB sync invoke limit. This session's largest payload was 172KB (17 missing tables). Payloads approaching limit: split or use async invoke (6MB limit).
