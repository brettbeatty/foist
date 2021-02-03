defmodule Foist.GameServer do
  @moduledoc """
  A game server holds the game/lobby/scoreboard state.
  """
  use GenServer
  alias Foist.{Game, GameRegistry, Lobby, Roster, Scoreboard}
  alias Foist.Events.{GameUpdated, LobbyUpdated, ScoreboardUpdated, TokensDivvied}

  @type join_code() :: Roster.join_code()
  @type state() :: Game.t() | Lobby.t() | Scoreboard.t()

  @spec broadcast!(join_code(), any()) :: :ok
  defp broadcast!(join_code, message) do
    Phoenix.PubSub.broadcast!(Foist.PubSub, join_code, message)
  end

  @doc """
  Create a child spec for a game server to be started under a supervisor.
  """
  @spec child_spec(none()) :: Supervisor.child_spec()
  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {GenServer, :start_link, [__MODULE__, nil]},
      restart: :temporary
    }
  end

  @doc """
  Fetch join code from server (via pid).
  """
  @spec fetch_join_code(pid()) :: {:ok, join_code()} | :error
  def fetch_join_code(pid) do
    case Registry.keys(GameRegistry, pid) do
      [join_code] ->
        {:ok, join_code}

      [] ->
        :error
    end
  end

  @impl GenServer
  def handle_call(request, from, state)

  def handle_call({:join, player}, {pid, _ref}, game = %Game{}) do
    case Game.rejoin(game, player) do
      :ok ->
        send(pid, GameUpdated.new(game))
        send(pid, TokensDivvied.new(game, player))
        {:reply, :ok, game}

      :error ->
        {:reply, :already_started, game}
    end
  end

  def handle_call({:join, player}, {pid, _ref}, lobby = %Lobby{}) do
    case Lobby.join(lobby, player) do
      {:ok, lobby = %Lobby{roster: %Roster{join_code: join_code}}} ->
        event = LobbyUpdated.new(lobby)
        broadcast!(join_code, event)
        send(pid, event)
        {:reply, :ok, lobby}

      :full ->
        {:reply, :full, lobby}
    end
  end

  def handle_call({:join, player}, {pid, _ref}, scoreboard = %Scoreboard{}) do
    case Scoreboard.rejoin(scoreboard, player) do
      :ok ->
        send(pid, ScoreboardUpdated.new(scoreboard))
        {:reply, :ok, scoreboard}

      :error ->
        {:reply, :already_started, scoreboard}
    end
  end

  def handle_call({:leave, player}, _from, lobby = %Lobby{}) do
    case Lobby.leave(lobby, player) do
      {:ok, lobby = %Lobby{roster: %Roster{join_code: join_code}}} ->
        broadcast!(join_code, LobbyUpdated.new(lobby))
        {:reply, :ok, lobby}

      :empty ->
        {:stop, :normal, :ok, lobby}
    end
  end

  def handle_call({:leave, player}, _from, scoreboard = %Scoreboard{}) do
    %Scoreboard{roster: %Roster{join_code: join_code}} = scoreboard

    case Scoreboard.leave(scoreboard, player) do
      {:ok, scoreboard} ->
        broadcast!(join_code, ScoreboardUpdated.new(scoreboard))
        {:reply, :ok, scoreboard}

      {:done, roster} ->
        lobby = Lobby.new(roster)
        broadcast!(join_code, LobbyUpdated.new(lobby))
        {:reply, :ok, lobby}

      :empty ->
        {:stop, :normal, :ok, scoreboard}
    end
  end

  def handle_call({:leave, _player}, _from, state) do
    {:reply, :already_started, state}
  end

  def handle_call({:place_token, player}, _from, game = %Game{}) do
    case Game.place_token(game, player) do
      {:ok, game = %Game{roster: %Roster{join_code: join_code}}} ->
        broadcast!(join_code, GameUpdated.new(game))
        {:reply, {:ok, game.hands[player].tokens}, game}

      :not_turn ->
        {:reply, :not_turn, game}

      :no_tokens ->
        {:reply, :no_tokens, game}
    end
  end

  def handle_call({:place_token, _player}, _from, state) do
    {:reply, :not_turn, state}
  end

  def handle_call({:play_again, player}, _from, scoreboard = %Scoreboard{}) do
    %Scoreboard{roster: %Roster{join_code: join_code}} = scoreboard

    case Scoreboard.play_again(scoreboard, player) do
      {:ok, scoreboard} ->
        broadcast!(join_code, ScoreboardUpdated.new(scoreboard))
        {:reply, :ok, scoreboard}

      {:done, roster} ->
        lobby = Lobby.new(roster)
        broadcast!(join_code, LobbyUpdated.new(lobby))
        {:reply, :ok, lobby}
    end
  end

  def handle_call({:play_again, _player}, _from, state) do
    {:reply, :not_scoreboard, state}
  end

  def handle_call({:start_game, player}, _from, lobby = %Lobby{}) do
    case Lobby.start_game(lobby, player) do
      {:ok, roster = %Roster{join_code: join_code}} ->
        game = Game.new(roster)
        broadcast!(join_code, GameUpdated.new(game))
        broadcast!(join_code, TokensDivvied.new(game, player))
        {:reply, :ok, game}

      :not_owner ->
        {:reply, :not_owner, lobby}

      :not_enough_players ->
        {:reply, :not_enough_players, lobby}
    end
  end

  def handle_call({:start_game, _player}, _from, state) do
    {:reply, :already_started, state}
  end

  def handle_call({:take_card, player}, _from, game = %Game{roster: roster}) do
    %Roster{join_code: join_code} = roster

    case Game.take_card(game, player) do
      {:ok, game} ->
        broadcast!(join_code, GameUpdated.new(game))
        {:reply, {:ok, game.hands[player].tokens}, game}

      {:done, hands} ->
        scoreboard = Scoreboard.new(roster, hands)
        broadcast!(join_code, ScoreboardUpdated.new(scoreboard))
        {:reply, {:ok, hands[player].tokens}, scoreboard}

      :not_turn ->
        {:reply, :not_turn, game}
    end
  end

  def handle_call({:take_card, _player}, _from, state) do
    {:reply, :not_turn, state}
  end

  @impl GenServer
  def init(opts) do
    roster = %Roster{join_code: join_code} = Roster.new()

    case Registry.register(GameRegistry, join_code, nil) do
      {:ok, _pid} ->
        {:ok, Lobby.new(roster)}

      {:error, {:already_started, _pid}} ->
        init(opts)
    end
  end

  @doc """
  Join game via `join_code` as `player`.
  """
  @spec join(join_code(), Player.t()) :: :ok | :already_started | :full | :not_found
  def join(join_code, player) do
    with :ok <- check_for_game(join_code),
         :ok <- GenServer.call(via(join_code), {:join, player}) do
      :ok = Phoenix.PubSub.subscribe(Foist.PubSub, join_code)
    end
  end

  @spec check_for_game(join_code()) :: :ok | :not_found
  defp check_for_game(join_code) do
    case Registry.lookup(GameRegistry, join_code) do
      [{_pid, nil}] ->
        :ok

      [] ->
        :not_found
    end
  end

  @doc """
  Leave game via `join_code` as `player`.
  """
  @spec leave(join_code(), Player.t()) :: :ok | :already_started
  def leave(join_code, player) do
    with :ok <- GenServer.call(via(join_code), {:leave, player}) do
      :ok = Phoenix.PubSub.unsubscribe(Foist.PubSub, join_code)
    end
  end

  @doc """
  Place token on card in focus (as `player` in game with `join_code`).
  """
  @spec place_token(join_code(), Player.t()) :: {:ok, non_neg_integer()} | :not_turn | :no_tokens
  def place_token(join_code, player) do
    GenServer.call(via(join_code), {:place_token, player})
  end

  @doc """
  Opt to play again (as `player` in game with `join_code`).
  """
  @spec play_again(join_code(), Player.t()) :: :ok | :not_scoreboard
  def play_again(join_code, player) do
    GenServer.call(via(join_code), {:play_again, player})
  end

  @doc """
  Start game via `join_code` as `player`.
  """
  @spec start_game(join_code(), Player.t()) ::
          :ok | :already_started | :not_owner | :not_enough_players
  def start_game(join_code, player) do
    GenServer.call(via(join_code), {:start_game, player})
  end

  @doc """
  Take card in focus (as `player` in game with `join_code`).
  """
  @spec take_card(join_code(), Player.t()) :: {:ok, non_neg_integer()} | :not_turn
  def take_card(join_code, player) do
    GenServer.call(via(join_code), {:take_card, player})
  end

  @spec via(join_code()) :: GenServer.name()
  defp via(join_code) do
    {:via, Registry, {GameRegistry, join_code}}
  end
end
