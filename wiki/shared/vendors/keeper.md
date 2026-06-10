---
title: Keeper Password Manager
type: vendor
tags: [keeper, passwords, iam, vendor, security]
created: 2026-04-13
updated: 2026-04-13
status: stable
sources: [Keeper Workshop.pptx, Acceptable Use Policy.docx, System Security Plan.docx]
related: ["[[gunner/environment]]", "[[vendors/google-workspace]]", "[[runbooks/acceptable-use-policy]]"]
---

# Keeper Password Manager

## What It Does

Keeper is the company-wide password manager for Gunner Roofing. It stores, generates, and audits passwords for all work accounts. Employees use Keeper to access credentials without needing to know or remember them.

## How It's Used at Gunner

- **Mandatory** for all employees with company devices (per AUP)
- Deployed as part of standard device setup
- All work account passwords should be stored and generated in Keeper
- Security Audit feature identifies weak, reused, or compromised passwords
- Credential management is a key part of the **offboarding ("Kill-Switch") process**
- Admin password rotation is triggered on any personnel change

## Key Rules (from AUP)

- All work account passwords must be stored in Keeper
- Personal passwords must not be stored in Keeper
- Passwords must be unique, randomly generated — never reused
- Keeper Master Password is the one password employees must remember (IT cannot reset it)
- Laptop/device password should also be saved in Keeper

## Passwords Employees Must Know

| Password | Notes |
|----------|-------|
| Keeper Master Password | Cannot be changed by Admin — employees own this |
| Laptop login password | Tip: also save this in Keeper |

All other passwords → Keeper generates and stores.

## Security Audit

Keeper's Security Audit feature surfaces:
- Weak passwords
- Reused passwords
- Compromised passwords (known breach data)

Employees were trained to review Security Audit and rotate flagged passwords as part of the Keeper Workshop. Priority accounts to audit: Google, My2N, CompanyCam, Contract Portal, GAF, Wells Fargo, Microsoft, etc.

## Offboarding Role

On employee separation, IT uses Keeper to:
- Ensure no shared credentials were sole-controlled by departing employee
- Rotate any shared credentials the employee had access to
- Revoke Keeper seat

## Admin Notes

- Admin cannot see or reset employee master passwords — this is by design
- If an employee forgets their master password, their vault is inaccessible — emphasize this during onboarding
- Shared credentials (e.g., Apple Business Manager, vendor portals) should be stored in shared Keeper folders, not individual vaults

## Integration Points

- Keeper is separate from Google SSO — it stores passwords for apps that do not support SSO
- Apps with Google SSO don't need stored passwords in Keeper (auth is handled by Google)
- For apps without SSO, Keeper is the authentication method
