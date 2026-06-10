---
title: SendGrid
type: vendor
tags:
  - vendor
  - email
  - transactional
created: '2026-04-16'
updated: '2026-05-12'
status: stable
sources: []
related:
  - '[[gunner/environment]]'
  - '[[concepts/email-security]]'
---
# SendGrid

> [!gap] This page is a stub. Expand with: use cases, API key management, sending domains, volume, pricing tier.

SendGrid is Twilio's transactional email platform. SendGrid access has been established for gunnerroofing.com — used for outbound transactional or marketing email flows separate from Gmail.

## How It's Used at Gunner

- Transactional email — sending domain: gunnerroofing.com
- Access established via Becky's account (see [[gunner/completed-projects]] — Email Domain Security)
- Used in the context of the Gunner Team app and any automated outbound email flows separate from Gmail

## Email Security Note

SendGrid must be included in the gunnerroofing.com SPF record to avoid DMARC failures. See [[concepts/email-security]] for Gunner's full email security posture.
