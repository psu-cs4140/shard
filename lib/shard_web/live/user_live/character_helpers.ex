defmodule ShardWeb.UserLive.CharacterHelpers do
  @moduledoc """
  Helper functions for character management in the MUD game.
  """

  # Helper function to calculate next level experience requirement
  def calculate_next_level_exp(level) do
    # Base experience + scaling factor based on level
    base_exp = 1000
    base_exp + (level - 1) * 500
  end

  # Function to save character stats back to database
  def save_character_stats(character, stats) do
    try do
      attrs = %{
        health: stats.health,
        mana: stats.mana,
        level: stats.level,
        experience: stats.experience,
        strength: stats.strength,
        dexterity: stats.dexterity,
        intelligence: stats.intelligence,
        constitution: stats.constitution || character.constitution || 10
      }

      Shard.Characters.update_character(character, attrs)
    rescue
      error ->
        # Log error but don't crash the game
        require Logger
        Logger.error("Failed to save character stats: #{inspect(error)}")
        {:error, error}
    end
  end

  # Check if stats have changed significantly enough to warrant a database save
  def stats_changed_significantly?(old_stats, new_stats) do
    # Save if level, experience, or core stats changed
    # Also save if health or mana drops significantly (combat damage/usage)
    old_stats.level != new_stats.level ||
      old_stats.experience != new_stats.experience ||
      old_stats.strength != new_stats.strength ||
      old_stats.dexterity != new_stats.dexterity ||
      old_stats.intelligence != new_stats.intelligence ||
      Map.get(old_stats, :constitution) != Map.get(new_stats, :constitution) ||
      abs(old_stats.health - new_stats.health) >= 10 ||
      abs(old_stats.mana - new_stats.mana) >= 15
  end

  # Load character inventory from database using the Items context
  def load_character_inventory(character) do
    try do
      # Use the proper Items context function to get inventory
      inventory_items = Shard.Items.get_character_inventory(character.id)

      # Transform to the format expected by the game state
      Enum.map(inventory_items, fn inventory ->
        %{
          inventory_id: inventory.id,
          id: inventory.item.id,
          name: inventory.item.name,
          item_type: inventory.item.item_type || "misc",
          quantity: inventory.quantity,
          damage:
            get_in(inventory.item.stats, ["damage"]) || get_in(inventory.item.effects, ["damage"]),
          defense:
            get_in(inventory.item.stats, ["defense"]) ||
              get_in(inventory.item.effects, ["defense"]),
          effect: get_in(inventory.item.effects, ["effect"]) || inventory.item.description,
          description: inventory.item.description,
          equipped: inventory.equipped || false,
          slot_position: inventory.slot_position
        }
      end)
    rescue
      error ->
        require Logger
        Logger.error("Failed to load character inventory: #{inspect(error)}")
        []
    end
  end

  # Load equipped weapon from database
  def load_equipped_weapon(character) do
    try do
      # Try to get equipped weapon from character data or inventory
      case character.character_inventories do
        inventories when is_list(inventories) ->
          equipped_weapon =
            Enum.find(inventories, fn inv ->
              item = Shard.Repo.get(Shard.Items.Item, inv.item_id)
              item && item.item_type == "weapon" && Map.get(inv, :equipped, false)
            end)

          if equipped_weapon do
            item = Shard.Repo.get(Shard.Items.Item, equipped_weapon.item_id)

            %{
              name: item.name,
              damage: get_in(item.stats, ["damage"]) || get_in(item.effects, ["damage"]) || "1d6",
              item_type: "weapon"
            }
          else
            # Default weapon
            %{name: "Fists", damage: "1d4", item_type: "unarmed"}
          end

        _ ->
          %{name: "Fists", damage: "1d4", item_type: "unarmed"}
      end
    rescue
      _ ->
        %{name: "Fists", damage: "1d4", item_type: "unarmed"}
    end
  end

  # Load character hotbar from database
  def load_character_hotbar(character) do
    try do
      case character.hotbar_slots do
        slots when is_list(slots) ->
          build_hotbar_from_slots(slots)

        _ ->
          empty_hotbar()
      end
    rescue
      _ ->
        empty_hotbar()
    end
  end

  # Helper function to build hotbar map from slots
  defp build_hotbar_from_slots(slots) do
    Enum.reduce(1..5, %{}, fn slot_num, acc ->
      slot_key = String.to_atom("slot_#{slot_num}")
      slot_data = Enum.find(slots, fn slot -> slot.slot_number == slot_num end)
      slot_content = build_slot_content(slot_data)
      Map.put(acc, slot_key, slot_content)
    end)
  end

  # Helper function to build content for a single hotbar slot
  defp build_slot_content(slot_data) do
    cond do
      is_nil(slot_data) ->
        nil

      is_nil(slot_data.item_id) ->
        nil

      true ->
        item = slot_data.item
        inventory = slot_data.inventory

        if item && slot_data.inventory_id && inventory do
          %{
            id: item.id,
            name: item.name,
            item_type: item.item_type || "misc",
            damage: get_in(item.stats, ["damage"]) || get_in(item.effects, ["damage"]),
            effect: get_in(item.effects, ["effect"]) || item.description,
            inventory_id: slot_data.inventory_id,
            quantity: inventory.quantity
          }
        else
          nil
        end
    end
  end

  # Helper function to return empty hotbar
  defp empty_hotbar do
    %{
      slot_1: nil,
      slot_2: nil,
      slot_3: nil,
      slot_4: nil,
      slot_5: nil
    }
  end
end
