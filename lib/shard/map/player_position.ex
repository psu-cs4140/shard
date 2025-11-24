defmodule Shard.Map.PlayerPosition do
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Characters.Character
  alias Shard.Map.{Zone, Room}

  @moduledoc """
  Creates schema for player position persistence
  """

  schema "player_positions" do
    field :x_coordinate, :integer
    field :y_coordinate, :integer
    field :z_coordinate, :integer, default: 0
    field :last_visited_at, :utc_datetime

    belongs_to :character, Character
    belongs_to :zone, Zone
    belongs_to :room, Room

    timestamps()
  end

  @doc false
  def changeset(player_position, attrs) do
    player_position
    |> cast(attrs, [
      :character_id,
      :zone_id,
      :room_id,
      :x_coordinate,
      :y_coordinate,
      :z_coordinate,
      :last_visited_at
    ])
    |> validate_required([
      :character_id,
      :zone_id,
      :room_id,
      :x_coordinate,
      :y_coordinate,
      :z_coordinate,
      :last_visited_at
    ])
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:zone_id)
    |> foreign_key_constraint(:room_id)
    |> unique_constraint([:character_id, :zone_id])
  end
end
