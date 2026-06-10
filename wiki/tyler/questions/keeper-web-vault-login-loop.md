---
title: Keeper Web Vault Login Redirect Loop
type: question
tags:
  - keeper
  - chrome
  - troubleshooting
  - browser
created: '2026-04-14'
updated: '2026-04-14'
status: stable
sources: []
related:
  - '"[[vendors/keeper]]"'
  - '"[[vendors/google-workspace]]"'
  - '"[[gunner/chrome-policy]]"'
---

# Keeper Web Vault Login Redirect Loop

**Symptom:** Logging into the Keeper web vault in Chrome causes an immediate page refresh back to the login screen. The Chrome extension popup login works fine.

**Root cause:** The Keeper Chrome extension intercepts the web vault login flow and redirects before the session can establish — causing a loop. The extension working normally while the web vault fails is the diagnostic signature of this conflict.

---

## Diagnosis Steps

1. **Test in Incognito** (extensions disabled by default) → go to the Keeper web vault → log in
   - If it works: the extension is the cause → proceed to fixes below
   - If it still fails: not extension-related → check cookies and Chrome policy

2. **Check Chrome policy interference** — Tyler's environment has HTTPS-Only mode enforced via Chrome Enterprise. If Keeper's login flow involves any HTTP redirect, it may be getting killed. Check `chrome://net-internals/#events` while logging in to observe redirects.

3. **Test in a different browser** (Safari, Firefox) — if it works there, the issue is Chrome-specific (extension or policy).

---

## Fixes

**Clear Keeper cookies:**
- `chrome://settings/cookies` → search "keeper" → delete all entries for `keepersecurity.com`
- Retry the web vault login

**Temporarily disable the extension:**
- `chrome://extensions` → Keeper → toggle off
- Log into the web vault
- Re-enable the extension

**Incognito workaround (quick access):**
- Open an Incognito window → log into web vault
- Works because extensions are disabled by default in Incognito

---

## Notes

- The extension login (popup dropdown) and the web vault login are separate authentication paths — the extension can work even when the web vault is broken
- This is a known pattern with password manager extensions that have "web vault detection" logic
- If the issue recurs after clearing cookies, the extension may need to be updated or the web vault URL may need to be added to an extension exclusion list
