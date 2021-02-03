defmodule Foist.GameServerTest do
  use ExUnit.Case, async: true
  alias Foist.{Fixtures, Game, GameRegistry, GameServer, Lobby, Scoreboard}
  alias Foist.Events.{GameUpdated, LobbyUpdated, ScoreboardUpdated, TokensDivvied}

  @spec get_state(GameServer.join_code()) :: GameServer.state()
  defp get_state(join_code) do
    :sys.get_state({:via, Registry, {GameRegistry, join_code}})
  end

  @spec start_server!() :: GameServer.join_code()
  defp start_server! do
    pid = start_supervised!(GameServer)
    {:ok, join_code} = GameServer.fetch_join_code(pid)
    :ok = Phoenix.PubSub.subscribe(Foist.PubSub, join_code)

    join_code
  end

  defp start_server!(state) do
    join_code = start_server!()

    state = Map.update!(state, :roster, &Map.put(&1, :join_code, join_code))

    :sys.replace_state({:via, Registry, {GameRegistry, join_code}}, fn _state -> state end)

    join_code
  end

  describe "fetch_join_code/1" do
    test "fetches join code from a game server" do
      pid = start_supervised!(GameServer)

      assert {:ok, join_code} = GameServer.fetch_join_code(pid)
      assert Registry.lookup(GameRegistry, join_code) == [{pid, nil}]
    end

    test "fails if process not a game server" do
      assert GameServer.fetch_join_code(self()) == :error
    end
  end

  describe "init/1" do
    test "starts game server in lobby" do
      pid = start_supervised!(GameServer)

      assert %Lobby{} = :sys.get_state(pid)
    end
  end

  describe "join/2" do
    test "adds player to lobby" do
      join_code = start_server!()
      player = Fixtures.player(?A)
      refute player in get_state(join_code).roster.players

      assert GameServer.join(join_code, player) == :ok
      assert player in get_state(join_code).roster.players
    end

    test "allows player to rejoin game" do
      join_code = start_server!(Fixtures.game())
      player = Fixtures.player(?A)
      assert player in get_state(join_code).roster.players

      assert GameServer.join(join_code, player) == :ok
      assert_received %GameUpdated{}
      assert_received %TokensDivvied{}
    end

    test "allows player to rejoin lobby" do
      join_code = start_server!(Fixtures.lobby(7))
      player = Fixtures.player(?A)
      assert player in get_state(join_code).roster.players

      assert GameServer.join(join_code, player) == :ok
      assert_received %LobbyUpdated{}
    end

    test "allows player to rejoin scoreboard" do
      join_code = start_server!(Fixtures.scoreboard(7))
      player = Fixtures.player(?A)
      assert player in get_state(join_code).roster.players

      assert GameServer.join(join_code, player) == :ok
      assert_received %ScoreboardUpdated{}
    end

    test "subscribes to join_code topic" do
      join_code = start_server!(Fixtures.lobby(7))
      player = Fixtures.player(?A)
      Phoenix.PubSub.unsubscribe(Foist.PubSub, join_code)

      ref = make_ref()
      Phoenix.PubSub.broadcast!(Foist.PubSub, join_code, ref)
      refute_receive ^ref

      assert GameServer.join(join_code, player) == :ok

      ref = make_ref()
      Phoenix.PubSub.broadcast!(Foist.PubSub, join_code, ref)
      assert_receive ^ref
    end

    test "broadcasts lobby update" do
      join_code = start_server!(Fixtures.lobby(2))
      player = Fixtures.player(?C)

      assert GameServer.join(join_code, player) == :ok

      assert_receive %LobbyUpdated{players: players}
      assert player in players
    end

    test "fails if lobby full" do
      join_code = start_server!(Fixtures.lobby(7))
      player = Fixtures.player(?H)
      refute player in get_state(join_code).roster.players

      assert GameServer.join(join_code, player) == :full
    end

    test "fails if game already started (game)" do
      join_code = start_server!(Fixtures.game())
      player = Fixtures.player(?H)

      assert GameServer.join(join_code, player) == :already_started
    end

    test "fails if game already started (scoreboard)" do
      join_code = start_server!(Fixtures.scoreboard(3))
      player = Fixtures.player(?H)

      assert GameServer.join(join_code, player) == :already_started
    end

    test "fails if still on scoreboard" do
      join_code = start_server!(Fixtures.scoreboard(3))
      player = Fixtures.player(?D)

      assert GameServer.join(join_code, player) == :already_started
    end

    test "fails if join code not in use" do
      player = Fixtures.player(?A)

      assert GameServer.join("ABCD", player) == :not_found
    end
  end

  describe "leave/2" do
    test "removes player from lobby" do
      join_code = start_server!(Fixtures.lobby(3))
      player = Fixtures.player(?A)
      assert player in get_state(join_code).roster.players

      assert GameServer.leave(join_code, player) == :ok
      refute player in get_state(join_code).roster.players
    end

    test "removes player from roster at scoreboard" do
      join_code = start_server!(Fixtures.scoreboard(3))
      player = Fixtures.player(?A)
      assert player in get_state(join_code).roster.players

      assert GameServer.leave(join_code, player) == :ok
      refute player in get_state(join_code).roster.players
    end

    test "advances to lobby (from scoreboard) if remaining players staying" do
      join_code = start_server!(Fixtures.scoreboard(3))
      player = Fixtures.player(?A)
      assert %Scoreboard{} = get_state(join_code)

      assert GameServer.leave(join_code, player) == :ok
      assert %Lobby{} = get_state(join_code)
    end

    test "unsubscribes from join_code topic" do
      join_code = start_server!(Fixtures.lobby(7))
      player = Fixtures.player(?A)

      ref = make_ref()
      Phoenix.PubSub.broadcast!(Foist.PubSub, join_code, ref)
      assert_receive ^ref

      assert GameServer.leave(join_code, player) == :ok

      ref = make_ref()
      Phoenix.PubSub.broadcast!(Foist.PubSub, join_code, ref)
      refute_receive ^ref
    end

    test "broadcasts lobby update" do
      join_code = start_server!(Fixtures.lobby(2))
      player = Fixtures.player(?A)

      # so the test process isn't unsubscribed from the topic
      spawn(GameServer, :leave, [join_code, player])

      assert_receive %LobbyUpdated{players: players}
      refute player in players
    end

    test "broadcasts lobby update (coming from scoreboard)" do
      join_code = start_server!(Fixtures.scoreboard(3))
      player = Fixtures.player(?A)

      # so the test process isn't unsubscribed from the topic
      spawn(GameServer, :leave, [join_code, player])

      assert_receive %LobbyUpdated{players: players}
      refute player in players
    end

    test "broadcasts scoreboard update" do
      join_code = start_server!(Fixtures.scoreboard(4))
      player = Fixtures.player(?A)

      # so the test process isn't unsubscribed from the topic
      spawn(GameServer, :leave, [join_code, player])

      expected_scores = [
        %{name: "Player F", play_again: :no, score: -1},
        %{name: "Player B", play_again: :yes, score: 6},
        %{name: "Player D", play_again: :maybe, score: 26},
        %{name: "Player A", play_again: :no, score: 27},
        %{name: "Player G", play_again: :no, score: 33},
        %{name: "Player E", play_again: :no, score: 35},
        %{name: "Player C", play_again: :yes, score: 74}
      ]

      assert_receive %ScoreboardUpdated{scores: scores}
      assert scores == expected_scores
    end

    test "fails if game already started" do
      join_code = start_server!(Fixtures.game())
      player = Fixtures.player(?A)

      assert GameServer.leave(join_code, player) == :already_started
    end

    test "shuts down server if last to leave (lobby)" do
      join_code = start_server!(Fixtures.lobby(1))
      player = Fixtures.player(?A)
      assert [{pid, nil}] = Registry.lookup(GameRegistry, join_code)
      ref = Process.monitor(pid)

      assert GameServer.leave(join_code, player) == :ok
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    end

    test "shuts down server if last to leave (scoreboard)" do
      join_code = start_server!(Fixtures.scoreboard(1))
      player = Fixtures.player(?A)
      assert [{pid, nil}] = Registry.lookup(GameRegistry, join_code)
      ref = Process.monitor(pid)

      assert GameServer.leave(join_code, player) == :ok
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    end
  end

  describe "place_token/2" do
    test "returns tokens remaining" do
      join_code = start_server!(Fixtures.game())
      player = Fixtures.player(?A)

      assert GameServer.place_token(join_code, player) == {:ok, 0}
    end

    test "broadcasts a GameUpdated event" do
      join_code = start_server!(Fixtures.game())
      player = Fixtures.player(?A)

      assert {:ok, _tokens} = GameServer.place_token(join_code, player)
      assert_receive %GameUpdated{tokens: 3}
    end

    test "fails if not player's turn" do
      join_code = start_server!(Fixtures.game())
      player = Fixtures.player(?B)

      assert GameServer.place_token(join_code, player) == :not_turn
    end

    test "fails if player has no tokens" do
      join_code = start_server!(Fixtures.game(turn: 1))
      player = Fixtures.player(?G)

      assert GameServer.place_token(join_code, player) == :no_tokens
    end
  end

  describe "play_again/2" do
    test "opts to play again" do
      join_code = start_server!(Fixtures.scoreboard(4))
      player = Fixtures.player(?A)
      refute player in get_state(join_code).play_again

      assert GameServer.play_again(join_code, player) == :ok
      assert player in get_state(join_code).play_again
    end

    test "advances to lobby if all remaining are playing again" do
      join_code = start_server!(Fixtures.scoreboard(3))
      player = Fixtures.player(?A)
      assert %Scoreboard{} = get_state(join_code)

      assert GameServer.play_again(join_code, player)
      assert %Lobby{} = get_state(join_code)
    end

    test "broadcasts lobby update (coming from scoreboard)" do
      join_code = start_server!(Fixtures.scoreboard(3))
      player = Fixtures.player(?A)

      assert GameServer.play_again(join_code, player) == :ok

      assert_receive %LobbyUpdated{players: players}
      assert player in players
    end

    test "broadcasts scoreboard update" do
      join_code = start_server!(Fixtures.scoreboard(4))
      player = Fixtures.player(?A)

      assert GameServer.play_again(join_code, player) == :ok

      expected_scores = [
        %{name: "Player F", play_again: :no, score: -1},
        %{name: "Player B", play_again: :yes, score: 6},
        %{name: "Player D", play_again: :maybe, score: 26},
        %{name: "Player A", play_again: :yes, score: 27},
        %{name: "Player G", play_again: :no, score: 33},
        %{name: "Player E", play_again: :no, score: 35},
        %{name: "Player C", play_again: :yes, score: 74}
      ]

      assert_receive %ScoreboardUpdated{scores: scores}
      assert scores == expected_scores
    end

    test "fails if not on scoreboard" do
      join_code = start_server!(Fixtures.lobby(3))
      player = Fixtures.player(?A)

      assert GameServer.play_again(join_code, player) == :not_scoreboard
    end
  end

  describe "start_game/2" do
    test "moves state from lobby to game" do
      join_code = start_server!(Fixtures.lobby(3))
      player = Fixtures.player(?A)
      assert %Lobby{} = get_state(join_code)

      assert GameServer.start_game(join_code, player) == :ok
      assert %Game{} = get_state(join_code)
    end

    test "broadcasts a GameUpdated event" do
      join_code = start_server!(Fixtures.lobby(3))
      player = Fixtures.player(?A)

      assert GameServer.start_game(join_code, player) == :ok
      assert_receive %GameUpdated{}
    end

    test "broadcasts a TokensDivvied event" do
      join_code = start_server!(Fixtures.lobby(3))
      player = Fixtures.player(?A)

      assert GameServer.start_game(join_code, player) == :ok
      assert_receive %TokensDivvied{tokens: 11}
    end

    test "fails if game already started" do
      join_code = start_server!(Fixtures.game())
      player = Fixtures.player(?A)

      assert GameServer.start_game(join_code, player) == :already_started
    end

    test "fails if on scoreboard" do
      join_code = start_server!(Fixtures.scoreboard(3))
      player = Fixtures.player(?A)

      assert GameServer.start_game(join_code, player) == :already_started
    end

    test "fails if not owner" do
      join_code = start_server!(Fixtures.lobby(3))
      player = Fixtures.player(?B)
      assert List.first(get_state(join_code).roster.players) != player

      assert GameServer.start_game(join_code, player) == :not_owner
    end

    test "fails if fewer than 3 players" do
      join_code = start_server!(Fixtures.lobby(2))
      player = Fixtures.player(?A)

      assert GameServer.start_game(join_code, player) == :not_enough_players
    end
  end

  describe "take_card/2" do
    test "returns player's updated token count" do
      join_code = start_server!(Fixtures.game())
      player = Fixtures.player(?A)

      assert GameServer.take_card(join_code, player) == {:ok, 3}
    end

    test "broadcasts a GameUpdated event" do
      join_code = start_server!(Fixtures.game())
      player = Fixtures.player(?A)

      expected_hands = [
        %{cards: [lone: 21], name: "Player E", turn?: false},
        %{cards: [lone: 34], name: "Player G", turn?: false},
        %{cards: [low: 32, high: 33], name: "Player F", turn?: false},
        %{cards: [low: 4, high: 5, lone: 27], name: "Player A", turn?: true},
        %{cards: [lone: 23, low: 25, high: 26, lone: 29], name: "Player C", turn?: false},
        %{cards: [low: 6, mid: 7, mid: 8, mid: 9, high: 10], name: "Player B", turn?: false},
        %{cards: [lone: 16], name: "Player D", turn?: false}
      ]

      assert {:ok, _tokens} = GameServer.take_card(join_code, player)
      assert_receive event = %GameUpdated{}
      assert event.card == 30
      assert event.deck_size == 6
      assert event.hands == expected_hands
      assert event.turn == Fixtures.player(?A)
    end

    test "advances to scoreboard if game finishes" do
      join_code = start_server!(Fixtures.game(deck: []))
      player = Fixtures.player(?A)

      assert {:ok, _tokens} = GameServer.take_card(join_code, player)
      assert %Scoreboard{} = get_state(join_code)
    end

    test "broadcasts a ScoreboardUpdated event if game finishes" do
      join_code = start_server!(Fixtures.game(deck: []))
      player = Fixtures.player(?A)

      expected_scores = [
        %{name: "Player F", play_again: :maybe, score: -4},
        %{name: "Player B", play_again: :maybe, score: 5},
        %{name: "Player D", play_again: :maybe, score: 11},
        %{name: "Player E", play_again: :maybe, score: 20},
        %{name: "Player A", play_again: :maybe, score: 28},
        %{name: "Player G", play_again: :maybe, score: 34},
        %{name: "Player C", play_again: :maybe, score: 74}
      ]

      assert {:ok, _tokens} = GameServer.take_card(join_code, player)
      assert_received %ScoreboardUpdated{scores: scores}
      assert scores == expected_scores
    end

    test "fails if not player's turn" do
      join_code = start_server!(Fixtures.game())
      player = Fixtures.player(?B)

      assert GameServer.take_card(join_code, player) == :not_turn
    end
  end
end
