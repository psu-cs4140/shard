defmodule Shard.Users.UserZoneProgress do
  @moduledoc """
  Tracks a user's progress through different zones in the game.
  
  Progress states:
  - "locked" - Zone is not yet accessible to the user
  - "in_progress" - Zone is accessible and user has started exploring
  - "completed" - User has completed all objectives in the zone
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_zone_progress" do
    field :progress, :string, default: "locked"
    
    belongs_to :user, Shard.Users.User
    belongs_to :zone, Shard.Map.Zone

    timestamps(type: :utc_datetime)
  end

  @progress_states ~w(locked in_progress completed)

  @doc false
  def changeset(user_zone_progress, attrs) do
    user_zone_progress
    |> cast(attrs, [:progress, :user_id, :zone_id])
    |> validate_required([:progress, :user_id, :zone_id])
    |> validate_inclusion(:progress, @progress_states)
    |> unique_constraint([:user_id, :zone_id], name: :user_zone_progress_user_id_zone_id_index)
  end

  def progress_states, do: @progress_states
end
