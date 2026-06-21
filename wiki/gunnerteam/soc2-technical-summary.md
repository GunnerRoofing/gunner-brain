---
title: GunnerTeam — SOC 2 Technical Control Summary
type: gunner
tags:
  - soc2
  - compliance
  - security
  - controls
  - gunnerteam
created: '2026-06-20'
updated: '2026-06-20'
status: stable
source: GunnerTeam-SOC2-Technical-Summary-2026-06-20.md
related:
  - '[[gunnerteam/security-compliance-roadmap]]'
  - '[[gunnerteam/system-security-plan]]'
  - '[[gunnerteam/ssp-addendum-1-product-environment]]'
  - '[[gunnerteam/soc2-accomplishments-2026-06]]'
  - '[[gunnerteam/attack-surface-reduction-cc2123-2126]]'
  - '[[gunnerteam/aws-environment]]'
  - '[[tyler/concepts/soc2]]'
---

# GunnerTeam — SOC 2 Technical Control Summary

**As of:** 2026-06-20 · **Scope:** GunnerTeam API + iOS app, AWS account Gunner-Dev (980921733684), us-east-2
**Status legend:** ✅ Implemented & verified · 🟡 Partial / interim · ⏸ Deferred (cost or coordination) · 🔜 Cutover-gated (needs real prod account)

---

## 1. Architecture snapshot

Serverless, single-region (us-east-2):

- **Compute:** `gunnerteam-dev-api` Lambda (Express via `@vendia/serverless-express`), alias `live` (currently v330), in VPC `vpc-0530…`, private subnets, SG `sg-06313256…`. API fronted by an **API Gateway HTTP API** (`ANY /{proxy+}`) → custom domains `api.team` / `api-dev.team.gunnerroofing.com` (ACM, regional). DNS/edge via Cloudflare.
- **Data:** Aurora PostgreSQL 17 (Serverless v2, 8–16 ACU) reached through RDS Proxy `gunnerteam-dev-masterdb-proxy`. Multi-tenant; tenant isolation by explicit `org_id` scoping. **The Aurora cluster + its parameter group are owned by a separate SST/Pulumi app (`gunner-masterdb`)** — the GunnerTeam app layer (Lambda/API GW/S3/Cognito/IAM) is Terraform; the database stack is not.
- **Identity:** Cognito user pool `us-east-2_hFVBSrcnn`; ID-token auth verified in-app (`aws-jwt-verify`).
- **Storage:** S3 — `gunner-fleet-dev` (photos/inspections), `gunner-assistant-docs`, `gunner-audit-logs-dev` (WORM archive).
- **Access:** AWS via IAM Identity Center SSO with `GunnerRequireMFA` (no IAM users).
- **Environment & data scope:** single, non-isolated AWS **dev** account. The cluster nicknamed "prod" is a higher-performance **dev** server, *not* a production environment — there is no production environment yet. Data is limited to **one PM's real pilot usage** (a handful of real jobs + live location-tracking under test); **no external-customer data**. This keeps the dev/prod-split item below in the realm of pre-go-live migration hygiene, not a data-exposure concern.
- **IaC / SDLC:** Terraform (app layer) + SST/Pulumi (masterdb); GitHub Actions CI; S3-staged Lambda deploys with version+alias promotion. Control ownership across the two-stack seam is documented in `GunnerTeam-CrossStack-Ownership-RACI-2026-06-20.md`.

---

## 2. Control posture by Trust Services Criteria

