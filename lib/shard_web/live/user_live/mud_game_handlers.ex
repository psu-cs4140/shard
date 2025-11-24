defmodule ShardWeb.UserLive.MudGameHandlers do
  @moduledoc """
  Event handlers and helper functions for MudGameLive
  """
  use ShardWeb, :live_view
  import ShardWeb.UserLive.Movement
  import ShardWeb.UserLive.Commands1
  import ShardWeb.UserLive.LegacyMap
  import ShardWeb.UserLive.CharacterHelpers
  import ShardWeb.UserLive.ItemHelpers

  def handle_keypress(%{"key" => key}, socket) do
    # Check if it's a movement key
    case key do
      arrow_key when arrow_key in ["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"] ->
        # Use the same execute_movement function that terminal commands use
        {response, updated_game_state} = execute_movement(socket.assigns.game_state, arrow_key)
        popup_result = :no_popup

        # Add the response to terminal output
        new_output = socket.assigns.terminal_state.output ++ response ++ [""]
        terminal_state = Map.put(socket.assigns.terminal_state, :output, new_output)

        # Handle completion popup
        modal_state =
          case popup_result do
            {:show_completion_popup, message} ->
              %{show: true, type: "dungeon_completion", completion_message: message}

            :no_popup ->
              socket.assigns.modal_state
          end

        socket =
          assign(socket,
            game_state: updated_game_state,
            terminal_state: terminal_state,
            modal_state: modal_state,
            available_exits:
              compute_available_exits(updated_game_state.player_position, updated_game_state)
          )

        {:noreply, socket, updated_game_state, terminal_state, updated_game_state.player_position}

      _ ->
        # Non-movement key, do nothing
        {:noreply, socket, socket.assigns.game_state, socket.assigns.terminal_state,
         socket.assigns.game_state.player_position}
    end
  end

  def handle_submit_command(%{"command" => %{"text" => command_text}}, socket) do
    trimmed_command = String.trim(command_text)

    if trimmed_command == "" do
      {:noreply, socket}
    else
      process_non_empty_command(trimmed_command, socket)
    end
  end

  defp process_non_empty_command(trimmed_command, socket) do
    # Add command to history
    new_history = [trimmed_command | socket.assigns.terminal_state.command_history]

    # Process the command and get response and updated game state
    {response, updated_game_state} = process_command(trimmed_command, socket.assigns.game_state)

    # Check if stats changed significantly and save to database
    old_stats = socket.assigns.game_state.player_stats
    new_stats = updated_game_state.player_stats

    if stats_changed_significantly?(old_stats, new_stats) do
      save_character_stats(updated_game_state.character, new_stats)
    end

    # Check if this was a quest completion command and reload character data if needed
    final_game_state = handle_quest_completion(trimmed_command, updated_game_state, new_stats)

    # Add command and response to output
    new_output =
      socket.assigns.terminal_state.output ++
        ["> #{trimmed_command}"] ++
        response ++
        [""]

    terminal_state = %{
      output: new_output,
      command_history: new_history,
      current_command: ""
    }

    socket =
      assign(socket,
        game_state: final_game_state,
        terminal_state: terminal_state
      )

    {:noreply, socket, final_game_state, terminal_state}
  end

  defp handle_quest_completion(command, updated_game_state, new_stats) do
    if quest_completion_command?(command) do
      reload_character_if_needed(updated_game_state, new_stats)
    else
      updated_game_state
    end
  end

  defp reload_character_if_needed(updated_game_state, new_stats) do
    case reload_character_from_database(updated_game_state.character.id) do
      nil ->
        updated_game_state

      reloaded_character ->
        # Update game state with reloaded character and synced stats
        synced_stats = sync_player_stats_with_character(new_stats, reloaded_character)
        %{updated_game_state | character: reloaded_character, player_stats: synced_stats}
    end
  end

  def handle_update_command(%{"command" => %{"text" => command_text}}, socket) do
    terminal_state = Map.put(socket.assigns.terminal_state, :current_command, command_text)
    socket = assign(socket, terminal_state: terminal_state)
    {:noreply, socket, terminal_state}
  end

  def handle_save_character_stats(_params, socket) do
    # Manually save character stats to database
    case save_character_stats(
           socket.assigns.game_state.character,
           socket.assigns.game_state.player_stats
         ) do
      {:ok, _character} ->
        {:noreply, socket, "Character stats saved successfully."}

      {:error, _error} ->
        {:noreply, socket, "Failed to save character stats."}
    end
  end

  def handle_use_hotbar_item(%{"slot" => slot_number}, socket) do
    slot_key = String.to_atom("slot_#{slot_number}")
    item = Map.get(socket.assigns.game_state.hotbar, slot_key)

    case item do
      nil ->
        # Add empty slot message to terminal
        new_output =
          socket.assigns.terminal_state.output ++ ["Hotbar slot #{slot_number} is empty"] ++ [""]

        terminal_state = Map.put(socket.assigns.terminal_state, :output, new_output)
        socket = assign(socket, terminal_state: terminal_state)

        {:noreply, socket, socket.assigns.game_state, terminal_state}

      item ->
        {response, updated_game_state} = use_item(socket.assigns.game_state, item)

        # Add response to terminal
        new_output = socket.assigns.terminal_state.output ++ response ++ [""]
        terminal_state = Map.put(socket.assigns.terminal_state, :output, new_output)
        socket = assign(socket, game_state: updated_game_state, terminal_state: terminal_state)

        {:noreply, socket, updated_game_state, terminal_state}
    end
  end

  def handle_use_hotbar_item(%{"item_id" => item_id} = _params, socket) do
    # Handle case where item_id is provided instead of slot
    # Find item in inventory by item_id
    item =
      Enum.find(socket.assigns.game_state.inventory_items, fn inv_item ->
        to_string(Map.get(inv_item, :id)) == item_id
      end)

    case item do
      nil ->
        # Add error message to terminal
        new_output =
          socket.assigns.terminal_state.output ++ ["Item not found in inventory."] ++ [""]

        terminal_state = Map.put(socket.assigns.terminal_state, :output, new_output)
        socket = assign(socket, terminal_state: terminal_state)

        {:noreply, socket, socket.assigns.game_state, terminal_state}

      item ->
        {response, updated_game_state} = use_item(socket.assigns.game_state, item)

        # Add response to terminal
        new_output = socket.assigns.terminal_state.output ++ response ++ [""]
        terminal_state = Map.put(socket.assigns.terminal_state, :output, new_output)
        socket = assign(socket, game_state: updated_game_state, terminal_state: terminal_state)

        {:noreply, socket, updated_game_state, terminal_state}
    end
  end

  def handle_equip_item(%{"item_id" => item_id}, socket) do
    # Find item in inventory
    item =
      Enum.find(socket.assigns.game_state.inventory_items, fn inv_item ->
        to_string(Map.get(inv_item, :id)) == item_id
      end)

    case item do
      nil ->
        # Add error message to terminal
        new_output =
          socket.assigns.terminal_state.output ++ ["Item not found in inventory."] ++ [""]

        terminal_state = Map.put(socket.assigns.terminal_state, :output, new_output)
        socket = assign(socket, terminal_state: terminal_state)

        {:noreply, socket, socket.assigns.game_state, terminal_state}

      item ->
        {response, updated_game_state} = equip_item(socket.assigns.game_state, item)

        # Add response to terminal
        new_output = socket.assigns.terminal_state.output ++ response ++ [""]
        terminal_state = Map.put(socket.assigns.terminal_state, :output, new_output)
        socket = assign(socket, game_state: updated_game_state, terminal_state: terminal_state)

        {:noreply, socket, updated_game_state, terminal_state}
    end
  end

  def handle_click_exit(%{"dir" => dir}, socket) do
    key = dir_to_key(dir)
    player_position = socket.assigns.game_state.player_position
    game_state = socket.assigns.game_state

    new_position =
      case key do
        nil -> player_position
        _ -> calc_position(player_position, key, game_state)
      end

    terminal_state =
      if new_position != player_position do
        msg = "You move #{dir}."
        Map.update!(socket.assigns.terminal_state, :output, &(&1 ++ [msg, ""]))
      else
        socket.assigns.terminal_state
      end

    game_state = %{
      socket.assigns.game_state
      | player_position: new_position
    }

    socket =
      assign(socket,
        game_state: game_state,
        terminal_state: terminal_state,
        available_exits: compute_available_exits(game_state.player_position, game_state)
      )

    {:noreply, socket, game_state, terminal_state, game_state.player_position}
  end

  def add_message_to_output(terminal_state, message) do
    new_output = terminal_state.output ++ [message] ++ [""]
    Map.put(terminal_state, :output, new_output)
  end

  def handle_noise_info({:noise, text}, socket) do
    terminal_state = add_message_to_output(socket.assigns.terminal_state, text)
    socket = assign(socket, terminal_state: terminal_state)
    {:noreply, socket, terminal_state}
  end

  def handle_area_heal_info({:area_heal, xx, msg}, socket) do
    terminal_state =
      socket.assigns.terminal_state
      |> add_message_to_output(msg)
      |> add_message_to_output("Area heal effect: #{xx} damage healed")

    current_stats = socket.assigns.game_state.player_stats
    max_health = current_stats.max_health
    current_health = current_stats.health

    if current_health < max_health do
      new_health = min(current_health + xx, max_health)

      updated_stats = %{current_stats | health: new_health}
      updated_game_state = %{socket.assigns.game_state | player_stats: updated_stats}

      # Save updated stats to database
      save_character_stats(socket.assigns.game_state.character, updated_stats)

      socket = assign(socket, game_state: updated_game_state, terminal_state: terminal_state)
      {:noreply, socket, updated_game_state, terminal_state}
    else
      socket = assign(socket, terminal_state: terminal_state)
      {:noreply, socket, terminal_state}
    end
  end

  def handle_update_game_state_info({:update_game_state, new_game_state}, socket) do
    socket = assign(socket, game_state: new_game_state)
    {:noreply, socket, new_game_state}
  end

  def handle_combat_event_info({:combat_event, event}, socket) do
    case event do
      %{type: :effect_tick, effect: "bleed", target: {:player, player_id}, dmg: dmg} ->
        # Check if this is our player
        if socket.assigns.game_state.character.id == player_id do
          current_stats = socket.assigns.game_state.player_stats
          new_health = max(current_stats.health - dmg, 0)
          updated_stats = %{current_stats | health: new_health}
          updated_game_state = %{socket.assigns.game_state | player_stats: updated_stats}

          terminal_state =
            add_message_to_output(socket.assigns.terminal_state, "You take #{dmg} bleed damage!")

          socket = assign(socket, game_state: updated_game_state, terminal_state: terminal_state)
          {:noreply, socket, updated_game_state, terminal_state}
        else
          terminal_state =
            add_message_to_output(
              socket.assigns.terminal_state,
              "Another player takes bleed damage!"
            )

          socket = assign(socket, terminal_state: terminal_state)
          {:noreply, socket, terminal_state}
        end

      %{type: :victory} ->
        terminal_state =
          add_message_to_output(
            socket.assigns.terminal_state,
            "Victory! All monsters have been defeated!"
          )

        updated_game_state = %{socket.assigns.game_state | combat: false}
        socket = assign(socket, game_state: updated_game_state, terminal_state: terminal_state)
        {:noreply, socket, updated_game_state, terminal_state}

      %{type: :defeat} ->
        terminal_state =
          add_message_to_output(socket.assigns.terminal_state, "Defeat! All players have fallen!")

        updated_game_state = %{socket.assigns.game_state | combat: false}
        socket = assign(socket, game_state: updated_game_state, terminal_state: terminal_state)
        {:noreply, socket, updated_game_state, terminal_state}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_player_joined_combat_info({:player_joined_combat, player_name}, socket) do
    terminal_state =
      add_message_to_output(socket.assigns.terminal_state, "#{player_name} joins the battle!")

    socket = assign(socket, terminal_state: terminal_state)
    {:noreply, socket, terminal_state}
  end

  def handle_player_left_combat_info({:player_left_combat, player_name}, socket) do
    terminal_state =
      add_message_to_output(socket.assigns.terminal_state, "#{player_name} leaves the battle!")

    socket = assign(socket, terminal_state: terminal_state)
    {:noreply, socket, terminal_state}
  end

  def handle_combat_action_info({:combat_action, event}, socket) do
    handle_player_attack(event, socket) ||
      handle_monster_attack(event, socket) ||
      handle_player_fled(event, socket) ||
      {:noreply, socket}
  end

  defp handle_player_attack(
         {:player_attack, attacker_name, monster_name, damage, monster_alive, remaining_hp},
         socket
       ) do
    if attacker_name == socket.assigns.character_name do
      # Don't show message to attacker themselves
      nil
    else
      message =
        if monster_alive do
          "#{attacker_name} attacks the #{monster_name} for #{damage} damage! The #{monster_name} has #{remaining_hp} health remaining."
        else
          "#{attacker_name} attacks the #{monster_name} for #{damage} damage! The #{monster_name} is defeated!"
        end

      terminal_state = add_message_to_output(socket.assigns.terminal_state, message)
      socket = assign(socket, terminal_state: terminal_state)
      {:noreply, socket, terminal_state}
    end
  end

  defp handle_player_attack(_event, _socket), do: nil

  defp handle_monster_attack({:monster_attack, monster_name, target_player_name, damage}, socket) do
    message =
      if target_player_name == socket.assigns.character_name do
        "The #{monster_name} attacks you for #{damage} damage!"
      else
        "The #{monster_name} attacks #{target_player_name} for #{damage} damage!"
      end

    terminal_state = add_message_to_output(socket.assigns.terminal_state, message)
    socket = assign(socket, terminal_state: terminal_state)
    {:noreply, socket, terminal_state}
  end

  defp handle_monster_attack(_event, _socket), do: nil

  defp handle_player_fled({:player_fled, player_name}, socket) do
    if player_name == socket.assigns.character_name do
      # Don't show message to fleeing player themselves
      nil
    else
      terminal_state =
        add_message_to_output(
          socket.assigns.terminal_state,
          "#{player_name} flees from combat!"
        )

      socket = assign(socket, terminal_state: terminal_state)
      {:noreply, socket}
    end
  end

  defp handle_player_fled(_event, _socket), do: nil

  # Helper function to detect if a command might have completed a quest
  defp quest_completion_command?(command) do
    command_lower = String.downcase(command)

    String.contains?(command_lower, "deliver") or
      String.contains?(command_lower, "turn in") or
      String.contains?(command_lower, "complete") or
      String.contains?(command_lower, "give")
  end

  # Helper function to reload character from database
  defp reload_character_from_database(character_id) do
    try do
      case Shard.Repo.get(Shard.Characters.Character, character_id) do
        nil ->
          nil

        character ->
          # Preload associations to ensure we have complete character data
          Shard.Repo.preload(character, [:character_inventories, :hotbar_slots])
      end
    rescue
      _error -> nil
    end
  end

  # Helper function to sync player stats with character data
  defp sync_player_stats_with_character(current_stats, character) do
    if character do
      # Ensure we update all relevant fields from the character
      current_stats
      |> Map.put(:experience, character.experience || 0)
      |> Map.put(:gold, character.gold || 0)
      |> Map.put(:level, character.level || 1)
    else
      current_stats
    end
  end
end
