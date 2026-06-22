---
title: Account Hygiene Sweep — Gunner-Dev 980921733684 (2026-06-20)
type: reference
owner: gunnerteam
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - soc2
  - security
  - aws
  - account-hygiene
  - read-only-audit
status: stable
related:
  - '[[gunnerteam/aws-environment]]'
  - '[[gunnerteam/soc2-technical-summary]]'
  - '[[colin/aws-infra]]'
---

# Account Hygiene Sweep — AWS Gunner-Dev `980921733684` (cc-2133)

**Read-only inventory** across all regions (`--profile mfa`), 2026-06-20. CC6.1 / CC6.6 (account
attack-surface + access hygiene). **Nothing was changed, terminated, deleted, detached, or modified
— recommendations only.** Many findings belong to other owners (WL-CompanyCam/Colin, Leo, DevOps,
Doug); route accordingly and dedupe against Colin's §C-6 sweep.

## Headline
- **8 public Lambda Function URLs** (`AuthType=NONE`) — **0 are GunnerTeam** (ours deleted in cc-2121).
- **8 IAM users, all with active static keys; only 1 (`tyler-cli`) has MFA** — 1 human user (`leonard.fuentes`) has console + key + **no MFA**; **root MFA = false**.
- **8 EC2 instances, all `Owner`-untagged; 0 are GunnerTeam** (our EC2 chain is retired — confirmed).
- World-open security groups expose **5432 (Postgres), 6379 (Redis), and SSH-22** in dev VPCs — none in GunnerTeam's pinned prod VPC.
- No app/Lambda role holds `AdministratorAccess` or inline `*:*`. Account-level S3 Public Access Block is **not** set.

**GunnerTeam's own surface is clean.** The one GunnerTeam-tagged item — the `gunner-fleet-worker-dev`
IAM user's static key — was **remediated in cc-2134** (confirmed abandoned, key deactivated 2026-06-20; delete after a ~1-week soak). Almost
everything else routes to other owners.

---

## Phase 1 — EC2 (all regions): 8 instances, all `Owner`-untagged
None are GunnerTeam. `Owner` tag missing on **all 8** → tagging-hygiene finding for every owner.

| Region | Name | Type | State | Launched | Key | Owner-tag | Attributed | Sev | Recommendation |
|---|---|---|---|---|---|---|---|---|---|
| us-east-1 | `gunner-autolabel` | **g5.xlarge (GPU)** | running | 2026-06-16 | gunner-ec2-key | none | Doug?/unknown (ML) | **HIGH (cost)** | New GPU box — confirm owner + whether it should run 24/7 (g5.xlarge ≈ \$1/hr). Tag `Owner`. |
| us-east-1 | `gunner-leads-bastion` | t3.micro | running | 2026-06-15 | none | none | Doug (Lead Finder)? | MED | Confirm owner; bastions should be ephemeral/SSM, not long-lived. Tag `Owner`. |
| us-east-2 | `dev-gunner-salesPortalEc2` | t3a.medium | running | **2024-11-14** | devopsFrontend | none | DevOps | MED | Long-lived dev portal (cc-2122). Confirm still needed; tag. |
| us-east-2 | `dev-gunner-CorpProtal-frontend` | t3a.medium | running | **2024-11-12** | devopsFrontend | none | DevOps | MED | Same as above. |
| us-east-2 | `dev-gunner-hrPortalEc2` | t3.medium | running | 2025-04-01 | devopsFrontend | none | DevOps | MED | Same as above. |
| us-east-2 | `testindqp2-hubspot` | t3.micro | **stopped** | 2026-05-15 | devopsFrontend | none | DevOps | LOW | Stopped — terminate if abandoned (still bills EBS). |
| us-east-2 | `wl-companycam-dev-bastion` | t4g.nano | running | 2026-05-18 | none | none | **Colin/WL-CC** | LOW | Confirm bastion still needed; tag. |
| us-east-2 | `db-tunnel` | t3.micro | running | 2026-05-26 | none | none | Colin/DevOps (masterdb tunnel) | MED | Long-lived DB tunnel — confirm owner + restrict its SG (see Phase 5). |

---

## Phase 2 — IAM users + access-key hygiene: 8 users, all with active static keys
Standard is SSO/Identity Center (roles, no static keys). **7 of 8 users lack MFA.** App/service users
with static keys are findings per-owner; the human user without MFA is the priority.

