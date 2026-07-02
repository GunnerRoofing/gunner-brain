---
type: readme
updated: 2026-06-10T00:00:00.000Z
owner: vault
status: stable
created: '2026-06-10'
tags:
  - shared
  - decisions
---

# Decisions (ADRs)

Architecture Decision Records for choices that affect more than one app or the team as
a whole. An ADR captures the context, the decision, and its consequences so we don't
relitigate it later.

## Convention

- **One file per decision**, numbered: `001-title.md`, `002-title.md`, ... (kebab-case
  title, zero-padded sequential number).
- `000-template.md` is the template — copy it, take the next free number, and fill it in.
- Frontmatter `status` is one of:
  - `proposed` — under discussion, not yet agreed.
  - `accepted` — agreed and in effect.
  - `deprecated` — no longer in effect (note what superseded it).
- Don't delete superseded ADRs. Mark them `deprecated` and link to the one that replaced
  them — the history is the point.

Start from [[000-template]].
