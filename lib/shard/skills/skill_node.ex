defmodule Shard.Skills.SkillNode do
  @moduledoc """
  Schema for individual skill nodes within a skill tree.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Skills.{SkillTree, CharacterSkill}

  schema "skill_nodes" do
    field :name, :string
    field :description, :string
    field :xp_cost, :integer
    field :prerequisites, {:array, :integer}, default: []
    field :effects, :map, default: %{}
    field :position_x, :integer, default: 0
    field :position_y, :integer, default: 0
    field :is_active, :boolean, default: true

    belongs_to :skill_tree, SkillTree
    has_many :character_skills, CharacterSkill

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(skill_node, attrs) do
    skill_node
    |> cast(attrs, [
      :name,
      :description,
      :xp_cost,
      :prerequisites,
      :effects,
      :position_x,
      :position_y,
      :is_active,
      :skill_tree_id
    ])
    |> validate_required([:name, :xp_cost, :skill_tree_id])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_number(:xp_cost, greater_than: 0)
    |> validate_number(:position_x, greater_than_or_equal_to: 0)
    |> validate_number(:position_y, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:skill_tree_id)
  end
end
