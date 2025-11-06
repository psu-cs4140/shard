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

    # Create Tutorial Zone
    {:ok, bone_zone} =
      Map.create_zone(%{
        name: "Beginner Bone Zone",
        slug: "bone-zone",
        description: "A quiet cavern lined with old bones — eerie but safe enough for a first adventure.",
        zone_type: "dungeon",
        min_level: 1,
        max_level: 5,
        is_public: true,
        is_active: true,
        display_order: 1,
        properties: %{
          "has_tutorial_npcs" => true,
          "respawn_point" => true
        }
      })

    IO.puts("Created Beginner Bone Zone")

    # Create Beginner Bone Zone rooms (3x3 grid)
   # bone_zone_rooms =
    #  for x <- 0..2, y <- 0..2 do
     #   {:ok, room} =
      #    Map.create_room(%{
       #     name: "Bone Zone (#{x},#{y})",
        #    description: "A training room in the tutorial area at coordinates (#{x},#{y})",
         #   zone_id: bone_zone.id,
          #  x_coordinate: x,
           # y_coordinate: y,
      #      z_coordinate: 0,
      #      is_public: true,
      #      room_type: "dungeon"
       #   })

      #  room
     # end

    bone_rooms =
      for x <- 0..7, y <- 0..5 do
        room_name =
          case {x, y} do
            {0, 0} -> " "
            {0, 1} -> " "
            {0, 2} -> " "
            {0, 3} -> "Spider Dungeon"
            {0, 4} -> "Hallway1"
            {0, 5} -> " "
            {1, 4} -> "Hallway2"
            {2, 0} -> "Bone Yard"
            {2, 1} -> "Hallway3"
            {2, 2} -> "Hallway4"
            {2, 3} -> "Hallway5"
            {2, 4} -> "Hallway6"
            {2, 5} -> "Tomb"
            {3, 4} -> "Hallway7"
            {4, 4} -> "Hallway8"
            {4, 5} -> "Hallway9"
            {5, 0} -> "Hallway10"
            {5, 1} -> "Hallway11"
            {5, 2} -> "Hallway12"
            {5, 3} -> "Hallway13"
            {5, 4} -> "Hallway14"
            {5, 5} -> "Grand Statue"
            {6, 0} -> "Treasure Room"
            {7, 0} -> "Exit"
            {6, 3} -> "Hallway16"
            {7, 3} -> "Barracks"
          end

        room_type =
          case {x, y} do
            {6, 0} -> "treasure_room"
            {0, 3} -> "dungeon"
            _ -> "standard"
          end

        {:ok, room} =
          Map.create_room(%{
            name: room_name,
            description: "#{room_name} in the Bone Zone",
            zone_id: bone_zone.id,
            x_coordinate: x,
            y_coordinate: y,
            z_coordinate: 0,
            is_public: true,
            room_type: room_type
          })

        room
      end

    IO.puts("Created #{length(bone_rooms)} bone rooms")

    # Create Vampire Castle Zone
    {:ok, vampire_zone} =
      Map.create_zone(%{
        name: "Vampire Castle",
        slug: "vampire-castle",
        description: "A dark and foreboding castle ruled by ancient vampires. Danger lurks in every shadow.",
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

        {:ok, room} =
          Map.create_room(%{
            name: room_name,
            description: "#{room_name} in the Vampire Castle",
            zone_id: vampire_zone.id,
            x_coordinate: x,
            y_coordinate: y,
            z_coordinate: 0,
            is_public: true,
            room_type: room_type
          })

        room
      end

    IO.puts("Created #{length(vampire_rooms)} vampire castle rooms")

    # Create Elven Forest Zone
    {:ok, forest_zone} =
      Map.create_zone(%{
        name: "Elven Forest",
        slug: "elven-forest",
        description: "An ancient forest inhabited by elves. The trees whisper secrets of old magic.",
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

        {:ok, room} =
          Map.create_room(%{
            name: room_name,
            description: "#{room_name} in the Elven Forest",
            zone_id: forest_zone.id,
            x_coordinate: x,
            y_coordinate: y,
            z_coordinate: 0,
            is_public: true,
            room_type: room_type
          })

        room
      end

    IO.puts("Created #{length(forest_rooms)} elven forest rooms")

    # Create doors for tutorial zone (connect horizontally and vertically)
    for x <- 0..1, y <- 0..2 do
      from_room = Enum.find(bone_rooms, &(&1.x_coordinate == x && &1.y_coordinate == y))
      to_room = Enum.find(bone_rooms, &(&1.x_coordinate == x + 1 && &1.y_coordinate == y))

      if from_room && to_room do
        Map.create_door(%{
          from_room_id: from_room.id,
          to_room_id: to_room.id,
          direction: "east",
          door_type: "standard",
          is_locked: false
        })
      end
    end

    for x <- 0..2, y <- 0..1 do
      from_room = Enum.find(bone_rooms, &(&1.x_coordinate == x && &1.y_coordinate == y))
      to_room = Enum.find(bone_rooms, &(&1.x_coordinate == x && &1.y_coordinate == y + 1))

      if from_room && to_room do
        Map.create_door(%{
          from_room_id: from_room.id,
          to_room_id: to_room.id,
          direction: "north",
          door_type: "standard",
          is_locked: false
        })
      end
    end

    IO.puts("Created doors for tutorial zone")

    # Create doors for vampire castle (4x4 grid)
    for x <- 0..2, y <- 0..3 do
      from_room = Enum.find(vampire_rooms, &(&1.x_coordinate == x && &1.y_coordinate == y))
      to_room = Enum.find(vampire_rooms, &(&1.x_coordinate == x + 1 && &1.y_coordinate == y))

      if from_room && to_room do
        Map.create_door(%{
          from_room_id: from_room.id,
          to_room_id: to_room.id,
          direction: "east",
          door_type: "standard",
          is_locked: false
        })
      end
    end

    for x <- 0..3, y <- 0..2 do
      from_room = Enum.find(vampire_rooms, &(&1.x_coordinate == x && &1.y_coordinate == y))
      to_room = Enum.find(vampire_rooms, &(&1.x_coordinate == x && &1.y_coordinate == y + 1))

      if from_room && to_room do
        # Lock the door to vampire lord's chamber
        is_locked = x == 1 && y == 2

        Map.create_door(%{
          from_room_id: from_room.id,
          to_room_id: to_room.id,
          direction: "north",
          door_type: if(is_locked, do: "locked_gate", else: "standard"),
          is_locked: is_locked,
          key_required: if(is_locked, do: "Vampire Lord's Key", else: nil)
        })
      end
    end

    IO.puts("Created doors for vampire castle")

    # Create doors for elven forest
    for x <- 0..1, y <- 0..2 do
      from_room = Enum.find(forest_rooms, &(&1.x_coordinate == x && &1.y_coordinate == y))
      to_room = Enum.find(forest_rooms, &(&1.x_coordinate == x + 1 && &1.y_coordinate == y))

      if from_room && to_room do
        Map.create_door(%{
          from_room_id: from_room.id,
          to_room_id: to_room.id,
          direction: "east",
          door_type: "standard",
          is_locked: false
        })
      end
    end

    for x <- 0..2, y <- 0..1 do
      from_room = Enum.find(forest_rooms, &(&1.x_coordinate == x && &1.y_coordinate == y))
      to_room = Enum.find(forest_rooms, &(&1.x_coordinate == x && &1.y_coordinate == y + 1))

      if from_room && to_room do
        Map.create_door(%{
          from_room_id: from_room.id,
          to_room_id: to_room.id,
          direction: "north",
          door_type: "standard",
          is_locked: false
        })
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
    ["tutorial-area", "vampire-castle", "elven-forest"]
    |> Enum.each(fn slug ->
      case Repo.get_by(Zone, slug: slug) do
        nil -> IO.puts("Zone #{slug} not found")
        zone -> 
          Repo.delete!(zone)
          IO.puts("Deleted zone: #{zone.name}")
      end
    end)

    IO.puts("✓ Zone system rollback completed!")
  end
end
