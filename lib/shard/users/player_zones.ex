defmodule Shard.Users.PlayerZones do
  @moduledoc """
  Context for managing player zone instances.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo
  alias Shard.Users.PlayerZone
  alias Shard.Map.Zone
  alias Shard.{Monsters, Items}

  @doc """
  Gets or creates a zone instance for a user.
  
  If the user doesn't have an instance of the specified type for this zone,
  creates a new zone instance and associates it with the user.
  """
  def get_or_create_player_zone(user_id, zone_name, instance_type) do
    case get_player_zone(user_id, zone_name, instance_type) do
      nil ->
        create_player_zone_instance(user_id, zone_name, instance_type)
      
      player_zone ->
        {:ok, player_zone}
    end
  end

  @doc """
  Gets a player's zone instance.
  """
  def get_player_zone(user_id, zone_name, instance_type) do
    Repo.one(
      from pz in PlayerZone,
        where: pz.user_id == ^user_id and 
               pz.zone_name == ^zone_name and 
               pz.instance_type == ^instance_type,
        preload: [:zone]
    )
  end

  @doc """
  Lists all zone instances for a user.
  """
  def list_user_zones(user_id) do
    Repo.all(
      from pz in PlayerZone,
        where: pz.user_id == ^user_id,
        preload: [:zone],
        order_by: [asc: pz.zone_name, asc: pz.instance_type]
    )
  end

  defp create_player_zone_instance(user_id, zone_name, instance_type) do
    # Generate a unique zone_id for this instance
    zone_instance_id = generate_zone_instance_id(zone_name, instance_type, user_id)
    
    # Get the zone template (zone with matching name ending in "-template")
    zone_template = Repo.one(
      from z in Zone,
        where: z.name == ^zone_name and like(z.zone_id, "%-template"),
        limit: 1
    )
    
    if zone_template do
      # Create the zone instance using the template
      case create_zone_from_template(zone_template, zone_instance_id, instance_type) do
        {:ok, zone} ->
          # Create the player zone association
          player_zone_attrs = %{
            zone_name: zone_name,
            instance_type: instance_type,
            zone_instance_id: zone_instance_id,
            user_id: user_id,
            zone_id: zone.id
          }
          
          case create_player_zone(player_zone_attrs) do
            {:ok, player_zone} ->
              {:ok, Repo.preload(player_zone, :zone)}
            
            {:error, changeset} ->
              # Clean up the zone if player_zone creation failed
              Shard.Map.delete_zone(zone)
              {:error, changeset}
          end
        
        {:error, changeset} ->
          {:error, changeset}
      end
    else
      {:error, :zone_template_not_found}
    end
  end

  @doc """
  Creates a player zone association.
  """
  def create_player_zone(attrs \\ %{}) do
    %PlayerZone{}
    |> PlayerZone.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a player zone and its associated zone instance.
  """
  def delete_player_zone(%PlayerZone{} = player_zone) do
    Repo.transaction(fn ->
      # Delete the zone instance
      try do
        zone = Shard.Map.get_zone!(player_zone.zone_id)
        Shard.Map.delete_zone(zone)
      rescue
        Ecto.NoResultsError -> :ok
      end
      
      # Delete the player zone association
      Repo.delete(player_zone)
    end)
  end

  defp create_zone_from_template(template_zone, zone_instance_id, instance_type) do
    # Create the zone instance
    zone_attrs = %{
      name: template_zone.name,
      zone_id: zone_instance_id,
      slug: "#{template_zone.slug}-#{zone_instance_id}",
      description: template_zone.description,
      zone_type: template_zone.zone_type,
      min_level: template_zone.min_level,
      max_level: template_zone.max_level,
      is_public: instance_type == "multiplayer",
      is_active: true,
      properties: Kernel.put_in(template_zone.properties || %{}, ["instance_type"], instance_type),
      display_order: template_zone.display_order
    }
    
    case Shard.Map.create_zone(zone_attrs) do
      {:ok, new_zone} ->
        # Copy all rooms from the template zone
        template_rooms = Shard.Map.list_rooms_by_zone(template_zone.id)
        
        room_mapping = 
          Enum.reduce(template_rooms, %{}, fn template_room, acc ->
            room_attrs = %{
              name: template_room.name,
              description: template_room.description,
              zone_id: new_zone.id,
              x_coordinate: template_room.x_coordinate,
              y_coordinate: template_room.y_coordinate,
              z_coordinate: template_room.z_coordinate,
              is_public: template_room.is_public,
              room_type: template_room.room_type,
              properties: template_room.properties
            }
            
            case Shard.Map.create_room(room_attrs) do
              {:ok, new_room} ->
                Map.put(acc, template_room.id, new_room)
              {:error, _} ->
                acc
            end
          end)
        
        # Copy all doors from the template zone
        # Get doors by querying from the template rooms
        template_doors = 
          template_rooms
          |> Enum.flat_map(fn room ->
            Shard.Map.list_doors_from_room(room.id)
          end)
          |> Enum.uniq_by(& &1.id)
        
        Enum.each(template_doors, fn template_door ->
          from_room = Map.get(room_mapping, template_door.from_room_id)
          to_room = Map.get(room_mapping, template_door.to_room_id)
          
          if from_room && to_room do
            door_attrs = %{
              from_room_id: from_room.id,
              to_room_id: to_room.id,
              direction: template_door.direction,
              door_type: template_door.door_type,
              is_locked: template_door.is_locked,
              key_required: template_door.key_required,
              properties: template_door.properties
            }
            
            Shard.Map.create_door(door_attrs)
          end
        end)
        
        # Copy monsters from the template zone (if the function exists)
        try do
          # Get monsters from all rooms in the template zone
          template_monsters = 
            template_rooms
            |> Enum.flat_map(fn room -> 
              Shard.Monsters.list_monsters_by_location(room.id)
            end)
          
          Enum.each(template_monsters, fn template_monster ->
            new_room = Map.get(room_mapping, template_monster.location_id)
            
            if new_room do
              monster_attrs = %{
                name: template_monster.name,
                race: template_monster.race,
                health: template_monster.max_health,
                max_health: template_monster.max_health,
                attack_damage: template_monster.attack_damage,
                xp_amount: template_monster.xp_amount,
                level: template_monster.level,
                description: template_monster.description,
                location_id: new_room.id,
                potential_loot_drops: template_monster.potential_loot_drops
              }
              
              Shard.Monsters.create_monster(monster_attrs)
            end
          end)
        rescue
          UndefinedFunctionError -> :ok
        end
        
        # Copy room items from the template zone (if the function exists)
        try do
          template_room_items = Shard.Items.list_room_items_by_zone(template_zone.id)
          
          Enum.each(template_room_items, fn template_room_item ->
            new_room = Map.get(room_mapping, template_room_item.room_id)
            
            if new_room do
              room_item_attrs = %{
                item_id: template_room_item.item_id,
                room_id: new_room.id,
                quantity: template_room_item.quantity,
                map: template_room_item.map
              }
              
              Shard.Items.create_room_item(room_item_attrs)
            end
          end)
        rescue
          UndefinedFunctionError -> :ok
        end
        
        {:ok, new_zone}
      
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp generate_zone_instance_id(zone_name, instance_type, user_id) do
    base = zone_name |> String.downcase() |> String.replace(" ", "-")
    timestamp = System.system_time(:second)
    
    case instance_type do
      "singleplayer" -> "#{base}-sp-#{user_id}-#{timestamp}"
      "multiplayer" -> "#{base}-mp-#{timestamp}"
    end
  end
end
