defmodule Shard.Marketplace do
  @moduledoc """
  The Marketplace context - handles player-to-player equipment trading.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo

  alias Shard.Marketplace.Listing
  alias Shard.Items
  alias Shard.Items.CharacterInventory
  alias Shard.Characters

  @doc """
  Lists all active marketplace listings with preloaded associations.
  """
  def list_active_listings do
    from(l in Listing,
      where: l.status == "active",
      join: ci in CharacterInventory,
      on: l.character_inventory_id == ci.id,
      join: i in assoc(ci, :item),
      join: s in assoc(l, :seller),
      preload: [
        character_inventory: {ci, item: i},
        seller: s
      ],
      order_by: [desc: l.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Lists active marketplace listings for a specific seller.
  """
  def list_seller_listings(seller_id) do
    from(l in Listing,
      where: l.seller_id == ^seller_id and l.status == "active",
      join: ci in assoc(l, :character_inventory),
      join: i in assoc(ci, :item),
      preload: [character_inventory: {ci, item: i}],
      order_by: [desc: l.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single listing with preloaded associations.
  """
  def get_listing(id) do
    from(l in Listing,
      where: l.id == ^id,
      join: ci in assoc(l, :character_inventory),
      join: i in assoc(ci, :item),
      join: s in assoc(l, :seller),
      preload: [
        character_inventory: {ci, item: i},
        seller: s
      ]
    )
    |> Repo.one()
  end

  @doc """
  Creates a marketplace listing for an inventory item.

  The inventory item must:
  - Belong to the seller's character
  - Not be currently equipped
  - Be a sellable item

  ## Examples

      iex> create_listing(%{price: 100, character_inventory_id: 1}, user)
      {:ok, %Listing{}}

      iex> create_listing(%{price: -10}, user)
      {:error, %Ecto.Changeset{}}
  """
  def create_listing(attrs, seller) do
    inventory_id =
      Map.get(attrs, "character_inventory_id") || Map.get(attrs, :character_inventory_id) ||
        Map.get(attrs, "item_id") || Map.get(attrs, :item_id)

    with {:ok, inventory} <- validate_inventory_for_listing(inventory_id, seller),
         attrs <-
           Map.merge(attrs, %{"seller_id" => seller.id, "character_inventory_id" => inventory.id}),
         changeset <- Listing.changeset(%Listing{}, attrs),
         {:ok, listing} <- Repo.insert(changeset) do
      {:ok, get_listing(listing.id)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Cancels a marketplace listing.
  Only the seller can cancel their own listing.
  """
  def cancel_listing(listing_id, user) do
    with {:ok, listing} <- get_listing_if_exists(listing_id),
         :ok <- verify_seller(listing, user),
         :ok <- verify_active(listing) do
      listing
      |> Listing.changeset(%{
        status: "cancelled",
        cancelled_at: DateTime.utc_now()
      })
      |> Repo.update()
    else
      error -> error
    end
  end

  @doc """
  Updates the price of a marketplace listing.
  Only the seller can update their own listing price.
  """
  def update_listing_price(listing_id, new_price, user) do
    with {:ok, listing} <- get_listing_if_exists(listing_id),
         :ok <- verify_seller(listing, user),
         :ok <- verify_active(listing) do
      listing
      |> Listing.changeset(%{price: new_price})
      |> Repo.update()
    else
      error -> error
    end
  end

  @doc """
  Purchases a marketplace listing.

  This function:
  1. Verifies the listing is active
  2. Verifies the buyer has enough gold
  3. Verifies the buyer is not the seller
  4. Transfers the item to the buyer's inventory
  5. Transfers gold from buyer to seller
  6. Marks the listing as sold
  7. Broadcasts a notification to the seller
  """
  def purchase_listing(listing_id, buyer) do
    result =
      Repo.transaction(fn ->
        with {:ok, listing} <- get_listing_if_exists(listing_id),
             :ok <- verify_active(listing),
             :ok <- verify_not_seller(listing, buyer),
             {:ok, buyer_character} <- get_buyer_character(buyer),
             {:ok, seller_character} <- get_seller_character(listing),
             :ok <- verify_buyer_has_gold(buyer_character, listing.price),
             {:ok, updated_listing} <- mark_as_sold(listing, buyer),
             {:ok, _} <- transfer_item(listing, buyer_character),
             {:ok, _} <- transfer_gold(buyer_character, seller_character, listing.price) do
          updated_listing
        else
          {:error, reason} -> Repo.rollback(reason)
        end
      end)

    # Broadcast sale notification to the seller after successful transaction
    case result do
      {:ok, listing} ->
        broadcast_sale_notification(listing)
        {:ok, listing}

      error ->
        error
    end
  end

  # Private helper functions

  defp validate_inventory_for_listing(nil, _seller) do
    {:error, :no_item_selected}
  end

  defp validate_inventory_for_listing(inventory_id, seller) when is_binary(inventory_id) do
    validate_inventory_for_listing(String.to_integer(inventory_id), seller)
  end

  defp validate_inventory_for_listing(inventory_id, seller) do
    inventory =
      from(ci in CharacterInventory,
        join: c in assoc(ci, :character),
        join: i in assoc(ci, :item),
        where: ci.id == ^inventory_id and c.user_id == ^seller.id,
        preload: [item: i, character: c]
      )
      |> Repo.one()

    cond do
      is_nil(inventory) ->
        {:error, :inventory_not_found}

      inventory.equipped ->
        {:error, :item_is_equipped}

      not inventory.item.sellable ->
        {:error, :item_not_sellable}

      listing_exists_for_inventory?(inventory_id) ->
        {:error, :item_already_listed}

      true ->
        {:ok, inventory}
    end
  end

  defp listing_exists_for_inventory?(inventory_id) do
    from(l in Listing,
      where: l.character_inventory_id == ^inventory_id and l.status == "active"
    )
    |> Repo.exists?()
  end

  defp get_listing_if_exists(listing_id) when is_binary(listing_id) do
    get_listing_if_exists(String.to_integer(listing_id))
  end

  defp get_listing_if_exists(listing_id) do
    case get_listing(listing_id) do
      nil -> {:error, :listing_not_found}
      listing -> {:ok, listing}
    end
  end

  defp verify_seller(listing, user) do
    if listing.seller_id == user.id do
      :ok
    else
      {:error, :not_seller}
    end
  end

  defp verify_not_seller(listing, user) do
    if listing.seller_id != user.id do
      :ok
    else
      {:error, :cannot_buy_own_listing}
    end
  end

  defp verify_active(listing) do
    if listing.status == "active" do
      :ok
    else
      {:error, :listing_not_active}
    end
  end

  defp get_buyer_character(buyer) do
    case Characters.get_characters_by_user(buyer.id) do
      [] -> {:error, :buyer_has_no_character}
      [character | _] -> {:ok, character}
    end
  end

  defp get_seller_character(listing) do
    case Characters.get_characters_by_user(listing.seller_id) do
      [] -> {:error, :seller_has_no_character}
      [character | _] -> {:ok, character}
    end
  end

  defp verify_buyer_has_gold(character, price) do
    if character.gold >= price do
      :ok
    else
      {:error, :insufficient_gold}
    end
  end

  defp transfer_item(listing, buyer_character) do
    inventory = listing.character_inventory

    # Remove item from seller's inventory
    with {:ok, _} <- Items.remove_item_from_inventory(inventory.id, inventory.quantity),
         {:ok, _} <-
           Items.add_item_to_inventory(buyer_character.id, inventory.item_id, inventory.quantity) do
      {:ok, :transferred}
    else
      error -> error
    end
  end

  defp transfer_gold(buyer_character, seller_character, price) do
    with {:ok, _} <-
           Characters.update_character(buyer_character, %{gold: buyer_character.gold - price}),
         {:ok, _} <-
           Characters.update_character(seller_character, %{gold: seller_character.gold + price}) do
      {:ok, :transferred}
    else
      error -> error
    end
  end

  defp mark_as_sold(listing, buyer) do
    listing
    |> Listing.changeset(%{
      status: "sold",
      sold_at: DateTime.utc_now(),
      buyer_id: buyer.id
    })
    |> Repo.update()
  end

  defp broadcast_sale_notification(listing) do
    item_name = listing.character_inventory.item.name
    price = listing.price

    Phoenix.PubSub.broadcast(
      Shard.PubSub,
      "user:#{listing.seller_id}",
      {:item_sold, %{item_name: item_name, price: price}}
    )
  end

  @doc """
  Searches and filters marketplace listings.

  ## Options
    - `:query` - Text search on item name
    - `:rarity` - Filter by item rarity
    - `:item_type` - Filter by item type
    - `:min_price` - Minimum price filter
    - `:max_price` - Maximum price filter
  """
  def search_listings(opts \\ []) do
    base_query =
      from(l in Listing,
        where: l.status == "active",
        join: ci in assoc(l, :character_inventory),
        join: i in assoc(ci, :item),
        join: s in assoc(l, :seller),
        preload: [character_inventory: {ci, item: i}, seller: s],
        order_by: [desc: l.inserted_at]
      )

    base_query
    |> apply_search_query(Keyword.get(opts, :query))
    |> apply_rarity_filter(Keyword.get(opts, :rarity))
    |> apply_item_type_filter(Keyword.get(opts, :item_type))
    |> apply_price_range(Keyword.get(opts, :min_price), Keyword.get(opts, :max_price))
    |> Repo.all()
  end

  defp apply_search_query(query, nil), do: query
  defp apply_search_query(query, ""), do: query

  defp apply_search_query(query, search_text) do
    search_pattern = "%#{search_text}%"

    from([l, ci, i, s] in query,
      where: ilike(i.name, ^search_pattern)
    )
  end

  defp apply_rarity_filter(query, nil), do: query
  defp apply_rarity_filter(query, "all"), do: query

  defp apply_rarity_filter(query, rarity) do
    from([l, ci, i, s] in query,
      where: i.rarity == ^rarity
    )
  end

  defp apply_item_type_filter(query, nil), do: query

  defp apply_item_type_filter(query, item_type) do
    from([l, ci, i, s] in query,
      where: i.item_type == ^item_type
    )
  end

  defp apply_price_range(query, nil, nil), do: query

  defp apply_price_range(query, min_price, nil) do
    from([l, ci, i, s] in query,
      where: l.price >= ^min_price
    )
  end

  defp apply_price_range(query, nil, max_price) do
    from([l, ci, i, s] in query,
      where: l.price <= ^max_price
    )
  end

  defp apply_price_range(query, min_price, max_price) do
    from([l, ci, i, s] in query,
      where: l.price >= ^min_price and l.price <= ^max_price
    )
  end
end
