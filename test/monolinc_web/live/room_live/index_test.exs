defmodule MonolincWeb.RoomLive.IndexTest do
  use MonolincWeb.ConnCase

  import Phoenix.LiveViewTest

  test "redirects unauthenticated users", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/rooms")
  end

  test "lists rooms for authenticated users", %{conn: conn} do
    %{conn: conn} = register_and_log_in_user(%{conn: conn})
    {:ok, view, _html} = live(conn, ~p"/rooms")
    assert has_element?(view, "#app-shell")
    assert has_element?(view, "#rooms-index")
    assert has_element?(view, "#rooms-page-shell")
  end
end
