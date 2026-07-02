---
title: Completed IT Projects
type: gunner
tags: [projects, history, gunner, timeline]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [IT_Tasks_1775773048.xlsx, Tyler Suffern - Performance Review 2026.docx]
related: ["[[gunnerteam/environment]]", "[[ciso-track/roadmap]]", "[[vendors/hexnode]]", "[[vendors/keeper]]", "[[vendors/knowbe4]]"]
---

# Completed IT Projects

Organized by epic/initiative. All tasks marked Done. Source: Monday.com IT Tasks board. Approximate date range: Nov 2025 – Apr 2026.

---

## Stamford Network Enhancement

**Goal:** Upgrade HQ network infrastructure to Unifi 2GB.

| Task | Notes |
|------|-------|
| Setup UniFi router in Stamford | Called Optimum, put modem into bridge mode, connected UDM, configured Unifi |
| Investigate 2GB Optimum delivery | Resolved — network running at 2GB |
| Enroll warehouse AP | Additional access point added |
| Static IPs for printers | Printers assigned static IPs |
| Get access to front door | Physical access sorted |
| Rhombus camera not working | Resolved |

**Result:** Stamford HQ running Unifi 2GB with Cat6a, centralized server, warehouse AP enrolled, static printer IPs.

---

## NJ Office Network Build-Out

**Goal:** Stand up a full managed network at the NJ office.

**Equipment ordered (authorized by [[entities/Eddie Prchal|Eddie Prchal]]):**
- UXG-Pro (Unifi Gateway Pro)
- USW-Pro-48-PoE (48-port managed PoE switch)
- 3× U6-Pro (WiFi access points)
- Mac Mini (management/server)
- UPS, PDU, Rack, Mac Mini shelf
- Owl conference room camera (brought from another location)

| Task | Notes |
|------|-------|
| NJ network analysis | Equipment spec'd and ordered |
| NJ infrastructure build | UPS, PDU, rack, Mac Mini shelf sourced |

---

## Google Chat Migration (Slack Replacement)

**Goal:** Replace Slack with Google Chat company-wide.

| Task | Notes |
|------|-------|
| Delete Slack from all laptops/phones | MDM-pushed removal |
| Add everyone as direct members to Google Groups | Critical — ensures all-staff reach |
| Make chart of Google Groups | Documentation |
| Change group names (Gunner_all → all_gunner, etc.) | Standardized naming convention |
| Finalize Spaces list for Google Chat | Chat structure finalized |
| Google Business Reviews → Google Chat (CT) | Automated notifications |
| Google Business Reviews → Google Chat (Cromwell, NJ) | Extended to additional locations |
| HubSpot → Google Chat notifications | Automated via Make.com |
| Monday completed tasks → Google Chat | Automated via Make.com |
| Send IT Request to Google Chat | Automated |
| Send email to IT requester when Done | Automated notification loop |
| Google Chat CarPlay | Configured for hands-free use |

**Result:** Full Slack removal, Google Chat live company-wide, automated notifications from HubSpot, Monday, Google Reviews, and IT request system.

---

## Hexnode MDM

**Goal:** Full MDM enrollment and policy deployment across all devices.

| Task | Notes |
|------|-------|
| Hexnode phone policies — go live | iPhone CIS IG1 policy deployed |
| Contactzilla deployment | Company-wide phone directory pushed via MDM |
| Add Gemini to Hexnode catalog | Google Gemini added to iOS app catalog |
| Finalize bookmarks bar | Chrome bookmarks standardized via policy |
| Leslie MDM | Individual device issue resolved |
| Contact list within Dialpad — research | Investigated Dialpad contact sync options |

---

## Keeper — Mandatory Password Manager Rollout

**Goal:** Make Keeper mandatory, import all passwords, rotate critical credentials.

| Task | Notes |
|------|-------|
| Build out Keeper | Initial setup and configuration |
| Send Keeper project email to management | Stakeholder buy-in |
| Send Chrome → Keeper password import guide | User-facing guide distributed |
| Check if passwords were imported | Verified adoption |
| Noncompliant users reported to Oscar | Non-adopters escalated to HR (Oscar — former HR, no longer at Gunner) |
| Create how-to presentation for Keeper | Became Keeper Workshop.pptx |
| Change all admin passwords in Keeper | Admin credential rotation complete |
| Change andrew@ GAF QuickMeasure password | Shared credential remediated |
| Audit accounts | SaaS permissions audited across tools |

