defmodule Shard.Npcs.Npc do
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Map.Room

  schema "npcs" do
    field :name, :string
    field :description, :string
    field :level, :integer, default: 1
    field :health, :integer, default: 100
    field :max_health, :integer, default: 100
    field :mana, :integer, default: 50
    field :max_mana, :integer, default: 50
    field :strength, :integer, default: 10
    field :dexterity, :integer, default: 10
    field :intelligence, :integer, default: 10
    field :constitution, :integer, default: 10
    field :experience_reward, :integer, default: 0
    field :gold_reward, :integer, default: 0
    field :npc_type, :string, default: "neutral"
    field :dialogue, :string
    field :inventory, :map, default: %{}
    field :location_x, :integer
    field :location_y, :integer
    field :location_z, :integer, default: 0
    field :is_active, :boolean, default: true
    field :respawn_time, :integer
    field :last_death_at, :utc_datetime
    field :faction, :string
    field :aggression_level, :integer, default: 0
    field :movement_pattern, :string, default: "stationary"
    field :properties, :map, default: %{}

    belongs_to :room, Room

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(npc, attrs) do
    npc
    |> cast(attrs, [
      :name, :description, :level, :health, :max_health, :mana, :max_mana,
      :strength, :dexterity, :intelligence, :constitution, :experience_reward,
      :gold_reward, :npc_type, :dialogue, :inventory, :location_x, :location_y,
      :location_z, :room_id, :is_active, :respawn_time, :last_death_at,
      :faction, :aggression_level, :movement_pattern, :properties
    ])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_inclusion(:npc_type, ["neutral", "friendly", "hostile", "merchant", "quest_giver"])
    |> validate_inclusion(:movement_pattern, ["stationary", "patrol", "random", "follow"])
    |> validate_number(:level, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_number(:health, greater_than_or_equal_to: 0)
    |> validate_number(:max_health, greater_than: 0)
    |> validate_number(:mana, greater_than_or_equal_to: 0)
    |> validate_number(:max_mana, greater_than_or_equal_to: 0)
    |> validate_number(:aggression_level, greater_than_or_equal_to: 0, less_than_or_equal_to: 10)
    |> validate_health_not_exceeding_max()
    |> validate_mana_not_exceeding_max()
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

  defp validate_mana_not_exceeding_max(changeset) do
    mana = get_field(changeset, :mana)
    max_mana = get_field(changeset, :max_mana)

    if mana && max_mana && mana > max_mana do
      add_error(changeset, :mana, "cannot exceed max mana")
    else
      changeset
    end
  end
end
