---
title: "Session 2026-05-13 — Gunner Assistant + Branch Management"
type: session
tags: [session, gunner-assistant, ios, companycam, branch-management, rag, white-label]
created: 2026-05-13
updated: 2026-05-13
sources: []
related:
  - "[[gunner/gunner-forms-app]]"
  - "[[gunner/software-suite]]"
  - "[[vendors/companycam]]"
  - "[[summaries/project-assigned-webhook-receiver-spec]]"
  - "[[summaries/white-label-agenda]]"
status: developing
---

# Session 2026-05-13 — Gunner Assistant + Branch Management

## What Was Built

### Gunner Assistant (RAG Chatbot)
Full AI chatbot shipped as a new card on the Gunner Team home screen.

**Architecture:**
- iOS card → `POST /assistant/chat` on EC2
- Claude Haiku 4.5 guard: cheap topic check (~$0.00006/question), rejects non-roofing questions
- Claude Sonnet 4.6: answers using retrieved context
- S3 bucket `gunner-assistant-docs`: 11 PDFs, 825 chunks fully ingested at startup
- RAG: 1500-char chunks, 150-char overlap, keyword scoring, top-15 chunks retrieved per query
- API key lives server-side in EC2 `.env` — never exposed to iOS

**iOS (`GunnerAssistantView.swift`):**
- Empty state with icon/description (suggestion chips removed — too easy to accidentally tap)
- Message bubbles: user = purple, assistant = white card
- `MarkdownUI` renders assistant responses (headers, bold, bullets)
- `TypingDotsView`: separate struct with `@State var animating`, bouncing dots on `onAppear` — fixes the "animation never fires because `isLoading` is already true" bug
- `AssistantStore` (`ObservableObject`): owns `messages[]`, persists across navigation, auto-clears after 4h inactivity, manual "New Chat" toolbar button
- `.scrollDismissesKeyboard(.interactively)` — dismisses on scroll drag, standard chat UX
- `.toolbarBackground(bgPrimary, .visible)` fixes black nav bar on scroll
- Custom principal toolbar `Text` in Gunner red — bypasses UIKit `titleTextAttributes` being dropped by SwiftUI's `toolbarBackground`

**Token cost estimate:**
- Per question: ~7,600 input tokens (15 chunks ≈ 5,600 + system prompt + message) + ~400 output tokens
- Sonnet pricing: $3/MTok input, $15/MTok output → ~$0.029/question
- 35 users × 2 questions/day × 30 days = 2,100 questions/month → **~$45–60/month**
- Haiku guard is negligible ($0.00006/question)
- Cost lever: `TOP_K_CHUNKS` in `assistant.js` (currently 15)

### project.assigned Webhook Receiver
Already implemented in `companycam.js` lines 179–243. Live on EC2. Waiting on WL-CompanyCam `feat/project-assigned-webhook` to merge and start firing.
- `COMPANYCAM_WEBHOOK_SECRET` confirmed in EC2 `.env`
- Uses `req.rawBody` (captured by `express.json` verify callback in `app.js`) for HMAC-SHA256
- Dedup via in-memory `seenDeliveries` Set, capped at 1000 entries
- Filters `assignedRole === "pm"`, clears stale APNs tokens on `BadDeviceToken`

---

## Branch Strategy Decisions

**Current branch structure:**
- `main` — forms-only (reset to `870ad94`); still uses Cloudflare Worker (EC2 port is in `release/forms-v2` but not yet landed in main)
- `release/forms-v2` — Apple-approved build; includes fleet, referrals, EC2 migration — NOT yet merged to main intentionally
- `feature/gunner-assistant` — AI chatbot, Jobs/CompanyCam, notifications cards
- `feature/companycam-jobs` — CompanyCam upload/viewing feature
- `feature/vehicle-inspections` — fleet management

**All branches pushed to `GunnerRoofing/gunner-ios`** as of this session.

**Strategy:** Features stay on branches until approved/ready. Merge to main one feature at a time. Cut App Store builds from main only.

**Note:** `main` still uses Cloudflare Worker (`gunner-forms-api.anil-nair.workers.dev`) for IT Request, Change Order, AP forms. The EC2 port (`6ca8739` in `release/forms-v2`) needs to be cherry-picked into main before the next App Store build.

---

## iOS Patterns Established This Session

**Nav bar title color with `toolbarBackground`:**
SwiftUI's `toolbarBackground` drops UIKit `titleTextAttributes`. Fix: use `.toolbar { ToolbarItem(placement: .principal) { Text(...).foregroundColor(red) } }` instead of `.navigationTitle()`.

**Animated typing indicator:**
`value: isLoading` animations don't fire if `isLoading` is already `true` when the view appears. Fix: extract to separate struct with `@State var animating = false` + `.onAppear { animating = true }`.

**Chat state persistence:**
`@State` on a pushed view resets on pop. Fix: `ObservableObject` store owned by the parent (`ContentView`), passed via `.environmentObject()`.

**MarkdownUI custom theme headings:**
`.heading1 { config in config.label.markdownTextStyle { FontSize(17); FontWeight(.bold) } }` — heading closures are `@ViewBuilder`, not `@MarkdownTextStyleBuilder`. `FontSize` goes inside `.markdownTextStyle { }`, not directly in the heading closure.

---

## Trademark Update

USPTO assigned design search codes to Gunner trademark application (SN: 99611883). Filed December 2025. Design codes assigned May 13, 2026 — examiner has picked it up. Expected path: examiner review (1–3 months) → publication → registration by late 2026 if no Office Action.

---

## White Label Software Suite

Full suite ingested from `white label agenda.xlsx`. See [[gunner/software-suite]] for complete breakdown.

Key context: GunnerCam (ColinCam) is being built in-house — it is the replacement for CompanyCam as an external vendor. The current CompanyCam integration in Gunner Team iOS is a bridge while ColinCam matures.

Velocity note: the team is moving significantly faster than traditional engineering estimates. Full auth + DB migration in <1 day, RAG chatbot in ~1 hour, ColinCam functional in ~1 week. The 60-day feature roadmap is credible at this pace.

Open gaps from this session:
- `Gunner_Technology_Roadmap_2026.xlsx` referenced but not yet ingested
- `Revenue & Pipeline Dashboard` referenced but not yet ingested
- All-in cost per partner still TBD
- HubSpot integration still TBD
- SSO / Global User Table architecture decision needed early
