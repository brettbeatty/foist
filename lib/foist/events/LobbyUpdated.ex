defmodule Foist.Events.LobbyUpdated do
  @moduledoc """
  Broadcast when going to a lobby or lobby is updated.
  """
  alias Foist.{Lobby, Player, Roster}

  @type t() :: %__MODULE__{players: [Player.t()]}

  defstruct [:players]

  @doc """
  Create a LobbyUpdated event.
  """
  @spec new(Lobby.t()) :: t()
  def new(%Lobby{roster: %Roster{players: players}}) do
    %__MODULE__{players: players}
  end
end
