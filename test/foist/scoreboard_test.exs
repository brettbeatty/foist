defmodule Foist.ScoreboardTest do
  use ExUnit.Case, async: true
  alias Foist.{Fixtures, Scoreboard}

  describe "leave/2" do
    test "removes player from roster" do
      scoreboard = Fixtures.scoreboard(4)
      player = Fixtures.player(?A)
      assert player in scoreboard.roster.players

      assert {:ok, scoreboard} = Scoreboard.leave(scoreboard, player)
      refute player in scoreboard.roster.players
    end

    test "no-op if player not on roster" do
      scoreboard = Fixtures.scoreboard(3)
      player = Fixtures.player(?D)
      refute player in scoreboard.roster.players

      assert {:ok, ^scoreboard} = Scoreboard.leave(scoreboard, player)
    end

    test "fails if last player on roster" do
      scoreboard = Fixtures.scoreboard(1)
      player = Fixtures.player(?A)
      assert scoreboard.roster.players == [player]

      assert Scoreboard.leave(scoreboard, player) == :empty
    end

    test "finishes if all remaining players have opted to play again" do
      scoreboard = Fixtures.scoreboard(3)
      player_a = Fixtures.player(?A)
      player_b = Fixtures.player(?B)
      player_c = Fixtures.player(?C)
      assert scoreboard.roster.players == [player_a, player_b, player_c]
      assert player_b in scoreboard.play_again
      assert player_c in scoreboard.play_again

      assert {:done, roster} = Scoreboard.leave(scoreboard, player_a)
      assert roster.players == [player_b, player_c]
    end
  end

  describe "new/2" do
    test "preserves roster" do
      roster = Fixtures.roster(7)
      hands = Fixtures.hands()

      assert %Scoreboard{roster: ^roster} = Scoreboard.new(roster, hands)
    end

    test "scores hands" do
      roster = Fixtures.roster(7)
      hands = Fixtures.hands()

      assert %Scoreboard{scores: scores} = Scoreboard.new(roster, hands)

      expected = [
        {Fixtures.player(?F), -1},
        {Fixtures.player(?B), 6},
        {Fixtures.player(?D), 26},
        {Fixtures.player(?A), 27},
        {Fixtures.player(?G), 33},
        {Fixtures.player(?E), 35},
        {Fixtures.player(?C), 74}
      ]

      assert scores == expected
    end

    test "creates an empty set of players opting to play again" do
      roster = Fixtures.roster(7)
      hands = Fixtures.hands()

      assert %Scoreboard{play_again: play_again} = Scoreboard.new(roster, hands)
      assert play_again == MapSet.new()
    end
  end

  describe "play_again/2" do
    test "adds player to set of players opting to play again" do
      scoreboard = Fixtures.scoreboard(4)
      player = Fixtures.player(?A)
      refute player in scoreboard.play_again

      assert {:ok, scoreboard} = Scoreboard.play_again(scoreboard, player)
      assert player in scoreboard.play_again
    end

    test "no-op if player has already opted to play again" do
      scoreboard = Fixtures.scoreboard(4)
      player = Fixtures.player(?B)
      assert player in scoreboard.play_again

      assert {:ok, ^scoreboard} = Scoreboard.play_again(scoreboard, player)
    end

    test "finishes if all remaining players have opted to play again" do
      scoreboard = Fixtures.scoreboard(3)
      player_a = Fixtures.player(?A)
      player_b = Fixtures.player(?B)
      player_c = Fixtures.player(?C)
      assert scoreboard.roster.players == [player_a, player_b, player_c]
      assert player_b in scoreboard.play_again
      assert player_c in scoreboard.play_again

      assert {:done, roster} = Scoreboard.play_again(scoreboard, player_a)
      assert roster.players == [player_a, player_b, player_c]
    end
  end

  describe "rejoin/2" do
    test "succeeds if player on roster" do
      game = Fixtures.scoreboard(2)
      player = Fixtures.player(?A)
      assert player in game.roster.players

      assert Scoreboard.rejoin(game, player) == :ok
    end

    test "fails if player not on roster" do
      game = Fixtures.scoreboard(2)
      player = Fixtures.player(?H)
      refute player in game.roster.players

      assert Scoreboard.rejoin(game, player) == :error
    end
  end
end
