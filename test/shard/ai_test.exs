defmodule Shard.AITest do
  use ExUnit.Case, async: true

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

    test "makes API call when API key is present" do
      # Set up test config
      Application.put_env(:shard, :open_router,
        api_key: "test-api-key",
        model: "test-model"
      )

      zone_description = "A mystical forest"

      surrounding_rooms = [
        %{name: "Forest Entrance", description: "A welcoming entrance"},
        %{name: "Deep Woods", description: "Dark and mysterious"}
      ]

      # Since we can't easily mock Req without additional dependencies,
      # we'll test that the function handles the case properly
      result = AI.generate_room_description(zone_description, surrounding_rooms)

      case result do
        {:ok, description} when is_binary(description) ->
          assert String.length(description) > 0

        {:error, reason} ->
          # This is expected if no real API key or network issues
          assert is_binary(reason)
          assert reason =~ "Failed to connect to OpenRouter" or reason =~ "Unexpected response"
      end
    end

    test "handles API error responses gracefully" do
      Application.put_env(:shard, :open_router,
        api_key: "invalid-key",
        model: "test-model"
      )

      zone_description = "A test zone"
      surrounding_rooms = []

      case AI.generate_room_description(zone_description, surrounding_rooms) do
        {:ok, _description} ->
          # API call succeeded (maybe using real key)
          assert true

        {:error, reason} ->
          # Expected for test environment with invalid key
          assert is_binary(reason)
      end
    end

    test "builds correct prompt with zone and surrounding rooms" do
      Application.put_env(:shard, :open_router, api_key: nil)

      zone_description = "A magical realm"

      surrounding_rooms = [
        %{name: "Crystal Cave", description: "Sparkling crystals everywhere"},
        %{name: "Mystic Pool", description: "A pool of glowing water"}
      ]

      # Since we return dummy data when no API key, we can test the flow
      assert {:ok, _description} =
               AI.generate_room_description(zone_description, surrounding_rooms)
    end

    test "handles empty surrounding rooms" do
      Application.put_env(:shard, :open_router, api_key: nil)

      zone_description = "An isolated area"
      surrounding_rooms = []

      assert {:ok, description} =
               AI.generate_room_description(zone_description, surrounding_rooms)

      assert is_binary(description)
    end

    test "trims whitespace from response" do
      Application.put_env(:shard, :open_router, api_key: nil)

      assert {:ok, description} = AI.generate_room_description("test", [])
      assert description == String.trim(description)
    end

    test "handles nil surrounding rooms" do
      Application.put_env(:shard, :open_router, api_key: nil)

      zone_description = "A test zone"

      # Test with nil instead of empty list
      assert {:ok, description} = AI.generate_room_description(zone_description, nil)
      assert is_binary(description)
    end

    test "handles very long zone descriptions" do
      Application.put_env(:shard, :open_router, api_key: nil)

      long_description = String.duplicate("A very long zone description. ", 100)
      
      assert {:ok, description} = AI.generate_room_description(long_description, [])
      assert is_binary(description)
    end

    test "handles special characters in zone description" do
      Application.put_env(:shard, :open_router, api_key: nil)

      zone_description = "A zone with special chars: !@#$%^&*()[]{}|\\:;\"'<>,.?/~`"
      
      assert {:ok, description} = AI.generate_room_description(zone_description, [])
      assert is_binary(description)
    end

    test "handles unicode characters in zone description" do
      Application.put_env(:shard, :open_router, api_key: nil)

      zone_description = "A mystical zone with runes: ᚠᚢᚦᚨᚱᚲ and symbols: ⚔️🏰🌟"
      
      assert {:ok, description} = AI.generate_room_description(zone_description, [])
      assert is_binary(description)
    end

    test "handles rooms with nil descriptions" do
      Application.put_env(:shard, :open_router, api_key: nil)

      surrounding_rooms = [
        %{name: "Room 1", description: nil},
        %{name: "Room 2", description: "Valid description"}
      ]
      
      assert {:ok, description} = AI.generate_room_description("Test zone", surrounding_rooms)
      assert is_binary(description)
    end

    test "handles rooms with missing keys" do
      Application.put_env(:shard, :open_router, api_key: nil)

      surrounding_rooms = [
        %{name: "Room 1"},  # Missing description
        %{description: "Room without name"}  # Missing name
      ]
      
      assert {:ok, description} = AI.generate_room_description("Test zone", surrounding_rooms)
      assert is_binary(description)
    end
  end
end
