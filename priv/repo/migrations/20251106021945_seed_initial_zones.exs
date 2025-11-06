defmodule Shard.Repo.Migrations.SeedInitialZones do
  use Ecto.Migration

  def change do
    execute(&seed_zones_up/0, &seed_zones_down/0)
  end

  defp seed_zones_up do
    alias Shard.Repo
    alias Shard.Map
    alias Shard.Map.{Zone, Room, Door}

    IO.puts("Creating zones and their rooms...")

    # Clean up any existing data first
    seed_zones_down()

    # Create Tutorial Zone
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

    # Create Vampire Castle Zone
    {:ok, vampire_zone} =
      Map.create_zone(%{
        name: "Vampire Castle",
        slug: "vampire-castle",
        description:
          "A dark and foreboding castle ruled by ancient vampires. Danger lurks in every shadow.",
        zone_type: "dungeon",
        min_level: 10,
        max_level: 20,
        is_public: true,
        is_active: true,
        display_order: 2,
        properties: %{
          "atmosphere" => "dark",
          "has_boss" => true,
          "recommended_party_size" => 4
        }
      })

    IO.puts("Created Vampire Castle zone")

    # Create vampire castle rooms (4x4 grid with same starting coordinates as tutorial)
    vampire_rooms =
      for x <- 0..3, y <- 0..3 do
        room_name =
          case {x, y} do
            {0, 0} -> "Castle Entrance"
            {1, 0} -> "Grand Foyer"
            {2, 0} -> "Armory"
            {3, 0} -> "Guard Tower"
            {0, 1} -> "West Wing Corridor"
            {1, 1} -> "Throne Room"
            {2, 1} -> "East Wing Corridor"
            {3, 1} -> "Library"
            {0, 2} -> "Dungeon Stairs"
            {1, 2} -> "Torture Chamber"
            {2, 2} -> "Prison Cells"
            {3, 2} -> "Secret Passage"
            {0, 3} -> "Crypt"
            {1, 3} -> "Vampire Lord's Chamber"
            {2, 3} -> "Treasure Room"
            {3, 3} -> "Escape Route"
          end

        room_type =
          case {x, y} do
            {2, 3} -> "treasure_room"
            {1, 3} -> "dungeon"
            _ -> "standard"
          end

        case Map.create_room(%{
               name: "#{room_name} (Vampire Castle)",
               description: "#{room_name} in the Vampire Castle",
               zone_id: vampire_zone.id,
               x_coordinate: x,
               y_coordinate: y,
               z_coordinate: 0,
               is_public: true,
               room_type: room_type
             }) do
          {:ok, room} ->
            room

          {:error, changeset} ->
            IO.puts("Failed to create vampire room #{room_name}: #{inspect(changeset.errors)}")
            raise "Room creation failed for #{room_name}"
        end
      end

    IO.puts("Created #{length(vampire_rooms)} vampire castle rooms")

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
            from_x == 2 && from_y == 3 && to_x == 2 && to_y == 4 -> "Tomb Key"
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

    IO.puts("Created doors for tutorial zone")

    # Create doors for vampire castle (4x4 grid) - East/West connections
    IO.puts("Creating vampire castle east/west doors...")

    for x <- 0..2, y <- 0..3 do
      from_room = Enum.find(vampire_rooms, &(&1.x_coordinate == x && &1.y_coordinate == y))
      to_room = Enum.find(vampire_rooms, &(&1.x_coordinate == x + 1 && &1.y_coordinate == y))

      if from_room && to_room do
        IO.puts("Creating east door from (#{x},#{y}) to (#{x + 1},#{y})")
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
            IO.puts(
              "Failed to create vampire castle east door (#{x},#{y}) -> (#{x + 1},#{y}): #{inspect(changeset.errors)}"
            )

            raise "Door creation failed for east door at (#{x},#{y})"
        end
      end
    end

    # Create doors for vampire castle (4x4 grid) - North/South connections
    IO.puts("Creating vampire castle north/south doors...")

    for x <- 0..3, y <- 0..2 do
      from_room = Enum.find(vampire_rooms, &(&1.x_coordinate == x && &1.y_coordinate == y))
      to_room = Enum.find(vampire_rooms, &(&1.x_coordinate == x && &1.y_coordinate == y + 1))

      if from_room && to_room do
        # Lock the door to vampire lord's chamber
        is_locked = x == 1 && y == 2

        IO.puts("Creating south door from (#{x},#{y}) to (#{x},#{y + 1}) - locked: #{is_locked}")
        # Create south door (Map.create_door automatically creates the return door)
        case Map.create_door(%{
               from_room_id: from_room.id,
               to_room_id: to_room.id,
               direction: "south",
               door_type: if(is_locked, do: "locked_gate", else: "standard"),
               is_locked: is_locked,
               key_required: if(is_locked, do: "Vampire Lord's Key", else: nil)
             }) do
          {:ok, _door} ->
            :ok

          {:error, changeset} ->
            IO.puts(
              "Failed to create vampire castle south door (#{x},#{y}) -> (#{x},#{y + 1}): #{inspect(changeset.errors)}"
            )

            raise "Door creation failed for south door at (#{x},#{y})"
        end
      end
    end

    IO.puts("Created doors for vampire castle")

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

    ✓ Zone system successfully seeded!

    Created 3 zones:
    - Tutorial Area (3x3 grid, coordinates 0,0 to 2,2)
    - Vampire Castle (4x4 grid, coordinates 0,0 to 3,3)
    - Elven Forest (3x3 grid, coordinates 0,0 to 2,2)

    Notice: Multiple zones can now use the same coordinates!
    For example, all three zones have a room at (0,0).
    """)
  end

  defp seed_zones_down do
    alias Shard.Repo
    alias Shard.Map.{Zone, Room, Door}

    IO.puts("Removing seeded zones and their rooms...")

    # Delete zones by slug (this will cascade to rooms and doors)
    ["bone-zone", "vampire-castle", "elven-forest"]
    |> Enum.each(fn slug ->
      case Repo.get_by(Zone, slug: slug) do
        nil ->
          IO.puts("Zone #{slug} not found")

        zone ->
          Repo.delete!(zone)
          IO.puts("Deleted zone: #{zone.name}")
      end
    end)

    IO.puts("✓ Zone system rollback completed!")
  end
end
