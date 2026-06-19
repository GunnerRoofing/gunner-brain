---
type: process
owner: tyler
created: '2026-06-15'
updated: '2026-06-15'
status: active
tags:
  - process
  - deploy
  - git
  - contributing
---

# Contributing & Deploy Workflow — GunnerTeam

**Audience:** everyone who touches the GunnerTeam backend, iOS app, or its infrastructure — internal Gunner engineers and external contractors (e.g. WL-CompanyCam / Project Hub).

**The one rule everything else serves:** **git is the single source of truth.** What's deployed must equal what's committed. No exceptions.

---

## 1. Repositories & ownership

| Repo | Owns | Deploys to |
|---|---|---|
| `GunnerRoofing/gunner-ios` (`gunnerteam-api/`, `GunnerForms/`, `terraform/`) | GunnerTeam backend (Lambda), iOS app, GunnerTeam infra | Lambda `gunnerteam-dev-api`, alias `live` |
| `gunner-masterdb` (SST) | Shared Aurora cluster, RDS Proxies, DB secrets/SGs | masterdb cluster + proxies |
| `WL-CompanyCam` (Project Hub) | The `/api/external/v1/*` integration (projects, photos, tasks, signing) | `project.dev.gunnerroofing.com` |

**Cross-repo boundary:** if a change touches infrastructure another repo owns (e.g. the masterdb cluster, an RDS Proxy, a shared secret/SG), it is made **in that repo's IaC by its owner** — never by hand from another team's CLI. Coordinate in writing; the change lands in code.

## 2. Branching & commits — scoped to who's involved

**`gunner-ios` is single-maintainer (Tyler).** No PR/review ceremony for your own iOS/backend work:
- Work directly on `main`. Commit **early and often** — your working tree is not a backup. (The 2026-06-15 iOS revert happened because a full session of work sat uncommitted and was lost on a checkout. "Git is the source of truth" here just means *commit your work*.)
- Keep the one long-lived branch **`forms-quick-fix-2026-05`** for the build currently shipped to the Apple App Store; merge into it only fixes meant for that shipped build.
- That's it for solo work — `main` + the App Store branch.

**The heavier rules below apply when more than one party can change something** — the shared Lambda runtime (Colin and automated sessions also deploy to it), the shared masterdb/RDS Proxies, and the cross-app integration contracts. There, deploy only from committed git, reconcile before deploying, never hand-patch the live artifact, and get the owning team's sign-off for shared-infra changes. Review is required for cross-team / shared-infra changes — not for your solo commits.

## 3. Deploy — only from a clean `main`

The Lambda runtime is shared (others deploy to it), so deploy discipline applies here regardless of the solo-repo allowance above. Before deploying, confirm your working tree **equals deployed**: `git status` clean, on `main`, your iOS/backend work **committed** (not sitting in the working tree), pulled. If you're unsure whether the live Lambda has drifted from `main`, **reconcile first** (download the live bundle and diff — see §6) before shipping anything.

Backend deploy (the full block — `update-function-code` alone does NOT route traffic):

```bash
cd ~/Dev/GunnerTeam/gunnerteam-api
zip -r /tmp/gunnerteam-deploy.zip . -x "*.git*" "node_modules/.cache/*" && \
aws s3 cp /tmp/gunnerteam-deploy.zip s3://gunnerteam-lambda-deploy-useast2/gunnerteam-deploy.zip \
  --region us-east-2 --profile mfa && \
aws lambda update-function-code --function-name gunnerteam-dev-api \
  --s3-bucket gunnerteam-lambda-deploy-useast2 --s3-key gunnerteam-deploy.zip \
  --region us-east-2 --profile mfa && \
aws lambda wait function-updated --function-name gunnerteam-dev-api --region us-east-2 --profile mfa && \
VERSION=$(aws lambda publish-version --function-name gunnerteam-dev-api --region us-east-2 \
  --profile mfa --query 'Version' --output text) && \
aws lambda update-alias --function-name gunnerteam-dev-api --name live \
  --function-version "$VERSION" --region us-east-2 --profile mfa
```

API Gateway routes through the `live` alias — skipping publish + alias means the change never goes live.

## 4. Everything-in-IaC (no out-of-band changes)

The deploy block above ships **code only.** Configuration and infrastructure are code too:

- **Lambda env vars** (e.g. `DB_HOST`) are set by Terraform (`terraform/lambda-api.tf`), sourced from SSM. To change one: update the SSM param, then `terraform plan` → review → `terraform apply`. A code deploy will **not** change env vars.
- **Security groups, IAM, API Gateway, RDS Proxies, SSM params** live in `terraform/` (or the owning repo's SST config). Never click-change them in the console or one-off via CLI without codifying.
- **DB migrations** are inline in the `migrations` object in `gunnerteam-api/src/lambda.js` and run via the `_migration` Lambda event handler — not loose SQL files, not manual `ALTER TABLE`.

If you change infra by hand to put out a fire, that's an **emergency change** — back-port it to IaC and log it the same day (see the Change-Management Policy).

## 5. Never patch the deployed artifact directly

Do **not**:
- edit the deployed Lambda's code/config outside a git-based deploy,
- run an `sst deploy` / CLI infra change that isn't reflected in the repo,
- deploy a local tree you haven't reconciled with what's live.

Every one of these creates drift between git and production, and drift is what caused the 2026-06-15 incident (three parties shipping to one Lambda; mystery code; un-deployable source).

## 6. If git and production have already drifted — reconcile

Download the live bundle and diff it against your tree before you trust either side:

```bash
URL=$(aws lambda get-function --function-name gunnerteam-dev-api --qualifier live \
  --region us-east-2 --profile mfa --query 'Code.Location' --output text)
rm -rf /tmp/live && mkdir -p /tmp/live && curl -s -o /tmp/live.zip "$URL" && unzip -q -o /tmp/live.zip -d /tmp/live
diff -rq /tmp/live/src "$HOME/Dev/GunnerTeam/gunnerteam-api/src"
```

Bring any deployed-only change into the repo via PR, then resume normal deploys from `main`.

## 7. Pre-deploy checklist

- [ ] On `main`, pulled; **your work is committed** (nothing important left only in the working tree).
- [ ] Backend: `node --check` on changed `.js`; relevant tests pass.
- [ ] iOS: builds clean; no new warnings.
- [ ] Infra/env changes are in Terraform / SST (not console/CLI one-offs).
- [ ] If drift was suspected, reconciled (§6).
- [ ] Deploy via the full block; confirm `live` points at the new version.
- [ ] Smoke-test the changed path.

## 8. Working with Claude Code on these repos

Read `CLAUDE.md` (repo root + `gunnerteam-api/`) first — it encodes the audit-hardened, white-label, secrets, migration, and deploy rules this project requires. See the **Claude Code Rules Onboarding** doc for the distilled version. Claude-generated changes follow the same commit-to-main (solo) or branch → PR → review (shared surface) flow as any other change.
