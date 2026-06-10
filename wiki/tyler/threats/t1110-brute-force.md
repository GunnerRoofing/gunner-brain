---
title: T1110 — Brute Force
type: threat
tags: [mitre, t1110, brute-force, credential-access, threat]
created: 2026-04-13
updated: 2026-04-13
status: developing
sources: []
related: ["[[concepts/mfa]]", "[[vendors/google-workspace]]", "[[vendors/keeper]]", "[[threats/t1078-valid-accounts]]"]
---

# T1110 — Brute Force

**Tactic:** Credential Access  
**Technique ID:** T1110  
**Sub-techniques:** T1110.001 (Password Guessing), T1110.002 (Password Cracking), T1110.003 (Password Spraying), T1110.004 (Credential Stuffing)

## Description

Adversaries attempt to gain access by systematically guessing or trying credentials. Credential stuffing (T1110.004) is particularly relevant at Gunner's scale — attackers use credentials from public data breaches to try accounts at other services, exploiting password reuse.

## Gunner Exposure

| Factor | Detail |
|--------|--------|
| Primary surface | Google Workspace accounts (internet-facing) |
| Password reuse risk | Reduced by mandatory Keeper policy; residual risk from non-compliant users |
| Credential stuffing | Google accounts; non-SSO apps (ADP, Wells Fargo, etc.) |

## Controls in Place

| Control | Coverage |
|---------|---------|
| [[concepts/mfa]] | MFA per OU — password-only brute force against Google SSO is effectively blocked |
| [[vendors/keeper]] | Mandatory password manager — unique, random passwords eliminate reuse |
| [[vendors/google-workspace]] | Login challenge on anomalous signals; account lockout; suspicious activity alerts |
| Admin password policy | 12-char min, complexity, 90-day rotation, Keeper-managed |
| Keeper Security Audit | Surfaces passwords flagged in known breach data |

## Detection Notes

- Google Workspace login challenge fires on anomalous IP, location, or device signals
- Admin OU: every login alerted — unusual patterns surface quickly
- Keeper Security Audit flags compromised passwords proactively

## Gaps

- Non-SSO apps (ADP, Wells Fargo, etc.) are not covered by Google MFA — credential stuffing against these is harder to detect and block
- No SIEM to correlate failed login attempts across services
- Keeper adoption must be actively maintained — non-adopters are a residual reuse risk

## Outcome

Successful brute force results in [[threats/t1078-valid-accounts]] — the adversary gains a valid session indistinguishable from normal user activity.

## Related

- [[concepts/mfa]] — primary mitigation; renders password-only attacks against Google SSO ineffective
- [[vendors/keeper]] — password uniqueness; kills reuse vector
- [[threats/t1078-valid-accounts]] — downstream outcome of successful brute force
- [[runbooks/incident-response]] — account compromise procedure if brute force succeeds
