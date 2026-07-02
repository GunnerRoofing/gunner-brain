---
title: 'Session 2026-05-15 — CO Upload Fix, Lambda/Terraform Debugging, Branch Cleanup'
type: session
tags:
  - session
  - gunnerteam-ios
  - lambda
  - terraform
  - monday
  - debug
created: '2026-05-15'
updated: '2026-05-15'
sources: []
related:
  - '[[gunnerteam/gunner-forms-app]]'
  - '[[tyler/gunnerteam/gunnerteam-api-aws-migration]]'
  - '[[vendors/monday]]'
  - '[[summaries/external-api-handoff]]'
status: stable
---

# Session 2026-05-15 — CO Upload Fix, Lambda/Terraform Debugging, Branch Cleanup

---

## Root Cause: Change Order File Upload Silent Failure

**Symptom:** CO form submitted successfully, item appeared in Monday, file column empty. IT Request upload worked. No error returned from Lambda — HTTP 200.

**Root cause:** Stray `; ` (semicolon + space) in the `Content-Disposition` header for the `boardContext` multipart field in `ChangeOrderView.swift`:

```swift
// Broken — trailing ; causes multer to fail parsing the field name
"Content-Disposition: form-data; name=\"boardContext\"; \r\n\r\nco\r\n"

// Fixed
"Content-Disposition: form-data; name=\"boardContext\"\r\n\r\nco\r\n"
```

Multer silently dropped the malformed field. `boardContext` arrived as `undefined` on the server. The `/upload` handler fell through to the default column ID (`file_mm29hc6h`, IT Request) instead of CO's column (`file_mkx79ncz`). Monday received the upload against the wrong column and returned `{"data": {"add_file_to_column": null}}` — HTTP 200, no `errors[]`, silent rejection.

**Fix:** `ChangeOrderView.swift:616` — remove trailing `; ` from the Content-Disposition value.

**Lesson:** Monday's file upload API returns HTTP 200 with `add_file_to_column: null` for wrong-column submissions. It does NOT return `errors[]`. The null-check `if (!data.data?.add_file_to_column)` is required in the upload handler to catch this.

**Commit:** `fix(ios): send boardContext=co on Change Order Form upload` on `forms-quick-fix-2026-05`.

---

## Terraform Branch-Mismatch Gotcha

**Problem:** `terraform apply` was packaging the wrong Lambda code repeatedly. Running `terraform plan` showed 0 changes even after confirmed file edits.

**Root cause:** Terraform's `archive_file` data source packages from the live working tree at `${path.module}/../gunnerteam-api`. If the repo is on the wrong branch (e.g. `forms-quick-fix-2026-05` — an iOS-only branch with an older `forms.js`), Terraform packages that branch's code. `source_code_hash` matched state because it hashed the same old file.

**Fix pattern:** Always `git checkout main` before `terraform apply`. Verify active branch first:
```bash
git branch --show-current   # must be main
cd terraform && terraform apply
```

**Secondary fix:** When Terraform won't detect a change at all (hash stuck), use `terraform taint aws_lambda_function.api` to force replacement on next apply. As a last resort, use AWS CLI directly:
```bash
aws lambda update-function-code --function-name gunnerteam-dev-api --zip-file fileb://... --region us-east-2
```

---

## Monday File Upload — Null Result Pattern

Monday's `/v2/file` endpoint (GraphQL file upload) has a silent failure mode:

- **Success:** `{"data": {"add_file_to_column": {"id": "..."}}}` — asset created
- **Wrong column or item-board mismatch:** `{"data": {"add_file_to_column": null}}` — HTTP 200, no `errors[]`
- **Actual API error:** `{"errors": [...]}` — explicit error array

The upload handler must check all three cases. The null case was the actual CO failure mode.

---

## forms-quick-fix-2026-05 Branch State

A stripped iOS branch for a forms-only build distributed outside ABM when the full app isn't needed. Intentionally diverged from main — kept permanently.

