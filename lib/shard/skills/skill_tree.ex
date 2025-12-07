defmodule Shard.Skills.SkillTree do
  @moduledoc """
  Schema for skill trees - represents different categories of skills.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Skills.SkillNode

  schema "skill_trees" do
    field :name, :string
    field :description, :string
    field :is_active, :boolean, default: true

    has_many :skill_nodes, SkillNode

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(skill_tree, attrs) do
    skill_tree
    |> cast(attrs, [:name, :description, :is_active])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 100)
    |> unique_constraint(:name)
  end
end
