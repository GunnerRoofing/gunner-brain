---
type: reference
owner: colin
app: GunnerCam
created: 2026-05-07
updated: 2026-06-21
tags: [wl-companycam, risks, ops, readiness]
status: active
---

# Operational Risks

Source: `~/repos/WL-CompanyCam` boss briefing §8. Ordered by likelihood × impact.

## Top five (will materially affect the system)

### 1. Shared dev/prod environment — WILL cause an incident
`.env.local` and the deployed Lambda both point at the **same** RDS instance and S3 bucket. A misdirected migration, seed run, or `DELETE FROM` will eventually hit prod data. **Fix:** split into two SST stages (`dev` and `production`) each with isolated RDS + S3 + Cognito. ~2–3 days work.

### 2. Bleeding-edge framework stack
Next.js 16 + OpenNext + SST is fragile. OpenNext already lags Next 16 features (see comment in `src/middleware.ts`). A future Next.js patch can break deploys. **Fix:** pin exact versions, add CI build check. ~1 day.

### 3. Database connection exhaustion
Connection pool is `max: 1` per Lambda. RDS `db.t4g.micro` accepts ~90 connections. Around **80 concurrent users → app down**. **Fix:** RDS Proxy (~$15/mo). ~½ day.

### 4. RDS storage fill-up
20 GB instance + soft-deletes that never purge + `updates` activity feed growing forever = fills in 6–18 months. RDS auto-scaling not confirmed enabled. **Fix:** enable storage auto-scaling. 30 minutes.

### 5. Region-level AWS outage
All in `us-east-2`. No multi-region. Annual exposure: a few hours when AWS has incidents. **Fix:** expensive multi-region setup; defer until SLAs demand it.

## Production operations readiness

As of 2026-06-21, the production ops/runbook surface is **not ready** (verified 2026-06-15). See [[colin/ops-deploy]] and [[colin/aws-infra]] for the deep treatment; the gaps:

| Gap | State as of 2026-06-21 |
| --- | --- |
| Runbook / README | README is still stock Next/Vercel boilerplate — no real runbook |
| Health route | Liveness-only; does not check DB/AWS/downstream dependencies |
| Production AWS surface | Alarms, WAF, Route 53, SQS not wired per `AWS.md` |
| User onboarding | Manual — Cognito invite emails are suppressed and permanent temp passwords are handed to staff directly (see [[colin/google-sso]]) |
| API key issuance | Script-created (`scripts/create-integration-key.mts`), not managed through an admin UI (see [[colin/external-api-integration]]) |

## Reliability gaps

| Gap | Impact |
| --- | --- |
| Webhooks are single-attempt | No retry queue — a transient downstream failure drops the event permanently |
| Task reminders stamp `sent` even on delivery failure | Failed reminders are silently marked delivered; no signal that a PM never got the nudge |

## Things that will degrade product

- **Orphan S3 files** — uploads that never get confirmed accumulate forever. No cleanup job. No unique constraint on `s3_key`. See [[colin/photos-uploads]].
- **Sessions die every hour** — refresh-token rotation not implemented; users get bounced to `/login` mid-day.
- **Unbounded photo size** — presigned PUT URL has no max-size policy.
- **No background workers** — blocks the photo variants pipeline, email invites, Quote Portal sync.
- **Photo originals served full-size** — slow on cell networks at job sites.

## Compounding tech debt

- No tests (in CI sense — Vitest exists locally, no CI runs it)
- No error monitoring (Sentry/Datadog)
- No audit log table — SOC 2 will need it
- `creator_name` / `author_name` denormalization drifts when users rename
- `projects.primary_pm_id` can drift from `project_users` join
- Cross-tenant isolation in app code only — no Postgres RLS

## Stale documentation / false alarms

- **Job ID search "gap" is stale (verified 2026-06-15).** `QA-CHECKLIST.md` claims Job ID search is missing, but the current project-list component already searches and displays `jobId`. The doc is out of date, not the product — remove the gap from the checklist.

## Open architectural calls (resolution unblocks risk fixes)

See [[colin/decisions]] §"Open decisions". The most operationally relevant are #1 (Postgres host: Aurora vs RDS — affects RDS Proxy approach) and #4 (S3 layout: prefix vs bucket-per-corp — affects tenant isolation rigor).

## Open questions / TODOs

- Wire the production ops surface per `AWS.md`: alarms, WAF, Route 53, SQS; replace the boilerplate README with a real runbook; extend the health route beyond liveness.
- Replace manual Cognito onboarding (suppressed invites + permanent temp passwords) and script-created API keys with proper admin-managed flows.
- Add a retry queue for single-attempt webhooks; stop stamping task reminders `sent` on delivery failure.
- Update `QA-CHECKLIST.md` to remove the stale Job ID search gap.

## Roughly

- ~3–4 weeks of focused ops work to graduate from "MVP that runs because nobody's pushing it" to "production system that can run unattended."
- ~1–2 months of feature work to get from "internal Gunner tool" to "sellable to customer #2" — branding, custom domains, billing, email invites, password reset, at least one differentiating integration.
