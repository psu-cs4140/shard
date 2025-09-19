alias Shard.Repo
alias Shard.World.{Room, Exit}

get_or_create_room = fn attrs ->
  Repo.get_by(Room, slug: attrs.slug) || Repo.insert!(struct(Room, attrs))
end

fields = Exit.__schema__(:fields)

from_field =
  cond do
    :from_id in fields -> :from_id
    :from_room_id in fields -> :from_room_id
    :source_id in fields -> :source_id
    :src_id in fields -> :src_id
    :from in fields -> :from
    true -> raise "Exit schema missing origin FK"
  end

to_field =
  cond do
    :to_id in fields -> :to_id
    :to_room_id in fields -> :to_room_id
    :dest_id in fields -> :dest_id
    :destination_id in fields -> :destination_id
    :to in fields -> :to
    true -> raise "Exit schema missing destination FK"
  end

dir_field =
  cond do
    :dir in fields -> :dir
    :direction in fields -> :direction
    true -> raise "Exit schema missing direction field"
  end

get_or_create_exit = fn from_id, dir, to_id ->
  where = [{from_field, from_id}, {dir_field, dir}]

  case Repo.get_by(Exit, where) do
    nil ->
      attrs = [{from_field, from_id}, {to_field, to_id}, {dir_field, dir}] |> Enum.into(%{})
      Repo.insert!(struct(Exit, attrs))

    e ->
      e
  end
end

start =
  get_or_create_room.(%{
    slug: "start",
    name: "Start Room",
    x: 0,
    y: 0,
    description: "You are here."
  })

north =
  get_or_create_room.(%{slug: "north", name: "North", x: 0, y: 1, description: "Chilly breeze."})

east = get_or_create_room.(%{slug: "east", name: "East", x: 1, y: 0, description: "Dry heat."})

get_or_create_exit.(start.id, "n", north.id)
get_or_create_exit.(north.id, "s", start.id)
get_or_create_exit.(start.id, "e", east.id)
get_or_create_exit.(east.id, "w", start.id)

alias Shard.Repo
alias Shard.World.{Monster, Room}

get_or_create_room = fn slug ->
  Repo.get_by(Room, slug: slug)
end

mk = fn attrs ->
  Repo.get_by(Monster, slug: attrs.slug) || Repo.insert!(struct(Monster, attrs))
end

start_room = get_or_create_room.("start")

mk.(%{
  name: "Slime",
  slug: "slime",
  species: "ooze",
  description: "Basic blob.",
  level: 1,
  hp: 12,
  attack: 2,
  defense: 0,
  speed: 1,
  xp_drop: 3,
  element: :neutral,
  ai: :passive,
  spawn_rate: 30,
  room_id: start_room && start_room.id
})

mk.(%{
  name: "Fire Imp",
  slug: "fire-imp",
  species: "imp",
  description: "Loves sparks.",
  level: 3,
  hp: 18,
  attack: 4,
  defense: 1,
  speed: 2,
  xp_drop: 7,
  element: :fire,
  ai: :aggressive,
  spawn_rate: 15,
  room_id: start_room && start_room.id
})

<<<<<<< HEAD
mk.(%{name: "Stone Turtle", slug: "stone-turtle", species: "turtle", description: "Tanky but slow.",
      level: 5, hp: 40, attack: 3, defense: 6, speed: 1, xp_drop: 12,
      element: :earth, ai: :defensive, spawn_rate: 10})

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

mk_monster.(%{
  name: "Slime",
  slug: "slime",
  species: "ooze",
  description: "Basic blob.",
  level: 1, hp: 12, attack: 2, defense: 0, speed: 1, xp_drop: 3,
  element: :neutral, ai: :passive, spawn_rate: 30
})

mk_monster.(%{
  name: "Fire Imp",
  slug: "fire-imp",
  species: "imp",
  description: "Loves sparks.",
  level: 3, hp: 18, attack: 4, defense: 1, speed: 2, xp_drop: 7,
  element: :fire, ai: :aggressive, spawn_rate: 15
})

mk_monster.(%{
=======
mk.(%{
>>>>>>> 2a37033 (chore: format)
  name: "Stone Turtle",
  slug: "stone-turtle",
  species: "turtle",
  description: "Tanky but slow.",
<<<<<<< HEAD
  level: 5, hp: 40, attack: 3, defense: 6, speed: 1, xp_drop: 12,
  element: :earth, ai: :defensive, spawn_rate: 10
=======
  level: 5,
  hp: 40,
  attack: 3,
  defense: 6,
  speed: 1,
  xp_drop: 12,
  element: :earth,
  ai: :defensive,
  spawn_rate: 10
>>>>>>> 2a37033 (chore: format)
})

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

mk_monster.(%{
  name: "Slime",
  slug: "slime",
  species: "ooze",
  description: "Basic blob.",
  level: 1, hp: 12, attack: 2, defense: 0, speed: 1, xp_drop: 3,
  element: :neutral, ai: :passive, spawn_rate: 30
})

mk_monster.(%{
  name: "Fire Imp",
  slug: "fire-imp",
  species: "imp",
  description: "Loves sparks.",
  level: 3, hp: 18, attack: 4, defense: 1, speed: 2, xp_drop: 7,
  element: :fire, ai: :aggressive, spawn_rate: 15
})

mk_monster.(%{
  name: "Stone Turtle",
  slug: "stone-turtle",
  species: "turtle",
  description: "Tanky but slow.",
  level: 5, hp: 40, attack: 3, defense: 6, speed: 1, xp_drop: 12,
  element: :earth, ai: :defensive, spawn_rate: 10
})
