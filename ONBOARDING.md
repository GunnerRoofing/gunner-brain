# gunner-brain Onboarding

This is the shared **Gunner engineering brain** — a persistent, compounding
Obsidian knowledge vault built on the LLM Wiki pattern (Claude + Obsidian).
You're joining **Tyler's existing vault**. Each person gets their own section
under `wiki/<your-name>/` that you own; `wiki/shared/` is read by everyone and
written with coordination.

Sections in this vault:

| Section | Owner | App(s) |
|---|---|---|
| `wiki/tyler/`, `wiki/gunnerteam/` | Tyler | GunnerTeam iOS + IT/Ops |
| `wiki/colin/` | Colin | GunnerCam (white-label CompanyCam) |
| `wiki/leo/` | Leo | gunner-ops (job lifecycle CRM) |
| `wiki/doug/` | Doug | Lead Finder, Review Engine, Content Creator, WP Templates |
| `wiki/shared/` | All (coordinate) | cross-team docs |

Follow the section below for your name. There are **6 steps**. When you finish,
ping Tyler — see the [closing note](#closing-note).

---

## Colin

### Step 1 — Clone the repo

```bash
git clone https://github.com/GunnerRoofing/gunner-brain.git ~/Documents/Obsidian/gunner-brain
```

### Step 2 — Open in Obsidian

Obsidian → **Open another vault** → **Open folder as vault** → select
`~/Documents/Obsidian/gunner-brain`.

### Step 3 — Install the Obsidian Git plugin

Settings → **Community plugins** → **Browse** → **Obsidian Git** → **Install** +
**Enable**, then set:

- Auto pull on startup: **ON**
- Auto push after commit: **ON**
- Commit interval (minutes): **0** (manual)
- Pull updates on startup: **ON**
- Pull before push: **ON**

### Step 4 — Create your `CLAUDE.local.md`

This file is **gitignored** — it stays local to your machine only and declares
your identity to Claude (drives where `/save` files your sessions). Create
`~/Documents/Obsidian/gunner-brain/CLAUDE.local.md` with:

```markdown
# Identity
Owner: Colin
Section: wiki/colin/
App: GunnerCam (WL-CompanyCam)
Role: team-member
```

### Step 5 — Migrate your existing vault (run this prompt in Claude Code)

Open Claude Code in your **existing vault directory** and paste this prompt:

```
I am setting up my section of the gunner-brain shared vault. My vault is already cloned at ~/Documents/Obsidian/gunner-brain and my CLAUDE.local.md is already created.

Help me migrate my existing knowledge into my section (wiki/colin/).

Step 1: Ask me where my existing Obsidian vault lives (or if I have one at all — if not, skip to step 3).

Step 2: Review the content I have. Ask me:
- Which folders contain app/project notes I want to share with the team?
- Which folders are personal and should stay local only?
Do NOT copy anything until I answer.

Step 3: Copy the relevant content into wiki/colin/, preserving folder structure where it makes sense.

Step 4: Update wiki/colin/hot.md with:
- What GunnerCam is currently doing (ask me for a 2-3 sentence status)
- Any active integration points with GunnerTeam iOS I know about
- Current blockers or open questions

Step 5: Run /lint on wiki/colin/ and fix any frontmatter gaps.

Step 6: Commit with message: "feat: Colin onboards to gunner-brain"

Do NOT proceed through steps silently — stop and confirm with me at each step.
```

### Step 6 — Add gunner-brain context to your project `CLAUDE.md`

In your **project's** `CLAUDE.md` (in the GunnerCam repo), add:

```markdown
## Shared Team Brain
- Vault: ~/Documents/Obsidian/gunner-brain
- My section: wiki/colin/
- Read at session start: wiki/colin/hot.md, then wiki/hot.md
- Save sessions: /save (goes to your section automatically via CLAUDE.local.md)
```

---

## Leo

### Step 1 — Clone the repo

```bash
git clone https://github.com/GunnerRoofing/gunner-brain.git ~/Documents/Obsidian/gunner-brain
```

### Step 2 — Open in Obsidian

Obsidian → **Open another vault** → **Open folder as vault** → select
`~/Documents/Obsidian/gunner-brain`.

### Step 3 — Install the Obsidian Git plugin

Settings → **Community plugins** → **Browse** → **Obsidian Git** → **Install** +
**Enable**, then set:

- Auto pull on startup: **ON**
- Auto push after commit: **ON**
- Commit interval (minutes): **0** (manual)
- Pull updates on startup: **ON**
- Pull before push: **ON**

### Step 4 — Create your `CLAUDE.local.md`

This file is **gitignored** — it stays local to your machine only and declares
your identity to Claude (drives where `/save` files your sessions). Create
`~/Documents/Obsidian/gunner-brain/CLAUDE.local.md` with:

```markdown
# Identity
Owner: Leo
Section: wiki/leo/
App: gunner-ops
Role: team-member
```

### Step 5 — Migrate your existing vault (run this prompt in Claude Code)

Open Claude Code in your **existing vault directory** and paste this prompt:

```
I am setting up my section of the gunner-brain shared vault. My vault is already cloned at ~/Documents/Obsidian/gunner-brain and my CLAUDE.local.md is already created.

Help me migrate my existing knowledge into my section (wiki/leo/).

Step 1: Ask me where my existing Obsidian vault lives (or if I have one at all — if not, skip to step 3).

Step 2: Review the content I have. Ask me:
- Which folders contain app/project notes I want to share with the team?
- Which folders are personal and should stay local only?
Do NOT copy anything until I answer.

Step 3: Copy the relevant content into wiki/leo/, preserving folder structure where it makes sense.

Step 4: Update wiki/leo/hot.md with:
- What gunner-ops is currently doing (ask me for a 2-3 sentence status) — the job lifecycle CRM replacing Monday.com
- Any active integration points with GunnerTeam iOS I know about (job data flowing into the iOS app)
- Current blockers or open questions

Step 5: Run /lint on wiki/leo/ and fix any frontmatter gaps.

Step 6: Commit with message: "feat: Leo onboards to gunner-brain"

Do NOT proceed through steps silently — stop and confirm with me at each step.
```

### Step 6 — Add gunner-brain context to your project `CLAUDE.md`

In your **project's** `CLAUDE.md` (in the gunner-ops repo), add:

```markdown
## Shared Team Brain
- Vault: ~/Documents/Obsidian/gunner-brain
- My section: wiki/leo/
- Read at session start: wiki/leo/hot.md, then wiki/hot.md
- Save sessions: /save (goes to your section automatically via CLAUDE.local.md)
```

---

## Doug

### Step 1 — Clone the repo

```bash
git clone https://github.com/GunnerRoofing/gunner-brain.git ~/Documents/Obsidian/gunner-brain
```

### Step 2 — Open in Obsidian

Obsidian → **Open another vault** → **Open folder as vault** → select
`~/Documents/Obsidian/gunner-brain`.

### Step 3 — Install the Obsidian Git plugin

Settings → **Community plugins** → **Browse** → **Obsidian Git** → **Install** +
**Enable**, then set:

- Auto pull on startup: **ON**
- Auto push after commit: **ON**
- Commit interval (minutes): **0** (manual)
- Pull updates on startup: **ON**
- Pull before push: **ON**

### Step 4 — Create your `CLAUDE.local.md`

This file is **gitignored** — it stays local to your machine only and declares
your identity to Claude (drives where `/save` files your sessions). Create
`~/Documents/Obsidian/gunner-brain/CLAUDE.local.md` with:

```markdown
# Identity
Owner: Doug
Section: wiki/doug/
App: Lead Finder, Review Engine, Content Creator, WP Templates
Role: team-member
```

### Step 5 — Migrate your existing vault (run this prompt in Claude Code)

Open Claude Code in your **existing vault directory** and paste this prompt:

```
I am setting up my section of the gunner-brain shared vault. My vault is already cloned at ~/Documents/Obsidian/gunner-brain and my CLAUDE.local.md is already created.

Help me migrate my existing knowledge into my section (wiki/doug/).

Step 1: Ask me where my existing Obsidian vault lives (or if I have one at all — if not, skip to step 3).

Step 2: Review the content I have. I work across 4 apps — Lead Finder, Review Engine, Content Creator, and the WP Local Page Template. Ask me:
- Which folders contain app/project notes I want to share with the team? (group by app where it makes sense)
- Which folders are personal and should stay local only?
Do NOT copy anything until I answer.

Step 3: Copy the relevant content into wiki/doug/, preserving folder structure where it makes sense. Consider a subfolder per app (lead-finder/, review-engine/, content-creator/, wp-templates/).

Step 4: Update wiki/doug/hot.md with:
- What each app is currently doing (ask me for a 2-3 sentence status per app)
- Any active integration points with the rest of Gunner I know about
- Current blockers or open questions

Step 5: Run /lint on wiki/doug/ and fix any frontmatter gaps.

Step 6: Commit with message: "feat: Doug onboards to gunner-brain"

Do NOT proceed through steps silently — stop and confirm with me at each step.
```

### Step 6 — Add gunner-brain context to your project `CLAUDE.md`

In **each** project's `CLAUDE.md` (Lead Finder, Review Engine, Content Creator,
WP Templates), add:

```markdown
## Shared Team Brain
- Vault: ~/Documents/Obsidian/gunner-brain
- My section: wiki/doug/
- Read at session start: wiki/doug/hot.md, then wiki/hot.md
- Save sessions: /save (goes to your section automatically via CLAUDE.local.md)
```

---

## Closing note

Once you've completed these steps, **ping Tyler**. He'll run **/lint** across
the full vault to verify everything merged cleanly.
