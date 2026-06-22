---
type: reference
owner: colin
app: GunnerCam
created: 2026-05-07
updated: 2026-05-07
tags: [wl-companycam, user-guide]
status: active
---

# User Guide (distilled)

Source: `~/repos/WL-CompanyCam/USER_GUIDE.md`

## Sign-in

- Any URL except `/login` redirects to sign-in.
- Cognito returns ID/access/refresh tokens → stored as HTTP-only cookies (`ccam_id`, `ccam_access`, `ccam_refresh`).
- Server resolves `sub` claim → `users` row → `corporation_id` + `role` decide visibility.
- Lands on `/projects`.
- Sign out calls Cognito `GlobalSignOut`, clears cookies, returns to `/login`.

**Seeded dev login:** `colin.wong@gunnerroofing.com` / `TestPass123!`

Other seeded test accounts (from `scripts/provision-test-users.mts`):

| Login | DB user | Table |
|---|---|---|
| sarah.gengo@gunnerroofing.com | sgengo | users |
| joe.massari@gunnerroofing.com | jmassari | users |
| zach@roofforce.example | zwebb | crew_members |
| dawn@roofforce.example | dlavia | crew_members |

## Projects list (`/projects`)

- Sorted by last-updated, newest first.
- Filters: All/Starred tabs · case-insensitive search on customer + address.
- Shows: name + customer + address · star · up to 3 colored labels (+N chip) · last-updated relative time · assignee avatars (PM, sales, crew) · photo/file counts.
- Visibility: admin/manager → all in corp; standard → only `project_users` assigned; crew member → only via `project_crews`.
- New Project button (top right): name required; customer/address/phone/email/status optional.

## Project detail (`/projects/<id>`)

Header card: thumbnail · customer + address · status pill (clickable; admin/manager/PM only) · labels · phone (tel:) + email (mailto:) · stacked avatars per role (PM, Sales, Estimator, crew) with +N overflow.

**Manage assignments** (admin only): add/remove users (with role on project) and crews. Each add writes an `assignment` event into the activity feed.

Tabs:

- **Activity** — single source of truth, reads from `updates` table joined to payload, grouped by `bucket_day` (America/New_York). Mixes photo events, comment events, file events, system events (status changes, assignments). Each day has an inline comment composer at the bottom. Two most recent days expanded by default.
- **Photos** — day-grouped grid. Each photo served via 1-hour presigned GET URL. Crew uploads get a *crew* badge.
- **Comments** — reverse-chrono list. ⌘/Ctrl+Enter to post.
- **Files** — same upload flow as photos but any content type. Click row → presigned GET in new tab.

**Lightbox:** fullscreen photo view, arrow-key nav, Escape closes. Right rail shows captured time, uploader, "n of N." Photo-level comments and tags are V2.

## Photo upload flow

1. Click Choose Files / drag-drop (HEIC, JPG, PNG, WEBP up to 25 MB; multi OK).
2. `POST /api/uploads/presign` → presigned PUT URL.
3. Browser PUTs bytes direct to S3.
4. `POST /api/photos` confirms upload — inserts photo row + paired `updates` row in one transaction.
5. Page refreshes, photo appears under Today.

Mobile: **Take Photo** button uses `<input capture="environment">`.

## Admin · Users (`/admin/users`)

Admin-only (sidebar hidden otherwise; direct visit redirects).

- Table: avatar, name, username, email, project assignment count, role.
- Invite form: first/last/username/email/role.
  1. `AdminCreateUser` with `MessageAction=SUPPRESS` (no email).
  2. Server-side temp password, set as **permanent** so no `NEW_PASSWORD_REQUIRED` flow.
  3. Insert into `users` with returned `sub`.
  4. Temp password is shown in a one-shot modal — copy + share out-of-band.
- Change role dropdown: `PATCH /api/admin/users/<id>` (standard / manager / admin / restricted).

## Admin · Crews (`/admin/crews`)

Crews are subcontractors — cross-tenant in `crews` table, linked to corp via `corporation_crews`.

- Crew list: name, contact, member count.
- Add Crew form (creates `crews` row + `corporation_crews` link in one transaction).
- Crew detail (`/admin/crews/<id>`): list members, add member (lands in `crew_members`, not `users`; same one-shot temp password modal).

Crew members signing in bridge to a `Principal` of type `crew_member` and only see projects whose `project_crews.crew_id` matches.

## Status meanings

`Lead` (no quote) · `Sold` (contract signed) · `Scheduled` (crew booked) · `In Progress` (tear-off started) · `Completed` (final inspection passed) · `On Hold` (paused) · `Lost` (cancelled / chose another roofer).

No enforced state machine — any → any. Each transition writes a `status_change` event.

## Roles cheat sheet

| Role | Sees | Can do |
|---|---|---|
| Admin | all in corp | everything |
| Manager | all in corp | change status; manage assignments; comment; upload |
| Standard | only assigned | change status only on projects where they're PM; comment; upload |
| Crew member | only their crew's projects | comment; upload (no status change, no admin) |
| Restricted | reserved V2 | (read-only) |

## Known UX gaps documented

- Photos served full-size (no variants) — slow on cell at job sites.
- Sessions die after 1 hour (refresh-token rotation not wired).
- No realtime — refresh page to see new events.
- Temp password modal is one-shot — re-invite if dismissed.
- Photo-level comments + tags + GPS map view are all V2.
