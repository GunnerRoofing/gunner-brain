---
type: session
title: >-
  Session 2026-06-13: Bundle perf, gamification Phase 2-3, iOS polish
  (cc-608–742)
created: '2026-06-13'
updated: '2026-06-13'
tags:
  - session
  - gunnerteam
  - ios
  - backend
  - gamification
  - bundle
  - perf
status: complete
---
# Session 2026-06-13: Bundle perf, gamification Phase 2–3, iOS polish (cc-608–742)

## Scope

Long session covering:
- GunnerCam bundle endpoint perf investigation and structural fixes (v183–v220)
- Gamification Phase 2 (achievements schema + evaluator + leaderboard) and Phase 3 (redemption, payroll export, Tremendous, deductions)
- iOS job-screen UX sprint (cc-608–742): 30+ prompts
- Wiki health check and auto-fix pass

---

## Backend — Lambda v183–v220

### Bundle perf saga (fieldportal.js)

**Root cause:** Six GunnerCam project IDs (c18e8ee8, 0a6714fc, 44b64089, fe285cf1, d6b3d849, bcfd90b3 + others) hold TCP connections open for ~25s. No JavaScript-level timeout mechanism (AbortController, Promise.race, withTimeout, AbortSignal.timeout) reliably aborts them — the signal fires at the JS layer but the OS-level TCP socket stays open until GunnerCam's server closes it.

**What was tried and learned:**
- v186: AbortController — does NOT abort TCP (only JS-side)
- v187–189: Promise.race with timer — same; race fires but fetch doesn't reject
- v191: body-read outside race — fixed the race to cover headers+body
- v192: cap 6→3 — wrong direction; more batches = worse total time
- v193: two-phase withTimeout — same TCP issue; upsert made fire-and-forget (bad)
- v194: undici Agent with headersTimeout/bodyTimeout — `require('undici')` fails in Lambda Node.js 18
- v195: AbortSignal.timeout — fires but socket stays open (25s in logs)
- v196–213: cc-607 cursor tracking, cc-710 leaderboard, cc-728 payroll, cc-731 exclusions, cc-725/726/727/728/729 redemption stack
- v217: upsert made inline-await before serve() (durable, ~300ms real cost)
- v218: express-rate-limit v8 IPv6 fix (ipKeyGenerator)
- v219: cc-742 diagnostic instrumentation (confirmed no JS-level leaked promises)
- v220: instrumentation removed; clean

**Current state (v220):**
- Detail cap: 30 jobs (was 150)
- Concurrency cap: 6
- AbortSignal.timeout(4500) on each fetchJson — fires correctly but doesn't cancel TCP; fast GunnerCam = sub-second rebuild; slow GunnerCam = 503 (cache still writes)
- Upsert: inline-await before serve() — durable, 253–406ms real Aurora cost
- Upstream cursor: stored from max(updatedAt) of returned jobs, not Lambda NOW()
- Delta path: modified_since uses upstream_cursor (cc-607)
- Colin's slow report: filed at `colin-slow-report-2026-06-12b.md` with 9 project IDs

**Key insight:** When GunnerCam is fast (nights/weekends), rebuild = 521ms total. The 503 problem is 100% Colin's broken endpoints. Our code is clean.

---

## Gamification Phase 2–3 (cc-603–731, v183–v213)

### Phase 2 (achievements + leaderboard)
- `gt_achievements`, `gt_user_achievement_progress`, `gt_user_achievements` tables
- `evaluateAchievements.js`: O(1) counter per event type, shared metric_key across tiers, windowed period support, exclusion window respect
- `awardPoints.js` wired to evaluator; returns `{ awarded, points, balance, unlocked, kind, recoverable }`
- Leaderboard: opt-in, bracketed (top-3 + ±2 neighborhood), pseudonymous, weekly window
- `GET /points/achievements`, `GET/PATCH /points/leaderboard`, `GET /points/audit-export`, `POST/GET /points/exclusions`
- iOS: `PointsHubView` with live achievements (progress rings grouped by metricKey), opt-in leaderboard, celebration on unlock

### Phase 3 (redemption + payroll)
- `gt_rewards_catalog`, `gt_redemptions` tables; `cash_value_cents` per row for payroll compliance
- `RedemptionProvider` interface + `TremendousAdapter` (sandbox) + `InternalAdapter` (PTO/perks)
- `POST /points/redeem`: reserve-then-order flow; `FOR UPDATE` balance lock; compensating refund on terminal failure; timeout leaves pending (202)
- `GET /points/payroll-export`: W-2 taxable wages export, CSV + JSON, `?unreportedOnly=true`
- `POST /points/payroll-export/mark`: idempotent reporting
- `gt_point_multipliers`: Double-XP windows, scope matching (exact > prefix > null), `POST/GET /points/multipliers` (gt-admin)
- Deductions: `internal.inspection.failed (-10)`, `internal.schedule.off_time (-5)`; balance floored at 0; lifetime_points never decreases
- `gt_points_exclusions`: FMLA/ADA accommodation path; full-week exclusion omits user from leaderboard; partial exclusion excludes windowed achievement progress
- HubSpot review ingestion: `pullHubSpotReviews()` scheduled task; durable cursor in `gt_task_cursors`; quality guard (≥4★ or POSITIVE sentiment)

