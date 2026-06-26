---
type: session
title: 'cc-2807–2809: Dialpad updated_at + consumer polling + event-loss monitoring'
created: '2026-06-26'
updated: '2026-06-26'
tags:
  - dialpad
  - masterdb
  - alembic
  - terraform
  - cloudwatch
  - monitoring
  - lambda
  - session
status: stable
related:
  - '[[gunnerteam/overview]]'
  - '[[leo/overview]]'
  - '[[meta/session-2026-06-19-cc1500-1505-terraform-infra-hardening]]'
---

# cc-2807–2809: Dialpad updated_at + Consumer Polling + Event-Loss Monitoring

Three paired prompts delivered in sequence on 2026-06-26. Together they close the Dialpad
reliability loop: a cursor column for consumer polling (cc-2807), app-side touches + a health
metric task (cc-2808), and Terraform alarms + IAM + scheduled task wire-up (cc-2809).

---

## cc-2807 — `updated_at` + cursor index on `dp_sms_messages` / `dp_calls` (masterdb p21)

**Problem:** `dp_calls` rows enrich in place after the initial hangup row (recording, transcription,
recap, voicemail arrive seconds–minutes later). A `created_at` cursor misses all enrichment. Leo's
HubSpot app and Finder need a reliable poll cursor.

**Solution:** Alembic revision `p21_dialpad_updated_at` adds:
- `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()` to both `dp_sms_messages` and `dp_calls`
- Composite index `(org_id, updated_at)` on each table for cursor-range queries

**Key execution details:**
- p20 source was missing from git (only `.pyc` in `__pycache__`); pyc inspection confirmed revision
  ID `p20_dialpad_agents` and its full DDL before writing p21.
- Remote `main` had diverged (crew-members-rls PR merged); resolved merge conflict in
  `.github/workflows/rls-isolation.yml` (took theirs), then committed + pushed (commit `b7f0449`).
- The throwaway prod migrate-Lambda (`gunner-masterdb-migrate-runner`) was already present but
  not deleted from p20. Its zip lacked p17/p18/p19 — `upgrade head` failed with
  `KeyError: 'p19_dialpad_ingest_tables'`. Fixed by rebuilding the zip with all migration sources
  from the repo before re-uploading.
- `q1_crew_members_rls` was already applied (head), so two heads existed (q1 + p21, both off p20).
  `upgrade head` failed with "Multiple head revisions". Used `upgrade_to p21_dialpad_updated_at`
  instead (the `upgrade_to` action already existed in `db/migrate.py`).
- Verified via gunnerteam-api `_sql` (runs as `gunnerteam_app`):
  - `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()` on both tables ✅
  - Both `(org_id, updated_at)` indexes present ✅
  - No new GRANT needed — p19 table grant covers new columns ✅
- Throwaway Lambda (`gunner-masterdb-migrate-cc2807`) + S3 artifact (`lambda-cc2807.zip`) deleted.

**No new GRANT required.** `GRANT SELECT, INSERT, UPDATE` from p19 covers all new columns automatically in PostgreSQL.

---

## cc-2808 — Dialpad tunable rate limit + `updated_at` touches + `dialpad-health` task

**Three changes to `gunnerteam-api/`:**

### Phase 1 — Configurable rate limit + drop/bad-sig logging (`src/routes/dialpad.js`)

```js
const { intEnv } = require('../lib/perf');   // added import

const webhookLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: intEnv('DIALPAD_WEBHOOK_RATE_MAX', 600),  // was 120; call events ~4-6/call
  standardHeaders: true,
  legacyHeaders: false,
  store: makeStore(60 * 1000, 'dialpad-webhook'),
  handler: (req, res) => {
    console.warn('[dialpad] rate_limited');   // cc-2809 alarms on this
    res.status(429).json({ error: 'Too many requests' });
  },
});

// JWT-verify failure path:
if (!payload) { console.warn('[dialpad] bad_signature'); return res.status(401).json({ error: 'bad signature' }); }
```

The existing `console.error('[dialpad] webhook error:', …)` in the catch block is left intact —
cc-2809 keys an ingest-error alarm off it.

### Phase 2 — Touch `updated_at = now()` on every write

Added `updated_at = now()` to three places in `dialpad.js`:
1. `ingestSms` → `ON CONFLICT … DO UPDATE SET` (SMS upsert)
2. `ingestCall` final-state → `ON CONFLICT … DO UPDATE SET` (call upsert)
3. `ingestCall` enrich-only → `UPDATE dp_calls SET …` branch

INSERTs omit it — the column defaults to `now()`.

### Phase 3 — `dialpad-health` scheduled task (`src/lib/scheduler.js`)

```js
const { CloudWatchClient, PutMetricDataCommand } = require('@aws-sdk/client-cloudwatch');
const _cw = new CloudWatchClient({ region: process.env.AWS_REGION_ || process.env.AWS_REGION || 'us-east-2' });

async function dialpadHealthCount() {
  const { rows } = await query(
    `SELECT (SELECT count(*) FROM dp_sms_messages WHERE created_at > now() - interval '1 hour')
          + (SELECT count(*) FROM dp_calls        WHERE created_at > now() - interval '1 hour') AS n`
  );
  const n = Number(rows[0]?.n ?? 0);
  try {
    await _cw.send(new PutMetricDataCommand({
      Namespace: 'gunnerteam/dev',
      MetricData: [{ MetricName: 'DialpadRowsLastHour', Value: n, Unit: 'Count', Timestamp: new Date() }],
    }));
  } catch (err) {
    console.error('[dialpad-health] PutMetricData failed:', err.message);
  }
  console.log(`[dialpad-health] rows_last_hour=${n}`);
  return { ok: true, task: 'dialpad-health', n };
}
```

