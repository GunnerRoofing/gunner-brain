---
type: reference
owner: colin
app: GunnerCam
created: 2026-05-21
updated: 2026-06-21
tags: [wl-companycam, gotchas, troubleshooting, testing, drizzle]
status: active
---

# Recurring Gotchas

The problems that came back more than once across the chat history, with the cause and the fix. Ordered roughly by how often they cost time. Sourced from ~25 distinct Claude + codex work sessions, 2026-05-25 → 2026-06-19.

## AWS SSO login expires constantly

**Symptom:** "do you have access to AWS?" appears in ~20+ sessions. Claude can't run `aws` commands, deploys fail, scripts that hit RDS/S3 fail with auth errors.
**Cause:** the `devops` SSO profile token expires (hours), so every new morning and many new sessions start logged out.
**Fix:** run `aws sso login --profile devops` (Colin runs it in-session with the `!` prefix). On **May 20** a `~/.zshrc` helper was added to make this one step instead of a manual dance. Account `980921733684`, region `us-east-2`, profile `devops`. Claude cannot do the interactive SSO browser step itself — Colin has to. See [[colin/aws-infra|AWS Infra]].

## Concurrent / parallel Claude sessions corrupt mid-session state

The single dominant source of confusing state on this repo. Multiple Claude Code sessions run against the same working tree at once, so Read-tool and `bash` snapshots go stale or contradictory **within one session**.

**Symptoms / observed events:**
- A parallel session branch-switched, committed, stashed, and cleaned files mid-conversation — e.g. (2026-06-09) another session committed `photo_360` work, stashed "wip before photo-360 deploy", and switched to `deploy/photo-360`, making the tree look reverted. `git reflog` recovered ground truth.
- Concurrent sessions add untracked files mid-task (`src/lib/monday-stage.ts` during an SST deploy; `phase-items/[itemId]/photos/route.ts`; `phase-workflow-tab.tsx`). They compile fine and don't break the build but cause vitest mock contamination and apparent 500s that clear once the other edit settles.
- A parallel session's in-progress edits to widely-imported modules (`external-auth.ts`, `external-projects.ts`, `project-detail.tsx`, `tasks/route.ts`, `assignments/route.ts`) produced 8 test failures in unrelated files. Stashing the whole tree made all 8 pass, confirming they were mock-only and not the current session's work.
- The shared preview browser is contended too — a parallel session navigated it to a different page and shifted `globals.css` under an active edit.

**Mitigations:**
- Prefer git worktrees for isolation. Concurrent worktrees use random adjective-scientist-hash names (e.g. `funny-lewin-5a68b0`) under `.claude/worktrees/`; uncommitted work is isolated to its worktree, not the main checkout. Clean up with `git worktree remove <path>`.
- Always re-read files and verify `git status` / `git reflog` state before trusting any snapshot.
- Avoid blanket `git commit -a` — it entangles separate work streams (it would have swept in uncommitted forecast-dashboard / `0032` migration work).

Memory: `feat/high-alert-tasks gets concurrent edits`. See also [[colin/ops-deploy|Ops & Deploy]].

## `cognito_sub` user-not-found at runtime

**Symptom:** `Runtime Error — Failed query: select ... from "users" where "users"."cognito_sub" = $1` (often after a schema reseed or when newly logged in).
**Cause:** the authenticated Cognito identity has no matching row in the `users` table. Happens after the DB is wiped/reseeded, after schema changes, or when a real Cognito user was never seeded.
**Fix:** ensure the logged-in Cognito `sub` is seeded into `users` (seed scripts / `promote-existing-pms.mts` style helpers). This is the single most common runtime error in the logs. **Caution:** `npm run db:seed` is destructive (see below) — do not reach for it casually to fix a missing record.

## Next.js `middleware` → `proxy` deprecation

