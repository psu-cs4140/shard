defmodule Shard.Quests do
  @moduledoc """
  The Quests context.
  """
  import Ecto.Query, warn: false
  alias Shard.Repo

  alias Shard.Quests.{Quest, QuestAcceptance}
  alias Shard.Items.{CharacterInventory, Item}

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
        result =
          quest_acceptance
          |> QuestAcceptance.changeset(%{
            status: "completed",
            completed_at: DateTime.utc_now() |> DateTime.truncate(:second)
          })
          |> Repo.update()

        # After completing a quest, check if any locked quests should be unlocked
        case result do
          {:ok, _} ->
            unlock_eligible_quests(user_id)
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
    # Get the user's characters from the Characters context
    case Shard.Characters.get_characters_by_user(user_id) do
      [] ->
        {:error, :character_not_found}

      [character | _] ->
        # Use the first character for now
        character_id = character.id

        with quest when not is_nil(quest) <- get_quest!(quest_id),
             true <- quest_in_progress_by_user?(user_id, quest_id) do
          case Shard.Items.character_has_quest_items?(character_id, quest.objectives) do
            true -> {:ok, true}
            false -> {:error, :missing_items}
          end
        else
          nil -> {:error, :quest_not_found}
          false -> {:error, :quest_not_in_progress}
        end
    end
  end

  @doc """
  Checks if a user can turn in a quest based on quest objectives with explicit character_id.
  """
  def can_turn_in_quest_with_character_id?(user_id, character_id, quest_id) do
    with quest when not is_nil(quest) <- get_quest!(quest_id),
         true <- quest_in_progress_by_user?(user_id, quest_id) do
      case Shard.Items.character_has_quest_items?(character_id, quest.objectives) do
        true -> {:ok, true}
        false -> {:error, :missing_items}
      end
    else
      nil -> {:error, :quest_not_found}
      false -> {:error, :quest_not_in_progress}
    end
  end

  @doc """
  Gets quests that can be turned in to a specific NPC by a user.
  """
  def get_turn_in_quests_by_npc(user_id, npc_id) do
    # Get all active quests for this user that can be turned in to this NPC
    from(qa in QuestAcceptance,
      join: q in Quest,
      on: qa.quest_id == q.id,
      where:
        qa.user_id == ^user_id and
          qa.status in ["accepted", "in_progress"] and
          q.turn_in_npc_id == ^npc_id,
      select: q
    )
    |> Repo.all()
    |> Repo.preload([:turn_in_npc])
  end

  @doc """
  Processes quest turn-in, removing required items from inventory.
  """
  def turn_in_quest_with_items(user_id, quest_id) do
    case Shard.Characters.get_characters_by_user(user_id) do
      [] ->
        {:error, :character_not_found}

      [character | _] ->
        process_quest_turn_in(user_id, character.id, quest_id)
    end
  end

  @doc """
  Processes quest turn-in with explicit character_id, removing required items from inventory.
  """
  def turn_in_quest_with_character_id(user_id, character_id, quest_id) do
    case can_turn_in_quest_with_character_id?(user_id, character_id, quest_id) do
      {:ok, true} ->
        execute_quest_turn_in_with_character(user_id, character_id, quest_id)

      error ->
        error
    end
  end

  @doc """
  Gives quest reward items to a character's inventory.
  """
  def give_quest_reward_items(character_id, item_rewards) when is_map(item_rewards) do
    case map_size(item_rewards) do
      0 -> {:ok, []}
      _ -> process_item_rewards(character_id, item_rewards)
    end
  end

  def give_quest_reward_items(_character_id, _item_rewards), do: {:ok, []}

  @doc """
  Applies experience and gold rewards to a character.
  """
  def apply_character_rewards(character_id, exp_reward, gold_reward) do
    try do
      case Shard.Repo.get(Shard.Characters.Character, character_id) do
        nil ->
          {:error, :character_not_found}

        character ->
          # Get current values, defaulting to 0 if fields don't exist
          current_exp = Map.get(character, :experience, 0) || 0
          current_gold = Map.get(character, :gold, 0) || 0
          current_level = Map.get(character, :level, 1) || 1

          # Update character with new experience and gold
          new_experience = current_exp + exp_reward
          new_gold = current_gold + gold_reward

          # Calculate level up if needed
          {new_level, new_experience_final} =
            calculate_level_from_experience(new_experience, current_level)

          # Build changeset with only fields that exist on the character schema
          attrs = %{}

          attrs =
            if Map.has_key?(character, :experience),
              do: Map.put(attrs, :experience, new_experience_final),
              else: attrs

          attrs =
            if Map.has_key?(character, :gold), do: Map.put(attrs, :gold, new_gold), else: attrs

          attrs =
            if Map.has_key?(character, :level), do: Map.put(attrs, :level, new_level), else: attrs

          changeset = Ecto.Changeset.change(character, attrs)

          case Shard.Repo.update(changeset) do
            {:ok, updated_character} -> {:ok, updated_character}
            {:error, changeset} -> {:error, changeset}
          end
      end
    rescue
      error -> {:error, error}
    end
  end

  # Helper function to calculate level from total experience
  defp calculate_level_from_experience(total_experience, _current_level) do
    # Simple leveling formula: each level requires level * 500 XP
    # Level 1: 0-499, Level 2: 500-1499, Level 3: 1500-2999, etc.

    calculate_level_recursive(total_experience, 1, 0)
  end

  defp calculate_level_recursive(remaining_exp, level, total_used_exp) do
    exp_for_this_level = level * 500

    if remaining_exp >= exp_for_this_level do
      calculate_level_recursive(
        remaining_exp - exp_for_this_level,
        level + 1,
        total_used_exp + exp_for_this_level
      )
    else
      {level, total_used_exp + remaining_exp}
    end
  end

  defp process_item_rewards(character_id, item_rewards) do
    results =
      Enum.map(item_rewards, fn {item_name, quantity} ->
        give_reward_item_by_name(character_id, item_name, quantity)
      end)

    # Check if all items were successfully given
    case Enum.all?(results, &match?({:ok, _}, &1)) do
      true ->
        given_items = Enum.map(results, fn {:ok, item} -> item end)
        {:ok, given_items}

      false ->
        {:error, :failed_to_give_items}
    end
  end

  defp give_reward_item_by_name(character_id, item_name, quantity) when is_binary(item_name) do
    # Find the item by name (case-insensitive)
    item_query = from(i in Shard.Items.Item, where: ilike(i.name, ^item_name))

    case Shard.Repo.one(item_query) do
      nil ->
        IO.puts("Item not found: #{item_name}")
        {:error, :item_not_found}

      item ->
        IO.puts("Found item: #{item.name} (ID: #{item.id})")

        case Shard.Items.add_item_to_inventory(character_id, item.id, quantity) do
          {:ok, _inventory_entry} ->
            IO.puts("Successfully added #{quantity} #{item.name} to inventory")
            {:ok, %{name: item.name, quantity: quantity}}

          error ->
            IO.puts("Failed to add item to inventory: #{inspect(error)}")
            error
        end
    end
  end

  defp give_reward_item_by_name(character_id, item_name, quantity) when is_integer(item_name) do
    # Handle case where item_name is actually an item_id
    case Shard.Items.add_item_to_inventory(character_id, item_name, quantity) do
      {:ok, _inventory_entry} ->
        case Shard.Repo.get(Shard.Items.Item, item_name) do
          nil -> {:ok, %{name: "Unknown Item", quantity: quantity}}
          item -> {:ok, %{name: item.name, quantity: quantity}}
        end

      error ->
        error
    end
  end

  defp give_reward_item_by_name(_character_id, _item_name, _quantity),
    do: {:error, :invalid_item_name}

  defp process_quest_turn_in(user_id, character_id, quest_id) do
    case can_turn_in_quest?(user_id, quest_id) do
      {:ok, true} ->
        execute_quest_turn_in_transaction(user_id, character_id, quest_id)

      error ->
        error
    end
  end

  defp execute_quest_turn_in_with_character(user_id, character_id, quest_id) do
    quest = get_quest!(quest_id)

    Repo.transaction(fn ->
      case remove_quest_items_from_inventory(character_id, quest.objectives) do
        :ok ->
          case complete_quest_or_rollback(user_id, quest_id) do
            quest_acceptance ->
              # Apply experience and gold rewards
              exp_reward = quest.experience_reward || 0
              gold_reward = quest.gold_reward || 0

              # Log the rewards being applied for debugging
              IO.puts(
                "Applying quest rewards: #{exp_reward} exp, #{gold_reward} gold to character #{character_id}"
              )

              case apply_character_rewards(character_id, exp_reward, gold_reward) do
                {:ok, _updated_character} ->
                  IO.puts("Successfully applied character rewards")
                  # Extract reward items from objectives field
                  reward_items = extract_reward_items_from_objectives(quest.objectives)
                  # Give quest reward items after successful completion
                  case give_quest_reward_items(character_id, reward_items) do
                    {:ok, given_items} ->
                      IO.puts("Successfully gave #{length(given_items)} quest reward items")
                      {quest_acceptance, given_items}

                    {:error, reason} ->
                      IO.puts("Failed to give quest reward items: #{inspect(reason)}")
                      Repo.rollback(reason)
                  end

                {:error, reason} ->
                  IO.puts("Failed to apply character rewards: #{inspect(reason)}")
                  Repo.rollback(reason)
              end
          end

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  defp execute_quest_turn_in_transaction(user_id, character_id, quest_id) do
    quest = get_quest!(quest_id)

    Repo.transaction(fn ->
      case remove_quest_items_from_inventory(character_id, quest.objectives) do
        :ok ->
          case complete_quest_or_rollback(user_id, quest_id) do
            quest_acceptance ->
              # Apply experience and gold rewards
              exp_reward = quest.experience_reward || 0
              gold_reward = quest.gold_reward || 0

              case apply_character_rewards(character_id, exp_reward, gold_reward) do
                {:ok, _updated_character} ->
                  # Extract reward items from objectives field
                  reward_items = extract_reward_items_from_objectives(quest.objectives)
                  # Give quest reward items after successful completion
                  case give_quest_reward_items(character_id, reward_items) do
                    {:ok, given_items} ->
                      {quest_acceptance, given_items}

                    {:error, reason} ->
                      Repo.rollback(reason)
                  end

                {:error, reason} ->
                  Repo.rollback(reason)
              end
          end

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  defp complete_quest_or_rollback(user_id, quest_id) do
    case complete_quest(user_id, quest_id) do
      {:ok, quest_acceptance} -> quest_acceptance
      {:error, reason} -> Repo.rollback(reason)
    end
  end

  defp remove_quest_items_from_inventory(character_id, objectives) when is_map(objectives) do
    case objectives do
      %{"retrieve_items" => items} when is_list(items) ->
        remove_all_quest_items(character_id, items)

      _ ->
        # No items to remove
        :ok
    end
  end

  defp remove_quest_items_from_inventory(_character_id, _objectives), do: :ok

  defp remove_all_quest_items(character_id, items) do
    Enum.reduce_while(items, :ok, fn item, :ok ->
      required_quantity = Map.get(item, "quantity", 1)

      case remove_items_by_name(character_id, item["item_name"], required_quantity) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp remove_items_by_name(character_id, item_name, quantity) do
    # Get all inventory entries for this item
    inventory_entries =
      from(ci in CharacterInventory,
        join: i in Item,
        on: ci.item_id == i.id,
        where: ci.character_id == ^character_id and ilike(i.name, ^item_name) and ci.quantity > 0,
        order_by: [asc: ci.id]
      )
      |> Repo.all()

    total_available = Enum.sum(Enum.map(inventory_entries, & &1.quantity))

    if total_available >= quantity do
      remove_items_from_entries(inventory_entries, quantity)
    else
      {:error, :insufficient_items}
    end
  end

  # Helper function to extract reward items from objectives field
  defp extract_reward_items_from_objectives(objectives) when is_map(objectives) do
    case objectives do
      %{"reward_items" => reward_items} when is_list(reward_items) ->
        # Convert list of reward items to map format expected by give_quest_reward_items
        Enum.reduce(reward_items, %{}, fn item, acc ->
          item_name = Map.get(item, "item_name")
          quantity = Map.get(item, "quantity", 1)
          if item_name, do: Map.put(acc, item_name, quantity), else: acc
        end)

      _ ->
        %{}
    end
  end

  defp extract_reward_items_from_objectives(_objectives), do: %{}

  defp remove_items_from_entries([], 0), do: :ok
  defp remove_items_from_entries([], _remaining), do: {:error, :insufficient_items}
  defp remove_items_from_entries(_entries, 0), do: :ok

  defp remove_items_from_entries([entry | rest], remaining) when remaining > 0 do
    cond do
      entry.quantity >= remaining ->
        remove_sufficient_items(entry.id, remaining)

      entry.quantity < remaining ->
        remove_partial_items(entry, rest, remaining)
    end
  end

  defp remove_sufficient_items(entry_id, quantity) do
    case Shard.Items.remove_item_from_inventory(entry_id, quantity) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  defp remove_partial_items(entry, rest, remaining) do
    case Shard.Items.remove_item_from_inventory(entry.id, entry.quantity) do
      {:ok, _} -> remove_items_from_entries(rest, remaining - entry.quantity)
      error -> error
    end
  end
end
