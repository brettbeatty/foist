defmodule Foist.Fixtures do
  alias Foist.{Game, Hand, Player, Roster, Scoreboard}

  @spec game(turn: 0..6) :: Game.t()
  def game(opts \\ []) do
    %Game{
      card: 27,
      deck: Keyword.get(opts, :deck, [30, 35, 15, 11, 14, 18, 12]),
      hands: %{
        player(?A) => hand(cards: [4, 5], tokens: 1),
        player(?B) => hand(cards: [6, 7, 8, 9, 10], tokens: 1),
        player(?C) => hand(cards: [23, 25, 26, 29], tokens: 3),
        player(?D) => hand(cards: [16], tokens: 5),
        player(?E) => hand(cards: [21], tokens: 1),
        player(?F) => hand(cards: [32, 33], tokens: 36),
        player(?G) => hand(cards: [34], tokens: 0)
      },
      roster: roster(7),
      tokens: 2,
      turn: Keyword.get(opts, :turn, 3),
      turn_order: {
        player(?E),
        player(?G),
        player(?F),
        player(?A),
        player(?C),
        player(?B),
        player(?D)
      }
    }
  end

  def hands do
    %{
      player(?A) => hand(cards: [4, 5, 12, 15], tokens: 4),
      player(?B) => hand(cards: [6, 7, 8, 9, 10, 11], tokens: 0),
      player(?C) => hand(cards: [23, 25, 26, 27, 29, 30], tokens: 3),
      player(?D) => hand(cards: [16, 18], tokens: 8),
      player(?E) => hand(cards: [14, 21], tokens: 0),
      player(?F) => hand(cards: [32, 33], tokens: 33),
      player(?G) => hand(cards: [34, 35], tokens: 1)
    }
  end

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

  @spec scoreboard(1..7) :: Scoreboard.t()
  def scoreboard(size \\ 3) do
    %Scoreboard{
      play_again: MapSet.new([player(?B), player(?C)]),
      roster: roster(size),
      scores: [
        {player(?F), -1},
        {player(?B), 6},
        {player(?D), 26},
        {player(?A), 27},
        {player(?G), 33},
        {player(?E), 35},
        {player(?C), 74}
      ]
    }
  end
end
