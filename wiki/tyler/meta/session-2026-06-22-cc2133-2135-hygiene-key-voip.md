---
type: session
owner: tyler
created: '2026-06-22'
updated: '2026-06-22'
tags:
  - session
  - soc2
  - security
  - aws
  - iam
  - fieldportal
  - voip
  - dialpad
status: stable
related:
  - '[[gunnerteam/account-hygiene-sweep-2026-06-20]]'
  - '[[gunnerteam/voip-softphone-research]]'
  - '[[gunnerteam/dialpad-hubspot-integration]]'
  - '[[gunnerteam/aws-environment]]'
  - '[[tyler/hot]]'
title: 'Session 2026-06-22: cc2133-2135 Hygiene Key VOIP'
---

# Session 2026-06-22 — cc-2133→2135 account hygiene + A4 diagnostic + VOIP ingest

Four work items: a read-only account-wide security sweep (cc-2133), an IAM static-key
remediation (cc-2134), a temporary forward-vs-return telephony diagnostic (cc-2135), and
an ingest of the VOIP/softphone platform research. Lambda `gunnerteam-dev-api` finished the
session at **v348** (alias `live`); env holds zero secrets; backend Cognito-RS256-only.

## cc-2133 — Account hygiene sweep (read-only, all regions, `--profile mfa`)

Read-only inventory of AWS account `980921733684`; nothing changed. Report:
[[gunnerteam/account-hygiene-sweep-2026-06-20]]. Headline counts: **8 public Lambda Function
URLs** (`AuthType=NONE`, **0 GunnerTeam** — ours was deleted in cc-2121; the 8 are
`permit-poc-live`, 3× `hubspot-dialpad-*`, 4× `wl-companycam-*`); **8 IAM users, all with
active static keys, only `tyler-cli` has MFA** (`root` MFA=false and `leonard.fuentes` —
human, console + key, no MFA — both HIGH); **8 EC2 instances, all `Owner`-untagged, 0
GunnerTeam** (incl. a NEW `gunner-autolabel` g5.xlarge **GPU** running). World-open security
groups expose 5432 (`wl-companycam-rds-dev`), 6379 (`redis-sg-dev`), and SSH-22 (×5) — all in
dev-gunner / wl-companycam VPCs, **none in GunnerTeam's pinned prod VPC**. No app/Lambda role
holds `AdministratorAccess` or an inline `*:*`; account-level S3 Public Access Block is not
set. GunnerTeam's own surface is clean. Findings routed by owner (Colin / Leo / DevOps /
Doug / account-owner) for dedupe against Colin's §C-6 sweep — recommend-only.

## cc-2134 — Remediate the `gunner-fleet-worker-dev` static access key (CC6.1)

The one possibly-GunnerTeam item from the sweep. Confirmed abandoned: key
`AKIA…GP2P` (created 2026-05-04) **last used 2026-05-05** (S3, ~7 wks idle);
**zero CloudTrail events in 90d** (us-east-1 + us-east-2); repo grep across `~/Dev/GunnerTeam`
for the key id / `AWS_ACCESS_KEY` / `accessKeyId` / `secretAccessKey` is **clean** (the app
holds no static creds — it runs on the Lambda execution role). Blast radius is narrow: one
managed policy = `s3:PutObject/GetObject/DeleteObject` on `gunner-fleet-dev/*` only (the app's
inspection-photo bucket, `s3_bucket` tf var, reached via the Lambda role — not this key).

Reversible-first: **deactivated** the key (`update-access-key … --status Inactive`, verified
Inactive); app unaffected (`/health` 200). **Phase 2 (delete) deferred** per the mandated
~1-week soak. Follow-up ~2026-06-27: if no new `AccessDenied`, `delete-access-key` → detach
`gunner-fleet-worker-dev-policy` → `delete-user`. The other sweep-flagged keys belong to other
owners (Leo `leonard.fuentes`, DevOps `KinesisDataStreamFabricUser`, Doug
`gunner-content-engine`/`leads-finder-dk`) — routed, not touched.

## cc-2135 — A4 close-out diagnostic (what we forward vs what comes back)

Temporary GunnerTeam-side diagnostic in `gunnerteam-api/src/routes/fieldportal.js` to settle
whether the test account "seeing all jobs" was our side forwarding the wrong identity or
Colin's `/projects` scoping. Added `console.log('[cc-2135] …')` on `/jobs` (combined
role+email+count) and `/jobs/bundle` (role+email after `resolveTargetEmail`; count on the
full-rebuild = cache-miss path). Deployed **v347**, reproduced (Tyler signed into iOS as the
test account, opened Jobs — app showed "no jobs assigned"), then removed and redeployed
**v348** (net-zero code; file byte-identical to pre-task, nothing to commit).

**Finding:** `gtRole=user`, `forwardedEmail=admin@gunnerroofing.com` (the test account's **own**
email — no `userEmail` param, so `resolveTargetEmail` returns `req.user.email`),
`projectsReturned=0` on both paths. **Not a GunnerTeam bug** — we forward the correct scoped
email at `user` role (no privilege escalation, no wrong identity); Colin correctly returns 0
for that email (membership-scoped → empty by design). The app's empty state is the correct
render of 0; the earlier "all jobs" symptom is not reproducible (stale client cache /
JobPreloadStore before a fresh fetch). Open question for Colin: if `admin@gunnerroofing.com`
is *expected* to have assignments, that's a Field-Portal membership question, not ours.

## Ingest — In-app softphone VOIP platform research

Ingested `~/Documents/Claude/Projects/Gunner Team App/VOIP-Platform-Research.md` →
[[gunnerteam/voip-softphone-research]] (research for an in-app voice + SMS/MMS second line, a
Dialpad replacement). **Telnyx recommended** (Twilio runner-up); **Amazon Connect
disqualified** — AWS verbatim: one number shared for voice + SMS isn't supported, forcing two
numbers per rep, which breaks the single-business-card-number requirement. Biggest engineering
risk is the iOS CallKit/PushKit/WebRTC audio handoff (spike week 1), not the telephony.
Compliance edge: CT all-party recording consent (disclosure on every recorded call) +
per-tenant 10DLC lead time (1–3 wks) gating white-label. Cross-linked to
[[gunnerteam/dialpad-hubspot-integration]] as an **evolution** (the webhook bridge is the
near-term call/SMS logging fix; the softphone is the strategic full replacement). Research,
not a committed decision; not legal advice.

## State at close

- **Lambda:** v348 live (== cc-2201 v346 code; cc-2135 was deploy-then-revert). Env secret-free.
- **IAM:** `gunner-fleet-worker-dev` key Inactive (delete after soak).
- **Repo `~/Dev/GunnerTeam`:** no net code change this session (cc-2135 reverted); commits remain local on `main` per infra precedent.
- **Vault:** this session note + the VOIP ingest are the new writes.

## Open follow-ups

- **~2026-06-27:** delete the deactivated `gunner-fleet-worker-dev` key + user if no new `AccessDenied` during the soak.
- **cc-2201 watch:** re-run the Phase 0 Logs Insights query / watch `gunnerteam-dev-apigw-5xx` for 24h (target zero new `status=5`).
- **Colin:** confirm whether `admin@gunnerroofing.com` should have FP project assignments (cc-2135).
- **VOIP (if pursued):** week-1 iOS CallKit/PushKit/WebRTC spike; verify Telnyx whisper/barge + Managed Accounts; register one 10DLC tenant to measure lead time.
