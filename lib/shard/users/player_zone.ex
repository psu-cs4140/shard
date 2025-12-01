defmodule Shard.Users.PlayerZone do
  @moduledoc """
  Tracks zone instances that belong to specific players.
  
  Each user can have one singleplayer instance and one multiplayer instance
  per zone type (zone name). This allows for personal progression in singleplayer
  while also participating in shared multiplayer instances.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Users.User
  alias Shard.Map.Zone

  schema "player_zones" do
    field :zone_name, :string
    field :instance_type, :string
    field :zone_instance_id, :string

    belongs_to :user, User
    belongs_to :zone, Zone

    timestamps(type: :utc_datetime)
  end

  @instance_types ~w(singleplayer multiplayer)

  @doc false
  def changeset(player_zone, attrs) do
    player_zone
    |> cast(attrs, [:zone_name, :instance_type, :zone_instance_id, :user_id, :zone_id])
    |> validate_required([:zone_name, :instance_type, :zone_instance_id, :user_id, :zone_id])
    |> validate_inclusion(:instance_type, @instance_types)
    |> validate_length(:zone_name, min: 2, max: 100)
    |> validate_length(:zone_instance_id, min: 2, max: 100)
    |> unique_constraint([:user_id, :zone_name, :instance_type],
      name: :player_zones_user_zone_instance_index,
      message: "user already has a #{:instance_type} instance for this zone"
    )
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:zone_id)
  end

  def instance_types, do: @instance_types
end
