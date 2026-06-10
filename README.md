# gunner-brain

Shared Obsidian vault — the collective knowledge base ("team brain") for the Gunner Roofing engineering team. Four teammates each maintain their own section, with a shared area for cross-team knowledge. Claude / Claude Code acts as the disciplined maintainer: filing sessions, cross-referencing, linting, and synthesizing.

**Repo:** `GunnerRoofing/gunner-brain` (private)

---

## Team roster

| Person | App | Description |
|--------|-----|-------------|
| **Tyler Suffern** | GunnerTeam iOS + IT/Ops | iOS app engineering, IT operations, and vault owner. |
| **Colin** | GunnerCam | Multi-tenant AWS Next.js field-operations app. |
| **Leo** | gunner-ops | Job-lifecycle CRM replacing Monday.com. |
| **Doug** | Lead Finder, Review Engine, Content Creator, WP Local Page Template | Four marketing/ops apps. |

---

## Vault structure

```
gunner-brain/
  CLAUDE.md          # Master instructions for every Claude in the vault.
  CLAUDE.local.md    # GITIGNORED — declares the owner of your working copy (created at onboarding).
  README.md          # This file.
  ONBOARDING.md      # Teammate setup steps.
  wiki/
    tyler/           # Tyler's section (+ gunnerteam/ below).
    gunnerteam/      # Tyler's GunnerTeam app engineering docs.
    colin/           # Colin's section (GunnerCam).
    leo/             # Leo's section (gunner-ops).
    doug/            # Doug's section (4 apps).
    shared/          # Read by all; write only after coordinating.
    meta/            # Vault-wide lint reports.
    hot.md           # Cross-team recent-activity cache (Tyler maintains).
    index.md         # Master index across sections (Tyler maintains).
    log.md           # Append-only chronological log.
```

Each person owns their section. `wiki/shared/` is coordinate-before-write. `wiki/hot.md` and `wiki/index.md` are maintained by Tyler as vault owner. `wiki/log.md` is append-only. Full rules live in `CLAUDE.md`.

---

## Obsidian Git sync

This vault syncs via the **Obsidian Git** community plugin. Recommended settings:

- **Auto-pull on startup:** **Yes** — always start from the latest team state.
- **Commit:** on close, or manually. (Auto-commit-on-interval is optional; commit-on-close keeps history readable.)
- **Pull before commit/push:** **Yes** — reduces merge conflicts on shared files (`log.md`, `index.md`, `hot.md`).

Because everyone touches the append-only `wiki/log.md` and the shared index/hot files, pulling before you commit is important. Keep edits scoped to your own section to minimize conflicts.

---

## Local config

`CLAUDE.local.md` is **gitignored** and is **created during onboarding** — it declares who *you* are (owner, sections, role, app) so Claude files into the right section. It never gets committed; each teammate's working copy has its own.

See **`ONBOARDING.md`** for teammate setup (cloning, installing Obsidian Git, creating your `CLAUDE.local.md`).
