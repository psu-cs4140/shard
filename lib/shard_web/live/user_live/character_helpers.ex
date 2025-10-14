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

  # Load character inventory from database
  def load_character_inventory(character) do
    try do
      # Check if character_inventories is loaded and has items
      case Map.get(character, :character_inventories) do
        inventories when is_list(inventories) ->
          loaded_items =
            Enum.map(inventories, fn inventory ->
              item = Shard.Repo.get(Shard.Items.Item, inventory.item_id)

              if item do
                %{
                  id: item.id,
                  name: item.name,
                  type: item.item_type || "misc",
                  quantity: inventory.quantity,
                  damage: item.damage,
                  defense: item.defense,
                  effect: item.effect,
                  description: item.description
                }
              else
                nil
              end
            end)
            |> Enum.filter(&(&1 != nil))

          loaded_items

        _ ->
          # Return empty list if no inventory loaded or association not loaded
          []
      end
    rescue
      _ ->
        # Return empty list on error instead of fallback items
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
              damage: item.damage || "1d6",
              type: "weapon"
            }
          else
            # Default weapon
            %{name: "Fists", damage: "1d4", type: "unarmed"}
          end

        _ ->
          %{name: "Fists", damage: "1d4", type: "unarmed"}
      end
    rescue
      _ ->
        %{name: "Fists", damage: "1d4", type: "unarmed"}
    end
  end

  # Load character hotbar from database
  def load_character_hotbar(character) do
    try do
      case character.hotbar_slots do
        slots when is_list(slots) ->
          # Convert list of hotbar slots to map
          hotbar_map =
            Enum.reduce(1..5, %{}, fn slot_num, acc ->
              slot_key = String.to_atom("slot_#{slot_num}")

              slot_data = Enum.find(slots, fn slot -> slot.slot_number == slot_num end)

              slot_content =
                if slot_data && slot_data.item_id do
                  item = Shard.Repo.get(Shard.Items.Item, slot_data.item_id)

                  if item do
                    %{
                      id: item.id,
                      name: item.name,
                      type: item.item_type || "misc",
                      damage: item.damage,
                      effect: item.effect
                    }
                  else
                    nil
                  end
                else
                  nil
                end

              Map.put(acc, slot_key, slot_content)
            end)

          hotbar_map

        _ ->
          # Empty hotbar if no slots loaded
          %{
            slot_1: nil,
            slot_2: nil,
            slot_3: nil,
            slot_4: nil,
            slot_5: nil
          }
      end
    rescue
      _ ->
        # Empty hotbar on error
        %{
          slot_1: nil,
          slot_2: nil,
          slot_3: nil,
          slot_4: nil,
          slot_5: nil
        }
    end
  end
end
