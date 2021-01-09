defmodule Foist.PlayerTest do
  use ExUnit.Case, async: true
  alias Foist.Player

  describe "new/1" do
    test "creates player with name" do
      assert %Player{name: "Brett"} = Player.new("Brett")
    end

    test "generates an ID for player" do
      assert %Player{id: id} = Player.new("Brett")
      assert is_binary(id)
    end
  end
end
