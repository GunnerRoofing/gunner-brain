---
type: session
title: "Project Folder Migration — ~/Documents/Gunner/ canonical root"
created: 2026-05-22
updated: 2026-05-22
tags:
  - gunner
  - project-structure
  - migration
  - subportal
  - masterdb
status: active
related:
  - "[[gunner/masterdb-architecture]]"
  - "[[gunner/subportal-cc-prompt-01-scaffold]]"
  - "[[gunner/subportal-cc-prompt-02-frontend]]"
  - "[[gunner/gunnerteam-api-aws-migration]]"
  - "[[gunner/claude-session-onboarding]]"
sources: []
---

# Project Folder Migration — `~/Documents/Gunner/` Canonical Root

## What Changed

All Gunner development projects now live under a single canonical root: `~/Documents/Gunner/`. The legacy location `~/Documents/Claude/Projects/Gunner Team App/` remains intact but is no longer the working home for any project.

## Final Layout

```
~/Documents/Gunner/
├── GunnerTeam/
│   ├── gunnerteam-api/        ← Express.js API (AWS Lambda)
│   ├── GunnerForms/           ← iOS app (Swift/SwiftUI)
│   ├── terraform/             ← IaC
│   ├── CLAUDE.md
│   ├── docs/                  ← Reference docs (10 files)
│   │   ├── BACKEND_ENVIRONMENT_HANDOFF.md
│   │   ├── masterdb-migration-CLAUDE.md
│   │   ├── compliance-audit-2026-05-15.md
│   │   ├── secure-coding-guide-claude-code.md
│   │   ├── session-2026-05-14-tls-cutover.md
│   │   ├── gunnerteam-app-summary.md
│   │   ├── colin-api-spec-request.md
│   │   ├── colin-photo-comments-asks.md
│   │   ├── colin-tasks-api-spec.md
│   │   └── colin-tasks-api-spec-v2.md
│   └── cc-prompts/            ← GunnerTeam cc-prompts 01–24 (30 files)
└── subportal/
    ├── frontend/              ← React + Vite + Amplify UI + shadcn/ui
    ├── backend/               ← Python Lambda backend (from gunner-subportal/)
    ├── db/                    ← Alembic migrations (from gunner-masterdb/)
    ├── scripts/               ← CSV import scripts (from sub-import/)
    └── cc-prompts/            ← cc-prompt-01 scaffold + cc-prompt-02 frontend + plan (3 files)
```

## Migration Verification

All diffs between legacy source and new destination were clean (empty `diff` output). File counts confirmed:

| Destination | Count | Status |
|---|---|---|
| `GunnerTeam/docs/` | 10 | ✅ |
| `GunnerTeam/cc-prompts/` | 30 | ✅ |
| `subportal/backend/` | matches source | ✅ |
| `subportal/db/` | matches source | ✅ |
| `subportal/scripts/` | matches source | ✅ |
| `subportal/cc-prompts/` | 3 | ✅ |
| Legacy folder | 46 entries intact | ✅ |

## Key Rules Going Forward

- **Never open projects from the legacy path.** `~/Documents/Claude/Projects/Gunner Team App/` is a read-only backup until explicitly deleted by Tyler.
- **Claude Code sessions** for GunnerTeam open at `~/Documents/Gunner/GunnerTeam/`.
- **Claude Code sessions** for subportal open at `~/Documents/Gunner/subportal/`.
- **masterdb clone** (Alembic migrations) lives at `~/Documents/Gunner/subportal/db/`.
- The `onboarding prompt` in [[gunner/claude-session-onboarding]] already reflects these paths.
