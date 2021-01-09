defmodule Foist.Player do
  @moduledoc """
  A player has a name and an ID.
  """

  @type id() :: <<_::64>>
  @type t() :: %__MODULE__{id: id(), name: String.t()}

  defstruct [:id, :name]

  @doc """
  Create a player with `name`.
  """
  @spec new(String.t()) :: t()
  def new(name) do
    %__MODULE__{id: generate_id(), name: name}
  end

  @spec generate_id() :: id()
  defp generate_id do
    6
    |> :crypto.strong_rand_bytes()
    |> Base.encode64()
  end
end
