defmodule Shard.Quests do
  @moduledoc """
  The Quests context.
  """
  import Ecto.Query, warn: false
  alias Shard.Repo

  alias Shard.Quests.{Quest, QuestAcceptance}
  alias Shard.Users.User

  @doc """
  Returns the list of quests.
  """
  def list_quests do
    Repo.all(Quest)
  end

  @doc """
  Returns the list of quests with preloaded associations.
  """
  def list_quests_with_preloads do
    Repo.all(Quest)
    |> Repo.preload([:giver_npc, :turn_in_npc])
  end

  @doc """
  Gets a single quest.

  Raises `Ecto.NoResultsError` if the Quest does not exist.
  """
  def get_quest!(id), do: Repo.get!(Quest, id)

  @doc """
  Gets a single quest with preloaded associations.
  """
  def get_quest_with_preloads!(id) do
    Repo.get!(Quest, id)
    |> Repo.preload([:giver_npc, :turn_in_npc])
  end

  @doc """
  Gets quests by type.
  """
  def get_quests_by_type(quest_type) do
    from(q in Quest, where: q.quest_type == ^quest_type and q.is_active == true)
    |> Repo.all()
  end

  @doc """
  Gets quests by difficulty.
  """
  def get_quests_by_difficulty(difficulty) do
    from(q in Quest, where: q.difficulty == ^difficulty and q.is_active == true)
    |> Repo.all()
  end

  @doc """
  Gets quests by status.
  """
  def get_quests_by_status(status) do
    from(q in Quest, where: q.status == ^status and q.is_active == true)
    |> Repo.all()
  end

  @doc """
  Gets available quests for a given level.
  """
  def get_available_quests_for_level(level) do
    from(q in Quest,
      where:
        q.status == "available" and
          q.is_active == true and
          q.min_level <= ^level and
          (is_nil(q.max_level) or q.max_level >= ^level)
    )
    |> Repo.all()
  end

  @doc """
  Checks if a user has already accepted a specific quest.
  """
  def quest_accepted_by_user?(user_id, quest_id) do
    from(qa in QuestAcceptance,
      where: qa.user_id == ^user_id and qa.quest_id == ^quest_id
    )
    |> Repo.exists?()
  end

  @doc """
  Checks if a user has already accepted or is in progress on a specific quest.
  """
  def quest_in_progress_by_user?(user_id, quest_id) do
    from(qa in QuestAcceptance,
      where:
        qa.user_id == ^user_id and qa.quest_id == ^quest_id and
          qa.status in ["accepted", "in_progress"]
    )
    |> Repo.exists?()
  end

  @doc """
  Checks if a user has an active quest of a specific quest type.
  """
  def user_has_active_quest_of_type?(user_id, quest_type) do
    from(qa in QuestAcceptance,
      join: q in Quest,
      on: qa.quest_id == q.id,
      where:
        qa.user_id == ^user_id and
          qa.status in ["accepted", "in_progress"] and
          q.quest_type == ^quest_type
    )
    |> Repo.exists?()
  end

  @doc """
  Checks if a user has already completed a specific quest.
  """
  def quest_completed_by_user?(user_id, quest_id) do
    from(qa in QuestAcceptance,
      where: qa.user_id == ^user_id and qa.quest_id == ^quest_id and qa.status == "completed"
    )
    |> Repo.exists?()
  end

  @doc """
  Checks if a user has ever accepted a quest (regardless of current status).
  """
  def quest_ever_accepted_by_user?(user_id, quest_id) do
    from(qa in QuestAcceptance,
      where: qa.user_id == ^user_id and qa.quest_id == ^quest_id
    )
    |> Repo.exists?()
  end

  @doc """
  Accepts a quest for a user.
  """
  def accept_quest(user_id, quest_id) do
    # Check if the user has already completed this quest or has it in progress
    cond do
      quest_completed_by_user?(user_id, quest_id) ->
        {:error, :quest_already_completed}

      quest_in_progress_by_user?(user_id, quest_id) ->
        {:error, :quest_already_accepted}

      quest_ever_accepted_by_user?(user_id, quest_id) ->
        # Additional safety check - if quest was ever accepted, don't allow duplicate
        {:error, :quest_already_accepted}

      true ->
        changeset =
          %QuestAcceptance{}
          |> QuestAcceptance.accept_changeset(%{user_id: user_id, quest_id: quest_id})

        case Repo.insert(changeset) do
          {:ok, quest_acceptance} ->
            {:ok, quest_acceptance}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  @doc """
  Completes a quest for a user.
  """
  def complete_quest(user_id, quest_id) do
    case from(qa in QuestAcceptance,
           where:
             qa.user_id == ^user_id and qa.quest_id == ^quest_id and
               qa.status in ["accepted", "in_progress"]
         )
         |> Repo.one() do
      nil ->
        {:error, :quest_not_found}

      quest_acceptance ->
        # Get the quest details for achievement checking
        quest = Repo.get!(Quest, quest_id)
        user = Repo.get!(Shard.Users.User, user_id)

        result =
          quest_acceptance
          |> QuestAcceptance.changeset(%{
            status: "completed",
            completed_at: DateTime.utc_now() |> DateTime.truncate(:second)
          })
          |> Repo.update()

        # After completing a quest, check if any locked quests should be unlocked
        # and check for quest completion achievements
        case result do
          {:ok, _} ->
            unlock_eligible_quests(user_id)
            # Check for quest completion achievements
            Shard.Achievements.check_quest_completion_achievements(user, quest.title)
            result

          error ->
            error
        end
    end
  end

  defp unlock_eligible_quests(user_id) do
    # Get completed quest titles for this user
    completed_quest_titles =
      from(qa in QuestAcceptance,
        join: q in Quest,
        on: qa.quest_id == q.id,
        where: qa.user_id == ^user_id and qa.status == "completed",
        select: q.title
      )
      |> Repo.all()

    # Find locked quests that should be unlocked
    locked_quests =
      from(q in Quest,
        where: q.status == "locked" and q.is_active == true
      )
      |> Repo.all()

    Enum.each(locked_quests, &unlock_quest_if_eligible(&1, completed_quest_titles))
  end

  defp unlock_quest_if_eligible(quest, completed_quest_titles) do
    if check_quest_prerequisites(quest, completed_quest_titles) do
      case update_quest(quest, %{status: "available"}) do
        {:ok, _updated_quest} -> :ok
        {:error, _changeset} -> :error
      end
    end
  end

  @doc """
  Gets all quest acceptances for a user.
  """
  def get_user_quest_acceptances(user_id) do
    from(qa in QuestAcceptance,
      where: qa.user_id == ^user_id,
      preload: [:quest]
    )
    |> Repo.all()
  end

  @doc """
  Gets all active (accepted/in_progress) quest acceptances for a user.
  """
  def get_user_active_quests(user_id) do
    from(qa in QuestAcceptance,
      where: qa.user_id == ^user_id and qa.status in ["accepted", "in_progress"],
      preload: [:quest]
    )
    |> Repo.all()
  end

  @doc """
  Gets quests available to a user (not yet accepted).
  """
  def get_available_quests_for_user(user_id) do
    accepted_quest_ids =
      from(qa in QuestAcceptance,
        where: qa.user_id == ^user_id,
        select: qa.quest_id
      )

    from(q in Quest,
      where: q.is_active == true and q.id not in subquery(accepted_quest_ids)
    )
    |> Repo.all()
  end

  @doc """
  Gets quests by giver NPC that are available to a user.
  """
  def get_available_quests_by_giver(user_id, npc_id) do
    accepted_quest_ids =
      from(qa in QuestAcceptance,
        where: qa.user_id == ^user_id,
        select: qa.quest_id
      )

    from(q in Quest,
      where:
        q.giver_npc_id == ^npc_id and
          q.is_active == true and
          q.status == "available" and
          q.id not in subquery(accepted_quest_ids),
      order_by: [asc: q.sort_order, asc: q.id]
    )
    |> Repo.all()
  end

  @doc """
  Gets quests by giver NPC that are available to a user and haven't been completed.
  This excludes quests that have been completed to prevent repetition.
  """
  def get_available_quests_by_giver_excluding_completed(user_id, npc_id) do
    user_quest_data = get_user_quest_data(user_id)
    all_npc_quests = get_npc_quests(npc_id)

    Enum.filter(all_npc_quests, &quest_available_for_user?(&1, user_quest_data))
  end

  defp get_user_quest_data(user_id) do
    %{
      completed_non_repeatable_quest_ids: get_completed_non_repeatable_quest_ids(user_id),
      active_quest_ids: get_active_quest_ids(user_id),
      completed_quest_titles: get_completed_quest_titles(user_id),
      active_quest_types: get_active_quest_types(user_id)
    }
  end

  defp get_completed_non_repeatable_quest_ids(user_id) do
    from(qa in QuestAcceptance,
      join: q in Quest,
      on: qa.quest_id == q.id,
      where: qa.user_id == ^user_id and qa.status == "completed" and q.is_repeatable == false,
      select: qa.quest_id
    )
    |> Repo.all()
  end

  defp get_active_quest_ids(user_id) do
    from(qa in QuestAcceptance,
      where: qa.user_id == ^user_id and qa.status in ["accepted", "in_progress"],
      select: qa.quest_id
    )
    |> Repo.all()
  end

  defp get_completed_quest_titles(user_id) do
    from(qa in QuestAcceptance,
      join: q in Quest,
      on: qa.quest_id == q.id,
      where: qa.user_id == ^user_id and qa.status == "completed",
      select: q.title
    )
    |> Repo.all()
  end

  defp get_active_quest_types(user_id) do
    from(qa in QuestAcceptance,
      join: q in Quest,
      on: qa.quest_id == q.id,
      where:
        qa.user_id == ^user_id and
          qa.status in ["accepted", "in_progress"],
      select: q.quest_type
    )
    |> Repo.all()
  end

  defp get_npc_quests(npc_id) do
    from(q in Quest,
      where:
        q.giver_npc_id == ^npc_id and
          q.is_active == true,
      order_by: [asc: q.sort_order, asc: q.id]
    )
    |> Repo.all()
  end

  defp quest_available_for_user?(quest, user_quest_data) do
    quest_not_taken?(quest, user_quest_data) and
      quest_type_available?(quest, user_quest_data) and
      quest_status_available?(quest, user_quest_data)
  end

  defp quest_not_taken?(quest, %{
         completed_non_repeatable_quest_ids: completed_ids,
         active_quest_ids: active_ids
       }) do
    quest.id not in completed_ids and quest.id not in active_ids
  end

  defp quest_type_available?(quest, %{active_quest_types: active_types}) do
    quest.quest_type not in active_types
  end

  defp quest_status_available?(quest, %{completed_quest_titles: completed_titles}) do
    case quest.status do
      "available" -> true
      "locked" -> check_quest_prerequisites(quest, completed_titles)
      _ -> false
    end
  end

  defp check_quest_prerequisites(quest, completed_quest_titles) do
    case quest.prerequisites do
      %{"completed_quests" => required_quests} when is_list(required_quests) ->
        Enum.all?(required_quests, fn required_quest ->
          required_quest in completed_quest_titles
        end)

      %{} ->
        # No prerequisites
        true

      _ ->
        false
    end
  end

  @doc """
  Creates a quest.
  """
  def create_quest(attrs \\ %{}) do
    %Quest{}
    |> Quest.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a quest.
  """
  def update_quest(%Quest{} = quest, attrs) do
    quest
    |> Quest.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a quest.
  """
  def delete_quest(%Quest{} = quest) do
    Repo.delete(quest)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking quest changes.
  """
  def change_quest(%Quest{} = quest, attrs \\ %{}) do
    Quest.changeset(quest, attrs)
  end

  @doc """
  Checks if a user can turn in a quest based on quest objectives.
  """
  def can_turn_in_quest?(user_id, quest_id) do
    Shard.Quest2.can_turn_in_quest?(user_id, quest_id)
  end

  @doc """
  Checks if a user can turn in a quest based on quest objectives with explicit character_id.
  """
  def can_turn_in_quest_with_character_id?(user_id, character_id, quest_id) do
    Shard.Quest2.can_turn_in_quest_with_character_id?(user_id, character_id, quest_id)
  end

  @doc """
  Gets quests that can be turned in to a specific NPC by a user.
  """
  def get_turn_in_quests_by_npc(user_id, npc_id) do
    Shard.Quest2.get_turn_in_quests_by_npc(user_id, npc_id)
  end

  @doc """
  Processes quest turn-in, removing required items from inventory.
  """
  def turn_in_quest_with_items(user_id, quest_id) do
    Shard.Quest2.turn_in_quest_with_items(user_id, quest_id)
  end

  @doc """
  Processes quest turn-in with explicit character_id, removing required items from inventory.
  """
  def turn_in_quest_with_character_id(user_id, character_id, quest_id) do
    Shard.Quest2.turn_in_quest_with_character_id(user_id, character_id, quest_id)
  end

  @doc """
  Gives quest reward items to a character's inventory.
  """
  def give_quest_reward_items(character_id, item_rewards) do
    Shard.Quest2.give_quest_reward_items(character_id, item_rewards)
  end

  @doc """
  Applies experience and gold rewards to a character.
  """
  def apply_character_rewards(character_id, exp_reward, gold_reward) do
    Shard.Quest2.apply_character_rewards(character_id, exp_reward, gold_reward)
  end
end
