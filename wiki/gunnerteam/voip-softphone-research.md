---
title: In-App Softphone — VOIP Platform Research & Recommendation
type: reference
owner: gunnerteam
created: '2026-06-22'
updated: '2026-06-22'
tags:
  - voip
  - telephony
  - telnyx
  - twilio
  - amazon-connect
  - dialpad
  - callkit
  - ios
  - 10dlc
  - tcpa
  - compliance
status: developing
related:
  - '[[gunnerteam/dialpad-hubspot-integration]]'
  - '[[gunnerteam/aws-environment]]'
  - '[[gunnerteam/gunner-forms-app]]'
  - '[[gunnerteam/security-compliance-roadmap]]'
  - '[[gunnerteam/overview]]'
---

# In-App Softphone — VOIP Platform Research & Recommendation

> [!key-insight] Bottom line
> **Build the in-app voice + SMS/MMS second line on Telnyx (single provider); Twilio is the runner-up. Do NOT build it on Amazon Connect.** The decision is forced by hard requirement #1 (one permanent number doing both voice + SMS): **Amazon Connect cannot share a number across voice and SMS — AWS says so verbatim — so an all-AWS design needs two numbers per rep**, which breaks the single-business-card-number requirement. A CPaaS gives one number for voice+SMS+MMS plus a real iOS Voice SDK that rings through CallKit.

**Scope:** voice + SMS/MMS second line embedded in the existing GunnerTeam iOS (SwiftUI) app, on the Lambda + PostgreSQL backend, multi-tenant/white-label, ~36 users (CT/NJ/OH). **A Dialpad replacement.** Prepared 2026-06-22.

> [!warning] Confidence + scope
> Claims below carry the source's confidence tags — **[HIGH]** (read from a primary doc), **[MEDIUM]** (corroborated), **[FLAG]** (time-sensitive/unverified, confirm before load-bearing). This is research, **not legal advice** — run §Compliance past telecom/TCPA counsel before launch.

---

## The forcing constraint (why not Amazon Connect)

Four starting assumptions were tested:

1. **A single Connect number can't do both voice + SMS → CONFIRMED [HIGH].** Verbatim AWS: *"Using one phone number that is shared for both voice and SMS isn't supported."* SMS numbers are procured in **AWS End User Messaging** and imported into Connect; *"Capabilities for SMS and Voice can't be changed after the phone number has been purchased."*
2. **All-AWS forces two numbers per rep → CONFIRMED [HIGH].** A Connect voice DID + a separate EUM SMS number. (The raw EUM "Voice" capability is automated text-to-audio, **not** a Connect agent line.)
3. **Connect routing is longest-idle, not strict round-robin → CONFIRMED [MEDIUM-HIGH].** No native strict sequential round-robin; you'd build it — same custom build as on any CPaaS, except you fight Connect's router instead of a blank canvas.
4. **Contact Lens real-time AI + monitor/barge only work inside Connect's media path → CONFIRMED [HIGH].** A call that leaves Connect's media path (rep dials customer directly, hard external transfer) is **not** transcribed/monitorable — directly collides with requirement #6 (continuity through the deal).

**Where Connect genuinely shines (what you give up):** best-in-class **hours-of-operation + holiday overrides** (native), and **Contact Lens** is the only turnkey real-time supervisor + keyword-alert engine in the comparison. On Telnyx/Twilio you rebuild both — but that doesn't rescue Connect, because it can't be the per-rep voice+text line at all. Using Connect *alongside* a CPaaS is possible (shared inbound IVR + analytics) but splits the recorded/monitored path across two media engines — **not recommended.**

---

## Platform shortlist

Seven platforms were scored against 13 hard requirements (full matrix in source). Verdicts:

