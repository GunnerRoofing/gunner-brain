---
type: session
title: "cc-prompts 76–80: Notion Workspace Build + SOC 2 Fixes"
created: 2026-06-02
updated: 2026-06-02
tags:
  - gunnerteam
  - notion
  - soc2
  - security
  - companycam
  - fleet
status: stable
related:
  - "[[meta/session-2026-05-27-cc38-45-cc69-75-fleet-perf-webhooks]]"
  - "[[gunner/gunnerteam-performance-standards]]"
  - "[[gunner/masterdb-architecture]]"
---

# cc-prompts 76–80: Notion Workspace Build + SOC 2 Fixes

---

## CLAUDE.md + Long-term Context (pre-session)

New rules absorbed from updated GunnerTeam `CLAUDE.md`:
- **Plan Before Code** — non-trivial changes need written plan + "go" before editing
- **`query()` for read-only routes with explicit `org_id`** — `queryWithTenant` for write paths (cc-03 rule formally superseded)
- **New Known Mistakes added:** pg numerics as strings, `forcePathStyle: false` on S3, no `Authorization` on presigned PUT, `MainActor.run` not `DispatchQueue.main.async`

`.claude/context/long-term/` scaffolded and committed (`dc71359`):
- `architecture.md` — stack, request flow, repo layout, DB schema, iOS auth model
- `decisions.md` — DEC-001–DEC-012; DEC-004 permanently documents the `query()` carve-out
- `conventions.md` — Node/Express + Swift patterns, security checklist
- `learnings.md` — 9 incident write-ups with root causes and exact fixes

---

## cc-prompt-76: SOC 2 Compliance Tracker in Notion

Created Notion database with all 35 compliance backlog items via `@notionhq/client@2`.

**Key finding:** `@notionhq/client@5` (latest) removed `properties` from `databases.create` bodyParams — a silent breaking change. Always pin to v2 for database creation scripts.

Database ID: `36eae826-910d-81a0-a72e-f5ef331e7df6`

---

## cc-prompt-77: Full Notion Workspace Build

Built the complete GunnerTeam Notion workspace under the SOC 2 page. One mid-run failure on `teal` color (not a valid Notion color — valid set: `default gray brown orange yellow green blue purple pink red`). Resumed cleanly from the Architecture section.

**Databases created:**

| Database | ID |
|----------|----|
| SOC 2 Compliance Tracker | `36eae826-910d-81a0-a72e-f5ef331e7df6` |
| Secrets Register | `36eae826-910d-8156-9780-d41d55b4d127` |
| Asset Inventory | `36eae826-910d-8102-974c-c4711bc8c3c7` |
| Risk Register | `36eae826-910d-819b-9b6d-df7b46f86557` |
| Integration Contracts | `36eae826-910d-8155-87b2-e7e334aedeb1` |
| Architecture Decisions | `36eae826-910d-8175-b703-e912d3cb192b` |
| Deploy Log | `36eae826-910d-8131-ac05-f65510952859` |
| Feature Backlog | `36eae826-910d-813f-afa4-f60a53a079ac` |

**Sections:** Security & Compliance, Architecture, Development, Policies (6 stub pages), Apps (3 stub pages).

**`scripts/notion-sync.js`** committed to GunnerRoofing/gunner-ios with commands:
- `deploy` — log a Lambda deploy with version + summary
- `feature` — update feature backlog item status
- `soc2` — mark SOC 2 item done + add evidence link
- `secret-rotate` — record rotation date on a secret

`scripts/notion-config.json` stores all database IDs (safe to commit — no secrets).

`terraform/lambda-api.tf` updated with `NOTION_TOKEN` SSM lookup + env var reference. SSM store pending MFA.

---

## cc-prompt-78: Tasks Database

Tasks database created under ⚙️ Development page. ID: `36eae826-910d-81f2-a2da-f845a1ceb173`

**21 tasks seeded** — 11 from the cc-78 spec + 10 from wiki vault audit:

Priority breakdown:
- **P0 — Now:** CompanyCam secrets rotation, close SSH port 22, deploy pending Lambda, run indexes migrations
- **P1 — Soon:** SSM Session Manager fix, APNs key inline env var, branch protection, Dependabot, Cloudflare scoped token, CI/CD, MFA audit, subportal S3 pipeline, NOTION_TOKEN in SSM, merge PR1, CompanyCam webhook smoke test, resolveUser cache, OneNote → Keeper rotation, masterdb cutover
- **P2 — Backlog:** Typed task checklist (Colin), APNs smoke test, SSP sign-off

