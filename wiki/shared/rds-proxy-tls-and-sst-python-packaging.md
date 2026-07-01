---
type: concept
title: "RDS Proxy TLS trust + SST Python Lambda packaging"
created: '2026-06-30'
updated: '2026-06-30'
tags:
  - rds-proxy
  - tls
  - sst
  - lambda
  - python
  - packaging
  - aws
  - shared
status: stable
related:
  - '[[tyler/meta/session-2026-06-30-cc08-09-comms-admin-tls-packaging]]'
  - '[[gunnerteam/meta/session-2026-06-30-cc3101-3103-weather-danger-engine]]'
  - '[[gunnerteam/aws-environment]]'
---

# RDS Proxy TLS trust + SST Python Lambda packaging

Two cross-app gotchas, learned building `gunner-comms-admin` and confirmed against `gunnerteam-api`.
Both cost multiple deploy cycles; both have a clean, verified fix.

## 1. RDS Proxy presents a PUBLIC CA cert — trust the public roots, not just the RDS bundle

An RDS **Proxy** endpoint is **not** an RDS instance. The instance's server cert is signed by the
**RDS regional CA** (the certs in `rds-combined-ca-bundle.pem` / `global-bundle.pem`). The **proxy**'s
cert is issued by **Amazon Trust Services — a public CA** (chains to `Amazon Root CA 1-4` /
`Starfield Services Root G2`), the same roots browsers trust.

**Consequence:** a client whose trust store is the RDS regional bundle **alone** fails against the proxy
with `SSL error: certificate verify failed` — even though the bundle contains the correct regional root.
The regional bundle simply doesn't contain the public roots the proxy chains to.

**Fix — trust BOTH sets:**
- Python (psycopg / libpq): `sslmode=verify-ca` with `sslrootcert` pointed at a combined bundle =
  `rds-combined-ca-bundle.pem` **+** the Mozilla/public roots (`certifi`'s `cacert.pem`). Build it once:
  `cat rds-combined-ca-bundle.pem $(python -m certifi) > proxy-ca-bundle.pem` (~300 certs).
- Node (`pg`): `ssl: { ca: [...rdsBundle, ...tls.rootCertificates], rejectUnauthorized: true }` — this is
  exactly what `gunnerteam-api`'s `lib/db.js` already does, which is why it connects and comms-admin
  (regional-only) didn't.

**`verify-ca` vs `verify-full`:** use **`verify-ca`** for a proxy endpoint. `verify-full` additionally
checks the cert hostname, which fails against the RDS Proxy endpoint (a hostname-match quirk). `verify-ca`
still validates the full chain (rejects rogue/self-signed) and only relaxes the hostname check. **Never**
`require`/`disable` — those skip validation entirely (MITM-exposed).

**CA-bundle path in a Lambda zip:** ship the bundle in the package and resolve it relative to the module
(`Path(__file__).parent…`), not a hardcoded `/var/task/...`. Count parents so it resolves in **both** the
Lambda zip root (`/var/task`) and the local source tree (`backend/`). Fail loud (`RuntimeError`) if the
bundle is missing — never silently downgrade TLS.

## 2. SST Python Lambda packaging — `bundle:` installs NO deps, and builds in place

SST's native Python packaging is uv-based and triggers only when you **don't** set `bundle:`. If a
function uses `bundle: "<dir>"`, SST zips that dir **as-is and installs nothing** — your `pyproject.toml`
deps never make it into the package, and the Lambda fails at init with `Runtime.ImportModuleError`.

Two ways to add deps to a `bundle:`-based Python function:
- **Vendor wheels into the source** (stopgap) — pollutes the tree, drifts from `pyproject.toml`, and
  breaks local dev on a different arch (see arch pinning below). Avoid.
- **`hook.postbuild` that installs from `pyproject.toml`** (the real fix) — deterministic and keeps
  `pyproject.toml` authoritative.

**`hook.postbuild(dir)` runs in place for `bundle:` functions:** `dir` is the directory SST zips, and for
a `bundle:"<dir>"` function that directory **is the source dir**, not a staging copy. So a naïve
`--target dir` scatters dep packages across your source root — polluting the working tree and putting
wrong-arch native extensions where local `pytest` (which inserts the rootdir on `sys.path`) will try to
`dlopen` them. **Install into a gitignored subdir** (e.g. `<dir>/.deps`), clear it first for determinism,
ship it in the zip, and add it to `PYTHONPATH` (`/var/task/src:/var/task/.deps`).

**Cross-arch native extensions (arm64 dev host → x86_64 Lambda):** native wheels (`psycopg`,
`cryptography`, `greenlet`, sqlalchemy c-ext) MUST match the Lambda arch. Pin the target:
`uv pip install -r pyproject.toml --target <dir> --python-platform x86_64-manylinux2014
--python-version 3.12 --only-binary=:all:`. `--only-binary=:all:` forces prebuilt manylinux wheels (no
cross-build of sdists like greenlet). Verify: the shipped `.so` files should read
`cpXXX-x86_64-linux-gnu`. For **local pytest on arm64**, make a separate venv (outside the bundled dir)
and install host-native wheels — never let the x86_64 `.deps` land on the test `sys.path`.

**`sst.config.ts` forbids top-level imports** — use inline `await import(...)` inside hooks (the one place
dynamic import is correct). **SST build/link artifacts to gitignore:** `.sst/`, `sst-env.d.ts`,
`sst.pyi`, `*.tsbuildinfo`, the deps build dir (`.deps/`), and **`resource.enc`** — the per-build
encrypted linking key file (`SST_KEY_FILE`, runtime-decrypted via the `SST_KEY` env var); generated, not
source.

## Extra gotchas confirmed alongside these
- **VPC Lambda in a public subnet has no egress** (no public IP) → boto3/SSM calls hang to the timeout.
  Use private subnets with NAT (or an SSM interface endpoint). `connect_timeout` bounds only the psycopg
  connection — a hang that survives it points at SSM/DNS egress, not the DB.
- **A Pulumi `Output` can't be string-interpolated into an IAM policy ARN** (`MalformedPolicyDocument`) —
  hardcode the account id or use `$interpolate`.
- **PyJWT's crypto extra is `PyJWT[crypto]`** (not `[cryptography]`); **moto's is `moto[cognitoidp]`**
  (not `[cognito-idp]`). A wrong extra name is a silent no-op — `auth.py` RS256 needs `cryptography`.
