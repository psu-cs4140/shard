defmodule Shard.Repo.Migrations.AddPoisonSpiderMonster do
  use Ecto.Migration

  def change do
    execute(&up/0, &down/0)
  end

  defp up do
    alias Shard.Repo
    alias Shard.Map
    alias Shard.Monsters
    alias Shard.Weapons.DamageTypes
    alias Shard.Items.Item

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
        spider_silk_item =
          case Repo.get_by(Item, name: "Spider Silk") do
            nil ->
              {:ok, new_item} =
                %Item{}
                |> Item.changeset(%{
                  name: "Spider Silk",
                  description: "Fine, strong silk harvested from a giant spider.",
                  item_type: "material",  # Changed from "crafting" to "material"
                  rarity: "common",
                  value: 5,
                  stackable: true,
                  max_stack_size: 10,
                  is_active: true
                })
                |> Repo.insert()

              new_item

            existing ->
              existing
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
    alias Shard.Items.Item

    # Find and delete the poison spider
    spider = Repo.get_by(Shard.Monsters.Monster, name: "Giant Poison Spider")

    if spider do
      Monsters.delete_monster(spider)
      IO.puts("Deleted Giant Poison Spider")
    else
      IO.puts("Poison spider not found")
    end

    # Find and delete the spider silk item
    spider_silk = Repo.get_by(Item, name: "Spider Silk")

    if spider_silk do
      Repo.delete(spider_silk)
      IO.puts("Deleted Spider Silk item")
    else
      IO.puts("Spider Silk item not found")
    end
  end
end
