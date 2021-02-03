defmodule Foist.Scoreboard do
  @moduledoc """
  A scoreboard has a roster and scores for the players on the roster.
  """
  alias Foist.{Hand, Roster, Player}

  @type t() :: %__MODULE__{
          play_again: MapSet.new(Player.t()),
          roster: Roster.t(),
          scores: [{Player.t(), integer()}]
        }

  defstruct [:play_again, :roster, :scores]

  @doc """
  Leave roster; don't stick around for another game (as `player`).

  Fails if last player to leave; mostly a signal to shut down roster.
  """
  @spec leave(t(), Player.t()) :: {:ok, t()} | {:done, Roster.t()} | :empty
  def leave(scoreboard = %__MODULE__{roster: roster}, player) do
    with {:ok, roster} <- Roster.remove_player(roster, player) do
      maybe_finish(%{scoreboard | roster: roster})
    end
  end

  @spec maybe_finish(t()) :: {:ok, t()} | {:done, Roster.t()}
  defp maybe_finish(scoreboard = %__MODULE__{play_again: play_again, roster: roster}) do
    %Roster{players: players} = roster

    if Enum.all?(players, &MapSet.member?(play_again, &1)) do
      {:done, roster}
    else
      {:ok, scoreboard}
    end
  end

  @doc """
  Create a scoreboard for `roster` by scoring `hands`.
  """
  @spec new(Roster.t(), %{Player.t() => Hand.t()}) :: t()
  def new(roster, hands) do
    %__MODULE__{play_again: MapSet.new(), roster: roster, scores: score(hands)}
  end

  @spec score(%{Player.t() => Hand.t()}) :: [{Player.t(), integer()}]
  defp score(hands) do
    hands
    |> Enum.map(fn {player, hand} -> {player, Hand.score(hand)} end)
    |> Enum.sort_by(fn {_player, score} -> score end)
  end

  @doc """
  Opt (as `player`) to play again.
  """
  @spec play_again(t(), Player.t()) :: {:ok, t()} | {:done, Roster.t()}
  def play_again(scoreboard = %__MODULE__{play_again: play_again}, player) do
    maybe_finish(%{scoreboard | play_again: MapSet.put(play_again, player)})
  end

  @doc """
  As `player` rejoin `scoreboard`.

  Fails if `player` not on `scoreboard`'s roster.
  """
  @spec rejoin(t(), Player.t()) :: :ok | :error
  def rejoin(%__MODULE__{roster: roster}, player) do
    if Roster.member?(roster, player) do
      :ok
    else
      :error
    end
  end
end
