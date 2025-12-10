defmodule Shard.Cooking do
  @moduledoc """
  Handles cooking logic for food-based crafting within the Workshop.
  """

  import Ecto.Query, warn: false

  alias Decimal
  alias Shard.Repo
  alias Shard.Items
  alias Shard.Items.{Item, CharacterInventory}

  @food_item_specs %{
    "Grilled Mushrooms" => %{
      description: "Forest mushrooms seared over an open flame. Savory and portable.",
      item_type: "food",
      rarity: "common",
      value: 6,
      weight: "0.2",
      stackable: true,
      max_stack_size: 20
    },
    "Forest Stew" => %{
      description:
        "A hearty stew of seeds, resin, and mushrooms. Fills even the hungriest adventurer.",
      item_type: "food",
      rarity: "uncommon",
      value: 14,
      weight: "0.6",
      stackable: true,
      max_stack_size: 10
    },
    "Miner's Snack" => %{
      description:
        "A dense trail bar forged from ore-town supplies. Keeps miners going between shifts.",
      item_type: "food",
      rarity: "common",
      value: 10,
      weight: "0.3",
      stackable: true,
      max_stack_size: 15
    }
  }

  @recipes [
    %{
      key: :cook_grilled_mushrooms,
      name: "Grilled Mushrooms",
      result_name: "Grilled Mushrooms",
      result_quantity: 2,
      sell_value: 6,
      ingredients: [
        %{name: "Mushroom", quantity: 2},
        %{name: "Stick", quantity: 1}
      ]
    },
    %{
      key: :cook_forest_stew,
      name: "Forest Stew",
      result_name: "Forest Stew",
      result_quantity: 1,
      sell_value: 14,
      ingredients: [
        %{name: "Mushroom", quantity: 1},
        %{name: "Forest Resin", quantity: 1},
        %{name: "Wood", quantity: 1}
      ]
    },
    %{
      key: :cook_miners_snack,
      name: "Miner's Snack",
      result_name: "Miner's Snack",
      result_quantity: 1,
      sell_value: 10,
      ingredients: [
        %{name: "Copper Ore", quantity: 1},
        %{name: "Coal", quantity: 1},
        %{name: "Stick", quantity: 1}
      ]
    }
  ]

  @doc """
  Lists the available cooking recipes.
  """
  def recipes, do: @recipes

  @doc """
  Returns decorated recipes with inventory availability for the given character.
  """
  def recipes_for_character(nil), do: decorate_recipes(%{})

  def recipes_for_character(character_id) do
    ingredient_counts = ingredient_counts(character_id)
    decorate_recipes(ingredient_counts)
  end

  @doc """
  Attempts to cook a recipe for a character.
  """
  def cook(character_id, key) do
    with {:ok, recipe} <- fetch_recipe(key),
         {:ok, ingredients} <- load_ingredient_items(recipe.ingredients),
         {:ok, result_item} <- fetch_item_by_name(recipe.result_name),
         :ok <- ensure_has_ingredients(character_id, ingredients),
         {:ok, _} <-
           apply_cooking(character_id, ingredients, result_item, recipe.result_quantity) do
      {:ok, recipe}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp decorate_recipes(ingredient_counts) do
    Enum.map(@recipes, fn recipe ->
      detailed =
        Enum.map(recipe.ingredients, fn ingredient ->
          available = Map.get(ingredient_counts, ingredient.name, 0)
          Map.put(ingredient, :available, available)
        end)

      recipe
      |> Map.put(:ingredients, detailed)
      |> Map.put(:can_cook?, Enum.all?(detailed, &(&1.available >= &1.quantity)))
    end)
  end

  defp ingredient_counts(character_id) do
    names =
      @recipes
      |> Enum.flat_map(fn recipe -> Enum.map(recipe.ingredients, & &1.name) end)
      |> Enum.uniq()

    if names == [] do
      %{}
    else
      from(ci in CharacterInventory,
        join: item in Item,
        on: ci.item_id == item.id,
        where: ci.character_id == ^character_id and item.name in ^names and ci.equipped == false,
        group_by: item.name,
        select: {item.name, coalesce(sum(ci.quantity), 0)}
      )
      |> Repo.all()
      |> Map.new()
    end
  end

  defp fetch_recipe(key) do
    case Enum.find(@recipes, &(&1.key == key)) do
      nil -> {:error, :unknown_recipe}
      recipe -> {:ok, recipe}
    end
  end

  defp load_ingredient_items(ingredients) do
    Enum.reduce_while(ingredients, {:ok, []}, fn ingredient, {:ok, acc} ->
      case fetch_item_by_name(ingredient.name) do
        {:ok, item} ->
          {:cont, {:ok, [Map.put(ingredient, :item, item) | acc]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, items} -> {:ok, Enum.reverse(items)}
      error -> error
    end
  end

  defp fetch_item_by_name(name) do
    case Repo.get_by(Item, name: name) do
      %Item{} = item -> {:ok, item}
      nil -> maybe_create_food_item(name)
    end
  end

  defp maybe_create_food_item(name) do
    case Map.fetch(@food_item_specs, name) do
      :error ->
        {:error, {:item_not_found, name}}

      {:ok, spec} ->
        spec
        |> build_food_item_attrs(name)
        |> Items.create_item()
        |> case do
          {:ok, item} ->
            {:ok, item}

          {:error, changeset} ->
            if name_taken?(changeset) do
              case Repo.get_by(Item, name: name) do
                %Item{} = existing -> {:ok, existing}
                nil -> {:error, changeset}
              end
            else
              {:error, changeset}
            end
        end
    end
  end

  defp build_food_item_attrs(spec, name) do
    %{
      name: name,
      description: spec.description,
      item_type: spec.item_type,
      rarity: Map.get(spec, :rarity, "common"),
      value: spec.value,
      weight: Decimal.new(spec.weight),
      stackable: Map.get(spec, :stackable, true),
      max_stack_size: Map.get(spec, :max_stack_size, 10),
      equippable: false,
      sellable: true
    }
  end

  defp ensure_has_ingredients(character_id, ingredients) do
    has_all? =
      Enum.all?(ingredients, fn ingredient ->
        Items.get_character_item_quantity(character_id, ingredient.name) >= ingredient.quantity
      end)

    if has_all? do
      :ok
    else
      {:error, :insufficient_materials}
    end
  end

  defp apply_cooking(character_id, ingredients, result_item, quantity) do
    Repo.transaction(fn ->
      Enum.each(ingredients, fn %{item: item, quantity: needed} ->
        case remove_item_quantity(character_id, item.id, needed) do
          :ok -> :ok
          {:error, reason} -> Repo.rollback(reason)
        end
      end)

      case Items.add_item_to_inventory(character_id, result_item.id, quantity) do
        {:ok, _} -> :ok
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
    |> case do
      {:ok, _} -> {:ok, :cooked}
      {:error, reason} -> {:error, reason}
    end
  end

  defp remove_item_quantity(character_id, item_id, quantity) do
    entries =
      from(ci in CharacterInventory,
        where:
          ci.character_id == ^character_id and ci.item_id == ^item_id and ci.equipped == false,
        order_by: [asc: ci.id]
      )
      |> Repo.all()

    do_remove(entries, quantity)
  end

  defp do_remove(_entries, 0), do: :ok
  defp do_remove([], _remaining), do: {:error, :insufficient_materials}

  defp do_remove([entry | rest], remaining) when remaining > 0 do
    take = min(entry.quantity, remaining)

    case Items.remove_item_from_inventory(entry.id, take) do
      {:ok, _} ->
        do_remove(rest, remaining - take)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp name_taken?(%Ecto.Changeset{errors: errors}) do
    Enum.any?(errors, fn
      {:name, {_, [constraint: :unique, constraint_name: _]}} -> true
      _ -> false
    end)
  end

  defp name_taken?(_), do: false
end
