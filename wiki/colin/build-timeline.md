---
type: reference
owner: colin
app: GunnerCam
created: 2026-05-21
updated: 2026-05-21
tags: [wl-companycam, timeline, history]
status: active
---

# Build Timeline

The story of WL-CompanyCam / Gunner Project Hub as it was actually built across Claude Code sessions, **2026-05-05 → 2026-05-21**. Synthesized from 117 repo sessions (see the session catalog for the raw index). Roughly three weeks from a meeting recording to a multi-tenant app deployed on AWS with an external API.

---

## May 5 — Requirements, from a meeting (in `~/repos`)

It started with a recorded meeting with the Gunner team (`Halloween Blvd.m4a`), transcribed via **Gemini 2.5 Pro** on 2026-05-05. That transcript becomes the source of truth pasted into many later sessions. From it Colin wrote up an agile-style spec and a sequence of tickets, sketched an address/data structure, and explored the UI with Claude design files. Two anchors set here: **build on AWS** (the boss kept mentioning S3) and the **endgame is to sell this as a service**.

## May 6 — Scaffold, infra, MVP shell

The `WL-CompanyCam` repo proper begins. Big day, ~18 sessions:

- **Next.js 16 App Router** scaffolded. Auth started on Clerk, then switched to **AWS Cognito**.
- `DECISIONS.md` created as the living architecture log.
- **AWS RDS Postgres 16** provisioned (us-east-2, public + IP-restricted SG) → `DATABASE_URL`.
- **S3 bucket + IAM** for photo/file storage via presigned URLs (bucket stays private).
- **Drizzle** DB layer wired; first CRUD loop — Projects list reads from DB, `/projects/new` form.
- **MVP UI** assembled: login, projects list, project detail (header card, status pill, label pills, assigned avatars, day-bucketed activity feed, photos grid, lightbox, comment composer), admin users.
- "Trim the fat" pass — removed messages, settings, payments, quote portal, Stripe; kept just enough to be usable.
- Banner image upload + remove; label editing; first HEIC-upload trouble noted.

## May 7 — Tests, notifications, labels, briefing the boss

- **Vitest** test suite written hard ("test everything"), including AWS-service tests.
- **Notifications system** + bell UI in the topbar.
- **Color-coded label presets** — a curated list of ~41 roofing labels (GAF Asphalt, CertainTeed Landmark, etc.) each with a hex color.
- Fixed starred projects; fixed HEIC images; pruned broken photos (S3 vs DB drift).
- Wrote `BOSS_BRIEFING.md`, `AGENTS.md`, `ARCHITECTURE.md`, `AWS.md` to make the codebase legible to a non-technical-but-schema-literate boss and to future LLM sessions.
- The claude-obsidian wiki domain for this project was first created on this day (the [[colin/index|WL-CompanyCam]] pages).

## May 8 — DocuSign, and a scale conversation

- **DocuSign** research and integration begins: a `src/lib/signing/` provider abstraction, `docusign.ts`, a signing webhook, and a signing button. (Sandbox is free; "Go Live" needs 20+ demo API calls.)
- A long-term thinking session: target a **50k-user cap**, find the simplest stable stack, keep AWS costs down.

## May 11 — Photo bundling + signing diagnostics

- **Photo bundling** — group photos uploaded close together (first "within 5 min", then "within an hour", clipping the bundle if someone interrupts with a message).
- DocuSign debugging tooling: `diagnose-signing`, `check-signatures`, `test-webhook`, `retry-docusign-webhook` scripts.
- Began researching cheaper DocuSign alternatives.

## May 12 — External API is born + domain rename

- The **external API contract** (`EXTERNAL_API_AI.md`) is written so a sister app can call in without reading the codebase. Permanent **integration API keys** (JWT). First external endpoints: projects, photos, presigned uploads. See [[colin/external-api-integration|External API Integration]].
- Dev domain renamed **`companycam.dev.gunnerroofing.com` → `project.dev.gunnerroofing.com`** via a Cloudflare CNAME.
- Activity feed gains **PDF document cards** and **comment threading** (comments can target a photo, a file, or another comment).

## May 13 — Comments UX, chasing CompanyCam

Heavy UI iteration, almost all screenshot-driven, with CompanyCam as the reference:

