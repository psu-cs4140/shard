defmodule Shard.Forest do
  @moduledoc """
  The Forest context - handles chopping logic and operations.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo
  alias Shard.Characters
  alias Shard.Characters.Character
  alias Shard.Forest.ChoppingInventory
  alias Shard.Items
  alias Shard.Items.Item

  @resource_weights [
    {:wood, 40},
    {:sticks, 30},
    {:seeds, 10},
    {:mushrooms, 12},
    {:resin, 8}
  ]

  @tick_interval 6

  @spec start_chopping(Character.t()) ::
          {:ok, Character.t()} | {:error, Ecto.Changeset.t() | term()}
  def start_chopping(%Character{is_chopping: true} = character) do
    {:ok, character}
  end

  def start_chopping(%Character{} = character) do
    character
    |> Character.changeset(%{
      is_chopping: true,
      chopping_started_at: DateTime.utc_now()
    })
    |> Repo.update()
  end

  @spec stop_chopping(Character.t()) ::
          {:ok,
           %{
             character: Character.t(),
             chopping_inventory: ChoppingInventory.t(),
             ticks_applied: non_neg_integer(),
             gained_resources: map()
           }}
          | {:error, term()}
  def stop_chopping(%Character{} = character) do
    case apply_chopping_ticks(character) do
      {:ok,
       %{
         character: updated_char,
         chopping_inventory: inventory,
         ticks_applied: ticks,
         gained_resources: gained
       }} ->
        case Characters.update_character(updated_char, %{
               is_chopping: false,
               chopping_started_at: nil
             }) do
          {:ok, final_character} ->
            {:ok,
             %{
               character: final_character,
               chopping_inventory: inventory,
               ticks_applied: ticks,
               gained_resources: gained
             }}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec apply_chopping_ticks(Character.t()) ::
          {:ok,
           %{
             character: Character.t(),
             chopping_inventory: ChoppingInventory.t(),
             ticks_applied: non_neg_integer(),
             gained_resources: map()
           }}
          | {:error, term()}
  def apply_chopping_ticks(%Character{is_chopping: false} = character) do
    case get_or_create_chopping_inventory(character) do
      {:ok, inventory} ->
        {:ok,
         %{
           character: character,
           chopping_inventory: inventory,
           ticks_applied: 0,
           gained_resources: %{},
           pet_messages: []
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def apply_chopping_ticks(%Character{chopping_started_at: nil} = character) do
    case get_or_create_chopping_inventory(character) do
      {:ok, inventory} ->
        {:ok,
         %{
           character: character,
           chopping_inventory: inventory,
           ticks_applied: 0,
           gained_resources: %{},
           pet_messages: []
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def apply_chopping_ticks(
        %Character{is_chopping: true, chopping_started_at: started_at} = character
      ) do
    now = DateTime.utc_now()
    elapsed_seconds = DateTime.diff(now, started_at, :second)
    ticks = div(elapsed_seconds, @tick_interval)

    if ticks <= 0 do
      case get_or_create_chopping_inventory(character) do
        {:ok, inventory} ->
          {:ok,
           %{
             character: character,
             chopping_inventory: inventory,
             ticks_applied: 0,
             gained_resources: %{},
             pet_messages: []
           }}

        {:error, reason} ->
          {:error, reason}
      end
    else
      resources = roll_multiple_resources(ticks, character)

      case get_or_create_chopping_inventory(character) do
        {:ok, inventory} ->
          case add_resources(inventory, resources) do
            {:ok, updated_inventory} ->
              {character_after_xp, pet_level_messages} = maybe_grant_pet_xp(character, ticks)

              case Characters.update_character(character_after_xp, %{chopping_started_at: now}) do
                {:ok, updated_character} ->
                  {char_after_drop, pet_message} = maybe_drop_shroomling(updated_character)

                  pet_messages =
                    pet_level_messages
                    |> Enum.reject(&is_nil/1)
                    |> Kernel.++((pet_message && [pet_message]) || [])

                  {:ok,
                   %{
                     character: char_after_drop,
                     chopping_inventory: updated_inventory,
                     ticks_applied: ticks,
                     gained_resources: resources,
                     pet_messages: pet_messages
                   }}

                {:error, reason} ->
                  {:error, reason}
              end

            {:error, reason} ->
              {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @spec get_or_create_chopping_inventory(Character.t()) ::
          {:ok, ChoppingInventory.t()} | {:error, term()}
  def get_or_create_chopping_inventory(%Character{id: character_id}) do
    case Repo.get_by(ChoppingInventory, character_id: character_id) do
      nil ->
        %ChoppingInventory{}
        |> ChoppingInventory.changeset(%{
          character_id: character_id,
          wood: 0,
          sticks: 0,
          seeds: 0,
          mushrooms: 0,
          resin: 0
        })
        |> Repo.insert()

      inventory ->
        {:ok, inventory}
    end
  end

  @spec roll_resource() :: :wood | :sticks | :seeds | :mushrooms | :resin
  def roll_resource do
    total_weight =
      Enum.reduce(@resource_weights, 0, fn {_resource, weight}, acc -> acc + weight end)

    rand = :rand.uniform(total_weight)

    {resource, _} =
      Enum.reduce_while(
        @resource_weights,
        {nil, 0},
        fn {resource, weight}, {_current, accumulated} ->
          new_accumulated = accumulated + weight

          if rand <= new_accumulated do
            {:halt, {resource, new_accumulated}}
          else
            {:cont, {resource, new_accumulated}}
          end
        end
      )

    resource
  end

  @spec roll_multiple_resources(non_neg_integer(), Character.t()) :: %{
          optional(atom()) => non_neg_integer()
        }
  def roll_multiple_resources(count, character) do
    1..count
    |> Enum.reduce(%{wood: 0, sticks: 0, seeds: 0, mushrooms: 0, resin: 0}, fn _, acc ->
      resource = roll_resource()

      bonus =
        if character.has_shroomling do
          chance = pet_double_chance(character.shroomling_level)
          if :rand.uniform(100) <= chance, do: 1, else: 0
        else
          0
        end

      Map.update(acc, resource, 1 + bonus, &(&1 + 1 + bonus))
    end)
  end

  @spec add_resources(ChoppingInventory.t(), %{optional(atom()) => non_neg_integer()}) ::
          {:ok, ChoppingInventory.t()} | {:error, Ecto.Changeset.t() | term()}
  def add_resources(%ChoppingInventory{} = inventory, resources) when is_map(resources) do
    updates = %{
      wood: (inventory.wood || 0) + Map.get(resources, :wood, 0),
      sticks: (inventory.sticks || 0) + Map.get(resources, :sticks, 0),
      seeds: (inventory.seeds || 0) + Map.get(resources, :seeds, 0),
      mushrooms: (inventory.mushrooms || 0) + Map.get(resources, :mushrooms, 0),
      resin: (inventory.resin || 0) + Map.get(resources, :resin, 0)
    }

    inventory
    |> ChoppingInventory.changeset(updates)
    |> Repo.update()
  end

  @spec calculate_pending_ticks(Character.t()) :: non_neg_integer()
  def calculate_pending_ticks(%Character{is_chopping: false}), do: 0
  def calculate_pending_ticks(%Character{chopping_started_at: nil}), do: 0

  def calculate_pending_ticks(%Character{is_chopping: true, chopping_started_at: started_at}) do
    now = DateTime.utc_now()
    elapsed_seconds = DateTime.diff(now, started_at, :second)
    div(elapsed_seconds, @tick_interval)
  end

<<<<<<< HEAD
  defp add_resources_to_character_inventory(%Character{id: character_id}, resources) do
    resource_items = ensure_chopping_resource_items()

    Enum.each(resources, fn
      {:wood, qty} when qty > 0 ->
        Items.add_item_to_inventory(character_id, resource_items.wood.id, qty)

      {:sticks, qty} when qty > 0 ->
        Items.add_item_to_inventory(character_id, resource_items.sticks.id, qty)

      {:seeds, qty} when qty > 0 ->
        Items.add_item_to_inventory(character_id, resource_items.seeds.id, qty)

      {:mushrooms, qty} when qty > 0 ->
        Items.add_item_to_inventory(character_id, resource_items.mushrooms.id, qty)

      {:resin, qty} when qty > 0 ->
        Items.add_item_to_inventory(character_id, resource_items.resin.id, qty)

      _ ->
        :ok
    end)
  end

  defp ensure_chopping_resource_items do
    %{
      wood: fetch_or_create_item("Wood", 1),
      sticks: fetch_or_create_item("Stick", 1),
      seeds: fetch_or_create_item("Forest Seeds", 2),
      mushrooms: fetch_or_create_item("Mushroom", 3),
      resin: fetch_or_create_item("Forest Resin", 5)
    }
  end

  defp fetch_or_create_item(name, value) do
    case Repo.get_by(Item, name: name) do
      nil ->
        {:ok, item} =
          %Item{}
          |> Item.changeset(%{
            name: name,
            description: "Gathered from the Whispering Forest.",
            item_type: "material",
            rarity: "common",
            value: value,
            stackable: true,
            max_stack_size: 99,
            is_active: true
          })
          |> Repo.insert()

        item

      item ->
        item
=======
  defp pet_double_chance(level) do
    min(10 + (level - 1), 50)
  end

  defp maybe_grant_pet_xp(%Character{has_shroomling: false} = character, _ticks),
    do: {character, []}

  defp maybe_grant_pet_xp(%Character{} = character, ticks) do
    xp = character.shroomling_xp + ticks

    {level, remaining_xp, level_messages} =
      level_up_pet(character.shroomling_level, xp, "Shroomling")

    updated =
      if level != character.shroomling_level or remaining_xp != character.shroomling_xp do
        {:ok, c} =
          Characters.update_character(character, %{
            shroomling_level: level,
            shroomling_xp: remaining_xp
          })

        c
      else
        character
      end

    {updated, level_messages}
  end

  defp level_up_pet(level, xp, pet_name) do
    required = 100 + (level - 1) * 20

    if xp >= required do
      new_level = level + 1
      {final_level, remaining_xp, messages} = level_up_pet(new_level, xp - required, pet_name)
      chance = pet_double_chance(final_level)

      message =
        "Your #{pet_name} levels up! It is now Level #{final_level}. Double chance increased to #{chance}%."

      {final_level, remaining_xp, [message | messages]}
    else
      {level, xp, []}
>>>>>>> 92f16d0 (Add a leveling system to the pets that increase buffs)
    end
  end

  defp maybe_drop_shroomling(%Character{has_shroomling: true} = character), do: {character, nil}

  defp maybe_drop_shroomling(%Character{} = character) do
    if :rand.uniform(500) == 1 do
      case Characters.update_character(character, %{has_shroomling: true}) do
        {:ok, updated} ->
          {updated,
           "A mischievous Shroomling appears and begins following you. He will sometimes help you out by doubling your resources. *If it feels like it*."}

        _ ->
          {character, nil}
      end
    else
      {character, nil}
    end
  end
end
