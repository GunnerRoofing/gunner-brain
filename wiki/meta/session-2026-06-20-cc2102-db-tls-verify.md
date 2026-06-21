---
type: session
title: session-2026-06-20-cc2102-db-tls-verify
created: '2026-06-20'
updated: '2026-06-20'
tags:
  - gunnerteam
  - backend
  - security
  - soc2
  - tls
  - rds
  - incident
status: stable
related:
  - '[[gunnerteam/aws-environment]]'
  - '[[meta/session-2026-06-20-cc2101-ci-sast-sbom-audit]]'
---

# Session cc-prompt-2102 — DB TLS: verify RDS server cert (CC6.7)

Replace `ssl: { rejectUnauthorized: false }` in `gunnerteam-api/src/lib/db.js` with real
server-cert verification. **Lambda v328 live, verified end-to-end.** Brief self-inflicted
outage during rollout (v325, ~minutes) — rolled back, root-caused, fixed correctly.

## The actual fix (after one wrong turn)

```js
const tls = require('tls');
const rdsBundle = fs.readFileSync(path.join(__dirname, '../../certs/rds-global-bundle.pem'),'utf8')
  .split(/(?=-----BEGIN CERTIFICATE-----)/).map(c=>c.trim()).filter(Boolean);
const dbCa = [...rdsBundle, ...tls.rootCertificates];
// pool: ssl: { ca: dbCa, rejectUnauthorized: true }
```

## KEY DISCOVERY — RDS Proxy uses a PUBLIC Amazon Trust Services cert, not an RDS CA

Captured the proxy's presented chain in-VPC (temporary secret-guarded peer-cert probe):
```
*.proxy-c52gm8goign8.us-east-2.rds.amazonaws.com
  → Amazon RSA 2048 M04 → Amazon Root CA 1 → Starfield Services Root CA - G2
```
The vendored RDS `global-bundle.pem` contains only **RDS-specific** CAs, so it could NOT chain
the proxy cert → every DB connect failed `unable to get local issuer certificate` (v325, all DB
routes 503). The proxy's roots live in Node's **default** trust store. Fix = trust BOTH the RDS
bundle (for direct-instance) AND `tls.rootCertificates` (public roots incl. Amazon/Starfield).
Splitting the bundle into an array was NOT the issue (tried, still failed) — it was the wrong
trust anchors.

## Path gotcha

`db.js` is at `src/lib/` → Lambda `__dirname=/var/task/src/lib`, bundle at `/var/task/certs`
→ **`../../certs/`** (the prompt's `../certs/` assumed a root-level `lib/`). Wrong path would
502 every route at module load; `/health` 200 confirmed the path resolved.

## Alias routing gotchas (cost the outage — IMPORTANT)

1. **Inline single-quoted `--routing-config '{"AdditionalVersionWeights":{}}'` gets MANGLED by
   the bash tool** → leaves/creates a stale `{<ver>:1.0}` weight that routes 100% to the WRONG
   version (cc-867 redux). My rollback to v324 didn't take because a phantom `{325:1.0}` kept
   serving the broken v325. **Pass the JSON via an env var** (`--routing-config "$RC"`, RC set
   in env) — that cleared it.
2. **`get-alias` returns eventually-consistent / phantom `{oldVer:1.0}` reads** even when the
   update response was `RoutingConfig: null`. Do NOT trust get-alias for "which version serves."
   **Verify via CloudWatch log-stream `[version]` tags** (`describe-log-streams --order-by
   LastEventTime`) — definitive. v328 streams confirmed live traffic on the fix.

## Safe deploy-iteration technique (reused next time)

Test candidate versions WITHOUT touching the live alias:
- `aws lambda publish-version` → candidate vN (alias stays put).
- DB-TLS probe = `aws lambda invoke --qualifier vN --payload '{"_migration":"20260610_task_photos_unique","_secret":"<MIGRATION_SECRET>"}'` — the migration runner does `pool.connect()` (the TLS handshake) then a no-op idempotent `CREATE UNIQUE INDEX IF NOT EXISTS`. Returns `[{"ok":true}]` if TLS verifies, cert error if not. Auth-free, no live impact.
- Promote alias only after the probe passes.

## Verification (v328, live)

- Probe → `[{"ok":true}]`; `/health` 200; `/fleet/my-vehicle` 200 (DB-backed, verified TLS);
  logs: `db.connect ms=34`, zero `local issuer`/cert errors.

## Flags / state

- v328 = main + TLS fix; still **lacks cc-2101 dep fixes** (PR #6 unmerged → node-forge/multer highs persist).
- Temporary peer-cert diagnostic was added to lambda.js then fully removed before final commit.
- Commits on main: `0101da5` (vendor bundle + initial — broken global-only ca) then `8b77c53` (correct combined-CA fix). Not yet pushed to origin.
