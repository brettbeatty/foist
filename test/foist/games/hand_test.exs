defmodule Foist.Games.HandTest do
  use ExUnit.Case, async: true
  alias Foist.Fixtures
  alias Foist.Games.Hand

  describe "add_card/2" do
    test "adds card to hand" do
      hand = Fixtures.hand(cards: [23, 25])

      hand = Hand.add_card(hand, 24)
      assert hand.cards == [23, 24, 25]
    end
  end

  describe "add_tokens/2" do
    test "adds tokens to hand" do
      hand = Fixtures.hand(tokens: 8)

      hand = Hand.add_tokens(hand, 7)
      assert hand.tokens == 15
    end
  end

  describe "new/1" do
    test "creates a hand with tokens" do
      assert %Hand{tokens: 11} = Hand.new(11)
    end

    test "hand starts with no cards" do
      assert %Hand{cards: []} = Hand.new(9)
    end
  end

  describe "remove_token/1" do
    test "removes token from hand if available" do
      hand = Fixtures.hand(tokens: 2)

      assert {:ok, hand} = Hand.remove_token(hand)
      assert hand.tokens == 1
    end

    test "fails if hand has no tokens" do
      hand = Fixtures.hand(tokens: 0)

      assert Hand.remove_token(hand) == :no_tokens
    end
  end

  describe "score/1" do
    test "adds points for cards" do
      hand = Fixtures.hand(cards: [7, 9], tokens: 0)

      assert Hand.score(hand) == 16
    end

    test "ignores incremented" do
      hand = Fixtures.hand(cards: [7, 8, 9], tokens: 0)

      assert Hand.score(hand) == 7
    end

    test "removes points for tokens" do
      hand = Fixtures.hand(cards: [], tokens: 6)

      assert Hand.score(hand) == -6
    end

    test "cards and tokens factor into score" do
      hand = Fixtures.hand(cards: [3, 4, 5, 7, 8], tokens: 4)

      assert Hand.score(hand) == 6
    end
  end
end
