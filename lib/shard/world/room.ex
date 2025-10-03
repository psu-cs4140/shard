defmodule Shard.World.Room do
  use Ecto.Schema
  import Ecto.Changeset

  @room_types ~w(standard safe_zone shop dungeon treasure_room trap_room)

  schema "rooms" do
    field :slug, :string
    field :name, :string
    field :description, :string, default: ""
    field :x_coordinate, :integer, default: 0
    field :y_coordinate, :integer, default: 0
    field :z_coordinate, :integer, default: 0
    field :is_public, :boolean, default: true
    field :room_type, :string, default: "standard"
    field :properties, :map, default: %{}

    # per-room music
    field :music_key, :string
    field :music_volume, :integer, default: 70
    field :music_loop, :boolean, default: true

    timestamps()
  end

  def changeset(room, attrs) do
    room
    |> cast(attrs, [
      :slug,
      :name,
      :description,
      :x_coordinate,
      :y_coordinate,
      :z_coordinate,
      :is_public,
      :room_type,
      :properties,
      :music_key,
      :music_volume,
      :music_loop
    ])
    |> validate_required([:slug, :name, :x_coordinate, :y_coordinate])
    |> validate_length(:name, max: 255)
    |> validate_inclusion(:room_type, @room_types)
    |> validate_number(:music_volume, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> unique_constraint(:slug)
  end
end
