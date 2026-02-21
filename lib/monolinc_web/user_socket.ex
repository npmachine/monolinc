defmodule MonolincWeb.UserSocket do
  use Phoenix.Socket

  alias Monolinc.Accounts
  alias Monolinc.Accounts.Scope

  channel "room:*", MonolincWeb.RoomChannel

  @impl true
  def connect(_params, socket, %{session: %{"user_token" => token}}) do
    case Accounts.get_user_by_session_token(token) do
      {user, _token_inserted_at} ->
        {:ok, assign(socket, :current_scope, Scope.for_user(user))}

      nil ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(_socket), do: nil
end