**Symptom:** `⚠ The "middleware" file convention is deprecated. Please use "proxy" instead.`
**Cause:** Next.js 16 renamed the convention.
**Fix:** the edge logic lives in `src/proxy.ts` (not `src/middleware.ts`). Keep it there.

## HEIC photos don't load

**Symptom:** iOS photos uploaded as HEIC don't render; some show as broken.
**Cause:** browsers don't render HEIC; and S3/DB can drift (image deleted in S3 but row remains, or vice-versa).
**Fix:** HEIC handling on upload, plus cleanup scripts (`prune-broken-photos.mts`, `cleanup-orphaned-photos.mts`) to reconcile S3 against the DB. See [[colin/photos-uploads|Photos & Uploads]].

---

## Test harness & mocking pitfalls

Vitest runs in a **Node-only** environment — no jsdom / React Testing Library — so all component/rendered behavior is untested (DictationButton, role-gated chrome, manager reporting bar, LabelsModal, QA toolbar localStorage, etc.). Only pure-logic helpers can be unit-tested; component testing would require adding jsdom (an outstanding coverage gap, see Open questions).

| Pitfall | Detail / fix |
| --- | --- |
| Static ESM import hoists above `vi.mock()` | "mock not defined" — `import()` the module-under-test **dynamically inside each test** (the established pattern across all external-route tests). |
| Drizzle queue mock has no `db.transaction` | `queries.test.ts` queue mock can't drive a materialize transaction (e.g. `loadProjectPhasesForUi`); mock at the module boundary (`vi.mock('./external-phases')`) or use an isolated file with its own queue mock. |
| Mocks aren't auto-reset | `dbMock.transaction` was not reset between tests in `src/app/api/files/route.test.ts`, accumulating call counts; tests passed only by execution order until a `beforeEach` reset was added. |
| Mocked-DB blind spots | Mocked tests cannot catch real-pg behaviors (Drizzle array-tuple bug, `Date`-instance interpolation, enum casts) — these need a real Postgres run. |
| Concurrent `git` during vitest | Running `git` commands while a vitest run is in flight causes timeouts and false failures (100s vs normal 2–3s; exit code masked by `tail` piping). A clean re-run passes (e.g. 990/990, 1252/1252, 1393). |

## Drizzle / raw SQL / migrations

| Pitfall | Detail / fix |
| --- | --- |
| `= ANY(${jsArray})` fails at runtime | Drizzle expands JS arrays to SQL **tuples** — compose `inArray()` instead. The windowed photo query hit this. Memory: `drizzle-sql-template-array-gotcha.md`. |
| `db.execute(sql\`...\`)` rejects `Date` | Convert with `.toISOString()` first (the pg driver errors otherwise). |
| Raw `psql` into enum columns | Driver-level SQL into a Postgres enum needs explicit `::enum_type` casts or the transaction rolls back silently; Drizzle ORM adds the casts automatically. |
| Migrations are per-environment | Each new migration must run on **every** environment separately — `notifications` existed in `0002_fresh_mojo.sql` and in code but 500'd until `npm run db:migrate` ran on dev. |
| Committing a schema **subset** tears the journal | When committing part of `schema.ts` (e.g. location-pings but not the co-resident dialpad block): surgically remove the dialpad block, trim idx 43 (`0043`) from `drizzle/meta/_journal.json`, commit the `0042` slice, then restore the dialpad block byte-for-byte. Precedent: `0031` also needed manual SQL trimming to suppress destructive DROPs (memory: `drizzle-snapshot-drift.md`). |
| `npm run db:seed` is destructive | It deletes existing dev rows before reseeding (including the `cwong` dev user); never use it casually to fix a missing record. |

See [[colin/data-model|Data Model]].

## tsx / `server-only` / Node-direct script execution

