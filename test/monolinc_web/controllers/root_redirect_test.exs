defmodule MonolincWeb.RootRedirectTest do
  use MonolincWeb.ConnCase

  test "redirects unauthenticated users to login", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/users/log-in"
  end

  describe "when authenticated" do
    setup :register_and_log_in_user

    test "redirects to rooms", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert redirected_to(conn) == "/rooms"
    end
  end
end
