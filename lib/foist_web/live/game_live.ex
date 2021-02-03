defmodule FoistWeb.GameLive do
  use FoistWeb, :live_view
  alias Foist.Events.{GameUpdated, LobbyUpdated, ScoreboardUpdated, TokensDivvied}
  alias FoistWeb.GameView

  @impl Phoenix.LiveView
  def handle_event(event, params, socket)

  def handle_event("leave_game", _params, socket) do
    %{join_code: join_code, player: player} = socket.assigns

    case Foist.leave_game(join_code, player) do
      :ok ->
        {:noreply, redirect(socket, to: Routes.game_path(socket, :index))}

      error when error in [:already_started, :not_owner, :not_enough_players] ->
        {:noreply, put_flash(socket, :error, error)}
    end
  end

  def handle_event("place_token", _params, socket) do
    %{join_code: join_code, player: player} = socket.assigns

    case Foist.place_token(join_code, player) do
      {:ok, tokens} ->
        {:noreply, assign(socket, tokens: tokens)}

      error when error in [:not_turn, :no_tokens] ->
        {:noreply, put_flash(socket, :error, error)}
    end
  end

  def handle_event("play_again", _params, socket) do
    %{join_code: join_code, player: player} = socket.assigns

    case Foist.play_again(join_code, player) do
      :ok ->
        {:noreply, socket}

      :not_scoreboard ->
        {:noreply, put_flash(socket, :error, :not_scoreboard)}
    end
  end

  def handle_event("start_game", _params, socket) do
    %{join_code: join_code, player: player} = socket.assigns

    case Foist.start_game(join_code, player) do
      :ok ->
        {:noreply, socket}

      error when error in [:already_started, :not_owner, :not_enough_players] ->
        {:noreply, put_flash(socket, :error, error)}
    end
  end

  def handle_event("take_card", _params, socket) do
    %{join_code: join_code, player: player} = socket.assigns

    case Foist.take_card(join_code, player) do
      {:ok, tokens} ->
        {:noreply, assign(socket, tokens: tokens)}

      :not_turn ->
        {:noreply, put_flash(socket, :error, :not_turn)}
    end
  end

  @impl Phoenix.LiveView
  def handle_info(message, socket)

  def handle_info(event = %GameUpdated{}, socket) do
    %GameUpdated{card: card, deck_size: deck_size, hands: hands, tokens: tokens, turn: turn} =
      event

    assigns = [
      card: card,
      card_tokens: tokens,
      deck_size: deck_size,
      hands: hands,
      screen: :game,
      turn: turn
    ]

    {:noreply, assign(socket, assigns)}
  end

  def handle_info(%LobbyUpdated{owner: owner, players: players}, socket) do
    assigns = [owner: owner, players: players, screen: :lobby]

    {:noreply, assign(socket, assigns)}
  end

  def handle_info(%ScoreboardUpdated{scores: scores}, socket) do
    {:noreply, assign(socket, scores: scores, screen: :scoreboard)}
  end

  def handle_info(%TokensDivvied{tokens: tokens}, socket) do
    {:noreply, assign(socket, tokens: tokens)}
  end

  @impl Phoenix.LiveView
  def mount(%{"join_code" => join_code}, %{"player" => player}, socket) do
    case Foist.join_game(join_code, player) do
      :ok ->
        {:ok, join_game(socket, join_code, player)}

      error when error in [:already_started, :full, :not_found] ->
        {:ok,
         socket
         |> put_flash(:error, error)
         |> redirect(to: Routes.game_path(socket, :join_code))}
    end
  end

  defp join_game(socket = %{host_uri: host}, join_code, player) do
    url =
      host
      |> struct!(authority: "localhost")
      |> URI.merge(Routes.game_path(socket, :show, join_code))
      |> URI.to_string()

    assigns = [
      card: nil,
      card_tokens: 0,
      deck_size: 0,
      hands: [],
      join_code: join_code,
      owner: nil,
      page_title: "Game #{join_code}",
      player: player,
      players: [],
      screen: :lobby,
      scores: [],
      tokens: 0,
      turn: nil,
      url: url
    ]

    assign(socket, assigns)
  end

  @impl Phoenix.LiveView
  def render(assigns)

  def render(assigns = %{screen: :game}) do
    render(GameView, "game.html", assigns)
  end

  def render(assigns = %{screen: :lobby}) do
    render(GameView, "lobby.html", assigns)
  end

  def render(assigns = %{screen: :scoreboard}) do
    render(GameView, "scoreboard.html", assigns)
  end
end
