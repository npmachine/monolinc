defmodule MonolincWeb.RoomLive.Show do
  use MonolincWeb, :live_view

  alias Monolinc.Messaging
  alias Monolinc.Rooms
  alias MonolincWeb.Endpoint

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case Rooms.get_room_by_slug(slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Room not found")
         |> push_navigate(to: ~p"/rooms")}

      room ->
        topic = "room:#{room.id}"

        if connected?(socket) do
          Endpoint.subscribe(topic)
        end

        messages =
          room
          |> Messaging.list_recent_messages(50)
          |> Enum.reverse()
          |> Enum.map(&message_to_view/1)

        {:ok,
         socket
         |> assign(:page_title, room.name)
         |> assign(:room, room)
         |> assign(:room_topic, topic)
         |> assign(:form, to_form(%{"content" => ""}, as: :message))
         |> stream(:messages, messages)}
    end
  end

  @impl true
  def handle_event("send", %{"message" => %{"content" => content}}, socket) do
    user = socket.assigns.current_scope.user
    room = socket.assigns.room

    case Messaging.create_message(user, room, %{content: content}) do
      {:ok, message} ->
        Endpoint.broadcast(socket.assigns.room_topic, "new_message", message_to_view(message))

        {:noreply, assign(socket, :form, to_form(%{"content" => ""}, as: :message))}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :message, action: :insert))}
    end
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "new_message", payload: payload}, socket) do
    {:noreply, stream_insert(socket, :messages, payload, at: -1)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section
        id="room-chat-shell"
        class="rounded-2xl border border-base-300/70 bg-base-100/70 p-6 shadow-sm"
      >
        <div id="room-chat" class="space-y-6">
          <div class="space-y-1">
            <h1 class="text-2xl font-semibold tracking-tight">{@room.name}</h1>
            <p class="text-sm text-base-content/70">Real-time room chat.</p>
          </div>

          <div id="messages" phx-update="stream" class="space-y-3">
            <div
              id="messages-empty"
              class="hidden only:block rounded-lg border border-dashed border-base-300 p-4 text-sm text-base-content/60"
            >
              No messages yet.
            </div>
            <article
              :for={{id, message} <- @streams.messages}
              id={id}
              class="rounded-xl border border-base-300 bg-base-100 p-3 transition-colors duration-200 hover:border-primary/40"
            >
              <div class="flex items-center justify-between gap-2">
                <p class="text-xs font-medium text-base-content/70">{message.user_email}</p>
                <p class="text-xs text-base-content/50">{format_time(message.inserted_at)}</p>
              </div>
              <p class="mt-1 whitespace-pre-wrap break-words text-sm text-base-content">
                {message.content}
              </p>
            </article>
          </div>

          <div
            id="chat-connection-status"
            class="hidden rounded-lg border border-warning/30 bg-warning/10 px-3 py-2 text-xs text-warning"
            phx-disconnected={JS.remove_class("hidden")}
            phx-connected={JS.add_class("hidden")}
          >
            Connection lost. Reconnecting...
          </div>

          <.form for={@form} id="message-form" phx-submit="send" class="flex items-start gap-2">
            <div class="flex-1">
              <.input
                field={@form[:content]}
                type="text"
                id="message-input"
                placeholder="Type your message"
                autocomplete="off"
                required
              />
            </div>
            <button
              type="submit"
              id="message-submit"
              class="btn btn-primary transition-all duration-200 hover:-translate-y-0.5 hover:shadow-md"
            >
              Send
            </button>
          </.form>
        </div>
      </section>
    </Layouts.app>
    """
  end

  defp message_to_view(message) do
    %{
      id: message.id,
      content: message.content,
      user_email: message.user.email,
      inserted_at: message.inserted_at
    }
  end

  defp format_time(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M")
  defp format_time(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M")
end
