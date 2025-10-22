defmodule ShardWeb.UserLive.QuestHandlers do
  alias Shard.Repo
  alias Shard.Quests.Quest
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
    # Mock user_id - should come from session in real implementation
    user_id = 1

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
      Shard.Quests.quest_ever_accepted_by_user?(user_id, quest_id)
    rescue
      _error ->
        # IO.inspect(error, label: "Error checking if quest already accepted")
        false
    end
  end

  # Handle case where quest was already accepted
  defp handle_already_accepted_quest(game_state, npc_name) do
    response = [
      "#{npc_name} looks at you with confusion.",
      "",
      "\"You have already accepted this quest. I cannot offer it to you again.\""
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
    try do
      Shard.Quests.accept_quest(user_id, quest_id)
    rescue
      _error ->
        # IO.inspect(error, label: "Error accepting quest") 
        {:error, :database_error}
    end
  end

  # Handle the result of quest acceptance attempt
  defp handle_quest_acceptance_result(game_state, quest, npc_name, quest_title, accept_result) do
    case accept_result do
      {:ok, _quest_acceptance} ->
        handle_successful_quest_acceptance(game_state, quest, npc_name, quest_title)

      {:error, :quest_already_completed} ->
        handle_quest_already_completed(game_state, npc_name)

      {:error, :database_error} ->
        handle_database_error_fallback(game_state, quest, npc_name, quest_title)

      {:error, _changeset} ->
        handle_quest_acceptance_error(game_state, npc_name)
    end
  end

  # Handle successful quest acceptance
  defp handle_successful_quest_acceptance(game_state, quest, npc_name, quest_title) do
    new_quest = create_new_quest_entry(quest, npc_name, quest_title)
    updated_quests = [new_quest | game_state.quests]

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

  # Handle database error fallback
  defp handle_database_error_fallback(game_state, quest, npc_name, quest_title) do
    new_quest = create_new_quest_entry(quest, npc_name, quest_title)
    updated_quests = [new_quest | game_state.quests]

    response = [
      "You accept the quest '#{quest_title}' from #{npc_name}.",
      "",
      "#{npc_name} says: \"Excellent! I knew I could count on you.\"",
      "",
      "Quest '#{quest_title}' has been added to your quest log.",
      "(Note: Quest saved locally due to database issue)"
    ]

    updated_game_state = %{
      game_state
      | quests: updated_quests,
        pending_quest_offer: nil
    }

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
              # IO.inspect(error, label: "Error getting quest #{quest.id} from database")
              false
          end
        else
          false
        end
      end)
    rescue
      _error ->
        # IO.inspect(error, label: "Error finding deliverable quest")
        nil
    end
  end

  # Complete the quest and give rewards to the player
  def complete_quest_and_give_rewards(game_state, quest, npc) do
    npc_name = npc.name || "Unknown NPC"
    quest_title = quest.title || "Untitled Quest"

    full_quest = get_full_quest_safely(quest.id)
    {exp_reward, gold_reward} = calculate_quest_rewards(full_quest)

    updated_stats = update_player_stats_with_experience(game_state.player_stats, exp_reward)
    {updated_stats, level_up_message} = handle_level_up_check(updated_stats)

    updated_quests = complete_quest_in_database_and_update_state(game_state.quests, quest.id)

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
        # IO.inspect(error, label: "Error getting quest #{quest_id} from database")
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
        # IO.inspect(error, label: "Error updating player stats")
        player_stats
    end
  end

  # Helper function to handle level up check
  defp handle_level_up_check(updated_stats) do
    try do
      check_level_up(updated_stats)
    rescue
      _error ->
        # IO.inspect(error, label: "Error checking level up")
        {updated_stats, nil}
    end
  end

  # Helper function to complete quest in database and update game state
  defp complete_quest_in_database_and_update_state(quests, quest_id) do
    # Mock user_id - should come from session in real implementation
    user_id = 1

    try do
      case Shard.Quests.complete_quest(user_id, quest_id) do
        {:ok, _quest_acceptance} ->
          mark_quest_as_completed(quests, quest_id)

        {:error, _} ->
          mark_quest_as_completed(quests, quest_id)
      end
    rescue
      _error ->
        # IO.inspect(error, label: "Error completing quest in database")
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
        # IO.inspect(error, label: "Error processing item rewards")
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
