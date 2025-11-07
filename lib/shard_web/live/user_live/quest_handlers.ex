defmodule ShardWeb.UserLive.QuestHandlers do
  alias Shard.Repo
  alias Shard.Quests.Quest

  # Execute quest command to get quest details from an NPC
  def execute_quest_command(game_state, npc_name) do
    {x, y} = game_state.player_position

    npcs_here =
      ShardWeb.UserLive.MapHelpers.get_npcs_at_location(
        x,
        y,
        game_state.character.current_zone_id
      )

    # Find the NPC by name (case-insensitive)
    target_npc =
      Enum.find(npcs_here, fn npc ->
        npc_name_lower = String.downcase(npc.name || "")
        target_name_lower = String.downcase(npc_name)
        npc_name_lower == target_name_lower
      end)

    case target_npc do
      nil ->
        {["There is no NPC named '#{npc_name}' here."], game_state}

      npc ->
        user_id = game_state.character.user_id

        # Get available quests from this NPC
        available_quests =
          Shard.Quests.get_available_quests_by_giver_excluding_completed(user_id, npc.id)

        # Additional filter to ensure we don't show quests that are in the local game state as accepted
        # This helps catch timing issues where the database query might not reflect recent changes
        available_quests =
          Enum.filter(available_quests, fn quest ->
            # Check if this quest is already in the player's quest log
            not Enum.any?(game_state.quests, fn player_quest ->
              player_quest[:id] == quest.id and
                player_quest[:status] in ["In Progress", "Completed"]
            end)
          end)

        if length(available_quests) == 0 do
          npc_name = npc.name || "Unknown NPC"
          {["#{npc_name} has no quests available for you at this time."], game_state}
        else
          # Show the first available quest
          quest = List.first(available_quests)
          npc_name = npc.name || "Unknown NPC"

          response = [
            "#{npc_name} offers you a quest:",
            "",
            "Quest: #{quest.title}",
            "Description: #{quest.description}",
            "",
            "Rewards:",
            "  Experience: #{quest.experience_reward || 0} XP",
            "  Gold: #{quest.gold_reward || 0} gold",
            "",
            "Do you want to accept this quest?",
            "Type 'accept' to accept or 'deny' to decline."
          ]

          # Store the quest offer in game state
          updated_game_state = %{
            game_state
            | pending_quest_offer: %{quest: quest, npc: npc}
          }

          {response, updated_game_state}
        end
    end
  end

  # Execute quest acceptance
  def execute_accept_quest(game_state) do
    case game_state.pending_quest_offer do
      nil ->
        {["There is no quest offer to accept."], game_state}

      %{quest: quest, npc: npc} ->
        handle_quest_acceptance(game_state, quest, npc)
    end
  end

  # Handle the quest acceptance logic
  defp handle_quest_acceptance(game_state, quest, npc) do
    npc_name = npc.name || "Unknown NPC"
    quest_title = quest.title || "Untitled Quest"
    # Get the actual user_id from the game state
    user_id = game_state.character.user_id

    already_accepted = check_quest_already_accepted(user_id, quest.id)

    if already_accepted do
      handle_already_accepted_quest(game_state, npc_name)
    else
      process_quest_acceptance(game_state, quest, npc_name, quest_title, user_id)
    end
  end

  # Check if quest has already been accepted
  defp check_quest_already_accepted(user_id, quest_id) do
    try do
      # Check if quest is currently in progress or completed
      in_progress = Shard.Quests.quest_in_progress_by_user?(user_id, quest_id)
      completed = Shard.Quests.quest_completed_by_user?(user_id, quest_id)

      in_progress || completed
    rescue
      _error ->
        false
    end
  end

  # Handle case where quest was already accepted
  defp handle_already_accepted_quest(game_state, npc_name) do
    response = [
      "#{npc_name} looks at you with confusion.",
      "",
      "\"You have already accepted this quest or completed it. Check your quest log.\""
    ]

    updated_game_state = %{game_state | pending_quest_offer: nil}
    {response, updated_game_state}
  end

  # Process the quest acceptance
  defp process_quest_acceptance(game_state, quest, npc_name, quest_title, user_id) do
    accept_result = attempt_quest_acceptance(user_id, quest.id)
    handle_quest_acceptance_result(game_state, quest, npc_name, quest_title, accept_result)
  end

  # Attempt to accept the quest in the database
  defp attempt_quest_acceptance(user_id, quest_id) do
    case Shard.Quests.accept_quest(user_id, quest_id) do
      {:ok, quest_acceptance} ->
        {:ok, quest_acceptance}

      {:error, changeset} when is_struct(changeset, Ecto.Changeset) ->
        # Log the changeset errors for debugging

        {:error, changeset}

      {:error, reason} ->
        # Log the specific error reason

        {:error, reason}
    end
  rescue
    error ->
      {:error, :database_error}
  end

  # Handle the result of quest acceptance attempt
  defp handle_quest_acceptance_result(game_state, quest, npc_name, quest_title, accept_result) do
    case accept_result do
      {:ok, _quest_acceptance} ->
        handle_successful_quest_acceptance(game_state, quest, npc_name, quest_title)

      {:error, :quest_already_completed} ->
        handle_quest_already_completed(game_state, npc_name)

      {:error, :quest_already_accepted} ->
        handle_quest_already_accepted(game_state, npc_name)

      {:error, :database_error} ->
        handle_database_error_fallback(game_state, quest, npc_name, quest_title)

      {:error, changeset} when is_struct(changeset, Ecto.Changeset) ->
        handle_quest_acceptance_validation_error(game_state, npc_name, changeset)

      {:error, _other_error} ->
        handle_quest_acceptance_error(game_state, npc_name)
    end
  end

  # Handle successful quest acceptance
  defp handle_successful_quest_acceptance(game_state, quest, npc_name, quest_title) do
    # Only add to local quest list if successfully added to database
    # Load the quest acceptance from database to get the current status
    user_id = game_state.character.user_id

    # Get the quest acceptance from database to confirm it was created
    quest_acceptance =
      case Shard.Quests.get_user_active_quests(user_id) do
        active_quests ->
          Enum.find(active_quests, fn qa -> qa.quest_id == quest.id end)
      end

    # Only add to local state if we can confirm it's in the database AND it's not already in local state
    updated_quests =
      if quest_acceptance do
        # Check if quest is already in local game state
        quest_already_in_local =
          Enum.any?(game_state.quests, fn local_quest ->
            local_quest[:id] == quest.id
          end)

        if quest_already_in_local do
          # Quest is already in local state, don't add duplicate
          game_state.quests
        else
          # Quest is not in local state, add it
          new_quest = create_new_quest_entry(quest, npc_name, quest_title)
          [new_quest | game_state.quests]
        end
      else
        game_state.quests
      end

    response = [
      "You accept the quest '#{quest_title}' from #{npc_name}.",
      "",
      "#{npc_name} says: \"Excellent! I knew I could count on you.\"",
      "",
      "Quest '#{quest_title}' has been added to your quest log."
    ]

    updated_game_state = %{
      game_state
      | quests: updated_quests,
        pending_quest_offer: nil
    }

    {response, updated_game_state}
  end

  # Handle case where quest was already completed
  defp handle_quest_already_completed(game_state, npc_name) do
    response = [
      "#{npc_name} looks at you with confusion.",
      "",
      "\"You have already completed this quest. I cannot offer it to you again.\""
    ]

    updated_game_state = %{game_state | pending_quest_offer: nil}
    {response, updated_game_state}
  end

  # Handle case where quest was already accepted
  defp handle_quest_already_accepted(game_state, npc_name) do
    response = [
      "#{npc_name} looks at you with confusion.",
      "",
      "\"You have already accepted this quest or it's in progress. Check your quest log.\""
    ]

    updated_game_state = %{game_state | pending_quest_offer: nil}
    {response, updated_game_state}
  end

  # Handle database error fallback
  defp handle_database_error_fallback(game_state, quest, npc_name, quest_title) do
    # Log more details about the quest and user for debugging

    response = [
      "#{npc_name} looks troubled.",
      "",
      "\"I'm sorry, but there seems to be an issue with accepting this quest right now.\"",
      "\"Please try again later when the connection is more stable.\"",
      "",
      "Quest '#{quest_title}' could not be accepted due to a database error.",
      "(Check server logs for more details)"
    ]

    updated_game_state = %{game_state | pending_quest_offer: nil}
    {response, updated_game_state}
  end

  # Handle quest acceptance validation errors (like quest type restrictions)
  defp handle_quest_acceptance_validation_error(game_state, npc_name, changeset) do
    # Extract the first error message from the changeset
    error_message =
      case changeset.errors do
        [{_field, {message, _opts}} | _] -> message
        _ -> "There seems to be an issue with accepting this quest right now."
      end

    response = [
      "#{npc_name} looks at you thoughtfully.",
      "",
      "\"#{String.capitalize(error_message)}\""
    ]

    updated_game_state = %{game_state | pending_quest_offer: nil}
    {response, updated_game_state}
  end

  # Handle general quest acceptance error
  defp handle_quest_acceptance_error(game_state, npc_name) do
    response = [
      "#{npc_name} looks troubled.",
      "",
      "\"I'm sorry, but there seems to be an issue with accepting this quest right now.\""
    ]

    updated_game_state = %{game_state | pending_quest_offer: nil}
    {response, updated_game_state}
  end

  # Create a new quest entry for the game state
  defp create_new_quest_entry(quest, npc_name, quest_title) do
    %{
      id: quest.id,
      title: quest_title,
      status: "In Progress",
      progress: "0% complete",
      npc_giver: npc_name,
      description: quest.description
    }
  end

  # Execute quest denial
  def execute_deny_quest(game_state) do
    case game_state.pending_quest_offer do
      nil ->
        {["There is no quest offer to deny."], game_state}

      %{quest: quest, npc: npc} ->
        npc_name = npc.name || "Unknown NPC"
        quest_title = quest.title || "Untitled Quest"

        response = [
          "You decline the quest '#{quest_title}' from #{npc_name}.",
          "",
          "#{npc_name} says: \"I understand. Perhaps another time when you're ready.\"",
          "",
          "The quest offer has been declined."
        ]

        updated_game_state = %{game_state | pending_quest_offer: nil}

        {response, updated_game_state}
    end
  end

  # Find a quest that can be delivered to the specified NPC
  def find_deliverable_quest(player_quests, npc) do
    # Look for quests that are "In Progress" and check against database for turn-in NPC
    try do
      Enum.find(player_quests, fn quest ->
        if quest.status == "In Progress" && quest[:id] do
          # Get the full quest data from database to check turn_in_npc_id
          try do
            case Shard.Repo.get(Quest, quest.id) do
              nil ->
                false

              db_quest ->
                # Check if this NPC is the designated turn-in NPC
                db_quest.turn_in_npc_id == npc.id
            end
          rescue
            _error ->
              false
          end
        else
          false
        end
      end)
    rescue
      _error ->
        nil
    end
  end

  # Complete the quest and give rewards to the player
  def complete_quest_and_give_rewards(game_state, quest, npc) do
    npc_name = npc.name || "Unknown NPC"
    quest_title = quest.title || "Untitled Quest"
    user_id = game_state.character.user_id

    full_quest = get_full_quest_safely(quest.id)
    {exp_reward, gold_reward} = calculate_quest_rewards(full_quest)

    updated_stats = update_player_stats_with_experience(game_state.player_stats, exp_reward)
    {updated_stats, level_up_message} = handle_level_up_check(updated_stats)

    updated_quests =
      complete_quest_in_database_and_update_state(game_state.quests, quest.id, user_id)

    response =
      build_quest_completion_response(
        npc_name,
        quest_title,
        exp_reward,
        gold_reward,
        full_quest,
        level_up_message
      )

    updated_game_state = %{game_state | player_stats: updated_stats, quests: updated_quests}
    {response, updated_game_state}
  end

  # Helper function to safely get quest from database
  defp get_full_quest_safely(quest_id) do
    try do
      Repo.get(Quest, quest_id)
    rescue
      _error ->
        nil
    end
  end

  # Helper function to calculate quest rewards
  defp calculate_quest_rewards(full_quest) do
    exp_reward = if full_quest, do: full_quest.experience_reward || 100, else: 100
    gold_reward = if full_quest, do: full_quest.gold_reward || 50, else: 50
    {exp_reward, gold_reward}
  end

  # Helper function to update player stats with experience
  defp update_player_stats_with_experience(player_stats, exp_reward) do
    try do
      player_stats
      |> Map.update(:experience, 0, &(&1 + exp_reward))
    rescue
      _error ->
        player_stats
    end
  end

  # Helper function to handle level up check
  defp handle_level_up_check(updated_stats) do
    try do
      check_level_up(updated_stats)
    rescue
      _error ->
        {updated_stats, nil}
    end
  end

  # Helper function to complete quest in database and update game state
  defp complete_quest_in_database_and_update_state(quests, quest_id, user_id) do
    try do
      case Shard.Quests.complete_quest(user_id, quest_id) do
        {:ok, _quest_acceptance} ->
          mark_quest_as_completed(quests, quest_id)

        {:error, _} ->
          mark_quest_as_completed(quests, quest_id)
      end
    rescue
      _error ->
        mark_quest_as_completed(quests, quest_id)
    end
  end

  # Helper function to mark quest as completed in quest list
  defp mark_quest_as_completed(quests, quest_id) do
    Enum.map(quests, fn q ->
      if q[:id] == quest_id do
        %{q | status: "Completed", progress: "100% complete"}
      else
        q
      end
    end)
  end

  # Helper function to build the complete response message
  defp build_quest_completion_response(
         npc_name,
         quest_title,
         exp_reward,
         gold_reward,
         full_quest,
         level_up_message
       ) do
    base_response = [
      "#{npc_name} examines your progress carefully.",
      "",
      "\"Excellent work! You have completed the quest '#{quest_title}'!\"",
      "",
      "Quest Completed: #{quest_title}",
      "Experience gained: #{exp_reward} XP"
    ]

    response_with_gold = add_gold_reward_to_response(base_response, gold_reward)
    response_with_items = add_item_rewards_to_response(response_with_gold, full_quest)

    response_with_level_up =
      add_level_up_message_to_response(response_with_items, level_up_message)

    response_with_level_up ++
      [
        "",
        "#{npc_name} says: \"Thank you for your service. You have proven yourself worthy!\""
      ]
  end

  # Helper function to add gold reward to response
  defp add_gold_reward_to_response(response, gold_reward) do
    if gold_reward > 0 do
      response ++ ["Gold received: #{gold_reward} gold"]
    else
      response
    end
  end

  # Helper function to add item rewards to response
  defp add_item_rewards_to_response(response, full_quest) do
    try do
      if full_quest && full_quest.item_rewards && map_size(full_quest.item_rewards) > 0 do
        item_list = Enum.map(full_quest.item_rewards, fn {_key, item} -> "  - #{item}" end)
        response ++ ["Items received:"] ++ item_list
      else
        response
      end
    rescue
      _error ->
        response
    end
  end

  # Helper function to add level up message to response
  defp add_level_up_message_to_response(response, level_up_message) do
    if level_up_message do
      response ++ ["", level_up_message]
    else
      response
    end
  end

  # Check if player should level up based on experience
  def check_level_up(stats) do
    if stats.experience >= stats.next_level_exp do
      new_level = stats.level + 1
      # Scaling experience requirement
      new_next_level_exp = stats.next_level_exp + new_level * 500

      updated_stats =
        stats
        |> Map.put(:level, new_level)
        |> Map.put(:next_level_exp, new_next_level_exp)
        # Increase core attributes
        |> Map.update(:strength, 10, &(&1 + 1))
        |> Map.update(:dexterity, 10, &(&1 + 1))
        |> Map.update(:intelligence, 10, &(&1 + 1))
        |> Map.update(:constitution, 10, &(&1 + 1))

      # Recalculate max stats based on new attributes
      new_max_health = 100 + (updated_stats.constitution - 10) * 5
      new_max_stamina = 100 + updated_stats.dexterity * 2
      new_max_mana = 50 + updated_stats.intelligence * 3

      updated_stats =
        updated_stats
        |> Map.put(:max_health, new_max_health)
        |> Map.put(:max_stamina, new_max_stamina)
        |> Map.put(:max_mana, new_max_mana)
        # Restore some health (but don't exceed new max)
        |> Map.update(:health, 100, &min(&1 + 10, new_max_health))

      level_up_message = "*** LEVEL UP! *** You are now level #{new_level}!"

      {updated_stats, level_up_message}
    else
      {stats, nil}
    end
  end
end
