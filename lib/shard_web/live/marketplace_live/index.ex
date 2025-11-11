defmodule ShardWeb.MarketplaceLive.Index do
  use ShardWeb, :live_view

  alias Shard.Marketplace
  alias Shard.Items

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns.current_scope
    
    # Get user's active listings
    listings = Marketplace.list_user_listings(current_scope.user)
    
    # Get user's inventory items for the dropdown
    inventory_items = Items.get_character_inventory(current_scope.user.id)
    |> Enum.map(&{&1.item.name, &1.id})
    
    {:ok,
     socket
     |> assign(:listings, listings)
     |> assign(:form, to_form(%{}, as: :listing))
     |> assign(:selected_item, nil)
     |> assign(:inventory_items, inventory_items)}
  end

  @impl true
  def handle_event("create_listing", %{"listing" => params}, socket) do
    current_user = socket.assigns.current_scope.user
    
    case Marketplace.create_listing(params, current_user) do
      {:ok, listing} ->
        {:noreply, 
         socket
         |> put_flash(:info, "Item listed successfully!")
         |> assign(:form, to_form(%{}, as: :listing)) # Reset form
         |> assign(:selected_item, nil)}
      
      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
  
  @impl true
  def handle_event("cancel_listing", %{"id" => id}, socket) do
    current_user = socket.assigns.current_scope.user
    
    case Marketplace.cancel_listing(id, current_user) do
      {:ok, _} ->
        {:noreply, 
         socket
         |> put_flash(:info, "Listing cancelled")}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Unable to cancel listing")}
    end
  end
  
  @impl true
  def handle_event("update_price", %{"id" => id, "price" => price}, socket) do
    current_user = socket.assigns.current_scope.user
    price = String.to_integer(price)
    
    case Marketplace.update_listing_price(id, price, current_user) do
      {:ok, _} ->
        {:noreply, 
         socket
         |> put_flash(:info, "Price updated successfully!")}
      
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
end
