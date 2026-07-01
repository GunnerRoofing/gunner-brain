---
type: runbook
title: GunnerTeam — SubPortal Track 1 — Onboard Real Sub Crew
created: '2026-06-30'
updated: '2026-06-30'
tags: [gunner, gunnerteam, runbook, subportal, onboarding]
status: stable
source: Gunner Team App/runbooks/subportal-track1-onboard-real-sub-runbook-2026-06-30.md
related: ["[[gunnerteam/gunnerteam-project-structure]]", "[[index]]"]
---

# SubPortal Track #1 — Onboard a Real Sub Crew (dev)

_2026-06-30 · CONFIDENTIAL · target: gunnerteam-dev-api (Lambda live alias, v424) · masterdb = prod cluster `sczazkvf` (gt_* live there even in dev)_

Goal: put one real subcontractor crew through the shipped Phase 1 path end-to-end so field-UX
issues surface before prod cutover (track #2). This is the prerequisite for prod.

**Code state: verified 2026-06-30.** All seven Phase 1 components match the kickoff description
(table, role gate, server-derived crew feed, invite→crew link, HMAC+dedup webhook, sub-scoped
photo key, homeowner-phone omission). One deny-by-default gap found — see §5. Nothing else blocks
onboarding.

Constants used below:
- Gunner org_id: `69aad261-347c-44db-8e9e-6c25a8509aa3`
- Dev API base: `https://api-dev.team.gunnerroofing.com`
- Lambda log group: `/aws/lambda/gunnerteam-dev-api`
- Cognito pool: `us-east-2_hFVBSrcnn`

---

## 1. Ownership split — who does what

| # | Step | Owner | Surface |
|---|------|-------|---------|
| A | Create a real crew + crew_member; return `crew_id` (+ `crew_member_id`) | **Colin** | GunnerCam |
| B | Invite the sub (`role=subcontractor` + `crewId`) | **Tyler** | app / API |
| C | Sub accepts invite, sets password, logs in, registers device | **Sub (real person)** | iOS app |
| D | Assign the crew to a **live** project | **Colin** | GunnerCam |
| E | Verify feed / photos / points / assignment push | **Tyler** | app + our-side queries |

Sequence is strict: A → B → C → D → E. D must come after C or the assignment push has no device to
hit (`notified=0`).

---

## 2. Step-by-step

### A. Colin — create the crew (GunnerCam)
Draft ask is in §4. You need back from Colin, for the dev environment:
- `crew_id` (uuid) — goes in the invite.
- `crew_member_id` (uuid, optional) — secondary mapping; store it if provided.
- Confirmation the crew exists in the **same GunnerCam env the sub-scoped key points at** (dev).

### B. Tyler — invite the sub
`crewId` is required for subcontractor invites (400 otherwise). Use a real device-holding person.

```bash
# Cognito ID token for an admin (requireAuth reads email + custom:tenantId)
# ADMIN_USER_PASSWORD_AUTH; complete MFA challenge if prompted.
TOKEN=<admin Cognito ID token>

curl -sS -X POST https://api-dev.team.gunnerroofing.com/auth/invite \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "role": "subcontractor",
    "email": "<sub-email>",
    "firstName": "<first>",
    "lastName": "<last>",
    "crewId": "<crew_id-from-Colin>",
    "crewMemberId": "<crew_member_id-or-omit>"
  }'
```

Expect `200`. Then verify the invite row (§3-B) before telling the sub to check email.

### C. Sub — accept + log in + register device
The invite email → accept-invite → set password (Cognito). Sub then logs into the **GunnerForms
app** and lands on the gated shell (Jobs + More, points via the logo, Gunner Assistant). Logging in
registers the APNs device token. Confirm with §3-C — **do not proceed to D until a push_token exists**,
or the assignment fires `notified=0`.

### D. Colin — assign the crew to a live project (GunnerCam)
This is the real in-app assignment that fires `project.crew.assigned`. Pick a genuinely live job so
the feed has real content. On assignment the webhook fans out a push to the sub's device.

### E. Tyler — verify (see §3-D/E/F)
Feed shows only this crew's jobs, photos render, points accrue, and the assignment push landed with
`notified>0`.

---

## 3. Server-side verification queries

Run read-only against masterdb (prod cluster `sczazkvf` — where gt_* live). Use your usual in-VPC /
bastion tunnel + `~/.pgpass`; **read-only, no DDL, no role/proxy changes** (shared cluster → any
mutation routes through Colin). `$ORG` = `69aad261-347c-44db-8e9e-6c25a8509aa3`.

**B. Invite created (after step B)**
```sql
SELECT email, role, crew_id, crew_member_id, used, expires_at
FROM   invite_tokens
WHERE  email = '<sub-email>' AND org_id = '69aad261-347c-44db-8e9e-6c25a8509aa3'
ORDER  BY created_at DESC LIMIT 1;
-- expect: role=subcontractor, crew_id = Colin's value, used=f, expires_at in future
```

**C-1. Crew link created (after sub accepts, step C)**
```sql
SELECT sc.user_id, sc.crew_id, sc.crew_member_id, u.email
FROM   gt_subcontractor_crew sc
JOIN   users u ON u.id = sc.user_id
WHERE  u.email = '<sub-email>'
  AND  sc.org_id = '69aad261-347c-44db-8e9e-6c25a8509aa3';
-- expect: exactly one row; crew_id matches the invite; used flips to t on invite_tokens
```

**C-2. Device registered (gate before step D)**
```sql
SELECT d.platform, (d.push_token IS NOT NULL) AS has_token, d.updated_at
FROM   user_devices d
JOIN   users u ON u.id::text = d.user_id
WHERE  u.email = '<sub-email>' AND d.platform = 'apns';
-- expect: >=1 row with has_token = t. If none: sub hasn't logged in / granted push. STOP.
```

**D. Assignment webhook fired + push count (after step D)**
```sql
SELECT delivery_id, event_type, created_at
FROM   gt_webhook_deliveries
WHERE  event_type = 'project.crew.assigned'
ORDER  BY created_at DESC LIMIT 5;                 -- confirms dedup row landed
```
```sql
-- notified count is audited without PII (crewId + projectId + notified)
SELECT action, metadata, created_at
FROM   audit_log
WHERE  action = 'webhook.project_crew_assigned'
ORDER  BY created_at DESC LIMIT 5;
-- expect: metadata->>'notified' >= 1 and crewId = Colin's value
```
Cross-check the live handler in logs:
```bash
aws logs filter-log-events --region us-east-2 --profile mfa \
  --log-group-name /aws/lambda/gunnerteam-dev-api \
  --filter-pattern '"project.crew.assigned"' \
  --start-time $(( ($(date +%s) - 900) * 1000 ))
# 200 with notified:N; a 401 = HMAC/secret mismatch; notified:0 = no device (redo C).
```

**E. Feed scoping sanity (optional, from the sub's token)**
Hit the feed as the sub and confirm only their crew's jobs return — the crew_id is server-derived
(`subCrewIdForUser`), so a tampered client value can't widen it, but confirm the count matches what
Colin assigned:
```bash
SUBTOKEN=<sub Cognito ID token>
curl -sS https://api-dev.team.gunnerroofing.com/fieldportal/jobs \
  -H "Authorization: Bearer $SUBTOKEN" | jq '.jobs | length, .jobs[].id'
```

**Points** accrue through the normal `/points` path (allow-listed for subs) — verify in-app on the
sub's profile after they complete a points-eligible action; no special query needed.

---

## 4. Draft ask to Colin (GunnerCam)

> **Subject: Real sub crew for SubPortal dev end-to-end**
>
> Colin — ready to run the first real subcontractor through Phase 1 on **dev**. Two things from you
> in the GunnerCam **dev** environment (the one `FIELD_PORTAL_SUBCONTRACTOR_API_KEY` points at):
>
> 1. **Create a real crew + one crew_member.** Send me back the `crew_id` (uuid) and, if you model
>    it, the `crew_member_id` (uuid). I store `crew_id` in our invite so the sub's app account maps
>    to that crew.
> 2. **Hold off assigning** the crew to a project until I confirm the sub has logged in and
>    registered a device (I'll ping you — otherwise the assignment push has no device to hit). Then
>    assign the crew to a **live** job via the normal in-app assignment so `project.crew.assigned`
>    fires.
>
> No secret/schema changes needed — just the crew creation + the assignment when I give the go.
> I'll verify the feed, photos, points, and the assignment push on our side.

---

## 5. Code-gap report

Full verification found the shipped code matches the kickoff on all seven components. **One
deny-by-default gap** worth a decision before a real sub is loose in the app:

**Receipt endpoints are reachable by subcontractors.**
`POST /fieldportal/jobs/:jobId/receipt/extract` and `.../receipt/commit`
(`src/routes/fieldportal.js:1752, :1824`) are guarded by `requireAuth` only — no role check. Because
they sit under `/fieldportal`, which is in `SUBCONTRACTOR_ALLOWED` (`src/middleware/auth.js:8-15`), a
subcontractor token can hit them. `commit` writes `gt_receipts` + line items and best-effort pushes
cost/credit lines to Colin's P&L (`pushReceiptToColin`). That's a financial write path against a
job, exposed to an external principal.

Everything else is solid: `/users`, `/forms`, `/fleet` return 403 at the middleware for subs;
homeowner phone is never sent (`fieldportal.js:667`, share-sheet enum only); the crew feed and photos
are server-scoped by the derived `crew_id` with the sub-scoped key.

Decision needed — is a sub *meant* to log receipts against a job?
- **If no (likely):** add an explicit subcontractor deny on the two receipt routes. Small, isolated
  cc-prompt; I'd claim the lowest free CC-PROMPT block and write it (audit-hardened: role check
  returning 403 before any write, plus a guard test). Recommend doing this **before** the real sub
  logs in.
- **If yes:** leave as-is, but document the intent so it isn't flagged again in the next audit.

No other gaps block track #1.

---

## 6. Exit criteria (track #1 done → unblocks track #2 prod cutover)

- [ ] Crew link row exists, `crew_id` matches invite (§3-C1)
- [ ] Sub device registered with APNs token (§3-C2)
- [ ] Sub feed returns only the assigned crew's jobs (§3-E)
- [ ] Crew-filtered photos render in-app
- [ ] Points accrue on a sub action
- [ ] Real assignment fires `project.crew.assigned` with `notified >= 1` (§3-D)
- [ ] Receipt-endpoint decision made (§5)
