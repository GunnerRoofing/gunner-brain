---
type: session
title: "OMP Plugins Setup + cc-prompts 51–53"
created: 2026-05-27
updated: 2026-05-27
tags:
  - omp
  - plugins
  - ios
  - guided-tasks
  - gunnerteam
status: stable
related:
  - "[[meta/session-2026-05-26-omp-reinstall]]"
  - "[[meta/session-2026-05-26-cc-prompts-39-50-guided-tasks-camera]]"
  - "[[runbooks/omp-hang-fix]]"
---

# OMP Plugins Setup + cc-prompts 51–53

---

## OMP Update — v15.5.2

Updated from 15.4.2 → 15.5.2 via `omp update`. The broken npm publish (pi-natives 404) blocking 15.4.2 is resolved in 15.5.2.

**Breaking change in 15.5.2 (edit format):** Payload continuation lines in hashline patches now require a leading `+`. Blank lines in payloads must also be `+`-prefixed. The OMP harness handles this translation automatically — no manual change needed.

---

## Marketplace System — Manual Clone Workaround

`omp marketplace update claude-plugins-official` hangs because OMP's internal git clone of `anthropics/claude-plugins-official` times out. Git itself works fine. Workaround:

```bash
git clone --depth 1 https://github.com/anthropics/claude-plugins-official.git /tmp/claude-plugins-official
mkdir -p ~/.omp/plugins/cache/marketplaces/claude-plugins-official
cp /tmp/claude-plugins-official/.claude-plugin/marketplace.json \
   ~/.omp/plugins/cache/marketplaces/claude-plugins-official/
cp -r /tmp/claude-plugins-official/plugins \
      ~/.omp/plugins/cache/marketplaces/claude-plugins-official/
cp -r /tmp/claude-plugins-official/external_plugins \
      ~/.omp/plugins/cache/marketplaces/claude-plugins-official/
```

The `external_plugins/` directory is required for plugins like `github` and `terraform` that don't live in `plugins/`. Without it, install fails with "Plugin source directory does not exist."

---

## Full Plugin Inventory (end state 2026-05-27)

### npm Plugins
| Plugin | Version | Status |
|---|---|---|
| `@oh-my-pi/swarm-extension` | 13.17.0 | ✅ works on 15.5.2 (was incompatible on 15.4.1) |
| `pi-obsidian-context` | 0.1.1 | ✅ working |
| `pi-powerline-footer` | 0.5.4 | ✅ works on 15.5.2 (was broken on 15.4.1) |

### Marketplace Plugins (`claude-plugins-official`)
| Plugin | Version | Type | Setup needed |
|---|---|---|---|
| `security-guidance` | 2.0.0 | hooks (auto) | None — active immediately |
| `semgrep` | 0.5.3 | hooks + MCP | `brew install semgrep` ✅ done |
| `aws-core` | 1.0.0 | skills + MCP | `uvx` already installed; uses `~/.aws` creds |
| `github` | 0.0.0 | MCP (HTTP) | `GITHUB_PERSONAL_ACCESS_TOKEN` in `~/.zshrc` |
| `terraform` | 0.0.0 | MCP (Docker) | ⚠️ requires Docker + `TFE_TOKEN`; not useful for local Terraform workflow |
| `typescript-lsp` | 1.0.0 | LSP (passive) | `npm install -g typescript-language-server typescript` ✅ done |
| `commit-commands` | 0.0.0 | slash commands | None |
| `pr-review-toolkit` | 0.0.0 | slash commands | None |
| `claude-md-management` | 1.0.0 | slash commands | None |
| `session-report` | 0.0.0 | slash command | None |

### How Each Plugin Type Works
- **Hooks (auto):** fire on every edit or session stop without invocation — `security-guidance`, `semgrep`
- **Skills:** passive context injection that improves answers — `aws-core`, `pr-review-toolkit`, `claude-md-management`
- **MCP servers:** become callable tools automatically when relevant — `github`, `terraform`, `aws-core`
- **LSP servers:** passive code intelligence (type lookup, references, completion) — `typescript-lsp`
- **Slash commands:** explicit `/command` invocations — `commit-commands` (`/commit`, `/push`, `/pr`), `pr-review-toolkit`, `claude-md-management` (`/claude-md audit`), `session-report` (`/session-report`)

