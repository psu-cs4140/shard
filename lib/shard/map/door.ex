defmodule Shard.Map.Door do
  use Ecto.Schema
  import Ecto.Changeset

  schema "doors" do
    field :name, :string
    field :description, :string
    field :direction, :string # north, south, east, west, up, down, etc.
    field :is_locked, :boolean, default: false
    field :key_required, :string
    field :door_type, :string, default: "standard" # standard, gate, portal, etc.
    field :properties, :map, default: %{} # For extensibility: lock difficulty, etc.

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
      :properties
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
end