| Pitfall | Detail / fix |
| --- | --- |
| `tsx` can't import `import "server-only"` | Next provides that package only at bundle time; it isn't on disk. Vitest stubs it, tsx does not. `--conditions=react-server` does **not** reliably help (it worked in one codex session `019ed0df` but a Claude session `2cd220a1` found it insufficient). Best path: split pure-logic modules from server-only DB/SSM wrappers and have scripts import only the pure layer. |
| `tsx -e` compiles as CJS | Inline async one-liners can fail; wrap in an async IIFE or use a heredoc/file. |
| CJS/ESM interop nests named exports under `.default` | The seeder `scripts/seed-pm-checklist-presets.mts` importing `pm-checklist-presets.ts` saw `undefined`; guard with `module.default ?? module`, or use namespace imports (as other scripts do). General `.mts` interop notes in memory `mts-script-cjs-interop.md`. |

## Dev server / Next.js / browser-QA pitfalls

| Pitfall | Detail / fix |
| --- | --- |
| Stale `globals.css` bundle | The dev CSS watcher logs "Compiled" but omits new rules even after `touch`. Clear `.next` and clean-restart. `ruleInSheet`-style `includes()` checks give false positives — diagnose via cache-busted HTTP fetch + cascade enumeration. |
| Turbopack stale module cache | Serves stale compiled output after source is fixed (phantom compile errors, e.g. `import type` mixing in `project-detail.tsx`). Only a **full preview-server restart** clears it — `.next` clear + browser reload don't. |
| Turbopack `ChunkLoadError` | A stale chunk hash in an open tab after many recompiles looks like a regression ("smoked", lone bare card) but the server returns HTTP 200 — `Cmd+Shift+R` hard-refresh fixes it. |
| Dev server binds IPv6 (`::1`) | Breaks the in-app browser pointed at `127.0.0.1`; restart with `HOST=0.0.0.0` for IPv4. The HMR dev-origin check rejects `127.0.0.1` — use `localhost` so interactive React state changes fire. |
| `preview_start` port 3000 collision | Collides with a user-run `next dev` because `.claude/launch.json` has `autoPort: false`. |
| In-app Browser screenshots unreliable | Repeated timeouts even when DOM/console checks pass; fallback is a local Playwright (Python) script against the authenticated `localhost:3000` session. Focus mode is local UI state (not a URL) — navigate + click into it. |
| Preview hidden-tab Suspense stuck | The preview tab is `visibility:hidden`, so React 19 streaming reveal/hydration never fire (skeleton forever, no errors). `$RV($RB)` + rAF patch + `_reactRetry()` workaround; `el.click()` over `preview_click`; scrolled screenshots paint blank. Memory: `preview-hidden-tab-suspense-stuck.md`. |

## Dev auth shim / preview access

The middleware gates only on presence of a `ccam_id` cookie; the server-side dev-auth shim (`DEV_AUTH_USERNAME`) bypasses Cognito but the middleware still blocks unless a dummy `ccam_id` cookie is planted.

- **Favicon hop:** navigate to a middleware-excluded route (`/favicon.ico` or `/api/health`) to land on origin, set `document.cookie='ccam_id=dev; path=/'`, then go to the protected page.
- With the shim active, navigating to `/login` causes an infinite 307 loop (shim sees an authenticated principal → `/projects`; middleware lacks `ccam_id` → bounces back). Same favicon-hop workaround.
- The shim lives in `src/lib/dal.ts`, double-guarded: active only when `NODE_ENV !== 'production'` **and** `DEV_AUTH_USERNAME` is set; inert by default, held uncommitted pending user opt-in.

Memory: `preview-auth-dev-shim.md`.

## DB connectivity in worktrees / tunnel

- Claude worktrees have no `DATABASE_URL` (or it points at `127.0.0.1:5432`, refused), so the dev server 500s before rendering any page. CSS/UI changes must be verified via isolated test-fixture pages mirroring the shell. (Affected worktrees: `crazy-hofstadter`, `modest-wu`, etc.)
- The SSM DB tunnel to dev RDS is flaky for sustained sessions — it dropped ~10 min after a successful migration, 500'ing all routes with `ECONNREFUSED 127.0.0.1:5432` (not a code defect). Running the QA toolbar locally requires the `127.0.0.1:5432` tunnel active. Memories: `dev-db-tunnel-recipe`, `local-pg-preview-verification`.

