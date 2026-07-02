---
type: session
title: >-
  cc-40-56 — comms-admin light-suite console redesign (masterdb-authed CRUD,
  theme JSONB fix, admin domain, thread/feed UX) + cc-1203/1205 iOS PII-cache purge
created: '2026-07-02'
updated: '2026-07-02'
tags:
  - comms-admin
  - masterdb
  - gunner-ios
  - dialpad
  - theme
  - csp
  - mfa
  - cognito
status: developing
related:
  - '[[tyler/meta/session-2026-06-29-cc2820-3002-comms-admin-full-stack]]'
  - '[[tyler/meta/session-2026-07-01-cc18-26-comms-admin-dialpad-backfill]]'
  - '[[tyler/meta/session-2026-07-01-cc13-15-comms-admin-custom-domains]]'
  - '[[gunnerteam/dialpad-hubspot-integration]]'
  - '[[shared/cloudflare-sst-custom-domains]]'
  - '[[tyler/masterdb/masterdb-architecture]]'
---

# cc-40-56 — comms-admin light-suite console redesign + iOS PII-cache purge

One long multi-repo conversation, **2026-07-01 16:32 → 2026-07-02 12:01** (~20h wall,
commit-dated). Two independent threads:

1. **`gunner-ios`** — cc-1203/cc-1205 PII-leak cache purge (the opening task).
2. **`gunner-comms-admin` + `gunner-masterdb`** — cc-40→56: turned the read-only Dialpad
   viewer into a full **light-suite admin console** (masterdb-authed CRUD tabs, real
   sign-in/MFA, theme, custom domain, and a long UX punch-list).

cc-prompts are **one shared number line landing in different repos** (e.g. cc-46 = comms-admin
CRUD tabs + masterdb CORS origin; cc-49 = admin-domain move in both). This note documents
cc-49→56 in full (directly from the working transcript) and cc-40→48 at commit level
(the detailed middle of the session was archived out). The predecessor note
[[tyler/meta/session-2026-06-29-cc2820-3002-comms-admin-full-stack]] covers comms-admin
cc-01→07 (the original from-scratch build).

> **Save-time reconstruction note:** ~1.7M chars of mid-conversation history were dropped
> from the archive before this save. Every commit hash, date, push/merge state, and the
> cc-53 "no-commit" finding below were **re-verified live against the three git repos** at
> save time — not taken from the compressed transcript.

---

## Thread 1 — gunner-ios: purge ALL per-user caches (cc-1203/1205)

**Reported PII leak:** a subcontractor saw the *previous* account's jobs (homeowner
names/addresses). Root cause: `logout()` cleared only `JobPreloadStore`; every other
per-user cache persisted, and an account switch that never ran a clean `logout()` leaked
the prior user's data outright.

**Fix (cc-1203, `65c9db0`):** one `clearAllUserCaches()` entry point, called on logout
**and** on authenticated-user change.
- Gave each per-user cache a `clear()`: `PhotoImageCache` (mem + on-disk `photo-cache/`,
  dir recreated lazily), `GeocodingCache` (in-mem dict + UserDefaults `geocode.cache.v1`),
  `AssignedVehicleCache` (`gt_assigned_vehicles`), and the form-draft `@AppStorage` keys
  (`co_*`, `ap_*`, `itReq_*`).
- Also wiped the **jobs cache + sync markers** (`jobs.cache.data`, `jobs.cache.ts`,
  `jobs.sync.ts`, `jobs.sync.etag`) and AuthManager's `gunner.*` keys — the real leak
  vector: `lastSyncTs` lives in global (not per-user) UserDefaults, so a new user's first
  load was treated as an *incremental* sync off the prior user's timestamp/etag → the merge
  path fell back to the prior user's `cachedJobsData` on an empty/304 result.
- **User-change guard:** persist last authed user id (Cognito `username`) in `gunner.lastAuthUserId`;
  in `validate(token:)`, before `isAuthenticated = true`, if the decoded user differs from
  the stored id → `clearAllUserCaches()` first, then store the new id. Purges stale data on
  switches that never ran `logout()`.

**cc-1205 (`a481c50`):** follow-up — `CheckInManager` reset on logout/account switch (it
persists check-in state incl. job name + geofence coords = genuine per-user PII).

Both committed 2026-07-01 16:32 to `main` (iOS is solo/main per CLAUDE.md). Build succeeded.

---

## Thread 2 — comms-admin console redesign (cc-40→56)

