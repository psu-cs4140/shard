defmodule Shard.MiningTest do
  use Shard.DataCase

  alias Shard.Mining
  alias Shard.Mining.MiningInventory
  alias Shard.Characters

  describe "start_mining/1" do
    test "sets is_mining to true for a character not currently mining" do
      character = character_fixture()
      assert character.is_mining == false
      assert character.mining_started_at == nil

      {:ok, updated_character} = Mining.start_mining(character)

      assert updated_character.is_mining == true
      assert updated_character.mining_started_at != nil
    end

    test "is idempotent when character is already mining" do
      character = character_fixture()
      {:ok, mining_character} = Mining.start_mining(character)
      original_started_at = mining_character.mining_started_at

      # Call start_mining again
      {:ok, still_mining} = Mining.start_mining(mining_character)

      assert still_mining.is_mining == true
      assert still_mining.mining_started_at == original_started_at
    end
  end

  describe "apply_mining_ticks/1" do
    test "returns 0 ticks when character is not mining" do
      character = character_fixture()

      {:ok, result} = Mining.apply_mining_ticks(character)

      assert result.ticks_applied == 0
      assert result.character.id == character.id
      assert %MiningInventory{} = result.mining_inventory
      assert result.gained_resources == %{}
    end

    test "returns 0 ticks when mining_started_at is nil" do
      character = character_fixture()

      {:ok, updated} =
        Characters.update_character(character, %{is_mining: true, mining_started_at: nil})

      {:ok, result} = Mining.apply_mining_ticks(updated)

      assert result.ticks_applied == 0
      assert result.gained_resources == %{}
    end

    test "calculates and applies ticks based on elapsed time" do
      character = character_fixture()
      # Set mining_started_at to 30 seconds ago (5 ticks at 6 seconds each)
      past_time = DateTime.add(DateTime.utc_now(), -30, :second)

      {:ok, mining_char} =
        Characters.update_character(character, %{is_mining: true, mining_started_at: past_time})

      {:ok, result} = Mining.apply_mining_ticks(mining_char)

      assert result.ticks_applied == 5
      assert result.gained_resources != %{}
      # Verify that some resources were added
      inventory = result.mining_inventory

      total_resources =
        inventory.stone + inventory.coal + inventory.copper + inventory.iron + inventory.gems

      assert total_resources == 5
    end

    test "updates mining_started_at to current time after applying ticks" do
      character = character_fixture()
      past_time = DateTime.add(DateTime.utc_now(), -30, :second)

      {:ok, mining_char} =
        Characters.update_character(character, %{is_mining: true, mining_started_at: past_time})

      {:ok, result} = Mining.apply_mining_ticks(mining_char)

      # The new mining_started_at should be close to now
      diff = DateTime.diff(DateTime.utc_now(), result.character.mining_started_at, :second)
      assert diff <= 1
    end
  end

  describe "stop_mining/1" do
    test "applies pending ticks and sets is_mining to false" do
      character = character_fixture()
      # 3 ticks
      past_time = DateTime.add(DateTime.utc_now(), -18, :second)

      {:ok, mining_char} =
        Characters.update_character(character, %{is_mining: true, mining_started_at: past_time})

      {:ok, result} = Mining.stop_mining(mining_char)

      assert result.ticks_applied == 3
      assert result.character.is_mining == false
      assert result.character.mining_started_at == nil
      # Verify resources were added
      total_resources =
        result.mining_inventory.stone + result.mining_inventory.coal +
          result.mining_inventory.copper + result.mining_inventory.iron +
          result.mining_inventory.gems

      assert total_resources == 3
    end
  end

  describe "get_or_create_mining_inventory/1" do
    test "creates a new inventory if none exists" do
      character = character_fixture()

      {:ok, inventory} = Mining.get_or_create_mining_inventory(character)

      assert inventory.character_id == character.id
      assert inventory.stone == 0
      assert inventory.coal == 0
      assert inventory.copper == 0
      assert inventory.iron == 0
      assert inventory.gems == 0
    end

    test "returns existing inventory if it exists" do
      character = character_fixture()
      {:ok, original_inventory} = Mining.get_or_create_mining_inventory(character)

      # Call again
      {:ok, fetched_inventory} = Mining.get_or_create_mining_inventory(character)

      assert fetched_inventory.id == original_inventory.id
    end
  end

  describe "roll_resource/0" do
    test "returns a valid resource type" do
      resource = Mining.roll_resource()
      assert resource in [:stone, :coal, :copper, :iron, :gem]
    end

    test "returns resources with expected distribution over many rolls" do
      # Roll 1000 times and check that we get all resource types
      resources = Enum.map(1..1000, fn _ -> Mining.roll_resource() end)
      unique_resources = Enum.uniq(resources)

      # We should get at least stone, coal, and copper in 1000 rolls
      assert :stone in unique_resources
      assert :coal in unique_resources
      assert :copper in unique_resources
    end
  end

  describe "add_resources/2" do
    test "adds resources to an existing inventory" do
      character = character_fixture()
      {:ok, inventory} = Mining.get_or_create_mining_inventory(character)

      {:ok, updated_inventory} = Mining.add_resources(inventory, %{stone: 5, coal: 3, gem: 1})

      assert updated_inventory.stone == 5
      assert updated_inventory.coal == 3
      assert updated_inventory.gems == 1
      assert updated_inventory.copper == 0
      assert updated_inventory.iron == 0
    end

    test "accumulates resources across multiple additions" do
      character = character_fixture()
      {:ok, inventory} = Mining.get_or_create_mining_inventory(character)

      {:ok, inventory1} = Mining.add_resources(inventory, %{stone: 5})
      {:ok, inventory2} = Mining.add_resources(inventory1, %{stone: 3, coal: 2})

      assert inventory2.stone == 8
      assert inventory2.coal == 2
    end
  end

  describe "total_gold_value/1" do
    test "calculates correct gold value for inventory" do
      character = character_fixture()
      {:ok, inventory} = Mining.get_or_create_mining_inventory(character)

      {:ok, updated_inventory} =
        Mining.add_resources(inventory, %{
          # 10 * 1 = 10
          stone: 10,
          # 5 * 2 = 10
          coal: 5,
          # 2 * 4 = 8
          copper: 2,
          # 1 * 8 = 8
          iron: 1,
          # 1 * 20 = 20
          gem: 1
        })

      total = Mining.total_gold_value(updated_inventory)
      assert total == 56
    end
  end

  describe "get_mining_status/1" do
    test "returns status for a non-mining character" do
      character = character_fixture()

      {:ok, status} = Mining.get_mining_status(character)

      assert status.is_mining == false
      assert status.ticks_pending == 0
      assert %MiningInventory{} = status.mining_inventory
    end

    test "returns status with pending ticks for a mining character" do
      character = character_fixture()
      # 3 ticks
      past_time = DateTime.add(DateTime.utc_now(), -18, :second)

      {:ok, mining_char} =
        Characters.update_character(character, %{is_mining: true, mining_started_at: past_time})

      {:ok, status} = Mining.get_mining_status(mining_char)

      assert status.is_mining == true
      assert status.ticks_pending == 3
    end
  end

  describe "calculate_pending_ticks/1" do
    test "returns 0 for non-mining character" do
      character = character_fixture()
      assert Mining.calculate_pending_ticks(character) == 0
    end

    test "calculates pending ticks correctly" do
      character = character_fixture()
      # 4 ticks (25 / 6 = 4)
      past_time = DateTime.add(DateTime.utc_now(), -25, :second)

      {:ok, mining_char} =
        Characters.update_character(character, %{is_mining: true, mining_started_at: past_time})

      pending = Mining.calculate_pending_ticks(mining_char)
      assert pending == 4
    end
  end

  # Helper function to create a test character
  defp character_fixture(attrs \\ %{}) do
    user = user_fixture()

    valid_attrs =
      Enum.into(attrs, %{
        name: "Test Character #{System.unique_integer([:positive])}",
        class: "warrior",
        race: "human",
        user_id: user.id
      })

    {:ok, character} = Characters.create_character(valid_attrs)
    character
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