## Secrets / credential hygiene

- **Never run `sst secret list`** — it decrypts and prints ALL secrets in plaintext (it leaked live Stripe restricted keys for CT/NJ/NY/OH/PA and a DocuSign RSA private key into the transcript). Use `aws ssm get-parameter --name <param> --with-decryption` narrowly, or `--no-with-decryption` to check existence only. Memory: `sst-secret-list-leaks-values.md`.
- **Never paste secrets into chat** — the transcript is confidential under org policy (a Monday JWT was leaked this way). Write directly from the shell instead: `! echo 'KEY=value' >> .env.local`.
- **Don't use `sst diff`** — it prints `SST_AWS_*` temp creds in plaintext; `sst deploy` is clean (memory: `sst-diff-leaks-aws-creds.md`).

## Git push blocked by the secret classifier

**Symptom:** `git push origin main` is blocked; "the classifier is blocking the push."
**Cause:** secrets/credentials detected in the diff.
**Fix:** keep keys in `.env.local` (gitignored), never commit secrets. When secrets leak (e.g. an integration key shared in the wrong place), **rotate** rather than scrub history. See [[colin/external-api-integration|External API Integration]].

## Branch sprawl from parallel worktrees

**Symptom:** "merge all the branches into main so I can `npm run dev`" recurs on May 13, 14, 18. Confusion over what's in which branch ("what even is funny-lewin?").
**Cause:** Colin runs many Claude sessions in separate git worktrees (`.claude/worktrees/*`), each on its own branch. They drift apart fast.
**Fix:** periodic consolidation passes that merge worktree branches back into `main`. Keep the worktree count low and merge same-day; the auto-named worktrees (happy-keller, funny-lewin…) are throwaway. See the concurrent-sessions section above for the mid-session hazards.

## "Is it live?" — localhost vs dev vs live confusion

**Symptom:** repeated "is it on the site?", "when I `npm run dev` will I see the changes?", "is it live?".
**Cause:** three surfaces — local `npm run dev`, the deployed `dev` stage (`project.dev.gunnerroofing.com`), and "live" — are easy to conflate, and a push to GitHub is not a deploy.
**Fix:** remember the chain: commit/push ≠ deploy. A change is only on the dev site after `AWS_PROFILE=devops npx sst deploy --stage dev` (classifier-gated; verify via `/api/health`). Local `npm run dev` shows local working-tree changes only. See [[colin/ops-deploy|Ops & Deploy]].

---

## Timezone / date handling (server vs client)

- `timeLabel()` / `dateLabel()` in `src/lib/view-models.ts` formatted without a timezone → default UTC in the (UTC) Lambda runtime, so server-baked times displayed +4h for EDT users (3 PM EDT shown as 7 PM). **Fix (deployed to dev 2026-05-29):** pass the corp's IANA timezone (`corporations.timezone`, default `America/New_York`) into `Intl.DateTimeFormat` — **not** ship raw ISO strings, which would disagree with the `bucket_day` generated column (converts at `America/New_York`) and mis-group day headers.
- Client-side date math caused **hydration crashes** in evening hours (client clock vs server corp-timezone date). Fix: resolve "today" server-side via a shared `resolveCorpToday` helper in `queries.ts` and pass it down as a required prop (also fixed the job-detail `[id]` page).

## Authorization / role policy drift

