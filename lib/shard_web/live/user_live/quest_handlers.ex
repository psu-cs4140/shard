defmodule ShardWeb.UserLive.QuestHandlers do
  alias Shard.Repo
  alias Shard.Quests.Quest
  # Execute quest acceptance
  def execute_accept_quest(game_state) do
    case game_state.pending_quest_offer do
      nil ->
        {["There is no quest offer to accept."], game_state}

      %{quest: quest, npc: npc} ->
        npc_name = npc.name || "Unknown NPC"
        quest_title = quest.title || "Untitled Quest"

        # Check if quest has already been accepted or completed
        # Mock user_id - should come from session in real implementation
        user_id = 1

        already_accepted =
          try do
            Shard.Quests.quest_ever_accepted_by_user?(user_id, quest.id)
          rescue
            _error ->
              # IO.inspect(error, label: "Error checking if quest already accepted")
              false
          end

        if already_accepted do
          response = [
            "#{npc_name} looks at you with confusion.",
            "",
            "\"You have already accepted this quest. I cannot offer it to you again.\""
          ]

          updated_game_state = %{game_state | pending_quest_offer: nil}
          {response, updated_game_state}
        else
          # Accept the quest in the database
          accept_result =
            try do
              Shard.Quests.accept_quest(user_id, quest.id)
            rescue
              _error ->
                # IO.inspect(error, label: "Error accepting quest") 
                {:error, :database_error}
            end

          case accept_result do
            {:ok, _quest_acceptance} ->
              # Add quest to player's active quests in game state
              new_quest = %{
                id: quest.id,
                title: quest_title,
                status: "In Progress",
                progress: "0% complete",
                npc_giver: npc_name,
                description: quest.description
              }

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

            {:error, :quest_already_completed} ->
              response = [
                "#{npc_name} looks at you with confusion.",
                "",
                "\"You have already completed this quest. I cannot offer it to you again.\""
              ]

              updated_game_state = %{game_state | pending_quest_offer: nil}
              {response, updated_game_state}

            {:error, :database_error} ->
              # Fallback: add quest to game state even if database fails
              new_quest = %{
                id: quest.id,
                title: quest_title,
                status: "In Progress",
                progress: "0% complete",
                npc_giver: npc_name,
                description: quest.description
              }

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

            {:error, _changeset} ->
              response = [
                "#{npc_name} looks troubled.",
                "",
                "\"I'm sorry, but there seems to be an issue with accepting this quest right now.\""
              ]

              updated_game_state = %{game_state | pending_quest_offer: nil}
              {response, updated_game_state}
          end
        end
    end
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

    # Get the full quest data from database with error handling
    full_quest =
      try do
        Repo.get(Quest, quest.id)
      rescue
        _error ->
          # IO.inspect(error, label: "Error getting quest #{quest.id} from database")
          nil
      end

    # Calculate rewards (use database values or defaults)
    exp_reward = if full_quest, do: full_quest.experience_reward || 100, else: 100
    gold_reward = if full_quest, do: full_quest.gold_reward || 50, else: 50

    # Update player stats with rewards
    updated_stats =
      try do
        game_state.player_stats
        |> Map.update(:experience, 0, &(&1 + exp_reward))
      rescue
        _error ->
          # IO.inspect(error, label: "Error updating player stats")
          game_state.player_stats
      end

    # Check if player levels up
    {updated_stats, level_up_message} =
      try do
        check_level_up(updated_stats)
      rescue
        _error ->
          # IO.inspect(error, label: "Error checking level up")
          {updated_stats, nil}
      end

    # Complete the quest in the database
    # Mock user_id - should come from session in real implementation
    user_id = 1

    updated_quests =
      try do
        case Shard.Quests.complete_quest(user_id, quest.id) do
          {:ok, _quest_acceptance} ->
            # Mark the quest as completed in player's quest list
            Enum.map(game_state.quests, fn q ->
              if q[:id] == quest.id do
                %{q | status: "Completed", progress: "100% complete"}
              else
                q
              end
            end)

          {:error, _} ->
            # If database update fails, still update game state for consistency
            Enum.map(game_state.quests, fn q ->
              if q[:id] == quest.id do
                %{q | status: "Completed", progress: "100% complete"}
              else
                q
              end
            end)
        end
      rescue
        _error ->
          # IO.inspect(error, label: "Error completing quest in database")
          # Fallback: update game state even if database fails
          Enum.map(game_state.quests, fn q ->
            if q[:id] == quest.id do
              %{q | status: "Completed", progress: "100% complete"}
            else
              q
            end
          end)
      end

    # Build response message
    response = [
      "#{npc_name} examines your progress carefully.",
      "",
      "\"Excellent work! You have completed the quest '#{quest_title}'!\"",
      "",
      "Quest Completed: #{quest_title}",
      "Experience gained: #{exp_reward} XP"
    ]

    response =
      if gold_reward > 0 do
        response ++ ["Gold received: #{gold_reward} gold"]
      else
        response
      end

    # Add item rewards if any (with error handling)
    response =
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

    # Add level up message if applicable
    response =
      if level_up_message do
        response ++ ["", level_up_message]
      else
        response
      end

    response =
      response ++
        [
          "",
          "#{npc_name} says: \"Thank you for your service. You have proven yourself worthy!\""
        ]

    # Update game state
    updated_game_state = %{game_state | player_stats: updated_stats, quests: updated_quests}

    {response, updated_game_state}
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