**Result:** Company-wide Keeper adoption. All admin passwords rotated. Shared credentials remediated. Keeper Workshop delivered.

---

## Email Domain Security

**Goal:** Harden gunnerroofing.com email security.

| Task | Notes |
|------|-------|
| Set up DMARC | Dec 3, 2025 — DMARC configured |
| Get into Sendgrid through Becky | Sendgrid access obtained for transactional email management |

**Result:** DMARC, SPF, DKIM all configured. Sendgrid access established.

---

## KnowBe4 — Phishing Program

**Goal:** Deploy phishing simulation program.

| Task | Notes |
|------|-------|
| KnowBe4 slideshow | Proposal/approval presentation built |
| Create Gunner phishing attacks | Custom roofing-specific phishing templates created |
| Phishing training | Training deployed |
| Phishing button template — sent weekly for 6 weeks | Sustained campaign |
| Check who finished cybersecurity training | Completion tracked |
| Sign up phishing failures for training (Mikayla) | Failed clickers enrolled in remedial training, tracked in Monday |

**Result:** Active phishing simulation program running. Custom templates in use. Failure tracking and remedial training pipeline in place.

---

## New VoIP Provider Evaluation

**Goal:** Evaluate whether to replace Dialpad due to service issues.

| Task | Notes |
|------|-------|
| Find another VoIP (Critical) | Full market audit conducted |
| A2P registration for test numbers | Compliance requirement addressed |
| Leslie, John Miller, Pam, Roger Dialpad issues | Individual user issues resolved during evaluation |
| GoTo → HubSpot integration | GoTo tested as alternative; integrated with HubSpot during evaluation |

**Result:** Stayed with Dialpad. The audit provided leverage to resolve service issues. RingCentral was also briefly tested but eliminated. GoTo evaluated but not selected.

---

## IT Documentation & Governance

**Goal:** Build out formal IT documentation.

| Task | Notes |
|------|-------|
| Communications Manual | IT Communications Style Guide (IT-SOP-COMMS-001) written |
| CMMC presentation | Federal market feasibility analysis delivered to leadership |
| Move IT requests to Monday Dev board | IT ticketing centralized |
| Build IT Monday Dev board | Automated request forms built |
| Update IT request form | Improved intake form |
| Format IT request response email | Standardized response templates |
| IT POC handoff | Point-of-contact documentation completed |
| Look into recurring tasks from IT task list | Recurring task automation reviewed |
| Add job titles in Google | Directory hygiene |

---

## Google Drive Cleanup

| Task | Notes |
|------|-------|
| Marketing's Google Drive | Organized and cleaned up |

---

## Infrastructure Miscellaneous

| Task | Notes |
|------|-------|
| Access Owl necessity? | Evaluated — Owl deployed to NJ conference room |
| Parallels for Mac Mini | Windows virtualization on Mac Mini configured |
| Add work phones as recovery phone — Google | MFA recovery numbers updated |
| Add all contacts to departments in Dialpad | Dialpad directory organized |
| Add work phones as Google recovery | Security hardening |
| Bulk email signature | Company-wide email signature standardized |
| Research fleet management solutions | Whip Around evaluated extensively — did not meet requirements; no solution selected. **Open need — fleet management remains unresolved.** |

---

## Recurring IT Support Themes

Patterns observed from the support ticket log (Nov 2025 – Jan 2026):

| Issue | Frequency | Resolution |
|-------|-----------|-----------|
| Microsoft Office crashes (Word/Excel) | High — multiple users across Sales, Operations | **Resolved via Hexnode** — MDM policy fixed the root cause; no longer an active issue |
| GAF QuickMeasure access issues | Medium — shared credential friction | Credentials rotated to Keeper; individual accounts |
| Dialpad service issues | High — critical priority | Resolved; VoIP audit provided leverage |
| Printer issues | Medium | Resolved case-by-case (static IPs helped) |
| Keeper password fill not working | Low | User education |