### GitHub Token Setup
Token lives in `~/.zshrc`:
```bash
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_..."
```
Required scopes: `repo`, `read:org`, `read:user`. Token must have closing `"` — omitting it causes silent 401. Verify with:
```bash
curl -sf -H "Authorization: Bearer $GITHUB_PERSONAL_ACCESS_TOKEN" \
  https://api.github.com/user | python3 -c "import json,sys; u=json.load(sys.stdin); print(u['login'])"
```

---

## cc-prompt-51 — Replace UIImagePickerController with InspectionCameraSession

Replaced `GuidedTaskCameraSession` (UIImagePickerController + custom overlay) with `InspectionCameraSession` (AVFoundation, same as vehicle inspection).

**Root cause of UIImagePickerController problems:** warm-up white screen (~0.5–1s), 4:3 viewport with black bars.

**Adapter pattern:** `[GunnerTaskStep]` → `[PhotoStep]` via `enumerated()` in `handleTaskTap`. `sessionRequiredIndices: Set<Int>` tracks which indices are required without needing to add a `required` field to `PhotoStep`.

**Critical fix:** `InspectionCameraSession` is now presented at the **top level** of `fullScreenCover` (no `if let task = cameraTask { }` wrapper). The `if let` wrapper caused `ConditionalContent` wrapping that broke safe-area propagation, which was the root cause of all previous shutter positioning failures.

**Upload pattern:** uploads happen post-session in `onComplete { captured in ... }`, not per-step. If a required step index is missing from `captured`, task is not patched complete.

**Deleted:** `GuidedTaskCameraSession`, `GuidedCameraOverlay`, `GuidedCameraPickerView` (~230 lines, net −218 lines).

---

## cc-prompt-52 — Steps Race Condition + Timestamps

**Bug 1 — 0/N on first tap (steps race):**
`photo_multi` guard `guard let steps = task.steps, !steps.isEmpty` was calling `completeTask` (patching task complete with no photos) when steps were nil — wrong. Fixed to refetch `loadTasks()` once and retry `handleTaskTap(loaded)`. `isLoadingCamera: Bool` state drives a spinner overlay during the brief refetch. Guard against re-entry prevents infinite loop if API consistently returns nil steps.

**Bug 2 — Timestamps 4 hours ahead:**
No code change needed. All `DateFormatter` instances in the codebase omit `.timeZone` (defaulting to `.current`). `ISO8601DateFormatter` is parse-only (UTC, correct). Zero UTC hardcoding in any display formatter — acceptance criteria satisfied as-is.

---

## cc-prompt-53 — Admin Delete User FK Violation

**Error:** `update or delete on table "users" violates foreign key constraint "user_organizations_user_id_fkey"` — bare `DELETE FROM users` with no child cleanup.

**Fix:** wrapped in explicit transaction (`pool.connect()` + `BEGIN/COMMIT/ROLLBACK`), child deletes before user delete:

```
reset_tokens (has user_id FK) → user_devices → user_app_roles → user_organizations → users
```

`invite_tokens` skipped — uses `email` column only, no `user_id` FK.

Final `DELETE FROM users WHERE id = $1 AND org_id = $2` (scoped to org — prevents cross-org deletion).

**Cognito delete** fires after DB commit; `UserNotFoundException` swallowed (expected for legacy imported accounts without Cognito identity).

**Audit log** written inside the transaction (SOC 2 CC6.1).

Added: `@aws-sdk/client-cognito-identity-provider` to `package.json`. `pool` added to `src/lib/db.js` destructure import.

Deploy pending MFA session renewal — zip at `/tmp/gt-deploy.zip`.

---

## Key File References
- `gunnerteam-api/src/routes/auth.js` — admin-delete handler (lines ~388–453)
- `GunnerForms/GunnerTeam/Forms/GuidedTasksView.swift` — InspectionCameraSession wiring, isLoadingCamera race fix
- `~/.omp/plugins/cache/marketplaces/claude-plugins-official/` — cached marketplace catalog
- `~/.zshrc` — `GITHUB_PERSONAL_ACCESS_TOKEN`
