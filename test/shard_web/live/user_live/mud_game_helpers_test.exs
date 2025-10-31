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
end
