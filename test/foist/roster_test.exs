defmodule Foist.RosterTest do
  use ExUnit.Case, async: true
  alias Foist.{Fixtures, Roster}

  describe "add_player/2" do
    test "adds player to roster" do
      roster = Fixtures.roster(2)
      player = Fixtures.player(?C)
      refute player in roster.players

      assert {:ok, roster} = Roster.add_player(roster, player)
      assert player in roster.players
    end

    test "no-op if player already on roster" do
      roster = Fixtures.roster(2)
      player = Fixtures.player(?B)
      assert player in roster.players

      assert {:ok, ^roster} = Roster.add_player(roster, player)
    end

    test "fails if roster full" do
      roster = Fixtures.roster(7)
      player = Fixtures.player(?H)
      refute player in roster.players

      assert Roster.add_player(roster, player) == :full
    end
  end

  describe "member?/2" do
    test "returns true if player on roster" do
      roster = Fixtures.roster(2)
      player = Fixtures.player(?B)
      assert player in roster.players

      assert Roster.member?(roster, player)
    end

    test "returns false if player not on roster" do
      roster = Fixtures.roster(2)
      player = Fixtures.player(?C)
      refute player in roster.players

      refute Roster.member?(roster, player)
    end
  end

  describe "new/0" do
    test "creates an empty roster" do
      assert %Roster{players: []} = Roster.new()
    end

    test "generates a join code for the roster" do
      assert %Roster{join_code: join_code} = Roster.new()
      assert is_binary(join_code)
    end
  end

  describe "owner/1" do
    test "returns the first player on the roster" do
      roster = Fixtures.roster(3)
      player = Fixtures.player(?A)
      assert List.first(roster.players) == player

      assert Roster.owner(roster) == player
    end

    test "returns nil for an empty roster" do
      roster = Fixtures.roster(0)
      assert roster.players == []

      assert Roster.owner(roster) == nil
    end
  end

  describe "remove_player/2" do
    test "removes player from roster" do
      roster = Fixtures.roster(3)
      player = Fixtures.player(?B)
      assert player in roster.players

      assert {:ok, roster} = Roster.remove_player(roster, player)
      refute player in roster.players
    end

    test "no-op if player not on roster" do
      roster = Fixtures.roster(2)
      player = Fixtures.player(?C)
      refute player in roster.players

      assert {:ok, ^roster} = Roster.remove_player(roster, player)
    end

    test "fails if last player remaining" do
      roster = Fixtures.roster(1)
      player = Fixtures.player(?A)
      assert roster.players == [player]

      assert Roster.remove_player(roster, player) == :empty
    end
  end
end
