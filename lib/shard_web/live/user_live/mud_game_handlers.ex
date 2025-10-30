defmodule ShardWeb.UserLive.MudGameHandlers do
  @moduledoc """
  Event handlers and helper functions for MudGameLive
  """
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
        movement_result = execute_movement(socket.assigns.game_state, arrow_key)

        {response, updated_game_state, popup_result} =
          case movement_result do
            {resp, state, popup} -> {resp, state, popup}
            {resp, state} -> {resp, state, :no_popup}
          end

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

        {:noreply, socket, updated_game_state, terminal_state, modal_state,
         updated_game_state.player_position}

      _ ->
        # Non-movement key, do nothing
        {:noreply, socket}
    end
  end

  def handle_submit_command(%{"command" => %{"text" => command_text}}, socket) do
    trimmed_command = String.trim(command_text)

    if trimmed_command != "" do
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

      {:noreply, socket, updated_game_state, terminal_state}
    else
      {:noreply, socket}
    end
  end

  def handle_update_command(%{"command" => %{"text" => command_text}}, socket) do
    terminal_state = Map.put(socket.assigns.terminal_state, :current_command, command_text)
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

        {:noreply, socket, socket.assigns.game_state, terminal_state}

      item ->
        {response, updated_game_state} = use_item(socket.assigns.game_state, item)

        # Add response to terminal
        new_output = socket.assigns.terminal_state.output ++ response ++ [""]
        terminal_state = Map.put(socket.assigns.terminal_state, :output, new_output)

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

        {:noreply, socket, socket.assigns.game_state, terminal_state}

      item ->
        {response, updated_game_state} = equip_item(socket.assigns.game_state, item)

        # Add response to terminal
        new_output = socket.assigns.terminal_state.output ++ response ++ [""]
        terminal_state = Map.put(socket.assigns.terminal_state, :output, new_output)

        {:noreply, socket, updated_game_state, terminal_state}
    end
  end

  def handle_click_exit(%{"dir" => dir}, socket) do
    key = dir_to_key(dir)
    player_position = socket.assigns.game_state.player_position
    map_data = socket.assigns.game_state.map_data

    new_position =
      case key do
        nil -> player_position
        _ -> calc_position(player_position, key, map_data)
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

    {:noreply, socket, game_state, terminal_state, game_state.player_position}
  end

  def add_message_to_output(terminal_state, message) do
    new_output = terminal_state.output ++ [message] ++ [""]
    Map.put(terminal_state, :output, new_output)
  end

  def handle_noise_info({:noise, text}, socket) do
    terminal_state = add_message_to_output(socket.assigns.terminal_state, text)
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

      {:noreply, socket, updated_game_state, terminal_state}
    else
      {:noreply, socket, terminal_state}
    end
  end

  def handle_update_game_state_info({:update_game_state, new_game_state}, socket) do
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

          {:noreply, socket, updated_game_state, terminal_state}
        else
          terminal_state =
            add_message_to_output(
              socket.assigns.terminal_state,
              "Another player takes bleed damage!"
            )

          {:noreply, socket, terminal_state}
        end

      %{type: :victory} ->
        terminal_state =
          add_message_to_output(
            socket.assigns.terminal_state,
            "Victory! All monsters have been defeated!"
          )

        updated_game_state = %{socket.assigns.game_state | combat: false}
        {:noreply, socket, updated_game_state, terminal_state}

      %{type: :defeat} ->
        terminal_state =
          add_message_to_output(socket.assigns.terminal_state, "Defeat! All players have fallen!")

        updated_game_state = %{socket.assigns.game_state | combat: false}
        {:noreply, socket, updated_game_state, terminal_state}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_player_joined_combat_info({:player_joined_combat, player_name}, socket) do
    terminal_state =
      add_message_to_output(socket.assigns.terminal_state, "#{player_name} joins the battle!")

    {:noreply, socket, terminal_state}
  end

  def handle_player_left_combat_info({:player_left_combat, player_name}, socket) do
    terminal_state =
      add_message_to_output(socket.assigns.terminal_state, "#{player_name} leaves the battle!")

    {:noreply, socket, terminal_state}
  end

  def handle_combat_action_info({:combat_action, event}, socket) do
    case event do
      {:player_attack, attacker_name, monster_name, damage, monster_alive} ->
        # Don't show the message to the attacker themselves
        if attacker_name != socket.assigns.character_name do
          message =
            if monster_alive do
              "#{attacker_name} attacks the #{monster_name} for #{damage} damage!"
            else
              "#{attacker_name} attacks the #{monster_name} for #{damage} damage! The #{monster_name} is defeated!"
            end

          terminal_state = add_message_to_output(socket.assigns.terminal_state, message)
          {:noreply, socket, terminal_state}
        else
          {:noreply, socket}
        end

      {:player_fled, player_name} ->
        # Don't show the message to the fleeing player themselves
        if player_name != socket.assigns.character_name do
          terminal_state =
            add_message_to_output(
              socket.assigns.terminal_state,
              "#{player_name} flees from combat!"
            )

          {:noreply, socket, terminal_state}
        else
          {:noreply, socket}
        end

      _other ->
        {:noreply, socket}
    end
  end
end
