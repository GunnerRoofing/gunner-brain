---
type: concept
title: Secure Coding Guide — Gunner Suite
created: '2026-05-22'
updated: '2026-05-22'
tags:
  - security
  - python
  - owasp
  - soc2
  - coding-standards
  - masterdb
  - lambda
  - cognito
status: active
related:
  - '[[tyler/masterdb/masterdb-architecture]]'
  - '[[concepts/soc2]]'
  - '[[gunnerteam/aws-environment]]'
  - '[[gunnerteam/system-security-plan]]'
---
# Secure Coding Guide — Gunner Suite

**Stack:** Python · SQLAlchemy · Pydantic · AWS Cognito · Lambda · Aurora PostgreSQL · SST v3  
**Sources:** OWASP Top 10:2021 · OpenSSF Python Secure Coding Guide  
**Applies to:** All Gunner suite apps (Sales, Ops, Field, Sub Portal, etc.)

---

## Core Principles (Always Apply)

Non-negotiable defaults — applied to every function, route, and model:

1. **Deny by default.** Every Lambda route requires authentication unless explicitly marked public.
2. **Validate at the boundary.** All input validated with Pydantic before it reaches business logic or the DB.
3. **Parameterize everything.** No string interpolation in SQL. SQLAlchemy ORM or `text()` with bound params only.
4. **Secrets from SSM.** No credentials in code, Lambda env vars, or `.env` files. Use SSM Parameter Store.
5. **Least privilege.** IAM roles grant only what the Lambda actually uses. No `*` actions without a comment.
6. **Audit everything privileged.** Every write, delete, assignment, or data access gets an audit row with `org_id`, `user_id`, action, timestamp, entity ID.
7. **org_id on every query.** All tenant-scoped queries filter by `org_id`. RLS is a safety net, not primary enforcement.

---

## A01 — Broken Access Control

The #1 risk. Always scope queries to `org_id` from JWT claims, never from request body.

```python
# ✅ org_id from Cognito claims — never from request body
def get_current_org(event) -> str:
    claims = event.request_context.authorizer.claims
    org_id = claims.get("custom:org_id")
    if not org_id:
        raise UnauthorizedError("Missing org context")
    return org_id

# ✅ Always scope DB queries to org_id
def get_subcontractor(db, sub_id, org_id):
    sub = db.query(Subcontractor).filter(
        Subcontractor.id == sub_id,
        Subcontractor.org_id == org_id  # never omit
    ).first()
    if not sub:
        raise NotFoundError("Not found")  # same message whether missing or forbidden
    return sub
```

**SOC 2:** CC6.1, CC6.2

---

## A02 — Cryptographic Failures

```python
# ✅ Secrets from SSM at cold start
from functools import lru_cache
import boto3

@lru_cache(maxsize=None)
def get_secret(name: str) -> str:
    ssm = boto3.client("ssm", region_name="us-east-2")
    return ssm.get_parameter(Name=name, WithDecryption=True)["Parameter"]["Value"]

# ✅ Log identifiers only — never PII, tokens, secrets
logger.info("Processing payment", extra={"payment_intent_id": intent_id, "org_id": org_id})

# ✅ S3 presigned URLs — never public ACLs
def get_presigned_url(bucket, key, expiry=3600):
    return boto3.client("s3").generate_presigned_url(
        "get_object", Params={"Bucket": bucket, "Key": key}, ExpiresIn=expiry
    )
```

**SOC 2:** CC6.1, CC6.7

---

## A03 — Injection

```python
# ✅ SQLAlchemy ORM — parameterized by default
results = db.query(Subcontractor).filter(
    Subcontractor.state == state,
    Subcontractor.org_id == org_id
).limit(8).all()

# ✅ If raw SQL is unavoidable — always bound parameters
results = db.execute(
    text("SELECT * FROM subcontractors WHERE state = :state AND org_id = :org_id"),
    {"state": state, "org_id": org_id}
).fetchall()

# ❌ Never: f"SELECT * FROM ... WHERE state = '{state}'"
# ❌ Never: shell=True with user input
```

**SOC 2:** CC6.1

---

## A04 — Insecure Design

```python
# ✅ Hard cap search results — never expose total count (prevents enumeration)
return {"results": results[:8]}  # never include "total": total_count

# ✅ Idempotent webhook receivers
def handle_stripe_webhook(event_id, payload, db):
    if db.query(WebhookEvent).filter(WebhookEvent.event_id == event_id).first():
        return {"status": "already_processed"}
    # ... process

# ✅ Response schemas return only what's needed (Pydantic)
class SubcontractorSearchResult(BaseModel):
    id: UUID
    company_name: str
    city: str
    state: str
    trade: str
    avg_rating: float
    # Never include: email, phone, address — reveal on explicit action only
```

