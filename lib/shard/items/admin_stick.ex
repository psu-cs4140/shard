defmodule Shard.Items.AdminStick do
  @moduledoc """
  Module for the Admin Stick item which allows admin players to modify zones.
  """

  alias Shard.Items
  alias Shard.Items.Item

  @admin_stick_attributes %{
    name: "Admin Zone Editing Stick",
    description: "A magical stick that allows admins to modify zones",
    item_type: "tool",
    rarity: "legendary",
    equippable: false,
    stackable: false,
    usable: true,
    consumable: false,
    attributes: %{
      "zone_editing" => true
    }
  }

  @doc """
  Creates the Admin Stick item in the database.
  This function should be called during application setup or migration.
  """
  def create_admin_stick_item do
    case Items.get_item_by_name(@admin_stick_attributes.name) do
      nil ->
        Items.create_item(%{
          name: @admin_stick_attributes.name,
          description: @admin_stick_attributes.description,
          item_type: @admin_stick_attributes.item_type,
          rarity: @admin_stick_attributes.rarity,
          equippable: @admin_stick_attributes.equippable,
          stackable: @admin_stick_attributes.stackable,
          usable: @admin_stick_attributes.usable,
          consumable: @admin_stick_attributes.consumable,
          attributes: @admin_stick_attributes.attributes
        })

      existing_item ->
        {:ok, existing_item}
    end
  end

  @doc """
  Gets the Admin Stick item from the database.
  """
  def get_admin_stick_item do
    Items.get_item_by_name(@admin_stick_attributes.name)
  end

  @doc """
  Checks if an item is the Admin Stick.
  """
  def is_admin_stick?(%Item{name: name}) do
    name == @admin_stick_attributes.name
  end

  def is_admin_stick?(_), do: false
end
