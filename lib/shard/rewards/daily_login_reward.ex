defmodule Shard.Rewards.DailyLoginReward do
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Users.User

  schema "daily_login_rewards" do
    field :last_claim_date, :date
    field :streak_count, :integer, default: 1
    field :total_claims, :integer, default: 1

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(daily_login_reward, attrs) do
    daily_login_reward
    |> cast(attrs, [:user_id, :last_claim_date, :streak_count, :total_claims])
    |> validate_required([:user_id, :last_claim_date, :streak_count, :total_claims])
    |> validate_number(:streak_count, greater_than: 0)
    |> validate_number(:total_claims, greater_than: 0)
    |> unique_constraint(:user_id)
  end
end
