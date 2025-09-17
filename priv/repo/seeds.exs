alias Shard.Repo
alias World.{Room, Exit}

Repo.delete_all(Exit)
Repo.delete_all(Room)

r0 = Repo.insert!(%Room{name: "Spawn", slug: "spawn", description: "Start here.", x: 0, y: 0})
r1 = Repo.insert!(%Room{name: "North", slug: "north", description: "Chilly breeze.", x: 0, y: 1})
r2 = Repo.insert!(%Room{name: "East", slug: "east", description: "Sun in your eyes.", x: 1, y: 0})

Repo.insert!(%Exit{dir: "n", from_room_id: r0.id, to_room_id: r1.id})
Repo.insert!(%Exit{dir: "s", from_room_id: r1.id, to_room_id: r0.id})
Repo.insert!(%Exit{dir: "e", from_room_id: r0.id, to_room_id: r2.id})
Repo.insert!(%Exit{dir: "w", from_room_id: r2.id, to_room_id: r0.id})

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
