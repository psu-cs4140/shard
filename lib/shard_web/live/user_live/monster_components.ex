defmodule ShardWeb.UserLive.MonsterComponents do
  @moduledoc """
  Monster-related functionality for the MUD game.
  """

  @doc """
  Load monsters from database and convert them to game format.
  """
  def load_monsters_from_database(zone_id, _starting_position) do
    try do
      # Get all monsters from database
      all_monsters = Shard.Monsters.list_monsters()

      # Filter monsters to only those in rooms within the specified zone
      monsters =
        Enum.filter(all_monsters, fn monster ->
          if monster.location_id do
            # Check if the monster's room belongs to the specified zone
            try do
              room = Shard.Map.get_room!(monster.location_id)
              room.zone_id == zone_id
            rescue
              _ -> false
            end
          else
            false
          end
        end)

      # Convert database monsters to game format
      Enum.map(monsters, fn monster ->
        # Use monster's location if available, otherwise place randomly
        position =
          if monster.location_id do
            # Try to get room coordinates from location_id
            try do
              room = Shard.Map.get_room!(monster.location_id)

              if not is_nil(room.x_coordinate) and not is_nil(room.y_coordinate) do
                {room.x_coordinate, room.y_coordinate}
              else
                {1, 1}
              end
            rescue
              _ -> {1, 1}
            end
          else
            # Place at a default location if no location_id
            {1, 1}
          end

        %{
          monster_id: monster.id,
          name: monster.name,
          level: monster.level,
          attack: monster.attack_damage,
          # Add defense field to monster schema if needed
          defense: 0,
          # Add speed field to monster schema if needed
          speed: 5,
          xp_reward: monster.xp_amount,
          # Add gold_reward field to monster schema if needed
          gold_reward: 0,
          # Add boss field to monster schema if needed
          boss: false,
          hp: monster.health,
          hp_max: monster.max_health,
          position: position,
          description: monster.description,
          # Special damage fields
          special_damage_type_id: monster.special_damage_type_id,
          special_damage_amount: monster.special_damage_amount,
          special_damage_duration: monster.special_damage_duration,
          special_damage_chance: monster.special_damage_chance
        }
      end)
    rescue
      _ ->
        # Fallback to empty list if database query fails
        []
    end
  end
end
