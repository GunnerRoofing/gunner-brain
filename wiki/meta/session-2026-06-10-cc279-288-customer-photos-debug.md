---
type: session
title: "Session 2026-06-10: cc-279–288 Customer Photos Debug"
created: 2026-06-10
updated: 2026-06-10
tags:
  - gunnerteam
  - ios
  - lambda
  - debug
  - companycam
status: complete
related:
  - "[[gunnerteam-project-structure]]"
  - "[[masterdb-architecture]]"
  - "[[aws-environment]]"
---

# Session 2026-06-10: cc-279–288 Customer Photos Debug

Multi-session customer photo upload debugging culminating in an Express body-limit fix, plus several UI polish prompts (haptics, photo cell hit area, Customer badge in customerMode). The real root cause turned out to be a `PayloadTooLargeError` rejecting the request at the Express layer before any route handler ran — three rounds of CloudWatch debug logging were needed to surface it.

---

## Commits

All on `main`, `GunnerRoofing/gunner-ios` monorepo.

| Hash | Change | Prompt |
|------|--------|--------|
| `0b6e23c` | fix: `isCustomer` uses Colin's `source` field as primary, table lookup as fallback | cc-279 |
| `11fb643` | fix: delay `isUploadingCustomer` clear until after reload (1.5s → 3s by cc-284) | cc-280 |
| — | fix: unify ⋯ menu and Create Field Task popover to fixed `#2A2E37` grey | cc-281 |
| — | TEMP debug logs added and reverted (PHOTODEBUG, GETDEBUG, UPLOADDEBUG, ROUTEHIT) | cc-282/283 |
| `de4f31f` | fix: use `TransferPhoto` Transferable wrapper for photo loading to handle Live Photos/HEIC | cc-284 |
| `6b45fd8` | fix: raise Express JSON body limit to 20mb for customer photo uploads | cc-284 |
| `3e43881` | fix: defensive `photoObj` extraction for `gt_customer_photos` INSERT | cc-283/284 |
| `79c960a` | feat: haptics on PM switcher + picker row; bump customer upload reload to 3s | cc-284 |
| `e4eb4f6` | fix: move frame/clip to AsyncImage container + `contentShape` to fix photo cell hit area | cc-285 |
| `bce6969` | feat: light haptic on job row tap via `simultaneousGesture` | cc-286 |
| `dec91fd` | fix: hide Customer badge in `customerMode` | cc-287 |

Lambda debug: all PHOTODEBUG logs added/reverted — **no net Lambda change except the body limit + `photoObj` fix**.

---

## Key Findings from the Debug Journey

### 1. The `source` field is null in this environment
CompanyCam white-label dev `/projects/:id/photos` never populates `source` on photo objects. `p.source === 'customer'` is dead code here. The `gt_customer_photos` table lookup is the **sole** signal for `isCustomer`. cc-279 made the table lookup the fallback behind the (null) source field — but in practice the table lookup is what actually fires.

### 2. `PayloadTooLargeError` was the real root cause
Express JSON body limit was **100kb**; camera-roll JPEG base64 payloads are **2–5MB**. Lambda rejected the request with **413 BEFORE the route handler ran**, which is exactly why `ROUTEHIT` / `UPLOADDEBUG` log lines never appeared in CloudWatch. Fix: raised the limit to **20mb** in `src/app.js` (`6b45fd8`). This was the actual blocker the whole session was chasing.

### 3. `loadTransferable(type: Data.self)` worked fine all along
The original `TransferPhoto: Transferable` wrapper was added as a red herring for Live Photo / HEIC handling, but the real block was the 413 rejection — not photo decoding. The wrapper is harmless and was **kept** (`de4f31f`).

### 4. `photoObj` defensive extraction
CompanyCam `POST /projects/:id/photos` returns `{ photo: {...} }` (wrapped), **not** a bare photo object. The `ccData?.id` guard was silently skipping **every** `gt_customer_photos` INSERT because `id` lived one level deeper. Fixed to unwrap `ccData?.photo ?? ccData?.photos?.[0]` (`3e43881`).

### 5. Debug log pattern (3 rounds)
Three rounds of targeted debug logs (cc-282, cc-283, cc-284) were deployed to CloudWatch and reverted. Pattern per round: **add targeted log → deploy → capture in CloudWatch → revert in the same zip**. Tags used: `PHOTODEBUG`, `GETDEBUG`, `UPLOADDEBUG`, `ROUTEHIT`. All removed by end of session.

---

## Lambda State

- **v139 live** on alias `live`.
- Net changes this session:
  - `src/app.js` — JSON body limit `100kb → 20mb`.
  - `src/routes/companycam.js` — `photoObj` unwrapping (`ccData?.photo ?? ccData?.photos?.[0]`).
- All PHOTODEBUG/GETDEBUG/UPLOADDEBUG/ROUTEHIT logs reverted — no net debug code remains.

---

## iOS State

- **HEAD:** `dec91fd` (cc-287 — hide Customer badge in customerMode); multiple commits through cc-288.
- Key new code:
  - `TransferPhoto: Transferable` struct in `JobSectionViews.swift` (Live Photo / HEIC handling).
  - Haptics on job row tap (`simultaneousGesture`), PM switcher, and PM picker row.
  - Photo cell hit area fixed — frame/clip moved to the `AsyncImage` container + `contentShape`.
  - Customer badge hidden when `customerMode` is active.
- Customer photo upload **working** end-to-end after the body-limit fix.
