---
title: "Claude Session Onboarding Prompt"
type: gunner
tags: [claude, vault, gunner, ios, workflow]
created: 2026-05-19
updated: 2026-05-19
sources: []
related:
  - "[[gunner/claude-team-setup]]"
  - "[[meta/claude-obsidian-setup-guide]]"
  - "[[gunner/gunner-forms-app]]"
  - "[[gunner/aws-environment]]"
status: active
---

# Claude Session Onboarding Prompt

Paste at the start of any new Claude Code session in this vault to prime context quickly.

---

```
You are working inside my Obsidian Second Brain vault for Gunner Roofing.

Who I am: Tyler Suffern — IT Manager, sole admin for ~36-person roofing company.
CISSP next. 10-year CISO track. MS in Cybersecurity done July 2025.

This vault is dual-domain — security/sysadmin knowledge AND active iOS app development.
Treat it as permanent memory, not a one-shot conversation.

Session start protocol (do this now, in order):
1. Read Memory.md — open items, active projects, recent decisions
2. Read wiki/hot.md — ~500-word live cache of recent changes and pending actions
3. Read wiki/index.md only if I ask a question or request an ingest

My stack:
- GunnerTeam app: Swift/SwiftUI iOS + Node.js/Express on AWS Lambda, PostgreSQL + RLS,
  S3, APNs, Terraform. Context files in .claude/context/long-term/ — read before any code.
  Project root: ~/Dev/GunnerTeam/ (moved 2026-05-22 from ~/Documents/GunnerTeam/)
- Subcontractor Portal: React+Vite+TypeScript frontend + Python Lambda backend.
  Project root: ~/Dev/subportal/
- IT stack: Hexnode MDM, Google Workspace (primary IdP), Keeper, Dialpad, HubSpot,
  Unifi, OPNsense homelab.

Available skills:
- ingest [file] — process raw-sources/, create wiki pages, update index/log/hot
- query: [question] — answer from wiki with citations
- /save — file this conversation as a structured wiki note
- /autoresearch [topic] — 3-round web research loop → wiki pages
- /canvas — Obsidian canvas management
- lint the wiki — full vault health check

Operating rules:
- Never modify raw-sources/ — read only
- Never let a session end without updating wiki/log.md and wiki/hot.md
- For any code change beyond a trivial edit: plan first, wait for "go"
- queryWithTenant() always for user data — raw query() = P0 multi-tenancy bug
- Flag anything that looks like credentials — do not copy into wiki pages

Confirm you've read Memory.md and hot.md, then state:
(1) the top open action item, (2) the current active thread on the iOS app,
and (3) one open security gap. Then ask what I want to work on.
```

---

## Notes

- The 3-point confirmation at the end proves the reads actually happened vs. just being acknowledged.
- The `queryWithTenant()` line front-loads the P0 multi-tenancy rule so it's active before any code is suggested.
- Update this prompt if the skill names or stack changes significantly.
