defmodule Shard.Map.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :name, :string
    field :description, :string
    field :x_coordinate, :integer, default: 0
    field :y_coordinate, :integer, default: 0
    field :z_coordinate, :integer, default: 0
    field :is_public, :boolean, default: true
    # standard, safe_zone, shop, dungeon, etc.
    field :room_type, :string, default: "standard"
    # For extensibility: lighting, weather, etc.
    field :properties, :map, default: %{}

    has_many :doors_from, Shard.Map.Door, foreign_key: :from_room_id
    has_many :doors_to, Shard.Map.Door, foreign_key: :to_room_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [
      :name,
      :description,
      :x_coordinate,
      :y_coordinate,
      :z_coordinate,
      :is_public,
      :room_type,
      :properties
    ])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:description, max: 1000)
    |> validate_inclusion(:room_type, [
      "standard",
      "safe_zone",
      "shop",
      "dungeon",
      "treasure_room",
      "trap_room"
    ])
    |> unique_constraint(:name)
    |> unique_constraint([:x_coordinate, :y_coordinate, :z_coordinate])
  end
end
