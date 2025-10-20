defmodule Shard.Monsters.Monster do
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
      :location_id
    ])
    |> validate_required([:name, :race, :health, :max_health, :attack_damage, :xp_amount])
    |> validate_number(:health, greater_than: 0)
    |> validate_number(:max_health, greater_than: 0)
    |> validate_number(:attack_damage, greater_than_or_equal_to: 0)
    |> validate_number(:xp_amount, greater_than_or_equal_to: 0)
    |> validate_number(:level, greater_than: 0)
    |> validate_health_not_exceeding_max()
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
end
