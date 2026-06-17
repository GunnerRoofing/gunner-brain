---
type: session
title: 'cc-766–788: App Store hardening, 360 camera redesign, polish sprint'
created: '2026-06-15'
updated: '2026-06-15'
tags:
  - session
  - ios
  - backend
  - gamification
  - 360-camera
  - app-store
  - hardening
status: complete
---

# Session: cc-766–788 — App Store hardening, 360 camera redesign, polish sprint

**Date:** 2026-06-15  
**Lambda at end:** v237 (`live`)  
**iOS build at end:** BUILD SUCCEEDED, all cc-766–788 committed to `main`  
**Git state:** clean — source of truth for both iOS and backend

---

## What Shipped

### Backend (deployed)

| Version | Change |
|---|---|
| v234 | Reconcile merge: all post-v233 deployed changes into source (`perf.js`, `db.js`, `app.js`, `auth.js`, `time.js`, `fieldportal.js`, `points.js`, `src/points/` module, `points-webhook.js`, `announcements.js`, `fleet/index.js`, `email.js`, `scheduler.js`) |
| v235 | `GET /fieldportal/jobs/:jobId/activity` — lightweight activity+files route (skips photo sub-fetch, 8s AbortSignal, iOS retry helper) |
| v236 | `GET /points/balance` → proxy-safe `query()` (no SET LOCAL pin); `GET /points/history` columns aliased to camelCase (`eventType`, `effectivePoints`, `createdAt`) |
| v237 | (history camelCase fix deployed as v236 then bumped) |

**Points history camelCase fix (cc-775):** `/points/history` was returning snake_case columns; iOS `PointsHistoryItem` decodes camelCase without `convertFromSnakeCase`, causing "Couldn't load" on the Points tab. Fixed by SQL `AS "eventType"` aliases.

**Leaderboard always-on (cc-778):** Removed opt-in gate and `PATCH /leaderboard-optin` endpoint. All members ranked. Both payloads always return `optedIn: true` for backward compat. `WHERE b.opt_in_leaderboard = true` filter dropped.

### iOS — feature changes

**cc-766 (field task chips):**  
- High-alert (red `appDestructive`) and required (amber `appWarning`) count chips on "View Field Tasks" card  
- `highAlertCount`/`requiredCount` state; `loadFieldTaskCount()` populates all three  
- Addendum A: create-task success paths call `loadFieldTaskCount()` instead of hand-bumping  
- Addendum B: `lineLimit(1).minimumScaleFactor(0.85)` on chip label (no-wrap fix)

**cc-781 (task counts exclude completed):**  
- `TaskCountPayload.TaskStub` gains `completedAt: String?`  
- Count filter: `resp.tasks.filter { $0.completedAt == nil }` — only open tasks counted

**cc-767 (toast top):** `ToastModifier` flipped from `.bottom` to `.top`; transition edge `.bottom` → `.top`; `.padding(.top, 8)`

**cc-769 (activity route + retry):**  
- `fetchJobActivity()` free function with 12s timeout, one 800ms retry  
- `JobFilesView.loadFiles` and `JobCommentsView.loadComments` both hit the new lightweight `/activity` route instead of the heavy detail route

**cc-770 (markup auto-refresh):**  
- `onPhotoAdded: (() -> Void)?` added to `CCPhotoViewer` and `FPPhotoViewer`  
- Markup upload wrapped in `do/catch`; callback fires only on success  
- `JobPhotosView` passes `onPhotoAdded` → 1.5s delay → `loadPhotos()`

**cc-774 (photos card contrast):**  
- Photos card: `regularMaterial` + `black.opacity(0.45)` dark scrim  
- Count badge fill: `white.opacity(0.15)` → `black.opacity(0.35)`  
- Videos header: `white.opacity(0.8)` → `.white`

**cc-776 (View Field Tasks title one line):** `lineLimit(1)` on title text

**cc-776 (Manage Users self row):** `Color.appPrimary` stripe moved from greedy HStack sibling to `.overlay(alignment: .leading)` — self row height now matches peers

**cc-777 (Invite User form):**  
- `menuPickerLabel` restyled to match text fields (`appPrimary.opacity(0.08)` fill + `appPrimary.opacity(0.35)` stroke)  
- Department: `confirmationDialog` bubble replaced with `Menu`+`Picker` inline dropdown + selection haptic  
- `showDeptDialog` state + `.confirmationDialog` removed

**cc-778 (leaderboard always-on iOS):**  
- `lb.optedIn` gate removed from `leaderboardCard`  
- `optInToggle`, `isOptingIn`, `setOptIn`, PATCH call all deleted  
- Neutral empty-state copy when no board yet

**cc-782 (legibility):**  
- CO form: `.tint(Color.appSecondary)` on `Form` so text caret is teal not invisible white  
- Phase card completed state: solid `appSuccess` circle, white checkmark, `white.opacity(0.85)` summary text

