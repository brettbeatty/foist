defmodule Foist.Fixtures do
  alias Foist.{Hand, Player, Roster}

  @spec hand(cards: [Hand.card()], tokens: non_neg_integer()) :: Hand.t()
  def hand(opts \\ []) do
    struct!(%Hand{cards: [23, 24, 25, 27], tokens: 8}, opts)
  end

  @spec player(?A..?Z) :: Player.t()
  def player(char) do
    %Player{id: <<"0000000", char>>, name: <<"Player ", char>>}
  end

  @spec roster(0..7) :: Roster.t()
  def roster(size) do
    players =
      ?A..?G
      |> Enum.take(size)
      |> Enum.map(&player/1)

    %Roster{join_code: "ABCD", players: players}
  end
end