### CC6.1 — Logical access & least privilege
| Control | Status | Notes |
|---|---|---|
| Cognito authentication, app-layer ID-token verification | ✅ | `requireAuth` pins client + required claims (`email`, `custom:tenantId`) |
| Password policy | ✅ | min 12, upper/lower/number/symbol required |
| Token lifetime + revocation | ✅ | ID/access 1h, refresh 30d, `enable_token_revocation = true` |
| IAM least privilege (Lambda exec role) | ✅ | Scoped to specific SSM path, Secrets Manager path, named S3 buckets, the specific Cognito pool, and the function's own log group; SES scoped to the verified domain identity. EC2-ENI on `*` (no resource-level support — unavoidable for VPC Lambda) |
| Multi-tenant isolation | ✅ | Explicit `org_id` filters on user-scoped reads/writes (`user_organizations` pre-flight) |
| Rate limiting (auth endpoints) | ✅ | DynamoDB-backed limiter on forgot-password/invite/webhooks; API GW throttle 5000/10000 |
| Secrets management | 🟡 | 41 secrets in SSM SecureString, baked into Lambda env via Terraform; masterdb credential in Secrets Manager. Runtime Secrets-Manager fetch (no env-baking) is on the backlog |
| Cognito advanced security (compromised-credential / adaptive auth) | ⏸ | Requires Cognito Plus tier (~$0.05/MAU) — deferred pending budget |

### CC6.2 / CC6.3 — Provisioning & deprovisioning
| Control | Status | Notes |
|---|---|---|
| User provisioning | ✅ | Invite-based, multi-step complete-invite |
| Deprovisioning | ✅ | Hard delete removes all DB rows + Cognito user, calls `AdminUserGlobalSignOut` (revokes refresh tokens), invalidates the auth cache; audited. IAM grant for sign-out confirmed live |

### CC6.6 — Boundary protection
| Control | Status | Notes |
|---|---|---|
| TLS termination at the edge | ✅ | ACM on API GW custom domains |
| Network isolation | ✅ | Lambda in private subnets; Aurora reachable only via in-VPC proxy, not public |
| Web Application Firewall | ⏸ | None yet. AWS WAF can't attach to an HTTP API; Cloudflare WAF (already the edge) is the chosen path — deferred pending Cloudflare Pro |

### CC6.7 — Encryption (in transit & at rest)
| Control | Status | Notes |
|---|---|---|
| TLS in transit (client→API) | ✅ | ACM/Cloudflare |
| **DB connection cert verification** | ✅ | `pg` now verifies the RDS Proxy cert against the RDS CA bundle + Node public roots (`rejectUnauthorized: true`) — previously `false` |
| `rds.force_ssl = 1` | ✅ | Enforced as the Aurora PG 17 engine default; explicit declarative pin deferred to the `gunner-masterdb` SST owner |
| S3 TLS-only | ✅ | `DenyInsecureTransport` on all three buckets |
| At rest — S3 | ✅ | AES256 default encryption + SSE-C block on all buckets |
| At rest — DB / SSM | ✅ | Aurora encryption (managed), SSM SecureString |
| Customer-managed KMS keys (CMK) | 🔜 | AES256/SSE-managed today; CMK rotation/key-policy is a prod-account cutover item |

### CC7.1 — Vulnerability & threat detection
| Control | Status | Notes |
|---|---|---|
| SAST | ✅ | Semgrep in CI (OWASP/Node packs + a committed local taint rule for command-injection sinks, since registry taint rules are login-gated) |
| Dependency scanning | ✅ | `npm audit --audit-level=high` **enforcing** (build fails on high/critical); multer + node-forge highs remediated live (v330) |
| SBOM | ✅ | CycloneDX generated + archived per CI run |
| AWS-native threat detection (GuardDuty / Config / CloudTrail org-level) | 🔜 | Cutover item — belongs in the prod account under Organizations with a tamper-isolated logging account |

### CC7.2 — Monitoring & audit logging
| Control | Status | Notes |
|---|---|---|
| Application audit trail | ✅ | Single `audit()` writer → `audit_log`; monthly EventBridge archiver → S3 NDJSON, **Object Lock WORM (GOVERNANCE, 7yr)**; 6-month hot retention |
| Audit-trail health | ✅ | On-demand count mode + hourly `AuditLogLast24h` metric + silence alarm (fires if no audit activity in 2h) |
| Alerting | ✅ | 5 CloudWatch alarms → SNS → SES email + Google Chat (ALARM/OK/INSUFFICIENT_DATA); 5xx alarm proven firing during a real incident |
| Log retention | ✅ | App logs 90d, audit log group 365d, audit archive 7yr |
| Log hygiene | ✅ | CI guardrail fails the build on `console.*` calls leaking bodies/auth headers/secrets |