- Comments redesigned: a count **badge** per photo, a **chat log** that opens when you click into a photo, comments panel on the right.
- Replies UI reworked (sat next to the image).
- **Video preview thumbnails, an audio player, and in-page video playback.**
- Repeated "merge all the branches so I can `npm run dev`" consolidation.

## May 14 — Multi-tenant schema + signing & tasks tickets

A pivotal day:

- **Schema redesign** to a real hierarchy: a **company** sits above **offices**, with **managers** and **PMs** below, multi-tenant via `corporation_id`. Admin roles introduced.
- Signing tickets shipped: **T-1** notify the assigned user when a customer signs, **T-2** daily reminder while a form is unsigned, **T-3** a "Resend" button on change orders.
- **Tasks** feature begun: **T-4** create tasks on a project; **T-5/6/7** task reminders (push + email), My Day, mentions.
- **Change-order PDF generation** via `pdf-lib`.
- External photo/file comments endpoints. Test-data cleanup in the DB.

## May 15 — Signed-doc flow, API handoff to Tyler

- Debugged the **DocuSign return flow**: after a customer signs via email, the signed PDF should drop back onto the project (it wasn't, on the live site).
- Wrote API **handoff documents** and minted an integration key for **Tyler** so his app can read projects and add comments-on-comments.
- More DB test-value cleanup; sidebar redesign.

## May 17 — Tangent

A one-off, unrelated data-analysis session: estimating the true graduation rate of the Queens College CS program from a spreadsheet/PDF. (Lived in a WL worktree by accident; see Other Sessions.)

## May 18 — Documents system, deploys, a 72-turn marathon

The busiest day by volume:

- **Project side drawer** with a full **swivel animation** (whole page swivels, CompanyCam-style).
- **Document templates system**: Project Completion Certificate, Chimney Waiver, Material Return List — generated server-side with branding, plus a preview popup and signature workflow.
- Task-creation fields simplified per **Eric Recchia**'s feedback (Title, Notes, Due Date; drop assignee for self-serve).
- External API: **`commentCount` per photo** (GunnerTeam's P1, actively blocking them).
- `consolidate-actions-column` — a 72-turn session implementing a Claude-design file across the projects/admin UI.
- Merged branches and **`sst deploy`** to both dev and live; debugged a slow notifications endpoint.

## May 19 — Chat drawer, signatures, role hierarchy

- Project conversation **drawer made chattable** and full-screen.
- Resend button made obvious and correctly labeled.
- **Signature pad + field overlay**: the PM fills out a document's fields before sending for signature; preview shows the real document.
- **External project-level comments** API (not just photo comments).
- Deep design of the **role hierarchy**: super_admin (Gunner) → manager (per company, can be many) → PM (per project) → standard user.

## May 20 — Retire "admin", daily logs, AWS-login relief

- **`retire-admin-role`** — replaced the generic `admin` role with `manager`; offices became cosmetic.
- **Daily Logs** + **smart INSTALL badge** + **job-first "My Day"**: a PM logs each job daily as on-time / at-risk / late.
- Generated fresh **CompanyCam integration keys** for Tyler (after some keys were exposed by accident).
- **AWS login simplified** in `~/.zshrc` to stop doing `aws sso login` by hand every morning (see [[colin/gotchas|Gotchas]]).
- Learned the `ultrathink` vs `/effort max` distinction (both raise reasoning; setting effort max makes the inline keyword redundant).

## May 21 — Daily-log polish + masterdb migration

- Daily-log form fixed to open in-place (no redirect), percentage hidden from PMs (manager-only), template button removed; project permissions tightened.
- **`gunner-masterdb` migration** planned and started: fold the `gunner-ios` stack (the GunnerTeam app + `gunnerteam-api` + its hand-rolled Postgres schema) into a shared **master DB** that owns core/common tables across all Gunner apps.
- Confirmed task endpoints exist.

---

## Shape of the three weeks

- **Phases:** requirements (May 5) → infra + MVP (May 6–7) → signing & external API (May 8–15) → documents, multi-tenancy, tasks, daily logs (May 14–21).
- **Cadence:** burst days (May 6, 7, 14, 18, 20 each had 10–22 sessions) separated by quieter ones.
- **Method:** ticket-driven (T-1…T-7, `tickets/`, handoff specs), screenshot-driven UI, parallel worktrees later merged, browser-verified, `ultrathink` + `/effort max` throughout. See [[colin/gotchas|Gotchas]] for the friction and [[colin/feature-inventory|Feature Inventory]] for the resulting surface.
