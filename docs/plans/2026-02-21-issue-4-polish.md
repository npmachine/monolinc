# Issue 4 Polish Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Complete GitHub issue #4 by implementing polish-only scope: robust room UX error handling and a focused Tailwind styling pass.

**Architecture:** Keep authenticated LiveView routes in the existing `live_session :require_authenticated_user` scope in `lib/monolinc_web/router.ex`, because room pages require `@current_scope` and must remain behind auth. Improve `RoomLive.Show` to handle missing room/disconnect-related UX safely, then apply a cohesive UI polish across rooms screens and layout primitives while preserving LiveView IDs used by tests.

**Tech Stack:** Elixir, Phoenix 1.8, Phoenix LiveView, Tailwind CSS v4, DaisyUI

---

### Task 1: Missing-room and resilient chat error handling

**Files:**
- Modify: `lib/monolinc_web/live/room_live/show.ex`
- Test: `test/monolinc_web/live/room_live/show_test.exs`

**Step 1: Write failing tests**
Add tests for:
- invalid room slug redirects/navigates user to `/rooms` with an error flash
- chat send event handles unavailable room state without crashing LiveView

**Step 2: Run tests to confirm failure**
Run: `mix test test/monolinc_web/live/room_live/show_test.exs`
Expected: FAIL for new error-handling expectations

**Step 3: Implement minimal fix in LiveView**
- Replace bang lookup path with safe lookup for slug in `mount/3`
- On missing room, set error flash and navigate to rooms index
- Guard send path to return a friendly error state instead of raising when room context is invalid

**Step 4: Re-run target test file**
Run: `mix test test/monolinc_web/live/room_live/show_test.exs`
Expected: PASS

**Step 5: Commit**
```bash
git add lib/monolinc_web/live/room_live/show.ex test/monolinc_web/live/room_live/show_test.exs
git commit -m "fix: improve room live error handling"
```

### Task 2: Connection-state UX polish in chat screen

**Files:**
- Modify: `lib/monolinc_web/live/room_live/show.ex`
- Test: `test/monolinc_web/live/room_live/show_test.exs`

**Step 1: Write failing test for connection-state affordances**
Add assertions for persistent, testable elements indicating reconnect/disconnect support (`#server-error`, `#client-error`, or chat-level status container IDs).

**Step 2: Run test to confirm failure**
Run: `mix test test/monolinc_web/live/room_live/show_test.exs`
Expected: FAIL on new selector assertions

**Step 3: Implement minimal UX updates**
- Add clear status copy and visual cues around message composer for transient connection issues
- Ensure existing `Layouts.app` flash group behavior remains intact and no duplicate flash group is introduced

**Step 4: Re-run target tests**
Run: `mix test test/monolinc_web/live/room_live/show_test.exs`
Expected: PASS

**Step 5: Commit**
```bash
git add lib/monolinc_web/live/room_live/show.ex test/monolinc_web/live/room_live/show_test.exs
git commit -m "feat: polish chat connection-state UX"
```

### Task 3: Tailwind styling pass for room index/new/show

**Files:**
- Modify: `lib/monolinc_web/live/room_live/index.ex`
- Modify: `lib/monolinc_web/live/room_live/new.ex`
- Modify: `lib/monolinc_web/live/room_live/show.ex`
- Modify: `assets/css/app.css`
- Test: `test/monolinc_web/live/room_live/index_test.exs`
- Test: `test/monolinc_web/live/room_live/new_test.exs`
- Test: `test/monolinc_web/live/room_live/show_test.exs`

**Step 1: Write failing tests for key polished containers**
Add selector-based assertions (not text-coupled) for stable shells and controls on each page:
- rooms index wrapper + create CTA
- new room form shell + submit/cancel actions
- chat header/messages/composer panel wrappers

**Step 2: Run focused tests to confirm failure**
Run: `mix test test/monolinc_web/live/room_live/index_test.exs test/monolinc_web/live/room_live/new_test.exs test/monolinc_web/live/room_live/show_test.exs`
Expected: FAIL on new selectors

**Step 3: Implement styling pass**
- Improve hierarchy, spacing, and surfaces with Tailwind utility classes
- Add subtle interaction states (`hover`, `focus-visible`, `transition`) on primary controls
- Keep existing IDs used by tests and LiveView stream containers unchanged

**Step 4: Re-run focused tests**
Run: same command as Step 2
Expected: PASS

**Step 5: Commit**
```bash
git add lib/monolinc_web/live/room_live/index.ex lib/monolinc_web/live/room_live/new.ex lib/monolinc_web/live/room_live/show.ex assets/css/app.css test/monolinc_web/live/room_live/index_test.exs test/monolinc_web/live/room_live/new_test.exs test/monolinc_web/live/room_live/show_test.exs
git commit -m "feat: polish room liveview styling"
```

### Task 4: Layout polish and template compliance cleanup

**Files:**
- Modify: `lib/monolinc_web/components/layouts.ex`
- Modify: `lib/monolinc_web/components/layouts/root.html.heex`
- Modify: `assets/js/app.js`
- Test: `test/monolinc_web/live/room_live/index_test.exs`

**Step 1: Write failing test for layout-level nav shell element**
Add selector assertion for a stable app-shell element rendered through `Layouts.app`.

**Step 2: Run target test to confirm failure**
Run: `mix test test/monolinc_web/live/room_live/index_test.exs`
Expected: FAIL for new app-shell selector

**Step 3: Implement minimal compliant layout updates**
- Polish navigation/header structure in `Layouts.app` while preserving auth-aware controls
- Move inline script from `root.html.heex` into `assets/js/app.js` to comply with no-inline-script rule
- Keep bundle constraints intact (only `app.js`/`app.css`)

**Step 4: Re-run tests**
Run: `mix test test/monolinc_web/live/room_live/index_test.exs test/monolinc_web/live/room_live/new_test.exs test/monolinc_web/live/room_live/show_test.exs`
Expected: PASS

**Step 5: Commit**
```bash
git add lib/monolinc_web/components/layouts.ex lib/monolinc_web/components/layouts/root.html.heex assets/js/app.js test/monolinc_web/live/room_live/index_test.exs test/monolinc_web/live/room_live/new_test.exs test/monolinc_web/live/room_live/show_test.exs
git commit -m "refactor: polish app layout and move inline theme script"
```

### Task 5: Final verification for Issue #4 (polish only)

**Files:**
- No new files

**Step 1: Run all room/live tests**
Run: `mix test test/monolinc_web/live/room_live/index_test.exs test/monolinc_web/live/room_live/new_test.exs test/monolinc_web/live/room_live/show_test.exs`
Expected: PASS

**Step 2: Run full project gate**
Run: `mix precommit`
Expected: PASS (`compile --warning-as-errors`, format, tests)

**Step 3: Confirm clean git state**
Run: `git status --short`
Expected: clean working tree
