---
title: Gunner Roofing — Security & Compliance Roadmap
type: gunner
tags:
  - soc2
  - compliance
  - security
  - governance
  - ciso
  - frameworks
  - cmmc
  - mdm
  - siem
  - roadmap
created: '2026-06-20'
updated: '2026-06-20'
status: stable
source: security-compliance-roadmap.md
related:
  - '[[gunnerteam/soc2-technical-summary]]'
  - '[[gunnerteam/system-security-plan]]'
  - '[[gunnerteam/aws-environment]]'
  - '[[tyler/ciso-track/roadmap]]'
  - '[[tyler/concepts/soc2]]'
---

# Gunner Roofing — Security & Compliance Roadmap

**Prepared for:** Tyler Suffern, sole IT admin / acting CISO
**Org profile:** ~36-person residential roofing company (Stamford CT HQ, Cromwell CT, Mt. Arlington NJ) that is **both** an internal IT operation **and** a SaaS vendor (white-label, multi-tenant iOS app on AWS Lambda/Node.js + RDS PostgreSQL + Cognito + API Gateway + CloudWatch).
**Date:** 2026-06-20
**Method:** Multi-agent web research, primary-source-anchored. Sourcing caveats are flagged inline; **all pricing is volatile — confirm before budgeting.**

---

## 0. The one decision that shapes everything: scope

Before any framework work, decide what your audit scope **is**. You wear two hats, and the cheapest, most defensible answer is to run **two distinct scopes**:

- **SaaS product scope** (the AWS multi-tenant environment + the iOS app) → this is what customers will demand a SOC 2 for. Prioritize it.
- **Corporate IT scope** (Google Workspace, MDM, UniFi, endpoints) → governed by CIS IG1→IG2 + NIST CSF; feeds CMMC L1 *only if* a federal contract triggers it.

Auditors (SOC 2 CC1/CC3, ISO A.5.3) will flag that one person holds all the keys. You cannot hire your way out at 36 people, so **design compensating controls now**: log every admin action, document approval/sign-off paths, and build peer-review or owner-attestation steps into change management. Bake this into the program from day one — retrofitting segregation-of-duties evidence later is painful.

---

## 1. The mental model (frameworks)

Your framing is the mainstream, correct one:

