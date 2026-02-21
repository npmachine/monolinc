defmodule MonolincWeb.RoomChannel do
  use MonolincWeb, :channel

  alias Monolinc.Messaging
  alias Monolinc.Rooms

  @impl true
  def join("room:" <> room_id, _payload, socket) do
    {:ok, assign(socket, :room_id, room_id)}
  end

  @impl true
  def handle_in("new_message", %{"content" => content}, socket) do
    user = socket.assigns.current_scope.user
    room = Rooms.get_room!(socket.assigns.room_id)

    case Messaging.create_message(user, room, %{content: content}) do
      {:ok, message} ->
        broadcast!(socket, "new_message", %{
          id: message.id,
          content: message.content,
          user_email: message.user.email,
          inserted_at: message.inserted_at
        })

        {:noreply, socket}

      {:error, _changeset} ->
        {:reply, {:error, %{error: "invalid"}}, socket}
    end
  end
end