### cc-40→48 — light-suite theme + tab shell + CRUD + a11y (commit-level)

| cc | commit | what |
|---|---|---|
| cc-40 | `ff9a496` | light suite theme tokens + tailwind token wiring + white-label "Business line" fix |
| cc-41 | `a8447b3` | shared primitives + tab-ready `AppShell` (Dialpad active, CRUD tabs scaffolded) |
| cc-42 | `69cb1bc` | feed redesign — event list + filter pills + summary/segment + live "N new" pill |
| cc-43 | `f71c66e` | thread redesign — suite call cards + slide-over transcript + standardized player |
| cc-44 | `a4c31db` | theme Amplify sign-in + MFA enroll/challenge + not-authorized → light suite |
| **cc-45** | masterdb `b7d550f` | **masterdb admin API trusts Cognito RS256 + `gt-admin` (Phase 1)** — no comms-admin commit (explains the cc-44→46 gap) |
| cc-46 | `f52b19f` (+ masterdb `2e4c651`) | MasterDB CRUD tabs (Orgs/Users/Contacts/Projects/Audit) via Cognito-authed masterdb API |
| cc-47 | `7f4c394` | motion + a11y (keyboard/focus/ARIA) + runtime WCAG contrast guard + perf pass (no new deps) |
| cc-48 | `a097bf9` (+ masterdb `d234c7f` cc-49 origin, `af98a02` CI) | `/theme` light-suite defaults (backend counterpart to cc-40 so the overhaul renders) |

**masterdb PR #27 merged 2026-07-02 02:24 (`8f45f4a`)** — cc-45 auth + cc-49 origin + cc-50
bandit-B310 CI fix. The admin API now trusts Cognito RS256 + the `gt-admin` role; the CRUD
tabs call it with the id token, least-privilege split from the read-only Dialpad role.

### cc-49 — serve console at admin.gunnerroofing.com (`57d3e08`)

Moved the console `comms.` → `admin.gunnerroofing.com` (redirect old host) + allowed the new
CORS origin on both API and masterdb. **Gotcha:** because `comms.` had been *canonical*
before, ACM re-validation snagged on stale Cloudflare records — fix was deleting the stale
validation records, letting the main distribution release its CNAME, refreshing SST, then
redeploying with the updated CORS on both services. Runbook: [[shared/cloudflare-sst-custom-domains]].

### cc-50 — /theme reads gt_org_theme.config JSONB (`1ba26ca`) — the real theme bug

`/theme` was `SELECT`ing **flat columns** (`primary_color`, `bg_color`, …) that **don't
exist** — so the query always raised → caught → fell back to `_DEFAULTS` → white-label
*never* worked. Actual schema (gunnerteam-api migration `20260608_org_theme`) is
**`gt_org_theme(org_id UUID PK, config JSONB, updated_at, updated_by)`**. Fixed to read the
`config` JSONB and tint per-org from known keys (`primary` shared with iOS vocab).
**Pre-deploy safety probe (gunnerteam-api `_sql` seam, read-only):** the gunner org has
**no `gt_org_theme` row** → the live palette stays light (defaults), no surprise recolor.
12 unit tests added (`test_theme.py`), full suite 66/66.

### cc-51 — UI punch-list (`a760de0`)

- Full-width top bar (`AppShell` `header` → `w-full`, left group = logo + GlobalSearch,
  right cluster pinned `ml-auto shrink-0`).
- `fmtPhone` (`format.ts`) — 11-digit-leading-1 / 10-digit → `(AAA) BBB-CCCC`; short
  codes / intl pass through unchanged. Applied to EventRow, ThreadPage, CallCard.
