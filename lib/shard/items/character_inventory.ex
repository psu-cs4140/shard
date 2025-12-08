defmodule Shard.Items.CharacterInventory do
  @moduledoc """
  This module defines the schema for character inventory and the changeset
  which allows changes to be made to a character inventory' fields. Also
  includes a functon to ensure equipment consistency
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Characters.Character
  alias Shard.Items.Item
  alias Shard.Items.HotbarSlot

  schema "character_inventories" do
    field :quantity, :integer, default: 1
    field :slot_position, :integer
    field :equipped, :boolean, default: false
    field :equipment_slot, :string
    field :current_durability, :integer

    belongs_to :character, Character
    belongs_to :item, Item
    has_many :hotbar_slots, HotbarSlot, foreign_key: :inventory_id

    timestamps(type: :utc_datetime)
  end

  def changeset(inventory, attrs) do
    inventory
    |> cast(attrs, [
      :character_id,
      :item_id,
      :quantity,
      :slot_position,
      :equipped,
      :equipment_slot,
      :current_durability
    ])
    |> validate_required([:character_id, :item_id, :quantity])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_optional_number(:slot_position, greater_than_or_equal_to: 0)
    |> validate_optional_number(:current_durability, greater_than_or_equal_to: 0)
    |> validate_equipment_consistency()
    |> validate_durability_consistency()
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:item_id)
    |> unique_constraint([:character_id, :slot_position])
    |> unique_constraint([:character_id, :equipment_slot],
      name: :character_inventories_character_id_equipment_slot_index
    )
  end

  defp validate_optional_number(changeset, field, opts) do
    case get_field(changeset, field) do
      nil -> changeset
      _value -> validate_number(changeset, field, opts)
    end
  end

  defp validate_equipment_consistency(changeset) do
    equipped = get_field(changeset, :equipped)
    equipment_slot = get_field(changeset, :equipment_slot)

    cond do
      equipped && is_nil(equipment_slot) ->
        add_error(changeset, :equipment_slot, "must be specified for equipped items")

      !equipped && equipment_slot ->
        put_change(changeset, :equipment_slot, nil)

      true ->
        changeset
    end
  end

  defp validate_durability_consistency(changeset) do
    item_id = get_field(changeset, :item_id)
    current_durability = get_field(changeset, :current_durability)

    case {item_id, current_durability} do
      {nil, _} -> changeset
      {_, nil} -> changeset
      {id, durability} -> validate_durability_against_item(changeset, id, durability)
    end
  end

  defp validate_durability_against_item(changeset, item_id, current_durability) do
    case Shard.Repo.get(Item, item_id) do
      nil -> changeset
      item -> check_durability_limits(changeset, item, current_durability)
    end
  end

  defp check_durability_limits(changeset, item, current_durability) do
    cond do
      !item.durability_enabled && current_durability ->
        add_error(changeset, :current_durability, "cannot be set for items without durability")

      item.durability_enabled && current_durability > item.max_durability ->
        add_error(changeset, :current_durability, "cannot exceed item's maximum durability")

      true ->
        changeset
    end
  end
end
