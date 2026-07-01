---
type: session
title: session-2026-06-30-cc08-09-comms-admin-tls-packaging
created: '2026-06-30'
updated: '2026-06-30'
tags:
  - comms-admin
  - tls
  - rds-proxy
  - sst
  - lambda
  - python
  - packaging
  - iam
  - vpc
status: stable
related:
  - '[[tyler/meta/session-2026-06-29-cc2820-3002-comms-admin-full-stack]]'
  - '[[shared/rds-proxy-tls-and-sst-python-packaging]]'
  - '[[gunnerteam/aws-environment]]'
---

# Session cc-08 / cc-09 — comms-admin DB TLS (verify-ca) + real Python packaging

Two work items on `gunner-comms-admin` (the admin-only read-only viewer over masterdb `dp_*`, SST/
Pulumi + Python 3.12 Lambda). cc-08 got the never-before-deployed dev stage to `/health` `db:ok` — which
required a DB-TLS fix plus clearing a cascade of pre-existing stage bugs. cc-09 replaced the cc-08
vendored-wheel stopgap with real `pyproject.toml`-driven packaging. Both committed on branch
`cc-08-db-tls-verify-ca` (commits `18a202b`, `b9d95a1`→ actually `5aacc41`; see below). **Not deployed to
prod** — dev stage only. Uses `AWS_PROFILE=mfa` (the `tyler-cli` user is MFA-gated via `GunnerRequireMFA`;
plain calls hit an explicit SSM deny).

## cc-08 — DB TLS verify-full → verify-ca (`backend/src/comms_admin/db.py`)

The stated task: `sslmode=verify-full` fails against the RDS **Proxy** endpoint (hostname-match quirk);
`verify-ca` validates the chain (rejects rogue/self-signed) and only relaxes the hostname check. Keep
`sslrootcert`; never `require`/`disable` (this service reads customer conversations). One-line change +
WHY comment. Confirmed `config.py` builds a bare URL (`sslmode` set only in `db.py` `connect_args`).

**But the dev stage had never deployed**, so `/health` surfaced a cascade — all fixed to reach `db:ok`:
1. **The real DB blocker (root cause):** even with verify-ca, the proxy connection failed
   `SSL error: certificate verify failed`. **RDS Proxy presents a cert issued by Amazon Trust Services
   (a PUBLIC CA), not the RDS regional CA that signs instance certs.** `rds-combined-ca-bundle.pem`
   (regional roots only, 108 certs) can't build that chain. Fix: `certs/proxy-ca-bundle.pem` = RDS
   regional bundle **+** certifi's Mozilla/public roots (Amazon Root CA 1-4, Starfield Services Root G2)
   = 300 certs; point `sslrootcert` at it. This mirrors `gunnerteam-api`'s `db.js`
   (`[...rdsBundle, ...tls.rootCertificates]`). See [[shared/rds-proxy-tls-and-sst-python-packaging]].
2. **`_CERT_PATH` miscount:** was `.parent×4` (→ `/`) with a `.parent×2` fallback; neither resolves.
   Correct = `.parent×3` (bundle root in both the Lambda zip `/var/task` and the source tree
   `backend/`).
3. **SST/Pulumi config drift** (`sst.config.ts`, provider `aws@7.x`): StaticSite
   `securityHeadersConfig.xContentTypeOptions` (invalid) → `contentTypeOptions:{override:true}`
   (verified against the Pulumi schema); the object-form `transform.cdn` replaced `defaultCacheBehavior`
   wholesale (dropped required `viewerProtocolPolicy`/`allowedMethods`) → hoist the ResponseHeadersPolicy
   to a const and use a **transform function** that mutates `args`; Lambda `vpc.subnets` →
   `vpc.privateSubnets` (SST rename).
4. **IAM:** the Lambda role had only `s3:GetObject` → added `ssm:GetParameters` (on
   `parameter/gunner/comms-admin/<stage>/*`) + `kms:Decrypt` (the AWS-managed `alias/aws/ssm` key
   `af11e2f0…`). Account id hardcoded — a Pulumi `Output` can't be string-interpolated into a policy ARN
   (`MalformedPolicyDocument`).
5. **VPC (the hang):** the provided `SubnetId1` (`subnet-0d89c369…`) was a **public** subnet (routes
   `0.0.0.0/0 → IGW`); Lambda ENIs get no public IP, so every cold-start `ssm:GetParameters` hung to the
   29s timeout. Repointed `SubnetId1` → the proxy's own private subnet `subnet-0481e68e…` (same VPC
   `vpc-0530f022b0273f215`, NAT egress, AZ `us-east-2b`; HA pair with `SubnetId2` in `us-east-2a`). The
   proxy SG `sg-0e3345754d47898b8` already admits the Lambda SG on 5432; the network path was open — the
   only gap was SSM egress. **Diagnostic:** `connect_timeout` (a psycopg param) can't bound a hang in the
   boto3 SSM call — a 30s hang that survives `connect_timeout` points at SSM egress / DNS, not psycopg.
