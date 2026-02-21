defmodule MonolincWeb.RoomLive.ShowTest do
  use MonolincWeb.ConnCase

  import Phoenix.LiveViewTest

  test "shows recent messages", %{conn: conn} do
    %{conn: conn, user: user} = register_and_log_in_user(%{conn: conn})
    {:ok, room} = Monolinc.Rooms.create_room(user, %{name: "General"})
    {:ok, _} = Monolinc.Messaging.create_message(user, room, %{content: "hello"})

    {:ok, view, _html} = live(conn, ~p"/rooms/#{room.slug}")
    assert has_element?(view, "#room-chat-shell")
    assert has_element?(view, "#messages")
    assert has_element?(view, "#message-input")
    assert has_element?(view, "#message-submit")
  end

  test "sends message and renders it", %{conn: conn} do
    %{conn: conn, user: user} = register_and_log_in_user(%{conn: conn})
    {:ok, room} = Monolinc.Rooms.create_room(user, %{name: "General"})

    {:ok, view, _html} = live(conn, ~p"/rooms/#{room.slug}")

    view
    |> form("#message-form", %{"message" => %{"content" => "hey"}})
    |> render_submit()

    assert has_element?(view, "#messages", "hey")
  end

  test "redirects to rooms when slug is missing", %{conn: conn} do
    %{conn: conn} = register_and_log_in_user(%{conn: conn})

    assert {:error, {:live_redirect, %{to: "/rooms"}}} = live(conn, ~p"/rooms/missing-room")
  end

  test "renders connection status helper", %{conn: conn} do
    %{conn: conn, user: user} = register_and_log_in_user(%{conn: conn})
    {:ok, room} = Monolinc.Rooms.create_room(user, %{name: "General"})

    {:ok, view, _html} = live(conn, ~p"/rooms/#{room.slug}")

    assert has_element?(view, "#chat-connection-status")
  end
end
