---
title: AWS IAM Least Privilege + Dev Team Access Model
type: runbook
tags:
  - aws
  - iam
  - security
  - access-control
status: pending — execute at end of first dev wave
created: 2026-05-20T00:00:00.000Z
related:
  - '[[gunner/aws-environment]]'
  - '[[concepts/soc2]]'
updated: '2026-05-22'
---

# AWS IAM Least Privilege + Dev Team Access Model

**Execute at end of first wave of development.** Do not run until development is stable and team composition is known.

**Account:** `980921733684` (Gunner-Dev), region `us-east-2`

**DO NOT delete `tyler-cli` until SSO CLI is confirmed working.**
**Do not delete any users.**

---

## Context

Interim state before IAM Identity Center (SSO) is enabled org-wide (requires Eddie / management account). When SSO is set up, IAM users for humans get retired — groups and permission policies carry forward.

---

## Preflight — Audit current state before changing anything

```bash
aws iam list-users --query 'Users[*].{User:UserName,Created:CreateDate}' --output table

aws iam list-groups --query 'Groups[*].GroupName' --output table

# Who has active access keys
aws iam list-users --query 'Users[*].UserName' --output text | \
  tr '\t' '\n' | while read user; do
    keys=$(aws iam list-access-keys --user-name "$user" \
      --query 'AccessKeyMetadata[?Status==`Active`].AccessKeyId' --output text)
    if [ -n "$keys" ]; then echo "$user: $keys"; fi
  done

# Who has console access
aws iam list-users --query 'Users[*].UserName' --output text | \
  tr '\t' '\n' | while read user; do
    aws iam get-login-profile --user-name "$user" 2>/dev/null \
      && echo "$user has console access"
  done

aws iam get-account-password-policy 2>/dev/null || echo "No password policy set"
```

---

## Phase 1 — Create IAM Groups

```bash
for group in gunner-readonly gunner-developers gunner-devops gunner-admins; do
  aws iam create-group --group-name $group
done
aws iam list-groups --query 'Groups[*].GroupName' --output table
```

---

## Phase 2 — Attach Permission Policies

```bash
aws iam attach-group-policy --group-name gunner-readonly \
  --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

aws iam attach-group-policy --group-name gunner-developers \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

aws iam attach-group-policy --group-name gunner-devops \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
aws iam attach-group-policy --group-name gunner-devops \
  --policy-arn arn:aws:iam::aws:policy/IAMReadOnlyAccess

aws iam attach-group-policy --group-name gunner-admins \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

### MFA Enforcement Policy (attach to all groups)

```bash
cat > /tmp/require-mfa-policy.json << 'POLICY'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowViewAccountInfo",
      "Effect": "Allow",
      "Action": ["iam:GetAccountPasswordPolicy", "iam:ListVirtualMFADevices"],
      "Resource": "*"
    },
    {
      "Sid": "AllowManageOwnMFA",
      "Effect": "Allow",
      "Action": [
        "iam:CreateVirtualMFADevice",
        "iam:EnableMFADevice",
        "iam:GetUser",
        "iam:ListMFADevices",
        "iam:ResyncMFADevice"
      ],
      "Resource": [
        "arn:aws:iam::*:mfa/${aws:username}",
        "arn:aws:iam::*:user/${aws:username}"
      ]
    },
    {
      "Sid": "DenyWithoutMFA",
      "Effect": "Deny",
      "NotAction": [
        "iam:CreateVirtualMFADevice",
        "iam:EnableMFADevice",
        "iam:GetUser",
        "iam:ListMFADevices",
        "iam:ResyncMFADevice",
        "sts:GetSessionToken"
      ],
      "Resource": "*",
      "Condition": {
        "BoolIfExists": {"aws:MultiFactorAuthPresent": "false"}
      }
    }
  ]
}
POLICY

aws iam create-policy \
  --policy-name GunnerRequireMFA \
  --policy-document file:///tmp/require-mfa-policy.json \
  --description "Deny all actions if MFA not present"

MFA_POLICY_ARN=$(aws iam list-policies \
  --query 'Policies[?PolicyName==`GunnerRequireMFA`].Arn' --output text)

for group in gunner-readonly gunner-developers gunner-devops gunner-admins; do
  aws iam attach-group-policy --group-name $group --policy-arn $MFA_POLICY_ARN
done
```

> ⚠️ **After attaching MFA policy:** any user in a group is immediately locked out of IAM operations until they enroll MFA. Enroll MFA for your own user FIRST before attaching this policy, or use a separate admin session to finish setup.

---

## Phase 3 — Create Individual IAM Users

Fill in actual team members before running. Format: `firstname.lastname`.

```bash
USERS=(
  "firstname.lastname"   # role: developer
  "firstname.lastname"   # role: developer
)

