defmodule Foist.Events.TokensDivvied do
  @moduledoc """
  Broadcast at the start of a game when tokens are divvied out.
  """
  alias Foist.{Game, Hand, Player}

  @type t() :: %__MODULE__{tokens: non_neg_integer()}

  defstruct [:tokens]

  @doc """
  Create a TokensDivvied event.
  """
  @spec new(Game.t(), Player.t()) :: t()
  def new(%Game{hands: hands}, player) do
    %{^player => %Hand{tokens: tokens}} = hands

    %__MODULE__{tokens: tokens}
  end
end