| User | MFA | Console pw last used | Key1 active (last used) | Attributed | Sev | Recommendation |
|---|---|---|---|---|---|---|
| `<root_account>` | **false** | (no info) | no keys | account | **HIGH** | Enable root MFA (CC6.6) — account-owner action. |
| `leonard.fuentes@gunnerroofing.com` | **false** | 2026-06-17 | yes (2026-06-18) | **Leo (human)** | **HIGH** | Human user with console **and** a static key, no MFA → enable MFA, move to SSO, delete the static key. |
| `gunner-fleet-worker-dev` | false | N/A | last used 2026-05-05 | **GunnerTeam (Fleet)** | RESOLVING | **cc-2134:** confirmed abandoned (S3-only blast radius on `gunner-fleet-dev/*`, app uses the Lambda role, repo grep clean). **Key deactivated 2026-06-20** (reversible); delete + remove user after ~1-week soak. |
| `gunner-content-engine` | false | N/A | yes (2026-06-15) | Doug (content) | MED | App service key — route to Doug; rotate + scope. |
| `leads-finder-dk` | false | (no info) | yes (2026-06-19) | Doug (Lead Finder) | MED | App service key — route to Doug; rotate + scope. |
| `KinesisDataStreamFabricUser` | false | N/A | yes (2026-06-22) | DevOps/unknown (Kinesis) | MED | Streaming service key — route to owner; prefer a role. |
| `wl-companycam-app-dev` | false | N/A | yes (2026-06-22) | **Colin/WL-CC** | MED | App service key — route to Colin; prefer a role. |
| `tyler-cli` | **true** | N/A | yes (2026-06-21) | **GunnerTeam (Tyler)** | LOW | The awsmfa base credential (MFA-gated via `GunnerRequireMFA`). Acceptable; rotate periodically. |

---

## Phase 3 — public Lambda Function URLs: 8, all `AuthType=NONE`, 0 GunnerTeam
GunnerTeam's public Function URL (`gunnerteam-dev-assistant-stream`) was removed in cc-2121 — confirmed
absent. Every URL below is unauthenticated at the platform layer; for each, confirm app-level auth /
signature verification and that none carry creds or touch shared data.

| Region | Function | Attributed | Sev | Recommendation |
|---|---|---|---|---|
| us-east-1 | `permit-poc-live` | DevOps/unknown (the known POC) | **HIGH** | The `permit-poc` class. Confirm it's intentional + has app auth; if a stale POC, retire it. |
| us-east-2 | `hubspot-dialpad-dev` | IT/DevOps (integration) | **HIGH** | Public webhook receiver — verify HMAC/signature validation; restrict if none. |
| us-east-2 | `hubspot-dialpad-webhook` | IT/DevOps (integration) | **HIGH** | Same — verify signature check on the public endpoint. |
| us-east-2 | `dialpad-hubspot-sync` | IT/DevOps (integration) | MED | Confirm auth + whether it needs a public URL at all. |
| us-east-2 | `wl-companycam-dev-WebServer…` | **Colin/WL-CC** | MED | Lambda Web Adapter app — `NONE` is by-design for a public web app; confirm in-app Cognito/Google SSO. |
| us-east-2 | `wl-companycam-dev-WebImageOptimizer…` | **Colin/WL-CC** | MED | Same family — confirm no unauth data exposure. |
| us-east-2 | `wl-companycam-colinwong-WebServer…` | **Colin/WL-CC** (personal stage) | MED | Personal stage — confirm still needed. |
| us-east-2 | `wl-companycam-colinwong-WebImageOptimizer…` | **Colin/WL-CC** (personal stage) | MED | Same. |

---

## Phase 4 — over-permissive IAM roles: clean
92 roles total. `AdministratorAccess` is attached only to the **expected** human/Org roles, and **no
role has an inline `*:*` policy**:

| Role | Sev | Note |
|---|---|---|
| `AWSReservedSSO_AdministratorAccess_…` | OK | Identity Center break-glass admin — expected. |
| `OrganizationAccountAccessRole` | OK | Org cross-account admin — expected. |
| (no app/Lambda exec role with admin) | OK | GunnerTeam Lambda role stays least-privilege (cc-2107). No inline-wildcard findings. |

---

## Phase 5 — network + storage exposure
**Account-level S3 Public Access Block: NOT configured** (`NoSuchPublicAccessBlockConfiguration`).
GunnerTeam buckets are protected per-bucket (PAB + TLS-only, cc-2109/2112), but an **account-level**
PAB is a stronger backstop → recommend enabling (account-owner/DevOps).

