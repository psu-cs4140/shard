defmodule Shard.Items.Item do
  use Ecto.Schema
  import Ecto.Changeset

  # Define valid item types and rarities
  @item_types ["weapon", "shield", "head", "body", "legs", "feet", "ring", "necklace", "consumable", "misc", "material", "tool", "quest"]
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
  end
end
