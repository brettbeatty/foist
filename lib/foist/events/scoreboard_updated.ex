defmodule Foist.Events.ScoreboardUpdated do
  @moduledoc """
  Broadcast when scoreboard is updated.
  """
  alias Foist.{Player, Roster, Scoreboard}

  @type score() :: %{name: String.t(), play_again: :yes | :no | :maybe, score: integer()}
  @type t() :: %__MODULE__{scores: [score()]}

  defstruct [:scores]

  @doc """
  Create a ScoreboardCreated event.
  """
  @spec new(Scoreboard.t()) :: t()
  def new(%Scoreboard{play_again: play_again, roster: %Roster{players: players}, scores: scores}) do
    scores =
      for {player = %Player{name: name}, score} <- scores do
        playing_again =
          cond do
            player not in players ->
              :no

            player in play_again ->
              :yes

            true ->
              :maybe
          end

        %{name: name, play_again: playing_again, score: score}
      end

    %__MODULE__{scores: scores}
  end
end