`task` command added to `notion-sync.js`:
```bash
node scripts/notion-sync.js task \
  --name "Fix X" --who "Tyler" \
  --app "GunnerTeam API" \
  --priority "P1 — Soon" \
  --notes "..."
```

**Gap fill** (separate run) added to all sections:
- SOC 2: items #36–39 (4 new Phase 2 audit findings)
- Asset Inventory: Monday.com, Dialpad, Stripe, Make.com, KnowBe4, masterdb Lambda, gunner-ops FastAPI, subportal, gunner-masterdb repo
- Feature Backlog: masterdb platform, GunnerForms consolidation, Dialpad↔HubSpot, HubSpot UTM workflow, network segmentation
- Tasks: 8 new (cross-tenant token clear, doc ownership, RDS SSL, dedup order, Terraform lifecycle, Aurora timeout, backup vendor, fleet mgmt software)
- ADRs: masterdb as platform foundation, single cluster/multi-schema rationale
- Apps: masterdb — Platform Overview, GunnerForms — Legacy iOS Forms App

---

## cc-prompt-79: CompanyCam Webhook Org Scope (SOC 2 #36)

**File:** `gunnerteam-api/src/routes/companycam.js`

**Bug:** All three webhook handlers looked up users by email with no `org_id` filter. Latent cross-tenant data leak for tenant #2.

**Fix:** `GUNNER_ORG_ID = '69aad261-347c-44db-8e9e-6c25a8509aa3'` defined once at file top (line 14). All three queries updated:

```js
// Single-recipient (project.assigned):
WHERE u.email = $1 AND u.org_id = $2
params: [assignedUserEmail, GUNNER_ORG_ID]

// Multi-recipient (photo.comment.added, project.comment.added):
WHERE u.email = ANY($1::text[]) AND u.org_id = $2
params: [targets, GUNNER_ORG_ID]
```

Replace `GUNNER_ORG_ID` with per-tenant webhook routing when tenant #2 is provisioned.

Committed `0e0a0e8`. SOC 2 #36 marked Done.

---

## cc-prompt-80: Fleet Document Ownership Check (SOC 2 #37)

**File:** `gunnerteam-api/src/routes/fleet/index.js`

**Bug:** Two document view routes used `queryWithTenant` with no explicit `org_id` filter. Sequential integer doc IDs meant any authenticated user could enumerate documents across orgs.

**Fixed routes (both):**
- `GET /fleet/documents/:docId/view` (gt_vehicle_documents)
- `GET /fleet/other-docs/:docId/view` (gt_vehicle_other_documents) — same vulnerability, fixed in same commit

**Fix pattern:**
```js
// Before
await queryWithTenant(req.orgId,
  'SELECT ... FROM gt_vehicle_documents WHERE id = $1 AND active = TRUE',
  [docId]
);

// After
await query(
  // org_id explicit — belt-and-suspenders ownership check (SOC 2 CC6.1)
  'SELECT ... FROM gt_vehicle_documents WHERE id = $1 AND org_id = $2 AND active = TRUE',
  [docId, req.orgId]
);
await audit({ action: 'fleet.document.viewed', req, resource: `document:${docId}` });
```

`audit()` fires after ownership confirmed, before S3 fetch — creates audit trail for every document access.

Committed `d3495d2`. SOC 2 #37 marked Done.

---

## IT Email: Dialpad + HubSpot Call Logging

**Tier:** BLUE — Reminder  
**Audience:** Sales team only  
**Subject:** `[REMINDER] Dialpad + HubSpot Call Logging — What to Do When Calls Don't Post`

**Core message:**
1. Calls/texts must be made through Dialpad app to log in HubSpot — native cell dialer bypasses the integration
2. When reporting a logging issue, attach a screenshot from Dialpad's Recents/conversation view
3. Issues reported without a screenshot cannot be escalated to Dialpad/HubSpot support

Label set used: New Process / New Tool BLUE (WHAT'S CHANGING / WHY / WHAT YOU NEED TO DO / WHEN / WHERE TO GET HELP).

---

## Deploy State

- cc-76–80 changes all committed and pushed to `main`
- cc-79 + cc-80 deployed and live (Tyler confirmed traffic is live despite expired token on version number fetch)
- Pending MFA: NOTION_TOKEN SSM store, fleet/schedules indexes migrations
- Next cc-prompt: **46** (fleet) or as directed
