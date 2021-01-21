defmodule FoistWeb.WelcomeControllerTest do
  use FoistWeb.ConnCase, async: true

  describe "index" do
    test "includes a button to start playing", %{conn: conn} do
      conn = get(conn, Routes.welcome_path(conn, :index))

      assert html_response(conn, 200) =~ ">Play</a>"
    end
  end
end
