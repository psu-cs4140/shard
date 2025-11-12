defmodule Shard.Monsters.Monster do
  @moduledoc """
  This module defines the monster schema and the changeset to 
  change monster field. Also includes functions to ensure that
  health does not exceed max health
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "monsters" do
    field :name, :string
    field :race, :string
    field :health, :integer
    field :max_health, :integer
    field :attack_damage, :integer
    field :potential_loot_drops, :map, default: %{}
    field :xp_amount, :integer
    field :level, :integer, default: 1
    field :description, :string

    # Special damage fields for poison, fire, etc.
    field :special_damage_amount, :integer, default: 0
    field :special_damage_duration, :integer, default: 0
    field :special_damage_chance, :integer, default: 100
    belongs_to :special_damage_type, Shard.Weapons.DamageTypes

    # Location reference - assuming monsters are placed in rooms
    belongs_to :location, Shard.Map.Room, foreign_key: :location_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(monster, attrs) do
    monster
    |> cast(attrs, [
      :name,
      :race,
      :health,
      :max_health,
      :attack_damage,
      :potential_loot_drops,
      :xp_amount,
      :level,
      :description,
      :location_id,
      :special_damage_type_id,
      :special_damage_amount,
      :special_damage_duration,
      :special_damage_chance
    ])
    |> validate_required([:name, :race, :health, :max_health, :attack_damage, :xp_amount])
    |> validate_number(:health, greater_than: 0)
    |> validate_number(:max_health, greater_than: 0)
    |> validate_number(:attack_damage, greater_than_or_equal_to: 0)
    |> validate_number(:xp_amount, greater_than_or_equal_to: 0)
    |> validate_number(:level, greater_than: 0)
    |> validate_number(:special_damage_amount, greater_than_or_equal_to: 0)
    |> validate_number(:special_damage_duration, greater_than_or_equal_to: 0)
    |> validate_number(:special_damage_chance,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100
    )
    |> validate_health_not_exceeding_max()
    # Add this line to handle empty strings
    |> handle_empty_location_id()
  end

  defp validate_health_not_exceeding_max(changeset) do
    health = get_field(changeset, :health)
    max_health = get_field(changeset, :max_health)

    if health && max_health && health > max_health do
      add_error(changeset, :health, "cannot exceed max health")
    else
      changeset
    end
  end

  # Add this function to handle empty location_id strings
  defp handle_empty_location_id(changeset) do
    case get_change(changeset, :location_id) do
      "" -> put_change(changeset, :location_id, nil)
      nil -> changeset
      _ -> changeset
    end
  end
end
