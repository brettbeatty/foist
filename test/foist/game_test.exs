defmodule Foist.GameTest do
  use ExUnit.Case, async: true
  alias Foist.{Fixtures, Game, Hand}

  defp player_turn?(%Game{turn: turn, turn_order: turn_order}, player) do
    elem(turn_order, turn) == player
  end

  describe "new/1" do
    test "puts a card in the middle" do
      roster = Fixtures.roster(3)

      assert %Game{card: card} = Game.new(roster)
      assert card in 3..35
    end

    test "shuffles deck and discards 9 for total of 23 (with one already in focus)" do
      roster = Fixtures.roster(3)

      assert %Game{deck: deck} = Game.new(roster)
      assert length(deck) == 23
      assert Enum.all?(deck, fn card -> card in 3..35 end)
    end

    test "creates a hand for every player" do
      roster = Fixtures.roster(3)

      assert %Game{hands: hands} = Game.new(roster)
      assert MapSet.new(Map.keys(hands)) == MapSet.new(roster.players)
    end

    test "gives 11 tokens to each of 3 players" do
      roster = Fixtures.roster(3)

      assert %Game{hands: hands} = Game.new(roster)
      assert Enum.all?(hands, fn {_player, hand} -> hand.tokens == 11 end)
    end

    test "gives 11 tokens to each of 4 players" do
      roster = Fixtures.roster(4)

      assert %Game{hands: hands} = Game.new(roster)
      assert Enum.all?(hands, fn {_player, hand} -> hand.tokens == 11 end)
    end

    test "gives 11 tokens to each of 5 players" do
      roster = Fixtures.roster(5)

      assert %Game{hands: hands} = Game.new(roster)
      assert Enum.all?(hands, fn {_player, hand} -> hand.tokens == 11 end)
    end

    test "gives 9 tokens to each of 6 players" do
      roster = Fixtures.roster(6)

      assert %Game{hands: hands} = Game.new(roster)
      assert Enum.all?(hands, fn {_player, hand} -> hand.tokens == 9 end)
    end

    test "gives 7 tokens to each of 7 players" do
      roster = Fixtures.roster(7)

      assert %Game{hands: hands} = Game.new(roster)
      assert Enum.all?(hands, fn {_player, hand} -> hand.tokens == 7 end)
    end

    test "holds onto roster as is" do
      roster = Fixtures.roster(3)

      assert %Game{roster: ^roster} = Game.new(roster)
    end

    test "starts with 0 tokens on card in focus" do
      roster = Fixtures.roster(3)

      assert %Game{tokens: 0} = Game.new(roster)
    end

    test "starts on turn 0" do
      roster = Fixtures.roster(3)

      assert %Game{turn: 0} = Game.new(roster)
    end

    test "turn order includes players from roster" do
      roster = Fixtures.roster(3)

      assert %Game{turn_order: turn_order} = Game.new(roster)
      assert MapSet.new(Tuple.to_list(turn_order)) == MapSet.new(roster.players)
    end
  end

  describe "place_token/2" do
    test "places a token on card" do
      game = Fixtures.game()
      player = Fixtures.player(?A)
      assert game.tokens == 2

      assert {:ok, game} = Game.place_token(game, player)
      assert game.tokens == 3
    end

    test "removes token from player's hand" do
      game = Fixtures.game()
      player = Fixtures.player(?A)
      assert game.hands[player].tokens == 1

      assert {:ok, game} = Game.place_token(game, player)
      assert game.hands[player].tokens == 0
    end

    test "advances the turn" do
      game = Fixtures.game()
      player = Fixtures.player(?A)
      assert player_turn?(game, player)

      assert {:ok, game} = Game.place_token(game, player)
      assert player_turn?(game, Fixtures.player(?C))
    end

    test "starts turn order over if on last turn" do
      game = Fixtures.game(turn: 6)
      player = Fixtures.player(?D)
      assert player_turn?(game, player)

      assert {:ok, game} = Game.place_token(game, player)
      assert player_turn?(game, Fixtures.player(?E))
    end

    test "fails if not player's turn" do
      game = Fixtures.game()
      player = Fixtures.player(?B)
      refute player_turn?(game, player)

      assert Game.place_token(game, player) == :not_turn
    end

    test "fails if player has no tokens" do
      game = Fixtures.game(turn: 1)
      player = Fixtures.player(?G)
      assert player_turn?(game, player)
      assert game.hands[player].tokens == 0

      assert Game.place_token(game, player) == :no_tokens
    end
  end

  describe "take_card/2" do
    test "puts card in player's hand" do
      game = Fixtures.game()
      player = Fixtures.player(?A)
      card = game.card
      refute card in game.hands[player].cards

      assert {:ok, game} = Game.take_card(game, player)
      assert card in game.hands[player].cards
    end

    test "puts tokens in player's hand" do
      game = Fixtures.game()
      player = Fixtures.player(?A)
      assert game.hands[player].tokens == 1

      assert {:ok, game} = Game.take_card(game, player)
      assert game.hands[player].tokens == 3
    end

    test "puts new card from deck in focus" do
      game = Fixtures.game()
      player = Fixtures.player(?A)
      assert [card | deck] = game.deck

      assert {:ok, game} = Game.take_card(game, player)
      assert game.card == card
      assert game.deck == deck
    end

    test "resets tokens" do
      game = Fixtures.game()
      player = Fixtures.player(?A)
      assert game.tokens == 2

      assert {:ok, game} = Game.take_card(game, player)
      assert game.tokens == 0
    end

    test "advances the turn" do
      game = Fixtures.game()
      player = Fixtures.player(?A)
      assert player_turn?(game, player)

      assert {:ok, game} = Game.take_card(game, player)
      assert player_turn?(game, Fixtures.player(?C))
    end

    test "starts turn order over if on last turn" do
      game = Fixtures.game(turn: 6)
      player = Fixtures.player(?D)
      assert player_turn?(game, player)

      assert {:ok, game} = Game.take_card(game, player)
      assert player_turn?(game, Fixtures.player(?E))
    end

    test "fails if not player's turn" do
      game = Fixtures.game()
      player = Fixtures.player(?B)
      refute player_turn?(game, player)

      assert Game.take_card(game, player) == :not_turn
    end

    test "returns {:done, hands} if game finished" do
      game = Fixtures.game(deck: [])
      player = Fixtures.player(?A)

      assert {:done, hands} = Game.take_card(game, player)

      expected = %{game.hands | player => %Hand{cards: [4, 5, 27], tokens: 3}}
      assert hands == expected
    end
  end
end
