---
type: session
title: "iOS cc-167–233: Tab Architecture, Markup Fix, ThemeManager, Polish Sprint"
created: 2026-06-08
updated: 2026-06-08
tags:
  - session
  - ios
  - gunnerteam
  - swift
  - lambda
status: stable
related:
  - "[[tyler/gunnerteam/gunnerteam-project-structure]]"
  - "[[gunnerteam/aws-environment]]"
  - "[[gunnerteam/brand-colors]]"
  - "[[tyler/masterdb/masterdb-developer-handoff]]"
---

# iOS cc-167–233: Tab Architecture, Markup Fix, ThemeManager, Polish Sprint

Session covering approximately 66 cc-prompts across two major themes: fixing the `PhotoMarkupEditor` chrome presentation bug (took 8+ iterations to resolve) and building a new 4-tab navigation architecture with scroll-aware titles and brand color alignment.

---

## Key Deliverables

### PhotoMarkupEditor Chrome Fix (cc-42 through cc-46, cc-190 through cc-194)

**Root cause (final):** SwiftUI reports `safeAreaInsets == .zero` on a `fullScreenCover`'s **first layout pass**. The chrome rendered correctly only after a background→foreground relayout. Additionally, `scaledToFill()` on the blurred backdrop widened the ZStack past screen edges, pushing all buttons off.

**Two-part fix (both required):**
1. Read insets from `UIApplication.shared.connectedScenes` key window (`deviceSafeInsets()`) — bypasses SwiftUI's per-pass safe area
2. Give the backdrop `Image` an explicit `.frame(width: geo.size.width, height: geo.size.height)` inside a `GeometryReader` — prevents `scaledToFill` from widening the layout

**Presentation architecture (cc-43):** `MarkupWrapper` deleted. Every entry point now uses a direct top-level `.fullScreenCover(item:)` presenting `PhotoMarkupEditor` directly. `PhaseDetailView`'s camera→markup swap-in-place was replaced with a `phaseMarkup` state + `onDismiss` handoff pattern.

**Lesson filed in CLAUDE.md:** fullScreenCover gives SwiftUI safeAreaInsets == .zero on first layout pass; always read from UIKit key window. Never leave `scaledToFill()` backdrop unframed inside an overlay container.

---

### Tab Bar Architecture (cc-207, cc-224, cc-225, cc-230–233)

**Structure:** `ContentView` is now a `TabView` with four tabs: Jobs, Forms, Fleet, More.

**Wrapper structs pattern:** `FormsTabRoot`, `FleetTabRoot`, `MoreTabRoot` wrap the inner view structs and own the `.toolbar` block. The inner views own `.navigationTitle`. This separation (toolbar on parent, title on child) is required for SwiftUI large titles — same pattern as `JobsTabRoot + JobsView`.

**Custom scroll titles:** `ScrollTitleKey` PreferenceKey detects when the large `Text("TabName")` scrolls off-screen. `ToolbarItem(placement: .principal)` uses `.opacity(showNavTitle ? 1 : 0)` — always occupies the principal slot so SwiftUI doesn't fall back to rendering `.navigationTitle`. `if showNavTitle { }` leaves the slot empty and causes double-title.

**Jobs scroll title uses named coordinate space:** `geo.frame(in: .named("jobsScroll")).maxY < 0` is reliable regardless of banner state; `.global` with a hardcoded threshold (< 110) was fragile.

**MoreView rewrite:** `List` replaced with `ScrollView + VStack + moreRow` tile grid matching Fleet/Forms card style. Referrals moved from `NavigationLink` to `.sheet` to prevent push animation.

**Logo → Settings:** All four tab root toolbars open `SettingsView` on logo tap. `.onTapGesture` used instead of `Button` to eliminate the press highlight artifact on tab switch.

**Scroll bounce:** `.scrollBounceBehavior(.basedOnSize)` on Forms, Fleet, More — prevents bounce on short-content tabs. Jobs intentionally excluded (long list needs real scroll).

---

### ThemeManager — Runtime White-Label Color System (cc-200, cc-226, cc-227)

`ThemeManager` (`@MainActor ObservableObject`) loads from `GET /org/theme`, applies hex overrides to all 8 semantic tokens, persists to `UserDefaults["gt_theme.*"]`, and restores on cold launch. Asset Catalog values are the fallback default.

**`AppSecondary.colorset` updated to Gunner teal:**
- Light: `#006782` (Gunner teal for light backgrounds)
- Dark: `#00bee9` (Gunner teal for dark backgrounds)

