defmodule Shard.Workshop do
  @moduledoc """
  Handles crafting and smelting logic for the Workshop feature.
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
    },
    "Copper Bar" => %{
      description: "A refined bar of copper ready for crafting.",
      item_type: "material",
      rarity: "common",
      value: 10,
      weight: "1.0",
      equippable: false,
      equipment_slot: nil,
      stackable: true,
      max_stack_size: 99
    },
    "Iron Bar" => %{
      description: "A sturdy iron bar prized by smiths.",
      item_type: "material",
      rarity: "common",
      value: 26,
      weight: "1.2",
      equippable: false,
      equipment_slot: nil,
      stackable: true,
      max_stack_size: 99
    },
    "Copper Dagger" => %{
      description: "A simple dagger with a copper blade. Better than bare hands.",
      item_type: "weapon",
      rarity: "common",
      value: 15,
      weight: "1.1",
      equippable: true,
      equipment_slot: "weapon",
      stackable: false
    },
    "Copper Pickaxe" => %{
      description: "A sturdy copper pickaxe, favored by novice miners.",
      item_type: "tool",
      rarity: "common",
      value: 22,
      weight: "2.8",
      equippable: false,
      equipment_slot: nil,
      stackable: false
    },
    "Iron Sword" => %{
      description: "A reliable iron sword with a well-balanced blade.",
      item_type: "weapon",
      rarity: "common",
      value: 35,
      weight: "2.1",
      equippable: true,
      equipment_slot: "weapon",
      stackable: false
    },
    "Iron Shield" => %{
      description: "A solid iron shield that can withstand heavy blows.",
      item_type: "shield",
      rarity: "common",
      value: 40,
      weight: "3.0",
      equippable: true,
      equipment_slot: "shield",
      stackable: false
    },
    "Gemmed Amulet" => %{
      description: "A radiant amulet set with a precious gem, humming with latent power.",
      item_type: "necklace",
      rarity: "common",
      value: 80,
      weight: "0.3",
      equippable: true,
      equipment_slot: "necklace",
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
    },
    %{
      key: :craft_copper_dagger,
      name: "Copper Dagger",
      result_name: "Copper Dagger",
      result_quantity: 1,
      sell_value: 15,
      ingredients: [
        %{name: "Copper Bar", quantity: 1},
        %{name: "Stick", quantity: 1}
      ]
    },
    %{
      key: :craft_copper_pickaxe,
      name: "Copper Pickaxe",
      result_name: "Copper Pickaxe",
      result_quantity: 1,
      sell_value: 22,
      ingredients: [
        %{name: "Copper Bar", quantity: 2},
        %{name: "Wood", quantity: 1}
      ]
    },
    %{
      key: :craft_iron_sword,
      name: "Iron Sword",
      result_name: "Iron Sword",
      result_quantity: 1,
      sell_value: 35,
      ingredients: [
        %{name: "Iron Bar", quantity: 2},
        %{name: "Wood", quantity: 1},
        %{name: "Stick", quantity: 1}
      ]
    },
    %{
      key: :craft_iron_shield,
      name: "Iron Shield",
      result_name: "Iron Shield",
      result_quantity: 1,
      sell_value: 40,
      ingredients: [
        %{name: "Iron Bar", quantity: 2},
        %{name: "Wood", quantity: 2}
      ]
    },
    %{
      key: :craft_gemmed_amulet,
      name: "Gemmed Amulet",
      result_name: "Gemmed Amulet",
      result_quantity: 1,
      sell_value: 80,
      ingredients: [
        %{name: "Gem", quantity: 1},
        %{name: "Copper Bar", quantity: 1},
        %{name: "Iron Bar", quantity: 1}
      ]
    }
  ]

  @furnace_recipes [
    %{
      key: :smelt_copper_bar,
      name: "Copper Bar",
      result_name: "Copper Bar",
      result_quantity: 1,
      sell_value: 10,
      ore: %{name: "Copper Ore", quantity: 2},
      fuel_options: [
        %{name: "Coal", quantity: 1},
        %{name: "Wood", quantity: 2}
      ]
    },
    %{
      key: :smelt_iron_bar,
      name: "Iron Bar",
      result_name: "Iron Bar",
      result_quantity: 1,
      sell_value: 26,
      ore: %{name: "Iron Ore", quantity: 3},
      fuel_options: [
        %{name: "Coal", quantity: 1},
        %{name: "Wood", quantity: 2}
      ]
    }
  ]

  @doc """
  Returns the base recipe definitions.
  """
  def recipes, do: @recipes

  @doc """
  Returns furnace recipe definitions.
  """
  def furnace_recipes, do: @furnace_recipes

  @doc """
  Returns decorated recipes with availability data for the given character.
  """
  def recipes_for_character(nil), do: decorate_recipes(%{})

  def recipes_for_character(character_id) do
    material_counts = material_counts(character_id)
    decorate_recipes(material_counts)
  end

  @doc """
  Returns furnace recipes with availability data for the character.
  """
  def furnace_recipes_for_character(nil), do: decorate_furnace_recipes(%{})

  def furnace_recipes_for_character(character_id) do
    material_counts = material_counts(character_id)
    decorate_furnace_recipes(material_counts)
  end

  @doc """
  Attempts to craft the recipe identified by `key` for the given character.
  """
  def craft(character_id, key) do
    with {:ok, recipe} <- fetch_recipe(key),
         {:ok, ingredients} <- load_ingredient_items(recipe.ingredients),
         {:ok, result_item} <- fetch_item_by_name(recipe.result_name),
         :ok <- ensure_has_ingredients(character_id, ingredients),
         {:ok, _} <-
           apply_crafting(character_id, ingredients, result_item, recipe.result_quantity) do
      {:ok, recipe}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Smelts a furnace recipe identified by `key` for the given character.
  """
  def smelt(character_id, key) do
    with {:ok, recipe} <- fetch_furnace_recipe(key),
         true <- has_required_ore?(character_id, recipe.ore) || {:error, :insufficient_materials},
         {:ok, ore_item} <- fetch_item_by_name(recipe.ore.name),
         {:ok, fuel_choice} <- choose_fuel(character_id, recipe.fuel_options),
         {:ok, result_item} <- fetch_item_by_name(recipe.result_name),
         {:ok, _} <-
           apply_smelt(
             character_id,
             ore_item.id,
             recipe.ore.quantity,
             fuel_choice,
             result_item,
             recipe.result_quantity
           ) do
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
    recipe_materials = recipes() |> Enum.flat_map(&ingredient_names/1)
    names = recipe_materials ++ furnace_material_names()
    canonical_lookup = Enum.into(names, %{}, fn name -> {name, canonical_item_name(name)} end)
    query_names = canonical_lookup |> Map.values() |> Enum.uniq()

    if names == [] do
      %{}
    else
      raw_counts =
        from(ci in CharacterInventory,
          join: item in Item,
          on: ci.item_id == item.id,
          where:
            ci.character_id == ^character_id and item.name in ^query_names and
              ci.equipped == false,
          group_by: item.name,
          select: {item.name, coalesce(sum(ci.quantity), 0)}
        )
        |> Repo.all()
        |> Map.new()

      Enum.reduce(canonical_lookup, %{}, fn {display, canonical}, acc ->
        Map.put(acc, display, Map.get(raw_counts, canonical, 0))
      end)
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

  defp decorate_furnace_recipes(material_counts) do
    Enum.map(@furnace_recipes, fn recipe ->
      ore_available = Map.get(material_counts, recipe.ore.name, 0)

      fuel_options =
        Enum.map(recipe.fuel_options, fn fuel ->
          available = Map.get(material_counts, fuel.name, 0)
          Map.put(fuel, :available, available)
        end)

      can_smelt? =
        ore_available >= recipe.ore.quantity and
          Enum.any?(fuel_options, &(&1.available >= &1.quantity))

      recipe
      |> Map.put(:ore, Map.put(recipe.ore, :available, ore_available))
      |> Map.put(:fuel_options, fuel_options)
      |> Map.put(:can_smelt?, can_smelt?)
    end)
  end

  defp ingredient_names(recipe) do
    Enum.map(recipe.ingredients, & &1.name)
  end

  defp furnace_material_names do
    Enum.flat_map(@furnace_recipes, fn recipe ->
      [recipe.ore.name | Enum.map(recipe.fuel_options, & &1.name)]
    end)
  end

  defp fetch_recipe(key) do
    case Enum.find(@recipes, &(&1.key == key)) do
      nil -> {:error, :unknown_recipe}
      recipe -> {:ok, recipe}
    end
  end

  defp fetch_furnace_recipe(key) do
    case Enum.find(@furnace_recipes, &(&1.key == key)) do
      nil -> {:error, :unknown_recipe}
      recipe -> {:ok, recipe}
    end
  end

  defp load_ingredient_items(ingredients) do
    Enum.reduce_while(ingredients, {:ok, []}, fn ingredient, {:ok, acc} ->
      lookup_name = canonical_item_name(ingredient.name)

      case fetch_item_by_name(lookup_name) do
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
      sellable: true,
      effects: Map.get(spec, :effects, %{})
    }
  end

  defp name_taken?(%Ecto.Changeset{errors: errors}) do
    Enum.any?(errors, fn
      {:name, {_, [constraint: :unique, constraint_name: _]}} -> true
      _ -> false
    end)
  end

  defp name_taken?(_), do: false

  defp has_required_ore?(character_id, %{name: name, quantity: quantity}) do
    Items.get_character_item_quantity(character_id, name) >= quantity
  end

  defp choose_fuel(character_id, fuel_options) do
    fuel_options
    |> Enum.sort_by(&fuel_priority/1)
    |> Enum.reduce_while(nil, fn option, _acc ->
      available = Items.get_character_item_quantity(character_id, option.name)

      if available >= option.quantity do
        case fetch_item_by_name(option.name) do
          {:ok, item} ->
            {:halt, {:ok, Map.put(option, :item, item)}}

          {:error, reason} ->
            {:halt, {:error, reason}}
        end
      else
        {:cont, nil}
      end
    end)
    |> case do
      {:ok, fuel} -> {:ok, fuel}
      {:error, reason} -> {:error, reason}
      nil -> {:error, :insufficient_fuel}
    end
  end

  defp fuel_priority(%{name: "Coal"}), do: 0
  defp fuel_priority(_), do: 1

  defp apply_smelt(character_id, ore_item_id, ore_quantity, fuel_choice, result_item, quantity) do
    Repo.transaction(fn ->
      case remove_item_quantity(character_id, ore_item_id, ore_quantity) do
        :ok ->
          case remove_item_quantity(character_id, fuel_choice.item.id, fuel_choice.quantity) do
            :ok ->
              case Items.add_item_to_inventory(character_id, result_item.id, quantity) do
                {:ok, _} -> :ok
                {:error, reason} -> Repo.rollback(reason)
              end

            {:error, reason} ->
              Repo.rollback(reason)
          end

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
    |> case do
      {:ok, _} -> {:ok, :smelted}
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_has_ingredients(character_id, ingredients) do
    has_all? =
      Enum.all?(ingredients, fn ingredient ->
        Items.get_character_item_quantity(
          character_id,
          canonical_item_name(ingredient.name)
        ) >= ingredient.quantity
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

  defp canonical_item_name("Gem"), do: "Gemstone"
  defp canonical_item_name(name), do: name
end