**cc-784 (360 camera arm-before-shoot):**  
- `armedTagId`/`armedHighAlert` state; `armTag()` replaces `toggleTag()`  
- Shutter auto-assigns armed tag + highAlert; stays armed across shots  
- Tag chips: teal when armed, green checkmark + count badge when photos exist; damage toggle binds to `armedHighAlert`  
- `rightPreview`: armed tag label in teal before first capture; "Tap a tag to start" when nothing armed  
- Gallery: grouped by tag (header + count), untagged section last; `galleryCell` helper extracted

**cc-785 (360 tag chip one line):** column 132→144pt; label `lineLimit(2)` → `lineLimit(1).minimumScaleFactor(0.8)`

**cc-786 (phase complete confetti):**  
- `CelebrationEvent.phaseComplete` added — confetti-only, no dim, no card, 2s auto-dismiss  
- `CelebrationOverlay` routes `.phaseComplete` to confetti branch; `scheduleAppear(delay:)` parameterized  
- `PhaseDetailView.attemptCompletePhase`: haptic replaced with `CelebrationManager.shared.celebrate(.phaseComplete)`

**cc-783/787/788 (phases card insets):**  
Final values: first row `.padding(.top, index == 0 ? 8 : 14)`, last row `.padding(.bottom, index < total - 1 ? 20 : 8)`, container `.padding(.vertical, 4)`. Net: top inset = bottom inset = 12pt.

### App Store hardening (cc-779, cc-780)

**P0:**
- `aps-environment`: `development` → `production` (push tokens now register on APNs prod)
- Build number: 8 → 9

**P1 — print() cleanup:**
- 5 pure-diagnostic `print()` calls deleted
- Remaining 38 calls across 15 files wrapped in `#if DEBUG`/`#endif`

**P2 — defensive hardening:**
- All test targets: `26.4` → `26.0` (aligned with app target)
- `missing.last!` → `?? ""`; `FileManager.urls[0]` → `.first ?? temporaryDirectory` (with parens for chaining)
- `captured[0]` confirmed safe (dictionary subscript, `[Int: Data]`)
- All `URL(string:)!` eliminated (0 remaining): `CheckInManager` (5), `PointsHubView` (4), `GunnerTaskModels` (4), `PhaseWorkflowModels` (7); all `throws` functions route else → `throw URLError(.badURL)`; client-supplied path components percent-encoded

### Process + governance

**Git is source of truth — revised rules:**
- Solo `gunner-ios` work (Tyler only) → commit directly to `main`, no branch/PR
- Shared Lambda (Colin + automated sessions) → full reconcile + deploy discipline
- Cross-team/shared infra → PR + owning-team sign-off

**Docs filed in repo and wiki:**
- `CONTRIBUTING.md` (revised: solo-maintainer scope)
- `CHANGE_MANAGEMENT_POLICY.md` (revised: §0 scope clarification)
- `TEAM-KICKOFF-MESSAGE.md`
- `CLAUDE_CODE_RULES_ONBOARDING.md`
- `POSTMORTEM-2026-06-15.md`
- `.claude/settings.json` hooks now tracked in git

**Employee notice draft:**  
`wiki/gunnerteam/employee-notice-points-location.md` — Recognition Points, Leaderboard & Location. Status: draft-ready, not distributed. Needs IT/HR (location on/off-clock), counsel (gift card tax treatment), CT/NJ written-disclosure confirmation before distribution.

**Stash note:** `stash@{0}` still held — Terraform diffs (`api-gateway.tf`, `lambda-api.tf`, `sg.tf`, etc.) need separate reconcile against live infra.

---

## Key Decisions

- **`captured[0]` is safe:** `captured` is `[Int: Data]` (dictionary), not an array — subscript returns `Optional`, never crashes. Do not replace with `.first`.
- **Leaderboard always-on:** All members ranked; opt-out via HR (exclusion window). No consent flag in app; see employee notice for disclosure.
- **Phase complete = confetti only:** No banner/modal; `CelebrationEvent.phaseComplete` auto-dismisses in 2s, no dim.
- **Activity route:** `/fieldportal/jobs/:id/activity` returns only `activity`+`files` (no photos sub-fetch). Files and Comments tabs no longer pay the ~25s upstream cost; one 800ms retry on the iOS side.

---

## Open Items

- `GUNNERCAM_POINTS_WEBHOOK_TOKEN` — still needs real value in Lambda console
- `REWARDS_ENABLED=false` — set true in Lambda + publish version when policy approved
- Terraform stash (`stash@{0}`) — reconcile `terraform/` against live infra separately
- Employee notice — not distributed; confirm with HR/legal/IT before sending
- Colin's slow endpoints (9 project IDs) — reported; waiting on Colin fix

---

## Related

- [[gunnerteam/CONTRIBUTING]]
- [[gunnerteam/CHANGE_MANAGEMENT_POLICY]]
- [[gunnerteam/POSTMORTEM-2026-06-15]]
- [[gunnerteam/git-source-of-truth-policy]]
- [[gunnerteam/employee-notice-points-location]]
