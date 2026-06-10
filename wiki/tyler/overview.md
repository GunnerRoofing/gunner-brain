---
type: overview
owner: tyler
created: 2026-06-10
status: active
---

# Tyler — Section Overview

## Role

Vault owner, IT/Ops lead, and GunnerTeam iOS app owner. Tyler runs the shared
`gunner-brain` vault, owns the GunnerTeam iOS application end-to-end, and is
responsible for Gunner Roofing's IT/Ops and security posture.

## GunnerTeam iOS App

Swift/SwiftUI iOS app for Gunner Roofing field crews. It integrates with
**GunnerCam** (the CompanyCam white-label deployment) for photos and project
data, and is backed by a **Lambda API on AWS**. **v3.0** ships in the App
Store. Development runs through the **cc-prompts** workflow (Claude Code →
Xcode → GitHub).

## IT/Ops

Owns Gunner Roofing's IT and operations: manages the **AWS infrastructure**,
**Cognito** identity, internal tooling, and the overall **security posture**
(CIS/CMMC alignment, MDM, MFA, access reviews).

## Key Integrations

- **GunnerCam** — customer photos and project webhooks (white-label CompanyCam).
- **gunner-ops** — job data flowing in from Leo's CRM (replacing Monday.com).
- **Monday.com** — current job sync source of record.
- **Stripe** — change-order (CO) invoicing.

## Vault Ownership

As vault owner, Tyler maintains **`wiki/hot.md`** and **`wiki/index.md`**, and
runs **/lint** across the full vault to keep every section (`tyler/`,
`gunnerteam/`, `colin/`, `leo/`, `doug/`, `shared/`) healthy and merged cleanly.

## Related

- [[index]]
- [[hot]]
- [[gunnerteam/overview]]
