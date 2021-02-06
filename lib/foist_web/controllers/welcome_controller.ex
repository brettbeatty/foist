defmodule FoistWeb.WelcomeController do
  use FoistWeb, :controller

  def how_to_play(conn, _params) do
    render(conn, "how_to_play.html", page_title: "How to Play")
  end

  def index(conn, _params) do
    render(conn, "index.html", page_title: "Welcome")
  end
end
