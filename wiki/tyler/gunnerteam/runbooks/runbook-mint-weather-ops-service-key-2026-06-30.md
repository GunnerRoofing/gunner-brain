---
type: runbook
title: GunnerTeam — Mint weather_alerts_read Service Key
created: '2026-06-30'
updated: '2026-06-30'
tags: [gunner, gunnerteam, runbook, secrets, weather, keys]
status: stable
source: Gunner Team App/runbooks/runbook-mint-weather-ops-service-key-2026-06-30.md
related: ["[[gunnerteam/gunnerteam-project-structure]]", "[[index]]"]
---

# Runbook — mint the `weather_alerts_read` service key for Colin (secret-safe)

One-off. Mints a scoped `gt_service_keys` row so Colin's app can poll `GET /weather/alerts/active`.
**Prereq: cc-3103 deployed** (adds `allowed_tasks` + the `gtsk_` prefix to `POST /templates/service-keys`).

Facts: API `https://api.team.gunnerroofing.com` · Cognito pool `us-east-2_hFVBSrcnn` · app client
`6m41qei5jq3nt46jler56im1cg` · the endpoint needs your **ID token** (reads `email` + `custom:tenantId`).

## 1. Get an admin ID token

The client already has `ALLOW_USER_PASSWORD_AUTH` (confirmed 2026-06-30) — use plain `initiate-auth`,
**no client change needed**, and `initiate-auth` takes **no** `--user-pool-id`:
```bash
read -rs GT_PW   # type your Cognito password, Enter
ID_TOKEN=$(aws cognito-idp initiate-auth --region us-east-2 \
  --client-id 6m41qei5jq3nt46jler56im1cg \
  --auth-flow USER_PASSWORD_AUTH \
  --auth-parameters USERNAME=tyler.suffern@gunnerroofing.com,PASSWORD="$GT_PW" \
  --query 'AuthenticationResult.IdToken' --output text)
unset GT_PW
echo "${ID_TOKEN:0:8}…"   # 'eyJ…' = non-empty, good
```
If empty/`None`, it's an MFA challenge — re-run without `--query` to read `ChallengeName` + `Session`, then:
```bash
ID_TOKEN=$(aws cognito-idp respond-to-auth-challenge --region us-east-2 \
  --client-id 6m41qei5jq3nt46jler56im1cg \
  --challenge-name SOFTWARE_TOKEN_MFA \
  --challenge-responses USERNAME=tyler.suffern@gunnerroofing.com,SOFTWARE_TOKEN_MFA_CODE=<6-digit> \
  --session "<Session from the previous response>" --query 'AuthenticationResult.IdToken' --output text)
# (SMS_MFA + SMS_MFA_CODE if your MFA is SMS)
```

## 2. Mint the scoped key (returned once)
```bash
curl -sS -X POST https://api.team.gunnerroofing.com/templates/service-keys \
  -H "Authorization: Bearer $ID_TOKEN" -H "Content-Type: application/json" \
  -d '{"description":"Colin ops weather poll","allowed_tasks":["weather_alerts_read"]}' \
  | jq -r .key | pbcopy
unset ID_TOKEN
```
- The `gtsk_…` key is now on your clipboard (server stores only its sha256 hash). If it 403s, your DB
  role isn't `admin` for org 69aad261; if 401, the token expired (re-run step 1).

## 3. Hand off + verify
- Paste into **Keeper**, share that record with Colin, then clear your clipboard (`pbcopy </dev/null`).
- Send Colin `colin-weather-ops-poll-contract-2026-06-30.md`.
- Smoke test (optional): `curl -sS https://api.team.gunnerroofing.com/weather/alerts/active -H "Authorization: Bearer <the gtsk_ key>"` → `200 {"alerts":[…]}`. A key without the scope → `403 task_not_allowed`.

## Revoke (if ever needed)
`GET /templates/service-keys` (admin token) to find the `id`, then `DELETE /templates/service-keys/:id`.

---
**Never** paste the ID token or the `gtsk_` key into chat, tickets, or logs. The only durable copy is Keeper.
If the token dance is painful and you'd rather a no-token, reusable path, say so — I'll spec option D
(a `provision_gt_service_key` action on the migrate-Lambda: sha256 + `gt_service_keys` + `allowed_tasks`,
in-VPC, audited).
