---
title: Cloudflare
type: vendor
status: stable
tags: [vendor, cloudflare, dns, networking, cdn, waf]
created: 2026-05-07
updated: 2026-05-07
related:
  - "[[tyler/gunnerteam/gunnerteam-api-aws-migration]]"
  - "[[gunnerteam/aws-environment]]"
  - "[[gunnerteam/environment]]"
---

# Cloudflare

## What It Does

Cloudflare is a cloud network platform providing DNS, CDN, DDoS mitigation, WAF (Web Application Firewall), and serverless compute (Workers/D1). Gunner uses it across several layers of the stack.

---

## How It Is Used at Gunner

### DNS

Cloudflare manages DNS for Gunner domains. All DNS records are maintained in the Cloudflare dashboard. DNS proxying (orange-cloud) is enabled for public-facing services.

### Cloudflare Pages

Gunner has deployed static front-end assets via Cloudflare Pages. Used for the GunnerForms application UI.

### Workers and D1 (Legacy — Being Migrated Away)

Cloudflare Workers (serverless edge compute) and D1 (SQLite-based edge database) were previously used as the backend for the GunnerTeam API and related automations. This stack is actively being migrated to AWS (Lambda + DynamoDB). See [[tyler/gunnerteam/gunnerteam-api-aws-migration]] for migration status and rationale.

> [!gap]
> Workers/D1 migration is in progress as of 2026-05-07. Some routes or data may still be served from Workers during transition. Verify current state before making DNS or routing changes.

### WAF

Cloudflare WAF rules are in place for public-facing properties. Review WAF logs periodically for anomalous traffic patterns.

---

## Key Configs and Quirks

- DNS TTL: Cloudflare proxied records report a TTL of 1 (automatic); actual cache TTL is managed by Cloudflare.
- SSL/TLS mode: Should be set to **Full (Strict)** for all proxied origins that have valid certs.
- Workers subdomain: Legacy Workers routes are bound to a `workers.dev` subdomain; production traffic should route through custom domains.

---

## Integration Points

- [[tyler/gunnerteam/gunnerteam-api-aws-migration]] — Migration away from Workers/D1 to AWS
- [[gunnerteam/aws-environment]] — Target infrastructure for the migration
- [[gunnerteam/gunner-forms-app]] — GunnerForms uses Cloudflare Pages for the front end

---

## Support and Access

- Dashboard: https://dash.cloudflare.com
- Access: Tyler Suffern (account owner / IT admin)
- Support tier: Free/Pro — community support; upgrade to Business for priority support if needed.

---

## Renewal / Billing

Cloudflare Free/Pro plans are billed annually or monthly via the Cloudflare dashboard. Confirm plan tier and billing cycle in the account settings.
