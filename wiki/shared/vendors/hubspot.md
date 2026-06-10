---
title: HubSpot
type: vendor
tags:
  - hubspot
  - crm
  - vendor
  - sales
  - automation
created: 2026-04-13T00:00:00.000Z
updated: 2026-04-23T00:00:00.000Z
status: stable
sources:
  - Departmental Comms.xlsx
  - Gunner IT Governance.xlsx
  - IT_Tasks_1775773048.xlsx
related:
  - '[[gunner/environment]]'
  - '[[gunner/app-inventory]]'
  - '[[gunner/hubspot-sales-pipeline]]'
  - '[[gunner/hubspot-leads-project]]'
  - '[[gunner/hubspot-salesperson-sop]]'
  - '[[vendors/google-workspace]]'
  - '[[gunner/dialpad-hubspot-integration]]'
  - '[[gunner/lead-assignment-automation]]'
  - '[[gunner/aws-environment]]'
---

# HubSpot

## What It Does

HubSpot is Gunner Roofing's sales CRM. It manages the full lead and deal lifecycle, from initial lead capture through closed deals.

## How It's Used at Gunner

- Lead capture and management — full Lead object buildout in progress (see [[gunner/hubspot-leads-project]])
- Deal pipeline tracking and stale deal management (see [[gunner/hubspot-sales-pipeline]])
- Customer communication log
- Google Business Reviews notifications surfaced via Google Chat integration
- Sales team primary workspace

## SSO Status

Google SSO enabled (confirmed 2026-01-16 audit). Onboarding: manual invite in HubSpot admin required first, then Google SSO for day-to-day login. Offboarding: manual deprovision in HubSpot admin — step 2 in [[runbooks/offboarding]]. Disabling the Google account alone does not remove the HubSpot seat.

SCIM (automated provisioning) requires a paid HubSpot tier — not currently in use.

## Active Projects

| Project | Status |
|---------|--------|
| [[gunner/hubspot-leads-project]] — Lead object buildout | In progress (as of 2026-04-13) |
| [[gunner/hubspot-sales-pipeline]] — Stale deal management | Complete — reports and workflows live |

## Pipeline Configuration

- Lifecycle stages: Inbound → Lead → Not Qualified → Opportunity → Customer → Win Back
- Lead statuses and round-robin reassignment configured
- 15-minute auto-reassignment for uncontacted leads
- 120-day no-activity deal detection via reports and workflows

## Integrations

| Integration | Direction | Method |
|------------|-----------|--------|
| Google Chat | HubSpot → Chat | Make.com |
| Google SSO | Auth | Google SAML |
| GoTo (Dialpad alt) | Tested during VoIP audit | Not selected — Dialpad retained |
| Dialpad (custom) | Bidirectional | Custom Lambda webhook receiver — see [[gunner/dialpad-hubspot-integration]] |
| Lead assignment | HubSpot → Lambda → HubSpot | Round-robin automation — see [[gunner/lead-assignment-automation]] |
| WordPress (via AWS) | WordPress → EC2 → HubSpot | api-user.php on EC2 creates contacts from web form submissions — see [[gunner/aws-environment]] |

## Renewal

- Renewal date: **unknown — verify with vendor**

## Related

- [[vendors/hubspot-api-reference]] — API reference: contact search, call/note engagements, associations
- [[gunner/hubspot-sales-pipeline]] — stale deal management
- [[gunner/hubspot-leads-project]] — Lead object buildout (in progress)
- [[gunner/hubspot-salesperson-sop]] — Sales Workspace SOP for salesperson day-to-day use (IT-SOP-HUB-002)
- [[gunner/dialpad-hubspot-integration]] — Custom Dialpad → HubSpot call/SMS logging architecture
- [[gunner/lead-assignment-automation]] — Round-robin lead assignment; HubSpot workflows trigger Lambda
- [[gunner/aws-environment]] — EC2 api-user.php creates HubSpot contacts from WordPress submissions
- [[gunner/app-inventory]] — SSO/offboarding status
- [[vendors/google-workspace]] — IdP and SSO
