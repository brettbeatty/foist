defmodule FoistWeb.GameControllerTest do
  use FoistWeb.ConnCase, async: true
  alias Foist.GameRegistry

  describe "create" do
    test "redirects to game", %{conn: conn} do
      conn = post(conn, Routes.game_path(conn, :create))

      assert "/games/" <> join_code = redirected_to(conn)
      assert [{_pid, nil}] = Registry.lookup(GameRegistry, join_code)
    end
  end

  describe "index" do
    test "includes a join game button", %{conn: conn} do
      conn = get(conn, Routes.game_path(conn, :index))

      assert html_response(conn, 200) =~ ">Join Game</a>"
    end

    test "includes a create game button", %{conn: conn} do
      conn = get(conn, Routes.game_path(conn, :index))

      assert html_response(conn, 200) =~ ">Create Game</a>"
    end
  end

  describe "join_code" do
    test "renders a form for entering join code", %{conn: conn} do
      conn = get(conn, Routes.game_path(conn, :join_code))

      assert html_response(conn, 200) =~ ">Join code</label>"
    end
  end

  describe "join" do
    test "redirects to game", %{conn: conn} do
      params = %{"join_code" => "ABCD"}
      conn = post(conn, Routes.game_path(conn, :join, %{"join_params" => params}))

      assert redirected_to(conn) == Routes.game_path(conn, :show, "ABCD")
    end

    test "upcases join code", %{conn: conn} do
      params = %{"join_code" => "defg"}
      conn = post(conn, Routes.game_path(conn, :join, %{"join_params" => params}))

      assert redirected_to(conn) == Routes.game_path(conn, :show, "DEFG")
    end

    test "fails if join code blank", %{conn: conn} do
      params = %{"join_code" => ""}
      conn = post(conn, Routes.game_path(conn, :join, %{"join_params" => params}))

      assert html_response(conn, 200) =~ "can&#39;t be blank"
    end

    test "fails if join code more than 4 characters", %{conn: conn} do
      params = %{"join_code" => "ABCDE"}
      conn = post(conn, Routes.game_path(conn, :join, %{"join_params" => params}))

      assert html_response(conn, 200) =~ "should be 4 character(s)"
    end

    test "fails if join code less than 4 characters", %{conn: conn} do
      params = %{"join_code" => "ABC"}
      conn = post(conn, Routes.game_path(conn, :join, %{"join_params" => params}))

      assert html_response(conn, 200) =~ "should be 4 character(s)"
    end
  end
end
