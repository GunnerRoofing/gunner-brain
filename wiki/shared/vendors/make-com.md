---
title: Make.com
type: vendor
tags:
  - vendor
  - automation
  - integration
  - hubspot
created: '2026-04-16'
updated: '2026-04-23'
status: developing
sources: []
related:
  - '[[gunner/environment]]'
  - '[[vendors/hubspot]]'
  - '[[runbooks/hubspot-google-chat]]'
  - '[[gunner/hubspot-leads-project]]'
  - '[[gunner/aws-environment]]'
---
# Make.com

Make.com (formerly Integromat) is the automation platform used for HubSpot integrations and workflow automation at Gunner. It connects HubSpot events to external actions via polling triggers and webhooks.

## Active Scenarios

### Delete AWS-Created Deals (Workaround)

**Purpose:** The AWS custom script (`api-user.php` on EC2) creates both a Contact and a Deal in HubSpot. Until the script is rewritten to stop creating deals, this scenario deletes the deal automatically while leaving the contact intact. See [[gunner/aws-environment]] for full context on the EC2 script.

**Trigger:** HubSpot — Watch Objects (Deals, Created)
**Filter:** `wp_project_id` is greater than 0
**Action:** HubSpot — Delete a Deal (Deal ID mapped from trigger)

**Key implementation notes:**
- `wp_project_id` is a numeric custom deal property set only by the AWS script — it is the unique identifier for script-created deals
- Filter must use **greater than 0**, not "has any value" — HubSpot numeric fields do not evaluate correctly with the "has any value" operator in Make.com
- Output Properties in the Watch Objects module must include `wp_project_id` explicitly or the filter cannot access it
- Watch Objects polls on a schedule (not real-time) — deals created between poll cycles are caught on the next run
- Set starting point to **From now on** to avoid processing historical deals on first run
- Deleting a deal does not affect the associated contact

**Status:** Active workaround — will be retired when AWS script is updated to stop creating deals.

### HubSpot → Google Chat Notifications

**Purpose:** Surfaces HubSpot deal and lead events to the sales team in Google Chat.

See [[runbooks/hubspot-google-chat]] for setup details.

## Related

- [[vendors/hubspot]] — source system for Make.com triggers
- [[runbooks/hubspot-google-chat]] — HubSpot Chat notification setup
- [[gunner/hubspot-leads-project]] — HubSpot Lead object buildout context
- [[gunner/aws-environment]] — EC2 api-user.php whose deal-creation side effect this scenario mitigates
