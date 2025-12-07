defmodule Shard.Items.LootBoxSystem do
  @moduledoc """
  System for managing loot box creation, purchasing, and rewards.
  """

  alias Shard.Items
  alias Shard.Repo

  @doc """
  Creates all standard loot box types in the database.
  Call this once to populate the marketplace with loot boxes.
  """
  def create_standard_loot_boxes do
    rarities = ["common", "uncommon", "rare", "epic", "legendary"]
    
    Enum.map(rarities, fn rarity ->
      case Items.create_loot_box(rarity) do
        {:ok, loot_box} -> 
          {:ok, loot_box}
        {:error, changeset} -> 
          # Check if it already exists
          existing = Repo.get_by(Items.Item, name: "#{String.capitalize(rarity)} Loot Box")
          if existing do
            {:ok, existing}
          else
            {:error, changeset}
          end
      end
    end)
  end

  @doc """
  Gets all available loot boxes for the marketplace.
  """
  def get_marketplace_loot_boxes do
    from(i in Items.Item,
      where: i.item_type == "loot_box" and i.is_active == true,
      order_by: [asc: i.value]
    )
    |> Repo.all()
  end

  @doc """
  Purchases a loot box for a character.
  Deducts gold and adds the loot box to inventory.
  """
  def purchase_loot_box(character_id, loot_box_id) do
    alias Ecto.Multi
    alias Shard.Characters

    loot_box = Items.get_item!(loot_box_id)
    character = Characters.get_character!(character_id)

    cond do
      loot_box.item_type != "loot_box" ->
        {:error, :not_a_loot_box}

      character.gold < loot_box.value ->
        {:error, :insufficient_gold}

      true ->
        Multi.new()
        |> Multi.run(:deduct_gold, fn _repo, _changes ->
          Characters.update_character(character, %{
            gold: character.gold - loot_box.value
          })
        end)
        |> Multi.run(:add_loot_box, fn _repo, _changes ->
          Items.add_item_to_inventory(character_id, loot_box_id, 1)
        end)
        |> Repo.transaction()
        |> case do
          {:ok, %{add_loot_box: inventory_item, deduct_gold: updated_character}} ->
            {:ok, %{
              character: updated_character,
              loot_box: inventory_item,
              cost: loot_box.value
            }}

          {:error, _operation, reason, _changes} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Gets loot box statistics for display.
  """
  def get_loot_box_stats(rarity) do
    %{
      price: Items.get_loot_box_price(rarity),
      gold_range: Items.get_gold_range(rarity),
      exp_range: Items.get_exp_range(rarity),
      item_count_range: Items.get_item_count_range(rarity),
      bonus_chance: Items.get_bonus_chance(rarity)
    }
  end

  @doc """
  Preview what rewards a loot box might contain (for UI display).
  """
  def preview_loot_box_rewards(rarity) do
    %{
      guaranteed: %{
        gold: "#{Enum.at(Items.get_gold_range(rarity), 0)}-#{Enum.at(Items.get_gold_range(rarity), 1)} gold",
        experience: "#{Enum.at(Items.get_exp_range(rarity), 0)}-#{Enum.at(Items.get_exp_range(rarity), 1)} XP",
        items: "#{Enum.at(Items.get_item_count_range(rarity), 0)}-#{Enum.at(Items.get_item_count_range(rarity), 1)} items"
      },
      bonus_chance: "#{trunc(Items.get_bonus_chance(rarity) * 100)}% chance for bonus gold"
    }
  end
end
