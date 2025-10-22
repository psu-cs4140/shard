defmodule Shard.Items.HotbarSlot do
  @moduledoc """
  This module defines the schema for a hotbarslot and the changeset
  which allows changes to be made to a hotbarslot's fields. Also
  includes a function to ensure inventory / item consistency
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Characters.Character
  alias Shard.Items.{Item, CharacterInventory}

  schema "hotbar_slots" do
    field :slot_number, :integer

    belongs_to :character, Character
    belongs_to :item, Item
    belongs_to :inventory, CharacterInventory

    timestamps(type: :utc_datetime)
  end

  def changeset(hotbar_slot, attrs) do
    hotbar_slot
    |> cast(attrs, [:character_id, :slot_number, :item_id, :inventory_id])
    |> validate_required([:character_id, :slot_number])
    |> validate_number(:slot_number, greater_than_or_equal_to: 1, less_than_or_equal_to: 12)
    |> validate_inventory_item_consistency()
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:item_id)
    |> foreign_key_constraint(:inventory_id)
    |> unique_constraint([:character_id, :slot_number])
  end

  defp validate_inventory_item_consistency(changeset) do
    item_id = get_field(changeset, :item_id)
    inventory_id = get_field(changeset, :inventory_id)

    case {item_id, inventory_id} do
      {nil, nil} -> changeset
      {_, nil} -> add_error(changeset, :inventory_id, "must be specified when item is set")
      {nil, _} -> add_error(changeset, :item_id, "must be specified when inventory is set")
      _ -> changeset
    end
  end
end
