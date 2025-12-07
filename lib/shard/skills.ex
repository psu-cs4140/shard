defmodule Shard.Skills do
  @moduledoc """
  The Skills context - manages skill trees and character skill progression.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo
  alias Shard.Skills.{SkillTree, SkillNode, CharacterSkill}
  alias Shard.Characters.Character

  @doc """
  Returns the list of skill trees.
  """
  def list_skill_trees do
    Repo.all(SkillTree)
    |> Repo.preload(:skill_nodes)
  end

  @doc """
  Gets a single skill tree.
  """
  def get_skill_tree!(id) do
    Repo.get!(SkillTree, id)
    |> Repo.preload(:skill_nodes)
  end

  @doc """
  Gets a skill tree by name.
  """
  def get_skill_tree_by_name(name) do
    Repo.get_by(SkillTree, name: name)
    |> case do
      nil -> nil
      tree -> Repo.preload(tree, :skill_nodes)
    end
  end

  @doc """
  Returns the list of skill nodes for a skill tree.
  """
  def list_skill_nodes(skill_tree_id) do
    from(n in SkillNode, where: n.skill_tree_id == ^skill_tree_id)
    |> Repo.all()
  end

  @doc """
  Gets a single skill node.
  """
  def get_skill_node!(id) do
    Repo.get!(SkillNode, id)
  end

  @doc """
  Gets character's unlocked skills.
  """
  def get_character_skills(character_id) do
    from(cs in CharacterSkill, 
         where: cs.character_id == ^character_id,
         preload: [:skill_node])
    |> Repo.all()
  end

  @doc """
  Checks if a character has unlocked a specific skill.
  """
  def has_skill?(character_id, skill_node_id) do
    from(cs in CharacterSkill,
         where: cs.character_id == ^character_id and cs.skill_node_id == ^skill_node_id)
    |> Repo.exists?()
  end

  @doc """
  Attempts to unlock a skill for a character.
  Returns {:ok, character_skill} if successful, {:error, reason} if not.
  """
  def unlock_skill(character_id, skill_node_id) do
    with {:ok, character} <- get_character_with_skills(character_id),
         {:ok, skill_node} <- get_valid_skill_node(skill_node_id),
         :ok <- validate_skill_unlock(character, skill_node) do
      
      case create_character_skill(character_id, skill_node_id) do
        {:ok, character_skill} ->
          # Deduct XP cost
          new_experience = character.experience - skill_node.xp_cost
          Shard.Characters.update_character(character, %{experience: new_experience})
          {:ok, character_skill}
        
        error -> error
      end
    end
  end

  @doc """
  Gets available skills that a character can unlock.
  """
  def get_available_skills(character_id) do
    with {:ok, character} <- get_character_with_skills(character_id) do
      unlocked_skill_ids = Enum.map(character.character_skills, & &1.skill_node_id)
      
      # Get all skill nodes that are not yet unlocked
      available_skills = 
        from(sn in SkillNode,
             where: sn.id not in ^unlocked_skill_ids,
             preload: [:skill_tree])
        |> Repo.all()
        |> Enum.filter(fn skill_node ->
          can_unlock_skill?(character, skill_node, unlocked_skill_ids)
        end)
      
      {:ok, available_skills}
    end
  end

  # Private functions

  defp get_character_with_skills(character_id) do
    case Repo.get(Character, character_id) |> Repo.preload(:character_skills) do
      nil -> {:error, :character_not_found}
      character -> {:ok, character}
    end
  end

  defp get_valid_skill_node(skill_node_id) do
    case Repo.get(SkillNode, skill_node_id) do
      nil -> {:error, :skill_not_found}
      skill_node -> {:ok, skill_node}
    end
  end

  defp validate_skill_unlock(character, skill_node) do
    cond do
      has_skill?(character.id, skill_node.id) ->
        {:error, :already_unlocked}
      
      character.experience < skill_node.xp_cost ->
        {:error, :insufficient_xp}
      
      not prerequisites_met?(character, skill_node) ->
        {:error, :prerequisites_not_met}
      
      true ->
        :ok
    end
  end

  defp prerequisites_met?(character, skill_node) do
    case skill_node.prerequisites do
      [] -> true
      nil -> true
      prerequisite_ids ->
        unlocked_skill_ids = Enum.map(character.character_skills, & &1.skill_node_id)
        Enum.all?(prerequisite_ids, fn prereq_id -> prereq_id in unlocked_skill_ids end)
    end
  end

  defp can_unlock_skill?(character, skill_node, unlocked_skill_ids) do
    character.experience >= skill_node.xp_cost and
    prerequisites_met_by_ids?(skill_node.prerequisites, unlocked_skill_ids)
  end

  defp prerequisites_met_by_ids?(prerequisites, unlocked_skill_ids) do
    case prerequisites do
      [] -> true
      nil -> true
      prereq_ids -> Enum.all?(prereq_ids, fn id -> id in unlocked_skill_ids end)
    end
  end

  defp create_character_skill(character_id, skill_node_id) do
    %CharacterSkill{}
    |> CharacterSkill.changeset(%{
      character_id: character_id,
      skill_node_id: skill_node_id
    })
    |> Repo.insert()
  end
end
