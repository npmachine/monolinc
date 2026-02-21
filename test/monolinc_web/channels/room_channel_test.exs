defmodule MonolincWeb.RoomChannelTest do
  use MonolincWeb.ChannelCase

  alias Monolinc.Accounts.Scope
  alias Monolinc.AccountsFixtures
  alias Monolinc.Rooms

  test "broadcasts new messages to room topic" do
    user = AccountsFixtures.user_fixture()
    {:ok, room} = Rooms.create_room(user, %{name: "General"})

    {:ok, _, socket} =
      MonolincWeb.UserSocket
      |> socket("user_id", %{current_scope: Scope.for_user(user)})
      |> subscribe_and_join(MonolincWeb.RoomChannel, "room:#{room.id}")

    push(socket, "new_message", %{"content" => "hi"})
    assert_broadcast "new_message", %{content: "hi"}
  end
end
