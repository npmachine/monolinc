defmodule Monolinc.Messaging do
  import Ecto.Query, warn: false

  alias Monolinc.Messaging.Message
  alias Monolinc.Repo

  def create_message(user, room, attrs) do
    attrs = Map.new(attrs)

    %Message{room_id: room.id, user_id: user.id}
    |> Message.changeset(%{content: attrs["content"] || attrs[:content]})
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
