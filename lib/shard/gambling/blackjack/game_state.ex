defmodule Shard.Gambling.Blackjack.GameState do
  @moduledoc """
  Struct representing the in-memory state of a Blackjack game.
  """

  defstruct [
    :game,
    :hands,
    :deck,
    :phase,
    :current_player_index,
    :current_player_id,
    :phase_timer,
    :phase_started_at,
    # Unique reference for the current phase instance
    :phase_ref,
    # List of {target_id, card_visibility}
    :dealing_queue
  ]
end
