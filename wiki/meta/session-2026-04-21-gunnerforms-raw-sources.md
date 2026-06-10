---
title: "Session 2026-04-21 — GunnerForms + Raw-Sources Ingest"
type: session
tags: [session, gunnerforms, appstore, ios, ingest]
created: 2026-04-21
updated: 2026-04-21
sources: []
related:
  - "[[gunner/gunner-forms-app]]"
  - "[[questions/app-store-guideline-4-8-webview-login]]"
  - "[[questions/ios-dev-workflow-claude-xcode-github]]"
  - "[[vendors/stripe-api-reference]]"
  - "[[gunner/it-decision-log]]"
status: stable
---

# Session 2026-04-21 — GunnerForms + Raw-Sources Ingest

## Canvas Cleanup

- `wiki/canvases/welcome.canvas` deleted — stale claude-obsidian demo template with broken GIF references
- `wiki/Wiki Map.canvas` and `wiki/canvases/main.canvas` indexed under new Canvases section in index

## GunnerForms App Store Work

**Problem:** App rejected under Guideline 4.8 (login services) — the explicit "Sign in to Monday.com" UI was treated as an app-level third-party login service.

**Fix:** Removed `MondaySignInView`, `signInBanner`, sign-out button, and `mondayLoggedIn` state entirely. Auth now handled by Monday.com's website within the WebView. Original sign-in flow preserved in `feature/sign-in-with-monday` branch.

**Also added:** haptic feedback on form card tap, Open in Safari button in form nav bar. Updated IT Request form URL.

**Resubmitted:** 2026-04-21. Reviewer notes left in Resolution Center. App Review test account: `appreview@gunnerroofing.com`.

**Dev workflow explained:** Claude Code edits `.swift` files on disk → Xcode builds (Cmd+R) → git tracks history → GitHub is the cloud backup. Branches = parallel versions, switching is instant. See [[questions/ios-dev-workflow-claude-xcode-github]].

## Raw-Sources Batch Ingest

**9 sources processed:**

| Source | Wiki Page |
|--------|-----------|
| Stripe API Reference.pdf | [[vendors/stripe-api-reference]] — Gunner CT Sandbox active |
| IT Decision & Change Log.docx | [[gunner/it-decision-log]] — SEC-001 CIS IG1, 3 Hexnode CHGs, EXC-001 |
| Departmental Comms.xlsx | [[gunner/departmental-comms]] — tool-to-use-case map |
| Gunner Forms Privacy Policy.docx | [[gunner/gunner-forms-privacy-policy]] — zero data collection |
| Keeper Workshop.pptx | [[summaries/keeper-workshop]] — staff training, Security Audit, priority accounts |
| Jamf/Microsoft v2 Final.pptx | Updated [[vendors/jamf]] — Defender for Business closes CMMC AV gap |
| CMMC Presentation.txt | Already captured in [[gunner/federal-market]] |
| KnowBe4 Proposal.pptx | Already captured in [[vendors/knowbe4]] |
| HubSpot Lead Phases.md | Already captured in [[gunner/hubspot-leads-project]] |

**Not ingested:** IT Tasks xlsx (historical task export), Performance Review (personal), IT Standards pptx (content in roadmap)

## raw-sources Reorganization

| Move | From → To |
|------|-----------|
| dialpadapi.json | root → articles/ |
| 5 HubSpot project files | runbooks/ → projects/ |
| Jamf + KnowBe4 pptx | transcripts/ → study/ |
| 2 duplicate md files | root → deleted |

## Pages Created This Session

- `wiki/questions/app-store-guideline-4-8-webview-login.md`
- `wiki/questions/ios-dev-workflow-claude-xcode-github.md`
- `wiki/vendors/stripe-api-reference.md`
- `wiki/gunner/it-decision-log.md`
- `wiki/gunner/departmental-comms.md`
- `wiki/gunner/gunner-forms-privacy-policy.md`
- `wiki/summaries/keeper-workshop.md`

## Pages Updated This Session

- `wiki/gunner/gunner-forms-app.md` — full rewrite with current status
- `wiki/vendors/jamf.md` — Microsoft + Jamf stack detail
- `wiki/index.md` — Canvases section added, 8 new entries
- `wiki/hot.md`, `wiki/log.md` — current