### CC8.1 — Change management
| Control | Status | Notes |
|---|---|---|
| Version control + CI gates | ✅ | GitHub Actions: syntax check, log-hygiene, unit tests, SBOM, SAST, enforcing audit — all green required |
| Infrastructure as Code | ✅ | Terraform (app layer) with `prevent_destroy` on stateful/identity resources; backend pinned to the `mfa` profile |
| Deploy process | ✅ | Documented S3-staged deploy → publish version → alias promotion; routing-weight reset codified |

### A1.2 — Availability, backup & recovery
| Control | Status | Notes |
|---|---|---|
| Terraform state durability | ✅ | State bucket versioning enabled |
| Database backups | ✅ | Aurora automated backups (managed by the `gunner-masterdb` SST stack) |
| **Tested DR (RTO/RPO)** | 🔜 | DR is documented but not yet executed — a timed Aurora PITR + S3 restore against real prod infra is required; cutover item |

### Client (iOS) — CC6.1 / CC6.7 / Privacy
| Control | Status | Notes |
|---|---|---|
| Token storage at rest | ✅ | Cognito ID/access/refresh tokens held in the iOS **Keychain** (Amplify-managed, hardware-backed). Single token scheme — the legacy HS256 invite token is fully retired (cc-2118), client + backend now Cognito-RS256 only |
| Transport security (ATS) | ✅ | App Transport Security at iOS defaults — TLS 1.2+ enforced, **no** `NSAllowsArbitraryLoads` / no cleartext exceptions |
| App-layer auth | ✅ | Every API call carries the Cognito ID token, verified server-side (`requireAuth`) |
| Location consent (Privacy / Confidentiality) | ✅ | **Layered:** OS `authorizedAlways` + server-side per-user `location_consent` flag (admin-toggled, delivered on `/validate`) + backend forward gate (consent **and** env). Every client report path guards on `locationConsentGranted`; permission-status reporting is coordinate-free. This is the white-label Privacy evidence |
| Certificate pinning | ✅ | **Implemented (cc-2116).** SPKI pinning to the stable Amazon RSA 2048 M04 intermediate (primary) + Amazon Root CA 1 (backup), via a shared pinned `API.session` (replaced ~178 `URLSession.shared` sites); fail-closed on the API hosts only. Amplify/Cognito + S3 presigned stay on standard trust by design. ⚠️ Pins must be updated to Cloudflare's chain in the same release that enables the Cloudflare proxy (cc-2110) |
| Jailbreak / tamper detection | ✅ | **Implemented (cc-2117).** Heuristic `JailbreakDetector` (artifact paths, URL schemes, dylib markers, sandbox-escape probe; never flags simulator/clean devices; 9 unit tests). Graduated response: report+audit (no block) on the supervised pilot, hard-block gated behind `JAILBREAK_ENFORCE` for the white-label public build. Documented as deterrent + audit signal (not tamper-proof); Hexnode MDM remains the primary control on the supervised fleet, this becomes the device-integrity control of record once white-labeled |

> Cert pinning and jailbreak detection were initially deferred as documented decisions, then **built** (cc-2116/2117) once the white-label/public-App-Store path made device integrity a primary control rather than MDM-redundant. Two open finishers: a backend `POST /device/integrity` endpoint so the jailbreak audit signal lands (client report is best-effort / 404s until it ships), and flipping `JAILBREAK_ENFORCE` for the white-label release.

---

## 3. Remaining work

**Deferred (cost / coordination):**
- Cognito advanced security (Plus tier) — prompt written, parked.
- Cloudflare WAF + rate limiting (Cloudflare Pro) — prompt written, parked; dev record must be flipped to proxied first.
- Explicit `rds.force_ssl = 1` pin — must be set in the `gunner-masterdb` SST app (Colin/DevOps); control is already met via engine default.

