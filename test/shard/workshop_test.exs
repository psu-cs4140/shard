defmodule Shard.WorkshopTest do
  use Shard.DataCase

  import Shard.CharactersFixtures

  alias Shard.{Items, Workshop}
  alias Shard.Items.Item
  alias Shard.Repo

  describe "recipes" do
    test "recipes/0 returns the defined crafting list" do
      recipes = Workshop.recipes()

      assert length(recipes) > 0
      assert Enum.any?(recipes, &(&1.key == :craft_torch))
    end

    test "recipes_for_character/1 marks craftable recipes" do
      character = character_fixture()
      ensure_material("Stick")
      ensure_material("Resin")

      add_material(character.id, "Stick", 1)
      add_material(character.id, "Resin", 1)

      recipes = Workshop.recipes_for_character(character.id)
      torch = Enum.find(recipes, &(&1.key == :craft_torch))

      assert torch.can_craft?
      assert Enum.all?(torch.ingredients, &(&1.available >= &1.quantity))
    end
  end

  describe "craft/2" do
    test "successfully crafts an item when materials exist" do
      character = character_fixture()
      ensure_material("Stick")
      ensure_material("Resin")

      add_material(character.id, "Stick", 1)
      add_material(character.id, "Resin", 1)

      assert {:ok, recipe} = Workshop.craft(character.id, :craft_torch)
      assert recipe.name == "Torch"

      assert Items.get_character_item_quantity(character.id, "Torch") == 1
      assert Items.get_character_item_quantity(character.id, "Stick") == 0
      assert Items.get_character_item_quantity(character.id, "Resin") == 0
    end
  end

  defp ensure_material(name) do
    case Repo.get_by(Item, name: name) do
      %Item{} = item -> item
      nil -> create_material(name)
    end
  end

  defp create_material(name) do
    {:ok, item} =
      Items.create_item(%{
        name: name,
        description: "#{name} material",
        item_type: "material",
        rarity: "common",
        value: 1,
        weight: "1.0",
        stackable: true,
        max_stack_size: 99
      })

    item
  end

  defp add_material(character_id, name, quantity) do
    item = ensure_material(name)
    {:ok, _} = Items.add_item_to_inventory(character_id, item.id, quantity)
    :ok
  end
end
