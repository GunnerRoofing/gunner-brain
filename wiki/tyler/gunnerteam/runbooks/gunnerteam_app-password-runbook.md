---
type: runbook
title: GunnerTeam — Set gunnerteam_app DB Password
created: '2026-06-22'
updated: '2026-06-22'
tags: [gunner, gunnerteam, runbook, masterdb, secrets, postgres]
status: stable
source: Gunner Team App/runbooks/gunnerteam_app-password-runbook.md
related: ["[[gunnerteam/gunnerteam-project-structure]]", "[[index]]"]
---

# Runbook — set `gunnerteam_app` password (Tyler, terminal; secret-safe)

**You run this, not Claude Code.** Generate once, push to all three destinations from the same shell
session, never echo it. The DB role lives in a private-subnet Aurora (no direct connect) — the only
write path is the migrate-Lambda `set_gunnerteam_app_password` action (added in cc-2138).
Keeper is the **source of truth** — store there FIRST so the value can't drift across destinations.

> Secrets rule: never print a var ending in `_PASSWORD`/`_SECRET`/`_KEY`/`_TOKEN`. This runbook uses
> `PW` and never echoes it (only its length). The migrate action sets it server-side via `format(%L)` —
> it is not logged.

## 0. Prereqs
- Active `mfa` AWS profile, us-east-2.
- The role exists already (cc-2138). Do this AFTER the grant audit / any dev downgrade test — a
  downgrade drops the role and re-upgrade recreates it password-less.

## 1. Generate (charset matches the action's validator `[A-Za-z0-9!@#%^&*_+=-]{16,128}`)
```bash
PW=$(LC_ALL=C tr -dc 'A-Za-z0-9!@#%^&*_+=-' < /dev/urandom | head -c 40); echo "len=${#PW}"   # expect len=40
```

## 2. Store in Keeper FIRST (source of truth)
Paste `$PW` into a new Keeper record (`gunnerteam_app / masterdb dev`) by hand — don't pass it as a CLI
arg (shell history). If you must use Keeper Commander, disable history for that command.

## 3. Set it on the DB role via the migrate Lambda (private-VPC write path)
Write the payload to a `0600` temp file, invoke, shred — never put the secret in process args/history.
```bash
FN=gunner-masterd-dev-MasterApi2RouteBbovcaHandlerFunction-wssoombt
umask 077; PJ=$(mktemp); trap 'shred -u "$PJ" 2>/dev/null || rm -f "$PJ"' EXIT
printf '{"action":"set_gunnerteam_app_password","password":"%s"}' "$PW" > "$PJ"

# swap handler → migrate, invoke, swap back (brief dev-API blip; or use the throwaway
# migration-Lambda variant per CONTRIBUTING §2 if you don't want to touch the main fn)
aws lambda update-function-configuration --function-name "$FN" --handler db/migrate.handler --region us-east-2 --profile mfa
aws lambda wait function-updated --function-name "$FN" --region us-east-2 --profile mfa
aws lambda invoke --function-name "$FN" --payload "fileb://$PJ" --cli-binary-format raw-in-base64-out \
  --region us-east-2 --profile mfa /tmp/out.json
aws lambda update-function-configuration --function-name "$FN" --handler api/main.handler --region us-east-2 --profile mfa
aws lambda wait function-updated --function-name "$FN" --region us-east-2 --profile mfa
cat /tmp/out.json    # expect {"status":"ok","detail":"..."} — NOT the password
```

## 4. Proxy secret — needs Colin (don't block on it)
The proxy authenticates as the role using its Secrets Manager secret; the proxy is Colin's. When he's
back, put the SAME `$PW` (`{"username":"gunnerteam_app","password":"<PW>"}`) into the proxy's secret —
either he updates it, or he gives you the secret ARN + permission and you run:
```bash
# only with the real ARN from Colin:
aws secretsmanager put-secret-value --secret-id <PROXY_SECRET_ARN> \
  --secret-string "$(printf '{"username":"gunnerteam_app","password":"%s"}' "$PW")" \
  --region us-east-2 --profile mfa
```
Until step 4 lands, `gunnerteam_app` is set on the DB but the proxy can't use it yet — harmless, the
role is inert until cutover (cc-2137).

## 5. Clean up
```bash
unset PW; rm -f /tmp/out.json    # $PJ already shredded by the trap
```
Banked in Keeper, set on the role; proxy-secret + GUC (Colin) + cred swap (cc-2137) remain.
