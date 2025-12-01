defmodule Shard.Users.PlayerZones do
  @moduledoc """
  Context for managing player zone instances.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo
  alias Shard.Users.PlayerZone
  alias Shard.Map.Zone

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

  @doc """
  Creates a new zone instance for a player.
  """
  defp create_player_zone_instance(user_id, zone_name, instance_type) do
    # Generate a unique zone_id for this instance
    zone_id = generate_zone_instance_id(zone_name, instance_type, user_id)
    
    # Get the zone template (first zone with this name)
    zone_template = Repo.one(
      from z in Zone,
        where: z.name == ^zone_name,
        limit: 1
    )
    
    if zone_template do
      # Create the actual zone instance
      zone_attrs = %{
        name: zone_name,
        zone_id: zone_id,
        slug: "#{zone_template.slug}-#{zone_id}",
        description: zone_template.description,
        zone_type: zone_template.zone_type,
        min_level: zone_template.min_level,
        max_level: zone_template.max_level,
        is_public: instance_type == "multiplayer",
        is_active: true,
        properties: Map.put(zone_template.properties || %{}, "instance_type", instance_type),
        display_order: zone_template.display_order
      }
      
      case Shard.Map.create_zone(zone_attrs) do
        {:ok, zone} ->
          # Create the player zone association
          player_zone_attrs = %{
            zone_name: zone_name,
            instance_type: instance_type,
            zone_id: zone_id,
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
      case Shard.Map.get_zone(player_zone.zone_id) do
        nil -> :ok
        zone -> Shard.Map.delete_zone(zone)
      end
      
      # Delete the player zone association
      Repo.delete(player_zone)
    end)
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