- **Two assignment policies must stay in sync:** `canAssignBetween` (client/UI filter in `role-hierarchy.ts`) and `canAssignTo` (server DAL in `dal.ts`). Drift causes silently-hidden UI options plus server `FORBIDDEN`.
- `company_admin` was missing from `task-modal.tsx`'s assignee list (admins couldn't be selected); fixed by extracting a shared `buildAssignTargets` helper now used by `task-modal.tsx` and `dispatch-checklist.tsx`.
- Company admins (pre-existing, fixed in `feat/redesign-v2`): couldn't see the corp-wide project list (fix in `listProjectsForPrincipal`) and were wrongly denied the Rain Day button (wrong `canManage` check for the role).
- QA toolbar auth preview is wired through `src/lib/dal.ts` so routes see the preview principal, but QA controller resolution reads the **real** underlying principal separately, preventing a preview account from authorizing its own privilege escalation. `PATCH /api/qa/context` uses the sentinel-error + `errorToResponse` convention and validates that preview accounts are real and non-deleted. See [[colin/my-day|My Day]] for the toolbar's day/preview-key state.
- Cognito operation failures with user-facing messages (e.g. wrong old password on ChangePassword) return `NextResponse.json({ error: <cognito msg> }, { status: 400 })` directly, **not** via sentinel Errors — sentinels (`UNAUTHENTICATED`, `FORBIDDEN`, …) are for auth/access errors only (precedent: `admin/users/route.ts`). See [[colin/decisions|Decisions]].

## Frontend / CSS gotchas

| Gotcha | Fix |
| --- | --- |
| `position: fixed` modal inside transformed ancestor | `.project-side-drawer` has `transform`, creating a new containing block that breaks fixed positioning. Render the TaskModal into `document.body` via `createPortal` (portal target computed inline to keep lint clean). |
| `setState` in capability-detection `useEffect` | `react-hooks/exhaustive-deps` forbids it — use `useSyncExternalStore` with a `false` server snapshot (SSR-safe, post-hydration-only render). |
| Mic button pushes Post off narrow drawer | Comment composer side-drawer uses space-between; a 32px mic button overflows. Add a shrinkable class to the left action cluster. Inline hints are safe under `.modal-card`'s `overflow:auto`, but absolutely-positioned elements get clipped. |
| Invisible PM badge after admin retirement | Post-T-10 the `.role-pill.pm` rule was missing (white text, no bg) and a dead `.role-pill.admin` rule remained. Fix: `.role-pill.pm { background:#1d4ed8 }` (blue, distinct from manager teal / restricted red). |
| Invite-row role `<select>` truncated "Standard"→"Standar" | Was `flex:1` in a tight grid cell; fixed with `min-width:96px` + a wider cell. |
| Logo overlaps search cluster on mobile | Mobile shell collapses/hides the logo on narrow viewports (390px) to stop overlap with the right-side search/control cluster (commit `9117934`). |
| Presigned S3 URLs + `next/image` | `next/image` requires a hostname allowlist; presigned URLs can't satisfy it. Codebase uses plain `<img>` for presigned avatars/logos (ESLint `<img>` warnings accepted; precedent `admin-companies.tsx`). |

## TypeScript / typing

- The ternary-of-string-literals anti-pattern is dangerous when the result flows into `db.insert().values()` — const narrowing is preserved but easy to break. Vulnerable site at `admins/route.ts:55` (role ternary into `users.role` enum), hardened in commit `0be4682` with an explicit literal-union annotation. Inline ternaries passed as function args are protected by contextual typing; standalone `const` assignments are the risk zone.
- Note: the CI gate is `npm run lint && npm test` (vitest), **not** `tsc` — 4 test files have pre-existing tsc errors; don't chase them (memory: `tsc-not-clean-over-tests.md`).

## Shell / sandbox tooling

- The bash sandbox **cannot traverse directory names with literal brackets** (e.g. `[id]`) — `find`, glob, `ugrep` (treats `[id]` as a char class), and Python `os.walk` silently return nothing. Use the Read tool with explicit absolute paths (e.g. `src/app/api/projects/[id]/tasks/batch/route.ts`).
- Route-group dirs like `(app)` must be quoted in zsh or the parens are read as a subshell and the path fails (silently, on file reads).
- `picsum.photos` returns HTTP 405 for HEAD, so HEAD availability probes falsely flag all photos broken — use `GET` with `Range: bytes=0-0` for an honest status without downloading bodies.

