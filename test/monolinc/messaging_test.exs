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

    timestamps = Enum.map(messages, & &1.inserted_at)
    assert timestamps == Enum.sort(timestamps, {:desc, NaiveDateTime})
  end
end
