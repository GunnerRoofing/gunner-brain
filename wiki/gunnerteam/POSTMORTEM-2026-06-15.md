---
type: postmortem
owner: tyler
date: '2026-06-15'
created: '2026-06-15'
updated: '2026-06-15'
severity: high
status: resolved
tags:
  - incident
  - postmortem
  - rds-proxy
  - deploy
  - process
title: Postmortem 2026-06-15
---
# Incident Postmortem — GunnerTeam app outage & masterdb slowness (2026-06-15)

**Status:** resolved (fix staged; deploy pending source reconciliation) · **Severity:** high (app
unsusable for users — login, jobs, and points intermittently failed) · **Author:** Tyler Suffern

This is written so the team understands *why* we're moving to git-as-source-of-truth and a
change-management policy. The technical fixes mattered; the process failure underneath them mattered
more.

---

## Summary
Over ~2 days the GunnerTeam app intermittently failed to load — login spinning, jobs list blank,
the points hub erroring "couldn't load." It looked like one bug but was a stack of issues across the
database connection path, an upstream API, and — underneath all of it — **source/deployment drift**
from multiple parties changing one Lambda without a shared source of truth.

## Impact
- Field users couldn't reliably log in, see jobs, or view points.
- Hours of engineering time spent chasing the wrong layer (database capacity) before the real causes
  surfaced.

## Root causes
1. **Direct Lambda→Aurora connections (no proxy).** The backend connected straight to the cluster
   writer endpoint. On cold containers, connection *acquisition* stalled — ~1–2s warm, up to 20–25s
   cold — with no error, so the symptoms looked like flaky "connection" failures. Auth gates every
   request, so a slow connect stalled the whole app.
2. **RDS Proxy `SET LOCAL` pinning (once the proxy was added).** Our tenant-scoped reads use
   `SET LOCAL app.current_org_id` for RLS. RDS Proxy pins a connection on `SET` and can't multiplex
   it; with the pool keeping connections open, pins accumulated. The points hub fires four parallel
   tenant reads, exhausted the proxy's connection budget, and those reads hung indefinitely.
3. **Upstream `/projects` N+1 (Project Hub).** The project-list photo-summary query ranked every
   photo to return the latest few, spiking to ~25s under real traffic and timing out the jobs list.
   (Fixed by the Project Hub team with a set-based query + indexes.)
4. **Source/deployment drift — the underlying cause.** Three parties were shipping to the same live
   Lambda: this engineer (via Cowork cc-prompts), a concurrent automated session (which added a
   timing/retry wrapper and a HubSpot pull), and the Project Hub maintainer (who patched the deployed
   Lambda directly for RDS-Proxy compatibility). None of these were fully captured in git. Result:
   mystery code in production, an inability to deploy safely (any deploy would clobber someone's
   change), and repeated regressions.

## Contributing factors
- **Config drift:** SSM `/.../DB_HOST` pointed at the *dev* cluster while the live Lambda actually
  ran in the prod VPC against the *prod* cluster. This sent us tuning the wrong database — ACU bumps
  on a cluster the app never used — wasting time and money.
- **Low Serverless v2 floor (0.5 ACU)** on the dev cluster reinforced the cold-resume theory and
  masked that the proxy/connection path was the real issue.

## Resolution
- Project Hub `/projects` N+1 fixed (set-based query + indexes) — jobs load fast again.
- masterdb fronted by a dedicated **RDS Proxy** in the correct (prod) VPC; `DB_HOST` repointed at the
  proxy; pg pool made proxy-safe (no `statement_timeout` startup option, `DB_CONNECT_TIMEOUT_MS=5000`)
  — deployed as v233.
- Points read endpoints converted off `SET LOCAL` to explicit-`org_id` `query()` so the proxy can
  multiplex them (staged).
- Dev cluster ACU restored to its baseline (it isn't used by the app).

## Corrective actions (process)
|Action|Why|
|---|---|
|**Git = single source of truth**; deploy only from reviewed `main`|Eliminates the drift that caused the outage|
|**Change-Management Policy** (PR review, no direct prod edits, audit trail)|Makes changes traceable and reviewable (SOC 2)|
|**Reconcile live v233 into git** before the next deploy|Recover the changes only present in production|
|**Capture proxy / SG / IAM / `DB_HOST` in IaC**|No more out-of-band infra|
|**Claude Code rules onboarding** for all contributors|Everyone follows the same audit-hardened playbook|
|**Drift check before deploy** (download live bundle, diff vs `main`)|Catch divergence before it ships|

## Lessons
- **Diagnose the connection *path*, not just capacity.** "Warm DB but 20s reads, no errors" was
  connection acquisition / proxy pinning — not ACU. We lost time on the wrong layer.
- **One runtime, one source of truth.** Multiple uncoordinated deployers to a single Lambda is the
  failure mode; everything else was a symptom.
- **Config can lie.** The SSM value didn't match the live env var. Verify what's actually running,
  not what the config says.
- **RLS via session GUC and RDS Proxy don't mix for hot reads.** Pin-on-`SET` defeats multiplexing;
  scope hot reads with explicit `org_id` filters instead.

## Follow-ups (open)
- Deploy the reconciled tree (proxy-safe pool + de-pinned points reads).
- Move remaining hot tenant reads off `SET LOCAL` (or raise the proxy's pin budget) to fully stop
  pin accumulation.
- Watch the intermittent client-side `Amplify.AuthError 5` on login (transient; not backend).
- Add branch protection on `main` and restrict deploy credentials per the policy.
