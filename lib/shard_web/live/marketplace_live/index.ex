defmodule ShardWeb.MarketplaceLive.Index do
  use ShardWeb, :live_view

  import Ecto.Query

  alias Shard.Marketplace
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

    # Get all active marketplace listings
    all_listings = Marketplace.list_active_listings() |> format_listings_for_display()

    # Get user's characters
    characters = Shard.Characters.get_characters_by_user(current_scope.user.id)

    # Get the first character's inventory items for the dropdown (if any characters exist)
    inventory_items =
      case characters do
        [first_character | _] ->
          Items.get_character_inventory(first_character.id)
          |> Enum.map(&{&1.item.name, &1.id})

        [] ->
          []
      end

    {:ok,
     socket
     |> assign(:form, to_form(%{}, as: :listing))
     |> assign(:selected_item, nil)
     |> assign(:characters, characters)
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
  def handle_event("create_listing", %{"listing" => params}, socket) do
    current_user = socket.assigns.current_scope.user

    case Marketplace.create_listing(params, current_user) do
      {:ok, _listing} ->
        all_listings = Marketplace.list_active_listings() |> format_listings_for_display()

        {:noreply,
         socket
         |> assign(:all_listings, all_listings)
         |> assign(:filtered_listings, all_listings)
         |> put_flash(:info, "Item listed successfully!")}

      {:error, :no_item_selected} ->
        {:noreply, put_flash(socket, :error, "Please select an item to list")}

      {:error, :inventory_not_found} ->
        {:noreply, put_flash(socket, :error, "Item not found in your inventory")}

      {:error, :item_is_equipped} ->
        {:noreply, put_flash(socket, :error, "Cannot list equipped items")}

      {:error, :item_not_sellable} ->
        {:noreply, put_flash(socket, :error, "This item cannot be sold")}

      {:error, :item_already_listed} ->
        {:noreply, put_flash(socket, :error, "This item is already listed")}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, put_flash(socket, :error, "Please check your listing details")}
    end
  end

  @impl true
  def handle_event("cancel_listing", %{"id" => id}, socket) do
    current_user = socket.assigns.current_scope.user

    case Marketplace.cancel_listing(id, current_user) do
      {:ok, _listing} ->
        all_listings = Marketplace.list_active_listings() |> format_listings_for_display()

        {:noreply,
         socket
         |> assign(:all_listings, all_listings)
         |> assign(:filtered_listings, all_listings)
         |> put_flash(:info, "Listing cancelled successfully")}

      {:error, :listing_not_found} ->
        {:noreply, put_flash(socket, :error, "Listing not found")}

      {:error, :not_seller} ->
        {:noreply, put_flash(socket, :error, "You can only cancel your own listings")}

      {:error, :listing_not_active} ->
        {:noreply, put_flash(socket, :error, "This listing is no longer active")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to cancel listing")}
    end
  end

  @impl true
  def handle_event("update_price", %{"id" => id, "price" => price}, socket) do
    current_user = socket.assigns.current_scope.user

    case Integer.parse(price) do
      {price_int, _} when price_int > 0 ->
        case Marketplace.update_listing_price(id, price_int, current_user) do
          {:ok, _listing} ->
            all_listings = Marketplace.list_active_listings() |> format_listings_for_display()

            {:noreply,
             socket
             |> assign(:all_listings, all_listings)
             |> assign(:filtered_listings, all_listings)
             |> put_flash(:info, "Price updated successfully")}

          {:error, :listing_not_found} ->
            {:noreply, put_flash(socket, :error, "Listing not found")}

          {:error, :not_seller} ->
            {:noreply, put_flash(socket, :error, "You can only update your own listings")}

          {:error, :listing_not_active} ->
            {:noreply, put_flash(socket, :error, "This listing is no longer active")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to update price")}
        end

      _ ->
        {:noreply, put_flash(socket, :error, "Please enter a valid price")}
    end
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
    current_user = socket.assigns.current_scope.user

    case Marketplace.purchase_listing(id, current_user) do
      {:ok, _listing} ->
        all_listings = Marketplace.list_active_listings() |> format_listings_for_display()

        {:noreply,
         socket
         |> assign(:all_listings, all_listings)
         |> assign(:filtered_listings, all_listings)
         |> assign(:selected_listing, nil)
         |> put_flash(:info, "Purchase successful!")}

      {:error, :listing_not_found} ->
        {:noreply,
         socket
         |> assign(:selected_listing, nil)
         |> put_flash(:error, "Listing not found")}

      {:error, :cannot_buy_own_listing} ->
        {:noreply,
         socket
         |> assign(:selected_listing, nil)
         |> put_flash(:error, "You cannot buy your own listing")}

      {:error, :listing_not_active} ->
        {:noreply,
         socket
         |> assign(:selected_listing, nil)
         |> put_flash(:error, "This listing is no longer active")}

      {:error, :insufficient_gold} ->
        {:noreply,
         socket
         |> assign(:selected_listing, nil)
         |> put_flash(:error, "You don't have enough gold")}

      {:error, :buyer_has_no_character} ->
        {:noreply,
         socket
         |> assign(:selected_listing, nil)
         |> put_flash(:error, "You need to create a character first")}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:selected_listing, nil)
         |> put_flash(:error, "Purchase failed. Please try again.")}
    end
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
    datetime_time = normalize_datetime(datetime)
    diff = DateTime.diff(now, datetime_time, :second)

    format_time_difference(diff)
  end

  defp normalize_datetime(%NaiveDateTime{} = datetime) do
    DateTime.from_naive!(datetime, "Etc/UTC")
  end

  defp normalize_datetime(%DateTime{} = datetime), do: datetime

  defp format_time_difference(diff) when diff < 60, do: "less than a minute"
  defp format_time_difference(diff) when diff < 120, do: "1 minute"
  defp format_time_difference(diff) when diff < 3_600, do: "#{div(diff, 60)} minutes"
  defp format_time_difference(diff) when diff < 7_200, do: "1 hour"
  defp format_time_difference(diff) when diff < 86_400, do: "#{div(diff, 3_600)} hours"
  defp format_time_difference(diff) when diff < 172_800, do: "1 day"
  defp format_time_difference(diff), do: "#{div(diff, 86_400)} days"

  # Helper function to format listings for display in the UI
  defp format_listings_for_display(listings) when listings == [], do: []

  defp format_listings_for_display(listings) do
    # Get all seller user IDs
    seller_ids = Enum.map(listings, & &1.seller_id) |> Enum.uniq()

    # Fetch all characters for these sellers
    seller_characters =
      from(c in Shard.Characters.Character,
        where: c.user_id in ^seller_ids,
        select: {c.user_id, c}
      )
      |> Shard.Repo.all()
      |> Enum.into(%{})

    Enum.map(listings, fn listing ->
      item = listing.character_inventory.item
      seller = listing.seller
      seller_character = Map.get(seller_characters, seller.id)

      %{
        id: listing.id,
        item_name: item.name,
        item_type: item.item_type,
        rarity: item.rarity,
        stats: item.stats || %{},
        requirements: item.requirements || %{},
        description: item.description,
        price: listing.price,
        seller: seller.email,
        seller_level: if(seller_character, do: seller_character.level, else: 1),
        listed_at: listing.inserted_at
      }
    end)
  end
end
