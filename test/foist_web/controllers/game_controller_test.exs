defmodule FoistWeb.GameControllerTest do
  use FoistWeb.ConnCase, async: true
  alias Foist.{Fixtures, GameRegistry}

  describe "create" do
    test "redirects to game", %{conn: conn} do
      conn =
        conn
        |> init_test_session(player: Fixtures.player(?A))
        |> post(Routes.game_path(conn, :create))

      assert "/games/" <> join_code = redirected_to(conn)
      assert [{_pid, nil}] = Registry.lookup(GameRegistry, join_code)
    end

    test "redirects if player not signed in", %{conn: conn} do
      route = Routes.game_path(conn, :create)

      uri =
        conn
        |> post(route)
        |> redirected_to()
        |> URI.parse()

      assert uri.path == Routes.player_path(conn, :new)
      assert URI.decode_query(uri.query) == %{"redirect" => route}
    end
  end

  describe "index" do
    test "includes a join game button", %{conn: conn} do
      conn =
        conn
        |> init_test_session(player: Fixtures.player(?A))
        |> get(Routes.game_path(conn, :index))

      assert html_response(conn, 200) =~ ">Join Game</a>"
    end

    test "includes a create game button", %{conn: conn} do
      conn =
        conn
        |> init_test_session(player: Fixtures.player(?A))
        |> get(Routes.game_path(conn, :index))

      assert html_response(conn, 200) =~ ">Create Game</a>"
    end

    test "includes a change name button", %{conn: conn} do
      conn =
        conn
        |> init_test_session(player: Fixtures.player(?A))
        |> get(Routes.game_path(conn, :index))

      assert html_response(conn, 200) =~ ">Change Name</a>"
    end

    test "includes a button to learn how to play", %{conn: conn} do
      conn =
        conn
        |> init_test_session(player: Fixtures.player(?A))
        |> get(Routes.game_path(conn, :index))

      assert html_response(conn, 200) =~ ">How to Play</a>"
    end

    test "redirects if player not signed in", %{conn: conn} do
      route = Routes.game_path(conn, :index)

      uri =
        conn
        |> get(route)
        |> redirected_to()
        |> URI.parse()

      assert uri.path == Routes.player_path(conn, :new)
      assert URI.decode_query(uri.query) == %{"redirect" => route}
    end
  end

  describe "join_code" do
    test "renders a form for entering join code", %{conn: conn} do
      conn =
        conn
        |> init_test_session(player: Fixtures.player(?A))
        |> get(Routes.game_path(conn, :join_code))

      assert html_response(conn, 200) =~ ">Join code</label>"
    end

    test "redirects if player not signed in", %{conn: conn} do
      route = Routes.game_path(conn, :join_code)

      uri =
        conn
        |> get(route)
        |> redirected_to()
        |> URI.parse()

      assert uri.path == Routes.player_path(conn, :new)
      assert URI.decode_query(uri.query) == %{"redirect" => route}
    end
  end

  describe "join" do
    test "redirects to game", %{conn: conn} do
      params = %{"join_code" => "ABCD"}

      conn =
        conn
        |> init_test_session(player: Fixtures.player(?A))
        |> post(Routes.game_path(conn, :join), %{"join_params" => params})

      assert redirected_to(conn) == Routes.game_path(conn, :show, "ABCD")
    end

    test "upcases join code", %{conn: conn} do
      params = %{"join_code" => "defg"}

      conn =
        conn
        |> init_test_session(player: Fixtures.player(?A))
        |> post(Routes.game_path(conn, :join), %{"join_params" => params})

      assert redirected_to(conn) == Routes.game_path(conn, :show, "DEFG")
    end

    test "fails if join code blank", %{conn: conn} do
      params = %{"join_code" => ""}

      conn =
        conn
        |> init_test_session(player: Fixtures.player(?A))
        |> post(Routes.game_path(conn, :join), %{"join_params" => params})

      assert html_response(conn, 200) =~ "can&#39;t be blank"
    end

    test "fails if join code more than 4 characters", %{conn: conn} do
      params = %{"join_code" => "ABCDE"}

      conn =
        conn
        |> init_test_session(player: Fixtures.player(?A))
        |> post(Routes.game_path(conn, :join), %{"join_params" => params})

      assert html_response(conn, 200) =~ "should be 4 character(s)"
    end

    test "fails if join code less than 4 characters", %{conn: conn} do
      params = %{"join_code" => "ABC"}

      conn =
        conn
        |> init_test_session(player: Fixtures.player(?A))
        |> post(Routes.game_path(conn, :join), %{"join_params" => params})

      assert html_response(conn, 200) =~ "should be 4 character(s)"
    end

    test "redirects if player not signed in", %{conn: conn} do
      route = Routes.game_path(conn, :join)

      uri =
        conn
        |> post(route, %{"join_params" => %{"join_code" => "ABCD"}})
        |> redirected_to()
        |> URI.parse()

      assert uri.path == Routes.player_path(conn, :new)
      assert URI.decode_query(uri.query) == %{"redirect" => route}
    end
  end
end
