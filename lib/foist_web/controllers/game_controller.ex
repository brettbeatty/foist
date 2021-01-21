defmodule FoistWeb.GameController do
  use FoistWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", page_title: "Play")
  end
end
