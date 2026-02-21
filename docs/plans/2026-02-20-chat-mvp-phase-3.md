# Chat MVP Phase 3 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement real-time messaging with a message schema, channel-based broadcast, and a chat room LiveView that loads recent messages and sends new ones.

**Architecture:** Add a `Messaging` context with `Message` schema (UUID IDs), validate content length, and preload user associations. Implement a `RoomChannel` that broadcasts messages on `room:{room_id}`. The Room LiveView subscribes to the same topic to receive broadcasts, streams messages for performance, and renders a chat UI under authenticated routes.

**Tech Stack:** Elixir, Phoenix 1.8, Phoenix LiveView, Phoenix Channels, Ecto + SQLite, Tailwind

---

### Task 1: Message schema + migration

**Files:**
- Create: `lib/monolinc/messaging/message.ex`
- Create: `priv/repo/migrations/*_create_messages.exs`
- Test: `test/monolinc/messaging/message_test.exs`

**Step 1: Write the failing test**
```elixir
defmodule Monolinc.Messaging.MessageTest do
  use Monolinc.DataCase

  alias Monolinc.Messaging.Message

  test "changeset requires content" do
    changeset = Message.changeset(%Message{}, %{content: ""})
    refute changeset.valid?
    assert "can't be blank" in errors_on(changeset).content
  end

  test "changeset enforces max length" do
    changeset = Message.changeset(%Message{}, %{content: String.duplicate("a", 2001)})
    refute changeset.valid?
    assert "should be at most 2000 character(s)" in errors_on(changeset).content
  end
end
```

**Step 2: Run test to verify it fails**
Run: `mix test test/monolinc/messaging/message_test.exs`
Expected: FAIL (module missing)

**Step 3: Write minimal implementation**
Create schema:
```elixir
defmodule Monolinc.Messaging.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field :content, :string
    belongs_to :room, Monolinc.Rooms.Room
    belongs_to :user, Monolinc.Accounts.User

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :room_id, :user_id])
    |> validate_required([:content, :room_id, :user_id])
    |> validate_length(:content, max: 2000)
  end
end
```

Migration:
```elixir
def change do
  create table(:messages, primary_key: false) do
    add :id, :binary_id, primary_key: true
    add :content, :string, null: false
    add :room_id, references(:rooms, type: :binary_id, on_delete: :delete_all), null: false
    add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

    timestamps()
  end

  create index(:messages, [:room_id])
  create index(:messages, [:user_id])
end
```

**Step 4: Run test to verify it passes**
Run: `mix test test/monolinc/messaging/message_test.exs`
Expected: PASS

**Step 5: Commit**
```bash
git add lib/monolinc/messaging/message.ex priv/repo/migrations/*_create_messages.exs test/monolinc/messaging/message_test.exs
git commit -m "feat: add messages schema"
```

### Task 2: Messaging context

**Files:**
- Create: `lib/monolinc/messaging.ex`
- Test: `test/monolinc/messaging_test.exs`

**Step 1: Write the failing test**
```elixir
defmodule Monolinc.MessagingTest do
  use Monolinc.DataCase

  alias Monolinc.Messaging
  alias Monolinc.Rooms

  test "create_message/3 persists and preloads user" do
    user = Monolinc.AccountsFixtures.user_fixture()
    {:ok, room} = Rooms.create_room(user, %{name: "General"})

    {:ok, message} = Messaging.create_message(user, room, %{content: "hello"})
    assert message.content == "hello"
    assert message.user.id == user.id
  end

  test "list_recent_messages/2 returns newest first, limited" do
    user = Monolinc.AccountsFixtures.user_fixture()
    {:ok, room} = Rooms.create_room(user, %{name: "General"})

    Enum.each(1..55, fn i ->
      {:ok, _msg} = Messaging.create_message(user, room, %{content: "msg-#{i}"})
    end)

    messages = Messaging.list_recent_messages(room, 50)
    assert length(messages) == 50
    assert hd(messages).content == "msg-55"
  end
end
```

**Step 2: Run test to verify it fails**
Run: `mix test test/monolinc/messaging_test.exs`
Expected: FAIL

**Step 3: Write minimal implementation**
```elixir
defmodule Monolinc.Messaging do
  import Ecto.Query, warn: false

  alias Monolinc.Repo
  alias Monolinc.Messaging.Message

  def create_message(user, room, attrs) do
    attrs = Map.new(attrs)

    %Message{}
    |> Message.changeset(%{
      content: attrs["content"] || attrs[:content],
      room_id: room.id,
      user_id: user.id
    })
    |> Repo.insert()
    |> case do
      {:ok, message} -> {:ok, Repo.preload(message, :user)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def list_recent_messages(room, limit \\ 50) do
    Message
    |> where([m], m.room_id == ^room.id)
    |> order_by([m], desc: m.inserted_at)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload(:user)
  end
end
```

**Step 4: Run test to verify it passes**
Run: `mix test test/monolinc/messaging_test.exs`
Expected: PASS

**Step 5: Commit**
```bash
git add lib/monolinc/messaging.ex test/monolinc/messaging_test.exs
git commit -m "feat: add messaging context"
```

### Task 3: Room channel

