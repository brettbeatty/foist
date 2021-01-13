defmodule Foist.Lobby do
  @moduledoc """
  Players wait in a lobby for additional players before starting a game.
  """
  alias Foist.{Player, Roster}

  @type t() :: %__MODULE__{roster: Roster.t()}

  defstruct [:roster]

  @doc """
  Join `lobby` (as `player`).
  """
  @spec join(t(), Player.t()) :: {:ok, t()} | :full
  def join(lobby = %__MODULE__{roster: roster}, player) do
    with {:ok, roster} <- Roster.add_player(roster, player) do
      {:ok, %{lobby | roster: roster}}
    end
  end

  @doc """
  Leave `lobby` (as `player`).
  """
  @spec leave(t(), Player.t()) :: {:ok, t()} | :empty
  def leave(lobby = %__MODULE__{roster: roster}, player) do
    with {:ok, roster} <- Roster.remove_player(roster, player) do
      {:ok, %{lobby | roster: roster}}
    end
  end

  @doc """
  Create a lobby for players on `roster`.
  """
  @spec new(Roster.t()) :: t()
  def new(roster) do
    %__MODULE__{roster: roster}
  end

  @doc """
  Start game for players in `lobby` (as `player`).
  """
  @spec start_game(t(), Player.t()) :: {:ok, Roster.t()} | :not_owner | :not_enough_players
  def start_game(%__MODULE__{roster: roster = %Roster{players: players}}, player) do
    cond do
      length(players) < 3 ->
        :not_enough_players

      Roster.owner(roster) != player ->
        :not_owner

      true ->
        {:ok, roster}
    end
  end
end
