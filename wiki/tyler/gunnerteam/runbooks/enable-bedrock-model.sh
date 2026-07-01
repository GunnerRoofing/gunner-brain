#!/usr/bin/env bash
# enable-bedrock-model.sh — enable a Bedrock foundation model in an account, idempotently.
# Usage: ./enable-bedrock-model.sh <model-id> [region] [profile]
#   e.g. ./enable-bedrock-model.sh anthropic.claude-opus-4-8
# Run as an ADMIN role (AmazonBedrockFullAccess + aws-marketplace:Subscribe).
# The runtime Lambda role stays InvokeModel-only — enablement is an out-of-band admin step.
set -euo pipefail

MID="${1:?Usage: enable-bedrock-model.sh <model-id> [region] [profile]}"
REGION="${2:-us-east-2}"
PROFILE="${3:-mfa}"
AWS=(aws --region "$REGION" --profile "$PROFILE")

status() { "${AWS[@]}" bedrock get-foundation-model-availability --model-id "$MID" \
  --query 'agreementAvailability.status' --output text 2>/dev/null || echo "UNKNOWN"; }

echo "→ Checking $MID ($REGION) ..."
if [ "$(status)" = "AVAILABLE" ]; then echo "✓ Already enabled — nothing to do."; exit 0; fi

echo "→ Fetching agreement offer ..."
OFFER=$("${AWS[@]}" bedrock list-foundation-model-agreement-offers --model-id "$MID" \
  --query 'offers[0].offerToken' --output text)
[ -n "$OFFER" ] && [ "$OFFER" != "None" ] || {
  echo "✗ No offer token. Check the model id, or submit the Anthropic first-time use-case form first."; exit 1; }

echo "→ Creating agreement ..."
"${AWS[@]}" bedrock create-foundation-model-agreement --model-id "$MID" --offer-token "$OFFER" >/dev/null

echo "→ Verifying (up to ~2 min) ..."
for _ in 1 2 3 4 5 6; do
  S=$(status); [ "$S" = "AVAILABLE" ] && { echo "✓ Enabled: $MID"; exit 0; }
  echo "   status=$S — waiting ..."; sleep 20
done
echo "✗ Not AVAILABLE yet — verify the Anthropic first-time form + a valid payment method on this account."; exit 1
