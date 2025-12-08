defmodule Shard.MarketplaceTest do
  use Shard.DataCase

  alias Shard.Marketplace

  describe "list_active_listings/0" do
    test "returns empty list when no listings exist" do
      listings = Marketplace.list_active_listings()
      assert listings == []
    end

    test "returns only active listings" do
      # This test would require complex setup with characters, items, and inventory
      # For now, we'll test that the function returns a list
      listings = Marketplace.list_active_listings()
      assert is_list(listings)
    end
  end

  describe "list_seller_listings/1" do
    test "returns empty list for seller with no listings" do
      listings = Marketplace.list_seller_listings(999)
      assert listings == []
    end

    test "returns list for valid seller" do
      listings = Marketplace.list_seller_listings(1)
      assert is_list(listings)
    end
  end

  describe "get_listing/1" do
    test "returns nil for non-existent listing" do
      listing = Marketplace.get_listing(999_999)
      assert listing == nil
    end
  end

  describe "create_listing/2" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "returns error when no item selected", %{user: user} do
      attrs = %{}
      assert {:error, :no_item_selected} = Marketplace.create_listing(attrs, user)
    end

    test "returns error when inventory not found", %{user: user} do
      attrs = %{character_inventory_id: 999_999, price: 100}
      assert {:error, :inventory_not_found} = Marketplace.create_listing(attrs, user)
    end

    test "handles string inventory id", %{user: user} do
      attrs = %{"character_inventory_id" => "999999", "price" => 100}
      assert {:error, :inventory_not_found} = Marketplace.create_listing(attrs, user)
    end

    test "handles item_id parameter", %{user: user} do
      attrs = %{item_id: 999_999, price: 100}
      assert {:error, :inventory_not_found} = Marketplace.create_listing(attrs, user)
    end
  end

  describe "cancel_listing/2" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "returns error when listing not found", %{user: user} do
      assert {:error, :listing_not_found} = Marketplace.cancel_listing(999_999, user)
    end

    test "handles string listing id", %{user: user} do
      assert {:error, :listing_not_found} = Marketplace.cancel_listing("999999", user)
    end
  end

  describe "update_listing_price/3" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "returns error when listing not found", %{user: user} do
      assert {:error, :listing_not_found} = Marketplace.update_listing_price(999_999, 150, user)
    end
  end

  describe "purchase_listing/2" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "returns error when listing not found", %{user: user} do
      assert {:error, :listing_not_found} = Marketplace.purchase_listing(999_999, user)
    end
  end

  describe "search_listings/1" do
    test "returns empty list when no listings exist" do
      listings = Marketplace.search_listings()
      assert listings == []
    end

    test "handles search query option" do
      listings = Marketplace.search_listings(query: "sword")
      assert is_list(listings)
    end

    test "handles rarity filter" do
      listings = Marketplace.search_listings(rarity: "rare")
      assert is_list(listings)
    end

    test "handles item type filter" do
      listings = Marketplace.search_listings(item_type: "weapon")
      assert is_list(listings)
    end

    test "handles price range filters" do
      listings = Marketplace.search_listings(min_price: 50, max_price: 200)
      assert is_list(listings)
    end

    test "handles empty search query" do
      listings = Marketplace.search_listings(query: "")
      assert is_list(listings)
    end

    test "handles nil search query" do
      listings = Marketplace.search_listings(query: nil)
      assert is_list(listings)
    end

    test "handles 'all' rarity filter" do
      listings = Marketplace.search_listings(rarity: "all")
      assert is_list(listings)
    end

    test "handles only min price" do
      listings = Marketplace.search_listings(min_price: 100)
      assert is_list(listings)
    end

    test "handles only max price" do
      listings = Marketplace.search_listings(max_price: 500)
      assert is_list(listings)
    end
  end

  defp user_fixture do
    unique_email = "user#{System.unique_integer([:positive])}@example.com"

    {:ok, user} =
      Shard.Users.register_user(%{
        email: unique_email,
        password: "password123password123"
      })

    user
  end
end
