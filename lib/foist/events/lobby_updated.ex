defmodule Foist.Events.LobbyUpdated do
  @moduledoc """
  Broadcast when going to a lobby or lobby is updated.
  """
  alias Foist.{Lobby, Player, Roster}

  @type t() :: %__MODULE__{owner: Player.t() | nil, players: [Player.t()]}

  defstruct [:owner, :players]

  @doc """
  Create a LobbyUpdated event.
  """
  @spec new(Lobby.t()) :: t()
  def new(%Lobby{roster: %Roster{players: players}}) do
    %__MODULE__{owner: List.first(players), players: players}
  end
end
