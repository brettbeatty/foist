defmodule Foist.LobbyTest do
  use ExUnit.Case, async: true
  alias Foist.{Fixtures, Lobby, Roster}

  describe "join/2" do
    test "adds player to lobby" do
      lobby = Fixtures.lobby(2)
      player = Fixtures.player(?C)
      refute player in lobby.roster.players

      assert {:ok, lobby} = Lobby.join(lobby, player)
      assert player in lobby.roster.players
    end

    test "no-op if player already in lobby" do
      lobby = Fixtures.lobby(7)
      player = Fixtures.player(?A)
      assert player in lobby.roster.players

      assert {:ok, ^lobby} = Lobby.join(lobby, player)
    end

    test "fails if lobby is full" do
      lobby = Fixtures.lobby(7)
      player = Fixtures.player(?H)
      refute player in lobby.roster.players

      assert Lobby.join(lobby, player) == :full
    end
  end

  describe "leave/2" do
    test "removes player from lobby" do
      lobby = Fixtures.lobby(2)
      player = Fixtures.player(?A)
      assert player in lobby.roster.players

      assert {:ok, lobby} = Lobby.leave(lobby, player)
      refute player in lobby.roster.players
    end

    test "no-op if player not in lobby" do
      lobby = Fixtures.lobby(2)
      player = Fixtures.player(?C)
      refute player in lobby.roster.players

      assert {:ok, ^lobby} = Lobby.leave(lobby, player)
    end

    test "fails if last player in lobby" do
      lobby = Fixtures.lobby(1)
      player = Fixtures.player(?A)
      assert lobby.roster.players == [player]

      assert Lobby.leave(lobby, player) == :empty
    end
  end

  describe "new/1" do
    test "holds onto roster" do
      roster = Fixtures.roster(3)

      assert %Lobby{roster: ^roster} = Lobby.new(roster)
    end
  end

  describe "start_game/2" do
    test "returns the roster" do
      lobby = Fixtures.lobby(3)
      player = Fixtures.player(?A)
      assert Roster.owner(lobby.roster) == player

      assert Lobby.start_game(lobby, player) == {:ok, lobby.roster}
    end

    test "fails if too few players" do
      lobby = Fixtures.lobby(2)
      player = Fixtures.player(?A)
      assert Roster.owner(lobby.roster) == player

      assert Lobby.start_game(lobby, player) == :not_enough_players
    end

    test "fails if not first player" do
      lobby = Fixtures.lobby(7)
      player = Fixtures.player(?B)
      assert Roster.owner(lobby.roster) != player

      assert Lobby.start_game(lobby, player) == :not_owner
    end
  end
end
