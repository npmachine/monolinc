defmodule MonolincWeb.PageController do
  use MonolincWeb, :controller

  def home(conn, _params) do
    if conn.assigns.current_scope && conn.assigns.current_scope.user do
      redirect(conn, to: "/rooms")
    else
      redirect(conn, to: ~p"/users/log-in")
    end
  end
end
