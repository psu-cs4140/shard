defmodule ShardWeb.UserLive.MudGameHelpersTest do
  use ExUnit.Case, async: true

  alias ShardWeb.UserLive.MudGameHelpers

  describe "posn_to_room_channel/1" do
    test "converts position coordinates to room channel string" do
      assert MudGameHelpers.posn_to_room_channel({0, 0}) == "room:0,0"
      assert MudGameHelpers.posn_to_room_channel({5, -3}) == "room:5,-3"
      assert MudGameHelpers.posn_to_room_channel({-10, 15}) == "room:-10,15"
    end
  end

  describe "add_message/2" do
    test "adds message to terminal output with empty line" do
      terminal_state = %{output: ["Welcome!", "Type help for commands"]}
      
      result = MudGameHelpers.add_message(terminal_state, "You picked up a sword")
      
      expected_output = ["Welcome!", "Type help for commands", "You picked up a sword", ""]
      assert result.output == expected_output
    end
  end
end
