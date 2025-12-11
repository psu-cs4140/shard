defmodule Shard.Map.DoorTest do
  use Shard.DataCase

  alias Shard.Map.Door

  describe "opposite_direction/1" do
    test "returns correct opposite directions" do
      assert Door.opposite_direction("north") == "south"
      assert Door.opposite_direction("south") == "north"
      assert Door.opposite_direction("east") == "west"
      assert Door.opposite_direction("west") == "east"
      assert Door.opposite_direction("up") == "down"
      assert Door.opposite_direction("down") == "up"
      assert Door.opposite_direction("northeast") == "southwest"
      assert Door.opposite_direction("northwest") == "southeast"
      assert Door.opposite_direction("southeast") == "northwest"
      assert Door.opposite_direction("southwest") == "northeast"
    end

    test "returns same direction for unknown directions" do
      assert Door.opposite_direction("unknown") == "unknown"
      assert Door.opposite_direction("") == ""
    end
  end
end
