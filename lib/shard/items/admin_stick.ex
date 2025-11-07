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
    Repo.get_by(Item, name: @admin_stick_name)
  end

  @doc """
  Checks if an item is the Admin Stick.
  """
  def admin_stick?(%Item{name: name}) do
    name == @admin_stick_name
  end

  def admin_stick?(_), do: false

  @doc """
  Grants the Admin Stick to a character if they don't already have it.
  """
  def grant_admin_stick(character_id) do
    admin_stick = get_admin_stick_item()

    if admin_stick do
      # Check if character already has the Admin Stick
      case get_character_admin_stick(character_id, admin_stick.id) do
        nil ->
          # Character doesn't have it, so add it to their inventory
          %CharacterInventory{}
          |> CharacterInventory.changeset(%{
            character_id: character_id,
            item_id: admin_stick.id,
            quantity: 1,
            slot_position: find_next_available_slot(character_id)
          })
          |> Repo.insert()

        _ ->
          # Character already has it
          {:ok, "Character already has Admin Stick"}
      end
    else
      {:error, "Admin Stick item not found in database"}
    end
  end

  @doc """
  Checks if a character has the Admin Stick in their inventory.
  """
  def has_admin_stick?(character_id) do
    admin_stick = get_admin_stick_item()

    if admin_stick do
      !!get_character_admin_stick(character_id, admin_stick.id)
    else
      false
    end
  end

  # Helper function to find a character's Admin Stick in their inventory
  defp get_character_admin_stick(character_id, admin_stick_id) do
    Repo.get_by(CharacterInventory, character_id: character_id, item_id: admin_stick_id)
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

    Enum.find(0..99, fn slot -> not MapSet.member?(used_slots, slot) end) || 0
  end
end
