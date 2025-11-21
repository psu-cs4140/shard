defmodule ShardWeb.UserLive.NpcCommands do
  @moduledoc """
  NPC-related command execution functions.
  """

  import ShardWeb.UserLive.MapHelpers

  # Execute talk command
  def execute_talk_command(game_state, npc_name) do
    # Ensure tutorial NPCs exist before checking
    ShardWeb.AdminLive.NpcHelpers.ensure_tutorial_npcs_exist()
    
    {x, y} = game_state.player_position
    npcs_here = get_npcs_at_location(x, y, game_state.character.current_zone_id)
    target_npc = find_npc_by_name(npcs_here, npc_name)

    case target_npc do
      nil ->
        {["There is no NPC named '#{npc_name}' here."], game_state}

      npc ->
        handle_npc_talk(game_state, npc)
    end
  end

  # Execute quest command
  def execute_quest_command(game_state, npc_name) do
    # Ensure tutorial NPCs exist before checking
    ShardWeb.AdminLive.NpcHelpers.ensure_tutorial_npcs_exist()
    
    {x, y} = game_state.player_position
    npcs_here = get_npcs_at_location(x, y, game_state.character.current_zone_id)
    target_npc = find_npc_by_name(npcs_here, npc_name)

    case target_npc do
      nil ->
        {["There is no NPC named '#{npc_name}' here."], game_state}

      npc ->
        handle_npc_quest(game_state, npc)
    end
  end

  # Helper function to handle talking to an NPC
  defp handle_npc_talk(game_state, npc) do
    user_id = game_state.character.user_id
    npc_name = npc.name || "Unknown NPC"

    # Check for available quests from this NPC
    available_quests = get_filtered_available_quests(user_id, npc.id, game_state.quests)

    # Check for quests that can be turned in to this NPC
    turn_in_quests = Shard.Quests.get_turn_in_quests_by_npc(user_id, npc.id)

    # Build dialogue based on quest status
    dialogue_lines =
      build_npc_dialogue(
        npc,
        npc_name,
        available_quests,
        turn_in_quests,
        user_id,
        game_state.character.id
      )

    {dialogue_lines, game_state}
  end

  # Helper function to handle quest interactions with an NPC
  defp handle_npc_quest(game_state, npc) do
    user_id = game_state.character.user_id
    npc_name = npc.name || "Unknown NPC"

    # Check for available quests from this NPC
    available_quests = get_filtered_available_quests(user_id, npc.id, game_state.quests)

    case available_quests do
      [] ->
        {["#{npc_name} says: \"I have no quests available for you at this time.\""], game_state}

      quests ->
        handle_quest_offering(game_state, npc, quests)
    end
  end

  # Helper function to handle quest offering
  defp handle_quest_offering(game_state, npc, available_quests) do
    npc_name = npc.name || "Unknown NPC"
    
    quest_lines = ["#{npc_name} offers you the following quests:", ""]
    
    quest_details = Enum.with_index(available_quests, 1)
    |> Enum.flat_map(fn {quest, index} ->
      [
        "#{index}. #{quest.title}",
        "   Description: #{quest.description}",
        "   Reward: #{quest.experience_reward || 0} exp, #{quest.gold_reward || 0} gold",
        ""
      ]
    end)

    instruction_lines = [
      "To accept a quest, use: accept_quest \"#{npc_name}\" \"<quest_title>\""
    ]

    all_lines = quest_lines ++ quest_details ++ instruction_lines
    {all_lines, game_state}
  end

  # Helper function to get filtered available quests
  defp get_filtered_available_quests(user_id, npc_id, player_quests) do
    available_quests =
      Shard.Quests.get_available_quests_by_giver_excluding_completed(user_id, npc_id)

    # Additional filter to ensure we don't show quests that are in the local game state as accepted
    # This helps catch timing issues where the database query might not reflect recent changes
    Enum.filter(available_quests, fn quest ->
      # Check if this quest is already in the player's quest log
      not Enum.any?(player_quests, fn player_quest ->
        player_quest[:id] == quest.id and
          player_quest[:status] in ["In Progress", "Completed"]
      end)
    end)
  end

  # Execute deliver_quest command
  def execute_deliver_quest_command(game_state, npc_name) do
    {x, y} = game_state.player_position
    npcs_here = get_npcs_at_location(x, y, game_state.character.current_zone_id)

    # Find the NPC by name (case-insensitive)
    target_npc = find_npc_by_name(npcs_here, npc_name)

    case target_npc do
      nil ->
        {["There is no NPC named '#{npc_name}' here."], game_state}

      npc ->
        process_quest_delivery(game_state, npc)
    end
  end

  # Helper function to find NPC by name
  defp find_npc_by_name(npcs, npc_name) do
    Enum.find(npcs, fn npc ->
      npc_name_lower = String.downcase(npc.name || "")
      target_name_lower = String.downcase(npc_name)
      npc_name_lower == target_name_lower
    end)
  end

  # Helper function to process quest delivery
  defp process_quest_delivery(game_state, npc) do
    user_id = game_state.character.user_id
    turn_in_quests = Shard.Quests.get_turn_in_quests_by_npc(user_id, npc.id)

    if Enum.empty?(turn_in_quests) do
      {["#{npc.name || "The NPC"} says: \"You don't have any completed quests for me.\""],
       game_state}
    else
      handle_quest_turn_ins(game_state, npc, turn_in_quests)
    end
  end

  # Helper function to handle quest turn-ins
  defp handle_quest_turn_ins(game_state, npc, turn_in_quests) do
    user_id = game_state.character.user_id
    character_id = game_state.character.id

    # Process each quest that can be turned in
    {results, completed_quest_ids} =
      Enum.reduce(turn_in_quests, {[], []}, fn quest, acc ->
        process_single_quest_turn_in(quest, user_id, character_id, acc)
      end)

    # Reverse results to maintain original order
    results = Enum.reverse(results)

    # Build response message
    npc_name = npc.name || "The NPC"
    response_lines = ["#{npc_name} examines your completed tasks:"] ++ results

    # Update game state to reflect changes
    updated_game_state = update_game_state_after_delivery(game_state, completed_quest_ids)

    {response_lines, updated_game_state}
  end

  # Helper function to process a single quest turn-in
  defp process_single_quest_turn_in(
         quest,
         user_id,
         character_id,
         {results_acc, completed_ids_acc}
       ) do
    case Shard.Quests.turn_in_quest_with_character_id(user_id, character_id, quest.id) do
      {:ok, {_quest_acceptance, given_items}} ->
        result = build_success_message_with_items(quest, given_items)
        {[result | results_acc], [quest.id | completed_ids_acc]}

      {:ok, _quest_acceptance} ->
        result = build_success_message_without_items(quest)
        {[result | results_acc], [quest.id | completed_ids_acc]}

      {:error, :missing_items} ->
        result = "Cannot turn in '#{quest.title}' - you don't have the required items"
        {[result | results_acc], completed_ids_acc}

      {:error, reason} ->
        result = "Failed to turn in '#{quest.title}': #{inspect(reason)}"
        {[result | results_acc], completed_ids_acc}
    end
  end

  # Helper function to build success message with items
  defp build_success_message_with_items(quest, given_items) do
    exp_reward = quest.experience_reward || 0
    gold_reward = quest.gold_reward || 0
    reward_parts = ["gained #{exp_reward} exp", "#{gold_reward} gold"]

    item_rewards = build_item_rewards_message(given_items)
    all_rewards = Enum.join(reward_parts ++ item_rewards, ", ")
    "Successfully turned in '#{quest.title}' (#{all_rewards})"
  end

  # Helper function to build success message without items
  defp build_success_message_without_items(quest) do
    exp_reward = quest.experience_reward || 0
    gold_reward = quest.gold_reward || 0
    "Successfully turned in '#{quest.title}' (gained #{exp_reward} exp, #{gold_reward} gold)"
  end

  # Helper function to build item rewards message
  defp build_item_rewards_message(given_items) do
    if length(given_items) > 0 do
      item_list = Enum.map(given_items, fn item -> "#{item.name} (x#{item.quantity})" end)
      ["items: #{Enum.join(item_list, ", ")}"]
    else
      []
    end
  end

  # Helper function to update game state after quest delivery
  defp update_game_state_after_delivery(game_state, completed_quest_ids) do
    # Early return if no quests were completed
    if Enum.empty?(completed_quest_ids), do: game_state

    # Reload character inventory to reflect item removal
    inventory_items = Shard.Items.get_character_inventory(game_state.character.id)

    # Update quest status in local game state
    updated_quests = update_completed_quests(game_state.quests, completed_quest_ids)

    %{game_state | inventory_items: inventory_items, quests: updated_quests}
  end

  # Helper function to update quest statuses
  defp update_completed_quests(quests, completed_quest_ids) do
    Enum.map(quests, fn quest ->
      if quest[:id] in completed_quest_ids do
        %{quest | status: "Completed", progress: "100% complete"}
      else
        quest
      end
    end)
  end

  # Helper function to build NPC dialogue
  defp build_npc_dialogue(npc, npc_name, available_quests, turn_in_quests, user_id, character_id) do
    # Start with basic greeting
    base_dialogue = npc.dialogue || "Hello there, traveler!"
    dialogue_lines = ["#{npc_name} says: \"#{base_dialogue}\""]

    # Add quest turn-in dialogue
    dialogue_lines =
      add_turn_in_dialogue(dialogue_lines, turn_in_quests, npc_name, user_id, character_id)

    # Add available quest dialogue
    dialogue_lines = add_available_quest_dialogue(dialogue_lines, available_quests, npc_name)

    # Add fallback dialogue if no quests
    add_fallback_dialogue(dialogue_lines, available_quests, turn_in_quests, npc_name)
  end

  # Helper function to add turn-in quest dialogue
  defp add_turn_in_dialogue(dialogue_lines, turn_in_quests, npc_name, user_id, character_id) do
    if Enum.any?(turn_in_quests) do
      {completable_quests, in_progress_quests} =
        categorize_turn_in_quests(turn_in_quests, user_id, character_id)

      dialogue_lines
      |> add_completable_quest_dialogue(completable_quests, npc_name)
      |> add_in_progress_quest_dialogue(in_progress_quests, npc_name)
    else
      dialogue_lines
    end
  end

  # Helper function to categorize turn-in quests
  defp categorize_turn_in_quests(turn_in_quests, user_id, character_id) do
    Enum.reduce(turn_in_quests, {[], []}, fn quest, {completable, in_progress} ->
      case Shard.Quests.can_turn_in_quest_with_character_id?(user_id, character_id, quest.id) do
        {:ok, true} -> {[quest | completable], in_progress}
        {:error, :missing_items} -> {completable, [quest | in_progress]}
        _ -> {completable, in_progress}
      end
    end)
  end

  # Helper function to add completable quest dialogue
  defp add_completable_quest_dialogue(dialogue_lines, completable_quests, npc_name) do
    if Enum.empty?(completable_quests) do
      dialogue_lines
    else
      quest_names = Enum.map(completable_quests, & &1.title)
      quest_list = Enum.join(quest_names, ", ")

      dialogue_lines ++
        [
          "",
          "#{npc_name} notices you have completed some tasks:",
          "\"Excellent! I see you have completed: #{quest_list}\"",
          "\"Use 'deliver_quest \"#{npc_name}\"' to turn in your completed quests.\""
        ]
    end
  end

  # Helper function to add in-progress quest dialogue
  defp add_in_progress_quest_dialogue(dialogue_lines, in_progress_quests, npc_name) do
    if Enum.empty?(in_progress_quests) do
      dialogue_lines
    else
      quest_names = Enum.map(in_progress_quests, & &1.title)
      quest_list = Enum.join(quest_names, ", ")

      dialogue_lines ++
        [
          "",
          "#{npc_name} checks on your progress:",
          "\"I see you're still working on: #{quest_list}\"",
          "\"Come back when you have everything I need.\""
        ]
    end
  end

  # Helper function to add available quest dialogue
  defp add_available_quest_dialogue(dialogue_lines, available_quests, npc_name) do
    if Enum.empty?(available_quests) do
      dialogue_lines
    else
      quest_names = Enum.map(available_quests, & &1.title)
      quest_list = Enum.join(quest_names, ", ")

      dialogue_lines ++
        [
          "",
          "#{npc_name} has tasks available for you:",
          "\"I have some work that needs doing: #{quest_list}\"",
          "\"Use 'quest \"#{npc_name}\"' to learn more about these tasks.\""
        ]
    end
  end

  # Helper function to add fallback dialogue
  defp add_fallback_dialogue(dialogue_lines, available_quests, turn_in_quests, npc_name) do
    if Enum.any?(available_quests) or Enum.any?(turn_in_quests) do
      dialogue_lines
    else
      dialogue_lines ++
        [
          "",
          "#{npc_name} has no tasks for you at this time."
        ]
    end
  end
end
