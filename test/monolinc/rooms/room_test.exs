defmodule Monolinc.Rooms.RoomTest do
  use Monolinc.DataCase

  alias Monolinc.Rooms.Room

  test "changeset requires name" do
    changeset = Room.changeset(%Room{}, %{name: ""})
    refute changeset.valid?
    assert "can't be blank" in errors_on(changeset).name
  end

  test "changeset enforces name max length" do
    changeset =
      Room.changeset(%Room{}, %{
        name: String.duplicate("a", 101),
        slug: "test-room",
        created_by: Ecto.UUID.generate()
      })

    refute changeset.valid?
    assert "should be at most 100 character(s)" in errors_on(changeset).name
  end

  test "changeset enforces description max length" do
    changeset =
      Room.changeset(%Room{}, %{
        name: "General",
        slug: "general",
        created_by: Ecto.UUID.generate(),
        description: String.duplicate("a", 501)
      })

    refute changeset.valid?
    assert "should be at most 500 character(s)" in errors_on(changeset).description
  end
end
