defmodule Shard.AITest do
  use Shard.DataCase

  alias Shard.AI

  describe "generate_room_description/2" do
    test "returns dummy response when API key is missing" do
      # Temporarily remove the API key
      original_config = Application.get_env(:shard, :open_router)
      Application.put_env(:shard, :open_router, api_key: nil)

      zone_description = "A dark forest"
      surrounding_rooms = []

      assert {:ok, description} =
               AI.generate_room_description(zone_description, surrounding_rooms)

      assert description == "A test room description generated without an API call."

      # Restore original config
      if original_config do
        Application.put_env(:shard, :open_router, original_config)
      else
        Application.delete_env(:shard, :open_router)
      end
    end

    test "handles empty surrounding rooms" do
      Application.put_env(:shard, :open_router, api_key: nil)

      zone_description = "An isolated area"
      surrounding_rooms = []

      assert {:ok, description} =
               AI.generate_room_description(zone_description, surrounding_rooms)

      assert is_binary(description)
    end

    test "handles nil surrounding rooms" do
      Application.put_env(:shard, :open_router, api_key: nil)

      zone_description = "A test zone"

      # Test with nil instead of empty list
      assert {:ok, description} = AI.generate_room_description(zone_description, nil)
      assert is_binary(description)
    end
  end
end
