defmodule Shard.Kitchen do
  @moduledoc """
  Handles cooking logic for the Kitchen feature.
  """

  import Ecto.Query, warn: false

  alias Decimal
  alias Shard.Repo
  alias Shard.Items
  alias Shard.Items.{Item, CharacterInventory}

  @food_item_specs %{
    "Roasted Seeds" => %{
      description: "Toasted forest seeds with a pleasant crunch.",
      value: 4,
      hp: 5,
      mana: 0,
      effect_text: "Restores 5 HP",
      weight: "0.1",
      max_stack_size: 40
    },
    "Cooked Mushroom" => %{
      description: "A tender mushroom roasted over a small fire.",
      value: 8,
      hp: 10,
      mana: 0,
      effect_text: "Restores 10 HP",
      weight: "0.1",
      max_stack_size: 30
    },
    "Mushroom Skewer" => %{
      description: "A generous skewer of mushrooms dripping with juices.",
      value: 20,
      hp: 30,
      mana: 10,
      effect_text: "Restores 30 HP and 10 Mana",
      weight: "0.2",
      max_stack_size: 15
    },
    "Sweet Glazed Seeds" => %{
      description: "Seeds coated in sticky resin for a sugary kick.",
      value: 15,
      hp: 0,
      mana: 15,
      effect_text: "Restores 15 Mana",
      weight: "0.1",
      max_stack_size: 25
    },
    "Forest Stew" => %{
      description: "A hearty stew packed with forest flavors.",
      value: 30,
      hp: 40,
      mana: 0,
      effect_text: "Restores 40 HP",
      weight: "0.3",
      max_stack_size: 10
    }
  }

  @food_effects Enum.into(@food_item_specs, %{}, fn {name, spec} ->
                  {name, %{hp: spec.hp, mana: spec.mana, effect_text: spec.effect_text}}
                end)

  @recipes [
    %{
      key: :cook_roasted_seeds,
      name: "Roasted Seeds",
      result_name: "Roasted Seeds",
      result_quantity: 1,
      effect_text: "Restores 5 HP",
      ingredients: [
        %{name: "Seed", quantity: 3},
        %{name: "Wood", quantity: 1}
      ]
    },
    %{
      key: :cook_cooked_mushroom,
      name: "Cooked Mushroom",
      result_name: "Cooked Mushroom",
      result_quantity: 1,
      effect_text: "Restores 10 HP",
      ingredients: [
        %{name: "Mushroom", quantity: 1},
        %{name: "Wood", quantity: 1}
      ]
    },
    %{
      key: :cook_mushroom_skewer,
      name: "Mushroom Skewer",
      result_name: "Mushroom Skewer",
      result_quantity: 1,
      effect_text: "Restores 30 HP and 10 Mana",
      ingredients: [
        %{name: "Cooked Mushroom", quantity: 3}
      ]
    },
    %{
      key: :cook_sweet_glazed_seeds,
      name: "Sweet Glazed Seeds",
      result_name: "Sweet Glazed Seeds",
      result_quantity: 1,
      effect_text: "Restores 15 Mana",
      ingredients: [
        %{name: "Seed", quantity: 5},
        %{name: "Resin", quantity: 1}
      ]
    },
    %{
      key: :cook_forest_stew,
      name: "Forest Stew",
      result_name: "Forest Stew",
      result_quantity: 1,
      effect_text: "Restores 40 HP",
      ingredients: [
        %{name: "Cooked Mushroom", quantity: 2},
        %{name: "Stick", quantity: 1},
        %{name: "Wood", quantity: 1}
      ]
    }
  ]

  @doc """
  Returns all kitchen recipes.
  """
  def recipes, do: @recipes

  @doc """
  Returns decorated recipes with ingredient availability.
  """
  def recipes_for_character(nil), do: decorate_recipes(%{})

  def recipes_for_character(character_id) do
    material_counts = material_counts(character_id)
    decorate_recipes(material_counts)
  end

  @doc """
  Attempts to cook a recipe identified by `key`.
  """
  def cook(character_id, key) do
    with {:ok, recipe} <- fetch_recipe(key),
         true <-
           has_all_ingredients?(character_id, recipe.ingredients) ||
             {:error, :insufficient_materials},
         {:ok, ingredients} <- load_ingredient_items(recipe.ingredients),
         {:ok, result_item} <- fetch_item_by_name(recipe.result_name),
         {:ok, _} <- apply_cooking(character_id, ingredients, result_item, recipe.result_quantity) do
      {:ok, recipe}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns the food effect definitions for easy lookup.
  """
  def food_effects, do: @food_effects

  def food_effect(name), do: Map.get(food_effects(), name)

  defp decorate_recipes(material_counts) do
    Enum.map(@recipes, fn recipe ->
      detailed_ingredients =
        Enum.map(recipe.ingredients, fn ingredient ->
          available = Map.get(material_counts, ingredient.name, 0)
          Map.put(ingredient, :available, available)
        end)

      can_cook? = Enum.all?(detailed_ingredients, &(&1.available >= &1.quantity))

      recipe
      |> Map.put(:ingredients, detailed_ingredients)
      |> Map.put(:can_cook?, can_cook?)
    end)
  end

  defp material_counts(nil), do: %{}

  defp material_counts(character_id) do
    names =
      recipes()
      |> Enum.flat_map(&ingredient_names/1)
      |> Enum.uniq()

    if names == [] do
      %{}
    else
      from(ci in CharacterInventory,
        join: i in Item,
        on: ci.item_id == i.id,
        where: ci.character_id == ^character_id and i.name in ^names and ci.equipped == false,
        group_by: i.name,
        select: {i.name, coalesce(sum(ci.quantity), 0)}
      )
      |> Repo.all()
      |> Map.new()
    end
  end

  defp ingredient_names(recipe) do
    Enum.map(recipe.ingredients, & &1.name)
  end

  defp fetch_recipe(key) do
    case Enum.find(@recipes, &(&1.key == key)) do
      nil -> {:error, :unknown_recipe}
      recipe -> {:ok, recipe}
    end
  end

  defp has_all_ingredients?(character_id, ingredients) do
    Enum.all?(ingredients, fn ingredient ->
      Items.get_character_item_quantity(character_id, ingredient.name) >= ingredient.quantity
    end)
  end

  defp load_ingredient_items(ingredients) do
    Enum.reduce_while(ingredients, {:ok, []}, fn ingredient, {:ok, acc} ->
      case fetch_item_by_name(ingredient.name) do
        {:ok, item} ->
          entry = Map.put(ingredient, :item, item)
          {:cont, {:ok, [entry | acc]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, loaded} -> {:ok, Enum.reverse(loaded)}
      error -> error
    end
  end

  defp fetch_item_by_name(name) do
    case Repo.get_by(Item, name: name) do
      %Item{} = item ->
        {:ok, item}

      nil ->
        maybe_create_food_item(name)
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
            {:error, changeset}
        end
    end
  end

  defp build_food_item_attrs(spec, name) do
    %{
      name: name,
      description: spec.description,
      item_type: "consumable",
      rarity: "common",
      value: spec.value,
      weight: Decimal.new(spec.weight),
      stackable: true,
      max_stack_size: spec.max_stack_size,
      equippable: false,
      sellable: true,
      effects: %{"effect" => spec.effect_text}
    }
  end

  defp apply_cooking(character_id, ingredients, result_item, result_quantity) do
    Repo.transaction(fn ->
      Enum.each(ingredients, fn %{item: item, quantity: qty} ->
        case remove_item_quantity(character_id, item.id, qty) do
          :ok -> :ok
          {:error, reason} -> Repo.rollback(reason)
        end
      end)

      case Items.add_item_to_inventory(character_id, result_item.id, result_quantity) do
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
end
