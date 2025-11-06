defmodule Shard.Repo.Migrations.SeedVampireCastle do
  use Ecto.Migration

  def change do
    execute(&seed_vampire_castle_up/0, &seed_vampire_castle_down/0)
  end

  defp seed_vampire_castle_up do
    alias Shard.Repo
    alias Shard.Map
    alias Shard.Map.{Zone, Room, Door}

    IO.puts("Creating Vampire Castle...")

    # Clean up any existing data first
    seed_vampire_castle_down()

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

    IO.puts("""

    ✓ Vampire Castle successfully seeded!

    Created 1 zone:
    - Vampire Castle (4x4 grid, coordinates 0,0 to 3,3)
    """)
  end

  defp seed_vampire_castle_down do
    alias Shard.Repo
    alias Shard.Map.{Zone, Room, Door}

    IO.puts("Removing Vampire Castle...")

    # Delete zone by slug (this will cascade to rooms and doors)
    case Repo.get_by(Zone, slug: "vampire-castle") do
      nil ->
        IO.puts("Zone vampire-castle not found")

      zone ->
        Repo.delete!(zone)
        IO.puts("Deleted zone: #{zone.name}")
    end

    IO.puts("✓ Vampire Castle rollback completed!")
  end
end
