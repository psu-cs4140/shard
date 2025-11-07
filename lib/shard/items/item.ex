defmodule Shard.Items.Item do
  @moduledoc """
  The item module defines the scheme and some functions related to items/
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Items.{CharacterInventory, RoomItem, HotbarSlot}
  alias Shard.Spells.Spells

  schema "items" do
    field :name, :string
    field :description, :string
    field :item_type, :string
    field :rarity, :string, default: "common"
    field :value, :integer, default: 0
    field :weight, :decimal, default: Decimal.new("0.0")
    field :stackable, :boolean, default: false
    field :max_stack_size, :integer, default: 1
    field :usable, :boolean, default: false
    field :equippable, :boolean, default: false
    field :equipment_slot, :string
    field :stats, :map, default: %{}
    field :requirements, :map, default: %{}
    field :effects, :map, default: %{}
    field :icon, :string
    field :is_active, :boolean, default: true
    field :pickup, :boolean, default: true
    field :location, :string
    field :map, :string

    belongs_to :spell, Spells

    has_many :character_inventories, CharacterInventory
    has_many :room_items, RoomItem
    has_many :hotbar_slots, HotbarSlot

    timestamps(type: :utc_datetime)
  end

  @item_types ~w(weapon armor consumable material quest misc key)
  @rarities ~w(common uncommon rare epic legendary)
  @equipment_slots ~w(head chest legs feet hands weapon shield ring necklace)
  @maps ~w(tutorial_terrain dark_forest crystal_caves volcanic_peaks frozen_wastes shadow_realm)

  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :name,
      :description,
      :item_type,
      :rarity,
      :value,
      :weight,
      :stackable,
      :max_stack_size,
      :usable,
      :equippable,
      :equipment_slot,
      :stats,
      :requirements,
      :effects,
      :icon,
      :is_active,
      :pickup,
      :location,
      :map,
      :spell_id
    ])
    |> validate_required([:name, :item_type])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_inclusion(:item_type, @item_types)
    |> validate_inclusion(:rarity, @rarities)
    |> validate_inclusion(:map, @maps)
    |> validate_number(:value, greater_than_or_equal_to: 0)
    |> validate_number(:weight, greater_than_or_equal_to: 0)
    |> validate_number(:max_stack_size, greater_than: 0)
    |> validate_equipment_slot()
    |> foreign_key_constraint(:spell_id)
    |> unique_constraint(:name)
  end

  defp validate_equipment_slot(changeset) do
    equippable = get_field(changeset, :equippable)
    equipment_slot = get_field(changeset, :equipment_slot)

    cond do
      equippable && is_nil(equipment_slot) ->
        add_error(changeset, :equipment_slot, "must be specified for equippable items")

      equippable && equipment_slot not in @equipment_slots ->
        add_error(changeset, :equipment_slot, "is not a valid equipment slot")

      !equippable && equipment_slot ->
        put_change(changeset, :equipment_slot, nil)

      true ->
        changeset
    end
  end

  def item_types, do: @item_types
  def rarities, do: @rarities
  def equipment_slots, do: @equipment_slots
  def maps, do: @maps
end
