defmodule Shard.Repo.Migrations.AddPoisonSpiderMonster do
  use Ecto.Migration

  def change do
    execute(&up/0, &down/0)
  end

  defp up do
    alias Shard.Repo
    alias Shard.Monsters
    alias Shard.Weapons.DamageTypes
    import Ecto.Query

    # Find the Bone Zone
    bone_zone = Repo.get_by(Shard.Map.Zone, slug: "bone-zone")

    if bone_zone do
      # Find the Spider Dungeon room at coordinates (0,3) in the Bone Zone
      spider_dungeon =
        Repo.get_by(Shard.Map.Room, zone_id: bone_zone.id, x_coordinate: 0, y_coordinate: 3)

      if spider_dungeon do
        # Get or create the Poison damage type
        poison_type =
          case Repo.get_by(DamageTypes, name: "Poison") do
            nil ->
              # Create Poison damage type if it doesn't exist
              {:ok, new_type} =
                %DamageTypes{}
                |> DamageTypes.changeset(%{name: "Poison"})
                |> Repo.insert()

              new_type

            existing ->
              existing
          end

        # Create the Spider Silk item if it doesn't exist
        # Query the items table directly to avoid schema issues with spell_id column
        spider_silk_item =
          case Repo.one(from(i in "items", where: i.name == "Spider Silk", select: i.id)) do
            nil ->
              # Insert directly into the items table
              {:ok, result} =
                Repo.query(
                  """
                  INSERT INTO items (name, description, item_type, rarity, value, stackable, max_stack_size, is_active, inserted_at, updated_at)
                  VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
                  RETURNING id
                  """,
                  [
                    "Spider Silk",
                    "Fine, strong silk harvested from a giant spider.",
                    "material",
                    "common",
                    5,
                    true,
                    10,
                    true,
                    NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
                    NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
                  ]
                )

              %{id: result.rows |> List.first() |> List.first()}

            existing_id ->
              %{id: existing_id}
          end

        # Create the poison spider monster
        {:ok, _spider} =
          Monsters.create_monster(%{
            name: "Giant Poison Spider",
            race: "Arachnid",
            health: 25,
            max_health: 25,
            attack_damage: 1,
            xp_amount: 15,
            level: 3,
            description: "A large spider with glistening fangs dripping with venom.",
            location_id: spider_dungeon.id,
            special_damage_type_id: poison_type.id,
            special_damage_amount: 1,
            special_damage_duration: 5,
            special_damage_chance: 25,
            potential_loot_drops: %{
              "#{spider_silk_item.id}" => %{chance: 1.0, min_quantity: 1, max_quantity: 1}
            }
          })

        IO.puts("Successfully created Giant Poison Spider in Spider Dungeon")
      else
        IO.puts("Warning: Spider Dungeon room not found at (0,3) in Bone Zone")
      end
    else
      IO.puts("Warning: Bone Zone not found")
    end
  end

  defp down do
    alias Shard.Repo
    alias Shard.Monsters

    # Find and delete the poison spider
    spider = Repo.get_by(Shard.Monsters.Monster, name: "Giant Poison Spider")

    if spider do
      Monsters.delete_monster(spider)
      IO.puts("Deleted Giant Poison Spider")
    else
      IO.puts("Poison spider not found")
    end

    # Find and delete the spider silk item using raw query
    Repo.query("DELETE FROM items WHERE name = $1", ["Spider Silk"])
    IO.puts("Deleted Spider Silk item (if it existed)")
  end
end
