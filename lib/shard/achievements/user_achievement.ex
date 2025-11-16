defmodule Shard.Achievements.UserAchievement do
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Users.User
  alias Shard.Achievements.Achievement

  schema "user_achievements" do
    belongs_to :user, User
    belongs_to :achievement, Achievement
    field :earned_at, :utc_datetime
    field :progress, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_achievement, attrs) do
    user_achievement
    |> cast(attrs, [:user_id, :achievement_id, :earned_at, :progress])
    |> validate_required([:user_id, :achievement_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:achievement_id)
    |> unique_constraint([:user_id, :achievement_id])
  end
end