---

## A05 — Security Misconfiguration

```python
# ✅ CORS — explicit origins only
ALLOWED_ORIGINS = ["https://app.gunnerroofing.com", "https://*.gunnerroofing.com"]

# ✅ Structured logging — never print() in Lambda
from aws_lambda_powertools import Logger
logger = Logger(service="subportal-api")

@logger.inject_lambda_context(log_event=False)  # False prevents request body logging
def handler(event, context): ...

# ✅ Generic errors to client — stack traces stay in CloudWatch
def handle_error(e):
    logger.exception("Unhandled error")
    return {"error": "Internal server error"}
```

```typescript
// sst.config.ts — 90 days minimum for SOC 2 CC7.2
logRetention: "3 months"
```

**SOC 2:** CC6.6, CC7.2

---

## A06 — Vulnerable Components

```bash
# Pin exact versions in requirements.txt
# Weekly: pip-audit for CVE scanning
pip install pip-audit && pip-audit

# Enable Dependabot on GitHub (.github/dependabot.yml)
# Never use: pickle, yaml.load() (use yaml.safe_load()), eval(), exec()
```

---

## A07 — Authentication Failures

```python
# ✅ API Gateway Cognito authorizer validates JWT before Lambda invokes
# In Lambda, trust claims directly
def get_user_context(event) -> dict:
    claims = event["requestContext"]["authorizer"]["claims"]
    return {
        "user_id": claims["sub"],
        "org_id": claims["custom:org_id"],  # set at JIT provisioning
        "email": claims["email"],
        "roles": claims.get("custom:roles", "").split(","),
    }

# ✅ Manual JWT verification when needed
import jwt
from jwt import PyJWKClient

jwks_client = PyJWKClient(
    f"https://cognito-idp.us-east-2.amazonaws.com/{pool_id}/.well-known/jwks.json"
)

def verify_cognito_token(token: str) -> dict:
    key = jwks_client.get_signing_key_from_jwt(token)
    return jwt.decode(token, key.key, algorithms=["RS256"], options={"verify_exp": True})

# ❌ Never: org_id = request.json.get("org_id")
# ✅ Always: org_id = claims["custom:org_id"]
```

**SOC 2:** CC6.2

---

## A08 — Software and Data Integrity Failures

```python
# ✅ Verify Stripe webhook signatures
def handle_stripe_webhook(body: bytes, signature: str, db):
    secret = get_secret("/gunner/prod/STRIPE_WEBHOOK_SECRET")
    try:
        event = stripe.Webhook.construct_event(body, signature, secret)
    except stripe.error.SignatureVerificationError:
        raise UnauthorizedError("Invalid webhook signature")

# ✅ Validate EventBridge event sources
def handler(event, context):
    if event.get("source") not in ["gunner.sales", "gunner.ops", "gunner.field"]:
        logger.warning("Unexpected event source", extra={"source": event.get("source")})
        return

# ✅ Pydantic instead of pickle for deserialization
data = MySchema.parse_raw(event["body"])
# ❌ Never: pickle.loads(user_provided_bytes)
```

**SOC 2:** CC6.8

---

## A09 — Security Logging and Monitoring Failures

```python
from aws_lambda_powertools import Logger, Tracer, Metrics
from aws_lambda_powertools.metrics import MetricUnit

# ✅ Audit log every privileged action
def log_audit(db, org_id, user_id, action, entity_id=None, metadata=None):
    db.add(AuditLog(
        org_id=org_id, user_id=user_id, action=action,
        entity_id=entity_id, metadata=metadata or {}, ip_address=get_client_ip()
    ))
    db.commit()
    logger.info("Audit event", extra={"action": action, "user_id": user_id, "org_id": org_id})

# ✅ Metrics for CloudWatch alarms
metrics.add_metric(name="AuthFailures", unit=MetricUnit.Count, value=1)

# ✅ Never silently swallow access control failures
try:
    result = get_subcontractor(db, sub_id, org_id)
except NotFoundError:
    logger.warning("Access denied or not found", extra={"sub_id": str(sub_id), "org_id": org_id})
    raise
```

**SOC 2:** CC7.2, CC6.2

---

## A10 — SSRF

Relevant when fetching external URLs (e.g., subcontractor website verification):

```python
import ipaddress, urllib.parse

def is_safe_url(url: str) -> bool:
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme not in ("http", "https"):
        return False
    host = parsed.hostname or ""
    try:
        addr = ipaddress.ip_address(host)
        if addr.is_private or addr.is_loopback or addr.is_link_local:
            return False
    except ValueError:
        pass  # hostname — additional DNS validation recommended
    return True
```

---

## Python-Specific Rules (OpenSSF)

### Secrets — Never In Code

