defmodule Shard.Map.Door do
  @moduledoc """
  Represents a door or connection between two rooms in the game world.

  Doors define how players can move between rooms, including directional
  movement (north, south, east, west, etc.), locked doors that require keys,
  and special door types like portals or secret passages.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "doors" do
    field :name, :string
    field :description, :string
    # north, south, east, west, up, down, etc.
    field :direction, :string
    field :is_locked, :boolean, default: false
    field :key_required, :string
    # standard, gate, portal, etc.
    field :door_type, :string, default: "standard"
    # For extensibility: lock difficulty, etc.
    field :properties, :map, default: %{}
    field :new_dungeon, :boolean, default: false

    belongs_to :from_room, Shard.Map.Room, foreign_key: :from_room_id
    belongs_to :to_room, Shard.Map.Room, foreign_key: :to_room_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(door, attrs) do
    door
    |> cast(attrs, [
      :name,
      :description,
      :from_room_id,
      :to_room_id,
      :direction,
      :is_locked,
      :key_required,
      :door_type,
      :properties,
      :new_dungeon
    ])
    |> validate_required([:from_room_id, :to_room_id, :direction])
    |> validate_length(:name, max: 100)
    |> validate_length(:description, max: 500)
    |> validate_length(:key_required, max: 100)
    |> validate_inclusion(:direction, [
      "north",
      "south",
      "east",
      "west",
      "up",
      "down",
      "northeast",
      "northwest",
      "southeast",
      "southwest"
    ])
    |> validate_inclusion(:door_type, [
      "standard",
      "gate",
      "portal",
      "secret",
      "locked_gate"
    ])
    |> validate_different_rooms()
    |> unique_constraint(:from_room_id, name: :doors_from_room_id_direction_index)
  end

  defp validate_different_rooms(changeset) do
    from_room_id = get_field(changeset, :from_room_id)
    to_room_id = get_field(changeset, :to_room_id)

    if from_room_id && to_room_id && from_room_id == to_room_id do
      add_error(changeset, :to_room_id, "cannot lead to the same room")
    else
      changeset
    end
  end

  # Map directions to their opposites
  def opposite_direction("north"), do: "south"
  def opposite_direction("south"), do: "north"
  def opposite_direction("east"), do: "west"
  def opposite_direction("west"), do: "east"
  def opposite_direction("up"), do: "down"
  def opposite_direction("down"), do: "up"
  def opposite_direction("northeast"), do: "southwest"
  def opposite_direction("northwest"), do: "southeast"
  def opposite_direction("southeast"), do: "northwest"
  def opposite_direction("southwest"), do: "northeast"
  def opposite_direction(direction), do: direction
end
