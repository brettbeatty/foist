defmodule Foist do
  @moduledoc """
  Logic for playing Foist.
  """
  alias Foist.{GameServer, GameSupervisor}

  @type join_code() :: GameServer.join_code()

  @doc """
  Create a game of Foist.
  """
  @spec create_game() :: {:ok, join_code()} | :error
  def create_game do
    case DynamicSupervisor.start_child(GameSupervisor, GameServer) do
      {:ok, pid} ->
        GameServer.fetch_join_code(pid)

      {:error, _error} ->
        :error
    end
  end

  @doc """
  Join a game of Foist.
  """
  @spec join_game(join_code(), Player.t()) :: :ok | :already_started | :full | :not_found
  def join_game(join_code, player) do
    GameServer.join(join_code, player)
  end

  @doc """
  Leave a game of Foist.
  """
  @spec leave_game(join_code(), Player.t()) :: :ok | :already_started
  def leave_game(join_code, player) do
    GameServer.leave(join_code, player)
  end

  @doc """
  Place a token on card.
  """
  @spec place_token(join_code(), Player.t()) :: {:ok, non_neg_integer()} | :not_turn | :no_tokens
  def place_token(join_code, player) do
    GameServer.place_token(join_code, player)
  end

  @doc """
  Opt to play again.
  """
  @spec play_again(join_code(), Player.t()) :: :ok | :not_scoreboard
  def play_again(join_code, player) do
    GameServer.play_again(join_code, player)
  end

  @doc """
  Start a game of Foist.
  """
  @spec start_game(join_code(), Player.t()) ::
          :ok | :already_started | :not_owner | :not_enough_players
  def start_game(join_code, player) do
    GameServer.start_game(join_code, player)
  end

  @doc """
  Take card.
  """
  @spec take_card(join_code(), Player.t()) :: {:ok, non_neg_integer()} | :not_turn
  def take_card(join_code, player) do
    GameServer.take_card(join_code, player)
  end
end
