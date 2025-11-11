defmodule ShardWeb.MarketplaceLive.Index do
  use ShardWeb, :live_view

  # alias Shard.Marketplace
  alias Shard.Items

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns.current_scope
    
    # Get user's active listings
    # TODO: Implement Marketplace.list_user_listings/1
    listings = []
    
    # Get user's inventory items for the dropdown
    inventory_items = Items.get_character_inventory(current_scope.user.id)
    |> Enum.map(&{&1.item.name, &1.id})
    
    {:ok,
     socket
     |> assign(:form, to_form(%{}, as: :listing))
     |> assign(:selected_item, nil)
     |> assign(:inventory_items, inventory_items)
     |> stream(:listings, listings)}
  end

  @impl true
  def handle_event("create_listing", %{"listing" => params}, socket) do
    current_user = socket.assigns.current_scope.user
    
    # TODO: Implement Marketplace.create_listing/2
    # case Marketplace.create_listing(params, current_user) do
    case {:error, :not_implemented} do
      {:ok, listing} ->
        {:noreply, 
         socket
         |> put_flash(:info, "Item listed successfully!")
         |> assign(:form, to_form(%{}, as: :listing)) # Reset form
         |> assign(:selected_item, nil)
         |> stream_insert(:listings, listing)}
      
      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
  
  @impl true
  def handle_event("cancel_listing", %{"id" => id}, socket) do
    current_user = socket.assigns.current_scope.user
    
    # TODO: Implement Marketplace.cancel_listing/2
    # case Marketplace.cancel_listing(id, current_user) do
    case {:error, :not_implemented} do
      {:ok, listing} ->
        {:noreply, 
         socket
         |> put_flash(:info, "Listing cancelled")
         |> stream_delete(:listings, listing)}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Unable to cancel listing")}
    end
  end
  
  @impl true
  def handle_event("update_price", %{"id" => id, "price" => price}, socket) do
    current_user = socket.assigns.current_scope.user
    price = String.to_integer(price)
    
    # TODO: Implement Marketplace.update_listing_price/3
    # case Marketplace.update_listing_price(id, price, current_user) do
    case {:error, :not_implemented} do
      {:ok, listing} ->
        {:noreply, 
         socket
         |> put_flash(:info, "Price updated successfully!")
         |> stream_insert(:listings, listing, at: -1)} # Update the listing in the stream
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Unable to update price")}
    end
  end
  
  @impl true
  def handle_event("preview_item", %{"listing" => %{"item_id" => item_id}}, socket) when item_id != "" do
    item = Items.get_item(item_id)
    {:noreply, assign(socket, :selected_item, item)}
  end
  
  def handle_event("preview_item", _params, socket) do
    {:noreply, assign(socket, :selected_item, nil)}
  end
  
  # Helper function to format time ago
  def time_ago_in_words(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)
    
    cond do
      diff < 60 -> "less than a minute"
      diff < 120 -> "1 minute"
      diff < 3_600 -> "#{div(diff, 60)} minutes"
      diff < 7_200 -> "1 hour"
      diff < 86_400 -> "#{div(diff, 3_600)} hours"
      diff < 172_800 -> "1 day"
      true -> "#{div(diff, 86_400)} days"
    end
  end
end
