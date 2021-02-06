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
        {name, cancel} =
          case get_session(conn, "player") do
            %Player{name: name} ->
              {name, Routes.game_path(conn, :index)}

            nil ->
              {"", Routes.welcome_path(conn, :index)}
          end

        assigns = [
          cancel: cancel,
          changeset: changeset,
          name: name,
          page_title: "New Player"
        ]

        render(conn, "new.html", assigns)
    end
  end

  def new(conn, params) do
    changeset =
      params
      |> Map.take(["redirect"])
      |> changeset()

    {name, cancel} =
      case get_session(conn, "player") do
        %Player{name: name} ->
          {name, Routes.game_path(conn, :index)}

        nil ->
          {"", Routes.welcome_path(conn, :index)}
      end

    assigns = [
      cancel: cancel,
      changeset: changeset,
      name: name,
      page_title: "New Player"
    ]

    render(conn, "new.html", assigns)
  end

  defp changeset(attrs) do
    {%{}, %{name: :string, redirect: :string}}
    |> Ecto.Changeset.cast(attrs, [:name, :redirect])
    |> Ecto.Changeset.validate_required([:name])
  end
end
