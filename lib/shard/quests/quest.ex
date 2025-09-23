defmodule Shard.Quests.Quest do
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Npcs.Npc

  schema "quests" do
    field :title, :string
    field :description, :string
    field :short_description, :string
    field :quest_type, :string, default: "main"
    field :difficulty, :string, default: "normal"
    field :min_level, :integer, default: 1
    field :max_level, :integer
    field :experience_reward, :integer, default: 0
    field :gold_reward, :integer, default: 0
    field :item_rewards, :map, default: %{}
    field :prerequisites, :map, default: %{}
    field :objectives, :map, default: %{}
    field :status, :string, default: "available"
    field :is_repeatable, :boolean, default: false
    field :cooldown_hours, :integer
    field :location_hint, :string
    field :time_limit, :integer
    field :faction_requirement, :string
    field :faction_reward, :map, default: %{}
    field :is_active, :boolean, default: true
    field :sort_order, :integer, default: 0
    field :properties, :map, default: %{}

    belongs_to :giver_npc, Npc, foreign_key: :giver_npc_id
    belongs_to :turn_in_npc, Npc, foreign_key: :turn_in_npc_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quest, attrs) do
    quest
    |> cast(attrs, [
      :title, :description, :short_description, :quest_type, :difficulty,
      :min_level, :max_level, :experience_reward, :gold_reward, :item_rewards,
      :prerequisites, :objectives, :status, :is_repeatable, :cooldown_hours,
      :giver_npc_id, :turn_in_npc_id, :location_hint, :time_limit,
      :faction_requirement, :faction_reward, :is_active, :sort_order, :properties
    ])
    |> validate_required([:title, :description])
    |> validate_length(:title, min: 3, max: 100)
    |> validate_length(:description, min: 10)
    |> validate_inclusion(:quest_type, ["main", "side", "daily", "repeatable"])
    |> validate_inclusion(:difficulty, ["easy", "normal", "hard", "epic", "legendary"])
    |> validate_inclusion(:status, ["available", "in_progress", "completed", "failed", "locked"])
    |> validate_number(:min_level, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_number(:max_level, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_number(:experience_reward, greater_than_or_equal_to: 0)
    |> validate_number(:gold_reward, greater_than_or_equal_to: 0)
    |> validate_number(:cooldown_hours, greater_than: 0)
    |> validate_number(:time_limit, greater_than: 0)
    |> validate_level_range()
  end

  defp validate_level_range(changeset) do
    min_level = get_field(changeset, :min_level)
    max_level = get_field(changeset, :max_level)

    if min_level && max_level && min_level > max_level do
      add_error(changeset, :max_level, "must be greater than or equal to min level")
    else
      changeset
    end
  end
end
