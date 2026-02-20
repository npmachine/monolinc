defmodule Monolinc.Rooms do
  import Ecto.Query, warn: false

  alias Monolinc.Repo
  alias Monolinc.Rooms.Room

  def list_rooms do
    Repo.all(from r in Room, order_by: [desc: r.inserted_at])
  end

  def create_room(user, attrs) do
    attrs = stringify_keys(attrs)
    name = Map.get(attrs, "name") || ""
    base_slug = normalize_slug(name)

    attrs =
      attrs
      |> Map.put("slug", base_slug)
      |> Map.put("created_by", user.id)

    if base_slug == "" do
      {:error,
       Room.changeset(%Room{}, attrs)
       |> Ecto.Changeset.add_error(:slug, "must include letters or numbers")
       |> Ecto.Changeset.add_error(:name, "must include letters or numbers")}
    else
      do_insert_with_slug(attrs, 0)
    end
  end

  defp do_insert_with_slug(attrs, attempt) when attempt < 3 do
    changeset = Room.changeset(%Room{}, attrs)

    case Repo.insert(changeset) do
      {:ok, room} ->
        {:ok, room}

      {:error, changeset} ->
        if slug_collision?(changeset) do
          suffix = random_suffix()
          base = attrs["slug"]
          new_slug = "#{base}-#{suffix}"
          do_insert_with_slug(Map.put(attrs, "slug", new_slug), attempt + 1)
        else
          {:error, changeset}
        end
    end
  end

  defp do_insert_with_slug(attrs, _attempt) do
    {:error, Room.changeset(%Room{}, attrs) |> Ecto.Changeset.add_error(:slug, "is already taken")}
  end

  defp slug_collision?(changeset) do
    Enum.any?(changeset.errors, fn {field, {_message, opts}} ->
      field == :slug && opts[:constraint] == :unique
    end)
  end

  defp normalize_slug(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.replace(~r/^-+|-+$/u, "")
  end

  defp random_suffix do
    Ecto.UUID.generate()
    |> String.replace("-", "")
    |> String.slice(0, 8)
  end

  defp stringify_keys(attrs) do
    Enum.into(attrs, %{}, fn {key, value} -> {to_string(key), value} end)
  end
end
