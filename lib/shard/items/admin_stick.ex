defmodule Shard.Items.AdminStick do
  @moduledoc """
  Module for the Admin Stick item which allows admin players to modify zones.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo
  alias Shard.Items.Item
  alias Shard.Items.CharacterInventory

  @admin_stick_name "Admin Zone Editing Stick"

  @doc """
  Gets the Admin Stick item from the database by name.
  """
  def get_admin_stick_item do
    item = Repo.get_by(Item, name: @admin_stick_name)
    IO.puts("DEBUG: get_admin_stick_item - Found item: #{inspect(item)}")
    item
  end

  @doc """
  Checks if an item is the Admin Stick.
  """
  def admin_stick?(%Item{name: name}) do
    result = name == @admin_stick_name
    IO.puts("DEBUG: admin_stick? - Item name: #{name}, Is admin stick: #{result}")
    result
  end

  def admin_stick?(_), do: false

  @doc """
  Grants the Admin Stick to a character if they don't already have it.
  """
  def grant_admin_stick(character_id) do
    IO.puts("DEBUG: grant_admin_stick - Character ID: #{character_id}")
    admin_stick = get_admin_stick_item()

    if admin_stick do
      IO.puts("DEBUG: grant_admin_stick - Admin stick found, ID: #{admin_stick.id}")
      # Check if character already has the Admin Stick (bypass sellable filter)
      case has_admin_stick?(character_id) do
        false ->
          IO.puts("DEBUG: grant_admin_stick - Character doesn't have stick, creating...")
          # Character doesn't have it, so add it to their inventory
          changeset_attrs = %{
            character_id: character_id,
            item_id: admin_stick.id,
            quantity: 1,
            slot_position: find_next_available_slot(character_id)
          }
          
          IO.puts("DEBUG: grant_admin_stick - Creating inventory with attrs: #{inspect(changeset_attrs)}")
          
          result = %CharacterInventory{}
          |> CharacterInventory.changeset(changeset_attrs)
          |> Repo.insert()
          
          IO.puts("DEBUG: grant_admin_stick - Insert result: #{inspect(result)}")
          result

        true ->
          IO.puts("DEBUG: grant_admin_stick - Character already has Admin Stick")
          # Character already has it
          {:ok, "Character already has Admin Stick"}
      end
    else
      IO.puts("DEBUG: grant_admin_stick - Admin Stick item not found in database")
      {:error, "Admin Stick item not found in database"}
    end
  end

  @doc """
  Checks if a character has the Admin Stick in their inventory.
  """
  def has_admin_stick?(character_id) do
    IO.puts("DEBUG: has_admin_stick? - Character ID: #{character_id}")
    admin_stick = get_admin_stick_item()

    if admin_stick do
      IO.puts("DEBUG: has_admin_stick? - Admin stick ID: #{admin_stick.id}")
      # Direct query that bypasses sellable filter
      query = from(ci in CharacterInventory,
        where: ci.character_id == ^character_id and ci.item_id == ^admin_stick.id
      )
      
      IO.puts("DEBUG: has_admin_stick? - Query: #{inspect(query)}")
      result = Repo.exists?(query)
      IO.puts("DEBUG: has_admin_stick? - Result: #{result}")
      result
    else
      IO.puts("DEBUG: has_admin_stick? - Admin stick not found")
      false
    end
  end

  # Helper function to find next available inventory slot
  defp find_next_available_slot(character_id) do
    used_slots =
      from(ci in CharacterInventory,
        where: ci.character_id == ^character_id,
        select: ci.slot_position
      )
      |> Repo.all()
      |> MapSet.new()

    next_slot = Enum.find(0..99, fn slot -> not MapSet.member?(used_slots, slot) end) || 0
    IO.puts("DEBUG: find_next_available_slot - Character ID: #{character_id}, Next slot: #{next_slot}")
    next_slot
  end
end
