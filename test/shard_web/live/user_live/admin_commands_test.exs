defmodule ShardWeb.UserLive.AdminCommandsTest do
  use Shard.DataCase, async: true

  alias ShardWeb.UserLive.AdminCommands
  alias Shard.Items.AdminStick
  alias ShardWeb.UserLive.AdminZoneEditor

  import Mox

  # Mock the AdminStick and AdminZoneEditor modules
  setup :verify_on_exit!

  describe "handle_create_room_command/2" do
    test "creates room when user has admin stick and valid direction" do
      game_state = %{character: %{id: 1}}
      
      # Mock AdminStick to return true
      expect(AdminStick, :has_admin_stick?, fn 1 -> true end)
      
      # Mock AdminZoneEditor to return success
      expect(AdminZoneEditor, :create_room_in_direction, fn ^game_state, "north" ->
        {["Room created to the north."], game_state}
      end)

      result = AdminCommands.handle_create_room_command("create room north", game_state)
      
      assert {["Room created to the north."], ^game_state} = result
    end

    test "denies room creation when user lacks admin stick" do
      game_state = %{character: %{id: 1}}
      
      # Mock AdminStick to return false
      expect(AdminStick, :has_admin_stick?, fn 1 -> false end)

      result = AdminCommands.handle_create_room_command("create room north", game_state)
      
      assert {["you do not wield powerful enough magic to change the very earth you stand on"], ^game_state} = result
    end

    test "returns error for invalid command format" do
      game_state = %{character: %{id: 1}}

      result = AdminCommands.handle_create_room_command("create room", game_state)
      
      assert {["Invalid create room command. Usage: create room [direction]"], ^game_state} = result
    end

    test "handles various direction formats" do
      game_state = %{character: %{id: 1}}
      
      # Mock AdminStick to return true for all tests
      expect(AdminStick, :has_admin_stick?, 3, fn 1 -> true end)
      
      # Mock AdminZoneEditor for different direction formats
      expect(AdminZoneEditor, :create_room_in_direction, fn ^game_state, "north" ->
        {["Room created north."], game_state}
      end)
      expect(AdminZoneEditor, :create_room_in_direction, fn ^game_state, "south" ->
        {["Room created south."], game_state}
      end)
      expect(AdminZoneEditor, :create_room_in_direction, fn ^game_state, "east" ->
        {["Room created east."], game_state}
      end)

      # Test different command formats
      assert {["Room created north."], ^game_state} = AdminCommands.handle_create_room_command("create room north", game_state)
      assert {["Room created south."], ^game_state} = AdminCommands.handle_create_room_command("create room \"south\"", game_state)
      assert {["Room created east."], ^game_state} = AdminCommands.handle_create_room_command("CREATE ROOM EAST", game_state)
    end
  end

  describe "handle_delete_room_command/2" do
    test "deletes room when user has admin stick and valid direction" do
      game_state = %{character: %{id: 1}}
      
      expect(AdminStick, :has_admin_stick?, fn 1 -> true end)
      expect(AdminZoneEditor, :delete_room_in_direction, fn ^game_state, "north" ->
        {["Room deleted to the north."], game_state}
      end)

      result = AdminCommands.handle_delete_room_command("delete room north", game_state)
      
      assert {["Room deleted to the north."], ^game_state} = result
    end

    test "denies room deletion when user lacks admin stick" do
      game_state = %{character: %{id: 1}}
      
      expect(AdminStick, :has_admin_stick?, fn 1 -> false end)

      result = AdminCommands.handle_delete_room_command("delete room north", game_state)
      
      assert {["you do not wield powerful enough magic to change the very earth you stand on"], ^game_state} = result
    end

    test "returns error for invalid command format" do
      game_state = %{character: %{id: 1}}

      result = AdminCommands.handle_delete_room_command("delete room", game_state)
      
      assert {["Invalid delete room command. Usage: delete room [direction]"], ^game_state} = result
    end
  end

  describe "handle_create_door_command/2" do
    test "creates door when user has admin stick and valid direction" do
      game_state = %{character: %{id: 1}}
      
      expect(AdminStick, :has_admin_stick?, fn 1 -> true end)
      expect(AdminZoneEditor, :create_door_in_direction, fn ^game_state, "north" ->
        {["Door created to the north."], game_state}
      end)

      result = AdminCommands.handle_create_door_command("create door north", game_state)
      
      assert {["Door created to the north."], ^game_state} = result
    end

    test "denies door creation when user lacks admin stick" do
      game_state = %{character: %{id: 1}}
      
      expect(AdminStick, :has_admin_stick?, fn 1 -> false end)

      result = AdminCommands.handle_create_door_command("create door north", game_state)
      
      assert {["you do not wield powerful enough magic to change the very earth you stand on"], ^game_state} = result
    end

    test "returns error for invalid command format" do
      game_state = %{character: %{id: 1}}

      result = AdminCommands.handle_create_door_command("create door", game_state)
      
      assert {["Invalid create door command. Usage: create door [direction]"], ^game_state} = result
    end
  end

  describe "handle_delete_door_command/2" do
    test "deletes door when user has admin stick and valid direction" do
      game_state = %{character: %{id: 1}}
      
      expect(AdminStick, :has_admin_stick?, fn 1 -> true end)
      expect(AdminZoneEditor, :delete_door_in_direction, fn ^game_state, "north" ->
        {["Door deleted to the north."], game_state}
      end)

      result = AdminCommands.handle_delete_door_command("delete door north", game_state)
      
      assert {["Door deleted to the north."], ^game_state} = result
    end

    test "denies door deletion when user lacks admin stick" do
      game_state = %{character: %{id: 1}}
      
      expect(AdminStick, :has_admin_stick?, fn 1 -> false end)

      result = AdminCommands.handle_delete_door_command("delete door north", game_state)
      
      assert {["you do not wield powerful enough magic to change the very earth you stand on"], ^game_state} = result
    end

    test "returns error for invalid command format" do
      game_state = %{character: %{id: 1}}

      result = AdminCommands.handle_delete_door_command("delete door", game_state)
      
      assert {["Invalid delete door command. Usage: delete door [direction]"], ^game_state} = result
    end
  end

  describe "command parsing" do
    test "parse_create_room_command handles various formats" do
      # Test valid formats
      assert {:ok, "north"} = AdminCommands.parse_create_room_command("create room north")
      assert {:ok, "south"} = AdminCommands.parse_create_room_command("create room \"south\"")
      assert {:ok, "east"} = AdminCommands.parse_create_room_command("CREATE ROOM EAST")
      assert {:ok, "west"} = AdminCommands.parse_create_room_command("create room 'west'")
      assert {:ok, "up"} = AdminCommands.parse_create_room_command("create room up   ")

      # Test invalid formats
      assert :error = AdminCommands.parse_create_room_command("create room")
      assert :error = AdminCommands.parse_create_room_command("create north")
      assert :error = AdminCommands.parse_create_room_command("room north")
      assert :error = AdminCommands.parse_create_room_command("create room north south")
    end

    test "parse_delete_room_command handles various formats" do
      # Test valid formats
      assert {:ok, "north"} = AdminCommands.parse_delete_room_command("delete room north")
      assert {:ok, "south"} = AdminCommands.parse_delete_room_command("delete room \"south\"")
      assert {:ok, "east"} = AdminCommands.parse_delete_room_command("DELETE ROOM EAST")

      # Test invalid formats
      assert :error = AdminCommands.parse_delete_room_command("delete room")
      assert :error = AdminCommands.parse_delete_room_command("delete north")
      assert :error = AdminCommands.parse_delete_room_command("room north")
    end

    test "parse_create_door_command handles various formats" do
      # Test valid formats
      assert {:ok, "north"} = AdminCommands.parse_create_door_command("create door north")
      assert {:ok, "south"} = AdminCommands.parse_create_door_command("create door \"south\"")
      assert {:ok, "east"} = AdminCommands.parse_create_door_command("CREATE DOOR EAST")

      # Test invalid formats
      assert :error = AdminCommands.parse_create_door_command("create door")
      assert :error = AdminCommands.parse_create_door_command("create north")
      assert :error = AdminCommands.parse_create_door_command("door north")
    end

    test "parse_delete_door_command handles various formats" do
      # Test valid formats
      assert {:ok, "north"} = AdminCommands.parse_delete_door_command("delete door north")
      assert {:ok, "south"} = AdminCommands.parse_delete_door_command("delete door \"south\"")
      assert {:ok, "east"} = AdminCommands.parse_delete_door_command("DELETE DOOR EAST")

      # Test invalid formats
      assert :error = AdminCommands.parse_delete_door_command("delete door")
      assert :error = AdminCommands.parse_delete_door_command("delete north")
      assert :error = AdminCommands.parse_delete_door_command("door north")
    end
  end
end
