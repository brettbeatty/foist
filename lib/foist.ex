defmodule Foist do
  @moduledoc """
  Logic for playing Foist.
  """
  alias Foist.{GameServer, GameSupervisor}

  @type join_code() :: GameServer.join_code()

  @doc """
  Create a game of Foist.
  """
  @spec create_game() :: {:ok, join_code()} | :error
  def create_game do
    case DynamicSupervisor.start_child(GameSupervisor, GameServer) do
      {:ok, pid} ->
        GameServer.fetch_join_code(pid)

      {:error, _error} ->
        :error
    end
  end
end
