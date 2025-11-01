defmodule Shard.Map.Zone do
  @moduledoc """
  Represents a distinct map zone or area in the game world.

  Zones allow for multiple independent maps with their own coordinate systems.
  Examples: "Vampire Castle", "Tutorial Area", "Dark Forest", "Crystal Caves"
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "zones" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :zone_type, :string, default: "standard"
    field :min_level, :integer, default: 1
    field :max_level, :integer
    field :is_public, :boolean, default: true
    field :is_active, :boolean, default: true
    field :properties, :map, default: %{}
    field :display_order, :integer, default: 0

    has_many :rooms, Shard.Map.Room

    timestamps(type: :utc_datetime)
  end

  @zone_types ~w(standard dungeon town wilderness raid pvp safe_zone)

  @doc false
  def changeset(zone, attrs) do
    zone
    |> cast(attrs, [
      :name,
      :slug,
      :description,
      :zone_type,
      :min_level,
      :max_level,
      :is_public,
      :is_active,
      :properties,
      :display_order
    ])
    |> validate_required([:name, :slug])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:slug, min: 2, max: 100)
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/, message: "must be lowercase alphanumeric with hyphens")
    |> validate_length(:description, max: 1000)
    |> validate_inclusion(:zone_type, @zone_types)
    |> validate_number(:min_level, greater_than_or_equal_to: 1)
    |> validate_number(:max_level, greater_than_or_equal_to: 1)
    |> validate_level_range()
    |> validate_number(:display_order, greater_than_or_equal_to: 0)
    |> unique_constraint(:name)
    |> unique_constraint(:slug)
  end

  defp validate_level_range(changeset) do
    min_level = get_field(changeset, :min_level)
    max_level = get_field(changeset, :max_level)

    if min_level && max_level && min_level > max_level do
      add_error(changeset, :max_level, "must be greater than or equal to min_level")
    else
      changeset
    end
  end

  def zone_types, do: @zone_types
end
