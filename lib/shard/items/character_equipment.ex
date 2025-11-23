defmodule Shard.Items.CharacterEquipment do
  @moduledoc """
  Schema for tracking which items a character has equipped.

  Each character can have one item equipped per equipment slot (head, body, legs, etc.).
  This module ensures that only equippable items can be equipped and that they are
  equipped in the correct slot.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Shard.Characters.Character
  alias Shard.Items.Item

  schema "character_equipment" do
    belongs_to :character, Character
    belongs_to :item, Item
    field :equipment_slot, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(character_equipment, attrs) do
    character_equipment
    |> cast(attrs, [:character_id, :item_id, :equipment_slot])
    |> validate_required([:character_id, :item_id, :equipment_slot])
    |> validate_inclusion(:equipment_slot, Item.equipment_slots())
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:item_id)
    |> unique_constraint([:character_id, :equipment_slot],
      name: :character_equipment_character_id_equipment_slot_index
    )
    |> validate_item_equippable()
    |> validate_equipment_slot_matches_item()
  end

  defp validate_item_equippable(changeset) do
    item_id = get_field(changeset, :item_id)

    case item_id do
      nil -> changeset
      id -> validate_item_exists_and_equippable(changeset, id)
    end
  end

  defp validate_item_exists_and_equippable(changeset, item_id) do
    case Shard.Repo.get(Item, item_id) do
      nil -> add_error(changeset, :item_id, "does not exist")
      item -> validate_item_is_equippable(changeset, item)
    end
  end

  defp validate_item_is_equippable(changeset, item) do
    if item.equippable do
      changeset
    else
      add_error(changeset, :item_id, "is not equippable")
    end
  end

  defp validate_equipment_slot_matches_item(changeset) do
    item_id = get_field(changeset, :item_id)
    equipment_slot = get_field(changeset, :equipment_slot)

    case {item_id, equipment_slot} do
      {nil, _} -> changeset
      {_, nil} -> changeset
      {id, slot} -> validate_slot_matches_item(changeset, id, slot)
    end
  end

  defp validate_slot_matches_item(changeset, item_id, equipment_slot) do
    case Shard.Repo.get(Item, item_id) do
      nil -> changeset
      item -> check_slot_match(changeset, item, equipment_slot)
    end
  end

  defp check_slot_match(changeset, item, equipment_slot) do
    if item.equipment_slot == equipment_slot do
      changeset
    else
      add_error(changeset, :equipment_slot, "does not match item's equipment slot")
    end
  end
end
