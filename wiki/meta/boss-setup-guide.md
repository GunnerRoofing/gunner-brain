---
title: "Claude + Obsidian Wiki — Fresh Setup Guide"
type: gunner
tags: [meta, setup, onboarding]
created: 2026-04-14
updated: 2026-04-14
status: stable
related:
  - "[[meta/vault-commands-reference]]"
---

# Claude + Obsidian Wiki — Fresh Setup Guide

**For:** Anyone on the Gunner Claude Team account who wants to build their own AI-powered knowledge base.

**Time:** ~20 minutes. After setup, you build it out yourself by dropping in documents and having conversations.

---

## Step 1 — Install Obsidian

1. Go to obsidian.md → Download for Mac
2. Install and open it
3. Click **Create new vault** → name it → pick a location like `~/Documents/My Vault`
4. Note the full path — you'll need it later (e.g. `/Users/yourname/Documents/My Vault`)

---

## Step 2 — Install Node.js

1. Go to nodejs.org → download the **LTS** version
2. Install — defaults are fine
3. Verify: open Terminal, run `node --version`

---

## Step 3 — Install Claude Code

**Option A — Desktop App:** Download from claude.ai/download.

**Option B — Terminal:**
```bash
npm install -g @anthropic-ai/claude-code
```

Sign in with your Gunner Claude Team account when prompted.

---

## Step 4 — Install the claude-obsidian Plugin

```bash
claude plugin marketplace add
```
```bash
claude plugin install claude-obsidian@claude-obsidian-marketplace
```

> **Note:** If you get an SSH error (`Permission denied (publickey)`), run this first, then retry:
> ```bash
> git config --global url."https://github.com/".insteadOf "git@github.com:"
> ```

---

## Step 5 — Connect Claude to Your Vault (MCP)

```bash
claude mcp add obsidian-vault -- npx -y @bitbonsai/mcpvault@latest "/Users/yourname/Documents/My Vault"
```

You only need to do this once.

---

## Step 6 — Open Claude in Your Vault

**Desktop app:** Open Claude Code → Open Folder → select your vault folder.

**Terminal:**
```bash
cd "/Users/yourname/Documents/My Vault"
claude
```

---

## Step 7 — Bootstrap the Wiki

```
/wiki
```

Claude asks for a one-sentence description of your vault's purpose, then scaffolds the full folder structure, index, CLAUDE.md, and memory system automatically.

---

## Commands Reference

| Command | What it does |
|---------|-------------|
| `ingest [filename]` | Drop file in `raw-sources/` first, then run this |
| `what do you know about X?` | Query the wiki |
| `/save` | File current conversation as a wiki note |
| `lint the wiki` | Weekly health check |
| `/canvas` | Visual canvas status |
| `/autoresearch [topic]` | Autonomous web research loop |

---

## Tips

- Ingest everything you have — the more you put in, the more useful it gets
- Ask questions in plain English — Claude synthesizes answers with citations
- Close Claude Code normally — session-end hook updates the knowledge base automatically
- Context persists across sessions via `wiki/hot.md` and `Memory.md`

---

*Need help? Ask Tyler — he set this up for Gunner IT.*
