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

    # Mock marketplace listings for demonstration
    all_listings = [
      %{
        id: 1,
        item_name: "Iron Sword",
        item_type: "weapon",
        rarity: "common",
        stats: %{damage: 15},
        requirements: %{strength: 8},
        description: "A basic iron sword",
        price: 150,
        seller: "SamplePlayer1",
        seller_level: 12,
        listed_at: ~N[2025-11-16 15:30:00]
      },
      %{
        id: 2,
        item_name: "Steel Dagger",
        item_type: "weapon",
        rarity: "uncommon",
        stats: %{damage: 20},
        requirements: %{dexterity: 10},
        description: "A sharp steel dagger",
        price: 220,
        seller: "SamplePlayer2",
        seller_level: 8,
        listed_at: ~N[2025-11-16 14:45:00]
      },
      %{
        id: 3,
        item_name: "Leather Cap",
        item_type: "head",
        rarity: "common",
        stats: %{defense: 8},
        requirements: %{},
        description: "Basic leather head protection",
        price: 75,
        seller: "SamplePlayer3",
        seller_level: 5,
        listed_at: ~N[2025-11-16 16:20:00]
      },
      %{
        id: 4,
        item_name: "Enchanted Cloak",
        item_type: "body",
        rarity: "rare",
        stats: %{defense: 25, magic_resist: 15},
        requirements: %{intelligence: 12},
        description: "A magically infused cloak that resists spells",
        price: 450,
        seller: "SamplePlayer4",
        seller_level: 18,
        listed_at: ~N[2025-11-16 12:10:00]
      }
    ]

    # Get user's inventory items for the dropdown
    inventory_items =
      Items.get_character_inventory(current_scope.user.id)
      |> Enum.map(&{&1.item.name, &1.id})

    {:ok,
     socket
     |> assign(:form, to_form(%{}, as: :listing))
     |> assign(:selected_item, nil)
     |> assign(:inventory_items, inventory_items)
     |> assign(:all_listings, all_listings)
     |> assign(:filtered_listings, all_listings)
     |> assign(:search_query, "")
     |> assign(:rarity_filter, "all")
     |> assign(:selected_listing, nil)
     |> assign(:active_tab, "browse")
     |> stream(:listings, [])}
  end

  @impl true
  def handle_event("create_listing", %{"listing" => _params}, socket) do
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

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_event("search", %{"search" => search_params}, socket) do
    search_query = Map.get(search_params, "query", "")
    rarity_filter = Map.get(search_params, "rarity", "all")

    filtered_listings = filter_listings(socket.assigns.all_listings, search_query, rarity_filter)

    {:noreply,
     socket
     |> assign(:search_query, search_query)
     |> assign(:rarity_filter, rarity_filter)
     |> assign(:filtered_listings, filtered_listings)}
  end

  @impl true
  def handle_event("view_listing", %{"id" => id}, socket) do
    listing = Enum.find(socket.assigns.all_listings, &(&1.id == String.to_integer(id)))
    {:noreply, assign(socket, :selected_listing, listing)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :selected_listing, nil)}
  end

  @impl true
  def handle_event("purchase_listing", %{"id" => id}, socket) do
    listing = Enum.find(socket.assigns.all_listings, &(&1.id == String.to_integer(id)))

    {:noreply,
     socket
     |> assign(:selected_listing, nil)
     |> put_flash(
       :info,
       "#{listing.item_name} is a sample item. Purchase functionality available once backend implemented."
     )}
  end

  # Helper functions
  defp filter_listings(listings, query, rarity) do
    listings
    |> filter_by_query(query)
    |> filter_by_rarity(rarity)
  end

  defp filter_by_query(listings, query) when query == "" or is_nil(query), do: listings

  defp filter_by_query(listings, query) do
    query_down = String.downcase(query)

    Enum.filter(listings, fn listing ->
      String.contains?(String.downcase(listing.item_name), query_down)
    end)
  end

  defp filter_by_rarity(listings, "all"), do: listings

  defp filter_by_rarity(listings, rarity) do
    Enum.filter(listings, &(&1.rarity == rarity))
  end

  # Helper function to get rarity color class
  def rarity_color_class(rarity) do
    case rarity do
      "common" -> "text-slate-600"
      "uncommon" -> "text-green-600"
      "rare" -> "text-blue-600"
      "epic" -> "text-purple-600"
      "legendary" -> "text-yellow-600"
      _ -> "text-slate-600"
    end
  end

  # Helper function to format time ago
  def time_ago_in_words(datetime) do
    now = DateTime.utc_now()

    # Convert NaiveDateTime to DateTime if needed
    datetime_time =
      case datetime do
        %NaiveDateTime{} -> DateTime.from_naive!(datetime, "Etc/UTC")
        %DateTime{} -> datetime
      end

    diff = DateTime.diff(now, datetime_time, :second)

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
