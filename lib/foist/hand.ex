defmodule Foist.Hand do
  @moduledoc """
  A hand holds a player's cards and tokens.
  """

  @type card() :: 3..35
  @type t() :: %__MODULE__{cards: card(), tokens: non_neg_integer()}

  defstruct [:cards, :tokens]

  @doc """
  Add `card` to `hand`.
  """
  @spec add_card(t(), card()) :: t()
  def add_card(hand = %__MODULE__{cards: cards}, card) do
    %{hand | cards: Enum.sort([card | cards])}
  end

  @doc """
  Add `tokens` to `hand`.
  """
  @spec add_tokens(t(), non_neg_integer()) :: t()
  def add_tokens(hand = %__MODULE__{tokens: total}, tokens) do
    %{hand | tokens: total + tokens}
  end

  @doc """
  Create a hand with `tokens`.
  """
  @spec new(7 | 9 | 11) :: t()
  def new(tokens) do
    %__MODULE__{cards: [], tokens: tokens}
  end

  @doc """
  Remove a token from `hand` if there is one to take.
  """
  @spec remove_token(t()) :: {:ok, t()} | :no_tokens
  def remove_token(hand)

  def remove_token(%__MODULE__{tokens: 0}) do
    :no_tokens
  end

  def remove_token(hand = %__MODULE__{tokens: tokens}) do
    {:ok, %{hand | tokens: tokens - 1}}
  end

  @doc """
  Scores `hand`.

  Cards not in a run add to score. Tokens remove from score.
  """
  @spec score(t()) :: integer()
  def score(%__MODULE__{cards: cards, tokens: tokens}) do
    score_cards(cards, 0, -tokens)
  end

  @spec score_cards([card()], card() | 0, integer()) :: integer()
  defp score_cards(cards, previous, total)

  defp score_cards([], _previous, total) do
    total
  end

  defp score_cards([card | cards], previous, total) when card == previous + 1 do
    score_cards(cards, card, total)
  end

  defp score_cards([card | cards], _previous, total) do
    score_cards(cards, card, total + card)
  end
end