**Files:**
- Create: `lib/monolinc_web/channels/room_channel.ex`
- Modify: `lib/monolinc_web/endpoint.ex` (if needed to add socket)
- Modify: `lib/monolinc_web/user_socket.ex` (if missing)
- Test: `test/monolinc_web/channels/room_channel_test.exs`

**Step 1: Write the failing test**
```elixir
defmodule MonolincWeb.RoomChannelTest do
  use MonolincWeb.ChannelCase

  alias Monolinc.Messaging
  alias Monolinc.Rooms

  test "broadcasts new messages to room topic" do
    user = Monolinc.AccountsFixtures.user_fixture()
    {:ok, room} = Rooms.create_room(user, %{name: "General"})

    {:ok, _, socket} =
      MonolincWeb.UserSocket
      |> socket("user_id", %{current_scope: Monolinc.Accounts.Scope.for_user(user)})
      |> subscribe_and_join(MonolincWeb.RoomChannel, "room:#{room.id}")

    push(socket, "new_message", %{"content" => "hi"})
    assert_broadcast "new_message", %{content: "hi"}
  end
end
```

**Step 2: Run test to verify it fails**
Run: `mix test test/monolinc_web/channels/room_channel_test.exs`
Expected: FAIL

**Step 3: Write minimal implementation**
Implement channel:
```elixir
defmodule MonolincWeb.RoomChannel do
  use MonolincWeb, :channel

  alias Monolinc.Messaging
  alias Monolinc.Rooms

  def join("room:" <> room_id, _payload, socket) do
    {:ok, assign(socket, :room_id, room_id)}
  end

  def handle_in("new_message", %{"content" => content}, socket) do
    user = socket.assigns.current_scope.user
    room = Rooms.get_room!(socket.assigns.room_id)

    case Messaging.create_message(user, room, %{content: content}) do
      {:ok, message} ->
        broadcast!(socket, "new_message", %{
          id: message.id,
          content: message.content,
          username: message.user.username,
          inserted_at: message.inserted_at
        })

        {:noreply, socket}

      {:error, _changeset} ->
        {:reply, {:error, %{error: "invalid"}}, socket}
    end
  end
end
```

Add to user socket / endpoint if needed.

**Step 4: Run test to verify it passes**
Run: `mix test test/monolinc_web/channels/room_channel_test.exs`
Expected: PASS

**Step 5: Commit**
```bash
git add lib/monolinc_web/channels/room_channel.ex lib/monolinc_web/user_socket.ex lib/monolinc_web/endpoint.ex test/monolinc_web/channels/room_channel_test.exs
git commit -m "feat: add room channel"
```

### Task 4: Room LiveView (chat)

**Files:**
- Create: `lib/monolinc_web/live/room_live/show.ex`
- Modify: `lib/monolinc_web/router.ex`
- Test: `test/monolinc_web/live/room_live/show_test.exs`

**Step 1: Write the failing test**
```elixir
defmodule MonolincWeb.RoomLive.ShowTest do
  use MonolincWeb.ConnCase

  import Phoenix.LiveViewTest

  test "shows recent messages", %{conn: conn} do
    %{conn: conn, user: user} = register_and_log_in_user(%{conn: conn})
    {:ok, room} = Monolinc.Rooms.create_room(user, %{name: "General"})
    {:ok, _} = Monolinc.Messaging.create_message(user, room, %{content: "hello"})

    {:ok, view, _html} = live(conn, ~p"/rooms/#{room.slug}")
    assert has_element?(view, "#messages")
    assert has_element?(view, "#message-input")
    assert has_element?(view, "#message-submit")
  end

  test "sends message and renders it", %{conn: conn} do
    %{conn: conn, user: user} = register_and_log_in_user(%{conn: conn})
    {:ok, room} = Monolinc.Rooms.create_room(user, %{name: "General"})

    {:ok, view, _html} = live(conn, ~p"/rooms/#{room.slug}")

    view
    |> form("#message-form", %{"message" => %{"content" => "hey"}})
    |> render_submit()

    assert has_element?(view, "#messages", "hey")
  end
end
```

**Step 2: Run test to verify it fails**
Run: `mix test test/monolinc_web/live/room_live/show_test.exs`
Expected: FAIL

**Step 3: Write minimal implementation**
- Load room by slug, 404 if not found.
- Subscribe to topic `room:{room.id}` via `MonolincWeb.Endpoint.subscribe/1`.
- Stream recent 50 messages (use `Messaging.list_recent_messages/2`).
- On "send" event, create message and broadcast via `Endpoint.broadcast/3` to the same topic.
- Render with `<Layouts.app flash={@flash} current_scope={@current_scope}>`.
- Use streams for messages with `phx-update="stream"` and IDs on children.

**Step 4: Run test to verify it passes**
Run: `mix test test/monolinc_web/live/room_live/show_test.exs`
Expected: PASS

**Step 5: Commit**
```bash
git add lib/monolinc_web/live/room_live/show.ex lib/monolinc_web/router.ex test/monolinc_web/live/room_live/show_test.exs
git commit -m "feat: add chat room liveview"
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

Plan complete and saved to `docs/plans/2026-02-20-chat-mvp-phase-3.md`.

Two execution options:
1. Subagent-Driven (this session) - I dispatch fresh subagent per task, review between tasks, fast iteration
2. Parallel Session (separate) - Open new session with executing-plans, batch execution with checkpoints

Which approach?
