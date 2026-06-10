---
type: entity
title: "Colin"
created: 2026-06-09
updated: 2026-06-09
tags:
  - entity
  - people
  - integration
status: stub
related:
  - "[[vendors/companycam]]"
  - "[[gunner/masterdb-developer-handoff]]"
  - "[[gunner/gunnerteam-project-structure]]"
---

# Colin

> [!gap] This is a stub page. Expand with full name, role title, and contact when available.

Colin is the developer and owner of GunnerCam / ColinCam — the CompanyCam-based phase documentation system used by Gunner Roofing. He maintains the external API that the GunnerTeam iOS app integrates against for job photos, phase items, and field tasks.

## Key Responsibilities

- Owns the Project Hub external API (phase items, photo capture, task routing)
- Maintains the `photo_360` item type and steps contract
- Seeds test projects for joint QA (dev project: Bob Smith `40fcbc6f-a5d8-4a3f-99e0-af5e38b8f0d9`)
- Manages service client credentials in the masterdb `service_clients` table

## Integration Contract

The GunnerTeam iOS app consumes Colin's API for:
- `GunnerPhase` / `GunnerPhaseItem` data
- Photo upload and PATCH (append `photoKeys`, set `status: "complete"`, `flagged`)
- `photo_360` items with `steps[]` carrying tag metadata (`id`, `label`, `itemId?`, `highAlert?`)

## References

- [[summaries/external-api-handoff]] — Project Hub external API contract
- [[gunner/masterdb-developer-handoff]] — M2M service client (ColinCam)
- [[meta/session-2026-06-08-cc167-233-ios-tab-markup-themes]] — 360 photo feature jointly designed
