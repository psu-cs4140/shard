defmodule ShardWeb.UserLive.Commands1Test do
  use Shard.DataCase, async: true
  alias ShardWeb.UserLive.Commands1

  describe "process_command/2" do
    setup do
      # Create a basic game state for testing
      game_state = %{
        player_position: {0, 0},
        character: %{
          id: 1,
          current_zone_id: 1,
          name: "TestCharacter"
        },
        player_stats: %{
          health: 100,
          max_health: 100,
          stamina: 50,
          max_stamina: 50,
          mana: 30,
          max_mana: 30
        },
        inventory_items: [],
        monsters: [],
        combat: false,
        map_id: 1,
        quests: [],
        pending_quest_offer: nil
      }

      {:ok, game_state: game_state}
    end

    test "help command returns list of available commands", %{game_state: game_state} do
      {response, _updated_state} = Commands1.process_command("help", game_state)

      assert is_list(response)
      assert Enum.any?(response, &String.contains?(&1, "Available commands"))
      assert Enum.any?(response, &String.contains?(&1, "look"))
      assert Enum.any?(response, &String.contains?(&1, "stats"))
      assert Enum.any?(response, &String.contains?(&1, "inventory"))
    end

    test "stats command returns character stats", %{game_state: game_state} do
      {response, _updated_state} = Commands1.process_command("stats", game_state)

      assert is_list(response)
      assert Enum.any?(response, &String.contains?(&1, "Character Stats"))
      assert Enum.any?(response, &String.contains?(&1, "Health: 100/100"))
      assert Enum.any?(response, &String.contains?(&1, "Stamina: 50/50"))
      assert Enum.any?(response, &String.contains?(&1, "Mana: 30/30"))
    end

    test "position command returns current position", %{game_state: game_state} do
      {response, _updated_state} = Commands1.process_command("position", game_state)

      assert response == ["You are at position (0, 0)."]
    end

    test "inventory command with empty inventory", %{game_state: game_state} do
      {response, _updated_state} = Commands1.process_command("inventory", game_state)

      assert response == ["Your inventory is empty."]
    end

    test "inventory command with items", %{game_state: game_state} do
      # Add mock inventory items
      inventory_items = [
        %{
          item: %{name: "Sword"},
          quantity: 1,
          equipped: true
        },
        %{
          item: %{name: "Potion"},
          quantity: 3,
          equipped: false
        }
      ]

      game_state_with_items = %{game_state | inventory_items: inventory_items}
      {response, _updated_state} = Commands1.process_command("inventory", game_state_with_items)

      assert is_list(response)
      assert Enum.any?(response, &String.contains?(&1, "Your inventory contains"))
      assert Enum.any?(response, &String.contains?(&1, "Sword (equipped)"))
      assert Enum.any?(response, &String.contains?(&1, "Potion x3"))
    end

    test "attack command with no monsters", %{game_state: game_state} do
      {response, _updated_state} = Commands1.process_command("attack", game_state)

      assert response == ["There are no monsters here to attack."]
    end

    test "flee command when not in combat", %{game_state: game_state} do
      {response, _updated_state} = Commands1.process_command("flee", game_state)

      assert response == ["There is nothing to flee from..."]
    end

    test "movement commands", %{game_state: game_state} do
      # Test north movement
      {_response, _updated_state} = Commands1.process_command("north", game_state)
      {_response, _updated_state} = Commands1.process_command("n", game_state)

      # Test other directions
      {_response, _updated_state} = Commands1.process_command("south", game_state)
      {_response, _updated_state} = Commands1.process_command("east", game_state)
      {_response, _updated_state} = Commands1.process_command("west", game_state)

      # Test diagonal movements
      {_response, _updated_state} = Commands1.process_command("northeast", game_state)
      {_response, _updated_state} = Commands1.process_command("ne", game_state)
    end

    test "accept command without pending quest", %{game_state: game_state} do
      {response, _updated_state} = Commands1.process_command("accept", game_state)

      # This should handle the case where there's no pending quest offer
      assert is_list(response)
    end

    test "deny command without pending quest", %{game_state: game_state} do
      {response, _updated_state} = Commands1.process_command("deny", game_state)

      # This should handle the case where there's no pending quest offer
      assert is_list(response)
    end

    test "unknown command returns error message", %{game_state: game_state} do
      {response, _updated_state} = Commands1.process_command("invalidcommand", game_state)

      assert is_list(response)
      assert Enum.any?(response, &String.contains?(&1, "Unknown command"))
      assert Enum.any?(response, &String.contains?(&1, "invalidcommand"))
    end

    test "case insensitive commands", %{game_state: game_state} do
      {response1, _} = Commands1.process_command("HELP", game_state)
      {response2, _} = Commands1.process_command("help", game_state)
      {response3, _} = Commands1.process_command("Help", game_state)

      assert response1 == response2
      assert response2 == response3
    end
  end
end
