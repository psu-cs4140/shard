defmodule ShardWeb.InventoryLive.Index do
  use ShardWeb, :live_view

  alias Shard.Items
  alias Shard.Characters

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user
    characters = Characters.get_characters_by_user(current_user.id)

    socket =
      socket
      |> assign(:characters, characters)
      |> assign(:selected_character, List.first(characters))
      |> assign(:inventory, [])
      |> assign(:hotbar, [])
      |> assign(:room_items, [])
      |> load_character_data()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Inventory")
  end

  @impl true
  def handle_event("select_character", %{"character_id" => character_id}, socket) do
    character = Enum.find(socket.assigns.characters, &(&1.id == String.to_integer(character_id)))

    socket =
      socket
      |> assign(:selected_character, character)
      |> load_character_data()

    {:noreply, socket}
  end

  def handle_event("pick_up_item", %{"room_item_id" => room_item_id}, socket) do
    character = socket.assigns.selected_character

    case Items.pick_up_item(character.id, String.to_integer(room_item_id)) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "Item picked up successfully")
          |> load_character_data()

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to pick up item: #{reason}")}
    end
  end

  def handle_event("drop_item", %{"inventory_id" => inventory_id}, socket) do
    character = socket.assigns.selected_character

    case Items.drop_item_in_room(
           character.id,
           String.to_integer(inventory_id),
           character.location
         ) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "Item dropped successfully")
          |> load_character_data()

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to drop item: #{reason}")}
    end
  end

  def handle_event("equip_item", %{"inventory_id" => inventory_id}, socket) do
    case Items.equip_item(String.to_integer(inventory_id)) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "Item equipped successfully")
          |> load_character_data()

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to equip item: #{reason}")}
    end
  end

  def handle_event("unequip_item", %{"inventory_id" => inventory_id}, socket) do
    case Items.unequip_item(String.to_integer(inventory_id)) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "Item unequipped successfully")
          |> load_character_data()

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to unequip item: #{reason}")}
    end
  end

  def handle_event("set_hotbar", %{"inventory_id" => inventory_id, "slot" => slot}, socket) do
    character = socket.assigns.selected_character

    case Items.set_hotbar_slot(
           character.id,
           String.to_integer(slot),
           String.to_integer(inventory_id)
         ) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "Hotbar slot set successfully")
          |> load_character_data()

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to set hotbar slot: #{reason}")}
    end
  end

  def handle_event("clear_hotbar", %{"slot" => slot}, socket) do
    character = socket.assigns.selected_character

    case Items.clear_hotbar_slot(character.id, String.to_integer(slot)) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "Hotbar slot cleared")
          |> load_character_data()

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to clear hotbar slot: #{reason}")}
    end
  end

  defp load_character_data(socket) do
    case socket.assigns.selected_character do
      nil ->
        socket

      character ->
        inventory = Items.get_character_inventory(character.id)
        hotbar = Items.get_character_hotbar(character.id)
        room_items = Items.get_room_items(character.location)

        socket
        |> assign(:inventory, inventory)
        |> assign(:hotbar, hotbar)
        |> assign(:room_items, room_items)
    end
  end

  defp rarity_class("common"), do: "text-base-content"
  defp rarity_class("uncommon"), do: "text-success"
  defp rarity_class("rare"), do: "text-info"
  defp rarity_class("epic"), do: "text-secondary"
  defp rarity_class("legendary"), do: "text-warning"
  defp rarity_class(_), do: "text-base-content"

  # Get equipment slots from Item schema
  defp equipment_slots, do: Shard.Items.Item.equipment_slots()

  # Group equipped items by slot
  defp group_equipped_items(inventory) do
    equipped_items = Enum.filter(inventory, & &1.equipped)
    
    Enum.reduce(equipped_items, %{}, fn item, acc ->
      slot = item.equipment_slot || "unknown"
      Map.put(acc, slot, item)
    end)
  end

  # Get available equipment slots that are not currently equipped
  defp available_equipment_slots(inventory) do
    equipped_slots = 
      inventory
      |> Enum.filter(& &1.equipped)
      |> Enum.map(& &1.equipment_slot)
      |> Enum.reject(&is_nil/1)
      |> MapSet.new()

    equipment_slots()
    |> Enum.reject(&MapSet.member?(equipped_slots, &1))
  end
end