- **NIST CSF 2.0 = the organizing backbone.** Voluntary, risk-based, six Functions (Govern, Identify, Protect, Detect, Respond, Recover). Not certifiable; you map everything else into it. [NIST CSWP 29](https://doi.org/10.6028/NIST.CSWP.29) · [csf](https://www.nist.gov/cyberframework)
- **CIS Controls = the prescriptive implementation layer.** IG1 = 56 Safeguards (essential hygiene); IG2 adds 74 more (130 total) and is explicitly scoped to orgs that "employ individuals responsible for managing IT" and "store/process sensitive client information" — i.e., a SaaS vendor. [IG1](https://www.cisecurity.org/controls/implementation-groups/ig1) · [IG2](https://www.cisecurity.org/controls/implementation-groups/ig2)
- **SOC 2 = the customer-facing attestation** (AICPA, CPA-issued report over a period). Not a "certification." [AICPA SOC/TSC](https://www.aicpa-cima.com/resources/landing/system-and-organization-controls-soc-suite-of-services)
- **ISO 27001:2022 = the international certificate** (accredited body, 3-year cycle). Pursue only if international/enterprise procurement demands a *certificate*. [ISO/IEC 27001:2022](https://www.iso.org/standard/27001)

**Recommended framework sequence:** finish **CIS IG1 → push to IG2** (do the work) → **NIST CSF 2.0** as the governance layer (organize the work) → **SOC 2 Type II** (prove it to customers) → **ISO 27001:2022** only if a customer requires the certificate. A Type II requires controls to have *operated over a window* (3–12 months), so IG2 + CSF must be running first.

**Conflicts to avoid:** Don't claim "NIST certified" or "SOC 2 certified" — neither exists (CSF/CIS = neither cert nor attestation; SOC 2 = attestation *report*; only ISO yields a certificate). Scope statements differ across frameworks (SOC 2 = a described "system" + chosen TSC; ISO = ISMS boundary + Statement of Applicability; CIS = assets) — reconcile them deliberately per §0.

### 1.1 Build-once, satisfy-many — the shared-control core

Implement these **six control domains once** (to IG2 depth) and you cover the bulk of SOC 2, CSF, ISO 27001, **and** CMMC L1 simultaneously. Crosswalk anchors: NIST OLIR catalog (official mappings of CIS 8.1, ISO 27001:2022, SP 800-53, SP 800-171 → CSF 2.0) at [nist.gov/cyberframework/informative-references](https://www.nist.gov/cyberframework/informative-references) and the [CIS→NIST CSF mapping](https://www.cisecurity.org/insights/white-papers/cis-controls-v8-mapping-to-nist-csf).

| Control domain | CIS v8.1 | NIST CSF 2.0 | SOC 2 (Common Criteria) | ISO 27001:2022 Annex A | CMMC L1 (FAR 52.204-21) |
|---|---|---|---|---|---|
| **MFA / access control** | CIS 5, 6 | PR.AA | CC6.1–6.3 | A.5.15–5.18, A.8.5 | (i),(ii),(v),(vi) |
| **Logging & monitoring** | CIS 8, 13 | DE.CM, DE.AE | CC7.1–7.2 | A.8.15, A.8.16 | (x) |
| **Vulnerability mgmt** | CIS 7 | ID.RA, PR.PS | CC7.1, CC3.x | A.8.8 | (xii) |
| **Asset inventory** | CIS 1, 2 | ID.AM | CC6.1, CC3.2 | A.5.9 | (i),(iii) |
| **Incident response** | CIS 17 | RS.*, RC.* | CC7.3–7.5 | A.5.24–5.28 | — |
| **Vendor / third-party mgmt** | CIS 15 | GV.SC | CC9.2 | A.5.19–5.22 | — |
| *(plus)* Data protection/encryption | CIS 3 | PR.DS | CC6.7, C1.x | A.8.10–8.12, A.8.24 | (vii) |
| *(plus)* Secure configuration | CIS 4 | PR.PS | CC6.1, CC7.1 | A.8.9 | (iv),(xi) |
| *(plus)* Awareness training | CIS 14 | PR.AT | CC1.4, CC2.2 | A.6.3 | — |

> **Verification note:** SOC 2 CC cell assignments reflect the standard alignment to AICPA Trust Services Criteria (2017, rev. 2022) — confirm exact cells against the AICPA TSC PDF before audit-facing use. OLIR crosswalks map at finer subcategory/Safeguard granularity; pull the actual XLSX for cell-exact evidence.

**Payoff:** standing up *MFA + centralized logging + a vuln-scan cadence + asset inventory + an IR plan + a vendor-review process* gets simultaneous coverage across all four frameworks — and these are the same IG1/IG2 Safeguards you're already building.

---

## 2. SOC 2 for the SaaS product on AWS

**TSC scope recommendation:** Security (Common Criteria CC1–CC9, mandatory) **+ Availability + Confidentiality**, and **Privacy if the iOS app touches end-user PII** (it likely does). Skip Processing Integrity unless transaction accuracy is your core promise. The heavy-weighted areas for multi-tenant SaaS: **CC6** (logical access — *where your tenant-isolation story lives*), **CC7** (monitoring/incident), **CC8** (change mgmt), **CC9** (risk + vendor mgmt). [AICPA TSC](https://www.aicpa-cima.com/resources/download/2017-trust-services-criteria-with-revised-points-of-focus-2022)

**AWS shared responsibility → your audit scope.** AWS owns "security *of* the cloud" (hardware, hypervisor, facilities); you own "security *in* the cloud" — your data, encryption config, IAM, network config, app security. [Shared Responsibility Model](https://aws.amazon.com/compliance/shared-responsibility-model/). Because Lambda/RDS/Cognito/API Gateway are managed, **AWS patches the underlying OS/runtime — that's off your plate.**

**Pre-built evidence via AWS Artifact.** All five of your core services are **in scope of AWS's SOC reports** ([services in scope](https://aws.amazon.com/compliance/services-in-scope/SOC/), confirmed Lambda, RDS, Cognito, API Gateway, CloudWatch — plus KMS, IAM, CloudTrail, Secrets Manager, S3). AWS is a **carved-out subservice organization**: download its SOC 2 report (under NDA via [Artifact](https://aws.amazon.com/artifact/); SOC 3 is [public](https://aws.amazon.com/compliance/soc-faqs/)), hand it to your auditor, and track the **CUECs** (Complementary User Entity Controls) it lists — those are the things AWS assumes *you* do.

**Gaps that remain yours** (become your SOC 2 controls): (1) IAM config / least privilege / MFA / root protection; (2) encryption config (KMS, RDS-at-rest, TLS); (3) app-level logging/alerting/retention; (4) periodic access reviews + JML; (5) change management / SDLC; (6) vuln management + pen test; (7) vendor management (incl. annually reviewing AWS's report + bridge letter).

**Timeline & cost — ⚠️ ESTIMATES, verify before budgeting** (the cost-research fetches were rate-limited this session; confirm at vanta.com/resources/soc-2-cost, secureframe.com/blog/soc-2-cost, vendr.com, and auditor sites):

| Item | Estimated range |
|---|---|
| Type II auditor fee (startup) | ~$12K–$30K+ |
| Observation window | 3 / 6 / 12 mo — **first-timers usually pick 3 mo** |
| Readiness prep | ~2–6 mo self-prep (4–8 wks with a platform + hands-on founder) |
| Compliance platform (Vanta/Drata/Secureframe) | ~$7.5K–$25K/yr |
| Pen test (commonly expected) | ~$4K–$15K |
| **All-in first year (Type II)** | **~$25K–$60K** |
| **Elapsed time (prep → report)** | **~6–12 months** |

**Strategy:** most startups **skip Type I and go straight to Type II** with a 3-month window — buyers only accept Type II, so Type I adds cost for a report customers reject.

---

## 3. SaaS product security architecture (decide before first external tenant)

**Load-bearing principle (AWS, verbatim):** "a user could be authenticated and authorized, and still access the resources of another tenant." Cognito JWTs + your RBAC do **not** by themselves prevent cross-tenant access. Isolation is a separate, *testable* control. [SaaS Lens — tenant isolation](https://docs.aws.amazon.com/wellarchitected/latest/saas-lens/tenant-isolation.html)

**Tenant isolation on RDS/PostgreSQL** — Silo (DB-per-tenant) / Bridge (schema-per-tenant) / Pool (shared table + Row-Level Security):

| | Silo | Bridge | Pool (RLS) |
|---|---|---|---|
| Cost | Highest | Medium | **Lowest** |
| Isolation | Strongest (physical) | Strong (schema) | Logical only |
| Blast radius | Smallest | Medium | Largest |
| SOC 2 story | Easiest | Moderate | **Hardest — must prove RLS** |

[Multi-tenant data isolation with PostgreSQL RLS](https://aws.amazon.com/blogs/database/multi-tenant-data-isolation-with-postgresql-row-level-security/). **Recommendation:** **Pool + RLS** as the cost-sane default, **but** it raises the testing bar. RLS fails *silently* if you get the role model wrong:

- The **table owner bypasses RLS by default** — your app must connect as a **non-owner role without `BYPASSRLS`**, and set `FORCE ROW LEVEL SECURITY`.
- Use shared login + per-connection session var: `USING (tenant_id = current_setting('app.current_tenant')::UUID)`.
- **Connection-pooling warning:** session variables can break with server-side poolers (pgBouncer) — **directly relevant to your Lambda + pooler setup.** Verify the pool doesn't share session state.
- **SOC 2 evidence = adversarial negative tests:** brute-forcing another `tenant_id` returns 0 rows; cross-tenant UPDATE/DELETE affect 0 rows; cross-tenant INSERT errors; no owner/view/`BYPASSRLS` path defeats it. *A policy existing is not evidence.*
- For a tenant with heavy compliance/residency demands, **silo that tenant via the Bridge/Silo model** while pooling the rest.

**Secrets management:** AWS explicitly recommends **Secrets Manager over env vars for DB creds** (native rotation, RDS integration; $0.40/secret/mo). [Lambda env var docs](https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html). Env vars leak via `get-function-configuration` (exactly why your CLAUDE.md forbids that command). **Cost note:** Secrets Manager is priced *per secret*, so a silo/DB-per-tenant design multiplies this linearly — a reason pool+RLS is cheaper end-to-end.

**Audit logging:** CloudTrail = control-plane/AWS-API audit, but it attributes activity to an **AWS principal (your Lambda role), NOT a tenant**, and misses in-app business actions. **Tenant-attributed audit logging is your app's job** — inject the tenant ID on every data access via your shared data-access layer (where your `audit()` helper already lives). For immutable storage, don't conflate the two mechanisms: **CloudTrail log-file validation = tamper-*evident*** (after-the-fact); **S3 Object Lock Compliance mode = tamper-*proof* WORM** (can't be deleted by anyone, incl. root). Use Object Lock for genuinely immutable audit storage. [Object Lock](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html)

**Data residency:** you choose the Region; AWS won't move data out except to provide the service or comply with law. [Data privacy FAQ](https://aws.amazon.com/compliance/data-privacy-faq/). Residency design = **silo-by-region**. Caveat: **global services (IAM, Organizations) are Region-exempt** — any "all data stays in EU" claim must account for them.

**Tooling — adopt in this order:**

1. **Prowler** (free, Apache 2.0) — has a built-in SOC 2 framework: `prowler aws --compliance soc2_aws`. **Run this now** to harden AWS and see your SOC 2 gaps at $0. [docs](https://docs.prowler.com/projects/prowler-open-source/en/latest/)
2. **Steampipe/Powerpipe** — SOC 2 benchmark in the AWS Compliance mod for repeatable checks. [hub](https://hub.powerpipe.io/mods/turbot/steampipe-mod-aws-compliance)
3. For the actual report, demo **both Vanta and Drata**, use competing quotes as leverage. Vanta edges ahead on solo-founder fit ("first security hire" positioning, AI auto-remediation, startup tier + discount); Drata is equally capable with a strong auditor network. Neither publishes prices (~$12K–$28K/yr per third-party data; **excludes** the separate auditor fee). [Vanta SOC2](https://www.vanta.com/products/soc-2) · [Drata SOC2](https://drata.com/frameworks/soc-2)

(ScoutSuite and OSS CloudSploit lack SOC 2 mappings — supplementary only.)

---

## 4. Endpoint: Hexnode vs Jamf Pro

**Verdict:** Jamf Pro is materially stronger on every audit-relevant axis for a CIS/SOC 2 Apple fleet. The differentiator isn't basic management (both lock screens) — it's **automated, attestable, benchmark-mapped evidence.**

- **CIS automation (decisive gap):** Jamf's free **Compliance Editor (JCE)** is built on the NIST-hosted **macOS Security Compliance Project (mSCP)** (NIST SP 800-219; Jamf is a listed co-author; Apple-acknowledged). It generates **CIS Level 1/2** config profiles, an audit-and-remediate script, per-device pass/fail Extension Attributes, and **PDF/Excel/HTML audit documents** — near-turnkey SOC 2 evidence. [JCE/mSCP](https://trusted.jamf.com/docs/establishing-compliance-baselines) · [mSCP](https://github.com/usnistgov/macos_security). Hexnode has compliance *policies* + custom `.mobileconfig` upload but **no native CIS-benchmark engine** — you map and assemble evidence by hand.
- **Audit logs / SIEM export:** Jamf's REST API breadth makes the SIEM pipeline cleaner; both require you to **export to your own retention store** (neither MDM should be your multi-year system of record).
- **DDM (Apple's strategic direction):** Jamf is consistently ahead (software-update enforcement, declarative status reporting).
- **SOC 2 CC6.x evidence:** Jamf wins on FileVault status + escrow reporting, OS-update enforcement via DDM, and auditor-ready exports.

**Recommendation:** harden Hexnode now (interim), then **migrate to Jamf Pro before the SOC 2 observation window opens** so the audit period runs on the platform that produces the cleanest evidence. Do **not** attempt the cutover *during* the observation window.

**Migration reality (solo, ~36 devices, 3 sites):** reassign device records in Apple Business Manager from Hexnode to Jamf; devices must unenroll/re-enroll (a wipe-and-enroll is cleanest for supervised state → per-device downtime + user re-setup); profiles do **not** transfer (rebuild in Jamf — JCE regenerates CIS baselines for you); reconfigure VPP/app assignments. **Plan a phased, site-by-site rollout over several weeks.**

**Interim Hexnode hardening:** enforce FileVault + recovery-key escrow; passcode/screen-lock + idle timeout (Mac + iPhone); OS-update/minimum-version compliance with auto-remediation; CIS-mapped custom config profiles (firewall, Gatekeeper, auto-updates); audit-log/webhook export to a retention store; and a **control-to-Hexnode-setting matrix** (this manual evidence work transfers into the Jamf project).

---

## 5. Google Workspace hardening

**The hard licensing lines** (verified against Google's [Business](https://knowledge.workspace.google.com/admin/getting-started/editions/compare-business-editions) and [Enterprise](https://knowledge.workspace.google.com/admin/getting-started/editions/compare-enterprise-editions) comparison pages):

- **Google Vault (retention/eDiscovery/legal hold) requires Business Plus or higher** — NOT in Starter or Standard.
- **DLP, Context-Aware Access, the actionable Security Investigation Tool, and log export to BigQuery / Google Security Operations (Chronicle)** are **Enterprise-only.**
- **2SV/MFA + security keys + alert center + report-only audit logs** are in **all editions** — enforce these regardless of tier (biggest free CC6.1 win).

**Tier recommendation:**
- **Minimum credible for SOC 2 = Business Plus** (~$22–26/user/mo, *verify*) — unlocks Vault + enforced 2SV/keys + alerts. Closes CC6/CC7 at a basic level.
- **Strong / recommended = Enterprise Standard** — adds DLP (CC6.7 exfil evidence), Context-Aware Access (conditional access, CC6.1), the actionable investigation tool, and **log export to BigQuery/Chronicle** (durable retention + SIEM). The log export alone often justifies the jump for an auditable shop. (Enterprise = quote-based; ~$23–30/user/mo commonly cited, *confirm with Google/reseller*.)
- BeyondCorp Enterprise (full zero-trust app access) is a *separate Google Cloud product* layered on top, not a Workspace edition tier — out of scope for a 36-person SOC 2.

**Pass-through:** Google Workspace rides Google Cloud's **SOC 2 Type II / SOC 3** (SOC 3 public; SOC 2 under NDA via Compliance Reports Manager). In your audit Google is a **carved-out subservice org** — get its current report for your auditor, and **map each CUEC** Google lists (enforce MFA, configure access/admin roles, enable+retain audit logs, configure DLP/retention, manage JML, review alerts) to a Workspace setting + evidence artifact. *Google attests to the platform; you attest to having configured it correctly.* [Google SOC 2](https://cloud.google.com/security/compliance/soc-2)

---

## 6. SIEM / logging for a solo admin

For one person the deciding factor is **who runs the infra and who maintains the detections** — not features. At 36 people your log volume is modest, so per-GB pricing is your friend and "free but self-hosted" (Wazuh) is expensive *in your time*.

| Tool | Pricing | Solo operability | Retention | SOC 2 fit |
|---|---|---|---|---|
| **Google SecOps (Chronicle)** | Quote-only; **Workspace + GCP logs ingest free ≤10 GB/day** (Enterprise+ SKU) | Fully managed; curated detections; 700+ parsers | **12 mo hot included** | **Excellent** |
| **Datadog Cloud SIEM** | ~$0.20/GB analyzed (*verify*) + log mgmt | Managed; Content Packs ship detections | Configurable (Flex Logs) | Strong |
| **Elastic Security** | Serverless ~$0.09–0.11/GB; self-mgd Basic free | Self-mgd = high maint.; serverless better | Configurable | Good |
| **Wazuh** | Self-host **free**; Cloud ~$571–1,467/mo | **Highest maintenance**; MDM via syslog only | Tiered | Workable, no SOC 2 module |
| **Panther** | Ingest-based, ~$65K/yr floor | Detection-as-code (Python) | **12 mo min** | Excellent but overkill |

**Recommendation: Google SecOps (Chronicle).** Fully managed (zero servers — the biggest solo win), **12 months hot retention included** (satisfies the SOC 2 ~1-year convention with no config), curated/maintained detections (you don't write a detection library), free Workspace+GCP ingest, and parsers covering CloudWatch/CloudTrail, UniFi (syslog), and MDM. Caveat: quote-only pricing may carry an enterprise floor; best features are Enterprise+. **Runner-up: Datadog Cloud SIEM — only if you already run Datadog for app observability** (then marginal cost/learning collapses). **Budget floor: Wazuh self-hosted** if cash is the hard constraint and you accept the maintenance. **Skip:** Panther (priced for security teams) and Elastic self-managed (you become the cluster operator).

> SOC 2 retention convention is **~1 year total, ~90 days hot** — industry practice, not a single AICPA-published number; confirm the window your CPA firm expects. Note both Chronicle and Panther include 12 months by default.

---

## 7. CMMC Level 1 — applicability to a roofing sub

**Applies only if you actually perform work on/under a federal (DoD) contract or subcontract where Federal Contract Information (FCI) resides in or transits your systems.** It's **contract-triggered, not industry-triggered** — no federal work = no CMMC, even on a federal building through a GC. The mechanism is flow-down: FAR 52.204-21(c) requires primes to push the safeguarding clause to subs that may handle FCI. [FAR 52.204-21](https://www.acquisition.gov/far/52.204-21)

- **CMMC L1 = FCI = FAR 52.204-21 = 15 basic safeguarding requirements**, **annual self-assessment + affirmation** in SPRS, **no POA&Ms allowed**. [DoD CIO](https://dodcio.defense.gov/CMMC/About/)
- **CMMC L2 = CUI = NIST SP 800-171 (110 reqs)** — a roofing sub **almost never handles CUI**, so **L1 is the realistic ceiling.** FCI for a roofer = non-public project drawings/specs/schedules/work orders generated for a federal building (simple payment info is excluded).
- **Overlap with CIS IG1:** completing IG1 genuinely satisfies the **large majority** of the 15 requirements (same NIST DNA). **Additive gaps are physical:** requirement (viii)/(ix) — limiting physical access, escorting visitors, and keeping **physical-access audit logs** — are weakly covered by CIS and easy to miss for a field-services company with a yard, warehouse, and trucks. IG2 overshoots L1 on the technical side.
- **Status (2026-06-20):** the 32 CFR program rule is final; the 48 CFR acquisition rule began **phased rollout Nov 10, 2025** — **we are in Phase 1**, where **L1 self-assessment** is operative when CMMC appears in a solicitation. [Fed. Reg. 2024-22905](https://www.federalregister.gov/documents/2024/10/15/2024-22905/cybersecurity-maturity-model-certification-cmmc-program)

**Action:** audit your actual contract clauses. If you take no federal work, document that determination and move on. If a federal re-roof through a GC is on the table, the additive lift over IG1 is mostly **physical security + a visitor log** plus the SPRS self-assessment/affirmation.

---

## 8. Your CISO-track certification roadmap

You hold **Security+, CySA+, PenTest+** + MS in progress — strong on technical/operational, gap is **cloud security depth, governance/management, and ISMS/audit fluency.**

**Recommended sequence (aligned to SOC 2 → AWS → cloud → governance):**

1. **AWS Certified Security – Specialty** *(now)* — **$300**, maps to your daily stack, fast credibility, and counts as an ISC2-approved credential (buys a CISSP experience year). [AWS](https://aws.amazon.com/certification/certified-security-specialty/)
2. **CISSP** *(next — the CISO anchor)* — 8 domains, lists "CISO" as a target role. Experience: 5 yr in 2+ domains; **your MS waives 1 year → 4**; Associate-of-ISC2 path lets you sit the exam now. [CISSP exp req](https://www.isc2.org/certifications/cissp/cissp-experience-requirements)
3. **ISO/IEC 27001 Lead Implementer** *(parallel / right after CISSP)* — the credential that best **teaches how to lead a SOC 2 effort** (ISMS = the control/documentation/evidence backbone overlapping SOC 2). Provisional tier available immediately. [PECB LI](https://pecb.com/en/education-and-certification-for-individuals/iso-iec-27001/iso-iec-27001-lead-implementer)
4. **CISM** — the governance/management half of the classic CISSP+CISM CISO pairing (**$575 member**; confirm your solo-admin role meets the "security management" experience definition). [ISACA CISM](https://www.isaca.org/credentialing/cism)
5. **CCSP** — deepen cloud/SaaS once CISSP clears its experience bar (an active CISSP **waives the entire CCSP experience requirement**). New exam outline Aug 1, 2026. [CCSP exp req](https://www.isc2.org/certifications/ccsp/ccsp-experience-requirements)
6. *(Optional)* **CRISC** / **GIAC GSLC** later; **CISA** if you'll repeatedly steer audits (auditor's-eye view). [CISA](https://www.isaca.org/credentialing/cisa)

> **Reframe:** "SOC 2" is not a personal certification — it's a CPA attestation against the Trust Services Criteria. "Leading a SOC 2 audit" = owning the control environment + readiness on the client side; **ISO 27001 Lead Implementer** is the credential that arms you for it.

---

## 9. Sequenced action roadmap

### 0–6 months — foundation & quick wins
- **Decide audit scope** (SaaS product vs corporate IT — §0); document the two scopes.
- **Finish CIS IG1**; stand up the **six shared-control domains** (§1.1) — MFA org-wide, centralized logging, vuln-scan cadence, asset inventory, IR plan, vendor-review process.
- **Enforce Google 2SV + security keys for admins** (free, all editions); evaluate **Business Plus** (Vault) vs **Enterprise Standard** (DLP/CAA/log export) and pick a tier.
- **Run Prowler `--compliance soc2_aws`** against the AWS account; remediate top findings. Add Steampipe/Powerpipe SOC 2 benchmark.
- **Lock the multi-tenant isolation model before the first external tenant** — implement pool+RLS with the non-owner role + `FORCE RLS` + per-connection tenant var; write the adversarial negative tests; verify pgBouncer doesn't share session state.
- **Move DB creds to Secrets Manager**; stand up tenant-attributed app audit logging + S3 Object Lock (Compliance) for immutable storage.
- **Harden Hexnode** (FileVault+escrow, screen-lock, OS-update compliance, CIS-mapped profiles, log export) and start the **control-to-setting matrix**.
- **Stand up the SIEM** — get a Google SecOps quote; onboard Workspace, CloudWatch/CloudTrail, UniFi (syslog), MDM.
- **Start AWS Security – Specialty** study.
- **CMMC check:** audit contract clauses; document FCI determination. If federal work is in scope, add a visitor log + physical-access controls.

### 6–18 months — formalize & attest
- **Adopt NIST CSF 2.0** as the governance backbone; build Current/Target Profiles mapping your controls.
- **Push CIS IG1 → IG2** (the 74 additional Safeguards).
- **Demo Vanta + Drata**, select one, and **engage a SOC 2 auditor**; run a readiness assessment.
- **Migrate Hexnode → Jamf Pro** (phased, site-by-site) **before** opening the SOC 2 observation window; rebuild CIS baselines via Jamf Compliance Editor.
- **Pen test** the SaaS product.
- **Open the SOC 2 Type II observation window** (Security + Availability + Confidentiality, + Privacy if PII) with a 3-month window for the first report.
- **Pass AWS Security – Specialty; begin CISSP.**

### 18–36 months — mature & scale
- **Earn the first SOC 2 Type II report**; move to a rolling 12-month window for renewals.
- **Pursue ISO 27001:2022** *only if* a customer demands the certificate (most Annex A controls already in place from IG2 + SOC 2).
- **Earn CISSP; start ISO 27001 Lead Implementer, then CISM.**
- **Mature multi-region residency** (silo-by-region for tenants with residency demands; account for Region-exempt global services).
- **Continuous monitoring** via the compliance platform + SecOps; quarterly access reviews, vendor re-reviews, and tabletop IR exercises as standing evidence.

---

## Roofing / construction-specific flags

- **CMMC is contract-triggered, not industry-triggered** — and FCI is broader than expected (project drawings/specs/schedules for a federal building qualify). A federal re-roof through a GC can pull a 36-person roofer into L1; CUI/L2 is very unlikely.
- **Physical security is your real CMMC gap, not IT** — visitor escorting + physical-access audit logs (FAR (viii)/(ix)) are weakly covered by CIS and easy to miss for a company with a yard, warehouse, and field crews.
- **Sole-admin segregation-of-duties** will be flagged by SOC 2 and ISO — design compensating controls (admin-action logging, documented approvals, owner sign-off) early; you can't hire it away at 36 people.
- **White-label multi-tenancy** raises logical tenant-isolation to a top-tier control (SOC 2 Confidentiality, ISO A.8.x) — build it into CIS 3/4 now, before the first external customer.

---

## Flagged uncertainties (verify before relying on)

- **SOC 2 cost/timeline figures (§2)** were not freshly verified this session (rate-limited) — confirm at the listed vendor/auditor URLs.
- **All pricing** (Google Workspace, SIEM tiers, cert exam fees beyond AWS/CISM/CRISC) is volatile and partly quote-only — confirm on live pages.
- **SOC 2 CC cell mappings (§1.1)** reflect standard TSC alignment — verify exact cells against the AICPA TSC PDF; OLIR crosswalks map at finer granularity (pull the XLSX for cell-exact evidence).
- **Hexnode internals** (audit-log granularity, API/webhook surface, DDM coverage) — Hexnode help pages are JS-rendered; verify at hexnode.com/mobile-device-management/help.
- **SOC 2 "90 days hot / 1 year" retention** is convention, not a published AICPA number — confirm with your CPA firm.
- **AWS "Bridge" terminology** differs between AWS's whitepaper (layered hybrid) and its Database Blog (schema-per-tenant) — specify which you mean.

---

## Related vault pages

- [[gunnerteam/soc2-technical-summary]] — current GunnerTeam product control posture (the SaaS-scope evidence this roadmap targets)
- [[gunnerteam/system-security-plan]] · [[gunnerteam/ssp-addendum-1-product-environment]] — SSP + product-environment addendum
- [[tyler/ciso-track/roadmap]] · [[tyler/ciso-track/cissp]] — Tyler's CISO certification track (§8 here)
- [[tyler/concepts/soc2]] — SOC 2 concept notes
- [[gunnerteam/federal-market]] — federal/CMMC market context (§7)

> [!note] Provenance
> Ingested 2026-06-20 (verbatim) from `security-compliance-roadmap.md` (`~/Documents/Claude/Projects/Gunner Team App/`). Org-wide program roadmap (frameworks → CIS/NIST/SOC 2/ISO/CMMC, SaaS architecture, Hexnode→Jamf, Google Workspace, SIEM, cert track). **All pricing/timeline figures are flagged estimates — verify before budgeting (see §"Flagged uncertainties").**
