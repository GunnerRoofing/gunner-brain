---
type: session
title: 'cc-2213–2215: resolveOrgName uuid=varchar join fix + fieldportal drift reconcile + deploy-doc fix'
created: '2026-06-30'
updated: '2026-06-30'
tags:
  - gunnerteam
  - lambda
  - postgres
  - white-label
  - incident
  - deploy
  - fieldportal
  - subportal
  - session
status: stable
related:
  - '[[gunnerteam/overview]]'
  - '[[gunnerteam/meta/session-2026-06-30-cc2211-3201-whitelabel-audit-flush]]'
  - '[[tyler/meta/session-2026-06-25-bedrock-billing-qp-key-org-reconcile]]'
  - '[[meta/session-2026-06-20-cc2102-db-tls-verify]]'
  - '[[meta/session-2026-06-20-cc2129-org-scope-ci-guard]]'
---

# cc-2213–2215: resolveOrgName join fix, fieldportal drift reconcile, deploy-doc fix

Three sequential prompts on 2026-06-30 in `gunner-ios` / `gunnerteam-api/`, all downstream of the
cc-2211/2212 white-label work ([[gunnerteam/meta/session-2026-06-30-cc2211-3201-whitelabel-audit-flush]]).
A forgot-password smoke rendered the `'your company'` fallback instead of "Gunner Roofing";
diagnosing it exposed a swallowed 500-class bug (cc-2213), whose deploy exposed a certs-omission
outage and a pre-existing deployed≠git drift (cc-2214), whose recovery exposed a wrong deploy doc
(cc-2215). **Lambda v421 → v424 live. Commits `2c13ce8` (cc-2213), `f75237d` (cc-2214),
`21f4bfe` (cc-2215) on `origin/main`.**

---

## cc-2213 — `resolveOrgName` uuid=varchar join throws → `'your company'` for EVERY caller

**Symptom:** the cc-2212 forgot-password reset email rendered `resolveOrgName`'s fallback
`'your company'` instead of the org name.

**Diagnostic (read-only, via the in-VPC `_sql` admin Lambda, MIGRATION_SECRET-gated):** The two
pre-written hypotheses were both DISPROVEN:
- **Not a data gap** — both org rows have non-null `name = "Gunner Roofing"` (real `69aad261` slug
  `gunnerroofing`; shell `7d6db1bb` slug `gunner`).
- **Not the `LIMIT 1` picking the shell** — the smoke user `tyler.suffern@gunnerroofing.com` has a
  single membership row, under the REAL org `69aad261`; the freshest `reset_tokens` row landed there.

**Real root cause (a third cause):** `resolveOrgName` (`src/lib/assistant-tasks.js`) does
`LEFT JOIN gt_org_theme t ON t.org_id = o.id`, but **`organizations.id` is `character varying`
while `gt_org_theme.org_id` is `uuid`**. Postgres raises `operator does not exist: uuid = character
varying` at execution for the WHOLE statement (regardless of `orgId` or row matches — `gt_org_theme`
is empty anyway), and the function's bare `catch { return 'your company'; }` swallowed it silently.
So EVERY caller rendered the fallback: reset/invite/welcome emails + push, `/invite` + `/reset`
deep-link pages, assistant persona.

**Regression pinned:** introduced by **cc-2211 `de4965a`** (added the uncast `LEFT JOIN
gt_org_theme`); before it the query was a plain `SELECT name FROM organizations WHERE id=$1` that
worked. cc-2212 `1e7ae8a` then wired the now-broken resolver into the reset email, surfacing it.

**Fix (two edits, per the prompt):**
```sql
LEFT JOIN gt_org_theme t ON t.org_id::text = o.id   -- cast the uuid side (::text never throws; cc-2205 convention)
```
```js
} catch (err) {
  console.error('[resolveOrgName] failed:', err.message);  // stop masking 500-class bugs
  return 'your company';
}
```
Plus a unit test asserting the emitted SQL uses the text-cast join key (fails if anyone reverts to
the cc-2211 uncast form). `node --check` ✓, `assistant-tasks.test.js` 6/6, full suite **179/179**.

**Deploy — and a self-inflicted outage:** The README's deploy zip (`zip … src/ node_modules/`)
OMITTED `certs/`. `db.js:15` reads `certs/rds-global-bundle.pem` at module init → `ENOENT` init
crash on every invocation → **prod down**. Recovered by rolling the `live` alias back to v421
(immutable, known-good) within ~1 min (`/health` 200 restored). Rebuilt the artifact by
**patching the known-good v421 zip** with only the fixed file (certs + all runtime dirs preserved)
→ v422 (a first clean deploy), then re-verified.

**Live verification (v423):** forgot-password on v423 → 200, `[email] sent … via ses`, and
crucially **no `[resolveOrgName] failed:` line** (pre-fix, every call logged the throw). The exact
deployed casted query returns `{"name":"Gunner Roofing"}`; a fresh `reset_tokens` row landed under
the real org. ⇒ subject/FROM render "Gunner Roofing".

Committed **only** `assistant-tasks.js` + its test as `2c13ce8`; pushed (also carried the user's
pre-existing local iOS-only commit `cc-3105`, zero backend impact).

---

## cc-2214 — reconcile `fieldportal.js` deployed≠git drift (the live SubPortal backend)

**Discovery (during cc-2213):** `src/routes/fieldportal.js` was **deployed in v421 but never
committed** — it carried the live SubPortal backend. Prior prompts had mislabeled it "user WIP" and
left it unstaged, so git lacked live code. This is the deployed≠git drift class behind an earlier
multi-hour incident. Confirmed the working-tree copy == deployed v421 byte-for-byte.

