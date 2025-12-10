defmodule Shard.WorldEvents do
  @moduledoc """
  The WorldEvents context.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo

  alias Shard.WorldEvents.WorldEvent

  @doc """
  Returns the list of world_events.

  ## Examples

      iex> list_world_events()
      [%WorldEvent{}, ...]

  """
  def list_world_events do
    Repo.all(WorldEvent)
  end

  @doc """
  Gets a single world_event.

  Raises `Ecto.NoResultsError` if the World event does not exist.

  ## Examples

      iex> get_world_event!(123)
      %WorldEvent{}

      iex> get_world_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_world_event!(id), do: Repo.get!(WorldEvent, id)

  @doc """
  Creates a world_event.

  ## Examples

      iex> create_world_event(%{field: value})
      {:ok, %WorldEvent{}}

      iex> create_world_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_world_event(attrs \\ %{}) do
    %WorldEvent{}
    |> WorldEvent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a world_event.

  ## Examples

      iex> update_world_event(world_event, %{field: new_value})
      {:ok, %WorldEvent{}}

      iex> update_world_event(world_event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_world_event(%WorldEvent{} = world_event, attrs) do
    world_event
    |> WorldEvent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a world_event.

  ## Examples

      iex> delete_world_event(world_event)
      {:ok, %WorldEvent{}}

      iex> delete_world_event(world_event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_world_event(%WorldEvent{} = world_event) do
    Repo.delete(world_event)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking world_event changes.

  ## Examples

      iex> change_world_event(world_event)
      %Ecto.Changeset{data: %WorldEvent{}}

  """
  def change_world_event(%WorldEvent{} = world_event, attrs \\ %{}) do
    WorldEvent.changeset(world_event, attrs)
  end

  @doc """
  Gets active world events for a specific room.
  """
  def get_active_events_for_room(room_id) do
    from(we in WorldEvent,
      where: we.room_id == ^room_id and we.is_active == true,
      order_by: [desc: we.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets all active world events.
  """
  def get_active_events do
    from(we in WorldEvent,
      where: we.is_active == true,
      order_by: [desc: we.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Deactivates a world event.
  """
  def deactivate_event(%WorldEvent{} = world_event) do
    update_world_event(world_event, %{is_active: false, ended_at: DateTime.utc_now()})
  end

  @doc """
  Spawns a random boss event in a random room.
  """
  def spawn_random_boss_event do
    # Get a random room (you'll need to implement this based on your room system)
    case get_random_room() do
      nil ->
        {:error, :no_rooms_available}

      room ->
        boss_types = [
          "Ancient Dragon",
          "Shadow Lord",
          "Frost Giant",
          "Fire Elemental",
          "Void Walker"
        ]

        boss_type = Enum.random(boss_types)

        create_world_event(%{
          event_type: "boss_spawn",
          title: "#{boss_type} Appears!",
          description: "A powerful #{boss_type} has appeared and threatens the area!",
          room_id: room.id,
          is_active: true,
          duration_minutes: Enum.random(30..120),
          data: %{
            boss_type: boss_type,
            difficulty: Enum.random(1..5),
            rewards: generate_boss_rewards()
          }
        })
    end
  end

  # Private helper functions
  defp get_random_room do
    # Get a random room from the database
    from(r in Shard.Map.Room, order_by: fragment("RANDOM()"), limit: 1)
    |> Repo.one()
  end

  defp generate_boss_rewards do
    %{
      experience: Enum.random(1000..5000),
      gold: Enum.random(500..2000),
      rare_items: Enum.random(1..3)
    }
  end
end