- `fmtWhen` — `today → 2:41 PM`, `this-year → Jul 1, 4:18 PM` (composed explicitly to
  dodge ICU's "at"), `older → Jul 1, 2021`. Replaced the old relative `relTime`.
- Working **"All reps" pill** — `ScopePill` is now a real dropdown fed by `fetchAgents()`,
  writes the shared `agentId` URL param (one source of truth with the FilterBar rep select
  + the feed filter); selecting a rep syncs both directions; "All reps" clears it.

### cc-52 — thread labels the customer side (`ee3a4e3`)

Fixed a "rep talking to himself" bug — inbound customer messages/calls were labelled with
`agent_name` (the rep). Now: added optional `contact_name` to `FeedRow` (cc-53 backend
enrichment will populate it); `customerLabel(row) = contact_name || fmtPhone(external_number)
|| "Unknown"`. `SmsBubble` author is now direction-aware (outbound → `agent_name`, inbound →
`customerLabel`); `CallCard` kept `Rep:` and added `Customer:`; `ThreadPage` header title =
`contact_name` when known (subtitle = formatted number) else formatted number.

### cc-53 — customer names (Dialpad → HubSpot) — FEASIBILITY ONLY, no commit

Cross-system enrichment, **no code committed in any repo** (verified — explains comms-admin's
cc-52→54 gap). Ground truth established live:
- The Dialpad webhook (`gunnerteam-api/src/routes/dialpad.js`) already stores the **full
  payload** in `dp_events.payload` (JSONB); `payload->contact->>name` is present in
  **5055/5055** rows — so the customer name is **already captured raw**. No Dialpad-API
  change needed.
- **Blocking prerequisite (Colin's, unmet):** `contact_name` does **not** exist on
  `dp_calls` / `dp_sms_messages` (verified via `information_schema.columns` → `rowCount:0`).
  The `dp_*` tables are created out-of-band (not in gunnerteam-api migrations, not in
  masterdb Alembic) → the column-add is a **shared-prod masterdb DDL, Colin's job** — not
  improvised. Every dependent step is gated on the column existing first (a stray reference
  would raise "column does not exist" → 500 the whole `/activity` + `/thread` feed).
- **Sequenced handoff** (ready to apply the moment the column lands): (1) Colin `ALTER TABLE`
  both `dp_*`; (2) gunnerteam-api ingest capture (`contact_name` on INSERT + ON CONFLICT +
  raw backfill `UPDATE … SET contact_name = payload->contact->>'name'`); (3) trivial
  comms-admin `feed.py` passthrough (`contact_name` in each arm + FeedRow + `_to_feedrow`);
  (4) HubSpot second pass for numbers not in Dialpad contacts.
- `comms_admin_ro` already has table-level SELECT on both `dp_*` (no grant change needed).

### cc-54 — CSP media-src fix so recordings play (`f2d36fc`)

Recording playback was `MediaError 4` (blocked). `<audio>` loads presigned recording URLs on
`https://gunnerteam-dev-dialpad-recordings.s3.us-east-2.amazonaws.com`, but the CSP
`media-src` only allowed the bare host `https://s3.us-east-2.amazonaws.com`. Fix (one line,
`sst.config.ts`): add the **bucket-subdomain wildcard** `https://*.s3.us-east-2.amazonaws.com`
to `media-src` (survives a bucket rename for white-label; bare host kept). Deployed via
`sst deploy --stage dev`; verified the live `content-security-policy` header now carries the
wildcard. This deploy rebuilt everything committed to that point (backend cc-48/50 + frontend
cc-40→52 went live with it).

### cc-55 — long-SMS wrap + Dialpad MMS images (`3d424c0`) — NOT deployed

View-layer only, no CSP change. New XSS-safe **`MessageBody`** linkifier: splits the body on
an `https?://` regex into plain-text + URL segments and builds **React elements** (no
`dangerouslySetInnerHTML` → auto-escaped); scheme allowlist (`http`/`https` re-validated via
`new URL().protocol`, so `javascript:`/`data:`/`<img onerror>` render as inert text); links
open in a new tab, trailing punctuation peeled off the href. Dialpad MMS (`content.dialpad.com/…/img/…`)
detected via parsed host+path → rendered as a compact `🖼 Image` link (no `img-src`/thumbnail
→ **no CSP change → no deploy**). Long tokens wrap via `break-words [overflow-wrap:anywhere]`
in `SmsBubble` + the EventRow feed preview. Traced against 8 cases (Dialpad img, normal URL,
surrounding text, `javascript:`, `data:`, HTML-injection, bare text, multi-URL, trailing-dot).

### cc-56 — frictionless TOTP entry, both auth screens (`e4fa07a`) — NOT deployed

Both TOTP screens now: autofocus, `inputMode="numeric"`, `autoComplete="one-time-code"`,
digits-only, `maxLength=6`, **auto-submit when the 6th digit lands**, and submit on click
**and** Enter.
- **`MfaEnroll.tsx`** (first-time): wrapped input+error+button in a real `<form onSubmit>`
  (Enter submits; button `type="submit"` fixes "Confirm click did nothing"); `verify(codeArg)`
  takes the fresh value (dodges stale state on paste) with a `busy || <6` guard; auto-submit
  inline in `onChange` (**not** an effect, so a wrong code doesn't re-fire until `busy` resets;
  a corrected code re-submits on the next input).
- **`App.tsx`** (recurring Amplify confirm-sign-in): added `formFields.confirmSignIn.confirmation_code`
  (label + placeholder); **new `ConfirmSignInEnhancer`** mounted under `<Authenticator.Provider>`
  (so it's alive during the pre-auth confirm screen, which `<Authenticator>`'s children are
  not) — on `route === 'confirmSignIn'` it finds `input[name="confirmation_code"]`, sets numeric
  inputMode + one-time-code + maxlength, focuses it, and at 6 digits calls
  `input.form.requestSubmit()` (Amplify's real handler — the robust "confirm click did nothing"
  fix). `autoFocus` isn't in Amplify's `ReactFormFieldOptions` type, so focus is handled by the
  enhancer (dropped from formFields to keep the build clean).

---

## Deploy / push state (verified at save time)

| Repo | State |
|---|---|
| **comms-admin** | cc-40→56 committed **and pushed** (`origin/main…HEAD = 0/0`). |
| **comms-admin LIVE (dev)** | Last `sst deploy` was **cc-54** (`f2d36fc`) → live = backend cc-48/50 + frontend cc-40→52 + CSP cc-54. **cc-55 & cc-56 are committed+pushed but NOT live** — both explicitly deployed nothing (pure frontend, no CSP change), so the served bundle is cc-54-era until the next `sst deploy --stage dev`. |
| **masterdb** | **PR #27 merged to main** 02:24 (`8f45f4a` = cc-45 auth + cc-49 origin + cc-50 CI). Lambda deploy state not re-verified this save. |
| **gunner-ios** | cc-1203 `65c9db0` + cc-1205 `a481c50` committed to `main` (2026-07-01 16:32). Push state not checked. |

---

## Reusable gotchas (cross-cutting)

- **`gt_org_theme` is `config JSONB`, not flat columns.** Reading `primary_color`/`bg_color`
  as columns always raises → silent default fallback. Schema: `(org_id UUID PK, config JSONB,
  updated_at, updated_by)`. The gunner org has **no row** → palette is light defaults.
- **iOS per-user cache leak:** sync markers (`jobs.sync.ts`/`.etag`, `lastSyncTs`) in *global*
  UserDefaults make a new user's first load look incremental → merge falls back to the prior
  user's `cachedJobsData`. Purge sync markers too, not just the bundle, and guard on a
  persisted `lastAuthUserId`.
- **CSP `media-src` needs the S3 *bucket-subdomain* wildcard** (`https://*.s3.<region>.amazonaws.com`),
  not just the bare regional host — presigned URLs use `<bucket>.s3.<region>.amazonaws.com`.
- **Amplify `ReactFormFieldOptions` has no `autoFocus`.** For frictionless TOTP, mount an
  enhancer under `<Authenticator.Provider>` (children of `<Authenticator>` aren't rendered
  pre-auth) that sets input attrs and calls `input.form.requestSubmit()`.
- **Cloudflare custom-domain move** where the old host was canonical: delete stale ACM
  validation records + let the main distribution release its CNAME before redeploy, else
  re-validation snags. See [[shared/cloudflare-sst-custom-domains]].
- **`dp_*` tables are unmanaged** (no Alembic / no gunnerteam-api migration) — any column-add
  is a shared-prod DDL owned by Colin; the raw Dialpad payload (incl. `contact.name`) is
  already in `dp_events.payload` for backfill once the column lands.

## Open items

- **cc-53 blocked on Colin's masterdb DDL** — `ALTER TABLE dp_calls / dp_sms_messages ADD
  COLUMN contact_name text`. gunnerteam-api ingest+backfill and the comms-admin `feed.py`
  passthrough are specced and ready to apply the moment it lands. HubSpot second pass is a
  follow-on for numbers absent from Dialpad contacts.
- **cc-55 / cc-56 not deployed** — need one `sst deploy --stage dev` to push the long-SMS
  wrap, MMS-image links, and frictionless-TOTP frontend live (currently cc-54-era bundle).
- **Live TOTP flow not machine-verified** — cc-56 logic traced against 4 invariants
  (digit-strip, exactly-one-submit-at-6, wrong-code-no-loop, busy-guard); the real
  sign-out→sign-in with a live Cognito session + authenticator wasn't exercised.
