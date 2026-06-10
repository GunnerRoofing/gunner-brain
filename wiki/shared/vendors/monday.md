---
title: Monday.com
type: vendor
tags: [monday, project-management, vendor, operations, automation, it]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [Departmental Comms.xlsx, Gunner IT Governance.xlsx, IT_Tasks_1775773048.xlsx]
related: ["[[gunner/environment]]", "[[gunner/app-inventory]]", "[[vendors/google-workspace]]"]
---

# Monday.com

## What It Does

Monday.com is Gunner Roofing's primary operations project management platform. IT also maintains a dedicated IT Dev board for ticket and request management.

## How It's Used at Gunner

### Operations
- Project management across operations and field teams
- Departmental task tracking
- Recurring task automation

### IT Dev Board
- IT request intake via the Gunner Forms iOS app (which wraps Monday WorkForms)
- Ticket lifecycle: submitted → in progress → done
- Automated notifications: completed tasks → Google Chat (via Make.com)
- Automated response email to requester when ticket closes

## SSO Status

Google SSO enabled (confirmed 2026-01-16 audit). Offboarding: Google account disable blocks login, but seat must be manually removed in Monday admin — step 3 in [[runbooks/offboarding]].

## Integrations

| Integration | Direction | Method |
|------------|-----------|--------|
| Gunner Forms (iOS) | Forms → Monday | Monday WorkForms (wrapped in ABM app) |
| Google Chat | Monday → Chat | Make.com automation |
| IT request → Chat | IT Dev board → notify Tyler | Make.com |
| Google Business Reviews | Reviews → Chat | Monday / Make.com |

## Gunner Forms iOS App

The internal Gunner Forms app is distributed via Apple Business Manager and wraps Monday WorkForms. Provides employees with IT request, service request, PTO, reimbursement, and referral forms in a native iOS experience. See [[concepts/apple-business-manager]].

## Renewal

- Renewal date: **unknown — verify with vendor**

## Related

- [[vendors/monday-api-reference]] — GraphQL API reference: search items, create/update, column value formats
- [[gunner/app-inventory]] — SSO/offboarding status
- [[vendors/google-workspace]] — IdP and SSO
- [[concepts/apple-business-manager]] — Gunner Forms app distribution
- [[gunner/environment]] — environment overview
