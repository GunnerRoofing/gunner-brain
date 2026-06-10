---
title: Claude + Obsidian Wiki — Fresh Setup Guide
type: gunner
tags:
  - meta
  - setup
  - onboarding
created: '2026-04-14'
updated: '2026-04-14'
status: stable
related:
  - '"[[meta/vault-commands-reference]]"'
---

# Claude + Obsidian Wiki — Fresh Setup Guide

**For:** Anyone on the Gunner Claude Team account who wants to build their own AI-powered knowledge base.

**Time:** ~20 minutes. After setup, you build it out yourself by dropping in documents and having conversations.

---

## Step 1 — Install Obsidian

Obsidian is the visual interface for your vault. Free download.

1. Go to [obsidian.md](https://obsidian.md) → Download for Mac
2. Install and open it
3. Click **Create new vault** → name it (e.g. "My Vault") → pick a location like `~/Documents/My Vault`
4. Note the full path to the folder — you'll need it in later steps
   - Example: `/Users/yourname/Documents/My Vault`

---

## Step 2 — Install Node.js

Required for the MCP server that connects Claude to your vault.

1. Go to [nodejs.org](https://nodejs.org) → download the **LTS** version
2. Install it — defaults are fine
3. Verify: open Terminal and run `node --version` — should print a version number

---

## Step 3 — Install Claude Code

Claude Code is the AI assistant CLI. It uses your existing Claude Team account.

**Option A — Desktop App (easiest):**
Download from [claude.ai/download](https://claude.ai/download).

**Option B — Terminal:**
```bash
npm install -g @anthropic-ai/claude-code
```

Sign in with your Gunner Claude Team account when prompted.

---

## Step 4 — Install the claude-obsidian Plugin

This installs the wiki skill system that powers the knowledge base.

Open Terminal and run these commands one at a time:

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

This lets Claude read and write pages in your vault directly.

Run this in Terminal — replace the path with your actual vault path:

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

Once Claude is open inside your vault, run:

```
/wiki
```

Claude will ask you for a one-sentence description of what your vault is for (e.g. *"Sales strategy and customer notes for Gunner Roofing"*), then scaffold the full folder structure, index, CLAUDE.md, and memory system automatically.

---

## You're Done — Now Build It Out

| Action | Command |
|--------|---------|
| Add a document to the knowledge base | Drop file in `raw-sources/` → `ingest [filename]` |
| Ask a question using your vault | Just ask — *"What do I know about X?"* |
| Save an important conversation | `/save` |
| Weekly health check | `lint the wiki` |
| Create a visual board of everything | `/canvas` |
| Research a topic autonomously | `/autoresearch [topic]` |

---

## Tips

- **Ingest everything you have** — meeting notes, PDFs, spreadsheets, docs. The more you put in, the more useful it gets.
- **Ask it questions in plain English** — Claude searches the vault and answers with citations.
- **Close Claude Code normally** — the session-end hook updates the knowledge base automatically every time.
- Context persists across sessions — Claude remembers what you worked on last time.

---

## Need Help?

Ask Tyler — he set this up for Gunner IT and has been running it since April 2026.
