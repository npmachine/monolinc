defmodule Monolinc.Rooms.RoomTest do
  use Monolinc.DataCase

  alias Monolinc.Rooms.Room

  test "changeset requires name" do
    changeset = Room.changeset(%Room{}, %{name: ""})
    refute changeset.valid?
    assert "can't be blank" in errors_on(changeset).name
  end
end
