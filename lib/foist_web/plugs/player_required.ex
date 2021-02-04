defmodule FoistWeb.PlayerRequired do
  @behaviour Plug
  import Phoenix.Controller, only: [redirect: 2]
  import Plug.Conn, only: [get_session: 2, halt: 1]
  alias Foist.Player
  alias FoistWeb.Router.Helpers, as: Routes

  @impl Plug
  def init(opts) do
    opts
  end

  @impl Plug
  def call(conn = %{request_path: path}, _opts) do
    case get_session(conn, "player") do
      nil ->
        conn
        |> redirect(to: Routes.player_path(conn, :new, redirect: path))
        |> halt()

      %Player{} ->
        conn
    end
  end
end
