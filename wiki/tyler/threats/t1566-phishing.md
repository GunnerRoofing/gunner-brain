---
title: T1566 — Phishing
type: threat
tags: [mitre, t1566, phishing, initial-access, threat]
created: 2026-04-13
updated: 2026-04-13
status: developing
sources: []
related: ["[[concepts/email-security]]", "[[vendors/knowbe4]]", "[[concepts/mfa]]", "[[runbooks/incident-response]]", "[[threats/t1078-valid-accounts]]"]
---

# T1566 — Phishing

**Tactic:** Initial Access  
**Technique ID:** T1566  
**Sub-techniques:** T1566.001 (Spearphishing Attachment), T1566.002 (Spearphishing Link), T1566.003 (Spearphishing via Service)

## Description

Phishing uses deceptive emails, messages, or links to trick users into revealing credentials, downloading malware, or granting access. One of the most common initial access vectors for ransomware and account compromise.

## Gunner Exposure

| Factor | Detail |
|--------|--------|
| Staff profile | Non-technical field staff; high email and SMS volume |
| Primary surface | Gmail; gunnerroofing.com domain |
| Secondary surface | SMS/Dialpad (smishing) — outside Chrome Safe Browsing coverage |
| Active simulation | KnowBe4 phishing program with custom roofing-industry templates |

## Controls in Place

| Control | Coverage |
|---------|---------|
| [[concepts/email-security]] — DMARC p=reject | Blocks domain spoofing of @gunnerroofing.com to external recipients |
| [[concepts/email-security]] — SPF, DKIM | Authenticates outbound mail |
| [[concepts/email-security]] — MTA-STS | Forces TLS on inbound SMTP |
| [[vendors/knowbe4]] — PAB | Phish Alert Button — users report suspicious emails directly |
| [[vendors/knowbe4]] — simulations | Custom roofing-industry phishing templates; remedial training for failures |
| Chrome Safe Browsing (Enhanced) | Real-time phishing link detection; blocks known phishing URLs |
| HTTPS-only mode (Chrome policy) | Forces encrypted connections |
| [[concepts/mfa]] | Limits value of captured credentials — second factor still required |

## Detection Notes

- Google Workspace login alerts surface suspicious logins if credentials are captured
- KnowBe4 PAB provides user-reported threat signals
- No email gateway or SIEM — reliant on Google's built-in filtering + user reporting

## Gaps

- DMARC prevents @gunnerroofing.com spoofing outbound but does not block inbound phishing from other domains
- Field staff on iPhones may receive smishing (SMS phishing) outside Chrome Safe Browsing
- No formal security awareness program documentation — KnowBe4 deployed but formal program ownership is a POAM gap

## Gunner-Specific Note

KnowBe4 has deployed custom phishing templates mimicking roofing industry communications (supplier invoices, permit notices, etc.). This is appropriate given the industry. A real phishing example has been documented — see [[vendors/knowbe4]].

## Response

If credentials captured: follow [[runbooks/incident-response]] — Procedure 2 (Account Compromise). Disable Google account, rotate passwords, review audit logs.

## Related

- [[concepts/email-security]] — DMARC/SPF/DKIM/MTA-STS; primary technical control
- [[vendors/knowbe4]] — phishing simulation and user training
- [[concepts/mfa]] — mitigates credential harvest outcome
- [[threats/t1078-valid-accounts]] — downstream result if phishing succeeds