Wired into `runScheduledTasks` dispatch alongside existing `if (task === …)` branches.

**`@aws-sdk/client-cloudwatch`** added to `package.json` (`^3.700.0`) and installed.

**Deployed:** Lambda v389, `live` alias updated. Probe returned `{ok:true,task:'dialpad-health',n:0}`.

---

## cc-2809 — Terraform: rate-max env, PutMetricData IAM, 4 alarms, health schedule

**Applied to `~/Dev/GunnerTeam/terraform/`.**

### Phase 1 — SSM + `lambda-api.tf` env

```bash
aws ssm put-parameter --name /gunnerteam/dev/DIALPAD_WEBHOOK_RATE_MAX --type String --value "600" --overwrite
```

`lambda-api.tf`:
```hcl
data "aws_ssm_parameter" "dialpad_webhook_rate_max" { name = "/${var.app_name}/${var.env}/DIALPAD_WEBHOOK_RATE_MAX" }
# in environment { variables = { … } }:
DIALPAD_WEBHOOK_RATE_MAX = data.aws_ssm_parameter.dialpad_webhook_rate_max.value
```

### Phase 2 — PutMetricData IAM

Added to `aws_iam_role_policy.lambda_api` in `lambda-api.tf`:
```hcl
{
  Sid      = "CloudWatchMetrics"
  Effect   = "Allow"
  Action   = ["cloudwatch:PutMetricData"]
  Resource = "*"
}
```

After apply, `dialpad-health` emits `DialpadRowsLastHour` with no IAM error.

### Phase 3 — `dialpad-monitoring.tf` (new file)

Four resources created in namespace `gunnerteam/dev`, all wired to `aws_sns_topic.alerts`:

| Resource | Metric | Threshold | Period | treat_missing |
|---|---|---|---|---|
| `dialpad_dropped` filter+alarm | `DialpadWebhookDropped` | ≥1 | 5 min | notBreaching |
| `dialpad_ingest_error` filter+alarm | `DialpadIngestError` | ≥1 | 5 min | notBreaching |
| `dialpad_bad_sig` filter+alarm | `DialpadBadSignature` | ≥5 | 5 min | notBreaching |
| `dialpad_silence` alarm (no filter) | `DialpadRowsLastHour` | < 1 | 1 hr × 2 | notBreaching |

**Silence alarm design:** `treat_missing_data = notBreaching` means off-hours (no metric emitted)
stays quiet. Two consecutive hours of `DialpadRowsLastHour < 1` during business hours triggers.

### Phase 4 — `eventbridge.tf` health schedule

```hcl
dialpad-health = {
  schedule    = "cron(0 12-23 ? * MON-FRI *)"   # hourly ~8am-7pm ET
  description = "Hourly business-hours count of dp_* rows → DialpadRowsLastHour metric (silence alarm)"
}
```

The `for_each` pattern auto-creates EventBridge rule + target + Lambda permission.

### Phase 5 — Apply result

```
Plan: 11 to add, 2 to change, 1 to destroy.
Apply complete! Resources: 11 added, 2 changed, 1 destroyed.
```

The "1 destroyed" is `null_resource.clear_alias_routing` — replaced on every Lambda env change, not a real resource loss.

**Lambda v390 published, `live` alias updated.**

---

## Gotchas & Lessons

**Alembic multi-head:** When two migrations both chain off the same parent (`p20`), Alembic
reports two heads. `upgrade head` is ambiguous; must use `upgrade_to <specific_revision>` or
`upgrade heads` (plural). The migrate Lambda handler had `upgrade_to` already — use it when
branching exists.

**Throwaway Lambda zip completeness:** The zip must include ALL migration sources back to the
initial revision. Alembic builds the full revision map at import time; a missing `down_revision`
parent causes a `KeyError`. Always pull sources from the repo before bundling.

**PostgreSQL column grants:** New columns added to an already-granted table are automatically
accessible by the grantee. No additional `GRANT` is needed for `updated_at`.

**CloudWatch `default_value = "0"` on metric filters:** Newly created alarms backed by log metric
filters start as `INSUFFICIENT_DATA` until the first evaluation window clears. They transition to
`OK` (not `ALARM`) once the default-value zero-fills the evaluation period. This is expected — not
a misconfiguration.

**`null_resource.clear_alias_routing` destroy:** This Terraform null_resource fires whenever the
Lambda function changes (including env var updates). It always shows as "1 destroyed, 1 added" in
plans that touch the Lambda — expected behavior, not a risk.

---

## Final State After All Three Prompts

- **masterdb:** head = `p21_dialpad_updated_at, q1_crew_members_rls` (two parallel heads)
- **gunnerteam-api:** v390, `live` alias; `updated_at` touched on every dp_* write
- **SSM:** `/gunnerteam/dev/DIALPAD_WEBHOOK_RATE_MAX = 600`
- **CloudWatch alarms:** 4 dialpad alarms active, all → `gunnerteam-dev-alerts` SNS
- **EventBridge:** `dialpad-health` task runs hourly Mon–Fri 8am–7pm ET
- **IAM:** API role can now call `cloudwatch:PutMetricData`
