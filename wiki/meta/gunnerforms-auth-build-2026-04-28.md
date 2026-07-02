---
type: session
title: "GunnerForms Auth System Build — 2026-04-28"
created: 2026-04-28
updated: 2026-04-28
tags:
  - gunner
  - ios
  - swift
  - cloudflare
  - auth
  - d1
  - resend
status: developing
related:
  - "[[gunnerteam/gunner-forms-app]]"
  - "[[vendors/monday]]"
---

# GunnerForms Auth System Build — 2026-04-28

Session covering the full auth system design and infrastructure setup for GunnerForms iOS app. Worker code complete and deployed. iOS screens not yet built. Admin bootstrap pending.

---

## Infrastructure Completed

- **Wrangler CLI** installed globally via npm (`npm install -g wrangler`, v4.86.0)
- **D1 database** `gunner-forms-db` created via Cloudflare dashboard, bound to `gunner-forms-api` worker as `DB`
- **Resend** account created, domain `updates.gunnerroofing.com` added, DNS records added to Cloudflare manually (Auto configure failed — OAuth issue). Sending access only. API key stored in Keeper as `gunner-forms-worker`.
- **Worker secrets added**: `JWT_SECRET` (40+ chars), `ADMIN_SECRET` (34 chars), `RESEND_API_KEY` — all stored in Keeper record "GunnerForms Worker Secrets"

## D1 Schema

```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  salt TEXT NOT NULL,
  email TEXT,
  role TEXT NOT NULL DEFAULT 'user',
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE submissions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER REFERENCES users(id),
  form_type TEXT NOT NULL,
  monday_item_id TEXT,
  form_data TEXT,
  submitted_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE invite_tokens (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  token TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'user',
  created_at TEXT DEFAULT (datetime('now')),
  expires_at TEXT NOT NULL,
  used INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE reset_tokens (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  token TEXT NOT NULL UNIQUE,
  user_id INTEGER NOT NULL REFERENCES users(id),
  created_at TEXT DEFAULT (datetime('now')),
  expires_at TEXT NOT NULL,
  used INTEGER NOT NULL DEFAULT 0
);
```

## Auth System Design

Two roles: `admin` and `user`. Admins can invite users, reset passwords, list all users. Users can only access forms.

### User lifecycle
1. Admin sends invite from iOS admin panel → `POST /auth/invite` → Resend emails `gunnerforms://invite?token=...` deep link
2. Employee taps link on iPhone → app opens invite screen → sets username + password → `POST /auth/complete-invite` → account created, JWT returned
3. Login: `POST /auth/login` → JWT (90-day expiry, HS256, stored in iOS Keychain)
4. Forgot password: enters email → `POST /auth/forgot` → Resend emails `gunnerforms://reset?token=...` → taps link → sets new password via `POST /auth/complete-reset`
5. Admin can force-reset any user's password via `POST /auth/admin-reset` (requires admin JWT)

### Worker routes (all in `gunner-forms-api`)

| Route | Auth | Purpose |
|-------|------|---------|
| `POST /auth/login` | None | Username + password → JWT + role |
| `GET /auth/validate` | Bearer JWT | Validate token, return username + role |
| `POST /auth/invite` | Admin JWT | Generate invite token, send email |
| `POST /auth/accept-invite` | None | Validate invite token (called before showing signup screen) |
| `POST /auth/complete-invite` | None | Set username + password, create account, return JWT |
| `POST /auth/forgot` | None | Send password reset email (silent if email not found) |
| `POST /auth/complete-reset` | None | Set new password via reset token |
| `GET /auth/users` | Admin JWT | List all users |
| `POST /auth/admin-reset` | Admin JWT | Reset any user's password by userId |

### Security implementation
- **Password hashing**: PBKDF2-SHA256, 100,000 iterations, 16-byte random salt, 256-bit output — all via Web Crypto API (native to CF Workers)
- **JWT**: HS256, HMAC-SHA256 signing, 90-day expiry, payload contains `sub` (userId), `username`, `role`
- **Invite tokens**: 32-byte random hex, 7-day expiry, single-use
- **Reset tokens**: 32-byte random hex, 1-hour expiry, single-use
- **Admin auth**: JWT must contain `role: "admin"` — checked server-side on every admin route
- **Email enumeration protection**: `/auth/forgot` returns `{success: true}` whether or not email exists

### Email sending
- Provider: Resend (`api.resend.com/emails`)
- From: `GunnerForms <noreply@updates.gunnerroofing.com>`
- Secret: `RESEND_API_KEY` worker secret
- Invite email contains `gunnerforms://` deep link (requires URL scheme registration in iOS app)
- Reset email contains `gunnerforms://reset?token=...` deep link, 1-hour expiry noted in body

## Pending: Admin Bootstrap (Chicken-and-Egg)

No admin account exists yet. `/auth/register` route was removed. `/auth/admin-reset` requires an admin JWT. Solution: insert Tyler's account directly via D1 console with a temporary password, log in to get JWT, then immediately change password via admin-reset (or just keep the temporary one and change it from the iOS app once built).

**Steps to complete tomorrow:**
1. Insert admin row in D1 console:
```sql
INSERT INTO users (username, password_hash, salt, email, role)
VALUES ('tyler', 'placeholder', 'placeholder', 'tyler.suffern@gunnerroofing.com', 'admin');
```
2. Use worker's `/auth/admin-reset` with userId=1 and real password — but this requires admin JWT (catch-22). Instead: set a real temporary password in the INSERT, log in to get JWT, then admin-reset to final password.
3. Alternatively: add a one-time bootstrap route to the worker, use it once, remove it.

## Pending: iOS Screens to Build

- Login screen (username + password, forgot password link)
- Invite acceptance screen (set username + password from deep link)
- Password reset screen (from deep link)
- Admin panel (invite user, list users, reset password)
- URL scheme `gunnerforms://` registration in Info.plist
- JWT storage in iOS Keychain
- Auth state management (show login vs. main content)

## AP Form Status

`APFormView.swift` on branch `feature/ap-native` — built but not yet added to Xcode project target. Worker updated with `/submit-ap` route and `boardContext: "ap"` file upload routing. Needs to be added to project.pbxproj and tested end-to-end.

## Change Order Status

Test board `18410487288` still active. Swap to production `18310339669` after end-to-end test passes.