**Backlog (no cost):**
- Secrets → runtime Secrets Manager fetch (out of Lambda env).
- Codify S3 SSE in Terraform once the AWS provider reaches ≥6.40 (the arg that preserves the SSE-C block exists only in 6.22+).

**Cutover-gated (needs the real prod account — don't build twice):**
- KMS customer-managed keys (Aurora / S3 / Secrets).
- Full VPC isolation review + tightened security groups in the prod topology.
- GuardDuty + AWS Config + org-level CloudTrail in a tamper-isolated logging account.
- Cross-region encrypted Aurora backups.
- **Tested DR** with documented RTO/RPO.
- **True dev/prod split** — today the "dev" Lambda connects to the Aurora cluster nicknamed "prod" (a faster dev server, not a production environment). Standing up a genuinely isolated production account is the single largest open SOC 2 item and is the cutover itself. Severity today is low (single-tester pilot, internal-only data), but it must precede any real customer onboarding.

**External:**
- Third-party penetration test against the real production environment (scoped to API + auth), post-cutover / pre-Type-I.

---

## 4. Honest framing

Control *coverage* across the Common Criteria is strong and largely verified-live. The remaining technical work is hardening detail (advanced security, WAF, CMKs, runtime secrets) plus the detection layer and tested DR that genuinely require the real environment. The gating item for a real SOC 2 is not a missing control — it is that the system currently runs in a single, non-isolated dev account with one PM's real pilot data (internal only; no external-customer data). Environment isolation, the AWS-native detection stack, and a tested DR all resolve at cutover. That cutover is the migration from this single-account dev setup to a genuinely separated production account — it must happen before real customer onboarding, but the present low-risk pilot posture does not require it yet.

---

## Related vault pages

- [[gunnerteam/security-compliance-roadmap]] — org-wide frameworks / SOC 2 process / MDM / SIEM / CMMC roadmap + CISO cert track
- [[gunnerteam/system-security-plan]] · [[gunnerteam/ssp-addendum-1-product-environment]] — the SSP + product-environment addendum (APP-01…APP-09)
- [[gunnerteam/soc2-accomplishments-2026-06]] — prior cc-16xx implementation summary (this doc reflects the later cc-21xx work)
- [[gunnerteam/aws-environment]] — AWS account / deploy reference
- [[tyler/concepts/soc2]] — SOC 2 concept notes

> [!note] Provenance
> Ingested 2026-06-20 (verbatim) from `GunnerTeam-SOC2-Technical-Summary-2026-06-20.md` (`~/Documents/Claude/Projects/Gunner Team App/`). Captures the cc-21xx control posture: cert pinning (cc-2116), jailbreak detection (cc-2117), HS256 retirement (cc-2118), `/device/integrity` (cc-2119), JWT_SECRET removal (cc-2120), TLS-only S3 (cc-2109/2112), force_ssl (cc-2111), TF mfa-profile (cc-2115).

> [!note] Snapshot currency (vault reconciliation)
> This is a 2026-06-20 point-in-time snapshot. Items its body lists as open/in-flight that shipped **same-day**: `POST /device/integrity` is **live** (cc-2119); `JWT_SECRET` + `jsonwebtoken` removed (cc-2120); the abandoned `gunnerteam-dev-assistant-stream` Function URL Lambda **fully removed** + its SSM param deleted (cc-2121) — JWT_SECRET teardown complete; the **Secrets → runtime fetch backlog item is DONE** — ~17 app secrets (cc-2123) **and now `DB_PASSWORD`** (cc-2124, lazy pool builds from a runtime `getSecret` fetch) are read from SSM at runtime, so the **Lambda env now contains ZERO secrets** (config + `SECRETS_PATH` only). The EC2 var/script chain was also cleaned (cc-2122). **Live alias is now v339** (body says v330). Still open: flip `JAILBREAK_ENFORCE` for white-label; pin `rds.force_ssl` in the `gunner-masterdb` SST app; (future) read `DB_PASSWORD` straight from the RDS Proxy Secrets Manager secret to make SSM-vs-proxy drift structurally impossible. See [[tyler/hot]].
