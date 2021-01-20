defmodule Foist.Events.TokensDivvied do
  @moduledoc """
  Broadcast at the start of a game when tokens are divvied out.
  """
  alias Foist.{Game, Hand, Player}

  @type t() :: %__MODULE__{tokens: 7 | 9 | 11}

  defstruct [:tokens]

  @doc """
  Create a TokensDivvied event.
  """
  @spec new(Game.t()) :: t()
  def new(%Game{hands: hands}) do
    [{%Player{}, %Hand{tokens: tokens}}] = Enum.take(hands, 1)

    %__MODULE__{tokens: tokens}
  end
end
