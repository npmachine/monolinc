# Chat MVP Phase 2 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement rooms (schema, context, list, create) with strict auto-slugging and collision handling.

**Architecture:** Add `Rooms` context with `Room` schema. Auto-generate slug from name in changeset and retry inserts on slug collisions. Provide LiveViews for list and create, behind authenticated routes.

**Tech Stack:** Elixir, Phoenix 1.8, Phoenix LiveView, Ecto + SQLite, Tailwind

---

### Task 1: Add Room schema + migration

**Files:**
- Create: `lib/monolinc/rooms/room.ex`
- Create: `priv/repo/migrations/*_create_rooms.exs`

**Step 1: Write the failing test**
Create schema changeset tests.

Create: `test/monolinc/rooms/room_test.exs`
```elixir
defmodule Monolinc.Rooms.RoomTest do
  use Monolinc.DataCase

  alias Monolinc.Rooms.Room

  test "changeset requires name" do
    changeset = Room.changeset(%Room{}, %{name: ""})
    refute changeset.valid?
    assert "can't be blank" in errors_on(changeset).name
  end
end
```

**Step 2: Run test to verify it fails**
Run: `mix test test/monolinc/rooms/room_test.exs`
Expected: FAIL (Room module missing)

**Step 3: Write minimal implementation**
Create `Room` schema with fields:
```elixir
defmodule Monolinc.Rooms.Room do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "rooms" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :created_by, :binary_id

    timestamps()
  end

  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name, :slug, :description, :created_by])
    |> validate_required([:name, :slug, :created_by])
  end
end
```

Migration (rooms table, unique index on slug):
```elixir
def change do
  create table(:rooms, primary_key: false) do
    add :id, :binary_id, primary_key: true
    add :name, :string, null: false
    add :slug, :string, null: false
    add :description, :string
    add :created_by, references(:users, type: :binary_id), null: false

    timestamps()
  end

  create unique_index(:rooms, [:slug])
end
```

**Step 4: Run test to verify it passes**
Run: `mix test test/monolinc/rooms/room_test.exs`
Expected: PASS

**Step 5: Commit**
```bash
git add lib/monolinc/rooms/room.ex priv/repo/migrations/*_create_rooms.exs test/monolinc/rooms/room_test.exs
git commit -m "feat: add rooms schema"
```

### Task 2: Rooms context + slugging + collision handling

**Files:**
- Create: `lib/monolinc/rooms.ex`
- Modify: `lib/monolinc/rooms/room.ex`
- Create: `test/monolinc/rooms_test.exs`

**Step 1: Write the failing test**
Create context tests:
```elixir
defmodule Monolinc.RoomsTest do
  use Monolinc.DataCase

  alias Monolinc.Rooms

  test "create_room/2 generates a strict slug" do
    user = Monolinc.AccountsFixtures.user_fixture()
    {:ok, room} = Rooms.create_room(user, %{name: "Hello World", description: "Test"})
    assert room.slug == "hello-world"
  end

  test "create_room/2 appends suffix on slug collision" do
    user = Monolinc.AccountsFixtures.user_fixture()
    {:ok, room1} = Rooms.create_room(user, %{name: "General"})
    {:ok, room2} = Rooms.create_room(user, %{name: "General"})
    assert room1.slug != room2.slug
    assert String.starts_with?(room2.slug, "general-")
  end

  test "create_room/2 errors when slug would be empty" do
    user = Monolinc.AccountsFixtures.user_fixture()
    assert {:error, changeset} = Rooms.create_room(user, %{name: "!!!"})
    assert "must include letters or numbers" in errors_on(changeset).slug
  end
end
```

**Step 2: Run test to verify it fails**
Run: `mix test test/monolinc/rooms_test.exs`
Expected: FAIL (Rooms context missing)

**Step 3: Write minimal implementation**
Implement `Rooms.create_room/2` with retry on unique slug constraint:
```elixir
defmodule Monolinc.Rooms do
  import Ecto.Query, warn: false
  alias Monolinc.Repo
  alias Monolinc.Rooms.Room

  def list_rooms do
    Repo.all(from r in Room, order_by: [desc: r.inserted_at])
  end

  def create_room(user, attrs) do
    base_slug = normalize_slug(attrs["name"] || attrs[:name] || "")

    attrs =
      attrs
      |> Map.new()
      |> Map.put("slug", base_slug)
      |> Map.put("created_by", user.id)

    do_insert_with_slug(attrs, 0)
  end

  defp do_insert_with_slug(attrs, attempt) when attempt < 3 do
    changeset = Room.changeset(%Room{}, attrs)

    case Repo.insert(changeset) do
      {:ok, room} ->
        {:ok, room}

      {:error, changeset} ->
        if slug_collision?(changeset) do
          suffix = random_suffix()
          base = attrs["slug"]
          new_slug = "#{base}-#{suffix}"
          do_insert_with_slug(Map.put(attrs, "slug", new_slug), attempt + 1)
        else
          {:error, changeset}
        end
    end
  end

  defp do_insert_with_slug(attrs, _attempt) do
    {:error, Room.changeset(%Room{}, attrs) |> Ecto.Changeset.add_error(:slug, "is already taken")}
  end

  defp slug_collision?(changeset) do
    Enum.any?(changeset.errors, fn {field, {_, opts}} ->
      field == :slug && opts[:constraint] == :unique
    end)
  end

  defp normalize_slug(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.replace(~r/^-+|-+$/u, "")
    |> case do
      "" -> ""
      slug -> slug
    end
  end

  defp random_suffix do
    Ecto.UUID.generate() |> String.replace("-", "") |> String.slice(0, 8)
  end
end
```

