defmodule Foist.Game do
  @moduledoc """
  Keeps track of game state.
  """
  alias Foist.{Hand, Player, Roster}

  @type t() :: %__MODULE__{
          card: Hand.card(),
          deck: [Hand.card()],
          hands: %{Player.t() => Hand.t()},
          roster: Roster.t(),
          tokens: non_neg_integer(),
          turn: 0..6,
          turn_order: tuple()
        }

  defstruct [:card, :deck, :hands, :roster, :tokens, :turn, :turn_order]

  @doc """
  Create a game for `roster` of players.
  """
  @spec new(Roster.t()) :: t()
  def new(roster = %Roster{players: players}) do
    [card | deck] = shuffle_deck()

    %__MODULE__{
      card: card,
      deck: deck,
      hands: divvy_tokens(players),
      roster: roster,
      tokens: 0,
      turn: 0,
      turn_order: players |> Enum.shuffle() |> List.to_tuple()
    }
  end

  @spec shuffle_deck() :: [Hand.card()]
  defp shuffle_deck do
    3..35
    |> Enum.shuffle()
    |> Enum.drop(9)
  end

  @spec divvy_tokens([Player.t()]) :: %{Player.t() => Hand.t()}
  defp divvy_tokens(players) do
    hand =
      case length(players) do
        size when size in 3..5 ->
          Hand.new(11)

        6 ->
          Hand.new(9)

        7 ->
          Hand.new(7)
      end

    Map.new(players, &{&1, hand})
  end

  @doc """
  As `player` place a token from hand on card.

  Fails if not `player`'s turn or if `player` out of tokens.
  """
  @spec place_token(t(), Player.t()) :: {:ok, t()} | :not_turn | :no_tokens
  def place_token(game = %__MODULE__{hands: hands, tokens: tokens}, player) do
    with :ok <- check_turn(game, player),
         {:ok, hand} <- Hand.remove_token(hands[player]) do
      game =
        %{game | tokens: tokens + 1}
        |> put_hand(player, hand)
        |> advance_turn()

      {:ok, game}
    end
  end

  @spec check_turn(t(), Player.t()) :: :ok | :not_turn
  defp check_turn(%__MODULE__{turn: turn, turn_order: turn_order}, player) do
    case elem(turn_order, turn) do
      ^player ->
        :ok

      _player ->
        :not_turn
    end
  end

  @spec put_hand(t(), Player.t(), Hand.t()) :: t()
  defp put_hand(game = %__MODULE__{hands: hands}, player, hand) do
    %{game | hands: %{hands | player => hand}}
  end

  @spec advance_turn(t()) :: t()
  defp advance_turn(game)

  defp advance_turn(game = %__MODULE__{turn: turn, turn_order: turn_order})
       when turn >= tuple_size(turn_order) - 1 do
    %{game | turn: 0}
  end

  defp advance_turn(game = %__MODULE__{turn: turn}) do
    %{game | turn: turn + 1}
  end

  @doc """
  As `player` rejoin `game`.

  Fails if `player` not on `game`'s roster.
  """
  @spec rejoin(t(), Player.t()) :: :ok | :error
  def rejoin(%__MODULE__{roster: roster}, player) do
    if Roster.member?(roster, player) do
      :ok
    else
      :error
    end
  end

  @doc """
  As `player` take the card.

  Fails if not `player`'s turn. Game ends when last card taken.
  """
  @spec take_card(t(), Player.t()) :: {:ok, t()} | {:done, %{Player.t() => Hand.t()}} | :not_turn
  def take_card(game = %__MODULE__{card: card, deck: deck, hands: hands, tokens: tokens}, player) do
    with :ok <- check_turn(game, player) do
      hand =
        hands[player]
        |> Hand.add_card(card)
        |> Hand.add_tokens(tokens)

      case deck do
        [card | deck] ->
          {:ok, put_hand(%{game | card: card, deck: deck, tokens: 0}, player, hand)}

        [] ->
          {:done, %{hands | player => hand}}
      end
    end
  end
end
