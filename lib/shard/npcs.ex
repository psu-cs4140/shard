defmodule Shard.Npcs do
  @moduledoc """
  The Npcs context.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo

  alias Shard.Npcs.Npc

  @doc """
  Returns the list of npcs.

  ## Examples

      iex> list_npcs()
      [%Npc{}, ...]

  """
  def list_npcs do
    Repo.all(Npc)
  end

  @doc """
  Returns the list of npcs with preloaded associations.
  """
  def list_npcs_with_preloads do
    Repo.all(Npc)
    |> Repo.preload([:room])
  end

  @doc """
  Gets a single npc.

  Raises `Ecto.NoResultsError` if the Npc does not exist.

  ## Examples

      iex> get_npc!(123)
      %Npc{}

      iex> get_npc!(456)
      ** (Ecto.NoResultsError)

  """
  def get_npc!(id), do: Repo.get!(Npc, id)

  @doc """
  Gets a single npc with preloaded associations.
  """
  def get_npc_with_preloads!(id) do
    Repo.get!(Npc, id)
    |> Repo.preload([:room])
  end

  @doc """
  Gets a single npc by name.
  """
  def get_npc_by_name(name) do
    Repo.get_by(Npc, name: name)
  end

  @doc """
  Gets NPCs by room.
  """
  def get_npcs_by_room(room_id) do
    from(n in Npc, where: n.room_id == ^room_id and n.is_active == true)
    |> Repo.all()
  end

  @doc """
  Gets NPCs by location coordinates.
  """
  def get_npcs_by_location(x, y, z \\ 0) do
    from(n in Npc,
      where:
        n.location_x == ^x and n.location_y == ^y and n.location_z == ^z and n.is_active == true
    )
    |> Repo.all()
  end

  @doc """
  Gets NPCs by type.
  """
  def get_npcs_by_type(npc_type) do
    from(n in Npc, where: n.npc_type == ^npc_type and n.is_active == true)
    |> Repo.all()
  end

  @doc """
  Creates a npc.

  ## Examples

      iex> create_npc(%{field: value})
      {:ok, %Npc{}}

      iex> create_npc(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_npc(attrs \\ %{}) do
    %Npc{}
    |> Npc.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a npc.

  ## Examples

      iex> update_npc(npc, %{field: new_value})
      {:ok, %Npc{}}

      iex> update_npc(npc, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_npc(%Npc{} = npc, attrs) do
    npc
    |> Npc.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a npc.

  ## Examples

      iex> delete_npc(npc)
      {:ok, %Npc{}}

      iex> delete_npc(npc)
      {:error, %Ecto.Changeset{}}

  """
  def delete_npc(%Npc{} = npc) do
    Repo.delete(npc)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking npc changes.

  ## Examples

      iex> change_npc(npc)
      %Ecto.Changeset{data: %Npc{}}

  """
  def change_npc(%Npc{} = npc, attrs \\ %{}) do
    Npc.changeset(npc, attrs)
  end

  @doc """
  Returns the list of rooms for NPC assignment.
  """
  def list_rooms do
    alias Shard.Map.Room
    Repo.all(Room)
  end

  ## Tutorial NPCs

  def create_tutorial_npc_goldie do
    # Check if Goldie already exists at (0,0)
    existing_goldie =
      from(n in Npc,
        where: n.location_x == 0 and n.location_y == 0 and n.name == "Goldie"
      )
      |> Repo.one()

    if is_nil(existing_goldie) do
      %Npc{}
      |> Npc.changeset(%{
        name: "Goldie",
        description: "A friendly golden retriever with bright, intelligent eyes and a wagging tail. She seems eager to help guide newcomers through their adventure.",
        npc_type: "friendly",
        location_x: 0,
        location_y: 0,
        location_z: 0,
        health: 100,
        max_health: 100,
        mana: 50,
        max_mana: 50,
        level: 1,
        is_active: true,
        dialogue: [
          "Woof! Welcome to the tutorial, adventurer!",
          "I'm Goldie, your faithful guide dog. Let me help you get started on your journey.",
          "",
          "Here are some basic commands to get you moving:",
          "• Type 'look' to examine your surroundings",
          "• Use 'north', 'south', 'east', 'west' (or n/s/e/w) to move around",
          "• Try 'pickup \"item_name\"' to collect items you find",
          "• Use 'inventory' to see what you're carrying",
          "• Type 'help' anytime for a full list of commands",
          "",
          "There's a key hidden somewhere to the south that might come in handy later!",
          "Good luck, and remember - I'll always be here at (0,0) if you need guidance!"
        ]
      })
      |> Repo.insert()
    else
      {:ok, existing_goldie}
    end
  end
end
