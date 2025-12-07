defmodule Shard.Skills.CharacterSkill do
  @moduledoc """
  Join table for characters and their unlocked skills.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Characters.Character
  alias Shard.Skills.SkillNode

  schema "character_skills" do
    field :unlocked_at, :utc_datetime

    belongs_to :character, Character
    belongs_to :skill_node, SkillNode

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(character_skill, attrs) do
    character_skill
    |> cast(attrs, [:character_id, :skill_node_id, :unlocked_at])
    |> validate_required([:character_id, :skill_node_id])
    |> put_change(:unlocked_at, DateTime.utc_now())
    |> unique_constraint([:character_id, :skill_node_id])
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:skill_node_id)
  end
end
