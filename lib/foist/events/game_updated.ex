defmodule Foist.Events.GameUpdated do
  @moduledoc """
  Broadcast when game is started or updated.
  """
  alias Foist.{Game, Hand, Player}

  @type card() :: {:lone | :low | :mid | :high, Hand.card()}
  @type hand() :: %{cards: [card()], name: String.t(), turn?: boolean()}
  @type t() :: %__MODULE__{
          card: Hand.card(),
          deck_size: non_neg_integer(),
          hands: [hand()],
          tokens: non_neg_integer(),
          turn: Player.t()
        }

  defstruct [:card, :deck_size, :hands, :tokens, :turn]

  @doc """
  Create a GameUpdated event.
  """
  @spec new(Game.t()) :: t()
  def new(game = %Game{card: card, deck: deck, tokens: tokens}) do
    %__MODULE__{
      card: card,
      deck_size: length(deck),
      hands: format_hands(game),
      tokens: tokens,
      turn: get_turn(game)
    }
  end

  @spec format_hands(Game.t()) :: [hand()]
  defp format_hands(%Game{hands: hands, turn: turn, turn_order: turn_order}) do
    players =
      turn_order
      |> Tuple.to_list()
      |> Enum.with_index()

    for {player = %Player{name: name}, index} <- players do
      %Hand{cards: cards} = hands[player]
      %{cards: group(cards, false), name: name, turn?: index == turn}
    end
  end

  @spec group([Hand.card()], boolean()) :: [card()]
  defp group(cards, within_group?)

  defp group([], _within_group?) do
    []
  end

  defp group([a, b | rest], true) when a + 1 == b do
    [{:mid, a} | group([b | rest], true)]
  end

  defp group([a | rest], true) do
    [{:high, a} | group(rest, false)]
  end

  defp group([a, b | rest], false) when a + 1 == b do
    [{:low, a} | group([b | rest], true)]
  end

  defp group([a | rest], false) do
    [{:lone, a} | group(rest, false)]
  end

  @spec get_turn(Game.t()) :: Player.t()
  defp get_turn(%Game{turn: turn, turn_order: turn_order}) do
    elem(turn_order, turn)
  end
end