**Phase 1 — diff is exactly the intended SubPortal code** (no mystery edits): cc-2210 distinct
webhook secret `FIELD_PORTAL_CREW_ASSIGNED_SECRET` + `sc.user_id::text` cast; cc-2208
`/jobs/:jobId/photos` sub branch calling Colin's `/photos` route directly (its 404 = the crew
org-verify, preverify GET removed). (cc-2204 sub-feed branch / `subCrewIdForUser` already committed
— only in unchanged context.)

**Phase 2 — the `check:orgscope` flag at fieldportal.js:209 is a FALSE POSITIVE, verified
structurally.** The flagged query is the `project.crew.assigned` crew→sub-users push map. Schema
check: `gt_subcontractor_crew.crew_id` is `uuid` (globally unique) and `org_id` is `NOT NULL` → one
crew ⇒ one org, so scoping by `crew_id = $1` cannot cross tenants. It's a service-auth signed
webhook (HMAC via `FIELD_PORTAL_CREW_ASSIGNED_SECRET`) with no `req.orgId`, so crew_id is the
correct scope. Resolved with the checker's escape hatch — a Postgres-ignored SQL comment on the
`WHERE` line (kept inside the `query(` span; must not break the `query(\s*` + backtick adjacency
the regex needs):
```sql
WHERE sc.crew_id = $1   -- org-scope-ok: crew_id is a global UUID (one crew → one org); service-auth webhook, no req.orgId — crew-scoped, not cross-tenant (cc-2214)
```
`check:orgscope` now OK.

**Deploy (Phase 3 conditional):** the annotation is a file change, so per the prompt's "if Phase 2
required a code fix, deploy first" — patched the live v423 artifact with the annotated file → **v424**
(comment-only; SQL functionally identical), `/health` 200. Committed **only** `fieldportal.js` as
`f75237d`; verified the downloaded, actually-deployed v424 `fieldportal.js` == `origin/main`
(**diff empty**). Drift closed.

---

## cc-2215 — fix the deploy doc so the zip includes `certs/` + `migrations/`

**Root cause of the doc bug:** `README.md`'s deploy zip used `zip -r … src/ node_modules/`, which
drops `certs/` (and `migrations/`) — the exact omission that caused the cc-2213 outage. The
canonical block in `CLAUDE.md` already uses the correct whole-dir form.

**Fix (docs only):** switched README to `zip -r /tmp/lambda-deploy.zip . -x "*.git*"
"node_modules/.cache/*"` (whole-dir, so a new runtime dir can't be silently dropped), added `rm -f`
first (avoid stale-merge), and added a pre-upload guard note: the artifact MUST contain
`certs/rds-global-bundle.pem` + `migrations/`, verifiable via
`unzip -l /tmp/lambda-deploy.zip | grep -E 'certs/|migrations/'`, plus a "keep in sync with
CLAUDE.md" pointer. Verified via grep that `certs/rds-global-bundle.pem` (db.js:15) is the ONLY disk
read outside `src/`/`node_modules/`. Dry-ran the corrected command → guard printed both present.
Committed as `21f4bfe` (README.md only, no deploy).

---

## Gotchas & Lessons

**Swallowing errors hides 500-class bugs as cosmetic fallbacks.** `catch { return fallback }` with
no log turned a hard `uuid = varchar` query failure into a silent "your company" everywhere. Always
log before falling back.

**uuid vs varchar joins throw for the whole statement.** `organizations.id` is `varchar` (users.id
too, per the schema note); `gt_*` tables use `uuid`. Cross-type joins fail at execution regardless
of data — cast the uuid side with `::text` (the cc-2205 convention; `::text` never throws on a bad
value, unlike `o.id::uuid`).

**The Lambda deploy artifact needs `certs/` (and `migrations/`), not just `src/`+`node_modules/`.**
`db.js` reads `certs/rds-global-bundle.pem` at init; omitting it = `ENOENT` init crash / outage.
Use the whole-dir `zip . -x <excludes>` form and guard with
`unzip -l … | grep -E 'certs/|migrations/'` before upload.

**Safest emergency redeploy = patch the known-good live artifact.** When a fresh zip broke init,
downloading the immutable last-good version's artifact and swapping only the one changed file (certs
+ all runtime dirs preserved) was lower-risk than rebuilding from scratch. Roll the alias back to
the immutable prior version FIRST to restore service, then fix the artifact.

**deployed≠git drift is a real incident class.** Code deployed without being committed (here
`fieldportal.js`, live since v421) means git lacks load-bearing code and the next "reconcile from
git" silently reverts live behavior. Reconcile by committing the live artifact's exact bytes, then
diff the downloaded deployed version against `origin/main` to prove closure.

**org-scope guard false positives:** a `gt_*` read scoped by a globally-unique UUID (e.g. `crew_id`)
in a service-auth webhook with no `req.orgId` is safe — annotate `// org-scope-ok <reason>` inside
the `query(` span without breaking the `query(` + backtick adjacency the checker's regex needs.

---

## Final State

- **Lambda:** **v424 live** (`gunnerteam-dev-api`, alias `live`). v421→v422 (cc-2213 first clean)
  →v423 (verified)→v424 (cc-2214 annotation).
- **`origin/main`:** `2c13ce8` (cc-2213 assistant-tasks.js + test) → `f75237d` (cc-2214
  fieldportal.js reconcile) → `21f4bfe` (cc-2215 README). Local/origin synced.
- **resolveOrgName:** casted join live; renders "Gunner Roofing", logs on failure. cc-2211 +
  cc-2212 + cc-2213 now truly work together.
- **fieldportal.js:** the live SubPortal backend (cc-2204/2208/2210) now in git == deployed v424
  byte-for-byte; orgscope flag annotated.
- **README deploy doc:** whole-dir zip + certs/migrations guard, consistent with CLAUDE.md.
