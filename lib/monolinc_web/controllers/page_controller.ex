defmodule MonolincWeb.PageController do
  use MonolincWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
