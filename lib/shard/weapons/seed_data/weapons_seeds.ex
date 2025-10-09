defmodule Shard.Weapons.SeedData.WeaponsSeeds do

  def data do
    [
      %{
        name: "Iron Dagger",
        damage: 5,
        gold_value: 25,
        description: "A simple iron dagger with a sharp blade.",
        weapon_class_id: 1,
        rarity_id: 1
      },
      %{
        name: "Steel Longsword",
        damage: 10,
        gold_value: 100,
        description: "A well-crafted steel longsword.",
        weapon_class_id: 2,
        rarity_id: 2
      },
      %{
        name: "Battle Axe",
        damage: 12,
        gold_value: 150,
        description: "A heavy battle axe that can cleave through armor.",
        weapon_class_id: 3,
        rarity_id: 2
      },
      %{
        name: "Flaming Sword",
        damage: 15,
        gold_value: 500,
        description: "A magical sword wreathed in eternal flames.",
        weapon_class_id: 2,
        rarity_id: 4
      }
    ]
  end
end
