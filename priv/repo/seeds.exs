# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Shard.Repo.insert!(%Shard.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Add a 3x3 grid of rooms to the map
alias Shard.Repo
alias Shard.Map.{Room, Door}

# Check if rooms already exist to avoid duplication
room_count = Repo.aggregate(Room, :count, :id)

if room_count == 0 do
  # Create a 3x3 grid of rooms (9 total)
  rooms = 
    for x <- 0..2, y <- 0..2 do
      %{
        name: "Room (#{x},#{y})",
        description: "A room in the grid at coordinates (#{x},#{y})",
        x_coordinate: x,
        y_coordinate: y,
        is_public: true,
        room_type: "standard"
      }
    end
    |> Enum.map(&Repo.insert!(%Room{} |> Room.changeset(&1)))

  # Create doors between adjacent rooms
  # Connect horizontally (east-west)
  for x <- 0..1, y <- 0..2 do
    from_room = Enum.find(rooms, &(&1.x_coordinate == x && &1.y_coordinate == y))
    to_room = Enum.find(rooms, &(&1.x_coordinate == x + 1 && &1.y_coordinate == y))
    
    # Door from left room to right room (east)
    Repo.insert!(%Door{} |> Door.changeset(%{
      from_room_id: from_room.id,
      to_room_id: to_room.id,
      direction: "east",
      door_type: "standard",
      is_locked: false,
      properties: %{"state" => "open"}
    }))
    
    # Door from right room to left room (west)
    Repo.insert!(%Door{} |> Door.changeset(%{
      from_room_id: to_room.id,
      to_room_id: from_room.id,
      direction: "west",
      door_type: "standard",
      is_locked: false,
      properties: %{"state" => "open"}
    }))
  end

  # Connect vertically (north-south)
  for x <- 0..2, y <- 0..1 do
    from_room = Enum.find(rooms, &(&1.x_coordinate == x && &1.y_coordinate == y))
    to_room = Enum.find(rooms, &(&1.x_coordinate == x && &1.y_coordinate == y + 1))
    
    # Door from bottom room to top room (north)
    Repo.insert!(%Door{} |> Door.changeset(%{
      from_room_id: from_room.id,
      to_room_id: to_room.id,
      direction: "north",
      door_type: "standard",
      is_locked: false,
      properties: %{"state" => "open"}
    }))
    
    # Door from top room to bottom room (south)
    Repo.insert!(%Door{} |> Door.changeset(%{
      from_room_id: to_room.id,
      to_room_id: from_room.id,
      direction: "south",
      door_type: "standard",
      is_locked: false,
      properties: %{"state" => "open"}
    }))
  end

  IO.puts("Created 3x3 grid of rooms with connecting doors")
else
  IO.puts("Rooms already exist in the database, skipping grid creation")
end

# --- Monsters seed (idempotent) ---
alias Shard.Repo
alias Shard.World.Monster
import Ecto.Query, only: [from: 2]

mk_monster = fn attrs ->
  slug = attrs[:slug] || attrs["slug"]
  case Repo.one(from m in Monster, where: m.slug == ^slug) do
    nil -> %Monster{} |> Monster.changeset(attrs) |> Repo.insert()
    _ -> {:ok, :exists}
  end
end

mk_monster.(%{name: "Slime", slug: "slime", species: "ooze", description: "Basic blob.",
  level: 1, hp: 12, attack: 2, defense: 0, speed: 1, xp_drop: 3, element: :neutral, ai: :passive, spawn_rate: 30})

mk_monster.(%{name: "Fire Imp", slug: "fire-imp", species: "imp", description: "Loves sparks.",
  level: 3, hp: 18, attack: 4, defense: 1, speed: 2, xp_drop: 7, element: :fire, ai: :aggressive, spawn_rate: 15})

mk_monster.(%{name: "Stone Turtle", slug: "stone-turtle", species: "turtle", description: "Tanky but slow.",
  level: 5, hp: 40, attack: 3, defense: 6, speed: 1, xp_drop: 12, element: :earth, ai: :defensive, spawn_rate: 10})
