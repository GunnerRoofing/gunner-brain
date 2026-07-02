---
title: "iOS Development Workflow — Claude Code + Xcode + GitHub"
type: question
tags: [ios, xcode, git, github, swift, development, workflow]
created: 2026-04-21
updated: 2026-04-21
sources: []
related:
  - "[[gunnerteam/gunner-forms-app]]"
status: stable
---

# iOS Development Workflow — Claude Code + Xcode + GitHub

Reference for how Claude Code, Xcode, and GitHub fit together when working on the GunnerForms app (or any iOS project).

## The Three Tools and Their Roles

| Tool | Role |
|------|------|
| **Claude Code** | Edits `.swift` files directly on disk — the code author |
| **Xcode** | Builds and runs the app in the simulator — the build/test tool |
| **GitHub** | Stores the full history of the project in the cloud — the backup and version history |

Claude Code edits files → switch to Xcode → **Cmd+R** to build and run → see result in simulator → repeat → commit when satisfied → push to GitHub.

## The Folder IS the Repo

`/Users/tyler.suffern/Documents/GunnerForms` is not just the code — it contains the entire history of the project inside a hidden `.git` folder. GitHub is a cloud copy of the same thing. Never delete the folder to "reset" — use git instead.

## Branches

Branches are parallel versions of the same folder. When you switch branches, git swaps the files on disk. Xcode sees the change immediately.

```bash
# Create a new branch and switch to it
git checkout -b feature/my-feature

# Switch to an existing branch
git checkout main

# List all branches
git branch -a
```

**Golden rule:** `main` = always working, always shippable. Never commit half-finished work there.

## The Development Loop

```bash
# 1. Make sure you're on the right branch
git checkout feature/my-feature

# 2. Claude Code edits files
# 3. Switch to Xcode, hit Cmd+R, test in simulator
# 4. Repeat until satisfied

# 5. Commit
git add GunnerForms/GunnerForms/ContentView.swift
git commit -m "Add pull to refresh"

# 6. Push to GitHub
git push origin feature/my-feature
```

## Merging a Feature into Main

When a feature is done and tested:

```bash
git checkout main                        # switch to main
git merge feature/my-feature             # bring the feature in
git push                                 # sync to GitHub
git branch -d feature/my-feature         # optional: delete the branch
```

## Where to Run Git Commands

- **Claude Code** — just ask; Claude runs git commands via Bash tool
- **Terminal** — `cd /Users/tyler.suffern/Documents/GunnerForms`, then type commands
- **Xcode Source Control menu** — exists but clunky; avoid for anything beyond viewing history

## Submitting to the App Store

1. Bump **Build** number in Xcode → Target → General (not Version — Build)
2. Set destination to **Any iOS Device (arm64)** — can't archive to simulator
3. **Product → Archive** → Organizer opens automatically
4. **Distribute App → App Store Connect → Upload** → follow prompts
5. Go to App Store Connect to submit the build for review

## GunnerForms Branch Map

| Branch | Purpose |
|--------|---------|
| `main` | App Store version — always shippable |
| `feature/sign-in-with-monday` | Original Monday.com sign-in flow (preserved, removed for 4.8 compliance) |
| `feature/gunner-assistant` | Claude API assistant tab (future) |

## Key Lesson: Never Delete the Folder

If you want to "go back" to the original version, just run `git checkout main`. The folder stays, the files change. Downloading from GitHub and replacing files is never necessary — git handles all of that locally.