---

## iOS Sprint (cc-608–742)

### Navigation & UX
- cc-615: Geofence arrival banner (explicit confirm required, not auto-check-in)
- cc-616: GuidedTasksView → bottom sheet with `.medium`/`.large` detents + SwipeToCompleteModifier
- cc-617: JobDetailView address → Maps link
- cc-618: ACTIVITY + COMMENTS merged into TIMELINE tab (4→3 tabs)
- cc-619: Checked-in job pinned to top of job list
- cc-620: Filter chips (Active/Complete/On Hold) with collapsible toggle button
- cc-713: Geofence false-trigger fix (guard `state == .inside`, `pendingArrivalJobId == nil`)
- cc-714: AI button removed from bottom bar; Create Task → direct Tasks sheet
- cc-715: Left accent bar and status chip removed from job rows
- cc-716: Filter chips collapsed behind icon button with active-filter badge
- cc-717: Next Action CTA removed
- cc-718/719: Photo/file/activity IDs normalized to String (backend + iOS defensive decoder)
- cc-720: Tasks picker (Photo Task → camera, Text Task → quick text, View All)
- cc-721: Filter chips status-only (label chips removed)
- cc-722: Phase row full-row tap; tab bar hidden in JobGuidedView and PhaseDetailView
- cc-723: PhaseDetailView list layout + Start Camera Session button (AllItemsSessionCover)
- cc-724 (check-in): persistState() called in checkIn(); reconcile doesn't clear in-session check-in
- cc-724 (jobs list): swipe-to-go-back restored (SwipeBackEnabler baked into darkJobTabBar)
- cc-725 (iOS): enableSwipeBack() explicit on JobGuidedView and PhaseDetailView
- cc-734: PointsHubView blank screen fixed (missing else branch)
- cc-735: PointsHubView load split — critical (balance/history) vs optional (achievements/leaderboard)
- cc-736 (job card): CheckedInPill removed; "● On site" replaces distance readout
- cc-737 (CheckInManager): geofencedJobName persisted; auto-checkout fires push + in-app notification
- cc-738: PointsHubView NavigationStack wrapper (back button now renders in sheet)
- cc-739: isManualCheckIn flag prevents auto-checkout on return to job list
- cc-740: Tasks picker routes to real flows (camera/quick-text), CreateTaskSheet dead code removed
- cc-741: express-rate-limit IPv6 fix (ipKeyGenerator)
- cc-742: Bundle promise leak diagnosis — no JS-level leaks confirmed; slow endpoints are Colin's problem

### Contrast audit (cc-280/281)
- AppDestructive dark variant: `#FF3B3B` (4.53:1 on bgCard dark)
- AppSuccess adaptive: light `#047857` (7.1:1), dark `#34D399` (8.96:1)
- REQ badge: amber capsule with `#0F1117` dark text (8.8:1 AAA)
- Required label: `#78350F` in light mode (9.1:1 AAA)

---

## Wiki Lint (2026-06-13)

- 214 pages scanned, 31 issues found
- Auto-fixed: Untitled.md deleted, Gamify brief ingested to gunnerteam/, ciso-track stubs created, raw-sources dead link fixed, lint report paths corrected, hot.md dead session link removed, 5 cc-11 sessions added to index.md
- Report: [[meta/lint/lint-report-2026-06-13]]

---

## Current Lambda Version

v220 — all gamification tables live, redemption schema live (REWARDS_ENABLED=false), bundle perf stable at sub-second on warm GunnerCam.

## Key Files Changed This Session

**Backend:** `src/routes/fieldportal.js`, `src/routes/points.js`, `src/routes/points-webhook.js`, `src/routes/auth.js`, `src/points/awardPoints.js`, `src/points/evaluateAchievements.js`, `src/points/resolveMultiplier.js`, `src/points/hubspotReviewsPull.js`, `src/points/redemption/` (provider.js, tremendousAdapter.js, internalAdapter.js, index.js), `src/lambda.js`

**iOS:** `GunnerTeam/App/CheckInManager.swift`, `GunnerTeam/Jobs/JobGuidedView.swift`, `GunnerTeam/Jobs/JobListView.swift`, `GunnerTeam/Jobs/JobDetailView.swift`, `GunnerTeam/Jobs/PhaseDetailView.swift`, `GunnerTeam/Jobs/GuidedTasksView.swift`, `GunnerTeam/Home/PointsHubView.swift`, `GunnerTeam/App/PointsModels.swift`, `GunnerTeam/Theme/CelebrationManager.swift`, `GunnerTeam/Theme/DarkJobTabBar.swift`
