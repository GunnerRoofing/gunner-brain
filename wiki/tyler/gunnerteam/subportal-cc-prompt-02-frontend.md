---
type: source
title: Subcontractor Portal — cc-prompt-02 Frontend Scaffold
created: '2026-05-22'
updated: '2026-05-22'
tags:
  - subportal
  - react
  - vite
  - amplify
  - shadcn
  - msw
  - frontend
status: active
related:
  - '[[tyler/gunnerteam/subportal-cc-prompt-01-scaffold]]'
  - '[[tyler/masterdb/masterdb-architecture]]'
  - '[[gunnerteam/secure-coding-guide]]'
---
# Subcontractor Portal — cc-prompt-02 Frontend Scaffold

**Working directory:** `gunner-subportal/` root (not `frontend/`)  
**Run in:** Claude Code session in that directory  
**Builds:** React+Vite+TypeScript frontend with Amplify auth, shadcn/ui, MSW mocks

---

## Stack

| Layer | Technology | Why |
|---|---|---|
| Framework | React 18 + Vite 5 + TypeScript 5 | Standard |
| Auth | Amplify UI v6 `@aws-amplify/ui-react` | `<Authenticator>` = login/MFA in ~10 lines; team already uses Cognito |
| Styling | Tailwind CSS v3 + shadcn/ui | shadcn components copy-pasted to repo (no lock-in); white-label = CSS var swaps |
| Mock API | MSW v2 (Mock Service Worker) | Full UI works offline; flip proxy target when backend deploys |
| HTTP | Native `fetch` with typed wrapper | No axios |
| Routing | React Router v6 | |
| State | React context + hooks only | No Redux |

---

## Before Running

1. Create `frontend/.env.local` with real Cognito values (same pool as GunnerTeam app):
   ```
   VITE_COGNITO_USER_POOL_ID=us-east-2_XXXXXXXXX
   VITE_COGNITO_CLIENT_ID=XXXXXXXXXXXXXXXXXXXXXXXXXX
   VITE_API_URL=
   ```
2. `npx shadcn-ui@latest init` asks interactive questions — accept defaults, choose **CSS variables** for theming
3. `msw init public/` generates a service worker — **commit that file**, it's not a secret

---

## Directory Structure

```
frontend/src/
├── components/
│   ├── ui/              # shadcn (do not edit)
│   ├── Layout.tsx        # nav shell + tenant logo/colors
│   ├── SearchForm.tsx    # postal + trade + radius inputs
│   ├── SubCard.tsx       # search result card
│   └── ContactModal.tsx  # reveals phone/email (audit-logged)
├── pages/
│   ├── SearchPage.tsx
│   └── NotFoundPage.tsx
├── lib/
│   ├── api.ts            # typed fetch wrapper — all API calls here
│   └── auth.ts           # Amplify configure
├── mocks/
│   ├── browser.ts        # MSW setup
│   └── handlers.ts       # mock handlers
├── types/
│   └── subcontractor.ts  # shared TS types
├── App.tsx
├── main.tsx
└── index.css             # Tailwind + CSS custom properties
```

---

## Key Implementation Decisions

### White-label via CSS variables
All brand colors are CSS custom properties — never hardcoded hex. Tenants swap `--brand-primary`, `--brand-accent`, `--brand-logo-url` at runtime.

```css
:root {
  --brand-primary: 220 90% 40%;    /* Gunner blue */
  --brand-accent: 28 95% 50%;      /* Gunner orange */
  --brand-logo-url: url("/logo.svg");
}
```

Tailwind config maps `brand` and `accent` to these vars.

### Auth pattern
`<Authenticator hideSignUp={true}>` wraps all routes. No unauthenticated route is reachable. JWT auto-attached by Amplify's `fetchAuthSession` in `api.ts`.

To bypass for local UI dev: temporarily render `children` directly in App.tsx (remove before real testing).

### API client — no org_id in requests
```typescript
// NEVER pass org_id — comes from JWT on backend
export async function searchSubcontractors(params: SearchParams) {
  const headers = await getAuthHeaders(); // fetchAuthSession() → idToken
  return apiFetch(`/subcontractors/search?${qs}`, { headers });
}
```

### Contact reveal pattern
Contact info is NOT in search results. Separate `revealContact(subId)` call made only when user explicitly opens `ContactModal`. Not cached — every open is a new audited API call (SOC 2 CC6.2, CC7.2).

### MSW mock handlers
```typescript
// Hard cap mirrors backend
http.get("/subcontractors/search", () =>
  HttpResponse.json({ results: MOCK_SUBS.slice(0, 8) })
)
```
MSW starts only when `import.meta.env.DEV` — zero production impact.

---

## Installed Packages

```bash
# Core
npm install react-router-dom @aws-amplify/ui-react aws-amplify

# Styling
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
npx shadcn-ui@latest init
npx shadcn-ui@latest add button card badge input label select dialog separator

# Mocks
npm install -D msw
npx msw init public/ --save
```

---

## TypeScript Types

```typescript
/** Search result — intentionally excludes email/phone/address */
interface SubSearchResult {
  id: string; company_name: string; city: string; state: string;
  trade: string; avg_rating: number; review_count: number;
  is_verified: boolean; boost_tier: "free" | "pro" | "featured";
}

/** Only returned by /subcontractors/{id}/contact after audit log */
interface SubContactInfo {
  id: string; email: string | null; phone: string | null; address_1: string | null;
}
```

---

## Acceptance Criteria

- `npm run dev` starts without errors
- Amplify login screen renders at `localhost:5173`
- `npx tsc --noEmit` → 0 errors
- Mock search returns results (MSW intercepts)
- Contact modal fires a **separate** API call (not cached)
- Result count shown but total DB count never exposed
- All colors reference CSS vars — no hardcoded hex anywhere
- No `console.log` with user data

---

## Hard Stops

- Contact info (email/phone) must NOT be in search result payload
- No `localStorage`/`sessionStorage` for auth tokens (Amplify handles this)
- Only `lib/auth.ts` and `lib/api.ts` import from `aws-amplify/auth`
- MSW only imported in `main.tsx` and `mocks/`

---

## Commit Message

```
feat: scaffold subportal frontend — React+Vite+Amplify+MSW

- Vite 5 + React 18 + TypeScript 5 + React Router v6
- Amplify UI v6: Cognito login, JWT auto-attached to all API calls
- Tailwind + shadcn/ui: white-label via CSS custom properties
- MSW v2: mock search + contact reveal (no AWS needed for local dev)
- SearchPage + SubCard + ContactModal (audit-logged contact reveal)

Next: cc-prompt-03 — Cognito pool wiring + real API integration
```


## Implementation Notes (2026-05-22)

- shadcn@latest v4.8.0 requires `components.json` pre-created; `init` CLI is interactive and ignores `--yes` on preset selection
- Tailwind v4 installed by default; explicitly pinned to v3 (`tailwindcss@3`) per spec
- Path aliases (`@/*`) must be in both `tsconfig.json` AND `tsconfig.app.json`
- `tailwindcss-animate` required as a separate install for shadcn component animations