Secrets resolve from SSM Parameter Store at cold start, never from source files, Lambda environment variables, or `.env` files committed to git. The `get_secret()` helper (see A02) fetches and caches each value with `lru_cache`, so API keys, database credentials, webhook secrets, and tokens all load through one decrypting path. A hardcoded secret fails code review, and any secret that reaches git history triggers immediate rotation as a security incident.

```python
# ❌ API_KEY = "sk-live-abc123"
# ✅ API_KEY = get_secret("/gunner/prod/ANTHROPIC_API_KEY")
```

### Input Validation — Pydantic at Every Boundary

Every request body, query parameter, and path parameter passes through a Pydantic model before any business logic or database access runs. Field constraints — `constr` patterns, `Literal` enums, `Field(ge=, le=)` bounds — reject malformed input at the boundary, so invalid data never reaches SQLAlchemy. Validators canonicalize values (trim, normalize case) before checking them. A validation failure returns a 422 with field-level detail, never a stack trace.

```python
class SubSearchRequest(BaseModel):
    postal: constr(regex=r"^\d{5}(-\d{4})?$")
    trade: Literal["roofing", "gutters", "siding", "windows", "solar", "other"]
    radius_miles: int = Field(default=25, ge=1, le=100)

    @validator("postal")
    def validate_postal(cls, v):
        return v.strip()  # canonicalize before validating
```

### Exception Handling — Specific, Never Silent

Handlers catch the narrowest exception type that can actually occur — never a bare `except:` or `except Exception: pass`. The failure is logged with `logger.exception()` to capture the traceback in CloudWatch, then re-raised as a domain error (`DatabaseError`, `NotFoundError`) using `raise ... from e` to preserve the original cause. Silent swallowing hides access-control failures and corrupts the audit trail, so every caught exception is either handled meaningfully or re-raised.

```python
# ❌ except Exception: pass
# ✅
try:
    result = db.query(...)
except SQLAlchemyError as e:
    logger.exception("DB query failed")
    raise DatabaseError("Query failed") from e  # preserve context
```

### Randomness — Use `secrets`, Not `random`

Security-sensitive values — tokens, OTPs, password-reset codes, session identifiers — come from the `secrets` module, which draws on the operating system's cryptographically secure RNG. The `random` module is deterministically seeded and predictable, so an attacker can reproduce its output; it is unsafe for anything guessable. Use `secrets.token_urlsafe()` for URL-safe tokens and `secrets.randbelow()` for bounded integers, and reserve `random` for non-security work such as jitter or sampling.

```python
# ❌ random.randint(100000, 999999)
# ✅
import secrets
token = secrets.token_urlsafe(32)
otp = secrets.randbelow(900000) + 100000
```

### Resource Cleanup — Context Managers
```python
@contextmanager
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

s3_client = boto3.client("s3")  # module-level singleton — not per-request
```

---

## Pre-PR Checklist

- [ ] Every Lambda route verifies Cognito JWT (API Gateway authorizer or manual)
- [ ] `org_id` from JWT claims only — never from request body/params
- [ ] All DB queries include `org_id` filter
- [ ] All input validated with Pydantic before use
- [ ] No raw SQL string concatenation — ORM or `text()` with bound params
- [ ] All secrets from SSM Parameter Store
- [ ] No PII/tokens/secrets in CloudWatch logs
- [ ] Audit row written for every privileged action
- [ ] Webhook receivers verify HMAC/Stripe signature
- [ ] Webhook receivers are idempotent (dedup on event ID)
- [ ] Search endpoints hard-cap results, never expose total count
- [ ] S3 assets via presigned URL — no public ACL
- [ ] CloudWatch log retention ≥ 90 days
- [ ] Error responses: generic to client, detail in logs only
- [ ] `secrets.token_urlsafe()` for generated tokens (never `random`)
- [ ] SOC 2 control in commit message where applicable

---

## SOC 2 Control Map

| Control | What | How |
|---|---|---|
| CC6.1 | Logical access / data at rest | SSM secrets, private S3, RLS, org_id on all queries |
| CC6.2 | Authentication & authorization | Cognito JWT, API Gateway authorizer, org_id from claims |
| CC6.6 | Boundary protection | Cloudflare WAF, API Gateway throttling, CORS allow-list |
| CC6.7 | Data in transit | TLS everywhere, HSTS, presigned S3 URLs only |
| CC6.8 | Change management | Signed webhooks (Stripe, EventBridge source validation) |
| CC7.2 | Monitoring & logging | Audit log table, CloudWatch ≥90d retention, powertools metrics |
| CC9.1 | Risk mitigation | Doc expiry tracking, dependency scanning (pip-audit) |

---

*Sources: OWASP Top 10:2021 · OpenSSF Python Secure Coding Guide · Last updated: 2026-05-22*
