defmodule Foist.Roster do
  @moduledoc """
  A roster contains a join code and a list of players.
  """
  alias Foist.Player

  @type join_code() :: <<_::32>>
  @type t() :: %__MODULE__{join_code: join_code(), players: [Player.t()]}

  defstruct [:join_code, :players]

  @capacity 7

  @doc """
  Add `player` to `roster` if roster not full.
  """
  @spec add_player(t(), Player.t()) :: {:ok, t()} | :full
  def add_player(roster = %__MODULE__{players: players}, player) do
    cond do
      player in players ->
        {:ok, roster}

      length(players) < @capacity ->
        {:ok, %{roster | players: players ++ [player]}}

      true ->
        :full
    end
  end

  @doc """
  Create a roster.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{join_code: generate_join_code(), players: []}
  end

  @spec generate_join_code() :: join_code()
  defp generate_join_code do
    3
    |> :crypto.strong_rand_bytes()
    |> Base.encode32()
    |> binary_part(0, 4)
  end

  @doc """
  Gets the owner (first player) of the roster.
  """
  @spec owner(t()) :: Player.t() | nil
  def owner(roster)

  def owner(%__MODULE__{players: [player | _players]}) do
    player
  end

  def owner(_roster) do
    nil
  end

  @doc """
  Remove `player` from `roster`.

  Fails if last player to leave, more as a signal the roster can be discarded.
  """
  @spec remove_player(t(), Player.t()) :: {:ok, t()} | :empty
  def remove_player(roster, player)

  def remove_player(%__MODULE__{players: [player]}, player) do
    :empty
  end

  def remove_player(roster = %__MODULE__{players: players}, player) do
    {:ok, %{roster | players: List.delete(players, player)}}
  end
end
