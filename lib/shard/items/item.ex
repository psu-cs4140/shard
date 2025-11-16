defmodule Shard.Items.Item do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  New schema for items
  """

  # Define valid item types and rarities
  @item_types [
    "weapon",
    "shield",
    "head",
    "body",
    "legs",
    "feet",
    "ring",
    "necklace",
    "consumable",
    "misc",
    "material",
    "tool",
    "quest"
  ]
  @rarities ["common", "uncommon", "rare", "epic", "legendary"]
  @equipment_slots [
    "head",
    "body",
    "legs",
    "feet",
    "weapon",
    "shield",
    "ring",
    "necklace"
  ]

  # Expose these for other modules to use
  def item_types, do: @item_types
  def rarities, do: @rarities
  def equipment_slots, do: @equipment_slots

  schema "items" do
    field :name, :string
    field :description, :string
    field :item_type, :string
    field :rarity, :string
    field :value, :integer
    field :weight, :decimal
    field :stackable, :boolean, default: false
    field :max_stack_size, :integer
    field :usable, :boolean, default: false
    field :equippable, :boolean, default: false
    field :equipment_slot, :string
    field :stats, :map
    field :requirements, :map
    field :effects, :map
    field :icon, :string
    field :is_active, :boolean, default: true
    field :pickup, :boolean, default: true
    field :location, :string
    field :map, :string
    field :sellable, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  @doc false
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
      :sellable
    ])
    # Added :item_type to required fields
    |> validate_required([:name, :item_type])
    # Validate item_type is in allowed list
    |> validate_inclusion(:item_type, @item_types)
    # Validate rarity is in allowed list
    |> validate_inclusion(:rarity, @rarities)
    # Validate equipment_slot when present
    |> validate_inclusion(:equipment_slot, @equipment_slots)
    # Add unique constraint on name
    |> unique_constraint(:name)
    # Auto-set equippable and equipment_slot for armor pieces
    |> set_equipment_defaults()
  end

  # Automatically set equippable=true and equipment_slot for armor pieces
  defp set_equipment_defaults(changeset) do
    item_type = get_field(changeset, :item_type)

    case item_type do
      type
      when type in ["head", "body", "legs", "feet", "weapon", "shield", "ring", "necklace"] ->
        changeset
        |> put_change(:equippable, true)
        |> maybe_set_equipment_slot(type)

      _ ->
        changeset
    end
  end

  # Set equipment_slot if not already set
  defp maybe_set_equipment_slot(changeset, item_type) do
    current_slot = get_field(changeset, :equipment_slot)

    if is_nil(current_slot) do
      put_change(changeset, :equipment_slot, item_type)
    else
      changeset
    end
  end
end