Update `Room.changeset/2` to:
- cast `:name`, `:description`
- compute and validate slug (error when empty)
- unique constraint on slug

**Step 4: Run test to verify it passes**
Run: `mix test test/monolinc/rooms_test.exs`
Expected: PASS

**Step 5: Commit**
```bash
git add lib/monolinc/rooms.ex lib/monolinc/rooms/room.ex test/monolinc/rooms_test.exs
git commit -m "feat: add rooms context with slug generation"
```

### Task 3: Rooms LiveViews + routing

**Files:**
- Create: `lib/monolinc_web/live/room_live/index.ex`
- Create: `lib/monolinc_web/live/room_live/new.ex`
- Modify: `lib/monolinc_web/router.ex`
- Create: `test/monolinc_web/live/room_live/index_test.exs`
- Create: `test/monolinc_web/live/room_live/new_test.exs`

**Step 1: Write the failing tests**
Index test:
```elixir
defmodule MonolincWeb.RoomLive.IndexTest do
  use MonolincWeb.ConnCase
  import Phoenix.LiveViewTest

  test "redirects unauthenticated users", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/rooms")
  end

  test "lists rooms for authenticated users", %{conn: conn} do
    %{conn: conn} = register_and_log_in_user(%{conn: conn})
    {:ok, _view, html} = live(conn, ~p"/rooms")
    assert html =~ "Rooms"
  end
end
```

New test:
```elixir
defmodule MonolincWeb.RoomLive.NewTest do
  use MonolincWeb.ConnCase
  import Phoenix.LiveViewTest

  test "renders create form", %{conn: conn} do
    %{conn: conn} = register_and_log_in_user(%{conn: conn})
    {:ok, _view, html} = live(conn, ~p"/rooms/new")
    assert html =~ "Create room"
  end
end
```

**Step 2: Run tests to verify they fail**
Run: `mix test test/monolinc_web/live/room_live/index_test.exs test/monolinc_web/live/room_live/new_test.exs`
Expected: FAIL (routes/views missing)

**Step 3: Write minimal implementation**
- Add authenticated `live_session` routes for rooms in router
- Create LiveViews (use `<Layouts.app flash={@flash} current_scope={@current_scope}>`)
- Index uses `Rooms.list_rooms/0` and renders list
- New uses `Rooms.create_room/2` on submit; redirect to `/rooms/:slug`
- Ensure form uses `to_form/2` and `<.input>` components

**Step 4: Run tests to verify they pass**
Run: `mix test test/monolinc_web/live/room_live/index_test.exs test/monolinc_web/live/room_live/new_test.exs`
Expected: PASS

**Step 5: Commit**
```bash
git add lib/monolinc_web/live/room_live/index.ex lib/monolinc_web/live/room_live/new.ex lib/monolinc_web/router.ex test/monolinc_web/live/room_live/*
git commit -m "feat: add rooms liveviews"
```

### Task 4: Rooms creation behavior tests

**Files:**
- Modify: `test/monolinc_web/live/room_live/new_test.exs`

**Step 1: Write the failing tests**
Add tests for creation + slug collision:
```elixir
test "creates a room and redirects", %{conn: conn} do
  %{conn: conn} = register_and_log_in_user(%{conn: conn})
  {:ok, view, _html} = live(conn, ~p"/rooms/new")

  form =
    form(view, "#room-create-form", %{
      "room" => %{"name" => "General", "description" => "Main"}
    })

  {:ok, _view, %{to: to}} = render_submit(form)
  assert to =~ "/rooms/general"
end

test "shows error when name normalizes to empty", %{conn: conn} do
  %{conn: conn} = register_and_log_in_user(%{conn: conn})
  {:ok, view, _html} = live(conn, ~p"/rooms/new")

  html =
    view
    |> form("#room-create-form", %{"room" => %{"name" => "!!!"}})
    |> render_submit()

  assert html =~ "must include letters or numbers"
end
```

**Step 2: Run tests to verify they fail**
Run: `mix test test/monolinc_web/live/room_live/new_test.exs`
Expected: FAIL

**Step 3: Write minimal implementation**
Ensure LiveView new handles validation and uses changeset errors from `Rooms.create_room/2`.

**Step 4: Run tests to verify they pass**
Run: `mix test test/monolinc_web/live/room_live/new_test.exs`
Expected: PASS

**Step 5: Commit**
```bash
git add test/monolinc_web/live/room_live/new_test.exs lib/monolinc_web/live/room_live/new.ex
git commit -m "test: cover room creation flows"
```

### Task 5: Verify and precommit

**Files:**
- None

**Step 1: Run full test suite**
Run: `mix test`
Expected: PASS

**Step 2: Run precommit**
Run: `mix precommit`
Expected: PASS

---

Plan complete and saved to `docs/plans/2026-02-20-chat-mvp-phase-2.md`.

Two execution options:
1. Subagent-Driven (this session) - I dispatch fresh subagent per task, review between tasks, fast iteration
2. Parallel Session (separate) - Open new session with executing-plans, batch execution with checkpoints

Which approach?
