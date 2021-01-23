defmodule FoistWeb.GameLive do
  use FoistWeb, :live_view
  alias FoistWeb.GameView

  @impl Phoenix.LiveView
  def mount(%{"join_code" => join_code}, _session, socket) do
    {:ok, assign(socket, page_title: "Game #{join_code}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    render(GameView, "lobby.html", assigns)
  end
end