| Platform | Verdict |
|---|---|
| **Amazon Connect (+AWS)** | ✗ disqualified — no shared voice+SMS number, no agent iOS SDK, no MMS |
| **Telnyx** | ✅ **recommended** — one number voice+SMS+MMS, most CallKit-explicit iOS SDK, TwiML-compatible (TeXML), ~30–35% cheaper |
| **Twilio** | ✅ **runner-up** — equally native iOS SDK, deepest ecosystem + clearest ISV 10DLC path; ~30% pricier |
| Bandwidth | best porting/wholesale, but **CallKit only in sample app, PushKit undocumented** — weak as the app SDK |
| Vonage | native whisper/barge primitive, but **Subaccounts (white-label) Beta-gated, no confirmed self-serve porting API** |
| Plivo | native `coachMode`, but **`PlivoVoiceKit` stale (perpetual beta) + no porting API** |
| Sinch | solid SDK, but **no GA real-time STT, no whisper/barge, MMS via separate account, no group texting** |

Telnyx and Twilio pass every requirement either native or build-on-top, and both pass the **iOS Voice SDK (CallKit + PushKit)** row natively — the row that disqualifies the others for a per-rep softphone.

---

## Recommended stack: Telnyx (single provider)

**Native (configure, don't build):** one number voice+SMS+MMS (req 1) · per-call outbound caller-ID via per-call `from` (req 2) · iOS WebRTC SDK `TelnyxRTC` with documented CallKit+PushKit wiring (`answerFromCallkit`/`endCallFromCallkit`) [HIGH] · call control via REST **and TeXML** (TwiML-compatible — a deliberate off-Twilio migration on-ramp) · real-time transcription (`<Transcription>` + media-fork `<Stream>`) [MEDIUM-HIGH] · MMS · Numbers/Porting APIs [FLAG] · Managed Accounts for white-label [FLAG — confirm naming] · STOP/HELP auto-handling, E911, CNAM · **~30–35% cheaper** [HIGH].

**You build (but you were going to anyway):** strict sequential round-robin w/ persistent pointer (req 3) · hours/holiday/weekend rotation (req 4 — Connect's the only one giving this free) · **monitor/whisper/barge** from conference + participant control (req 5) — **named whisper/coach primitive is NOT verified on Telnyx [LOW/FLAG]; this is the one risk that could flip the pick to Twilio** · voicemail + AMD + transcription (req 8) · continuity-through-deal recording (req 6) · CRM-agnostic event layer (req 9) · multi-tenant model (req 11) · reporting (req 13).

**Runner-up — Twilio:** choose it if you weight **SDK maturity + docs + ecosystem** over cost. `TwilioVoice` iOS SDK + CallKit/PushKit equally native [HIGH]; Subaccounts white-label; **ISV A2P 10DLC API is the clearest path to register many tenant brands programmatically** [HIGH]. ~30% pricier (immaterial at this scale). Twilio = lower execution risk; Telnyx = lower cost + more vertically integrated.

---

## Reference architecture (iOS SwiftUI + Lambda + Postgres + Telnyx)

> [!key-insight] The biggest engineering unknown is NOT telephony
> It's the **iOS CallKit ↔ PushKit ↔ AVAudioSession ↔ WebRTC audio handoff.** No CPaaS hands you a turnkey CallKit class — you own `CXProviderDelegate` + `PKPushRegistryDelegate`. Budget the hardest time here; spike it in week 1.

- **Inbound voice [HIGH]:** customer → Telnyx number → API Gateway → Lambda call-control webhook → routing decision → **VoIP push via APNs** (`apns-push-type: voip`) → iOS wakes in `pushRegistry(_:didReceiveIncomingPushWith:)` → **immediately** `reportNewIncomingCall(...)` *and* hand payload to `telnyxClient.processVoIPNotification(...)`. **Apple rule [VERY HIGH]:** *fail to report a VoIP push to CallKit and the system terminates your app* (and eventually stops delivering VoIP pushes). Audio handoff: WebRTC in **manual audio mode** (`RTCAudioSession.useManualAudio = true`); start audio only in `provider(_:didActivate:)`, tear down in `didDeactivate`; Telnyx exposes `enableAudioSession`/`disableAudioSession`. Handle the "ended before push handled" race by reporting first, then ending async.
- **Outbound second line [HIGH]:** `CXStartCallAction` → `CXTransaction` → `CXCallController.request`; displayed handle = the business DID in `CXHandle`, independent of the rep's cellular number.
- **Inbound SMS/MMS [HIGH]:** **never use VoIP push for texts** (re-triggers the termination penalty). Use a **standard APNs alert push** + a **Notification Service Extension** (`mutable-content: 1`); MMS media is a URL fetched on thread open (4 KB push cap).
- **Strict round-robin (req 3):** Postgres `sales_rotation(org_id, position, user_id, active)` + `rotation_pointer(org_id, last_position)`; advance to next **active** rep preserving order, `SELECT … FOR UPDATE` on the pointer to avoid two leads grabbing the same rep; full cycle no-answer → missed-lead alert + voicemail. Persist pointer on answer (not "longest idle").
- **Continuity (req 6):** keep all deal calls/texts on the **same Telnyx number** routed through your call-control webhook so media never leaves the recorded/transcribed path — exactly what Connect can't do.
- **CRM-agnostic event layer (req 9):** normalize every telephony event into a canonical schema on an **EventBridge bus** (or SNS) → Postgres; CRM adapters (HubSpot now, own CRM later) **subscribe** — swapping CRM is a new subscriber, zero changes to the telephony core. Keeps integration inside the AWS/SOC-2 boundary.
- **Multi-tenant / white-label (req 11):** one Telnyx Managed Account (or messaging profile/number pool) per org; numbers, greetings, caller-ID, branding **resolve from Postgres per request** (`gt_org_theme` / `organizations.name`) — consistent with the de-hardcoding rule. No brand string in any greeting/SMS/push; number lifecycle (req 10) hooks into existing onboarding/offboarding.

---

## Compliance plan (run past counsel)

> [!warning] CT recording consent is the sharp edge
> **CT: treat as ALL-PARTY for phone calls.** Civil statute §52-570d requires all-party consent **OR** a recorded verbal notice at call start **OR** a periodic tone. NJ + OH are one-party. Mixed-state calls are legally unsettled (a two-party state can reach an out-of-state recorder — *Kearney v. Salomon Smith Barney*). **Recommendation: play a "this call may be monitored or recorded" disclosure at the start of every recorded call, all orgs/states** — the only posture safe across the CT footprint, and it also covers monitor/whisper/barge.

- **E911 [VERIFIED federal]:** interconnected VoIP must provide 911 with a validated dispatchable location (RAY BAUM'S). **You register/maintain a per-number emergency address** at provisioning (~$0.75–$1/mo per number).
- **10DLC A2P SMS [VERIFIED]:** register a **Brand (needs EIN) + Campaign** via The Campaign Registry through your CPaaS as CSP. **White-label = each tenant org needs its own Brand + Campaign**, registered programmatically (Twilio ISV A2P is clearest). Fees per tenant ≈ $4.50 brand + $15 + ~$41.50 vetting + ~$10/mo. **Review lead time ~10–15 days / 1–3 wks per tenant [FLAG]** — gates tenant go-live; start at contract signature.
- **CNAM [MEDIUM]:** optional, best-effort, terminating-carrier-dependent; ≤15 chars per number.
- **STOP/opt-out [VERIFIED]:** Twilio + Telnyx auto-handle STOP/HELP by default — leave on; honor opt-out ≤10 business days.
- **TCPA outbound sales [VERIFIED]:** marketing calls/texts to wireless need **prior express written consent**; scrub National DNC ≤31 days; internal DNC 5 yrs; call only 8a–9p called-party-local; exposure **$500–$1,500/message**. FCC "one-to-one consent" rule **vacated** (11th Cir., Jan 24 2025) — not bound, watch for re-proposal. State mini-TCPAs (CT/NJ/OH) add rules — **confirm with counsel [FLAG].**

---

## Cost model (~36 users, low inbound, moderate texting)

Live-verified 2026-06-22; re-verify before procurement.

| | **Telnyx (rec.)** | **Twilio** |
|---|---|---|
| Monthly recurring (40 numbers, 3k voice min, 3k SMS, ~200 MMS, transcription ~80%, 1 10DLC campaign) | **~$130–$145** | **~$190–$200** |
| One-time 10DLC setup (per brand) | ~$61 | ~$61 |

**Takeaway:** the ~$60/mo delta is **noise** next to engineering build cost — choose on SDK fit and feature risk, not per-minute price. (Connect ≈ $135–$160/mo for *voice + analytics only* and still no native texting.)

---

## Risks (ranked — validate before committing engineering time)

1. **iOS CallKit/PushKit/WebRTC audio handoff** [highest] — spike `TelnyxRTC` + CallKit + a real VoIP push ringing a *killed* app with clean audio in **week 1**.
2. **Telnyx whisper/barge primitive** [high] — named coach/whisper **unverified** [LOW]; if undeliverable and unbuildable, this flips the pick to Twilio.
3. **10DLC per-tenant onboarding lead time** [high] — 1–3 wks/tenant gates go-live; register one real tenant now to measure.
4. **Telnyx network ownership + private AWS connectivity** [medium] — central to the "keep it near AWS" thesis but not citation-confirmed this run [FLAG].
5. **CT recording-consent exposure** [medium] — get the disclosure flow right day one; counsel sign-off.
6. **Multi-tenant white-label account model** [medium] — Telnyx "Managed Accounts" naming/capabilities unverified [FLAG].
7. **Group texting parity with Dialpad** [low-medium] — confirm group MMS semantics or build fan-out threading.

---

## Phased rollout

- **Phase 0 — De-risk (1–2 wks):** iOS spike (#1); register one real 10DLC brand to measure lead time; confirm Telnyx whisper/barge + Managed Accounts. **Gate:** if the iOS spike or whisper/barge fails → re-decide (Twilio) before building further.
- **Phase 1 — MVP (Gunner single tenant):** per-rep numbers (voice+SMS+MMS); in-app PSTN calling via CallKit; 1:1 SMS/MMS (APNs alert + NSE); per-call origination switch (req 2); recording + consent disclosure (req 6/12); event-layer logging → Postgres (req 9); E911 per number.
- **Phase 2 — Dialpad parity:** strict round-robin + missed-lead alerts (req 3); hours/holiday rotation (req 4); voicemail + transcription (req 8); group texting (req 7); manager reporting (req 13); HubSpot adapter on the event bus.
- **Phase 3 — Differentiators:** real-time transcription + keyword alerts (req 5); live monitor/whisper/barge w/ RBAC (req 5); multi-tenant/white-label rollout + ISV 10DLC auto-registration in onboarding (req 10/11); swap-ready own-CRM adapter.

**Dialpad port/cutover:** stand up new temp Telnyx numbers and run **in parallel**; submit Dialpad port-out (account/PIN + recent bill + matching address; ~1–3+ wks, batch not big-bang); **pre-register 10DLC before the port** (the long pole); on FOC date numbers move to Telnyx, same business-card numbers — no customer-visible change; keep Dialpad live until every number is confirmed.

---

## Relationship to existing Dialpad → HubSpot work

> [!note] Evolution, not contradiction
> [[gunnerteam/dialpad-hubspot-integration]] (2026-04) deliberately **ruled out replacing Dialpad** — the problem then was *call/SMS logging reliability*, "solvable in days with a webhook receiver," not telephony. This research is a **later, broader initiative**: a strategic **full Dialpad replacement** with an owned in-app softphone (voice+text on the same business-card number). The two are complementary on a timeline: the **webhook bridge is the near-term logging fix**; the **softphone is the strategic replacement**. The new doc also **supersedes** the old "Why Not Amazon Connect" note with a far deeper, AWS-verbatim disqualification (shared voice+SMS number is unsupported).

---

## Open / flagged for fresh verification

Blocked by a session-wide fetch limit, none change the core recommendation: Telnyx network-ownership + private AWS interconnect · Telnyx named whisper/barge primitive · Telnyx Managed Accounts naming · Twilio group-MMS / `<Record transcribe>` current status · exact 10DLC throughput tiers + current review lead time · CNAM cost/propagation · CT/NJ/OH state mini-TCPA specifics · Vonage CallKit/PushKit specifics.

## Source

`~/Documents/Claude/Projects/Gunner Team App/VOIP-Platform-Research.md` (prepared 2026-06-22). Primary docs read: docs.aws.amazon.com/connect + /sms-voice; twilio.com/docs + pricing; developers.telnyx.com + pricing; developer.apple.com (pushkit/callkit/usernotifications) + App Store Review Guidelines; eCFR 47 CFR §9.11/§9.16, 47 CFR 64.1200, 18 U.S.C. §2511, CT §52-570d.
