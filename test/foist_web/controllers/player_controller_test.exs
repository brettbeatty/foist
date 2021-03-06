defmodule FoistWeb.PlayerControllerTest do
  use FoistWeb.ConnCase, async: true
  alias Foist.{Fixtures, Player}

  describe "create" do
    test "saves player to session", %{conn: conn} do
      params = %{"name" => "Brett"}

      conn = post(conn, Routes.player_path(conn, :create), %{"player_params" => params})

      assert %Player{name: "Brett"} = get_session(conn, "player")
    end

    test "redirects player to game index by default", %{conn: conn} do
      params = %{"name" => "Brett"}

      conn = post(conn, Routes.player_path(conn, :create), %{"player_params" => params})

      assert redirected_to(conn) == Routes.game_path(conn, :index)
    end

    test "honors redirect param", %{conn: conn} do
      params = %{"name" => "Brett", "redirect" => "/games/ABCD"}

      conn = post(conn, Routes.player_path(conn, :create), %{"player_params" => params})

      assert redirected_to(conn) == "/games/ABCD"
    end

    test "fails if name not included", %{conn: conn} do
      params = %{"name" => ""}

      conn = post(conn, Routes.player_path(conn, :create), %{"player_params" => params})

      assert html_response(conn, 200) =~ "can&#39;t be blank"
    end
  end

  describe "new" do
    test "renders a form for entering player's name", %{conn: conn} do
      conn = get(conn, Routes.player_path(conn, :new))

      assert html_response(conn, 200) =~ ">Name</label>"
    end

    test "allows passing a redirect to include in hidden form input", %{conn: conn} do
      conn = get(conn, Routes.player_path(conn, :new), redirect: "/games/ABCD")

      assert html_response(conn, 200) =~ "/games/ABCD"
    end

    test "name input is empty if initial", %{conn: conn} do
      conn = get(conn, Routes.player_path(conn, :new))

      assert html_response(conn, 200) =~ ~S(value="")
    end

    test "name input is populated if already provided", %{conn: conn} do
      conn =
        conn
        |> init_test_session(player: Fixtures.player(?A))
        |> get(Routes.player_path(conn, :new))

      assert html_response(conn, 200) =~ ~S(value="Player A")
    end

    test "cancel button returns to home screen by default", %{conn: conn} do
      conn = get(conn, Routes.player_path(conn, :new))

      assert html_response(conn, 200) =~ Routes.welcome_path(conn, :index)
    end

    test "cancel button returns to game screen if player in session", %{conn: conn} do
      conn =
        conn
        |> init_test_session(player: Fixtures.player(?A))
        |> get(Routes.player_path(conn, :new))

      assert html_response(conn, 200) =~ Routes.game_path(conn, :index)
    end
  end
end
