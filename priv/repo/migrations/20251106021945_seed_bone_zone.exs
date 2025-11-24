defmodule Shard.Repo.Migrations.SeedBoneZone do
  use Ecto.Migration

  def change do
    execute(&seed_bone_zone_up/0, &seed_bone_zone_down/0)
  end

  defp seed_bone_zone_up do
    alias Shard.Repo
    alias Shard.Map
    alias Shard.Map.Zone

    IO.puts("Creating Bone Zone and Elven Forest...")

    # Clean up any existing data first
    seed_bone_zone_down()

    # Create Bone Zone
    {:ok, bone_zone} =
      Map.create_zone(%{
        name: "Beginner Bone Zone",
        slug: "bone-zone",
        description:
          "A quiet cavern lined with old bones — eerie but safe enough for a first adventure.",
        zone_type: "dungeon",
        min_level: 1,
        max_level: 5,
        is_public: true,
        is_active: true,
        display_order: 1,
        properties: %{
          "has_tutorial_npcs" => true,
          "respawn_point" => true,
          "starting_room" => %{"x" => 2, "y" => 5, "z" => 0}
        }
      })

    IO.puts("Created Beginner Bone Zone")

    # Create Beginner Bone Zone rooms using the specified coordinates

    bone_room_specs = [
      {0, 3, "Spider Dungeon", "dungeon"},
      {0, 4, "Hallway1", "standard"},
      {1, 4, "Hallway2", "standard"},
      {2, 0, "Bone Yard", "standard"},
      {2, 1, "Hallway3", "standard"},
      {2, 2, "Hallway4", "standard"},
      {2, 3, "Hallway5", "standard"},
      {2, 4, "Hallway6", "standard"},
      {2, 5, "Tomb", "standard"},
      {3, 4, "Hallway7", "standard"},
      {4, 4, "Hallway8", "standard"},
      {4, 5, "Hallway9", "standard"},
      {5, 0, "Hallway10", "standard"},
      {5, 1, "Hallway11", "standard"},
      {5, 2, "Hallway12", "standard"},
      {5, 3, "Hallway13", "standard"},
      {5, 4, "Hallway14", "standard"},
      {5, 5, "Grand Statue", "standard"},
      {6, 0, "Treasure Room", "treasure_room"},
      {7, 0, "Exit", "standard"},
      {6, 3, "Hallway16", "standard"},
      {7, 3, "Barracks", "standard"}
    ]

    bone_rooms =
      Enum.map(bone_room_specs, fn {x, y, room_name, room_type} ->
        case Map.create_room(%{
               name: "#{room_name} (Bone Zone)",
               description: "#{room_name} in the Bone Zone",
               zone_id: bone_zone.id,
               x_coordinate: x,
               y_coordinate: y,
               z_coordinate: 0,
               is_public: true,
               room_type: room_type
             }) do
          {:ok, room} ->
            room

          {:error, changeset} ->
            IO.puts("Failed to create room #{room_name}: #{inspect(changeset.errors)}")
            raise "Room creation failed for #{room_name}"
        end
      end)

    IO.puts("Created #{length(bone_rooms)} bone rooms")

    # Create Elven Forest Zone
    {:ok, forest_zone} =
      Map.create_zone(%{
        name: "Elven Forest",
        slug: "elven-forest",
        description:
          "An ancient forest inhabited by elves. The trees whisper secrets of old magic.",
        zone_type: "wilderness",
        min_level: 5,
        max_level: 15,
        is_public: true,
        is_active: true,
        display_order: 3,
        properties: %{
          "atmosphere" => "mystical",
          "has_merchants" => true,
          "fauna" => ["deer", "birds", "magical creatures"]
        }
      })

    IO.puts("Created Elven Forest zone")

    # Create forest rooms (3x3 grid, also reusing coordinates)
    forest_rooms =
      for x <- 0..2, y <- 0..2 do
        room_name =
          case {x, y} do
            {0, 0} -> "Forest Entrance"
            {1, 0} -> "Winding Path"
            {2, 0} -> "Ancient Oak"
            {0, 1} -> "Moonlight Glade"
            {1, 1} -> "Elven Village Center"
            {2, 1} -> "Merchant Quarter"
            {0, 2} -> "Sacred Grove"
            {1, 2} -> "Treehouse District"
            {2, 2} -> "Elder's Sanctuary"
          end

        room_type =
          case {x, y} do
            {1, 1} -> "safe_zone"
            {2, 1} -> "shop"
            _ -> "standard"
          end

        case Map.create_room(%{
               name: "#{room_name} (Elven Forest)",
               description: "#{room_name} in the Elven Forest",
               zone_id: forest_zone.id,
               x_coordinate: x,
               y_coordinate: y,
               z_coordinate: 0,
               is_public: true,
               room_type: room_type
             }) do
          {:ok, room} ->
            room

          {:error, changeset} ->
            IO.puts("Failed to create forest room #{room_name}: #{inspect(changeset.errors)}")
            raise "Room creation failed for #{room_name}"
        end
      end

    IO.puts("Created #{length(forest_rooms)} elven forest rooms")

    # Create doors for bone zone based on actual room coordinates
    bone_door_connections = [
      # Connect Spider Dungeon (0,3) to Hallway1 (0,4)
      {{0, 3}, {0, 4}, "south"},
      # Connect Hallway1 (0,4) to Hallway2 (1,4)
      {{0, 4}, {1, 4}, "east"},
      # Connect Hallway2 (1,4) to Hallway6 (2,4)
      {{1, 4}, {2, 4}, "east"},
      # Connect Bone Yard (2,0) to Hallway3 (2,1)
      {{2, 0}, {2, 1}, "south"},
      # Connect Hallway3 (2,1) to Hallway4 (2,2)
      {{2, 1}, {2, 2}, "south"},
      # Connect Hallway4 (2,2) to Hallway5 (2,3)
      {{2, 2}, {2, 3}, "south"},
      # Connect Hallway5 (2,3) to Hallway6 (2,4)
      {{2, 3}, {2, 4}, "south"},
      # Connect Hallway6 (2,4) to Tomb (2,5)
      {{2, 4}, {2, 5}, "south"},
      # {{2, 5}, {2, 4}, "south"},
      # Connect Hallway6 (2,4) to Hallway7 (3,4)
      {{2, 4}, {3, 4}, "east"},
      # Connect Hallway7 (3,4) to Hallway8 (4,4)
      {{3, 4}, {4, 4}, "east"},
      # Connect Hallway8 (4,4) to Hallway9 (4,5)
      {{4, 4}, {4, 5}, "south"},
      # Connect Hallway8 (4,4) to Hallway14 (5,4)
      {{4, 4}, {5, 4}, "east"},
      # Connect Hallway10 (5,0) to Hallway11 (5,1)
      {{5, 0}, {5, 1}, "south"},
      # Connect Hallway11 (5,1) to Hallway12 (5,2)
      {{5, 1}, {5, 2}, "south"},
      # Connect Hallway12 (5,2) to Hallway13 (5,3)
      {{5, 2}, {5, 3}, "south"},
      # Connect Hallway13 (5,3) to Hallway14 (5,4)
      {{5, 3}, {5, 4}, "south"},
      # Connect Hallway14 (5,4) to Grand Statue (5,5)
      {{5, 4}, {5, 5}, "south"},
      # Connect Hallway9 (4,5) to Grand Statue (5,5)
      {{4, 5}, {5, 5}, "east"},
      # Connect Treasure Room (6,0) to Exit (7,0)
      {{6, 0}, {7, 0}, "east"},
      # Connect Hallway16 (6,3) to Barracks (7,3)
      {{6, 3}, {7, 3}, "east"},
      # Connect Hallway10 (5,0) to Treasure Room (6,0)
      {{5, 0}, {6, 0}, "east"},
      # Connect Hallway13 (5,3) to Hallway16 (6,3)
      {{5, 3}, {6, 3}, "east"}
    ]

    Enum.each(bone_door_connections, fn {{from_x, from_y}, {to_x, to_y}, direction} ->
      from_room = Enum.find(bone_rooms, &(&1.x_coordinate == from_x && &1.y_coordinate == from_y))
      to_room = Enum.find(bone_rooms, &(&1.x_coordinate == to_x && &1.y_coordinate == to_y))

      if from_room && to_room do
        # Determine if this door should be locked
        is_locked =
          (from_x == 2 && from_y == 3 && to_x == 2 && to_y == 4) ||
            (from_x == 5 && from_y == 0 && to_x == 5 && to_y == 1)

        door_type = if is_locked, do: "locked_gate", else: "standard"

        key_required =
          cond do
            from_x == 2 && from_y == 3 && to_x == 2 && to_y == 4 -> "Bone Zone Key"
            from_x == 5 && from_y == 0 && to_x == 5 && to_y == 1 -> "Treasure Room Key"
            true -> nil
          end

        # Create door (Map.create_door automatically creates the return door)
        case Map.create_door(%{
               from_room_id: from_room.id,
               to_room_id: to_room.id,
               direction: direction,
               door_type: door_type,
               is_locked: is_locked,
               key_required: key_required
             }) do
          {:ok, _door} ->
            :ok

          {:error, changeset} ->
            IO.puts("Failed to create door #{direction}: #{inspect(changeset.errors)}")
            raise "Door creation failed"
        end
      end
    end)

    IO.puts("Created doors for bone zone")

    # Create doors for elven forest
    for x <- 0..1, y <- 0..2 do
      from_room = Enum.find(forest_rooms, &(&1.x_coordinate == x && &1.y_coordinate == y))
      to_room = Enum.find(forest_rooms, &(&1.x_coordinate == x + 1 && &1.y_coordinate == y))

      if from_room && to_room do
        # Create east door (Map.create_door automatically creates the return door)
        case Map.create_door(%{
               from_room_id: from_room.id,
               to_room_id: to_room.id,
               direction: "east",
               door_type: "standard",
               is_locked: false
             }) do
          {:ok, _door} ->
            :ok

          {:error, changeset} ->
            IO.puts("Failed to create forest east door (#{x},#{y}): #{inspect(changeset.errors)}")
            raise "Door creation failed"
        end
      end
    end

    for x <- 0..2, y <- 0..1 do
      from_room = Enum.find(forest_rooms, &(&1.x_coordinate == x && &1.y_coordinate == y))
      to_room = Enum.find(forest_rooms, &(&1.x_coordinate == x && &1.y_coordinate == y + 1))

      if from_room && to_room do
        # Create south door (Map.create_door automatically creates the return door)
        case Map.create_door(%{
               from_room_id: from_room.id,
               to_room_id: to_room.id,
               direction: "south",
               door_type: "standard",
               is_locked: false
             }) do
          {:ok, _door} ->
            :ok

          {:error, changeset} ->
            IO.puts(
              "Failed to create forest south door (#{x},#{y}): #{inspect(changeset.errors)}"
            )

            raise "Door creation failed"
        end
      end
    end

    IO.puts("Created doors for elven forest")

    IO.puts("""

    ✓ Bone Zone and Elven Forest successfully seeded!

    Created 2 zones:
    - Beginner Bone Zone (complex layout with locked doors)
    - Elven Forest (3x3 grid, coordinates 0,0 to 2,2)
    """)
  end

  defp seed_bone_zone_down do
    alias Shard.Repo
    alias Shard.Map.Zone

    IO.puts("Removing Bone Zone and Elven Forest...")

    # Delete zones by slug (this will cascade to rooms and doors)
    ["bone-zone", "elven-forest"]
    |> Enum.each(fn slug ->
      case Repo.get_by(Zone, slug: slug) do
        nil ->
          IO.puts("Zone #{slug} not found")

        zone ->
          Repo.delete!(zone)
          IO.puts("Deleted zone: #{zone.name}")
      end
    end)

    IO.puts("✓ Bone Zone and Elven Forest rollback completed!")
  end
end
