---
type: concept
title: "Cloudflare + SST custom domains (DNS-only, ACM) — token types, account ID, CSP gotcha"
created: '2026-07-01'
updated: '2026-07-01'
tags:
  - cloudflare
  - sst
  - pulumi
  - acm
  - dns
  - cloudfront
  - api-gateway
  - csp
  - cors
  - soc2
  - shared
status: stable
related:
  - '[[shared/rds-proxy-tls-and-sst-python-packaging]]'
  - '[[gunnerteam/aws-environment]]'
---

# Cloudflare + SST custom domains (DNS-only, ACM)

How to put a custom domain in front of an SST `StaticSite` (CloudFront) **and** an
`ApiGatewayV2`, with Cloudflare as **DNS-only** (`proxied=false`) and end-to-end **ACM/Amazon**
TLS — matching the house `api.<app>.gunnerroofing.com` shape (SOC 2 CC6.7). Distilled from the
comms-admin cc-13/14/15 arc, which burned ~90 minutes almost entirely on Cloudflare token
confusion. Read this first next time.

## The config (SST `sst.config.ts`)

```ts
// app().providers — pin after first resolve (read .sst/provider-lock.json)
providers: {
  aws:        { region: "us-east-2", version: "6.79.0" },
  cloudflare: { version: "6.13.0" },   // DNS records + ACM validation
},

// StaticSite (CloudFront) — cert issued in us-east-1 (CloudFront requirement)
domain: { name: "comms.gunnerroofing.com", dns: sst.cloudflare.dns() },

// ApiGatewayV2 — REGIONAL cert issued in the API's OWN region (us-east-2), NOT us-east-1
domain: { name: "api.comms.gunnerroofing.com", dns: sst.cloudflare.dns() },
```

- **Cert region differs by resource:** CloudFront/StaticSite → **us-east-1**; API Gateway regional
  → the **API's region (us-east-2)**. SST issues the right one automatically per `dns` set.
- `sst.cloudflare.dns()` is **DNS-only by default** (writes CNAME/CAA as `proxied=false`). If `dig`
  ever shows Cloudflare anycast (`104.x`) instead of the AWS target, force it:
  `dns: sst.cloudflare.dns({ proxy: false })`.
- **Break dependency cycles with literals, not references.** The frontend's `VITE_API_URL` and the
  API's `cors.allowOrigins` must be **literal hostnames**, never `api.url` / `site.url` — referencing
  the other resource's `.url` closes a Pulumi cycle. Custom hostnames are stable, so literals are correct.

## The token maze (this is what wastes the time)

Cloudflare tokens now use **scannable prefixed formats** (`cfat_`/`cfut_` + 40 chars + checksum ≈
**53 chars total**). **Length is NOT a validity signal** — do not gate on "40 chars"; that's the old
unprefixed format.

| Prefix | Type | Verify endpoint | SST wants |
|---|---|---|---|
| `cfut_` | **User** token (My Profile → API Tokens) | `GET /user/tokens/verify` | ✅ **this one** |
| `cfat_` | **Account**-owned token | `GET /accounts/{account_id}/tokens/verify` | ✗ can't self-discover account |

- **Wrong verify endpoint returns a misleading `1000 "Invalid API Token"`** even for a *valid* token.
  An account (`cfat_`) token hit against `/user/tokens/verify` **always** reads `1000`. Use the
  matching endpoint before concluding a token is dead.
