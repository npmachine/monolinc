# Chat MVP Phase 1 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Establish the Phoenix/SQLite/auth/routing foundation required for the chat MVP.

**Architecture:** Use Phoenix 1.8 + LiveView with `phx.gen.auth` for session auth. Keep the root route as a redirect into either `/rooms` or `/users/log_in`, and standardize UUID primary keys for new schemas.

**Tech Stack:** Elixir, Phoenix 1.8, Phoenix LiveView, Ecto + SQLite (ecto_sqlite3), Tailwind

---

### Task 1: Align generators with UUID primary keys

**Files:**
- Modify: `config/config.exs`

**Step 1: Write the failing test**
- Skip (generator config change; no direct unit tests)

**Step 2: Run test to verify it fails**
- Skip

**Step 3: Write minimal implementation**
- Update `config :monolinc, generators` to include `binary_id: true` alongside `timestamp_type: :utc_datetime`.

```elixir
config :monolinc,
  ecto_repos: [Monolinc.Repo],
  generators: [binary_id: true, timestamp_type: :utc_datetime]
```

**Step 4: Run test to verify it passes**
- Skip

**Step 5: Commit**
```bash
git add config/config.exs
git commit -m "chore: default generators to uuid ids"
```

### Task 2: Generate authentication scaffolding

**Files:**
- Create: `lib/monolinc/accounts/user.ex`
- Create: `lib/monolinc/accounts/user_token.ex`
- Create: `lib/monolinc/accounts/accounts.ex`
- Create: `lib/monolinc_web/user_auth.ex`
- Create: `lib/monolinc_web/controllers/user_*_controller.ex`
- Create: `lib/monolinc_web/components/user_*` (LiveViews + HTML)
- Create: `priv/repo/migrations/*_create_users_auth_tables.exs`
- Modify: `lib/monolinc_web/router.ex`
- Modify: `lib/monolinc_web/components/layouts.ex` (if required by generator)

**Step 1: Write the failing test**
- Use the generated tests from `phx.gen.auth` (it generates failing tests before code is compiled).

**Step 2: Run test to verify it fails**
Run: `mix test test/monolinc_web/controllers/user_*_controller_test.exs`
Expected: FAIL until generator code is compiled and migrations run

**Step 3: Write minimal implementation**
Run the generator with binary IDs:
```bash
mix phx.gen.auth Accounts User users --binary-id
```

Then run migrations:
```bash
mix ecto.migrate
```

**Step 4: Run test to verify it passes**
Run: `mix test test/monolinc_web/controllers/user_*_controller_test.exs`
Expected: PASS

**Step 5: Commit**
```bash
git add lib priv test config
git commit -m "feat: add authentication scaffolding"
```

### Task 3: Base routing and root redirect

**Files:**
- Modify: `lib/monolinc_web/router.ex`
- Modify: `lib/monolinc_web/controllers/page_controller.ex`
- Modify: `lib/monolinc_web/controllers/page_html.ex`
- Modify/Delete: `lib/monolinc_web/controllers/page_html/*` (if no longer used)

**Step 1: Write the failing test**
Create a simple controller test to assert redirect behavior:
- Create: `test/monolinc_web/controllers/root_redirect_test.exs`

```elixir
defmodule MonolincWeb.RootRedirectTest do
  use MonolincWeb.ConnCase

  test "redirects unauthenticated users to login", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/users/log_in"
  end
end
```

**Step 2: Run test to verify it fails**
Run: `mix test test/monolinc_web/controllers/root_redirect_test.exs`
Expected: FAIL until root redirect is implemented

**Step 3: Write minimal implementation**
- Replace the root route to point to a controller action that redirects based on auth.
- Use `MonolincWeb.UserAuth` helpers to detect the current user (from `conn.assigns`).

**Step 4: Run test to verify it passes**
Run: `mix test test/monolinc_web/controllers/root_redirect_test.exs`
Expected: PASS

**Step 5: Commit**
```bash
git add lib test
git commit -m "feat: add root redirect for auth flow"
```

### Task 4: Verify and precommit

**Files:**
- None

**Step 1: Run full test suite**
Run: `mix test`
Expected: PASS

**Step 2: Run precommit**
Run: `mix precommit`
Expected: PASS

**Step 3: Commit**
- Skip (already committed per-task)

---

Plan complete and saved to `docs/plans/2026-02-19-chat-mvp-phase-1.md`.

Two execution options:
1. Subagent-Driven (this session) - I dispatch fresh subagent per task, review between tasks, fast iteration
2. Parallel Session (separate) - Open new session with executing-plans, batch execution with checkpoints

Which approach?
