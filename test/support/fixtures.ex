defmodule Foist.Fixtures do
  alias Foist.Games.Hand

  @spec hand(cards: [Hand.card()], tokens: non_neg_integer()) :: Hand.t()
  def hand(opts \\ []) do
    struct!(%Hand{cards: [23, 24, 25, 27], tokens: 8}, opts)
  end
end