## Next.js version-staleness warning

**Symptom:** `Next.js 16.2.4 (stale) Turbopack` banner in runtime errors.
**Cause:** a newer Next.js exists than the lockfile pins.
**Fix:** cosmetic; mostly ignorable unless chasing a Turbopack bug. It attaches to unrelated runtime errors, so don't be misled by it.

## `.mts` script CJS interop

**Symptom:** `.mts` provisioning/maintenance scripts (`scripts/*.mts`, run with `npx tsx`) hit CJS/ESM interop issues.
**Cause:** mixed module systems between the script and its imports (see the tsx section above for the `.default` nesting and `server-only` specifics).
**Fix:** captured in the repo-local Claude memory (`mts-script-cjs-interop.md`). Check there before re-debugging.

---

## Data integrity / stale-doc landmines

- **Phantom field tasks:** a "PM Field Checklist" preset was bulk-applied at project creation, producing ~55 phantom field tasks per new job (all created 0s after the project, untouched — unambiguous root cause). Fix: don't apply the preset at creation; `scripts/cleanup-bulk-applied-tasks.mts` (dry-run by default) soft-deleted 377 phantom tasks across 6 dev projects.
- **JOIN-duplicate projects:** a corp with multiple active integration API keys causes duplicate project rows when joining via `integration_keys`. Fix uses `DISTINCT` (all-live query) and `EXISTS` (single-project fallback) instead of a plain JOIN.
- **Stale TODO/handoff docs are unverified.** `tickets/TODO-batch-tasks.md` falsely claimed `GET/POST /api/projects/[id]/tasks/batch`, `src/components/dispatch-checklist.tsx`, and `src/lib/assign-targets.ts` were shipped — none existed (`assign-targets.ts` had zero consumers); actually built in commit `9f0d873`.
- **`review_requested` is about Google reviews**, requesting reviews from customers (`offices.google_review_url`), entirely unrelated to internal crew quality ratings — do not conflate (clarified in [[colin/decisions|DECISIONS]] for T-16).
- **QA toolbar `save()` bugs:** failed PATCHes don't roll back optimistic `today`/`previewKey` state (stay set until refresh), and `useTransition` only gates the post-fetch `router.refresh()`, not the PATCH itself (rapid clicks fire concurrent unordered PATCHes). Fixes: restore a pre-save snapshot in the `!res.ok` branch; wrap the full `save()` in the transition or a `saving` ref.

## Open questions / TODOs

- **"Voice notes" (talkie updates)** was *inferred* by schema authors from Eric's founding-meeting quote ("…just the talkie updates"); Eric never explicitly requested audio-recording functionality — confirm with Eric before building any audio infrastructure. See [[colin/people-and-context|People & Context]].
- **`feat/redesign-v2`** was abandoned mid-session (user disliked it after token spend); the full redesign was committed to branch `redesign-trash` (commit `0ce3df3`) for possible cherry-picking, main restored, a pre-redesign snapshot saved as a separate branch. Migration `0037` remains applied to dev (additive) — open question whether/what to cherry-pick.
- **Component/rendered-behavior test coverage is entirely missing** (Node-only vitest). Adding jsdom + a React DOM harness is an outstanding gap if role-gated chrome, reporting-bar visibility, LabelsModal, or QA-toolbar localStorage are to be tested.

---

**Pattern:** most of these are environment/deploy friction and parallel-session state confusion, not application bugs. The app code moved fast; the recurring time sinks were AWS auth, the local↔dev↔live mental model, mock contamination from concurrent sessions, and the tsx/`server-only` boundary. When something looks broken mid-session, suspect a parallel session or a stale cache **before** suspecting your own code.
