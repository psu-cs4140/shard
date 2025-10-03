# priv/repo/seeds.exs
alias Shard.Repo
alias Shard.World.{Room, Exit}
import Ecto.Query, only: [from: 2]

# --- Clean tables (portable) --------------------------------------------
# Using delete_all avoids TRUNCATE permissions issues and works across DBs.
Repo.delete_all(Exit)
Repo.delete_all(Room)

# --- Rooms ---------------------------------------------------------------
town =
  Repo.insert!(%Room{
    slug: "town-square",
    name: "Town Square",
    description: "A bustling plaza with a dry fountain.",
    x: 0,
    y: 0
  })

gate =
  Repo.insert!(%Room{
    slug: "north-gate",
    name: "North Gate",
    description: "Old stone gate with iron portcullis.",
    x: 0,
    y: 1
  })

market =
  Repo.insert!(%Room{
    slug: "market-street",
    name: "Market Street",
    description: "Stalls line the road, spices in the air.",
    x: 1,
    y: 0
  })

# --- Figure out Exit column names at runtime ----------------------------
exit_fields = Exit.__schema__(:fields)

from_key =
  cond do
    :from_room_id in exit_fields -> :from_room_id
    :from_id in exit_fields -> :from_id
    :source_id in exit_fields -> :source_id
    true -> raise "Unknown origin column in exits: #{inspect(exit_fields)}"
  end

to_key =
  cond do
    :to_room_id in exit_fields -> :to_room_id
    :to_id in exit_fields -> :to_id
    :dest_id in exit_fields -> :dest_id
    :destination_id in exit_fields -> :destination_id
    true -> raise "Unknown destination column in exits: #{inspect(exit_fields)}"
  end

dir_key =
  cond do
    :dir in exit_fields -> :dir
    :direction in exit_fields -> :direction
    true -> raise "Unknown direction column in exits: #{inspect(exit_fields)}"
  end

# --- Helper to insert exits using the detected keys ---------------------
mk_exit = fn from_id, dir, to_id ->
  attrs =
    %{}
    |> Map.put(from_key, from_id)
    |> Map.put(dir_key, dir)
    |> Map.put(to_key, to_id)

  Repo.insert!(struct(Exit, attrs))
end

# --- Wire up N/S and E/W paths -----------------------------------------
mk_exit.(town.id, "n", gate.id)
mk_exit.(gate.id, "s", town.id)
mk_exit.(town.id, "e", market.id)
mk_exit.(market.id, "w", town.id)

IO.puts(" Seeded rooms & exits: Town Square ↔ North Gate, Town Square ↔ Market Street")
