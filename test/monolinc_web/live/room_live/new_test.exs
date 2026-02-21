defmodule MonolincWeb.RoomLive.NewTest do
  use MonolincWeb.ConnCase

  import Phoenix.LiveViewTest

  test "renders create form", %{conn: conn} do
    %{conn: conn} = register_and_log_in_user(%{conn: conn})
    {:ok, view, _html} = live(conn, ~p"/rooms/new")
    assert has_element?(view, "#room-new-shell")
    assert has_element?(view, "#room-create-form")
    assert has_element?(view, "#room-name-input")
    assert has_element?(view, "#room-description-input")
  end

  test "creates a room and redirects", %{conn: conn} do
    %{conn: conn} = register_and_log_in_user(%{conn: conn})
    {:ok, view, _html} = live(conn, ~p"/rooms/new")

    view
    |> form("#room-create-form", %{
      "room" => %{"name" => "General", "description" => "Main"}
    })
    |> render_submit()

    assert_redirect(view, "/rooms/general")
  end

  test "shows error when name normalizes to empty", %{conn: conn} do
    %{conn: conn} = register_and_log_in_user(%{conn: conn})
    {:ok, view, _html} = live(conn, ~p"/rooms/new")

    view
    |> form("#room-create-form", %{"room" => %{"name" => "!!!"}})
    |> render_submit()

    assert has_element?(view, "p.text-error", "must include letters or numbers")
  end
end
