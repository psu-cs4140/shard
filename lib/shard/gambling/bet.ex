defmodule Shard.Gambling.Bet do
  @moduledoc """
  Schema for coin flip bets.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Characters.Character

  schema "coin_flip_bets" do
    field :flip_id, :string
    field :amount, :integer
    field :prediction, :string
    field :result, :string, default: "pending"
    field :payout, :integer, default: 0

    belongs_to :character, Character

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bet, attrs) do
    bet
    |> cast(attrs, [:character_id, :flip_id, :amount, :prediction, :result, :payout])
    |> validate_required([:character_id, :flip_id, :amount, :prediction])
    |> validate_number(:amount, greater_than: 0)
    |> validate_inclusion(:prediction, ["heads", "tails"])
    |> validate_inclusion(:result, ["pending", "won", "lost"])
  end
end
