defmodule FoistWeb.GameController do
  use FoistWeb, :controller

  def create(conn, _params) do
    case Foist.create_game() do
      {:ok, join_code} ->
        redirect(conn, to: Routes.game_path(conn, :show, join_code))

      :error ->
        conn
        |> put_flash(:error, "Could not create game")
        |> redirect(to: Routes.game_path(conn, :index))
    end
  end

  def index(conn, _params) do
    render(conn, "index.html", page_title: "Play")
  end
end
