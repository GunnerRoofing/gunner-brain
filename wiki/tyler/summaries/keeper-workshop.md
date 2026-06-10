---
title: "Keeper Workshop — Staff Training"
type: summary
tags: [keeper, passwords, security, training]
created: 2026-04-21
updated: 2026-04-21
sources: [Keeper Workshop.pptx]
related:
  - "[[vendors/keeper]]"
  - "[[runbooks/onboarding]]"
  - "[[runbooks/offboarding]]"
status: stable
---

# Keeper Workshop — Staff Training

Staff-facing training presentation for Keeper password manager rollout. Used during initial deployment to walk employees through setup and usage.

## Core Message

Employees imported old passwords from Google into Keeper. The problem: many were weak, reused, or compromised. The fix: generate new random complex passwords for every account — Keeper remembers them, employees only need to remember two things:

1. **Keeper Master Password** — cannot be reset by admin; employee owns this
2. **Laptop Password** — tip: save this in Keeper too

## How to Find Compromised Passwords

1. Log into Keeper
2. Click **Security Audit** in the left sidebar
3. Review the list of flagged accounts — these need new passwords

## Priority Accounts to Change

- Google Workspace
- My2N
- CompanyCam
- Contract Portal
- GAF
- Wells Fargo
- Microsoft
- (Any others flagged in Security Audit)

## Context

- Passwords were migrated from Google Password Manager at rollout
- Keeper is mandatory for all Gunner staff (see [[runbooks/onboarding]])
- Admin cannot reset master passwords — employees are responsible for theirs
- Accounts are exported at offboarding (see [[runbooks/offboarding]])
