---
type: reference
owner: tyler
created: 2026-06-11
updated: 2026-06-11
tags: [meta, memory, persistent]
status: active
---

# Persistent Memory — Tyler Suffern

Facts that should survive across every session. Claude reads this alongside `hot.md` at session start.

---

## Identity
- **Name:** Tyler Suffern
- **Role:** IT Manager — Gunner Roofing LLC
- **Location:** Stamford CT HQ
- **GitHub:** GunnerRoofing org

## AWS
- **Account:** 980921733684
- **Region:** us-east-2
- **Lambda:** `gunnerteam-dev-api`, alias `live`
- **Prod Aurora:** `gunner-masterdb-production-masterdbcluster-sczazkvf.cluster-c52gm8goign8.us-east-2.rds.amazonaws.com`
- **Dev Aurora:** `gunner-masterdb-dev-masterdbcluster-kdsmbssw.cluster-c52gm8goign8.us-east-2.rds.amazonaws.com` (different VPC from Lambda — unreachable directly)
- **Deploy bucket:** `gunnerteam-lambda-deploy-useast2`, key `function.zip`
- **MFA ARN:** `arn:aws:iam::980921733684:mfa/tylerMFA`
- **MFA profile:** `mfa` (base profile: `default`)
- **awsmfa broken on Python 3.14** — use manual `sts get-session-token` block instead

## GunnerTeam App
- **iOS repo:** `~/Dev/GunnerTeam/GunnerForms/`
- **Backend repo:** `~/Dev/GunnerTeam/gunnerteam-api/`
- **API base:** `https://api-dev.team.gunnerroofing.com`
- **Cognito pool:** us-east-2
- **S3 fleet bucket:** `gunner-fleet-prod`
- **Gunner org ID:** `69aad261-347c-44db-8e9e-6c25a8509aa3`

## Key Patterns
- **`_stmts` Lambda runner:** Deploy with handler, invoke SQL batches against prod Aurora, remove handler, redeploy. Never publish to `live` with `_stmts` active.
- **Color tokens:** `AppBackground`/`AppSurface` come from Xcode asset catalog — do NOT add manual `extension Color` for them (causes `invalid redeclaration`).
- **Lambda VPC:** Lambda is in `vpc-0530f022b0273f215`. Prod Aurora is in the same VPC. Dev Aurora is in `vpc-0eb66556f100c7b3c` (unreachable from Lambda).
- **Live alias verification:** After every deploy, confirm `DB_HOST` points to prod Aurora — it has silently reverted to dev in the past.

## Preferences
- **Haptic style:** `.light` for nav/UI, `.medium` for actions, `.success`/`.warning` for outcomes
- **Error states:** `loadError: String?` pattern with Retry button — established in cc-302
- **Font tokens:** `Font.appX` static vars in `ThemeManager.swift` (UIFontMetrics-backed)
- **No trailing summaries in responses**
- **No "let me know if you need anything"**
