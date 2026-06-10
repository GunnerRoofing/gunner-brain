---
title: Claude AI — Team Setup & Integration Options
type: gunner
tags:
  - claude
  - ai
  - hubspot
  - github
  - mcp
  - team
created: '2026-04-20'
updated: '2026-04-20'
status: in-progress
sources: []
related:
  - "[[gunner/gunner-assistant]]"
  - "[[vendors/hubspot]]"
---

# Claude AI — Team Setup & Integration Options

Notes on configuring Claude AI for the Gunner team — covering Claude.ai Team integrations and Claude Code tooling.

---

## Claude.ai Team — Integrations (Web)

Configured by admin at `claude.ai → Settings → Integrations`. Connections made at workspace level are available to all team members without individual setup.

**Available as of 2026-04-20:**
- HubSpot ✅ — OAuth with HubSpot super admin account
- GitHub ❌ — Not available in Claude.ai Team integrations yet (may be rolling out)

**How it works:** Team members can invoke connected integrations in conversations without any setup. Auth is handled via the admin's OAuth connection.

---

## Claude Code — GitHub MCP (Individual / Developer Use)

For org-wide repo scanning and code analysis, Claude Code with the GitHub MCP server is the right tool — not Claude.ai Team. Claude Code can read file trees, search across repos, analyze code structure, and answer questions about the codebase.

### Setup (Docker method — no Copilot required)

**Prerequisites:**
- Docker installed and running
- GitHub PAT (classic) with `repo` scope — create at `github.com/settings/tokens`

**Install:**
```bash
claude mcp add github \
  -e GITHUB_PERSONAL_ACCESS_TOKEN=your_token_here \
  -- docker run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server
```

**Verify:**
```bash
claude mcp list
```

Config is stored in `~/.claude.json` — applies to all Claude Code sessions for that user.

### Alternative — HTTP method (requires GitHub Copilot)

```bash
claude mcp add-json github '{"type":"http","url":"https://api.githubcopilot.com/mcp","headers":{"Authorization":"Bearer YOUR_COPILOT_TOKEN"}}'
```

Only works if the account has an active GitHub Copilot subscription.

---

## Use Case Decision Guide

| Goal | Right Tool |
|------|-----------|
| Team members ask HubSpot questions in chat | Claude.ai Team + HubSpot integration |
| Scan GitHub org, find things across repos | Claude Code + GitHub MCP |
| Answer questions about repo structure/code | Claude Code + GitHub MCP (or clone locally) |
| Roofing knowledge base for field staff | See [[gunner/gunner-assistant]] |

### Org-Wide Repo Scanning

For "find things across our GitHub org" — Claude Code + GitHub MCP or cloning repos locally is more effective than Claude.ai Team. Claude.ai's integrations are conversational (look up a specific PR or file), not indexing tools.

---

## Status

- HubSpot integration: available in Claude.ai Team admin console — **not yet connected**
- GitHub MCP (Claude Code): setup steps documented above — **not yet installed**
- GitHub integration for Claude.ai Team: not available as of 2026-04-20
