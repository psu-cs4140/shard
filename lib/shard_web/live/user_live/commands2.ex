defmodule ShardWeb.UserLive.Commands2 do
  import ShardWeb.UserLive.MapHelpers
  import ShardWeb.UserLive.QuestHandlers

  # Execute talk command with a specific NPC
  def execute_talk_command(game_state, npc_name) do
    {x, y} = game_state.player_position
    npcs_here = get_npcs_at_location(x, y, game_state.map_id)

    target_npc =
      Enum.find(npcs_here, fn npc ->
        String.downcase(npc.name || "") == String.downcase(npc_name)
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
        dialogue_response = generate_npc_dialogue(npc, game_state)
        {dialogue_response, game_state}
    end
  end

  # Execute quest command with a specific NPC
  def execute_quest_command(game_state, npc_name) do
    {x, y} = game_state.player_position
    npcs_here = get_npcs_at_location(x, y, game_state.map_id)

    target_npc =
      Enum.find(npcs_here, fn npc ->
        String.downcase(npc.name || "") == String.downcase(npc_name)
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
        generate_npc_quest_response(npc, game_state)
    end
  end

  # Execute deliver_quest command with a specific NPC
  def execute_deliver_quest_command(game_state, npc_name) do
    {x, y} = game_state.player_position
    npcs_here = get_npcs_at_location(x, y, game_state.map_id)

    target_npc =
      Enum.find(npcs_here, fn npc ->
        String.downcase(npc.name || "") == String.downcase(npc_name)
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
            complete_quest_and_give_rewards(game_state, quest, npc)
        end
    end
  end

  # Generate dialogue for an NPC
  def generate_npc_dialogue(npc, _game_state) do
    npc_name = npc.name || "Unknown NPC"

    dialogue =
      case npc.dialogue do
        nil -> "I don't have much to say right now."
        "" -> "..."
        dialogue_text when is_binary(dialogue_text) -> dialogue_text
        dialogue_text when is_list(dialogue_text) -> Enum.join(dialogue_text, " ")
        _ -> "I seem to be having trouble speaking."
      end

    personality_response =
      case npc.npc_type do
        "friendly" -> "#{npc_name} smiles warmly at you."
        "hostile" -> "#{npc_name} glares at you menacingly."
        "neutral" -> "#{npc_name} regards you with mild interest."
        "merchant" -> "#{npc_name} eyes you as a potential customer."
        "guard" -> "#{npc_name} stands at attention and nods formally."
        _ -> "#{npc_name} acknowledges your presence."
      end

    base =
      [
        personality_response,
        "",
        "#{npc_name} says: \"#{dialogue}\""
      ]

    available_quests = get_quests_by_giver_npc(npc.id)

    response =
      if Enum.empty?(available_quests) do
        base
      else
        # Append one block per quest without shadowing or unused vars
        Enum.reduce(available_quests, base ++ [""], fn quest, acc ->
          quest_status_text =
            case quest.status do
              "available" -> "#{npc_name} has a quest for you!"
              "active" -> "#{npc_name} is waiting for you to complete your current quest."
              "completed" -> "#{npc_name} thanks you for completing the quest."
              _ -> "#{npc_name} mentions something about a quest."
            end

          title = quest.title || "Untitled Quest"

          quest_description =
            quest.short_description || quest.description || "A mysterious quest awaits."

          acc =
            acc ++
              [
                quest_status_text,
                "",
                "Quest: #{title}",
                quest_description
              ]

          # Only include detailed rewards/requirements for "available" quests
          if quest.status == "available" do
            details =
              []
              |> maybe_push(
                quest.experience_reward && quest.experience_reward > 0,
                "Reward: #{quest.experience_reward} experience"
              )
              |> maybe_push(
                quest.gold_reward && quest.gold_reward > 0,
                "Gold Reward: #{quest.gold_reward} gold"
              )
              |> maybe_push(
                quest.min_level && quest.min_level > 0,
                "Minimum Level: #{quest.min_level}"
              )

            if details == [] do
              acc
            else
              acc ++ [""] ++ details
            end
          else
            acc
          end
        end)
      end

    response ++ ["", "#{npc_name} waits to see if you have anything else to say."]
  end

  # Generate quest response for an NPC
  def generate_npc_quest_response(npc, game_state) do
    npc_name = npc.name || "Unknown NPC"

    # TODO: Replace mock user_id with current session's user id when available
    user_id = 1

    available_quests =
      try do
        get_quests_by_giver_npc_excluding_completed(npc.id, user_id)
      rescue
        _error ->
          nil
          # IO.inspect(error, label: "Error getting quests for NPC #{npc.id}")
          # []
      end

    if Enum.empty?(available_quests) do
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
      quest = hd(available_quests)
      quest_title = quest.title || "Untitled Quest"
      quest_description = quest.description || "A mysterious quest awaits."

      header = [
        "#{npc_name} brightens up when you ask about quests.",
        "",
        "=== #{quest_title} ===",
        quest_description,
        ""
      ]

      # Build details safely using rebinds (not inner-scope assignments)
      details = []

      details =
        if quest.difficulty do
          details ++ ["Difficulty: #{String.capitalize(to_string(quest.difficulty))}"]
        else
          details
        end

      details =
        if quest.min_level && quest.min_level > 0 do
          details ++ ["Minimum Level: #{quest.min_level}"]
        else
          details
        end

      details =
        if quest.max_level && quest.max_level > 0 do
          details ++ ["Maximum Level: #{quest.max_level}"]
        else
          details
        end

      details =
        if quest.experience_reward && quest.experience_reward > 0 do
          details ++ ["Experience Reward: #{quest.experience_reward} XP"]
        else
          details
        end

      details =
        if quest.gold_reward && quest.gold_reward > 0 do
          details ++ ["Gold Reward: #{quest.gold_reward} gold"]
        else
          details
        end

      details =
        if quest.time_limit && quest.time_limit > 0 do
          details ++ ["Time Limit: #{quest.time_limit} hours"]
        else
          details
        end

      objectives =
        case quest.objectives do
          objectives when is_map(objectives) and map_size(objectives) > 0 ->
            ["Objectives:"] ++ Enum.map(objectives, fn {_k, v} -> "  - #{v}" end)

          _ ->
            []
        end

      prerequisites =
        case quest.prerequisites do
          prereqs when is_map(prereqs) and map_size(prereqs) > 0 ->
            ["Prerequisites:"] ++ Enum.map(prereqs, fn {_k, v} -> "  - #{v}" end)

          _ ->
            []
        end

      full_response =
        header ++
          details ++
          objectives ++
          prerequisites ++
          [
            "",
            "#{npc_name} says: \"Would you like to accept this quest?\"",
            "",
            "Type 'accept' to accept the quest or 'deny' to decline it."
          ]

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

  # ─────────────────────────── helpers ───────────────────────────

  defp maybe_push(list, true, item), do: list ++ [item]
  defp maybe_push(list, _cond, _item), do: list
end
