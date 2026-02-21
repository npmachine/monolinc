defmodule MonolincWeb.UserSocketTest do
  use MonolincWeb.ChannelCase

  alias Monolinc.Accounts
  alias Monolinc.AccountsFixtures

  test "connect/3 authenticates with a valid session token" do
    user = AccountsFixtures.user_fixture()
    token = Accounts.generate_user_session_token(user)

    assert {:ok, socket} =
             connect(MonolincWeb.UserSocket, %{},
               connect_info: %{session: %{"user_token" => token}}
             )

    assert socket.assigns.current_scope.user.id == user.id
  end

  test "connect/3 rejects missing session token" do
    assert :error = connect(MonolincWeb.UserSocket, %{}, connect_info: %{session: %{}})
  end

  test "connect/3 rejects invalid session token" do
    assert :error =
             connect(MonolincWeb.UserSocket, %{},
               connect_info: %{session: %{"user_token" => "invalid"}}
             )
  end
end
