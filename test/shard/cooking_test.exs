defmodule Shard.CookingTest do
  use Shard.DataCase

  import Shard.CharactersFixtures

  alias Shard.{Cooking, Items}
  alias Shard.Items.Item
  alias Shard.Repo

  describe "recipes/0" do
    test "returns defined cooking recipes" do
      recipes = Cooking.recipes()

      assert Enum.any?(recipes, &(&1.key == :cook_grilled_mushrooms))
      assert Enum.any?(recipes, &(&1.key == :cook_forest_stew))
    end
  end

  describe "recipes_for_character/1" do
    test "marks recipes as cookable when inventory has enough ingredients" do
      character = character_fixture()
      ensure_ingredient("Mushroom")
      ensure_ingredient("Stick")

      add_ingredient(character.id, "Mushroom", 2)
      add_ingredient(character.id, "Stick", 1)

      recipes = Cooking.recipes_for_character(character.id)
      recipe = Enum.find(recipes, &(&1.key == :cook_grilled_mushrooms))

      assert recipe.can_cook?
      assert Enum.all?(recipe.ingredients, &(&1.available >= &1.quantity))
    end
  end

  describe "cook/2" do
    test "consumes ingredients and adds cooked food" do
      character = character_fixture()
      ensure_ingredient("Mushroom")
      ensure_ingredient("Stick")

      add_ingredient(character.id, "Mushroom", 2)
      add_ingredient(character.id, "Stick", 1)

      assert {:ok, recipe} = Cooking.cook(character.id, :cook_grilled_mushrooms)
      assert recipe.name == "Grilled Mushrooms"

      assert Items.get_character_item_quantity(character.id, "Grilled Mushrooms") == 2
      assert Items.get_character_item_quantity(character.id, "Mushroom") == 0
      assert Items.get_character_item_quantity(character.id, "Stick") == 0
    end

    test "fails when ingredients are missing" do
      character = character_fixture()
      ensure_ingredient("Mushroom")
      ensure_ingredient("Stick")

      add_ingredient(character.id, "Mushroom", 1)

      assert {:error, :insufficient_materials} =
               Cooking.cook(character.id, :cook_grilled_mushrooms)
    end
  end

  defp ensure_ingredient(name) do
    case Repo.get_by(Item, name: name) do
      %Item{} = item ->
        item

      nil ->
        {:ok, item} =
          Items.create_item(%{
            name: name,
            description: "#{name} ingredient",
            item_type: "material",
            rarity: "common",
            value: 1,
            weight: "1.0",
            stackable: true,
            max_stack_size: 99,
            sellable: true
          })

        item
    end
  end

  defp add_ingredient(character_id, name, quantity) do
    item = ensure_ingredient(name)
    {:ok, _} = Items.add_item_to_inventory(character_id, item.id, quantity)
    :ok
  end
end
