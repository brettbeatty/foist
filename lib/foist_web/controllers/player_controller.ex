defmodule FoistWeb.PlayerController do
  use FoistWeb, :controller
  alias Foist.Player

  def create(conn, %{"player_params" => params}) do
    changeset = changeset(params)

    case Ecto.Changeset.apply_action(changeset, :create) do
      {:ok, params = %{name: name}} ->
        player = Player.new(name)
        redirect = Map.get(params, :redirect, Routes.game_path(conn, :index))

        conn
        |> put_session("player", player)
        |> redirect(to: redirect)

      {:error, changeset} ->
        render(conn, "new.html", page_title: "New Player", changeset: changeset)
    end
  end

  def new(conn, params) do
    changeset =
      params
      |> Map.take(["redirect"])
      |> changeset()

    render(conn, "new.html", page_title: "New Player", changeset: changeset)
  end

  defp changeset(attrs) do
    {%{}, %{name: :string, redirect: :string}}
    |> Ecto.Changeset.cast(attrs, [:name, :redirect])
    |> Ecto.Changeset.validate_required([:name])
  end
end
