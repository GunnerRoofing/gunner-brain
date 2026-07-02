---
title: Dialpad
type: vendor
tags:
  - dialpad
  - voip
  - vendor
  - communication
created: 2026-04-13T00:00:00.000Z
updated: 2026-04-16T00:00:00.000Z
status: stable
sources:
  - Departmental Comms.xlsx
  - Gunner IT Governance.xlsx
  - IT_Tasks_1775773048.xlsx
related:
  - '[[gunnerteam/environment]]'
  - '[[gunnerteam/app-inventory]]'
  - '[[runbooks/dialpad-out-of-office]]'
  - '[[gunnerteam/dialpad-hubspot-integration]]'
  - '[[gunnerteam/lead-assignment-automation]]'
---

# Dialpad

## What It Does

Dialpad is Gunner Roofing's VoIP platform for all customer-facing communication — inbound/outbound calls and SMS. Primary phone number (866-262-6005) routes through Dialpad across all three offices.

## How It's Used at Gunner

- Customer calls, outbound sales calls, SMS
- Department routing and call queues
- Company-wide contact directory organized in Dialpad admin
- Per-user OOO / vacation routing (see [[runbooks/dialpad-out-of-office]])
- CarPlay configured for hands-free use

## SSO Status

**Unclear — verify.** The 2026-01-16 audit lists Dialpad under "Google SSO enabled," but the offboarding checklist also lists Dialpad under apps requiring manual deprovision. Likely explanation: Dialpad supports Google SSO for login, but removing a user's seat still requires manual action in Dialpad admin even after disabling the Google account.

**Offboarding action required:** Manual deprovision in Dialpad admin — step 8 in [[runbooks/offboarding]].

## VoIP Audit (2025)

A full market audit was conducted when Dialpad experienced service quality issues. Alternatives evaluated:

| Vendor | Result |
|--------|--------|
| GoTo | Tested — HubSpot integration evaluated; not selected |
| RingCentral | Briefly tested; eliminated |
| Dialpad | Retained — audit provided leverage to resolve service issues |

A2P (Application-to-Person) SMS registration completed for compliance during this period.

## Known Issues (Resolved)

Individual user issues (Leslie, John Miller, Pam, Roger) resolved during the VoIP audit period.

## Support & Renewal

- Renewal date: **unknown — verify with vendor**
- Service issues: escalate using audit findings as leverage with Dialpad support

## HubSpot Integration

The native Dialpad HubSpot integration is unreliable — calls and texts do not consistently log to contacts or associated deals. A custom webhook-based integration is being built to replace it. See [[gunnerteam/dialpad-hubspot-integration]] for the full architecture and [[gunnerteam/lead-assignment-automation]] for the round-robin lead assignment system. See [[gunnerteam/hubspot-leads-project]] for project context and [[vendors/dialpad-api-reference]] for the full API spec.

## Related

- [[vendors/dialpad-api-reference]] — Full API reference: webhooks, calls, SMS, contacts, auth
- [[runbooks/dialpad-out-of-office]] — OOO, vacation status, DND, SMS auto-reply
- [[gunnerteam/dialpad-hubspot-integration]] — Custom webhook integration architecture (call/SMS logging)
- [[gunnerteam/lead-assignment-automation]] — Round-robin lead assignment automation using Dialpad availability
- [[gunnerteam/app-inventory]] — SSO/offboarding status
- [[gunnerteam/environment]] — environment overview
- [[gunnerteam/hubspot-leads-project]] — Lead object buildout; Dialpad integration in scope