- **Create the token via My Profile → API Tokens → "Edit zone DNS" template** → this yields a `cfut_`
  user token with exactly the right perms. Avoid the account-token wrapper UI (the "Account ID / JSON
  Payload / Terraform / Confirm" screen) — it's the account flow and adds friction.

### The permission that actually matters
The DNS-write permission is the row literally named **`DNS`** — *"Grants write access to DNS records"*.
It is **NOT** "Zone DNS Settings" (that's DNSSEC/zone-level toggles) and **NOT** "Zone" (zone config).
A **search filter of `zone` hides the `DNS` row** (its name doesn't contain "zone") — clear the filter.
Minimal correct set = **`Zone:DNS:Edit` + `Zone:Zone:Read`**, scoped to **Specific zone →
gunnerroofing.com**. The "Edit zone DNS" template is exactly these two.

- Diagnose write access with a real API write, not `verify`:
  `POST /zones/{zid}/dns_records` → `9109 "Unauthorized to access requested resource"` = missing
  `DNS:Edit`; `81058 "identical record already exists"` = **auth+perm PASSED** (a leftover probe
  record — the token works); `1000` = bad value/wrong verify context.

### Zone-scoped tokens can't self-discover the account
A zone-scoped "Edit zone DNS" token has no account-read permission, so `sst deploy` fails with:
`"The Cloudflare Account ID was not able to be determined from this token."` → **set
`CLOUDFLARE_DEFAULT_ACCOUNT_ID`** (our account: `912d0d5f5fd18c942dd57cf7d9cf0f17`). This is **not a
secret** — safe to persist in the repo/shell deploy env. The token stays in Keeper (`read -rs`, never
`=paste` — avoids the newline/quote contamination that reads as auth errors).

## The CSP gotcha that curl can't catch (custom API domain)
When the frontend is repointed to a custom API host (e.g. `VITE_API_URL=https://api.comms.gunnerroofing.com`),
the StaticSite's **`Content-Security-Policy: connect-src`** must list that host. If it only allows
`https://*.execute-api.us-east-2.amazonaws.com`, the custom host matches neither that nor `'self'`, and
**the browser CSP-blocks every API fetch** — while **all curl checks still pass** (curl ignores CSP).
Add the custom API origin to `connect-src`. This will silently break the app otherwise; the only proof
is a real browser + DevTools console, not curl.

## Deploy + verify checklist
1. `export CLOUDFLARE_API_TOKEN=…` (cfut_, via `read -rs`) **and** `export CLOUDFLARE_DEFAULT_ACCOUNT_ID=912d0d5f…`.
2. `AWS_PROFILE=mfa npx sst deploy --stage dev` (GunnerRequireMFA explicit-denies without the mfa profile;
   MFA via `awsmfa`). First deploy **blocks on ACM DNS validation** (~several min) — normal, don't Ctrl-C.
3. `dig +short <host>` → AWS target (`*.cloudfront.net` for the site, `d-*.execute-api…` for the API),
   **not** `104.x` Cloudflare anycast.
4. `openssl s_client -connect <host>:443 -servername <host> | openssl x509 -noout -issuer -subject` →
   issuer **Amazon**, subject = the custom host. (Right after deploy the cert/base-path mapping can lag
   a minute — an empty first `/health` is transient; retry.)
5. `curl -sI https://<host>/health` → 200; CORS preflight echoes the site origin.
6. **Browser:** open the site, log in, confirm Network calls hit the custom API host with **no CORS AND
   no CSP errors**. This is the only check that catches the CSP gap.

## Reference values (comms-admin, us-east-2, account 980921733684)
- Cloudflare zone `gunnerroofing.com` id: `003ce6220f4f034a1d0f4703799be37a`
- Cloudflare account id: `912d0d5f5fd18c942dd57cf7d9cf0f17`
- Provider pins: `aws 6.79.0`, `cloudflare 6.13.0`
- Live: `comms.gunnerroofing.com` (CloudFront), `api.comms.gunnerroofing.com` (API GW regional)

> **Token hygiene (resolved 2026-07-01):** a `cfat_` account token was exposed in a screenshot
> during this arc — it has since been **rotated** and the dead experiment tokens deleted. Lasting
> rule: never paste a token into an image or a committed file; env var only (`read -rs`, Keeper).
> The live deploy uses a `cfut_` user token + `CLOUDFLARE_DEFAULT_ACCOUNT_ID` (both persisted to the
> deploy env; token in Keeper).
