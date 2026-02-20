defmodule MonolincWeb.RoomLive.New do
  use MonolincWeb, :live_view

  alias Monolinc.Rooms
  alias Monolinc.Rooms.Room

  def mount(_params, _session, socket) do
    changeset = Room.changeset(%Room{}, %{})

    {:ok,
     socket
     |> assign(:page_title, "Create room")
     |> assign(:form, to_form(changeset, as: :room))}
  end

  def handle_event("save", %{"room" => room_params}, socket) do
    %{user: user} = socket.assigns.current_scope

    case Rooms.create_room(user, room_params) do
      {:ok, room} ->
        {:noreply, push_navigate(socket, to: "/rooms/#{room.slug}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :room, action: :insert))}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">
        <div>
          <h1 class="text-2xl font-semibold">Create room</h1>
          <p class="text-sm text-base-content/70">Start a new space for the conversation.</p>
        </div>

        <.form for={@form} id="room-create-form" phx-submit="save" class="space-y-4">
          <.input
            field={@form[:name]}
            type="text"
            label="Room name"
            placeholder="e.g. General"
            id="room-name-input"
            required
          />

          <.input
            field={@form[:description]}
            type="textarea"
            label="Description"
            placeholder="Optional"
            id="room-description-input"
            rows="3"
          />

          <div class="flex items-center gap-3">
            <button type="submit" class="btn btn-primary" id="room-submit">
              Create room
            </button>
            <.link navigate={~p"/rooms"} class="btn btn-ghost">Cancel</.link>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
