defmodule Shard.Marketplace.ListingTest do
  use Shard.DataCase

  alias Shard.Marketplace.Listing

  describe "changeset/2" do
    @valid_attrs %{
      price: 100,
      status: "active",
      seller_id: 1,
      character_inventory_id: 1
    }

    test "changeset with valid attributes" do
      changeset = Listing.changeset(%Listing{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset requires price, seller_id, and character_inventory_id" do
      changeset = Listing.changeset(%Listing{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.price
      assert "can't be blank" in errors.seller_id
      assert "can't be blank" in errors.character_inventory_id
    end

    test "validates price is greater than 0" do
      invalid_attrs = %{@valid_attrs | price: 0}
      changeset = Listing.changeset(%Listing{}, invalid_attrs)
      refute changeset.valid?
      assert %{price: ["must be greater than 0"]} = errors_on(changeset)

      negative_attrs = %{@valid_attrs | price: -10}
      changeset = Listing.changeset(%Listing{}, negative_attrs)
      refute changeset.valid?
      assert %{price: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "validates status inclusion" do
      invalid_attrs = %{@valid_attrs | status: "invalid_status"}
      changeset = Listing.changeset(%Listing{}, invalid_attrs)
      refute changeset.valid?
      assert %{status: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts all valid statuses" do
      for status <- ["active", "sold", "cancelled"] do
        attrs = %{@valid_attrs | status: status}
        changeset = Listing.changeset(%Listing{}, attrs)
        assert changeset.valid?, "Expected #{status} to be valid"
      end
    end

    test "validates sold status requires sold_at" do
      attrs = %{@valid_attrs | status: "sold", sold_at: nil}
      changeset = Listing.changeset(%Listing{}, attrs)
      refute changeset.valid?
      assert %{sold_at: ["must be set when status is sold"]} = errors_on(changeset)
    end

    test "validates cancelled status requires cancelled_at" do
      attrs = %{@valid_attrs | status: "cancelled", cancelled_at: nil}
      changeset = Listing.changeset(%Listing{}, attrs)
      refute changeset.valid?
      assert %{cancelled_at: ["must be set when status is cancelled"]} = errors_on(changeset)
    end

    test "clears timestamps when status is active" do
      now = DateTime.utc_now()
      attrs = %{@valid_attrs | status: "active", sold_at: now, cancelled_at: now}
      changeset = Listing.changeset(%Listing{}, attrs)
      
      assert changeset.valid?
      assert get_change(changeset, :sold_at) == nil
      assert get_change(changeset, :cancelled_at) == nil
    end

    test "accepts valid sold listing" do
      now = DateTime.utc_now()
      attrs = %{@valid_attrs | status: "sold", sold_at: now, buyer_id: 2}
      changeset = Listing.changeset(%Listing{}, attrs)
      assert changeset.valid?
    end

    test "accepts valid cancelled listing" do
      now = DateTime.utc_now()
      attrs = %{@valid_attrs | status: "cancelled", cancelled_at: now}
      changeset = Listing.changeset(%Listing{}, attrs)
      assert changeset.valid?
    end

    test "accepts default status" do
      minimal_attrs = %{
        price: 75,
        seller_id: 1,
        character_inventory_id: 1
      }

      changeset = Listing.changeset(%Listing{}, minimal_attrs)
      assert changeset.valid?
      assert get_field(changeset, :status) == "active"
    end
  end

  describe "listing_statuses/0" do
    test "returns list of valid statuses" do
      statuses = Listing.listing_statuses()
      assert statuses == ["active", "sold", "cancelled"]
    end
  end
end
