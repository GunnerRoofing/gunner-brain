---
type: session
title: "Fellow App (Gunner Notes) — MV3 Remote-Code Store Rejection Fix"
created: 2026-07-01
updated: 2026-07-01
tags:
  - chrome-extension
  - mv3
  - firebase
  - chrome-web-store
status: developing
related:
  - "[[shared/rds-proxy-tls-and-sst-python-packaging]]"
---

# Fellow App (Gunner Notes) — MV3 Remote-Code Store Rejection Fix

Repo: `/Users/tyler.suffern/Dev/Gunner Notes/Fellow App` (Gunner Notes Chrome extension — collaborative meeting notes tied to Google Calendar meetings, injects into Google Meet and Calendar). Not part of the tracked GunnerTeam/gunnerteam-brain apps; a separate personal/side project.

## Problem

Chrome Web Store rejected the package: "Including remotely hosted code in a Manifest V3 item." The extension imported Firebase Auth from the standard `firebase/auth` entry point in `src/lib/firebase.ts`. That entry bundles the popup/redirect resolver and reCAPTCHA loaders, which dynamically fetch `https://apis.google.com/js/api.js`, `https://www.google.com/recaptcha/api.js`, and call `gapi.load`. The app never exercises that path — it only calls `signInWithCredential` with an ID token obtained via `chrome.identity.launchWebAuthFlow` — but the code was present in the bundle and MV3's static analysis flags any remote-code-capable path regardless of reachability.

## Fix

Firebase ships an extension-safe entry point that excludes the remote-loading popup/reCAPTCHA code and uses extension-appropriate persistence: `firebase/auth/web-extension`. Available since Firebase ≥10 (project is on 12.15.0). It exports the same named symbols the app needs (`getAuth`, `Auth`, `GoogleAuthProvider`, `signInWithCredential`, `signOut`, `onAuthStateChanged`, `User`), so the swap is a pure import-path change with zero auth-logic changes.

```ts
// src/lib/firebase.ts
import {
  getAuth,
  Auth,
  GoogleAuthProvider,
  signInWithCredential,
  signOut,
  onAuthStateChanged,
  User,
} from 'firebase/auth/web-extension';
```

Only `src/lib/firebase.ts` imports from Firebase Auth directly; popup and content scripts import the wrapped helpers from `../lib/firebase`, so no other file needed touching.

## Secondary fix bundled in the same release

A separate store rejection flagged the unused `notifications` permission in `manifest.json` — the app's notifications are Gmail-based emails, not `chrome.notifications`. Removed it; kept `identity`, `storage`, `alarms` (all actively used). Version bumped to `1.0.3`.

## Store-build packaging gotcha

The Chrome Web Store forbids a `key` field in an uploaded manifest, but `key` must stay in the manifest used for local `load-unpacked` dev (it pins the extension ID so `chrome.identity.launchWebAuthFlow`'s redirect URI stays stable across reloads). This repo has no dedicated store-packaging script — `dist-store/` is a manually maintained copy of `dist/` with `key` stripped via a one-off `python3 -c "json.load/pop('key')/dump"`. `dist/manifest.json` keeps `key`; `dist-store/manifest.json` does not. Worth automating into `package.json` (`build:store` script) if this project gets touched again — the manual step is an easy thing to forget before a store upload.

## Verification

```bash
npm run build
grep -ohE "apis\.google\.com/js|recaptcha/api\.js|gapi\.load" dist/*.js | sort -u
```
Must print nothing. Confirmed empty across `background.js`, `calendar-inject.js`, `popup.js`, `meet-inject.js` after the fix — proof the remote-loading code path is gone from the bundle, not just unreachable.

Not verified in this session (requires interactive OAuth against the live Firebase project, can't be driven headlessly): actual `signInWithCredential` sign-in flow end-to-end in a loaded unpacked build (popup + Google Meet panel). Flagged as the remaining manual QA step before store upload.

## Takeaway (generalizes to any MV3 extension using Firebase Auth)

If an MV3 extension's only auth need is `signInWithCredential` (token obtained out-of-band, e.g. via `chrome.identity.launchWebAuthFlow`), never import from `firebase/auth` — always use `firebase/auth/web-extension`. The standard entry's popup/redirect/reCAPTCHA code trips MV3's remote-code static analysis even when dead-code-unreachable at runtime; tree-shaking doesn't save you because the loaders are invoked dynamically (`import()`/`gapi.load`), not statically eliminable.
</content>