**Color rules (from ux-design-spec.md §9):**
- `appSecondary` (Gunner teal) = sole interactive accent across all tabs
- `appDestructive` (red `#DD141E`) = titles, errors, alerts, destructive — brand-exact
- `appWarning` (amber `#F59E0B`) = warning/caution indicators only — NOT a Gunner brand color
- `appSuccess` = completion/pass states only
- `appPrimary` (navy `#1B538F`) = links, informational — brand-exact

**`OrgLogoView`:** Falls back to bundled `gunnerpng`; swaps when admin uploads via `/org/theme`.

---

### Backend: `/org/theme` + `/companycam/tasks/high-alert` (cc-177–180, cc-201)

- `GET/PATCH /org/theme` — stores per-org theme config in `gt_org_theme` table (plain UUID PK, JSONB config, no FK constraints per codebase convention). Hex validation on all 8 keys. Admin/manager only for PATCH.
- `GET /companycam/tasks/high-alert` — returns jobs with pending high-alert tasks (job summary + count) scoped to `req.user.email`. Powers the Jobs tab high-alert banner.
- **Lambda at v127**; all migrations applied.

---

### 360 Photo Capture Feature (cc-203–207)

`Photo360CameraSession`: full-screen camera + right-side collapsible tag column + bottom-right gallery with count badge + single active-photo preview. Tags can be label-only (`itemId == nil`) or hidden-sibling (`itemId != nil`) for routing to separate phase items.

`GunnerPhaseItemType.photo360` added. `GunnerTaskStep` extended with `itemId?` and `highAlert?`. `handle360Captures` routes:
- Tagged photos with `itemId` → PATCH sibling item complete (with `flagged` for damage)
- Untagged + label-only → PATCH the 360 item complete with `photoKeys`
- Label-only damage (`allowsHighAlert`, `itemId == nil`) → `ownFlag = true` → 360 item gets `flagged: true`

---

### Other Significant Changes

**FAB visibility state machine:** `onDisappear` never restores FAB — only `onAppear` on the destination drives it. `JobsView.onAppear` restores FAB when returning from any job screen. `JobGuidedView.onAppear` hides it on entry.

**Phase items:** Completed items collapse to `✓N` badge. `CompletedPhaseItemsSheet` groups by section. `CompletedPhaseItemDetailSheet` shows photo gallery, text, checklist, measurement, or signature. Retake/add-photo for completed items via `startPhotoCapture` (reuses existing capture→markup→PATCH chain, appends `photoKeys`). Progress bar replaced with custom `appWarning` capsule (invisible on ultraThinMaterial).

**Cinematic hero vignette (`HeroVignette.swift`):** Radial + linear gradient vignette applied to all 9 hero photo backgrounds. Blur reduced 4 → 1.5pt. Flat `Color.black.opacity()` overlays removed.

**`CameraPinchZoomer`:** Universal pinch-to-zoom on all custom AVCapture cameras (`CameraPreview` and `DualCameraPreview`). `n.n×` badge fades in/out. UIImagePickerController cameras (ITRequest, VehicleDocumentViews) unaffected — they zoom natively.

**SFSafariViewController:** `openInAppSafari()` presents via `present(_:animated:)` from the topmost UIViewController — NOT as a `UIViewControllerRepresentable` inside a sheet (which causes the "Do not add SFSafariViewController as a child" crash).

**`release/3.0.0` branch:** Created at build 8, v3.0.0 — the exact commit submitted to App Store Review. Frozen. New features continue on `main`.

**OMP 15.8.3 → 15.10.4:** Key fixes: O(N²) compaction hang fixed; `workflow` keyword renamed to `workflowz` (prevents accidental subagent fan-out); iTerm2 streaming text truncation fixed.

---

## Files Most Changed This Session

- `GunnerForms/GunnerTeam/Photos/PhotoMarkupEditor.swift` — chrome architecture rewrite
- `GunnerForms/GunnerTeam/Home/ContentView.swift` — tab bar architecture, ThemeManager, forms, more
- `GunnerForms/GunnerTeam/Jobs/JobListView.swift` — scroll-aware title, job row polish
- `GunnerForms/GunnerTeam/Jobs/PhaseDetailView.swift` — 360 routing, completed items, progress bar
- `GunnerForms/GunnerTeam/Theme/ThemeManager.swift` — runtime color system
- `GunnerForms/GunnerTeam/Fleet/VehicleInspectionHubView.swift` — tab root, scroll title, teal accent
- `gunnerteam-api/src/routes/org.js` — new file: GET/PATCH /org/theme
- `gunnerteam-api/src/routes/companycam.js` — high-alert endpoint

## Git State

- **HEAD (main):** `ba18413` (cc-233 — Jobs scroll title, logo tap, FAB 100pt)
- **release/3.0.0:** `74c9d2c` (frozen at App Store submission)
- **Lambda live:** v127
