defmodule ShardWeb.UserLive.MudGameEventHandlers do
  @moduledoc """
  Event handlers for the MUD game live view to reduce file complexity.
  """

  alias ShardWeb.UserLive.CharacterHelpers
  alias Phoenix.Component

  def handle_drop_item(%{"item_id" => item_id}, socket) do
    case find_inventory_item(socket.assigns.game_state.inventory_items, item_id) do
      nil -> handle_item_not_found(socket)
      item -> handle_item_drop(socket, item)
    end
  end

  def handle_show_hotbar_modal(%{"item_id" => item_id}, socket) do
    case find_inventory_item(socket.assigns.game_state.inventory_items, item_id) do
      nil -> handle_item_not_found(socket)
      inventory_item -> show_hotbar_selection_modal(socket, inventory_item)
    end
  end

  def handle_set_hotbar_from_modal(%{"item_id" => item_id, "slot" => slot}, socket) do
    case parse_inventory_id(item_id) do
      nil -> handle_invalid_item_id(socket)
      inventory_id -> handle_hotbar_assignment(socket, inventory_id, slot)
    end
  end

  def handle_save_character_stats(_params, socket) do
    case save_character_stats(
           socket.assigns.game_state.character,
           socket.assigns.game_state.player_stats
         ) do
      {:ok, _character} ->
        terminal_state = add_terminal_message(socket.assigns.terminal_state, "Character stats saved successfully.")
        {:noreply, Component.assign(socket, :terminal_state, terminal_state)}

      {:error, _error} ->
        terminal_state = add_terminal_message(socket.assigns.terminal_state, "Failed to save character stats.")
        {:noreply, Component.assign(socket, :terminal_state, terminal_state)}
    end
  end

  def handle_submit_chat(%{"chat" => %{"text" => message_text}}, socket) do
    trimmed_message = String.trim(message_text)

    if trimmed_message != "" do
      timestamp =
        DateTime.utc_now() |> DateTime.to_time() |> Time.to_string() |> String.slice(0, 8)

      message_data = %{
        timestamp: timestamp,
        character_name: socket.assigns.character_name,
        character_id: socket.assigns.game_state.character.id,
        text: trimmed_message
      }

      Phoenix.PubSub.broadcast(Shard.PubSub, "global_chat", {:chat_message, message_data})

      chat_state = Map.put(socket.assigns.chat_state, :current_message, "")
      {:noreply, Component.assign(socket, chat_state: chat_state)}
    else
      {:noreply, socket}
    end
  end

  def handle_update_chat(%{"chat" => %{"text" => message_text}}, socket) do
    chat_state = Map.put(socket.assigns.chat_state, :current_message, message_text)
    {:noreply, Component.assign(socket, chat_state: chat_state)}
  end

  # Private helper functions

  defp find_inventory_item(inventory_items, item_id) do
    Enum.find(inventory_items, fn inv_item ->
      to_string(Map.get(inv_item, :id)) == item_id
    end)
  end

  defp handle_item_not_found(socket) do
    terminal_state = add_terminal_message(socket.assigns.terminal_state, "Item not found in inventory.")
    {:noreply, Component.assign(socket, terminal_state: terminal_state)}
  end

  defp handle_item_drop(socket, item) do
    character = socket.assigns.game_state.character
    location = build_location_string(socket.assigns.game_state.player_position)

    case Shard.Items.drop_item_in_room(character.id, item.id, location, 1) do
      {:ok, _} -> handle_successful_drop(socket, item, character)
      {:error, reason} -> handle_failed_drop(socket, reason)
    end
  end

  defp build_location_string({x, y}), do: "#{x},#{y},0"

  defp handle_successful_drop(socket, item, character) do
    updated_inventory = CharacterHelpers.load_character_inventory(character)
    updated_game_state = %{socket.assigns.game_state | inventory_items: updated_inventory}
    
    message = "You drop #{get_item_name(item)}."
    terminal_state = add_terminal_message(socket.assigns.terminal_state, message)

    socket = Component.assign(socket, game_state: updated_game_state, terminal_state: terminal_state)
    {:noreply, socket}
  end

  defp handle_failed_drop(socket, reason) do
    message = "Failed to drop item: #{reason}"
    terminal_state = add_terminal_message(socket.assigns.terminal_state, message)
    {:noreply, Component.assign(socket, terminal_state: terminal_state)}
  end

  defp show_hotbar_selection_modal(socket, inventory_item) do
    modal_state = %{
      show: true,
      type: "hotbar_selection",
      item_id: to_string(inventory_item.id)
    }

    {:noreply, Component.assign(socket, modal_state: modal_state)}
  end

  defp parse_inventory_id(item_id) do
    case Integer.parse(item_id) do
      {id, ""} -> id
      _ -> nil
    end
  end

  defp handle_invalid_item_id(socket) do
    terminal_state = add_terminal_message(socket.assigns.terminal_state, "Invalid item ID provided")
    modal_state = %{show: false, type: "", item_id: nil}
    {:noreply, Component.assign(socket, terminal_state: terminal_state, modal_state: modal_state)}
  end

  defp handle_hotbar_assignment(socket, inventory_id, slot) do
    character = socket.assigns.game_state.character
    item_name = find_item_name_by_id(socket.assigns.game_state.inventory_items, inventory_id)

    case Shard.Items.set_hotbar_slot(character.id, String.to_integer(slot), inventory_id) do
      {:ok, _} -> handle_successful_hotbar_assignment(socket, character, item_name, slot)
      {:error, reason} -> handle_failed_hotbar_assignment(socket, reason)
    end
  end

  defp find_item_name_by_id(inventory_items, inventory_id) do
    case Enum.find(inventory_items, &(&1.id == inventory_id)) do
      nil -> "Unknown Item"
      inv_item -> get_item_name(inv_item)
    end
  end

  defp handle_successful_hotbar_assignment(socket, character, item_name, slot) do
    updated_hotbar = CharacterHelpers.load_character_hotbar(character)
    updated_inventory = CharacterHelpers.load_character_inventory(character)

    updated_game_state = %{
      socket.assigns.game_state
      | hotbar: updated_hotbar,
        inventory_items: updated_inventory
    }

    message = "#{item_name} added to hotbar slot #{slot}"
    terminal_state = add_terminal_message(socket.assigns.terminal_state, message)
    modal_state = %{show: false, type: "", item_id: nil}

    socket = Component.assign(socket,
      game_state: updated_game_state,
      terminal_state: terminal_state,
      modal_state: modal_state
    )

    {:noreply, socket}
  end

  defp handle_failed_hotbar_assignment(socket, reason) do
    error_message = format_hotbar_error(reason)
    terminal_state = add_terminal_message(socket.assigns.terminal_state, error_message)
    modal_state = %{show: false, type: "", item_id: nil}
    {:noreply, Component.assign(socket, terminal_state: terminal_state, modal_state: modal_state)}
  end

  defp format_hotbar_error(reason) do
    case reason do
      :inventory_not_found -> "Item not found in inventory"
      :item_not_found -> "Item data not found"
      _ -> "Failed to add item to hotbar: #{inspect(reason)}"
    end
  end

  defp add_terminal_message(terminal_state, message) do
    new_output = terminal_state.output ++ [message] ++ [""]
    Map.put(terminal_state, :output, new_output)
  end

  defp get_item_name(item) do
    cond do
      item.item && item.item.name -> item.item.name
      item.name -> item.name
      true -> "Unknown Item"
    end
  end

  defp save_character_stats(character, player_stats) do
    attrs = %{
      level: player_stats.level,
      health: player_stats.health,
      mana: player_stats.mana,
      experience: player_stats.experience,
      gold: player_stats.gold,
      strength: player_stats.strength,
      dexterity: player_stats.dexterity,
      intelligence: player_stats.intelligence,
      constitution: player_stats.constitution
    }

    Shard.Characters.update_character(character, attrs)
  end
end