**What it is:** iOS app opens directly to a 5-form WebView list, no login gate, no fleet/announcements/referrals.

**Forms (alphabetized, alternating red/blue):**
1. Accounts Payable Form → Monday hosted form
2. Change Order Form → Monday hosted form
3. IT Request → `wkf.ms/4mpafga`
4. Lowe's COC → `https://ime.myhomeprojectcenter.com/documents`
5. Site Manager Forms → `wkf.ms/3PGtJR9`

**Header:** Gunner logo + "TEAM" wordmark. No navigation bar. `FormsListView` is the root view.

**API base:** `https://api-dev.team.gunnerroofing.com` (same Lambda as main).

**Key files changed vs main:**
- `GunnerFormsApp.swift` — `FormsListView()` as root, no auth
- `Home/ContentView.swift` — stripped to `FormsListView` + `FormCard`; logo header
- `ChangeOrderView.swift` — CO upload boardContext fix applied here too

---

## maybeAuth Middleware

Added to allow anonymous CO form submissions while still attributing when a JWT is present.

```js
function maybeAuth(req, res, next) {
  const header = req.headers['authorization'];
  if (header?.startsWith('Bearer ')) {
    try {
      const payload = verifyToken(header.slice(7));
      req.user       = payload;
      req.tenantId   = payload.tenantId;
      req.tenantSlug = payload.tenantSlug ?? String(payload.tenantId);
    } catch {
      console.warn('maybeAuth: invalid JWT, treating as anonymous');
    }
  }
  next();
}
```

Applied to: `POST /submit-co`, `POST /upload`, `POST /search-projects`.

---

## EventBridge Keep-Warm

Added to eliminate Lambda cold starts on form submissions (previously causing 3–5s delays for first submission after idle).

- **Rule:** `rate(5 minutes)` EventBridge rule → fires `{"keepWarm": true}` at Lambda
- **Handler:** `if (event.keepWarm) return { statusCode: 200, body: 'warm' }` before Express init
- **Effect:** At least one warm container always available; cold-start latency eliminated

Resources in `terraform/eventbridge.tf`.

---

## Branch Cleanup

Deleted 21 stale branches (all already merged into main):

- All feature/* branches (companycam-jobs, vehicle-inspections, tls-alb, gunner-assistant, announcements, navigation, ap-native, change-order-native, it-request-native, ux-improvements, webview-improvements, sign-in-with-monday)
- All fix/* and chore/* branches
- release/forms-v2
- debug/upload-monday-response, debug/upload-response-inspect, debug/login-trace (cleanup pending)

**Remaining branches:** `main`, `forms-quick-fix-2026-05`. Both local and remote.

---

## Login Timeout Investigation (in progress)

**Symptom:** `POST /auth/login` hits Lambda's 30s timeout. Handler enters but never returns.

**Deployed:** `debug/login-trace` branch with `[LOGIN-DEBUG]` console.log before/after every `await` in the login handler.

**Hypothesis:** Hang is at `queryWithTenant` (the user lookup). `queryWithTenant` issues `SET LOCAL app.tenant_id = $1` inside a transaction via the RDS proxy. The `SET LOCAL` may be holding an idle connection open without releasing it — RDS proxy can deadlock if connection pool is exhausted.

**Next step:** After one login attempt, run:
```bash
aws logs tail /aws/lambda/gunnerteam-dev-api --since 2m --filter-pattern "LOGIN-DEBUG"
```
Last `[LOGIN-DEBUG]` line before timeout = exact hang point.

---

## External API Handoff (Colin's App)

Colin's Project Hub external API ingested — see [[summaries/external-api-handoff]].

**Key facts:** `https://project.dev.gunnerroofing.com/api/external/v1`, 7 endpoints, 3-step S3 upload, threaded photo comments via `parentCommentId`. Dev key in SSM as `COMPANYCAM_API_KEY`. 58 tests passing.
