defmodule MonolincWeb.RoomLive.Index do
  use MonolincWeb, :live_view

  alias Monolinc.Rooms

  def mount(_params, _session, socket) do
    rooms = Rooms.list_rooms()

    {:ok,
     socket
     |> assign(:page_title, "Rooms")
     |> stream(:rooms, rooms)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section
        id="rooms-page-shell"
        class="rounded-2xl border border-base-300/70 bg-base-100/70 p-6 shadow-sm"
      >
        <div id="rooms-index" class="space-y-6">
          <div class="flex items-center justify-between">
            <div>
              <h1 class="text-2xl font-semibold tracking-tight">Rooms</h1>
              <p class="text-sm text-base-content/70">Join a room to start chatting.</p>
            </div>
            <.link
              navigate={~p"/rooms/new"}
              class="btn btn-primary transition-all duration-200 hover:-translate-y-0.5 hover:shadow-md"
              id="rooms-create-link"
            >
              Create room
            </.link>
          </div>

          <div id="rooms" phx-update="stream" class="space-y-3">
            <div id="rooms-empty" class="hidden only:block text-sm text-base-content/60">
              No rooms yet.
            </div>
            <div
              :for={{id, room} <- @streams.rooms}
              id={id}
              class="rounded-xl border border-base-300 bg-base-100 p-4 transition-colors duration-200 hover:border-primary/40"
            >
              <div class="flex items-start justify-between gap-4">
                <div>
                  <.link
                    navigate={"/rooms/#{room.slug}"}
                    class="font-medium text-base-content transition-colors duration-200 hover:text-primary"
                  >
                    {room.name}
                  </.link>
                  <p class="text-sm text-base-content/70">{room.description}</p>
                </div>
                <div class="text-xs text-base-content/50">Online: 0</div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </Layouts.app>
    """
  end
end