Security groups open to `0.0.0.0/0` (all in **dev-gunner `vpc-04f851…`** or **wl-companycam
`vpc-01348…`** — **none in GunnerTeam's pinned prod VPC `vpc-0530f022…`**):

| SG | Name | VPC | World-open ports | Sev | Recommendation |
|---|---|---|---|---|---|
| sg-0691f10fcdbf09a13 | `wl-companycam-rds-dev` | wl-cc | **5432 (Postgres)** | **HIGH** | DB port open to the internet — restrict to the app SG/bastion. **Colin.** |
| sg-05992f2dc3fe820dc | `redis-sg-dev` | dev-gunner | **6379 (Redis)** | **HIGH** | Redis open to the internet (usually no auth) — restrict. DevOps. |
| sg-0c9a9e54e2b6300c9 | `dev-gunner-vpc-generalSG` | dev-gunner | 22, 80, 443 | **HIGH** | SSH-22 world-open — restrict to office/VPN CIDR. DevOps. |
| sg-0ccea8c28c3d98651 | `gunnerFronendDevEc2-…` | dev-gunner | 22 | **HIGH** | SSH-22 world-open. DevOps. |
| sg-0b60ab35e8936cdb3 | `launch-wizard-1` | wl-cc | 22, 80, 443 | **HIGH** | Ad-hoc launch SG, SSH world-open. Colin/owner. |
| sg-0328dd52df39c9ae4 | `launch-wizard-2` | wl-cc | 22, 80, 443 | **HIGH** | Same. |
| sg-0b102269eff84bfb0 | `default` | wl-cc | 22 | MED | Default SG with SSH world-open — should have no rules. Colin. |
| sg-07c1753bb57bca05c | `dev-gunner-auroraPgDb-rds-group` | dev-gunner | (all/ICMP — FromPort null) | **HIGH (verify)** | A `0.0.0.0/0` ingress rule with no numeric port on a **DB SG** — verify it's not all-traffic; restrict. DevOps. |
| sg-0f72d0a15dd5e38bd | `dev-gunner-lambda-subnet` | dev-gunner | (all/ICMP — FromPort null) | MED (verify) | Verify the world-open rule scope. DevOps. |
| sg-075667848c7e572b5 | `hrPortalFrontendEC2-…` | dev-gunner | (all/ICMP — FromPort null) | MED (verify) | Verify. DevOps. |
| sg-033184139577e19c8 | `salesPortalDevFrontendEc2-…` | dev-gunner | (all/ICMP — FromPort null) | MED (verify) | Verify. DevOps. |
| sg-0618195eba0782c7f | `alb-gunner-dev-sales-corp-ALB…` | dev-gunner | 80, 443 | LOW | Public ALB — expected for a web front end. DevOps. |

---

## Routing summary (recommend-only — change nothing)

| Owner | Items |
|---|---|
| **GunnerTeam (us)** | `gunner-fleet-worker-dev` static key **deactivated (cc-2134, 2026-06-20)** — delete the key + user after a ~1-week soak (Phase 2). Rotate `tyler-cli` key periodically. Our compute/buckets/roles are otherwise clean. |
| **Colin / WL-CompanyCam** | `wl-companycam-rds-dev` SG (5432 world-open, HIGH); `wl-companycam-*` Function URLs (4); `wl-companycam-app-dev` key; `wl-companycam-dev-bastion` EC2; `default` + `launch-wizard-*` SGs (vpc-01348). Dedupe w/ §C-6. |
| **Leo** | `leonard.fuentes@…` IAM user — enable MFA, move to SSO, delete the static key (**HIGH**). |
| **DevOps** | dev-portal EC2 (sales/corp/hr + stopped hubspot test); `dev-gunner-vpc-generalSG` / `gunnerFronendDevEc2` SSH-22; `redis-sg-dev` 6379; `dev-gunner-auroraPgDb` SG; `db-tunnel` EC2; ALB; account-level S3 PAB; `KinesisDataStreamFabricUser` key. |
| **Doug / unknown** | `gunner-autolabel` (GPU cost) + `gunner-leads-bastion` EC2; `gunner-content-engine` + `leads-finder-dk` keys. |
| **Account owner** | Root MFA (**HIGH**); account-level S3 Public Access Block. |

## Method note
All data via read-only AWS describe/list calls (`--profile mfa`, `AWS_REGION=us-east-2` for region-less
endpoints). Phase 2 used a single IAM credential report. `ports=[]`/FromPort-null SG rules are flagged
"verify" because a `0.0.0.0/0` rule with no numeric port may be all-traffic or ICMP — confirm before
acting. No mutations were performed.
