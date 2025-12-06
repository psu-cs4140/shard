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
      |> assign(:show_hotbar_modal, false)
       |> assign(:show_sell_modal, false)
       |> assign(:sell_inventory_id, nil)
       |> assign(:sell_quantity, 1)
       |> assign(:sell_error, nil)
      |> assign(:selected_inventory_id, nil)
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
          |> put_flash(:info, "Item added to hotbar slot #{slot}")
          |> assign(:show_hotbar_modal, false)
          |> assign(:selected_inventory_id, nil)
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

  def handle_event("show_hotbar_modal", %{"inventory_id" => inventory_id}, socket) do
    socket =
      socket
      |> assign(:show_hotbar_modal, true)
      |> assign(:selected_inventory_id, inventory_id)

    {:noreply, socket}
  end

  def handle_event("hide_hotbar_modal", _params, socket) do
    socket =
      socket
      |> assign(:show_hotbar_modal, false)
      |> assign(:selected_inventory_id, nil)

    {:noreply, socket}
  end

  def handle_event("sell_item", %{"inventory_id" => inventory_id}, socket) do
    socket =
      socket
      |> assign(:show_sell_modal, true)
      |> assign(:sell_inventory_id, String.to_integer(inventory_id))
      |> assign(:sell_quantity, 1)
      |> assign(:sell_error, nil)

    {:noreply, socket}
  end

  def handle_event("hide_sell_modal", _params, socket) do
    socket =
      socket
      |> assign(:show_sell_modal, false)
      |> assign(:sell_inventory_id, nil)
      |> assign(:sell_error, nil)

    {:noreply, socket}
  end

  def handle_event("change_sell_quantity", %{"sell" => %{"quantity" => qty}}, socket) do
    {qty_int, error} =
      case Integer.parse(qty) do
        {val, ""} when val >= 1 ->
          max_qty = current_sell_max(socket)
          if val <= max_qty, do: {val, nil}, else: {val, "Enter a number between 1 and #{max_qty}"}

        _ ->
          {socket.assigns.sell_quantity, "Enter a number between 1 and #{current_sell_max(socket)}"}
      end

    {:noreply, assign(socket, sell_quantity: qty_int, sell_error: error)}
  end

  def handle_event("confirm_sell", _params, socket) do
    character = socket.assigns.selected_character
    qty = socket.assigns.sell_quantity
    inventory_id = socket.assigns.sell_inventory_id

    case Items.sell_item(character, inventory_id, qty) do
      {:ok, %{gold_earned: gold_earned}} ->
        socket =
          socket
          |> put_flash(:info, "Item sold for #{gold_earned} gold")
          |> assign(:show_sell_modal, false)
          |> assign(:sell_inventory_id, nil)
          |> assign(:sell_error, nil)
          |> load_character_data()

        {:noreply, socket}

      {:error, :item_not_found} ->
        {:noreply, put_flash(socket, :error, "Item not found")}

      {:error, :not_owned_by_character} ->
        {:noreply, put_flash(socket, :error, "You don't own this item")}

      {:error, :cannot_sell_equipped_item} ->
        {:noreply, put_flash(socket, :error, "Cannot sell equipped items. Unequip it first.")}

      {:error, :item_not_sellable} ->
        {:noreply, put_flash(socket, :error, "This item cannot be sold")}

      {:error, :invalid_quantity} ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid quantity")
         |> assign(:sell_error, "Enter a number between 1 and #{current_sell_max(socket)}")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to sell item: #{inspect(reason)}")}
    end
  end

  defp load_character_data(socket) do
    case socket.assigns.selected_character do
      nil ->
        socket

      character ->
        # Reload character to get updated gold and other stats
        character = Characters.get_character!(character.id)
        inventory = Items.get_character_inventory(character.id)
        hotbar = Items.get_character_hotbar(character.id)
        room_items = Items.get_room_items(character.location)

        socket
        |> assign(:selected_character, character)
        |> assign(:inventory, inventory)
        |> assign(:hotbar, hotbar)
        |> assign(:room_items, room_items)
    end
  end

  defp current_sell_max(socket) do
    case Enum.find(socket.assigns.inventory, &(&1.id == socket.assigns.sell_inventory_id)) do
      nil -> 1
      inv -> inv.quantity
    end
  end

  defp rarity_class("common"), do: "text-base-content"
  defp rarity_class("uncommon"), do: "text-success"
  defp rarity_class("rare"), do: "text-info"
  defp rarity_class("epic"), do: "text-secondary"
  defp rarity_class("legendary"), do: "text-warning"
  defp rarity_class(_), do: "text-base-content"
end
