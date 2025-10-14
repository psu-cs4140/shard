defmodule ShardWeb.UserLive.MonsterComponents do
  @moduledoc """
  Monster-related functionality for the MUD game.
  """

  @doc """
  Load monsters from database and convert them to game format.
  """
  def load_monsters_from_database(map_id, starting_position) do
    try do
      # Get all monsters from database
      monsters = Shard.Monsters.list_monsters()

      # Convert database monsters to game format
      Enum.map(monsters, fn monster ->
        # Use monster's location if available, otherwise place randomly
        position =
          if monster.location_id do
            # Try to get room coordinates from location_id
            case Shard.Map.get_room!(monster.location_id) do
              room when not is_nil(room.x_coordinate) and not is_nil(room.y_coordinate) ->
                {room.x_coordinate, room.y_coordinate}

              _ ->
                # Fallback to a default position if room has no coordinates
                {1, 1}
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
          description: monster.description
        }
      end)
    rescue
      _ ->
        # Fallback to empty list if database query fails
        []
    end
  end
end
