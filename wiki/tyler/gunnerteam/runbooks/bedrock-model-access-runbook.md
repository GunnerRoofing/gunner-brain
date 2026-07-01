---
type: runbook
title: GunnerTeam — Bedrock Model Access
created: '2026-06-25'
updated: '2026-06-25'
tags: [gunner, gunnerteam, runbook, aws, bedrock, llm]
status: stable
source: Gunner Team App/runbooks/bedrock-model-access-runbook.md
related: ["[[gunnerteam/gunnerteam-project-structure]]", "[[index]]"]
---

# Bedrock model access — set-once + adding new models going forward

## Why there's no "Option A toggle"

Per AWS: Bedrock model access is **enabled by default per account** in all commercial
regions, given three prerequisites on that account:
1. IAM perm `aws-marketplace:Subscribe` on whatever role first enables a model,
2. a valid payment method,
3. (Anthropic only) the first-time use-case form.

New models **auto-subscribe on first invoke** if the invoking role has
`aws-marketplace:Subscribe`. There is **no** org-wide "allow member accounts to
subscribe" switch — member accounts can already self-enable; the only org-level lever
is the *opposite* (restrict via SCP). So the real "set it for everyone" work is the two
parts below.

Source: https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html

## Part 1 — one-time org setup (management account 661095510147 · Eddie)

Submit the **Anthropic first-time use-case form once at the management/root account** —
AWS inherits it to every current and future member account in the org, so no account
ever has to do the Anthropic form again.

- Console: Bedrock → region **US East (Ohio) us-east-2** → Model catalog → open
  **Claude Sonnet** → submit the use-case form (use: "Internal business app for
  quoting, CRM, and operational workflows").
- or CLI (admin in mgmt acct): `aws bedrock put-use-case-for-model-access --form-data <base64-json>`

Optional — the dev account already has its own form done (proven by a working call).
This only smooths *future* accounts.

## Part 2 — enable a NEW model going forward (dev account 980921733684 · Tyler, admin profile)

When a new Claude model ships, an admin enables it **once**; the app's Lambda then just
invokes it. Keep the runtime Lambda least-privileged — `bedrock:InvokeModel` only (already
set in cc-1803). Do **not** add `aws-marketplace:Subscribe` to the runtime role; an admin
does enablement out-of-band.

Fastest (console): Bedrock → us-east-2 → **Model access** → **Modify model access** →
check the new model → Submit.

Scriptable (CLI, admin/`mfa` profile):
```bash
MID="anthropic.claude-<new-model-id>"        # from `aws bedrock list-foundation-models`
R="--region us-east-2 --profile mfa"
OFFER=$(aws bedrock list-foundation-model-agreement-offers --model-id "$MID" $R \
  --query 'offers[0].offerToken' --output text)
aws bedrock create-foundation-model-agreement --model-id "$MID" --offer-token "$OFFER" $R
aws bedrock get-foundation-model-availability --model-id "$MID" $R   # expect status AVAILABLE
```

Then adopt it in the app with **zero code change** — point the swappable client at it via
SSM (from cc-1801/1803):
```bash
aws ssm put-parameter --name /gunnerteam/dev/BEDROCK_MODEL_SMART \
  --value "us.anthropic.claude-<new>" --type String --overwrite --region us-east-2 --profile mfa
# re-bake env (targeted apply) + publish + alias, per the deploy rule
```
(New Claude models usually need the `us.`-prefixed **inference profile** id, not the bare
`anthropic.…` id — check `aws bedrock list-inference-profiles`.)

## Don't
- Don't grant the runtime Lambda `aws-marketplace:Subscribe` (least-priv; admin enables).
- Don't use the Private Marketplace / "allow member accounts" path — not how Bedrock
  access works; it's a different system.

## Current state (2026-06-24)
Dev account: Claude Sonnet 4.6 + Haiku 4.5 already enabled and live; app running on
Bedrock. Nothing required today — Parts 1 & 2 are for future accounts/models.
