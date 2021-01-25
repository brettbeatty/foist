defmodule FoistWeb.GameLive do
  use FoistWeb, :live_view
  alias FoistWeb.GameView

  @impl Phoenix.LiveView
  def mount(%{"join_code" => join_code}, %{"player" => player}, socket = %{host_uri: host}) do
    url =
      host
      |> struct!(authority: "localhost")
      |> URI.merge(Routes.game_path(socket, :show, join_code))
      |> URI.to_string()

    assigns = [
      join_code: join_code,
      page_title: "Game #{join_code}",
      player: player,
      url: url
    ]

    {:ok, assign(socket, assigns)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    render(GameView, "lobby.html", assigns)
  end
end
