defmodule ShardWeb.MarketplaceLive.Index do
  use ShardWeb, :live_view

  # alias Shard.Marketplace
  alias Shard.Items

  @moduledoc """
  Marketplace LiveView for listing and managing player item listings.

  NOTE: Most event handlers are currently stubbed out because the underlying
  Shard.Marketplace context functions have not been implemented yet. The 
  handlers contain the proper variable assignments and structure that will
  be needed once the database context is implemented.
  """

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns.current_scope

    # Get user's active listings
    # TODO: Implement Marketplace.list_user_listings/1
    listings = []

    # Get user's inventory items for the dropdown
    inventory_items =
      Items.get_character_inventory(current_scope.user.id)
      |> Enum.map(&{&1.item.name, &1.id})

    {:ok,
     socket
     |> assign(:form, to_form(%{}, as: :listing))
     |> assign(:selected_item, nil)
     |> assign(:inventory_items, inventory_items)
     |> stream(:listings, listings)}
  end

  @impl true
  def handle_event("create_listing", %{"listing" => _params}, socket) do
    # TODO: Implement Marketplace.create_listing/2
    # This handler is stubbed until the database context is implemented
    # Variables that will be needed:
    # current_user = socket.assigns.current_scope.user
    # case Marketplace.create_listing(params, current_user) do

    {:noreply,
     socket
     |> put_flash(:info, "Item listing functionality coming soon!")}
  end

  @impl true
  def handle_event("cancel_listing", %{"id" => _id}, socket) do
    # TODO: Implement Marketplace.cancel_listing/2
    # This handler is stubbed until the database context is implemented
    # Variables that will be needed:
    # current_user = socket.assigns.current_scope.user
    # case Marketplace.cancel_listing(id, current_user) do

    {:noreply,
     socket
     |> put_flash(:info, "Listing cancellation functionality coming soon!")}
  end

  @impl true
  def handle_event("update_price", %{"id" => _id, "price" => _price}, socket) do
    # TODO: Implement Marketplace.update_listing_price/3
    # This handler is stubbed until the database context is implemented
    # Variables that will be needed:
    # current_user = socket.assigns.current_scope.user
    # price = String.to_integer(price)
    # case Marketplace.update_listing_price(id, price, current_user) do

    {:noreply,
     socket
     |> put_flash(:info, "Price update functionality coming soon!")}
  end

  @impl true
  def handle_event("preview_item", %{"listing" => %{"item_id" => item_id}}, socket)
      when item_id != "" do
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
