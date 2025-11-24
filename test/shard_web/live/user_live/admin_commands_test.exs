defmodule ShardWeb.UserLive.AdminCommandsTest do
  use Shard.DataCase, async: true

  alias ShardWeb.UserLive.AdminCommands

  # Note: The handler tests that require AdminStick and AdminZoneEditor
  # are commented out since they depend on external modules that would
  # need proper mocking setup. The parsing tests below are self-contained.

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
