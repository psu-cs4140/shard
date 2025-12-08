defmodule Shard.KitchenTest do
  use Shard.DataCase

  import Shard.CharactersFixtures

  alias Shard.{Kitchen, Items}
  alias Shard.Items.Item
  alias Shard.Repo

  describe "recipes/0" do
    test "returns base cooking recipes" do
      assert Enum.any?(Kitchen.recipes(), &(&1.key == :cook_roasted_seeds))
    end

    test "recipes_for_character/1 annotates ingredient availability" do
      character = character_fixture()
      add_material(character.id, "Seed", 3)
      add_material(character.id, "Wood", 1)

      recipes = Kitchen.recipes_for_character(character.id)
      roasted = Enum.find(recipes, &(&1.key == :cook_roasted_seeds))

      assert roasted.can_cook?
      assert Enum.all?(roasted.ingredients, &(&1.available >= &1.quantity))
    end
  end

  describe "cook/2" do
    test "consumes ingredients and grants the prepared food" do
      character = character_fixture()
      add_material(character.id, "Seed", 3)
      add_material(character.id, "Wood", 1)

      assert {:ok, recipe} = Kitchen.cook(character.id, :cook_roasted_seeds)
      assert recipe.name == "Roasted Seeds"

      assert Items.get_character_item_quantity(character.id, "Roasted Seeds") == 1
      assert Items.get_character_item_quantity(character.id, "Seed") == 0
      assert Items.get_character_item_quantity(character.id, "Wood") == 0
    end
  end

  describe "food_effect/1" do
    test "returns effect metadata for cooked items" do
      effect = Kitchen.food_effect("Roasted Seeds")

      assert effect.hp == 5
      assert effect.mana == 0
      assert effect.effect_text =~ "Restores"
    end
  end

  defp add_material(character_id, name, quantity) do
    item = ensure_material(name)
    {:ok, _} = Items.add_item_to_inventory(character_id, item.id, quantity)
    :ok
  end

  defp ensure_material(name) do
    case Repo.get_by(Item, name: name) do
      %Item{} = item ->
        item

      nil ->
        {:ok, item} =
          Items.create_item(%{
            name: name,
            description: "#{name} material",
            item_type: "material",
            rarity: "common",
            value: 1,
            weight: "0.1",
            stackable: true,
            max_stack_size: 99
          })

        item
    end
  end
end

