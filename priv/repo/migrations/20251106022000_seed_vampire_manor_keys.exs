defmodule Shard.Repo.Migrations.SeedVampireManorKeys do
  use Ecto.Migration

  def change do
    execute(&seed_keys_up/0, &seed_keys_down/0)
  end

  defp seed_keys_up do
    alias Shard.Repo
    alias Shard.Items.Item

    IO.puts("Creating Vampire Manor key items...")

    # Define the key items needed for the vampire manor
    key_items = [
      %{
        name: "Rusty Sewer Key",
        description: "A corroded iron key that looks like it belongs to the manor's old sewer system. The metal is stained with age and moisture.",
        item_type: "key",
        rarity: "common",
        value: 25,
        weight: 0.1,
        stackable: false,
        equippable: false,
        pickup: true,
        is_active: true,
        properties: %{
          "unlocks" => "sewer_entrance",
          "manor_area" => "sewers"
        }
      },
      %{
        name: "Manor Key",
        description: "An ornate brass key with intricate vampire motifs carved into its head. It feels cold to the touch and seems to pulse with dark energy.",
        item_type: "key",
        rarity: "uncommon",
        value: 100,
        weight: 0.2,
        stackable: false,
        equippable: false,
        pickup: true,
        is_active: true,
        properties: %{
          "unlocks" => "manor_entrance",
          "manor_area" => "main_hall"
        }
      },
      %{
        name: "Library Key",
        description: "A scholarly key made of tarnished silver, with small book symbols etched along its shaft. Knowledge seekers would prize this highly.",
        item_type: "key",
        rarity: "uncommon",
        value: 75,
        weight: 0.1,
        stackable: false,
        equippable: false,
        pickup: true,
        is_active: true,
        properties: %{
          "unlocks" => "library",
          "manor_area" => "library"
        }
      },
      %{
        name: "Study Key",
        description: "A delicate key crafted from blackened iron, with arcane symbols that seem to shift in the light. It radiates a faint magical aura.",
        item_type: "key",
        rarity: "rare",
        value: 150,
        weight: 0.1,
        stackable: false,
        equippable: false,
        pickup: true,
        is_active: true,
        properties: %{
          "unlocks" => "study",
          "manor_area" => "study",
          "magical" => true
        }
      },
      %{
        name: "Master Key",
        description: "An imposing key forged from dark steel and adorned with blood-red gems. This key grants access to the vampire lord's private chambers.",
        item_type: "key",
        rarity: "legendary",
        value: 500,
        weight: 0.3,
        stackable: false,
        equippable: false,
        pickup: true,
        is_active: true,
        properties: %{
          "unlocks" => "master_chamber",
          "manor_area" => "master_chamber",
          "boss_key" => true,
          "vampire_lord" => true
        }
      }
    ]

    # Create each key item
    Enum.each(key_items, fn key_attrs ->
      case Repo.get_by(Item, name: key_attrs.name) do
        nil ->
          case %Item{}
               |> Item.changeset(key_attrs)
               |> Repo.insert() do
            {:ok, item} ->
              IO.puts("Created key item: #{item.name}")

            {:error, changeset} ->
              IO.puts("Failed to create key item #{key_attrs.name}: #{inspect(changeset.errors)}")
              raise "Key item creation failed for #{key_attrs.name}"
          end

        existing_item ->
          IO.puts("Key item already exists: #{existing_item.name}")
      end
    end)

    IO.puts("✓ Vampire Manor key items successfully seeded!")
  end

  defp seed_keys_down do
    alias Shard.Repo
    alias Shard.Items.Item

    IO.puts("Removing Vampire Manor key items...")

    key_names = [
      "Rusty Sewer Key",
      "Manor Key", 
      "Library Key",
      "Study Key",
      "Master Key"
    ]

    Enum.each(key_names, fn key_name ->
      case Repo.get_by(Item, name: key_name) do
        nil ->
          IO.puts("Key item not found: #{key_name}")

        item ->
          Repo.delete!(item)
          IO.puts("Deleted key item: #{key_name}")
      end
    end)

    IO.puts("✓ Vampire Manor key items rollback completed!")
  end
end
