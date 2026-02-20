defmodule Monolinc.RoomsTest do
  use Monolinc.DataCase

  alias Monolinc.Rooms

  test "create_room/2 generates a strict slug" do
    user = Monolinc.AccountsFixtures.user_fixture()
    {:ok, room} = Rooms.create_room(user, %{name: "Hello World", description: "Test"})
    assert room.slug == "hello-world"
  end

  test "create_room/2 appends suffix on slug collision" do
    user = Monolinc.AccountsFixtures.user_fixture()
    {:ok, room1} = Rooms.create_room(user, %{name: "General"})
    {:ok, room2} = Rooms.create_room(user, %{name: "General"})
    assert room1.slug != room2.slug
    assert String.starts_with?(room2.slug, "general-")
  end

  test "create_room/2 errors when slug would be empty" do
    user = Monolinc.AccountsFixtures.user_fixture()
    assert {:error, changeset} = Rooms.create_room(user, %{name: "!!!"})
    assert "must include letters or numbers" in errors_on(changeset).slug
  end
end
