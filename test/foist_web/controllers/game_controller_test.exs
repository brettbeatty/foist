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
end
