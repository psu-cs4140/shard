defmodule Shard.Mining do
  @moduledoc """
  The Mining context - handles all mining logic and operations.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo
  alias Shard.Characters
  alias Shard.Characters.Character
  alias Shard.Mining.MiningInventory
  alias Shard.Items
  alias Shard.Items.Item

  # Resource probabilities (weights)
  @resource_weights [
    {:stone, 40},
    {:coal, 30},
    {:copper, 15},
    {:iron, 14},
    {:gem, 1}
  ]

  # Gold values for each resource (for future selling)
  @gold_values %{
    stone: 1,
    coal: 2,
    copper: 4,
    iron: 8,
    gem: 20
  }

  # Tick interval in seconds
  @tick_interval 6

  @doc """
  Starts mining for a character.

  If the character is already mining, returns {:ok, character} (idempotent).
  Otherwise, sets is_mining to true and mining_started_at to current UTC time.

  ## Examples

      iex> start_mining(character)
      {:ok, %Character{is_mining: true}}

  """
  @spec start_mining(Character.t()) ::
          {:ok, Character.t()} | {:error, Ecto.Changeset.t() | term()}
  def start_mining(%Character{is_mining: true} = character) do
    # Already mining, return as-is (idempotent)
    {:ok, character}
  end

  def start_mining(%Character{} = character) do
    character
    |> Character.changeset(%{
      is_mining: true,
      mining_started_at: DateTime.utc_now()
    })
    |> Repo.update()
  end

  @doc """
  Stops mining for a character.

  Applies any pending mining ticks, then sets is_mining to false and
  mining_started_at to nil.

  ## Examples

      iex> stop_mining(character)
      {:ok, %{character: character, mining_inventory: inventory, ticks_applied: 5}}

  """
  @spec stop_mining(Character.t()) ::
          {:ok,
           %{
             character: Character.t(),
             mining_inventory: MiningInventory.t(),
             ticks_applied: non_neg_integer()
           }}
          | {:error, term()}
  def stop_mining(%Character{} = character) do
    # First apply any pending ticks
    case apply_mining_ticks(character) do
      {:ok, %{character: updated_char, mining_inventory: inventory, ticks_applied: ticks}} ->
        # Now stop mining
        case Characters.update_character(updated_char, %{
               is_mining: false,
               mining_started_at: nil
             }) do
          {:ok, final_character} ->
            {:ok,
             %{character: final_character, mining_inventory: inventory, ticks_applied: ticks}}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Applies mining ticks based on elapsed time since mining started.

  Each tick is 6 seconds. Calculates how many ticks have elapsed,
  rolls for resources for each tick, and updates the mining inventory.

  ## Examples

      iex> apply_mining_ticks(character)
      {:ok, %{character: character, mining_inventory: inventory, ticks_applied: 3}}

  """
  @spec apply_mining_ticks(Character.t()) ::
          {:ok,
           %{
             character: Character.t(),
             mining_inventory: MiningInventory.t(),
             ticks_applied: non_neg_integer()
           }}
          | {:error, term()}
  def apply_mining_ticks(%Character{is_mining: false} = character) do
    # Not mining, return inventory unchanged
    case get_or_create_mining_inventory(character) do
      {:ok, inventory} ->
        {:ok,
         %{
           character: character,
           mining_inventory: inventory,
           ticks_applied: 0,
           gained_resources: %{},
           pet_messages: []
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def apply_mining_ticks(%Character{mining_started_at: nil} = character) do
    # No start time, return inventory unchanged
    case get_or_create_mining_inventory(character) do
      {:ok, inventory} ->
        {:ok,
         %{
           character: character,
           mining_inventory: inventory,
           ticks_applied: 0,
           gained_resources: %{},
           pet_messages: []
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def apply_mining_ticks(%Character{is_mining: true, mining_started_at: started_at} = character) do
    now = DateTime.utc_now()
    elapsed_seconds = DateTime.diff(now, started_at, :second)
    ticks = div(elapsed_seconds, @tick_interval)

    if ticks <= 0 do
      # No ticks to apply
      case get_or_create_mining_inventory(character) do
        {:ok, inventory} ->
          {:ok,
           %{
             character: character,
             mining_inventory: inventory,
             ticks_applied: 0,
             gained_resources: %{}
           }}

        {:error, reason} ->
          {:error, reason}
      end
    else
      # Roll resources for each tick
      resources = roll_multiple_resources(ticks, character)

      # Get or create inventory
      case get_or_create_mining_inventory(character) do
        {:ok, inventory} ->
          # Add resources to inventory
          case add_resources(inventory, resources) do
            {:ok, updated_inventory} ->
              add_resources_to_character_inventory(character, resources)
              # Update character's mining_started_at to now
              {character_after_pet, pet_level_messages} =
                maybe_grant_pet_xp(character, ticks)

              case Characters.update_character(character_after_pet, %{mining_started_at: now}) do
                {:ok, updated_character} ->
                  {updated_character, pet_drop_message} = maybe_drop_pet_rock(updated_character)

                  pet_messages =
                    pet_level_messages
                    |> Enum.reject(&is_nil/1)
                    |> Kernel.++((pet_drop_message && [pet_drop_message]) || [])

                  {:ok,
                   %{
                     character: updated_character,
                     mining_inventory: updated_inventory,
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

  @doc """
  Gets or creates a mining inventory for a character.

  ## Examples

      iex> get_or_create_mining_inventory(character)
      {:ok, %MiningInventory{}}

  """
  @spec get_or_create_mining_inventory(Character.t()) ::
          {:ok, MiningInventory.t()} | {:error, term()}
  def get_or_create_mining_inventory(%Character{id: character_id}) do
    case Repo.get_by(MiningInventory, character_id: character_id) do
      nil ->
        # Create new inventory
        %MiningInventory{}
        |> MiningInventory.changeset(%{
          character_id: character_id,
          stone: 0,
          coal: 0,
          copper: 0,
          iron: 0,
          gems: 0
        })
        |> Repo.insert()

      inventory ->
        {:ok, inventory}
    end
  end

  @doc """
  Rolls a single resource based on weighted probabilities.

  ## Examples

      iex> roll_resource()
      :stone

  """
  @spec roll_resource() :: :stone | :coal | :copper | :iron | :gem
  def roll_resource do
    total_weight =
      Enum.reduce(@resource_weights, 0, fn {_resource, weight}, acc -> acc + weight end)

    rand = :rand.uniform(total_weight)

    {resource, _} =
      Enum.reduce_while(@resource_weights, {nil, 0}, fn {resource, weight},
                                                        {_current, accumulated} ->
        new_accumulated = accumulated + weight

        if rand <= new_accumulated do
          {:halt, {resource, new_accumulated}}
        else
          {:cont, {resource, new_accumulated}}
        end
      end)

    resource
  end

  @doc """
  Rolls multiple resources and aggregates them into a map.

  ## Examples

      iex> roll_multiple_resources(10)
      %{stone: 4, coal: 3, copper: 2, iron: 1, gem: 0}

  """
  @spec roll_multiple_resources(non_neg_integer(), Character.t()) :: %{
          optional(atom()) => non_neg_integer()
        }
  def roll_multiple_resources(count, character) do
    Enum.reduce(1..count, %{stone: 0, coal: 0, copper: 0, iron: 0, gem: 0}, fn _, acc ->
      resource = roll_resource()

      bonus =
        if character.has_pet_rock do
          chance = pet_double_chance(character.pet_rock_level)

          if :rand.uniform(100) <= chance, do: 1, else: 0
        else
          0
        end

      Map.update(acc, resource, 1 + bonus, &(&1 + 1 + bonus))
    end)
  end

  @doc """
  Adds resources to a mining inventory.

  ## Examples

      iex> add_resources(inventory, %{stone: 5, coal: 3})
      {:ok, %MiningInventory{stone: 5, coal: 3}}

  """
  @spec add_resources(MiningInventory.t(), %{optional(atom()) => non_neg_integer()}) ::
          {:ok, MiningInventory.t()} | {:error, Ecto.Changeset.t() | term()}
  def add_resources(%MiningInventory{} = inventory, resources) when is_map(resources) do
    # Build updates map from resources
    updates = %{
      stone: (inventory.stone || 0) + Map.get(resources, :stone, 0),
      coal: (inventory.coal || 0) + Map.get(resources, :coal, 0),
      copper: (inventory.copper || 0) + Map.get(resources, :copper, 0),
      iron: (inventory.iron || 0) + Map.get(resources, :iron, 0),
      gems: (inventory.gems || 0) + Map.get(resources, :gem, 0)
    }

    inventory
    |> MiningInventory.changeset(updates)
    |> Repo.update()
  end

  defp add_resources_to_character_inventory(%Character{id: character_id}, resources) do
    resource_items = ensure_resource_items()

    Enum.each(resources, fn
      {:stone, qty} when qty > 0 ->
        Items.add_item_to_inventory(character_id, resource_items.stone.id, qty)

      {:coal, qty} when qty > 0 ->
        Items.add_item_to_inventory(character_id, resource_items.coal.id, qty)

      {:copper, qty} when qty > 0 ->
        Items.add_item_to_inventory(character_id, resource_items.copper.id, qty)

      {:iron, qty} when qty > 0 ->
        Items.add_item_to_inventory(character_id, resource_items.iron.id, qty)

      {:gem, qty} when qty > 0 ->
        Items.add_item_to_inventory(character_id, resource_items.gem.id, qty)

      _ ->
        :ok
    end)
  end

  defp ensure_resource_items do
    %{
      stone: fetch_or_create_item("Stone", 1),
      coal: fetch_or_create_item("Coal", 2),
      copper: fetch_or_create_item("Copper Ore", 4),
      iron: fetch_or_create_item("Iron Ore", 8),
      gem: fetch_or_create_item("Gemstone", 20)
    }
  end

  defp fetch_or_create_item(name, value) do
    case Repo.get_by(Item, name: name) do
      nil ->
        {:ok, item} =
          %Item{}
          |> Item.changeset(%{
            name: name,
            description: "Resource gathered from mining.",
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
    end
  end

  @doc """
  Calculates the total gold value of a mining inventory.

  ## Examples

      iex> total_gold_value(inventory)
      150

  """
  @spec total_gold_value(MiningInventory.t()) :: non_neg_integer()
  def total_gold_value(%MiningInventory{} = inventory) do
    (inventory.stone || 0) * @gold_values.stone +
      (inventory.coal || 0) * @gold_values.coal +
      (inventory.copper || 0) * @gold_values.copper +
      (inventory.iron || 0) * @gold_values.iron +
      (inventory.gems || 0) * @gold_values.gem
  end

  @doc """
  Gets the mining status for a character.

  Returns a map with mining state and current inventory.

  ## Examples

      iex> get_mining_status(character)
      {:ok, %{is_mining: true, mining_inventory: %MiningInventory{}, ticks_pending: 2}}

  """
  @spec get_mining_status(Character.t()) ::
          {:ok,
           %{
             is_mining: boolean(),
             mining_inventory: MiningInventory.t(),
             ticks_pending: non_neg_integer()
           }}
          | {:error, term()}
  def get_mining_status(%Character{} = character) do
    case get_or_create_mining_inventory(character) do
      {:ok, inventory} ->
        ticks_pending = calculate_pending_ticks(character)

        {:ok,
         %{
           is_mining: character.is_mining,
           mining_inventory: inventory,
           ticks_pending: ticks_pending
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Calculates how many ticks are pending for a character.

  ## Examples

      iex> calculate_pending_ticks(character)
      3

  """
  @spec calculate_pending_ticks(Character.t()) :: non_neg_integer()
  def calculate_pending_ticks(%Character{is_mining: false}), do: 0
  def calculate_pending_ticks(%Character{mining_started_at: nil}), do: 0

  def calculate_pending_ticks(%Character{is_mining: true, mining_started_at: started_at}) do
    now = DateTime.utc_now()
    elapsed_seconds = DateTime.diff(now, started_at, :second)
    div(elapsed_seconds, @tick_interval)
  end

  defp pet_double_chance(level) do
    min(10 + (level - 1), 50)
  end

  defp maybe_grant_pet_xp(%Character{has_pet_rock: false} = character, _ticks),
    do: {character, []}

  defp maybe_grant_pet_xp(%Character{} = character, ticks) do
    xp = character.pet_rock_xp + ticks
    {level, remaining_xp, level_messages} = level_up_pet(character.pet_rock_level, xp, "Pet Rock")

    updated =
      if level != character.pet_rock_level or remaining_xp != character.pet_rock_xp do
        {:ok, c} =
          Characters.update_character(character, %{
            pet_rock_level: level,
            pet_rock_xp: remaining_xp
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
    end
  end

  defp maybe_drop_pet_rock(%Character{has_pet_rock: true} = character), do: {character, nil}

  defp maybe_drop_pet_rock(%Character{} = character) do
    if :rand.uniform(500) == 1 do
      case Characters.update_character(character, %{has_pet_rock: true}) do
        {:ok, updated} ->
          {updated,
           "Wow! You found a pet rock! Rumor has it that it sometimes doubles your mining haul."}

        _ ->
          {character, nil}
      end
    else
      {character, nil}
    end
  end
end
