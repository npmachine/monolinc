defmodule Monolinc.Messaging.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias Monolinc.Accounts.User
  alias Monolinc.Rooms.Room

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field :content, :string

    belongs_to :room, Room
    belongs_to :user, User

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content])
    |> validate_required([:content, :room_id, :user_id])
    |> validate_length(:content, max: 2000)
  end
end
