---
type: readme
updated: 2026-06-10
owner: vault
---

# API Contracts

Cross-app API and event contracts. When two apps in this org talk to each other, the
contract between them lives here so both sides share one source of truth.

## Convention

- **One file per integration**, named `<provider>-to-<consumer>.md`.
  - `<provider>` = the app/service that exposes the endpoint or emits the event.
  - `<consumer>` = the app that calls it or receives it.
  - Examples: `companycam-to-gunnerteam.md`, `gunnerteam-to-gunner-ops.md`.
- If traffic flows both ways, create one file per direction.
- Start from [[_template]] — copy it, rename, and fill in every section.
- When you change either side of a contract, update its file here **and** note the change
  in the system-wide [[hot.md]] under **Recent Cross-Team Changes**, then commit and push.
