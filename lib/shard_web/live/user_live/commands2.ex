defmodule ShardWeb.UserLive.Commands2 do
  import ShardWeb.UserLive.MapHelpers
  import ShardWeb.UserLive.QuestHandlers

  # Execute talk command with a specific NPC
  def execute_talk_command(game_state, npc_name) do
    {x, y} = game_state.player_position
    npcs_here = get_npcs_at_location(x, y, game_state.map_id)

    # Find the NPC by name (case-insensitive)
    target_npc =
      Enum.find(npcs_here, fn npc ->
        npc_name_normalized = String.downcase(npc.name || "")
        input_name_normalized = String.downcase(npc_name)
        npc_name_normalized == input_name_normalized
      end)

    case target_npc do
      nil ->
        if length(npcs_here) > 0 do
          available_names = Enum.map(npcs_here, & &1.name) |> Enum.join(", ")

          response = [
            "There is no NPC named '#{npc_name}' here.",
            "Available NPCs: #{available_names}"
          ]

          {response, game_state}
        else
          {["There are no NPCs here to talk to."], game_state}
        end

      npc ->
        # Generate dialogue based on NPC
        dialogue_response = generate_npc_dialogue(npc, game_state)
        {dialogue_response, game_state}
    end
  end

  # Execute quest command with a specific NPC
  def execute_quest_command(game_state, npc_name) do
    {x, y} = game_state.player_position
    npcs_here = get_npcs_at_location(x, y, game_state.map_id)

    # Find the NPC by name (case-insensitive)
    target_npc =
      Enum.find(npcs_here, fn npc ->
        npc_name_normalized = String.downcase(npc.name || "")
        input_name_normalized = String.downcase(npc_name)
        npc_name_normalized == input_name_normalized
      end)

    case target_npc do
      nil ->
        if length(npcs_here) > 0 do
          available_names = Enum.map(npcs_here, & &1.name) |> Enum.join(", ")

          response = [
            "There is no NPC named '#{npc_name}' here.",
            "Available NPCs: #{available_names}"
          ]

          {response, game_state}
        else
          {["There are no NPCs here to ask for quests."], game_state}
        end

      npc ->
        # Get quests from this NPC
        generate_npc_quest_response(npc, game_state)
    end
  end

  # Execute deliver_quest command with a specific NPC
  def execute_deliver_quest_command(game_state, npc_name) do
    {x, y} = game_state.player_position
    npcs_here = get_npcs_at_location(x, y, game_state.map_id)

    # Find the NPC by name (case-insensitive)
    target_npc =
      Enum.find(npcs_here, fn npc ->
        npc_name_normalized = String.downcase(npc.name || "")
        input_name_normalized = String.downcase(npc_name)
        npc_name_normalized == input_name_normalized
      end)

    case target_npc do
      nil ->
        if length(npcs_here) > 0 do
          available_names = Enum.map(npcs_here, & &1.name) |> Enum.join(", ")

          response = [
            "There is no NPC named '#{npc_name}' here.",
            "Available NPCs: #{available_names}"
          ]

          {response, game_state}
        else
          {["There are no NPCs here to deliver quests to."], game_state}
        end

      npc ->
        # Find active quests that can be turned in to this NPC
        deliverable_quest = find_deliverable_quest(game_state.quests, npc)

        case deliverable_quest do
          nil ->
            npc_display_name = npc.name || "Unknown NPC"

            response = [
              "#{npc_display_name} looks at you expectantly.",
              "",
              "\"I don't see any completed quests that you can turn in to me.\""
            ]

            {response, game_state}

          quest ->
            # Complete the quest and give rewards
            complete_quest_and_give_rewards(game_state, quest, npc)
        end
    end
  end

  # Generate dialogue for an NPC
  def generate_npc_dialogue(npc, _game_state) do
    npc_name = npc.name || "Unknown NPC"

    # Get dialogue from NPC record
    dialogue =
      case npc.dialogue do
        nil -> "I don't have much to say right now."
        "" -> "..."
        dialogue_text when is_binary(dialogue_text) -> dialogue_text
        dialogue_text when is_list(dialogue_text) -> Enum.join(dialogue_text, " ")
        _ -> "I seem to be having trouble speaking."
      end

    # Add some personality based on NPC type
    personality_response =
      case npc.npc_type do
        "friendly" -> "#{npc_name} smiles warmly at you."
        "hostile" -> "#{npc_name} glares at you menacingly."
        "neutral" -> "#{npc_name} regards you with mild interest."
        "merchant" -> "#{npc_name} eyes you as a potential customer."
        "guard" -> "#{npc_name} stands at attention and nods formally."
        _ -> "#{npc_name} acknowledges your presence."
      end

    # Check for quests this NPC can give
    available_quests = get_quests_by_giver_npc(npc.id)

    response = [
      personality_response,
      "",
      "#{npc_name} says: \"#{dialogue}\""
    ]

    # Add quest information if any quests are available
    if length(available_quests) > 0 do
      response = response ++ [""]

      for quest <- available_quests do
        quest_status_text =
          case quest.status do
            "available" -> "#{npc_name} has a quest for you!"
            "active" -> "#{npc_name} is waiting for you to complete your current quest."
            "completed" -> "#{npc_name} thanks you for completing the quest."
            _ -> "#{npc_name} mentions something about a quest."
          end

        quest_description =
          quest.short_description || quest.description || "A mysterious quest awaits."

        response =
          response ++
            [
              quest_status_text,
              "",
              "Quest: #{quest.title}",
              quest_description
            ]

        # Add quest details for available quests
        if quest.status == "available" do
          response = response ++ [""]

          if quest.experience_reward && quest.experience_reward > 0 do
            response = response ++ ["Reward: #{quest.experience_reward} experience"]
          end

          if quest.gold_reward && quest.gold_reward > 0 do
            response = response ++ ["Gold Reward: #{quest.gold_reward} gold"]
          end

          if quest.min_level && quest.min_level > 0 do
            response = response ++ ["Minimum Level: #{quest.min_level}"]
          end
        end
      end
    end

    response ++
      [
        "",
        "#{npc_name} waits to see if you have anything else to say."
      ]
  end

  # Generate quest response for an NPC
  def generate_npc_quest_response(npc, game_state) do
    npc_name = npc.name || "Unknown NPC"

    # Get quests this NPC can give, excluding completed ones
    # For now, we'll use a mock user_id of 1 - in a real implementation,
    # this should come from the current user session
    user_id = 1

    available_quests =
      try do
        get_quests_by_giver_npc_excluding_completed(npc.id, user_id)
      rescue
        error ->
          IO.inspect(error, label: "Error getting quests for NPC #{npc.id}")
          []
      end

    if length(available_quests) == 0 do
      # Check if there are any quests from this NPC that were completed
      all_quests =
        try do
          get_quests_by_giver_npc(npc.id)
        rescue
          _ -> []
        end

      completed_quests =
        try do
          Enum.filter(all_quests, fn quest ->
            quest_completed_by_user_in_game_state?(quest.id, game_state)
          end)
        rescue
          _ -> []
        end

      response =
        if length(completed_quests) > 0 do
          [
            "#{npc_name} looks at you with recognition.",
            "",
            "\"Thank you for all the help you've provided. I don't have any new quests for you at the moment.\""
          ]
        else
          [
            "#{npc_name} looks at you thoughtfully.",
            "",
            "\"I don't have any quests for you at the moment.\""
          ]
        end

      {response, game_state}
    else
      # For now, offer the first available quest
      quest = List.first(available_quests)
      quest_title = quest.title || "Untitled Quest"
      quest_description = quest.description || "A mysterious quest awaits."

      response = [
        "#{npc_name} brightens up when you ask about quests.",
        "",
        "=== #{quest_title} ===",
        quest_description,
        ""
      ]

      # Add quest details
      details = []

      if quest.difficulty do
        details = details ++ ["Difficulty: #{String.capitalize(quest.difficulty)}"]
      end

      if quest.min_level && quest.min_level > 0 do
        details = details ++ ["Minimum Level: #{quest.min_level}"]
      end

      if quest.max_level && quest.max_level > 0 do
        details = details ++ ["Maximum Level: #{quest.max_level}"]
      end

      if quest.experience_reward && quest.experience_reward > 0 do
        details = details ++ ["Experience Reward: #{quest.experience_reward} XP"]
      end

      if quest.gold_reward && quest.gold_reward > 0 do
        details = details ++ ["Gold Reward: #{quest.gold_reward} gold"]
      end

      if quest.time_limit && quest.time_limit > 0 do
        details = details ++ ["Time Limit: #{quest.time_limit} hours"]
      end

      # Add objectives if available
      objectives =
        case quest.objectives do
          objectives when is_map(objectives) and map_size(objectives) > 0 ->
            objective_list = Enum.map(objectives, fn {_key, value} -> "  - #{value}" end)
            ["Objectives:"] ++ objective_list

          _ ->
            []
        end

      # Add prerequisites if any
      prerequisites =
        case quest.prerequisites do
          prereqs when is_map(prereqs) and map_size(prereqs) > 0 ->
            prereq_list = Enum.map(prereqs, fn {_key, value} -> "  - #{value}" end)
            ["Prerequisites:"] ++ prereq_list

          _ ->
            []
        end

      # Combine all quest information
      full_response =
        response ++
          details ++
          objectives ++
          prerequisites ++
          [
            "",
            "#{npc_name} says: \"Would you like to accept this quest?\"",
            "",
            "Type 'accept' to accept the quest or 'deny' to decline it."
          ]

      # Store the quest offer in game state
      updated_game_state = %{
        game_state
        | pending_quest_offer: %{
            quest: quest,
            npc: npc
          }
      }

      {full_response, updated_game_state}
    end
  end
end
