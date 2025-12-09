defmodule Shard.Gambling.BlackjackHand do
  @moduledoc """
  Schema for individual blackjack hands within a game.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Gambling.BlackjackGame
  alias Shard.Characters.Character

  schema "blackjack_hands" do
    field :position, :integer
    field :hand_cards, {:array, :map}
    field :bet_amount, :integer, default: 0
    field :status, :string, default: "betting"
    field :outcome, :string, default: "pending"
    field :payout, :integer, default: 0

    belongs_to :blackjack_game, BlackjackGame
    belongs_to :character, Character

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(hand, attrs) do
    hand
    |> cast(attrs, [
      :blackjack_game_id,
      :character_id,
      :position,
      :hand_cards,
      :bet_amount,
      :status,
      :outcome,
      :payout
    ])
    |> validate_required([:blackjack_game_id, :character_id, :position])
    |> validate_inclusion(:status, [
      "betting",
      "playing",
      "stood",
      "busted",
      "blackjack",
      "surrendered",
      "folded"
    ])
    |> validate_inclusion(:outcome, ["pending", "won", "lost", "push", "blackjack_win"])
    |> validate_number(:bet_amount, greater_than_or_equal_to: 0)
    |> validate_number(:position, greater_than: 0, less_than_or_equal_to: 6)
    |> validate_number(:payout, greater_than_or_equal_to: 0)
    |> unique_constraint([:blackjack_game_id, :position])
    |> unique_constraint([:blackjack_game_id, :character_id])
  end
end
