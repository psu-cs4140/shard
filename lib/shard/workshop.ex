defmodule Shard.Workshop do
  @moduledoc """
  Handles simple crafting recipes for the Workshop feature.
  """

  import Ecto.Query, warn: false

  alias Decimal
  alias Shard.Repo
  alias Shard.Items
  alias Shard.Items.{Item, CharacterInventory}

  @result_item_specs %{
    "Crude Stone Dagger" => %{
      description: "A rough dagger carved from sharpened stone.",
      item_type: "weapon",
      rarity: "common",
      value: 10,
      weight: "1.2",
      equippable: true,
      equipment_slot: "weapon",
      stackable: false
    },
    "Stone Axe" => %{
      description: "A balanced axe with a chiseled stone head.",
      item_type: "weapon",
      rarity: "common",
      value: 18,
      weight: "2.5",
      equippable: true,
      equipment_slot: "weapon",
      stackable: false
    },
    "Reinforced Club" => %{
      description: "A heavy club reinforced with extra timber bindings.",
      item_type: "weapon",
      rarity: "common",
      value: 20,
      weight: "2.0",
      equippable: true,
      equipment_slot: "weapon",
      stackable: false
    },
    "Torch" => %{
      description: "A simple torch for exploring dark tunnels.",
      item_type: "misc",
      rarity: "common",
      value: 6,
      weight: "0.5",
      equippable: false,
      equipment_slot: nil,
      stackable: true,
      max_stack_size: 10
    },
    "Forager's Pack" => %{
      description: "A bundle of gathered supplies for long journeys.",
      item_type: "misc",
      rarity: "common",
      value: 22,
      weight: "1.8",
      equippable: false,
      equipment_slot: nil,
      stackable: false
    }
  }

  @recipes [
    %{
      key: :craft_dagger,
      name: "Crude Stone Dagger",
      result_name: "Crude Stone Dagger",
      result_quantity: 1,
      sell_value: 10,
      ingredients: [
        %{name: "Stick", quantity: 1},
        %{name: "Stone", quantity: 2}
      ]
    },
    %{
      key: :craft_stone_axe,
      name: "Stone Axe",
      result_name: "Stone Axe",
      result_quantity: 1,
      sell_value: 18,
      ingredients: [
        %{name: "Wood", quantity: 2},
        %{name: "Stone", quantity: 3}
      ]
    },
    %{
      key: :craft_club,
      name: "Reinforced Club",
      result_name: "Reinforced Club",
      result_quantity: 1,
      sell_value: 20,
      ingredients: [
        %{name: "Wood", quantity: 3}
      ]
    },
    %{
      key: :craft_torch,
      name: "Torch",
      result_name: "Torch",
      result_quantity: 1,
      sell_value: 6,
      ingredients: [
        %{name: "Stick", quantity: 1},
        %{name: "Resin", quantity: 1}
      ]
    },
    %{
      key: :craft_foragers_pack,
      name: "Forager's Pack",
      result_name: "Forager's Pack",
      result_quantity: 1,
      sell_value: 22,
      ingredients: [
        %{name: "Wood", quantity: 2},
        %{name: "Stick", quantity: 2},
        %{name: "Mushroom", quantity: 1}
      ]
    }
  ]

  @doc """
  Returns the base recipe definitions.
  """
  def recipes, do: @recipes

  @doc """
  Returns decorated recipes with availability data for the given character.
  """
  def recipes_for_character(nil), do: decorate_recipes(%{})

  def recipes_for_character(character_id) do
    material_counts = material_counts(character_id)
    decorate_recipes(material_counts)
  end

  @doc """
  Attempts to craft the recipe identified by `key` for the given character.
  """
  def craft(character_id, key) do
    with {:ok, recipe} <- fetch_recipe(key),
         {:ok, ingredients} <- load_ingredient_items(recipe.ingredients),
         {:ok, result_item} <- fetch_item_by_name(recipe.result_name),
         :ok <- ensure_has_ingredients(character_id, ingredients),
         {:ok, _} <- apply_crafting(character_id, ingredients, result_item, recipe.result_quantity) do
      {:ok, recipe}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns how many of each material the character currently holds for Workshop recipes.
  """
  def material_counts(nil), do: %{}

  def material_counts(character_id) do
    names = recipes() |> Enum.flat_map(&ingredient_names/1) |> Enum.uniq()

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

  defp decorate_recipes(material_counts) do
    Enum.map(@recipes, fn recipe ->
      detailed_ingredients =
        Enum.map(recipe.ingredients, fn ingredient ->
          available = Map.get(material_counts, ingredient.name, 0)
          ingredient |> Map.put(:available, available)
        end)

      recipe
      |> Map.put(:ingredients, detailed_ingredients)
      |> Map.put(:can_craft?, Enum.all?(detailed_ingredients, &(&1.available >= &1.quantity)))
    end)
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
      {:ok, items} -> {:ok, Enum.reverse(items)}
      error -> error
    end
  end

  defp fetch_item_by_name(name) do
    case Repo.get_by(Item, name: name) do
      %Item{} = item ->
        {:ok, item}

      nil ->
        maybe_create_result_item(name)
    end
  end

  defp maybe_create_result_item(name) do
    case Map.fetch(@result_item_specs, name) do
      :error ->
        {:error, {:item_not_found, name}}

      {:ok, spec} ->
        spec
        |> build_result_item_attrs(name)
        |> Items.create_item()
        |> case do
          {:ok, item} ->
            {:ok, item}

          {:error, changeset} ->
            if name_taken?(changeset) do
              case Repo.get_by(Item, name: name) do
                %Item{} = item -> {:ok, item}
                nil -> {:error, changeset}
              end
            else
              {:error, changeset}
            end
        end
    end
  end

  defp build_result_item_attrs(spec, name) do
    %{
      name: name,
      description: spec.description,
      item_type: spec.item_type,
      rarity: spec.rarity,
      value: spec.value,
      weight: Decimal.new(spec.weight),
      stackable: Map.get(spec, :stackable, false),
      max_stack_size: Map.get(spec, :max_stack_size, 1),
      equippable: Map.get(spec, :equippable, false),
      equipment_slot: Map.get(spec, :equipment_slot),
      sellable: true
    }
  end

  defp name_taken?(%Ecto.Changeset{errors: errors}) do
    Enum.any?(errors, fn
      {:name, {_, [constraint: :unique, constraint_name: _]}} -> true
      _ -> false
    end)
  end

  defp name_taken?(_), do: false

  defp ensure_has_ingredients(character_id, ingredients) do
    has_all? =
      Enum.all?(ingredients, fn ingredient ->
        available = Items.get_character_item_quantity(character_id, ingredient.name)
        available >= ingredient.quantity
      end)

    if has_all? do
      :ok
    else
      {:error, :insufficient_materials}
    end
  end

  defp apply_crafting(character_id, ingredients, result_item, result_quantity) do
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
      {:ok, _} -> {:ok, :crafted}
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
