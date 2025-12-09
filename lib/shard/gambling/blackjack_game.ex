defmodule Shard.Gambling.BlackjackGame do
  @moduledoc """
  Schema for blackjack games.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Gambling.BlackjackHand

  schema "blackjack_games" do
    field :game_id, :string
    field :status, :string, default: "waiting"
    field :dealer_hand, {:array, :map}
    field :current_player_index, :integer, default: 0
    field :round_started_at, :utc_datetime
    field :max_players, :integer, default: 6

    has_many :hands, BlackjackHand

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [
      :game_id,
      :status,
      :dealer_hand,
      :current_player_index,
      :round_started_at,
      :max_players
    ])
    |> validate_required([:game_id])
    |> validate_inclusion(:status, ["waiting", "betting", "playing", "dealer_turn", "finished"])
    |> validate_number(:max_players, greater_than: 0, less_than_or_equal_to: 6)
    |> unique_constraint(:game_id)
  end
end
