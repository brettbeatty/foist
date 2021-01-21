defmodule FoistWeb.GameControllerTest do
  use FoistWeb.ConnCase, async: true

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
