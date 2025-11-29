defmodule ShardWeb.UserLive.ItemCommandsTest do
  use Shard.DataCase

  alias ShardWeb.UserLive.ItemCommands
  alias Shard.Items.RoomItem
  alias Shard.{Repo, Characters, Items}

  describe "get_items_at_location/3" do
    setup do
      # Create test items
      {:ok, pickupable_item} =
        Items.create_item(%{
          name: "Test Sword",
          description: "A test sword",
          item_type: "weapon",
          pickup: true,
          is_active: true
        })

      {:ok, non_pickupable_item} =
        Items.create_item(%{
          name: "Heavy Boulder",
          description: "A very heavy boulder",
          item_type: "misc",
          pickup: false,
          is_active: true
        })

      {:ok, inactive_item} =
        Items.create_item(%{
          name: "Inactive Item",
          description: "An inactive item",
          item_type: "misc",
          pickup: true,
          is_active: false
        })

      # Create room items
      {:ok, room_item1} =
        Repo.insert(%RoomItem{
          item_id: pickupable_item.id,
          location: "5,10,0",
          quantity: 2
        })

      {:ok, room_item2} =
        Repo.insert(%RoomItem{
          item_id: non_pickupable_item.id,
          location: "5,10,0",
          quantity: 1
        })

      # Create direct item with location
      {:ok, direct_item} =
        Items.create_item(%{
          name: "Direct Item",
          description: "An item placed directly",
          item_type: "misc",
          pickup: true,
          is_active: true,
          location: "5,10,0"
        })

      %{
        pickupable_item: pickupable_item,
        non_pickupable_item: non_pickupable_item,
        inactive_item: inactive_item,
        room_item1: room_item1,
        room_item2: room_item2,
        direct_item: direct_item
      }
    end

    test "returns items from both RoomItem and Item tables at location", %{
      pickupable_item: _pickupable_item,
      non_pickupable_item: _non_pickupable_item,
      direct_item: _direct_item
    } do
      items = ItemCommands.get_items_at_location(5, 10, 1)

      assert length(items) == 3

      item_names = Enum.map(items, & &1.name)
      assert "Test Sword" in item_names
      assert "Heavy Boulder" in item_names
      assert "Direct Item" in item_names
    end

    test "excludes inactive items" do
      items = ItemCommands.get_items_at_location(5, 10, 1)

      item_names = Enum.map(items, & &1.name)
      refute "Inactive Item" in item_names
    end

    test "returns empty list when no items at location" do
      items = ItemCommands.get_items_at_location(99, 99, 1)
      assert items == []
    end

    test "removes duplicates based on name", %{pickupable_item: pickupable_item} do
      # Create another room item with same item as existing pickupable_item
      # This simulates having the same item in multiple room item records
      {:ok, _room_item} =
        Repo.insert(%RoomItem{
          # Use the existing pickupable item's ID
          item_id: pickupable_item.id,
          location: "5,10,0",
          quantity: 1
        })

      items = ItemCommands.get_items_at_location(5, 10, 1)

      # Should still only have 3 unique items despite duplicate room items
      assert length(items) == 3

      # Verify we don't have duplicate names
      item_names = Enum.map(items, & &1.name)
      unique_names = Enum.uniq(item_names)
      assert length(item_names) == length(unique_names)
    end
  end

  describe "parse_pickup_command/1" do
    test "parses quoted item names with double quotes" do
      assert {:ok, "magic sword"} = ItemCommands.parse_pickup_command("pickup \"magic sword\"")

      assert {:ok, "long item name"} =
               ItemCommands.parse_pickup_command("pickup \"long item name\"")
    end

    test "parses quoted item names with single quotes" do
      assert {:ok, "magic sword"} = ItemCommands.parse_pickup_command("pickup 'magic sword'")

      assert {:ok, "long item name"} =
               ItemCommands.parse_pickup_command("pickup 'long item name'")
    end

    test "parses single word item names without quotes" do
      assert {:ok, "sword"} = ItemCommands.parse_pickup_command("pickup sword")
      assert {:ok, "shield"} = ItemCommands.parse_pickup_command("pickup shield")
    end

    test "handles case insensitive pickup command" do
      assert {:ok, "sword"} = ItemCommands.parse_pickup_command("PICKUP sword")
      assert {:ok, "sword"} = ItemCommands.parse_pickup_command("Pickup sword")
    end

    test "handles extra whitespace" do
      assert {:ok, "sword"} = ItemCommands.parse_pickup_command("pickup   sword   ")

      assert {:ok, "magic sword"} =
               ItemCommands.parse_pickup_command("pickup   \"magic sword\"   ")
    end

    test "returns error for invalid formats" do
      assert :error = ItemCommands.parse_pickup_command("pickup")
      assert :error = ItemCommands.parse_pickup_command("pickup \"")
      assert :error = ItemCommands.parse_pickup_command("pickup '")
      assert :error = ItemCommands.parse_pickup_command("get sword")
      assert :error = ItemCommands.parse_pickup_command("pickup multiple words without quotes")
    end
  end

  describe "execute_pickup_command/2" do
    setup do
      # Create a user first
      {:ok, user} = Shard.Users.register_user(%{
        email: "test@example.com",
        password: "password123"
      })

      # Create a character with the user_id
      {:ok, character} =
        Characters.create_character(%{
          name: "Test Character",
          level: 1,
          health: 100,
          max_health: 100,
          experience: 0,
          class: "warrior",
          race: "human",
          user_id: user.id
        })

      # Create test items
      {:ok, pickupable_item} =
        Items.create_item(%{
          name: "Test Sword",
          description: "A test sword",
          item_type: "weapon",
          pickup: true,
          is_active: true
        })

      {:ok, non_pickupable_item} =
        Items.create_item(%{
          name: "Heavy Boulder",
          description: "A very heavy boulder",
          item_type: "misc",
          pickup: false,
          is_active: true
        })

      # Create room items at player location
      {:ok, room_item1} =
        Repo.insert(%RoomItem{
          item_id: pickupable_item.id,
          location: "0,0,0",
          quantity: 1
        })

      {:ok, room_item2} =
        Repo.insert(%RoomItem{
          item_id: non_pickupable_item.id,
          location: "0,0,0",
          quantity: 1
        })

      game_state = %{
        character: character,
        player_position: {0, 0},
        inventory_items: []
      }

      %{
        character: character,
        pickupable_item: pickupable_item,
        non_pickupable_item: non_pickupable_item,
        room_item1: room_item1,
        room_item2: room_item2,
        game_state: game_state
      }
    end

    test "successfully picks up a pickupable item", %{
      game_state: game_state,
      pickupable_item: _pickupable_item
    } do
      {response, updated_game_state} =
        ItemCommands.execute_pickup_command(game_state, "Test Sword")

      assert "You pick up Test Sword." in response
      assert "Test Sword has been added to your inventory." in response
      assert updated_game_state.inventory_items != game_state.inventory_items
    end

    test "fails to pick up non-pickupable item", %{
      game_state: game_state,
      non_pickupable_item: _non_pickupable_item
    } do
      {response, updated_game_state} =
        ItemCommands.execute_pickup_command(game_state, "Heavy Boulder")

      assert "You cannot pick up Heavy Boulder." in response
      assert updated_game_state == game_state
    end

    test "handles item not found with suggestions", %{
      game_state: game_state
    } do
      {response, updated_game_state} =
        ItemCommands.execute_pickup_command(game_state, "Nonexistent Item")

      assert Enum.any?(
               response,
               &String.contains?(&1, "There is no item named 'Nonexistent Item' here.")
             )

      assert Enum.any?(response, &String.contains?(&1, "Available items:"))
      assert updated_game_state == game_state
    end

    test "handles no items at location", %{character: character} do
      empty_game_state = %{
        character: character,
        player_position: {99, 99},
        inventory_items: []
      }

      {response, updated_game_state} =
        ItemCommands.execute_pickup_command(empty_game_state, "Any Item")

      assert "There are no items here to pick up." in response
      assert updated_game_state == empty_game_state
    end

    test "handles case insensitive item matching", %{
      game_state: game_state
    } do
      {response, _updated_game_state} =
        ItemCommands.execute_pickup_command(game_state, "test sword")

      assert "You pick up Test Sword." in response
    end

    test "handles case insensitive item matching with different case", %{
      game_state: game_state
    } do
      {response, _updated_game_state} =
        ItemCommands.execute_pickup_command(game_state, "TEST SWORD")

      assert "You pick up Test Sword." in response
    end
  end
end
