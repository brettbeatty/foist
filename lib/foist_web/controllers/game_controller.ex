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
    player = get_session(conn, "player")

    render(conn, "index.html", page_title: "Play", player: player)
  end

  def join_code(conn, _params) do
    render(conn, "join.html", page_title: "Join Game", changeset: join_changeset(%{}))
  end

  def join(conn, %{"join_params" => params}) do
    changeset = join_changeset(params)

    case Ecto.Changeset.apply_action(changeset, :join) do
      {:ok, %{join_code: join_code}} ->
        redirect(conn, to: Routes.game_path(conn, :show, String.upcase(join_code)))

      {:error, changeset} ->
        render(conn, "join.html", page_title: "Join Game", changeset: changeset)
    end
  end

  defp join_changeset(attrs) do
    {%{}, %{join_code: :string}}
    |> Ecto.Changeset.cast(attrs, [:join_code])
    |> Ecto.Changeset.validate_required([:join_code])
    |> Ecto.Changeset.validate_length(:join_code, is: 4)
  end
end
