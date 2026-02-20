defmodule Monolinc.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :string
      add :created_by, references(:users, type: :binary_id), null: false

      timestamps()
    end

    create unique_index(:rooms, [:slug])
  end
end
