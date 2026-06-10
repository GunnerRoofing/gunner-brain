---
type: concept
title: "GunnerTeam Performance Standards"
created: 2026-05-27
updated: 2026-05-27
tags:
  - gunnerteam
  - performance
  - backend
  - ios
  - aws
  - required-reading
status: evergreen
related:
  - "[[gunner/gunnerteam-api-aws-migration]]"
  - "[[gunner/gunnerteam-project-structure]]"
  - "[[gunner/secure-coding-guide]]"
---

# GunnerTeam Performance Standards

> [!key-insight] Required reading
> This is required reading before any backend or iOS work. The app had 25-30s request hangs caused by every pattern listed below.

---

## Backend — Node.js / Lambda / Aurora

### DB Queries: query() vs queryWithTenant()

**Use `query()` for read-only routes that already filter by `org_id`:**

```js
// ✅ Fast — no transaction overhead
const result = await query(
  'SELECT * FROM gt_vehicles WHERE org_id = $1 AND active = TRUE',
  [req.orgId]
);

// ❌ Slow — wraps every call in BEGIN / SET LOCAL / COMMIT
const result = await queryWithTenant(req.orgId,
  'SELECT * FROM gt_vehicles WHERE active = TRUE', []
);
```

Use `queryWithTenant` only when you need RLS row-level org isolation AND cannot add an explicit `org_id` filter to the WHERE clause.

### N+1 Queries: Never Loop and Query

Looping over a collection and firing one query per item turns a single request into N+1 round-trips — one to fetch the list, then one per row — all serialized through the connection pool. At 15+ rows this is the difference between 50ms and a Lambda timeout. Collapse it into one query: a `JOIN` or `LATERAL JOIN` for related rows, an `IN ($1, $2, …)` clause for a known set of IDs, or a single batch fetch grouped by parent key. Never call a DB function inside `map`, `forEach`, or a loop body.

```js
// ❌ N+1 — fires one query per user, serialized through pool
const summary = await Promise.all(users.map(async u => {
  const last = await queryWithTenant(orgId,
    'SELECT * FROM gt_vehicle_inspections WHERE user_id = $1 LIMIT 1', [u.id]
  );
  return { ...u, last_inspection: last.rows[0] };
}));

// ✅ One query — LATERAL JOIN
const result = await query(`
  SELECT u.*, li.submitted_at, li.review_status
  FROM users u
  LEFT JOIN LATERAL (
    SELECT submitted_at, review_status
    FROM gt_vehicle_inspections
    WHERE user_id = u.id
    ORDER BY submitted_at DESC LIMIT 1
  ) li ON TRUE
  WHERE u.org_id = $1
`, [orgId]);
```

### Connection Pool

```js
// db.js
max: 5,  // ✅ Never set to 1
```

`max: 1` serializes all `Promise.all` parallel queries through a single connection. With 15 users each needing a query, that's 15 sequential round-trips.

### Indexes

Every new table with a hot query path needs indexes before shipping. Required on: `org_id`, `user_id`, `review_status` (partial if nullable), `submitted_at`, `manager_id`, any column used in WHERE or ORDER BY at scale.

```sql
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tablename_column
  ON tablename (column);
-- Always CONCURRENTLY — no table lock on live DB
```

### Route Logging

Every route handler must log at entry:

```js
console.log(`[Module] GET /path user=${req.user.id} role=${req.user.role}`);
```

Without this, Lambda timeouts show START/END with nothing in between and are impossible to diagnose from CloudWatch.

---

## iOS — SwiftUI

### onAppear Fetch Guard

`onAppear` fires on every view appearance — tab switches, nav pops, sheet dismissals. Always guard:

```swift
// ✅ Correct
@State private var hasFetched = false

.onAppear {
    guard !hasFetched else { return }
    hasFetched = true
    Task { await loadData() }
}

// ❌ Wrong — fires 4x on every navigation event
.onAppear {
    Task { await loadData() }
}
```

### Cancel In-Flight Requests

A view re-fetches constantly — filter changes, pull-to-refresh, a fast tab switch — and the previous request is often still in flight. Hold the `Task` handle and `cancel()` it before launching the next one, so a stale response can never overwrite fresh state and the abandoned work stops at its next suspension point. On the Node.js side the equivalent is an `AbortController`: pass its `signal` into the `fetch` or upstream call and `abort()` it when the request is superseded, freeing the socket instead of waiting on a dead response.

```swift
@State private var fetchTask: Task<Void, Never>?

func loadData() {
    fetchTask?.cancel()
    fetchTask = Task { await fetchFromAPI() }
}
```

### Hoist Shared Data Fetches

If multiple child views in the same nav stack need the same data, fetch once in the parent and pass down. Never have siblings independently fetching the same endpoint.

---

## AWS / Lambda Architecture

- **Keep-warm EventBridge must target the `live` alias**, not `$LATEST`. `$LATEST` is never the version serving traffic.
- **Aurora `connectionTimeoutMillis` must be > 15000** — Aurora Serverless v2 takes ~15s to resume from pause. 20000 is the minimum safe value.
- **Always publish-version + update-alias after deploy** — `update-function-code` alone does not route traffic. The `live` alias must point to the new version.
- **Terraform lifecycle blocks on Lambda resources** — add `ignore_changes = [source_code_hash, s3_key, s3_object_version]` to prevent Terraform from reverting manual deploys.

---

## Pre-Ship Checklist

Run through these before shipping any cc-prompt:

1. Does any route loop over rows and call a DB function per row? → Rewrite as JOIN/LATERAL.
2. Does any route use `queryWithTenant` on a query that already has `WHERE org_id = $1`? → Switch to `query()`.
3. Does any new table lack indexes on filtered/sorted columns? → Add migration.
4. Does any new SwiftUI view fetch data in `onAppear` without a `hasFetched` guard? → Add guard.
5. Does any new EventBridge rule target `aws_lambda_function.api.arn`? → Must use alias ARN.
