defmodule Monolinc.Rooms.Room do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "rooms" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :created_by, :binary_id

    timestamps()
  end

  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name, :slug, :description, :created_by])
    |> validate_required([:name, :slug, :created_by])
    |> validate_length(:name, max: 100)
    |> validate_length(:description, max: 500)
    |> unique_constraint(:slug)
  end
end
