defmodule MonolincWeb.RoomChannelTest do
  use MonolincWeb.ChannelCase

  alias Monolinc.Accounts
  alias Monolinc.AccountsFixtures
  alias Monolinc.Rooms

  test "broadcasts new messages to room topic" do
    user = AccountsFixtures.user_fixture()
    token = Accounts.generate_user_session_token(user)
    {:ok, room} = Rooms.create_room(user, %{name: "General"})

    {:ok, socket} =
      connect(MonolincWeb.UserSocket, %{}, connect_info: %{session: %{"user_token" => token}})

    {:ok, _, socket} =
      socket
      |> subscribe_and_join(MonolincWeb.RoomChannel, "room:#{room.id}")

    push(socket, "new_message", %{"content" => "hi"})
    assert_broadcast "new_message", %{content: "hi"}
  end
end
