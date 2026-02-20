defmodule MonolincWeb.RoomLive.NewTest do
  use MonolincWeb.ConnCase

  import Phoenix.LiveViewTest

  test "renders create form", %{conn: conn} do
    %{conn: conn} = register_and_log_in_user(%{conn: conn})
    {:ok, view, _html} = live(conn, ~p"/rooms/new")
    assert has_element?(view, "#room-create-form")
    assert has_element?(view, "#room-name-input")
    assert has_element?(view, "#room-description-input")
  end
end