6. **cc-03 reconstruction:** `routes/activity.py` and `routes/thread.py` were committed without their
   module header — `router = Router()`, the `_BadRequest` class, and `_VALID_TYPES`/`_VALID_DIRECTIONS`/
   `_DEFAULT_LIMIT`/`_MAX_LIMIT` were used but never defined → both modules (and `app.py`) crashed at
   import (`NameError: router`). Rebuilt from the authoritative siblings (`calls.py`'s `_BadRequest`) +
   the feed vocabulary (`feed.py` `'sms'`/`'call'`, direction `'inbound'`/`'outbound'`, limit 50–100).
7. **Deps stopgap (cc-08):** `bundle:"backend"` installs no deps, so cc-08 vendored prebuilt manylinux
   x86_64 wheels into `backend/src/` — flagged as tech debt, replaced in cc-09.

Result: `/health` → `{"ok":true,"db":"ok"}`. Committed `18a202b` (verify-ca, proxy-ca-bundle, IAM, SST
fixes, cc-03 reconstruction) + the vendored wheels.

## cc-09 — replace vendored wheels with real packaging (uv postbuild)

`pyproject.toml` is the source of truth. Mechanism = **`hook.postbuild`** in `sst.config.ts` (chosen over
SST native uv packaging, which would need dropping `bundle:` + a uv workspace + uncertain arm64→x86_64
native-ext cross-resolution). Installs deps with uv, platform-pinned:
`uv pip install -r backend/pyproject.toml --target <depsDir> --python-platform x86_64-manylinux2014
--python-version 3.12 --only-binary=:all:`.

- **`bundle:"backend"` builds in place** — SST's `postbuild(dir)` gets `dir == backend/` (the source
  dir, not a staging copy), so a naïve `--target dir` scattered x86_64 packages across the source root
  and broke arm64 local pytest (`dlopen … slice is not valid mach-o`, since pytest's rootdir insertion
  put `backend/` on `sys.path`). Fix: install into a gitignored **`backend/.deps/`** subdir (cleared
  first for determinism) and add `/var/task/.deps` to `PYTHONPATH` (`/var/task/src:/var/task/.deps`).
  `.deps/` ships in the zip; the source root stays clean.
- **SST forbids top-level imports in `sst.config.ts`** → the hook uses `await import("node:child_process")`
  etc. inline (the documented `ts-no-dynamic-import` exception; static import cannot work here).
- Removed the vendored tree — `backend/src/` = only `comms_admin/` (3067 deletions).
- **`pyproject.toml` latent bugs the vendoring masked:** `PyJWT[cryptography]` → `PyJWT[crypto]`
  (PyJWT's extra is `crypto`; the wrong name silently dropped `cryptography`, which `auth.py` needs for
  RS256 — exactly why cc-08 hand-vendored cryptography). `moto[ssm,cognito-idp]` → `moto[ssm,cognitoidp]`
  (moto's extra is `cognitoidp`; test dep).
- **`.gitignore`:** added `.deps/`, broadened `tsconfig.tsbuildinfo` → `*.tsbuildinfo`. `resource.enc`
  (SST's per-build encrypted `SST_KEY_FILE` — the linking key, runtime-decrypted via the `SST_KEY` env
  var), `sst.pyi`, `sst-env.d.ts` already ignored (prior `6fefa80`); `git check-ignore` confirms all SST
  artifacts covered.

**Verify:** `sst deploy --stage dev` → deps install into `.deps/`, zip carries `.deps/`+`src/`+`certs/`,
native `.so` are `cp312-x86_64-linux-gnu`; `GET /health` → `db:ok` ×3; **arm64 local pytest 48/48** in an
isolated `/tmp` 3.12 venv (arm64 wheels; `.deps` x86_64 output not on pytest's `sys.path`). No vendored
packages under `backend/src/`. Committed `5aacc41` on branch `cc-08-db-tls-verify-ca` (branch is local,
not pushed).

## Key facts / gotchas
- **RDS Proxy TLS ≠ RDS instance TLS.** The proxy cert chains to a **public** CA (Amazon Trust Services),
  so the trust bundle must include public roots — the regional `rds-combined-ca-bundle.pem` alone fails
  chain validation. `verify-ca` (not `verify-full`) for the proxy hostname quirk; never `require`.
  Detail + reuse guidance: [[shared/rds-proxy-tls-and-sst-python-packaging]].
- **`gunnerteam-dev-masterdb-proxy` fronts PROD `sczazkvf`** — comms-admin (dev stage) reads the prod
  `dp_*` feed through it. VPC `vpc-0530f022b0273f215`; proxy SG `sg-0e3345754d47898b8` admits the app SG
  on 5432; proxy private subnets `subnet-0481e68e…` (us-east-2b) + `subnet-004acfd6…` (us-east-2a).
- **Lambda in a public subnet = no egress** (no public IP) → SSM/boto3 hangs to timeout. Put VPC Lambdas
  in private subnets with NAT (or an SSM interface endpoint). `connect_timeout` only bounds psycopg, not
  boto3/DNS.
- **SST `bundle:"backend"` builds in place** (postbuild `dir` == source), copies the whole dir verbatim
  (ships `tests/`, `.pytest_cache/`), and installs no deps — hence the `.deps/` subdir + PYTHONPATH.
- **`AWS_PROFILE=mfa`** for all comms-admin deploys (tyler-cli MFA-gated).
