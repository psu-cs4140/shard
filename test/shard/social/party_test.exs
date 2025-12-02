defmodule Shard.Social.PartyTest do
  use Shard.DataCase

  alias Shard.Social.Party
  alias Shard.UsersFixtures

  describe "changeset/2" do
    setup do
      user = UsersFixtures.user_fixture()
      %{user: user}
    end

    test "valid changeset with required fields", %{user: user} do
      attrs = %{leader_id: user.id}
      changeset = Party.changeset(%Party{}, attrs)
      assert changeset.valid?
    end

    test "valid changeset with all fields", %{user: user} do
      attrs = %{
        name: "Test Party",
        leader_id: user.id,
        max_size: 4
      }
      changeset = Party.changeset(%Party{}, attrs)
      assert changeset.valid?
      assert changeset.changes.name == "Test Party"
      assert changeset.changes.leader_id == user.id
      assert changeset.changes.max_size == 4
    end

    test "invalid changeset without leader_id" do
      attrs = %{name: "Test Party"}
      changeset = Party.changeset(%Party{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).leader_id
    end

    test "invalid changeset with max_size of 0" do
      user = UsersFixtures.user_fixture()
      attrs = %{leader_id: user.id, max_size: 0}
      changeset = Party.changeset(%Party{}, attrs)
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).max_size
    end

    test "invalid changeset with max_size greater than 10" do
      user = UsersFixtures.user_fixture()
      attrs = %{leader_id: user.id, max_size: 11}
      changeset = Party.changeset(%Party{}, attrs)
      refute changeset.valid?
      assert "must be less than or equal to 10" in errors_on(changeset).max_size
    end

    test "valid changeset with max_size at boundary values" do
      user = UsersFixtures.user_fixture()
      
      # Test min boundary (1)
      attrs = %{leader_id: user.id, max_size: 1}
      changeset = Party.changeset(%Party{}, attrs)
      assert changeset.valid?
      
      # Test max boundary (10)
      attrs = %{leader_id: user.id, max_size: 10}
      changeset = Party.changeset(%Party{}, attrs)
      assert changeset.valid?
    end

    test "changeset ignores unknown fields" do
      user = UsersFixtures.user_fixture()
      attrs = %{
        leader_id: user.id,
        unknown_field: "should be ignored"
      }
      changeset = Party.changeset(%Party{}, attrs)
      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :unknown_field)
    end

    test "changeset with default max_size" do
      user = UsersFixtures.user_fixture()
      attrs = %{leader_id: user.id}
      changeset = Party.changeset(%Party{}, attrs)
      assert changeset.valid?
      # Default max_size should be 6 according to schema
      party = %Party{}
      assert party.max_size == 6
    end
  end

  describe "schema" do
    test "has correct fields and types" do
      party = %Party{}
      assert Map.has_key?(party, :name)
      assert Map.has_key?(party, :max_size)
      assert Map.has_key?(party, :leader_id)
      assert party.max_size == 6  # default value
    end
  end
end
