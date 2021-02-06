defmodule FoistWeb.WelcomeControllerTest do
  use FoistWeb.ConnCase, async: true

  describe "how_to_play" do
    test "includes a button to start playing", %{conn: conn} do
      conn = get(conn, Routes.welcome_path(conn, :how_to_play))

      assert html_response(conn, 200) =~ ">Play</a>"
    end
  end

  describe "index" do
    test "includes a button to start playing", %{conn: conn} do
      conn = get(conn, Routes.welcome_path(conn, :index))

      assert html_response(conn, 200) =~ ">Play</a>"
    end

    test "includes a button to learn how to play", %{conn: conn} do
      conn = get(conn, Routes.welcome_path(conn, :index))

      assert html_response(conn, 200) =~ ">How to Play</a>"
    end
  end
end