for user in "${USERS[@]}"; do
  aws iam create-user --user-name "$user"
  TEMP_PASS="Gunner-$(openssl rand -hex 6)!"
  aws iam create-login-profile \
    --user-name "$user" \
    --password "$TEMP_PASS" \
    --password-reset-required
  echo "$user — temp password: $TEMP_PASS"
done
```

**Distribute temp passwords via Keeper, not Slack or email.**

---

## Phase 4 — Assign Users to Groups

```bash
# Admins
aws iam add-user-to-group --user-name tyler-cli --group-name gunner-admins

# Developers — fill in names
for user in "firstname.lastname"; do
  aws iam add-user-to-group --user-name "$user" --group-name gunner-developers
done

# DevOps
for user in "firstname.lastname"; do
  aws iam add-user-to-group --user-name "$user" --group-name gunner-devops
done

# ReadOnly (stakeholders, PMs)
for user in "firstname.lastname"; do
  aws iam add-user-to-group --user-name "$user" --group-name gunner-readonly
done
```

---

## Phase 5 — Account Password Policy

```bash
aws iam update-account-password-policy \
  --minimum-password-length 16 \
  --require-uppercase-characters \
  --require-lowercase-characters \
  --require-numbers \
  --require-symbols \
  --max-password-age 90 \
  --password-reuse-prevention 12 \
  --allow-users-to-change-password

aws iam get-account-password-policy
```

---

## Phase 6 — Offboard a User

For each person being offboarded (do NOT delete the user):

```bash
OFFBOARD_USER="firstname.lastname"

# Disable console access
aws iam delete-login-profile --user-name $OFFBOARD_USER 2>/dev/null || true

# Deactivate all access keys
aws iam list-access-keys --user-name $OFFBOARD_USER \
  --query 'AccessKeyMetadata[*].AccessKeyId' --output text | \
  tr '\t' '\n' | while read key; do
    [ -z "$key" ] && continue
    aws iam update-access-key \
      --user-name $OFFBOARD_USER --access-key-id $key --status Inactive
    echo "Deactivated $key"
  done

# Remove from all groups
aws iam list-groups-for-user --user-name $OFFBOARD_USER \
  --query 'Groups[*].GroupName' --output text | \
  tr '\t' '\n' | while read group; do
    [ -z "$group" ] && continue
    aws iam remove-user-from-group --user-name $OFFBOARD_USER --group-name $group
    echo "Removed from $group"
  done

echo "$OFFBOARD_USER offboarded."
```

---

## MFA Enrollment for tyler-cli (CLI flow)

Run this yourself — do not paste output into Claude Code.

```bash
aws iam create-virtual-mfa-device \
  --virtual-mfa-device-name tyler-cli \
  --outfile /tmp/tyler-mfa-qr.png \
  --bootstrap-method QRCodePNG

open /tmp/tyler-mfa-qr.png   # scan into authenticator app

aws iam enable-mfa-device \
  --user-name tyler-cli \
  --serial-number arn:aws:iam::980921733684:mfa/tyler-cli \
  --authentication-code1 <code1> \
  --authentication-code2 <code2>

# Get MFA-authenticated session (12 hours)
aws sts get-session-token \
  --serial-number arn:aws:iam::980921733684:mfa/tyler-cli \
  --token-code <code> \
  --duration-seconds 43200

export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
```

---

## EC2 Access Model

No new EC2s use shared key pairs. All human access via SSM Session Manager.

```bash
# Verify SSM agent
aws ssm describe-instance-information \
  --filters Key=InstanceIds,Values=<INSTANCE_ID> \
  --query 'InstanceInformationList[*].{ID:InstanceId,Ping:PingStatus}' \
  --output table --region us-east-2

# Connect (no port 22 needed)
aws ssm start-session --target <INSTANCE_ID> --region us-east-2
```

Instances need `AmazonSSMManagedInstanceCore` on their IAM role.

---

## Acceptance Criteria

- [ ] Every human has their own IAM user — no shared credentials
- [ ] All users in appropriate groups — no direct policy attachments
- [ ] MFA policy attached to all groups
- [ ] Account password policy set (16 char, 90 day rotation)
- [ ] Offboarded users: login profile deleted, keys inactive, removed from groups
- [ ] tyler-cli MFA enrolled and confirmed working
- [ ] No active access keys on any shared/service accounts that are no longer needed

## Next Step After This Runbook

Ask Eddie to enable IAM Identity Center at the org management account level. When SSO is live, IAM users for humans are retired — groups/policies carry forward. SSM Session Manager replaces all SSH key pair access permanently.
