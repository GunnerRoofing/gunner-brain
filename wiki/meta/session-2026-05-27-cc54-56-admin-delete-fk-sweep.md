---
type: session
title: "cc-prompts 54–56: Admin Delete User — Complete FK Sweep"
created: 2026-05-27
updated: 2026-05-27
tags:
  - gunnerteam
  - api
  - postgres
  - fk
  - admin
  - soc2
status: stable
related:
  - "[[meta/session-2026-05-27-omp-plugins-cc51-53]]"
---

# cc-prompts 54–56: Admin Delete User — Complete FK Sweep

Five iterative deploys to get `POST /auth/admin-delete` working. Each deploy surfaced the next FK violation. cc-56 uses the full FK map from `information_schema` to do it in one shot.

---

## The Final Transaction Block (cc-56)

Both `POST /auth/admin-delete` and `DELETE /auth/admin/users/:id` in `auth.js` share this pattern:

```javascript
await client.query(`SET LOCAL app.current_org_id = '${orgId}'`);

// NULL-out secondary FK references (preserve rows, remove user pointer)
await client.query('UPDATE audit_log                  SET user_id      = NULL WHERE user_id      = $1', [userId]);
await client.query('UPDATE audit_logs                 SET user_id      = NULL WHERE user_id      = $1', [userId]);
await client.query('UPDATE gt_announcements           SET author_id    = NULL WHERE author_id    = $1', [userId]);
await client.query('UPDATE gt_vehicle_documents       SET uploaded_by  = NULL WHERE uploaded_by  = $1', [userId]);
await client.query('UPDATE gt_vehicle_other_documents SET uploaded_by  = NULL WHERE uploaded_by  = $1', [userId]);
await client.query('UPDATE gt_vehicle_inspections     SET reviewed_by  = NULL WHERE reviewed_by  = $1', [userId]);
await client.query('UPDATE gt_vehicle_maintenance     SET created_by   = NULL WHERE created_by   = $1', [userId]);
await client.query('UPDATE gt_vehicles                SET assigned_user_id = NULL WHERE assigned_user_id = $1', [userId]);
await client.query('UPDATE gt_user_profile            SET manager_id   = NULL WHERE manager_id   = $1', [userId]);
await client.query('UPDATE invite_tokens              SET manager_id   = NULL WHERE manager_id   = $1', [userId]);

// DELETE rows owned by this user
await client.query('DELETE FROM crew_members              WHERE user_id = $1', [userId]);
await client.query('DELETE FROM gt_vehicle_inspections    WHERE user_id = $1', [userId]);
await client.query('DELETE FROM gt_vehicle_schedules      WHERE user_id = $1', [userId]);
await client.query('DELETE FROM gt_vehicle_license_plates WHERE user_id = $1', [userId]);
await client.query('DELETE FROM gt_user_profile           WHERE user_id = $1', [userId]);
await client.query('DELETE FROM reset_tokens              WHERE user_id = $1', [userId]);
await client.query('DELETE FROM user_devices              WHERE user_id = $1', [userId]);
await client.query('DELETE FROM user_app_roles            WHERE user_id = $1', [userId]);
await client.query('DELETE FROM user_organizations        WHERE user_id = $1', [userId]);

// Delete the user (no org_id filter — users table has no direct org_id column in masterdb)
await client.query('DELETE FROM users WHERE id = $1', [userId]);

// SOC 2 CC6.1 — audit log inside transaction
await client.query(
  `INSERT INTO audit_log (id, org_id, user_id, action, details, ip_address, created_at)
   VALUES (gen_random_uuid(), $1, $2, 'admin.delete_user', $3, $4, NOW())`,
  [orgId, req.user.id,
   JSON.stringify({ deleted_user_id: userId, deleted_email: user.email }),
   req.ip]
);
```

---

## Key Lessons / Permanent Rules

### `queryWithTenant` must NOT be used inside a transaction
`queryWithTenant` checks out its own connection from the pool and auto-commits. Using it inside a `pool.connect()` transaction block breaks atomicity — each call runs on a separate connection. Use `client.query()` exclusively inside the transaction, and set RLS context manually:
```javascript
await client.query(`SET LOCAL app.current_org_id = $1`, [orgId]);
```

### `users` table has no `org_id` column in masterdb
The masterdb `users` table is not tenant-scoped by a direct column. Org membership lives in `user_organizations`. `DELETE FROM users WHERE id = $1 AND org_id = $2` always fails with "column does not exist." Cross-tenant safety is enforced by RLS via `SET LOCAL`.

### `req.user.orgId` is always `undefined`
`requireAuth` in `middleware/auth.js` puts the orgId on `req.orgId` (not `req.user.orgId`). The user object from `resolveUser()` has `{id, username, email, firstName, lastName, role, orgSlug}` — no `orgId` field.

### `requireAdmin` does not exist
The middleware exports `{requireAuth, requireRole, maybeAuth}`. Use `requireRole('admin')` — it must be imported alongside `requireAuth`.

### `audit_log`/`audit_logs` user_id: NULL out, don't delete (SOC 2)
Both audit log tables reference `users.user_id` as a FK. Deleting audit rows would violate SOC 2 audit trail requirements. NULL out `user_id` to preserve the record while removing the foreign key reference.

### How to get the complete FK map
Add this diagnostic route temporarily:
```javascript
router.get('/admin/fk-check', requireAuth, requireRole('admin'), async (req, res) => {
  const { rows } = await queryWithTenant(req.orgId, `
    SELECT tc.table_name, kcu.column_name, ccu.table_name AS foreign_table
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY' AND ccu.table_name = 'users'
    ORDER BY tc.table_name, kcu.column_name
  `, []);
  return res.json(rows);
});
```
Remove after running once.

---

## FK Violation History (for reference)

Each FK was discovered one deploy at a time because the transaction rolled back on the first violation:

| Deploy | FK violated | Fix |
|---|---|---|
| v70 | `user_organizations_user_id_fkey` | Added transaction; child deletes |
| v71 | `users.org_id does not exist` | Removed `AND org_id = $2` from DELETE |
| v72 | `gt_vehicle_inspections_reviewed_by_fkey` | NULL-out reviewed_by |
| v73 | `gt_vehicles.assigned_user_id` | NULL-out assigned_user_id |
| v74 | `audit_log.user_id` | NULL-out user_id (preserve SOC 2) |
| v75 | Full FK sweep | All 10 NULL-outs + crew_members DELETE |

---

## Other Session Items

### pi-powerline-footer permanently removed
Still broken on 15.5.2. `omp plugin uninstall pi-powerline-footer` — wait for a fixed version before reinstalling. The built-in status line covers the same functionality.

### GitHub token 401 — missing closing quote
Token was saved to `~/.zshrc` without the closing `"`. Fix:
```bash
sed -i '' '/GITHUB_PERSONAL_ACCESS_TOKEN/d' ~/.zshrc
echo 'export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_..."' >> ~/.zshrc
source ~/.zshrc
```
Verify: `curl -sf -H "Authorization: Bearer $GITHUB_PERSONAL_ACCESS_TOKEN" https://api.github.com/user | python3 -c "import json,sys; print(json.load(sys.stdin)['login'])"`

### Cognito app client ID
`6m41qei5jq3nt46jler56im1cg` (from `GunnerForms/GunnerTeam/amplifyconfiguration.json`)

### MFA session pattern
`AWS_PROFILE=mfa` commands expire every ~60 minutes. Always chain update-function-code + wait + publish-version + update-alias in a single command block. Zip can be pre-built without MFA: `zip -r /tmp/gt-deploy.zip . --exclude "*.git*"`.
