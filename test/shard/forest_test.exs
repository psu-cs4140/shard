defmodule Shard.ForestTest do
  use Shard.DataCase

  alias Shard.Forest
  alias Shard.Forest.ChoppingInventory
  alias Shard.Characters
  import Shard.UsersFixtures

  describe "start_chopping/1" do
    test "sets is_chopping to true for a character not currently chopping" do
      character = character_fixture()
      assert character.is_chopping == false
      assert character.chopping_started_at == nil

      {:ok, updated_character} = Forest.start_chopping(character)

      assert updated_character.is_chopping == true
      assert updated_character.chopping_started_at != nil
    end

    test "is idempotent when character is already chopping" do
      character = character_fixture()
      {:ok, chopping_character} = Forest.start_chopping(character)
      original_started_at = chopping_character.chopping_started_at

      # Call start_chopping again
      {:ok, still_chopping} = Forest.start_chopping(chopping_character)

      assert still_chopping.is_chopping == true
      assert still_chopping.chopping_started_at == original_started_at
    end
  end

  describe "apply_chopping_ticks/1" do
    test "returns 0 ticks when character is not chopping" do
      character = character_fixture()

      {:ok, result} = Forest.apply_chopping_ticks(character)

      assert result.ticks_applied == 0
      assert result.character.id == character.id
      assert %ChoppingInventory{} = result.chopping_inventory
      assert result.gained_resources == %{}
    end

    test "returns 0 ticks when chopping_started_at is nil" do
      character = character_fixture()

      {:ok, updated} =
        Characters.update_character(character, %{is_chopping: true, chopping_started_at: nil})

      {:ok, result} = Forest.apply_chopping_ticks(updated)

      assert result.ticks_applied == 0
      assert result.gained_resources == %{}
    end

    test "calculates and applies ticks based on elapsed time" do
      character = character_fixture()
      # Set chopping_started_at to 30 seconds ago (5 ticks at 6 seconds each)
      past_time = DateTime.add(DateTime.utc_now(), -30, :second)

      {:ok, chopping_char} =
        Characters.update_character(character, %{is_chopping: true, chopping_started_at: past_time})

      {:ok, result} = Forest.apply_chopping_ticks(chopping_char)

      assert result.ticks_applied == 5
      assert result.gained_resources != %{}
      # Verify that some resources were added
      inventory = result.chopping_inventory

      total_resources = inventory.wood + inventory.sticks + inventory.seeds + inventory.mushrooms + inventory.resin

      assert total_resources == 5
    end

    test "updates chopping_started_at to current time after applying ticks" do
      character = character_fixture()
      past_time = DateTime.add(DateTime.utc_now(), -30, :second)

      {:ok, chopping_char} =
        Characters.update_character(character, %{is_chopping: true, chopping_started_at: past_time})

      {:ok, result} = Forest.apply_chopping_ticks(chopping_char)

      # The new chopping_started_at should be close to now
      diff = DateTime.diff(DateTime.utc_now(), result.character.chopping_started_at, :second)
      assert diff <= 1
    end
  end

  describe "stop_chopping/1" do
    test "applies pending ticks and sets is_chopping to false" do
      character = character_fixture()
      # 3 ticks
      past_time = DateTime.add(DateTime.utc_now(), -18, :second)

      {:ok, chopping_char} =
        Characters.update_character(character, %{is_chopping: true, chopping_started_at: past_time})

      {:ok, result} = Forest.stop_chopping(chopping_char)

      assert result.ticks_applied == 3
      assert result.character.is_chopping == false
      assert result.character.chopping_started_at == nil
      # Verify resources were added
      total_resources = result.chopping_inventory.wood + result.chopping_inventory.sticks + 
                       result.chopping_inventory.seeds + result.chopping_inventory.mushrooms + 
                       result.chopping_inventory.resin

      assert total_resources == 3
    end
  end

  describe "get_or_create_chopping_inventory/1" do
    test "creates a new inventory if none exists" do
      character = character_fixture()

      {:ok, inventory} = Forest.get_or_create_chopping_inventory(character)

      assert inventory.character_id == character.id
      assert inventory.wood == 0
      assert inventory.sticks == 0
      assert inventory.seeds == 0
      assert inventory.mushrooms == 0
      assert inventory.resin == 0
    end

    test "returns existing inventory if it exists" do
      character = character_fixture()
      {:ok, original_inventory} = Forest.get_or_create_chopping_inventory(character)

      # Call again
      {:ok, fetched_inventory} = Forest.get_or_create_chopping_inventory(character)

      assert fetched_inventory.id == original_inventory.id
    end
  end

  describe "roll_resource/0" do
    test "returns a valid resource type" do
      resource = Forest.roll_resource()
      assert resource in [:wood, :sticks, :seeds, :mushrooms, :resin]
    end

    test "returns resources with expected distribution over many rolls" do
      # Roll 1000 times and check that we get all resource types
      resources = Enum.map(1..1000, fn _ -> Forest.roll_resource() end)
      unique_resources = Enum.uniq(resources)

      # We should get at least wood and sticks in 1000 rolls
      assert :wood in unique_resources
      assert :sticks in unique_resources
    end
  end

  describe "add_resources/2" do
    test "adds resources to an existing inventory" do
      character = character_fixture()
      {:ok, inventory} = Forest.get_or_create_chopping_inventory(character)

      {:ok, updated_inventory} = Forest.add_resources(inventory, %{wood: 5, sticks: 3, seeds: 1})

      assert updated_inventory.wood == 5
      assert updated_inventory.sticks == 3
      assert updated_inventory.seeds == 1
      assert updated_inventory.mushrooms == 0
      assert updated_inventory.resin == 0
    end

    test "accumulates resources across multiple additions" do
      character = character_fixture()
      {:ok, inventory} = Forest.get_or_create_chopping_inventory(character)

      {:ok, inventory1} = Forest.add_resources(inventory, %{wood: 5})
      {:ok, inventory2} = Forest.add_resources(inventory1, %{wood: 3, sticks: 2})

      assert inventory2.wood == 8
      assert inventory2.sticks == 2
    end
  end

  describe "total_gold_value/1" do
    test "calculates correct gold value for inventory" do
      character = character_fixture()
      {:ok, inventory} = Forest.get_or_create_chopping_inventory(character)

      {:ok, updated_inventory} =
        Forest.add_resources(inventory, %{
          wood: 10,
          sticks: 5,
          seeds: 2,
          mushrooms: 1,
          resin: 1
        })

      total = Forest.total_gold_value(updated_inventory)
      assert total > 0
    end
  end

  describe "get_chopping_status/1" do
    test "returns status for a non-chopping character" do
      character = character_fixture()

      {:ok, status} = Forest.get_chopping_status(character)

      assert status.is_chopping == false
      assert status.ticks_pending == 0
      assert %ChoppingInventory{} = status.chopping_inventory
    end

    test "returns status with pending ticks for a chopping character" do
      character = character_fixture()
      # 3 ticks
      past_time = DateTime.add(DateTime.utc_now(), -18, :second)

      {:ok, chopping_char} =
        Characters.update_character(character, %{is_chopping: true, chopping_started_at: past_time})

      {:ok, status} = Forest.get_chopping_status(chopping_char)

      assert status.is_chopping == true
      assert status.ticks_pending == 3
    end
  end

  describe "calculate_pending_ticks/1" do
    test "returns 0 for non-chopping character" do
      character = character_fixture()
      assert Forest.calculate_pending_ticks(character) == 0
    end

    test "calculates pending ticks correctly" do
      character = character_fixture()
      # 4 ticks (25 / 6 = 4)
      past_time = DateTime.add(DateTime.utc_now(), -25, :second)

      {:ok, chopping_char} =
        Characters.update_character(character, %{is_chopping: true, chopping_started_at: past_time})

      pending = Forest.calculate_pending_ticks(chopping_char)
      assert pending == 4
    end
  end

  describe "sell_all_resources/1" do
    test "converts all resources to gold" do
      character = character_fixture()
      {:ok, inventory} = Forest.get_or_create_chopping_inventory(character)

      {:ok, inventory_with_resources} =
        Forest.add_resources(inventory, %{wood: 10, sticks: 5, seeds: 2})

      {:ok, result} = Forest.sell_all_resources(character)

      assert result.gold_earned > 0
      assert result.chopping_inventory.wood == 0
      assert result.chopping_inventory.sticks == 0
      assert result.chopping_inventory.seeds == 0
    end

    test "returns 0 gold when no resources to sell" do
      character = character_fixture()
      {:ok, _inventory} = Forest.get_or_create_chopping_inventory(character)

      {:ok, result} = Forest.sell_all_resources(character)

      assert result.gold_earned == 0
    end
  end

  describe "ChoppingInventory changeset" do
    test "validates required fields" do
      changeset = ChoppingInventory.changeset(%ChoppingInventory{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.character_id
    end

    test "validates non-negative resource amounts" do
      attrs = %{
        character_id: 1,
        wood: -1,
        sticks: -1,
        seeds: -1,
        mushrooms: -1,
        resin: -1
      }

      changeset = ChoppingInventory.changeset(%ChoppingInventory{}, attrs)
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "must be greater than or equal to 0" in errors.wood
      assert "must be greater than or equal to 0" in errors.sticks
      assert "must be greater than or equal to 0" in errors.seeds
      assert "must be greater than or equal to 0" in errors.mushrooms
      assert "must be greater than or equal to 0" in errors.resin
    end

    test "accepts valid chopping inventory data" do
      attrs = %{
        character_id: 1,
        wood: 10,
        sticks: 5,
        seeds: 3,
        mushrooms: 1,
        resin: 0
      }

      changeset = ChoppingInventory.changeset(%ChoppingInventory{}, attrs)
      assert changeset.valid?
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
